--- @type ns.Core
local ns       = select(2, ...)
local params   = ns.params
--- @class BF_CoreModel
local model    = ns.model

--- =========================================================
--- Caches
--- =========================================================

local _type    = type
local _pairs   = pairs
local _floor   = math.floor
local _time    = time

local defaults = {
    global = {
        minimapButton = {
            hide = false,
            lock = false,
            minimapPos = 220,
        },
        characters = {},       -- [guid] = {name, realm, nameRealm, lastSeen}
        lastSeenThreshold = 0, -- days; 0 = Never
    },
    char = {
        plugins = {
            ['*'] = true, -- Default to true for all plugins unless explicitly set to false
        },
    },
}

--- =========================================================
--- Overridable Methods
--- =========================================================

function model:OnInit()
    self.db = ns.DBMS.new(params.core.dbName, defaults)
end

function model:OnDisable()
    self.db:CleanUp()
end

--- =========================================================
--- Plugin Management
--- =========================================================

-- local pluginSettings = {}

-- --- Register a Blizzard Settings API setting object for a plugin
-- --- @param pluginName string The name of the plugin
-- --- @param setting table The Settings API setting object
-- function model:RegisterPluginSetting(pluginName, setting)
--     pluginSettings[pluginName] = setting
-- end

-- --- Get all registered plugin settings
-- --- @return table<string, table> Map of plugin names to setting objects
-- function model:GetPluginSettings()
--     return pluginSettings
-- end

-- --- Get a specific plugin's setting object
-- --- @param pluginName string The name of the plugin
-- --- @return table? The setting object, or nil if not found
-- function model:GetPluginSetting(pluginName)
--     return pluginSettings[pluginName]
-- end

--- Set whether a plugin is activated for the current character
--- @param pluginName string The name of the plugin
--- @param activated boolean True to activate, false to deactivate
function model:SetPluginActivated(pluginName, activated)
    self.db.char.plugins[pluginName] = activated
end

--- Get whether a plugin is activated for the current character
--- @param pluginName string The name of the plugin (e.g., "BitForge_AutoBalance")
--- @return boolean activated True if the plugin is activated, false if deactivated
function model:IsPluginActivated(pluginName)
    return self.db.char.plugins[pluginName] == true
end

--- Get all plugin states for the current character
--- @return table<string, boolean> Map of plugin names to activated states
function model:GetAllPluginStates()
    return self.db.char.plugins
end

--- =========================================================
--- Minimap Button Settings
--- =========================================================

--- Get the minimap button settings
--- @return table minimapButtonSettings The minimap button settings table
function model:GetMinimapButtonSettings()
    return self.db.global.minimapButton
end

--- Save the minimap button angle
--- @param angle number The angle in degrees
function model:SetMinimapPos(angle)
    self.db.global.minimapButton.minimapPos = angle
end

--- =========================================================
--- Alts Management
--- =========================================================

--- Get the list of all alts with their GUIDs, names, and realms
--- @return table alts List of character info tables: { [guid] = {name, realm, nameRealm, lastSeen} }
function model:GetCharacters()
    return self.db.global.characters
end

--- Save or update a character's info by GUID
--- @param guid string The character's GUID
--- @param data table The character's info table: {name, realm, nameRealm, lastSeen}
function model:SaveCharacter(guid, data)
    self.db.global.characters[guid] = data
end

--- Delete characters by their GUIDs
--- @param guidList table List of GUIDs to delete
function model:DeleteCharacters(guidList)
    for _, guid in _pairs(guidList) do
        self.db.global.characters[guid] = nil
    end
end

--- Get the lastSeen threshold in days (0 = Never)
--- @return number days
function model:GetLastSeenThreshold()
    return self.db.global.lastSeenThreshold
end

--- Set the lastSeen threshold in days (0 = Never)
--- @param days number
function model:SetLastSeenThreshold(days)
    self.db.global.lastSeenThreshold = days
end

--- Get characters whose lastSeen exceeds the threshold, excluding the given GUID
--- @param excludeGUID string The current character's GUID to exclude
--- @return table[]|nil List of {guid, nameRealm, daysSince}, or nil if threshold is 0 or none found
function model:GetInvalidCharacters(excludeGUID)
    local threshold = self.db.global.lastSeenThreshold
    if not threshold or threshold == 0 then return nil end

    local now        = _time()
    local cutoff     = threshold * 86400
    local characters = self.db.global.characters
    local results    = {}

    for guid, data in _pairs(characters) do
        if guid ~= excludeGUID and data.lastSeen then
            local elapsed = now - data.lastSeen
            if elapsed >= cutoff then
                results[#results + 1] = {
                    guid      = guid,
                    nameRealm = data.nameRealm,
                    daysSince = _floor(elapsed / 86400),
                }
            end
        end
    end

    return #results > 0 and results or nil
end

--- Get all DB characters that share the given class token, excluding the specified GUID
--- @param class string The class token (e.g. "WARRIOR")
--- @param excludeGUID string The GUID to exclude (the current character's GUID)
--- @return table[]? entries List of matching entry tables, or nil if none found
function model:GetCharactersByClass(class, excludeGUID)
    local characters = self.db.global.characters
    local matches    = {}

    for guid, data in _pairs(characters) do
        if guid ~= excludeGUID and data.class == class then
            matches[#matches + 1] = {
                guid        = guid,
                storedName  = data.name,
                storedRealm = data.realm,
                nameRealm   = data.nameRealm,
            }
        end
    end

    return #matches > 0 and matches or nil
end

--- =========================================================
--- Character Migration
--- =========================================================

local function migrateGUIDEntry(dbTable, oldGUID, newGUID)
    if _type(dbTable) ~= "table" then return end
    if oldGUID == newGUID then return end

    local oldData = dbTable[oldGUID]
    if oldData == nil then return end

    local newData = dbTable[newGUID]
    if newData == nil then
        dbTable[newGUID] = oldData
    elseif _type(oldData) == "table" and _type(newData) == "table" then
        for key, value in pairs(oldData) do
            if newData[key] == nil then
                newData[key] = value
            end
        end
    end

    dbTable[oldGUID] = nil
end

--- Migrate character data from an old GUID to a new GUID (e.g., after a character rename).
--- Migrates `global.characters`, root `char`, and each namespace's `char` table.
--- If both GUID entries exist, performs a shallow merge and keeps existing `newGUID` keys.
--- @param oldGUID string The old character GUID
--- @param newGUID string The new character GUID
function model:MigrateCharacter(oldGUID, newGUID)
    local db = self.db

    migrateGUIDEntry(db.global and db.global.characters, oldGUID, newGUID)
    migrateGUIDEntry(db.charMap, oldGUID, newGUID)

    for _, nsSV in _pairs(db.namespaces) do
        if _type(nsSV) == "table" and _type(nsSV.char) == "table" then
            migrateGUIDEntry(nsSV.char, oldGUID, newGUID)
        end
    end
end

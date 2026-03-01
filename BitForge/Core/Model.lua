--- @type ns_core
local ns = select(2, ...)
local params = ns.params
--- @class BF_CoreModel
local model = ns.model

--- =========================================================
--- Caches
--- =========================================================

local _error = error
local _type = type
local _pairs = pairs
local _GetPlayerInfoByGUID = GetPlayerInfoByGUID

local function assertInitialized(self)
    if not self.initialized then
        _error("Database not initialized.", 3)
    end
end

local defaults = {
    global = {
        minimapButton = {
            hide = false,
            lock = false,
            minimapPos = 220,
        },
        characters = {}, -- [guid] = {name, realm, nameRealm, lastSeen}
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
    assertInitialized(self)

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
    assertInitialized(self)

    self.db.char.plugins[pluginName] = activated
end

--- Get whether a plugin is activated for the current character
--- @param pluginName string The name of the plugin (e.g., "BitForge_AutoBalance")
--- @return boolean activated True if the plugin is activated, false if deactivated
function model:IsPluginActivated(pluginName)
    assertInitialized(self)

    return self.db.char.plugins[pluginName] == true
end

--- Get all plugin states for the current character
--- @return table<string, boolean> Map of plugin names to activated states
function model:GetAllPluginStates()
    assertInitialized(self)

    return self.db.char.plugins
end

--- =========================================================
--- Minimap Button Settings
--- =========================================================

--- Get the minimap button settings
--- @return table minimapButtonSettings The minimap button settings table
function model:GetMinimapButtonSettings()
    assertInitialized(self)

    return self.db.global.minimapButton
end

--- =========================================================
--- Alts Management
--- =========================================================

--- Get the list of all alts with their GUIDs, names, and realms
--- @return table alts List of character info tables: { [guid] = {name, realm, nameRealm, lastSeen} }
function model:GetCharacters()
    assertInitialized(self)

    return self.db.global.characters
end

--- Save or update a character's info by GUID
--- @param guid string The character's GUID
--- @param data table The character's info table: {name, realm, nameRealm, lastSeen}
function model:SaveCharacter(guid, data)
    assertInitialized(self)

    self.db.global.characters[guid] = data
end

--- Delete characters by their GUIDs
--- @param guidList table List of GUIDs to delete
function model:DeleteCharacters(guidList)
    assertInitialized(self)

    for _, guid in _pairs(guidList) do
        self.db.global.characters[guid] = nil
    end
end

--- Validate if a GUID corresponds to an existing character and return its name and realm
--- @param guid string The character's GUID
--- @return boolean? isValid True if the GUID is valid, nil otherwise
function model:IsValidCharacter(guid)
    local name = select(6, _GetPlayerInfoByGUID(guid))

    -- If name is nil, the GUID is invalid (character deleted/doesn't exist)
    return name ~= nil
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
    assertInitialized(self)

    local db = self.db

    migrateGUIDEntry(db.global and db.global.characters, oldGUID, newGUID)
    migrateGUIDEntry(db.charMap, oldGUID, newGUID)

    for _, nsSV in _pairs(db.namespaces) do
        if _type(nsSV) == "table" and _type(nsSV.char) == "table" then
            migrateGUIDEntry(nsSV.char, oldGUID, newGUID)
        end
    end
end

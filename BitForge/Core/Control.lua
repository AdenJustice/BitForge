---@type string, ns.Core
local ADDON_NAME, ns = ...
local params = ns.params
local utils = ns.utils
local L = ns.locale
local model = ns.model
local view = ns.view
--- @class BF_CoreControl
local control = ns.control

--- =========================================================
--- Caches
--- =========================================================

local _ipairs = ipairs
local _pairs = pairs
local _format = string.format
local _time = time

local _GetAddOnInfo = C_AddOns.GetAddOnInfo
local _GetNumAddOns = C_AddOns.GetNumAddOns
local _LoadAddOn = C_AddOns.LoadAddOn
local _IsAddOnLOD = C_AddOns.IsAddOnLoadOnDemand
local _GetCategory = Settings.GetCategory
local _RegisterCategory = Settings.RegisterVerticalLayoutCategory
local _CreateCheckbox = Settings.CreateCheckbox
local _RegisterProxy = Settings.RegisterProxySetting
local _RegisterAddon = Settings.RegisterAddOnCategory
local _GetRealmName = GetRealmName
local _UnitGUID = UnitGUID
local _UnitName = UnitName

--- =========================================================
--- Character Management
--- =========================================================

local function updateCharacterInfo(guid, name, realm)
    if not guid or not name or not realm then
        return
    end

    model:SaveCharacter(guid, {
        name      = name,
        realm     = realm,
        nameRealm = _format("%s-%s", name, realm),
        lastSeen  = _time(),
    })
end

local function searchInvalidCharacters()
    local characters = model:GetCharacters()
    local invalidEntries = {}

    for guid, data in _pairs(characters) do
        local isValid = model:IsValidCharacter(guid)
        if not isValid and data.nameRealm then
            invalidEntries[#invalidEntries + 1] = {
                guid        = guid,
                storedName  = data.name,
                storedRealm = data.realm,
                nameRealm   = data.nameRealm,
            }
        end
    end

    return #invalidEntries > 0 and invalidEntries
end

local function onCharacterLogin()
    local currentGUID  = _UnitGUID("player")
    local currentName  = _UnitName("player")
    local currentRealm = _GetRealmName()

    if not (currentGUID and currentName and currentRealm) then return end

    local characters     = model:GetCharacters()
    local tracked        = characters[currentGUID]
    local invalidEntries = searchInvalidCharacters()

    if invalidEntries and not tracked then
        control:ShowMigrationDialog(invalidEntries, currentGUID, currentName, currentRealm)
    else
        updateCharacterInfo(currentGUID, currentName, currentRealm)
        if invalidEntries then
            control:ShowPurgeDialog(invalidEntries)
        end
    end
end

function control:ShowMigrationDialog(invalidList, guid, name, realm)
    -- Callback when user selects a character to migrate from the invalid list
    local onSelect = function(selectedGUID)
        local selectedEntry
        for _, entry in _ipairs(invalidList) do
            if entry.guid == selectedGUID then
                selectedEntry = entry
                break
            end
        end

        if not selectedEntry then return end

        -- Migrate tracking GUID
        model:MigrateCharacter(selectedGUID, guid)
        -- Save current character with up-to-date info
        updateCharacterInfo(guid, name, realm)

        -- Remove the migrated entry from the invalid list
        local remainingList = {}
        for _, entry in _ipairs(invalidList) do
            if entry.guid ~= selectedGUID then
                remainingList[#remainingList + 1] = entry
            end
        end

        -- Proceed to purge if there are still entries to clean up
        if #remainingList > 0 then
            control:ShowPurgeDialog(remainingList)
        else
            view:HideMigrationDialog()
        end
    end

    -- Callback when user skips migration.
    -- We save the current character immediately so the new GUID is registered
    -- before Step 2, regardless of what the user decides to purge or keep there.
    local onSkip = function()
        updateCharacterInfo(guid, name, realm)
        control:ShowPurgeDialog(invalidList)
    end

    view:ShowMigrationDialog(invalidList, onSelect, onSkip)
end

function control:ShowPurgeDialog(invalidList)
    -- Callback when user purges selected invalid entries
    local onPurge = function(selectedGuids)
        if selectedGuids and #selectedGuids > 0 then
            model:DeleteCharacters(selectedGuids)
        end
        view:HideMigrationDialog()
    end

    -- Callback when user keeps all invalid entries
    local onKeepAll = function()
        view:HideMigrationDialog()
    end

    view:ShowPurgeDialog(invalidList, onPurge, onKeepAll)
end

--- =========================================================
--- Plugin Management
--- =========================================================

local function getAvailablePlugins()
    local plugins   = {}
    local numAddOns = _GetNumAddOns()

    for i = 1, numAddOns do
        --- Filter addons by prefix and load-on-demand status
        local name, title = _GetAddOnInfo(i)
        if name and name:match("^BitForge_") and _IsAddOnLOD(name) then
            plugins[#plugins + 1] = {
                name      = name,
                title     = title,
                activated = model:IsPluginActivated(name),
            }
        end
    end

    return plugins
end

local function loadActivePlugins(availablePlugins)
    local activePlugins = {}
    --- Check which plugins are activated for this character and load them
    for _, pluginInfo in _ipairs(availablePlugins) do
        if pluginInfo.activated then
            -- Load and activate the plugin in one step since WoW doesn't support unloading addons
            local success, reason = _LoadAddOn(pluginInfo.name)
            if success then
                activePlugins[#activePlugins + 1] = {
                    name = pluginInfo.name,
                    title = pluginInfo.title,
                }
                control:Trigger("BitForge.Plugins.Enable", pluginInfo.name)
            elseif reason then
                local msg = _G["ADDON_" .. reason] or reason
                view:Print(_format("Failed to load plugin '%s': %s", pluginInfo.name, msg))
            end
        end
    end

    return activePlugins
end

local registeredCategory
local function registerSettings(activePlugins)
    local category, layout = _RegisterCategory(params.core.name)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["settings:plugins_header"]))

    for _, pluginInfo in _ipairs(activePlugins) do
        local name = pluginInfo.title
        local variable = pluginInfo.name

        local function GetValue()
            return model:IsPluginActivated(variable)
        end

        local function SetValue(value)
            model:SetPluginActivated(variable, value)
        end

        local setting = _RegisterProxy(category, variable, Settings.VarType.Boolean, name, Settings.Default.True, GetValue, SetValue)
        _CreateCheckbox(category, setting, L["settings:plugins_tooltip"])
    end

    _RegisterAddon(category)

    return category
end

local function openSettings()
    local category = registeredCategory or _GetCategory(params.core.name)
    if category then
        Settings.OpenToCategory(category:GetID())
    else
        view:Print("Settings category not found.")
    end
end

--- =========================================================
--- Overridable Methods
--- =========================================================

function control:OnEnable()
    -- Create minimap button
    view:CreateMinimapButton(model:GetMinimapButtonSettings())
    onCharacterLogin()
end

--- =========================================================
--- Event Callbacks
--- =========================================================

local function onAddOnLoaded(_, addonName)
    if addonName ~= ADDON_NAME then return end

    model:Init()
    view:Init()
    control:Init()
    control:Unsubscribe("ADDON_LOADED")
end

local function onPlayerLogin()
    model:Enable()
    view:Enable()
    control:Enable()
    params:UpdateCharLevel()
    params:UpdateCharFaction()
end

local function onSettingsLoaded()
    if _GetCategory(params.core.name) then return end

    local availablePlugins = getAvailablePlugins()
    if not availablePlugins then return end

    local activePlugins = loadActivePlugins(availablePlugins)

    registeredCategory = registerSettings(activePlugins)
    if registeredCategory then
        control:Trigger("BitForge.Plugins.RegisterSettings", registeredCategory)
        control:Subscribe("BitForge.Core.OpenSettings", openSettings)
    end
end

local function onPlayerLogout()
    model:Disable()
    view:Disable()
    control:Disable()
end

local function onPlayerLevelUp()
    if params:UpdateCharLevel() then
        control:Unsubscribe("PLAYER_LEVEL_UP")
    end
end

local function onUnitFaction()
    if params:UpdateCharFaction() then
        control:Unsubscribe("UNIT_FACTION")
    end
end

control:Subscribe("ADDON_LOADED", onAddOnLoaded)
control:Subscribe("PLAYER_LOGIN", onPlayerLogin)
control:Subscribe("PLAYER_LOGOUT", onPlayerLogout)
control:Subscribe("SETTINGS_LOADED", onSettingsLoaded)
control:Subscribe("PLAYER_LEVEL_UP", onPlayerLevelUp)
control:Subscribe("UNIT_FACTION", onUnitFaction, "player")

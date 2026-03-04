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
local _format = string.format
local _time = time

local _GetAddOnInfo = C_AddOns.GetAddOnInfo
local _GetNumAddOns = C_AddOns.GetNumAddOns
local _LoadAddOn = C_AddOns.LoadAddOn
local _IsAddOnLOD = C_AddOns.IsAddOnLoadOnDemand
local _GetCategory = Settings.GetCategory
local _RegisterCategory = Settings.RegisterVerticalLayoutCategory
local _CreateCheckbox = Settings.CreateCheckbox
local _CreateDropdown = Settings.CreateDropdown
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
        class     = params.character.class,
        lastSeen  = _time(),
    })
end

local function onCharacterLogin()
    local currentGUID  = _UnitGUID("player")
    local currentName  = _UnitName("player")
    local currentRealm = _GetRealmName()

    if not (currentGUID and currentName and currentRealm) then return end

    if not model:GetCharacters()[currentGUID] then
        local sameClassEntries = model:GetCharactersByClass(params.character.class, currentGUID)
        if sameClassEntries then
            control:ShowMigrationDialog(sameClassEntries, currentGUID, currentName, currentRealm)
            return
        end
    end

    updateCharacterInfo(currentGUID, currentName, currentRealm)

    local invalidList = model:GetInvalidCharacters(currentGUID)
    if invalidList then
        local threshold = model:GetLastSeenThreshold()
        view:Print(_format(L["notification:invalidCharacters"], #invalidList, threshold))
    end
end

function control:ShowMigrationDialog(matchList, guid, name, realm)
    local selectedGuid

    local finish = function()
        updateCharacterInfo(guid, name, realm)
        view:HideMigrationDialog()
    end

    local onSelectionChanged = function(newGuid)
        selectedGuid = newGuid
        view:UpdateMigrateButton(newGuid ~= nil)
    end

    local onSelect = function()
        if not selectedGuid then return end
        model:MigrateCharacter(selectedGuid, guid)
        finish()
    end

    local onSkip = finish

    view:ShowMigrationDialog(matchList, onSelect, onSkip, onSelectionChanged)
end

function control:ShowPurgeDialog(invalidList)
    local selectedGuids = {}
    local selectedCount = 0

    local onSelectionChanged = function(guid, checked)
        if checked then
            if not selectedGuids[guid] then
                selectedGuids[guid] = true
                selectedCount       = selectedCount + 1
            end
        else
            if selectedGuids[guid] then
                selectedGuids[guid] = nil
                selectedCount       = selectedCount - 1
            end
        end
        view:UpdatePurgeButton(selectedCount)
    end

    local onPurge = function()
        local guidList = {}
        for guid in pairs(selectedGuids) do
            guidList[#guidList + 1] = guid
        end
        model:DeleteCharacters(guidList)
        view:HideMigrationDialog()
        view:Print(_format(L["notification:purgeComplete"], #guidList))
    end

    local onKeepAll = function()
        view:HideMigrationDialog()
    end

    view:ShowPurgeDialog(invalidList, onPurge, onKeepAll, onSelectionChanged)
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

    --- Characters section
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["settings:characters_header"]))

    local thresholdDays = { 0, 30, 60, 90, 180, 365 }

    local function createThresholdOptions()
        local container = Settings.CreateControlTextContainer()
        for i, days in _ipairs(thresholdDays) do
            local label = days == 0 and L["settings:lastSeenThreshold_never"] or _format(L["settings:lastSeenThreshold_days"], days)
            container:Add(i, label)
        end
        return container:GetData()
    end

    local function getThresholdIndex()
        local current = model:GetLastSeenThreshold()
        for i, days in _ipairs(thresholdDays) do
            if days == current then return i end
        end
        return 1
    end

    local function setThresholdIndex(index)
        model:SetLastSeenThreshold(thresholdDays[index] or 0)
    end

    local thresholdSetting = _RegisterProxy(
        category,
        "BITFORGE_LAST_SEEN_THRESHOLD",
        Settings.VarType.Number,
        L["settings:lastSeenThreshold"],
        1,
        getThresholdIndex,
        setThresholdIndex
    )
    _CreateDropdown(category, thresholdSetting, createThresholdOptions, L["settings:lastSeenThreshold_tooltip"])

    layout:AddInitializer(CreateSettingsButtonInitializer(
        L["settings:purgeInvalidButton"],
        L["settings:purgeInvalidButton"],
        function()
            local guid        = _UnitGUID("player") --[[@as string]]
            local invalidList = model:GetInvalidCharacters(guid)
            if not invalidList then
                view:Print(L["notification:nothingToPurge"])
            else
                control:ShowPurgeDialog(invalidList)
            end
        end,
        L["settings:purgeInvalidButton_tooltip"],
        true
    ))

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

local function onMinimapMoved(_, angle)
    model:SetMinimapPos(angle)
end

control:Subscribe("ADDON_LOADED", onAddOnLoaded)
control:Subscribe("PLAYER_LOGIN", onPlayerLogin)
control:Subscribe("PLAYER_LOGOUT", onPlayerLogout)
control:Subscribe("SETTINGS_LOADED", onSettingsLoaded)
control:Subscribe("PLAYER_LEVEL_UP", onPlayerLevelUp)
control:Subscribe("UNIT_FACTION", onUnitFaction, "player")
control:Subscribe("BitForge.Core.MinimapMoved", onMinimapMoved)

--- =========================================================
--- Debug Commands
--- =========================================================

local DEBUG = true

if DEBUG then
    SLASH_BITFORGE1 = "/bitforge"
    SlashCmdList["BITFORGE"] = function(msg)
        local cmd = msg:match("^(%S+)") or ""
        cmd = cmd:lower()

        if cmd == "testmigration" then
            local guid     = _UnitGUID("player")
            local name     = _UnitName("player")
            local realm    = _GetRealmName()
            local fakeList = {
                { guid = "Player-0000-00000001", storedName = name .. "Alt1", storedRealm = realm, nameRealm = name .. "Alt1-" .. realm },
                { guid = "Player-0000-00000002", storedName = name .. "Alt2", storedRealm = realm, nameRealm = name .. "Alt2-" .. realm },
            }
            control:ShowMigrationDialog(fakeList, guid, name, realm)
        else
            view:Print("Debug commands: testmigration")
        end
    end
end

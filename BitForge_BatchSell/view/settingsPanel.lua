---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local CreateSettingsButtonInitializer = CreateSettingsButtonInitializer
local SettingsPanel = SettingsPanel

local enum = ns.enum
local model = ns.model
local locale = ns.locale
---@class BitForge.BatchSell.View
local view = ns.view

do
    ---@class BitForge.BatchSell.View.SettingsPanel
    local panel = {}

    StaticPopupDialogs["BATCHSELL_CONFIRM_RESET_LIST"] = {
        text = locale["listReset:confirm"],
        button1 = ACCEPT,
        button2 = CANCEL,
        OnAccept = function(self, data) data.callback() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    local function OnOpenRuleWindow()
        -- SettingsPanel is toplevel at HIGH and raises itself to the top of
        -- that strata on click, so a window shown from underneath it opens
        -- behind it. Blizzard_SettingsDefinitions_Frame/AdvancedOptions.lua's
        -- own ShowDesiredPanelFromSettingsPanel does the same before it shows
        -- Edit Mode or the Cooldown Manager.
        SettingsPanel:Close(true)
        view.ruleWindow.Toggle()
    end

    function panel.Init()
        local cat = BitForge.Settings.NewSubcategory(ADDON_NAME, locale["panel:batchSell"], locale)

        cat:AddExpandableSection(locale["section:general"], true)
        -- Named rather than "" like the reset buttons below: addSearchTags is
        -- true here, and being findable in settings search is why this entry
        -- point exists.
        cat:AddInitializer(CreateSettingsButtonInitializer("openRuleWindow",
            locale["settings:openRuleWindow"], OnOpenRuleWindow,
            locale["settings:openRuleWindowTooltip"], true))
        cat:AddCheckbox("limitBatch", model.GetLimitBatchTo12, model.SetLimitBatchTo12)

        cat:AddExpandableSection(locale["section:lists"], false)

        local function AddResetInitializer(labelKey, scope, status)
            local function OnClick()
                StaticPopup_Show("BATCHSELL_CONFIRM_RESET_LIST", nil, nil, {
                    callback = function() model.ClearList(scope, status) end,
                })
            end
            return CreateSettingsButtonInitializer("", locale[labelKey], OnClick, nil, false)
        end

        local SCOPE, STATUS = enum.LIST_SCOPE, enum.LIST_STATUS
        cat:AddInitializer(AddResetInitializer("listReset:warbandBlacklist", SCOPE.GLOBAL, STATUS.BLACKLIST))
        cat:AddInitializer(AddResetInitializer("listReset:warbandWhitelist", SCOPE.GLOBAL, STATUS.WHITELIST))
        cat:AddInitializer(AddResetInitializer("listReset:charBlacklist", SCOPE.CHAR, STATUS.BLACKLIST))
        cat:AddInitializer(AddResetInitializer("listReset:charWhitelist", SCOPE.CHAR, STATUS.WHITELIST))
    end

    view.settingsPanel = panel
end

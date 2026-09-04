---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...

local SettingsPanel = SettingsPanel

local model = ns.model
local enum = ns.enum
local locale = ns.locale
local control = ns.control
---@class BitForge.AzerothPrime.View
local view = ns.view

---@class BitForge.AzerothPrime.View.SettingsPanel
local settingsPanel = {}

StaticPopupDialogs["BITFORGE_AZEROTHPRIME_CONFIRM_RESET_LIST"] = {
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

local function OnSetOpenEnabled(value)
    model.SetOpenEnabled(value)
    control.openScanner.RequestScan()
end

local function OnSetButtonSize(value)
    model.SetButtonSize(value)
    view.button.ApplySize()
end

local function OnSetShowCount(value)
    model.SetShowCount(value)
    control.openScanner.RequestScan()
end

local function OnSetShowCooldown(value)
    model.SetShowCooldown(value)
    view.button.RefreshCooldown()
end

-- Wrapped rather than passed straight through: with the merchant window open,
-- a sell button left enabled after the module is switched off swallows the
-- click in seller.SellBatch's IsSellEnabled guard and looks broken.
-- merchantPanel.Refresh is itself the no-op guard here, same as
-- bankButton.SetIdle below -- it bails when the panel was never built or is
-- not on screen.
local function OnSetSellEnabled(value)
    model.SetSellEnabled(value)
    view.merchantPanel.Refresh()
end

-- Wrapped rather than passed straight through: with the bank open, a bank
-- button left enabled after the module is switched off swallows the click in
-- deposit.Run's IsBankEnabled guard and looks broken.
local function OnSetBankEnabled(value)
    model.SetBankEnabled(value)
    view.bankButton.SetIdle()
end

function settingsPanel.Init()
    local category = BitForge.Settings.NewSubcategory(ADDON_NAME, locale["panel:title"], locale)

    category:AddCheckbox("openEnabled", model.IsOpenEnabled, OnSetOpenEnabled)
    category:AddCheckbox("sellEnabled", model.IsSellEnabled, OnSetSellEnabled)
    category:AddCheckbox("bankEnabled", model.IsBankEnabled, OnSetBankEnabled)
    category:AddCheckbox("previewMoves", model.GetPreviewMoves, model.SetPreviewMoves)
    category:AddCheckbox("onlyWantedReagents", model.GetOnlyWantedReagents, model.SetOnlyWantedReagents)

    category:AddCheckbox("locked", model.GetLocked, model.SetLocked)
    category:AddSlider("buttonSize", model.GetButtonSize, OnSetButtonSize,
        enum.BUTTON_SIZE_MIN, enum.BUTTON_SIZE_MAX, enum.BUTTON_SIZE_STEP)
    category:AddCheckbox("showCount", model.GetShowCount, OnSetShowCount)
    category:AddCheckbox("showCooldown", model.GetShowCooldown, OnSetShowCooldown)
    category:AddInitializer(CreateSettingsButtonInitializer(
        "", locale["settings:resetPosition"], view.button.ResetPosition, nil, false))
    -- The blacklist list and the curation window cannot live inline in the
    -- settings panel: the vertical layout mixin returned by
    -- RegisterVerticalLayoutSubcategory accepts initializers only, and has no
    -- way to parent a raw frame into the list. A settings button opening a
    -- standalone window is this suite's established pattern instead.
    category:AddInitializer(CreateSettingsButtonInitializer(
        "", locale["settings:manageBlacklist"], view.blacklistFrame.Open, nil, false))
    category:AddInitializer(CreateSettingsButtonInitializer(
        "", locale["curation:open"], view.curationWindow.Toggle, nil, false))

    category:AddExpandableSection(locale["section:general"], true)
    -- Named rather than "" like the reset buttons below: addSearchTags is
    -- true here, and being findable in settings search is why this entry
    -- point exists.
    category:AddInitializer(CreateSettingsButtonInitializer("openRuleWindow",
        locale["settings:openRuleWindow"], OnOpenRuleWindow,
        locale["settings:openRuleWindowTooltip"], true))
    category:AddCheckbox("limitBatch", model.GetLimitBatchTo12, model.SetLimitBatchTo12)

    category:AddExpandableSection(locale["section:lists"], false)

    local function AddResetInitializer(labelKey, scope, status)
        local function OnClick()
            StaticPopup_Show("BITFORGE_AZEROTHPRIME_CONFIRM_RESET_LIST", nil, nil, {
                callback = function() model.overrides.ClearAllSell(scope, status) end,
            })
        end
        return CreateSettingsButtonInitializer("", locale[labelKey], OnClick, nil, false)
    end

    local SCOPE, STATUS = enum.LIST_SCOPE, enum.LIST_STATUS
    category:AddInitializer(AddResetInitializer("listReset:warbandBlacklist", SCOPE.GLOBAL, STATUS.BLACKLIST))
    category:AddInitializer(AddResetInitializer("listReset:warbandWhitelist", SCOPE.GLOBAL, STATUS.WHITELIST))
    category:AddInitializer(AddResetInitializer("listReset:charBlacklist", SCOPE.CHAR, STATUS.BLACKLIST))
    category:AddInitializer(AddResetInitializer("listReset:charWhitelist", SCOPE.CHAR, STATUS.WHITELIST))
end

view.settingsPanel = settingsPanel

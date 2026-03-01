--- @type string, ns_BB
local ADDON_NAME, ns = ...
local L = ns.locale
local model = ns.model --[[@as BB_Model]]
local view = ns.view --[[@as BB_View]]
--- @class BB_Control: BF_BaseControl
local control = ns.control

--- =========================================================
--- Caches
--- =========================================================

local _min = math.min

local _After = C_Timer.After
local _GetMoney = GetMoney
local _FetchDepositedMoney = C_Bank.FetchDepositedMoney
local _CanDepositMoney = C_Bank.CanDepositMoney
local _DepositMoney = C_Bank.DepositMoney
local _CanWithdrawMoney = C_Bank.CanWithdrawMoney
local _WithdrawMoney = C_Bank.WithdrawMoney
local _RegisterProxy = Settings.RegisterProxySetting
local _CreateCheckbox = Settings.CreateCheckbox
local _CreateDropdown = Settings.CreateDropdown
local _CreateSlider = Settings.CreateSlider

local ACCOUNT_BANK = Enum.BankType.Account
local ACCOUNT_BANKER = Enum.PlayerInteractionType.AccountBanker

--- =========================================================
--- Helpers
--- =========================================================

local function deposit(amount)
    if not _CanDepositMoney(ACCOUNT_BANK) then return end
    _DepositMoney(ACCOUNT_BANK, amount)

    return true
end

local function withdraw(amount)
    if not _CanWithdrawMoney(ACCOUNT_BANK) then return end
    _WithdrawMoney(ACCOUNT_BANK, amount)

    return true
end

local function setMoneyBalance()
    local currentGold = _GetMoney()
    local lowerBound, targetGold, upperBound = model:GetTargetGold()

    if currentGold < lowerBound then
        local delta = targetGold - currentGold
        local available = _FetchDepositedMoney(ACCOUNT_BANK)
        if available <= 0 then
            view:ShowError(L["message:noBalance"])
            return
        end

        local actualWithdraw = _min(delta, available)
        if withdraw(actualWithdraw) then
            view:ShowWithdraw(actualWithdraw)
        else
            view:ShowError(L["message:withdrawError"])
        end
    elseif currentGold > upperBound then
        local delta = currentGold - targetGold
        if deposit(delta) then
            view:ShowDeposit(delta)
        else
            view:ShowError(L["message:depositError"])
        end
    end
end


--- =========================================================
--- "Settings" Management
--- =========================================================



-- =========================================================
-- Event Handlers
-- =========================================================

local function onAddonLoaded()
    control:Init()
end

local function onInteraction(_, arg)
    if arg == ACCOUNT_BANKER then
        -- Delay by a frame to ensure C_Bank data is initialized
        _After(0.1, setMoneyBalance)
    end
end

local function onPluginsEnabled(_, pluginName)
    if pluginName ~= ADDON_NAME then return end

    control:Enable()
end

local registeredSettings = {}
--- @param coreControl BF_CoreControl
local function onRegisterSettings(coreControl, coreCategory)
    local category, layout = view:CreateCategory(L["setting:category"], coreCategory)

    --- title
    view:CreateSectionHeader(layout, L["setting:title"])

    --- setting for 'useGlobal'
    do
        local useGlobalSetting = _RegisterProxy(
            category,
            ADDON_NAME .. "_USE_GLOBAL",
            Settings.VarType.Boolean,
            L["setting:useGlobal"],
            Settings.Default.True,
            function() return model:GetUseGlobal() end,
            function(value) model:SetUseGlobal(value) end
        )
        registeredSettings[#registeredSettings + 1] = _CreateCheckbox(category, useGlobalSetting, L["setting:useGlobal_tooltip"])
    end

    --- setting for 'threshold'
    do
        local golds = { 1000, 5000, 10000, 20000, 50000, 100000 }
        local function getThreshHoldIndex()
            local threshold = model:GetThreshold() / 1000
            for i, gold in next, golds do
                if gold == threshold then
                    return i
                end
            end

            return 1 -- default to 1k if not found
        end

        local function setThresholdIndex(index)
            local gold = golds[index] or 1000
            model:SetThreshold(gold * 1000)
        end

        local thresholdSetting = _RegisterProxy(
            category,
            ADDON_NAME .. "_THRESHOLD",
            Settings.VarType.Number,
            L["ui:threshold_label"],
            1,
            getThreshHoldIndex,
            setThresholdIndex
        )
        registeredSettings[#registeredSettings + 1] = _CreateDropdown(category, thresholdSetting, golds, L["ui:threshold_label"] .. " (in thousands)")
    end

    --- setting for 'margin'
    do
        -- Enable checkbox proxy
        local function getUseMargin()
            return model:GetUseMargin()
        end

        local useMargin = _RegisterProxy(
            category,
            ADDON_NAME .. "_USE_MARGIN",
            Settings.VarType.Boolean,
            L["setting:enableMargin"],
            Settings.Default.True,
            getUseMargin,
            function(v) model:SetUseMargin(v) end
        )

        local marginRatio = _RegisterProxy(
            category,
            ADDON_NAME .. "_MARGIN_RATIO",
            Settings.VarType.Number,
            L["setting:marginRatio"],
            0,
            function() return model:GetMarginRatio() end,
            function(v) model:SetMarginRatio(v) end
        )
        local ratioOptions = Settings.CreateSliderOptions(0, 1, 0.05)
        ratioOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)

        local initializer = CreateSettingsCheckboxSliderInitializer(
            useMargin,
            L["setting:enableMargin"],
            L["setting:enableMargin_tooltip"],
            marginRatio,
            ratioOptions,
            L["setting:marginRatio"],
            L["setting:marginRatio_tooltip"]
        )
        layout:AddInitializer(initializer)
        registeredSettings[#registeredSettings + 1] = initializer
    end
end

EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, onAddonLoaded)

control:Subscribe("BitForge.Plugins.Enable", onPluginsEnabled)
control:Subscribe("BitForge.Core.RegisterSettings", onRegisterSettings)

--- =========================================================
--- Overridable Methods
--- =========================================================

function control:OnInit()
    model:Init()
    view:Init(ADDON_NAME)
end

function control:OnEnable()
    self:Subscribe("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", onInteraction)
end

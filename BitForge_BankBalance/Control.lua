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

local _upper = string.upper
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
    local function getUseGlobal()
        return model:GetUseGlobal()
    end
    local function setUseGlobal(value)
        model:SetUseGlobal(value)
    end

    local useGlobalSetting = _RegisterProxy(
        category,
        _upper(ADDON_NAME) .. "_USE_GLOBAL",
        Settings.VarType.Boolean,
        L["setting:useGlobal"],
        Settings.Default.True,
        getUseGlobal,
        setUseGlobal
    )
    _CreateCheckbox(category, useGlobalSetting, L["setting:useGlobal_tooltip"])

    --- setting for 'balance'
    local golds = { 1000, 5000, 10000, 50000, 100000 }
    local function createDesiredBalanceOptions()
        local container = Settings.CreateControlTextContainer()
        for i, gold in next, golds do
            container:Add(i, GetMoneyString(gold * 10000, true))
        end

        return container:GetData()
    end

    local function getBalanceIndex()
        local balance = model:GetDesiredBalance()
        for i, gold in next, golds do
            if gold == balance then
                return i
            end
        end

        return 1 -- default to 1k if not found
    end

    local function setBalanceIndex(index)
        local gold = golds[index] or 1000
        model:SetDesiredBalance(gold)
    end

    local balanceSetting = _RegisterProxy(
        category,
        _upper(ADDON_NAME) .. "_BALANCE",
        Settings.VarType.Number,
        L["setting:balance"],
        1,
        getBalanceIndex,
        setBalanceIndex
    )
    registeredSettings[#registeredSettings + 1] = balanceSetting
    _CreateDropdown(category, balanceSetting, createDesiredBalanceOptions, L["setting:balance_tooltip"])

    --- setting for 'margin'
    local function formatter(value)
        return string.format("%d%%", math.floor(value * 100 + 0.5))
    end

    local function getUseMargin()
        return model:GetUseMargin()
    end

    local useMarginSetting = _RegisterProxy(
        category,
        _upper(ADDON_NAME) .. "_USE_MARGIN",
        Settings.VarType.Boolean,
        L["setting:enableMargin"],
        Settings.Default.True,
        getUseMargin,
        function(v) model:SetUseMargin(v) end
    )
    registeredSettings[#registeredSettings + 1] = useMarginSetting

    local marginRatioSetting = _RegisterProxy(
        category,
        _upper(ADDON_NAME) .. "_MARGIN_RATIO",
        Settings.VarType.Number,
        L["setting:marginRatio"],
        0.05,
        function() return model:GetMarginRatio() end,
        function(v) model:SetMarginRatio(v) end
    )
    registeredSettings[#registeredSettings + 1] = marginRatioSetting

    local ratioOptions = Settings.CreateSliderOptions(0, 1, 0.05)
    ratioOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, formatter)

    local initializer = CreateSettingsCheckboxSliderInitializer(
        useMarginSetting,
        L["setting:enableMargin"],
        L["setting:enableMargin_tooltip"],
        marginRatioSetting,
        ratioOptions,
        L["setting:marginRatio"],
        L["setting:marginRatio_tooltip"]
    )
    layout:AddInitializer(initializer)

    useGlobalSetting:SetValueChangedCallback(function(_, value)
        model:SetUseGlobal(value)

        for _, s in ipairs(registeredSettings) do
            if s ~= useGlobalSetting then
                s:SetValue(s:GetValue())
            end
        end
    end)
end

EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, onAddonLoaded)

control:Subscribe("BitForge.Plugins.Enable", onPluginsEnabled)
control:Subscribe("BitForge.Plugins.RegisterSettings", onRegisterSettings)

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

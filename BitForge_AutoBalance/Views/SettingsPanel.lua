local ns = select(2, ...)
local E  = BitForge.Events

local format = string.format
local floor  = math.floor
local ipairs = ipairs

local Settings = Settings

local model = ns.Model
local L     = ns.L

ns:Subscribe(E.CORE_LOADED, function()
    local category = Settings.RegisterVerticalLayoutSubcategory(
        BitForge.settingsCategory, "AutoBalance")
    Settings.RegisterAddOnCategory(category)

    local balanceSetting = Settings.RegisterProxySetting(
        category, "BITFORGE_AUTOBALANCE_BALANCE",
        Settings.VarType.Number, L["settings:desiredBalance"], ns.DB_DEFAULTS.global.desiredBalance,
        function() return model.GetDesiredBalance() end,
        function(v) model.SetDesiredBalance(v) end)
    Settings.CreateDropdown(category, balanceSetting, function()
        local c = Settings.CreateControlTextContainer()
        for _, v in ipairs(ns.BALANCE_OPTIONS) do
            c:Add(v, GetMoneyString(v * ns.COPPER_PER_GOLD, true))
        end
        return c:GetData()
    end)

    local ratioSetting = Settings.RegisterProxySetting(
        category, "BITFORGE_AUTOBALANCE_RATIO",
        Settings.VarType.Number, L["settings:marginalRatio"], ns.DB_DEFAULTS.global.marginalRatio,
        function() return model.GetMarginalRatio() end,
        function(v) model.SetMarginalRatio(v) end)
    local sliderOpts = Settings.CreateSliderOptions(0, 0.5, 0.1)
    sliderOpts:SetLabelFormatter(
        MinimalSliderWithSteppersMixin.Label.Right,
        function(value)
            if value == 0 then return L["settings:always"] end
            return format("%d%%", floor(value * 100 + 0.5))
        end)
    Settings.CreateSlider(category, ratioSetting, sliderOpts, L["settings:marginalRatioTip"])

    local collectorSetting = Settings.RegisterProxySetting(
        category, "BITFORGE_AUTOBALANCE_COLLECTOR",
        Settings.VarType.String, L["settings:collectorCharacter"], ns.DB_DEFAULTS.global.collectorName,
        function() return model.GetCollectorName() end,
        function(v) model.SetCollectorName(v) end)
    Settings.CreateDropdown(category, collectorSetting, function()
        local c = Settings.CreateControlTextContainer()
        c:Add("", L["settings:none"])
        for _, name in ipairs(BitForge:GetKnownCharacters()) do
            c:Add(name, name)
        end
        return c:GetData()
    end)
end)

---@class BitForge.AutoBalance
---@field view BitForge.AutoBalance.View

---@type string, BitForge.AutoBalance
local ADDON_NAME, ns = ...
local format = string.format
local floor = math.floor
local ipairs = ipairs

local Settings = Settings
local GetMoneyString = GetMoneyString

---@class BitForge.AutoBalance.View
local view = ns.view
local model = ns.model
local L = ns.locale

local balanceSetting, ratioSetting

local function OnUseCharChanged(value)
    model.SetUseCharSettings(value)
    balanceSetting:SetValue(model.GetDesiredBalance())
    ratioSetting:SetValue(model.GetMarginalRatio())
end

local function BalanceOptions()
    local container = Settings.CreateControlTextContainer()
    for _, option in ipairs(ns.enum.BALANCE_OPTIONS) do
        container:Add(option, GetMoneyString(option * COPPER_PER_GOLD, true))
    end
    return container:GetData()
end

local function FormatRatio(value)
    if value == 0 then return L["settings:always"] end
    return format("%d%%", floor(value * 100 + 0.5))
end

local function CollectorOptions()
    local container = Settings.CreateControlTextContainer()
    container:Add("", L["settings:none"])
    for _, name in ipairs(BitForge:GetKnownCharacters()) do
        container:Add(name, name)
    end
    return container:GetData()
end

function view.Init()
    local cat = BitForge.Settings.NewSubcategory(ADDON_NAME, L["panel:autoBalance"], L)

    cat:AddCheckbox("useCharSettings", model.GetUseCharSettings, OnUseCharChanged)
    balanceSetting = cat:AddDropdown("desiredBalance", model.GetDesiredBalance, model.SetDesiredBalance, BalanceOptions)
    ratioSetting = cat:AddSlider("marginalRatio", model.GetMarginalRatio, model.SetMarginalRatio, 0, 0.5, 0.1, FormatRatio)
    cat:AddDropdown("collectorCharacter", model.GetCollectorName, model.SetCollectorName, CollectorOptions, Settings.VarType.String)
end

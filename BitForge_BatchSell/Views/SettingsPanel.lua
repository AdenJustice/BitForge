local ns = select(2, ...)
local E  = BitForge.Events

local ipairs   = ipairs
local tostring = tostring

local Settings = Settings

local model = ns.Model
local L     = ns.L

-- =========================================================
-- Static popup for list reset confirmation
-- =========================================================

StaticPopupDialogs["BATCHSELL_CONFIRM_RESET_LIST"] = {
    text         = L["listReset:confirm"],
    button1      = ACCEPT,
    button2      = CANCEL,
    OnAccept     = function(self, data) data.callback() end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

-- =========================================================
-- Helpers
-- =========================================================

local function AddCheckbox(category, labelKey, tipKey, getter, setter)
    local setting = Settings.RegisterAddOnSetting(
        category, L[labelKey], labelKey, Settings.VarType.Boolean, getter())
    Settings.CreateCheckbox(category, setting, L[tipKey])
    setting:SetValueChangedCallback(function(_, value) setter(value) end)
    return setting
end

local function AddDropdown(category, labelKey, tipKey, getter, setter, optionsFn)
    local setting = Settings.RegisterAddOnSetting(
        category, L[labelKey], labelKey, Settings.VarType.Number, getter())
    Settings.CreateDropdown(category, setting, optionsFn, L[tipKey])
    setting:SetValueChangedCallback(function(_, value) setter(value) end)
    return setting
end

local function AddSlider(category, labelKey, tipKey, getter, setter, min, max, step)
    local setting = Settings.RegisterAddOnSetting(
        category, L[labelKey], labelKey, Settings.VarType.Number, getter())
    local options = Settings.CreateSliderOptions(min, max, step)
    options:SetLabelFormatter(
        MinimalSliderWithSteppersMixin.Label.Right,
        function(value) return tostring(value) end)
    Settings.CreateSlider(category, setting, options, L[tipKey])
    setting:SetValueChangedCallback(function(_, value) setter(value) end)
    return setting
end

local function QualityOptions()
    return {
        { text = L["quality:poor"],     value = 0 },
        { text = L["quality:common"],   value = 1 },
        { text = L["quality:uncommon"], value = 2 },
        { text = L["quality:rare"],     value = 3 },
        { text = L["quality:epic"],     value = 4 },
    }
end

local EXPANSION_IDS = {
    { L["expansion:all"],                0 },
    { L["expansion:classic"],            1 },
    { L["expansion:burningCrusade"],     2 },
    { L["expansion:wrathOfTheLichKing"], 3 },
    { L["expansion:cataclysm"],          4 },
    { L["expansion:mistsOfPandaria"],    5 },
    { L["expansion:warlordsOfDraenor"],  6 },
    { L["expansion:legion"],             7 },
    { L["expansion:battleForAzeroth"],   8 },
    { L["expansion:shadowlands"],        9 },
    { L["expansion:dragonflight"],       10 },
    { L["expansion:theWarWithin"],       11 },
}

local function ExpansionOptions()
    local opts = {}
    for _, pair in ipairs(EXPANSION_IDS) do
        opts[#opts + 1] = { text = pair[1], value = pair[2] }
    end
    return opts
end

local function AddResetButton(parent, anchor, labelKey, list)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(200, 24)
    btn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    btn:SetText(L[labelKey])
    btn:SetScript("OnClick", function()
        StaticPopup_Show("BATCHSELL_CONFIRM_RESET_LIST", nil, nil, {
            callback = function() model.ClearList(list) end,
        })
    end)
    return btn
end

-- =========================================================
-- Registration  (deferred until BitForge is ready)
-- =========================================================

local function RegisterSettings()
    local category = Settings.RegisterVerticalLayoutCategory(L["panel:batchSell"])
    Settings.RegisterAddOnCategory(category)

    -- Sell behaviour
    AddCheckbox(category,
        "settings:sellJunk", "settings:sellJunkTip",
        model.GetSellJunk, model.SetSellJunk)

    -- Keep rules
    AddCheckbox(category,
        "settings:keepEquippable", "settings:keepEquippableTip",
        model.GetKeepEquippable, model.SetKeepEquippable)

    AddCheckbox(category,
        "settings:keepBindOnAccount", "settings:keepBindOnAccountTip",
        model.GetKeepBindOnAccount, model.SetKeepBindOnAccount)

    AddCheckbox(category,
        "settings:keepBindOnAccountPastExpac", "settings:keepBindOnAccountPastExpacTip",
        model.GetKeepBindOnAccountPastExpac, model.SetKeepBindOnAccountPastExpac)

    AddCheckbox(category,
        "settings:keepDisenchantables", "settings:keepDisenchantablesTip",
        model.GetKeepDisenchantables, model.SetKeepDisenchantables)

    AddCheckbox(category,
        "settings:keepDisenchantablesPastExpac", "settings:keepDisenchantablesPastExpacTip",
        model.GetKeepDisenchantablesPastExpac, model.SetKeepDisenchantablesPastExpac)

    -- Batch limit
    AddCheckbox(category,
        "settings:limitBatch", "settings:limitBatchTip",
        model.GetLimitBatchTo12, model.SetLimitBatchTo12)

    -- Quality threshold
    AddDropdown(category,
        "settings:qualityThreshold", "settings:qualityThresholdTip",
        model.GetQualityThreshold, model.SetQualityThreshold,
        QualityOptions)

    -- ilvl threshold
    AddSlider(category,
        "settings:ilvlThreshold", "settings:ilvlThresholdTip",
        model.GetIlvlThreshold, model.SetIlvlThreshold,
        -50, 0, 1)

    -- Expansion filter
    AddCheckbox(category,
        "settings:sellPastExpansion", "settings:sellPastExpansionTip",
        model.GetSellPastExpansion, model.SetSellPastExpansion)

    AddDropdown(category,
        "settings:expansionThreshold", "settings:expansionThresholdTip",
        model.GetExpansionThreshold, model.SetExpansionThreshold,
        ExpansionOptions)

    -- List reset buttons (rendered on the canvas below settings controls)
    -- These are layout-level elements; attach to the category layout frame after registration.
    local layout = category:GetLayout()
    if layout and layout.AddLayoutChildren then
        local container = CreateFrame("Frame", nil, layout)
        container:SetHeight(120)

        local anchor = container
        local btn1 = AddResetButton(container, anchor, "listReset:warbandBlacklist", "blacklist")
        btn1:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        local btn2 = AddResetButton(container, btn1, "listReset:warbandWhitelist", "whitelist")
        local btn3 = AddResetButton(container, btn2, "listReset:charBlacklist", "charBlacklist")
        local btn4 = AddResetButton(container, btn3, "listReset:charWhitelist", "charWhitelist")

        layout:AddLayoutChildren(container)
    end
end

ns:Subscribe(E.CORE_LOADED, RegisterSettings)

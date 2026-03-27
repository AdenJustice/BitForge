local ns = select(2, ...)
local E  = BitForge.Events

local Settings = Settings

local model = ns.Model
local L = ns.L

ns:Subscribe(E.CORE_LOADED, function()
    local category = Settings.RegisterVerticalLayoutSubcategory(
        BitForge.settingsCategory, L["settings:unitFramePanel"]
    )

    -- Helper: run setter then delegate post-toggle logic to the controller.
    local function OnToggle(setValue)
        return function(value)
            setValue(value)
            ns.OnSettingToggled()
        end
    end

    -- Unit Frames toggle
    local ufSetting = Settings.RegisterProxySetting(
        category,
        "UnitFramesEnabled",
        Settings.VarType.Boolean,
        L["settings:enableUnitFrames"],
        true,
        function() return model.GetUnitFramesEnabled() end,
        OnToggle(model.SetUnitFramesEnabled)
    )
    Settings.CreateCheckBox(category, ufSetting, L["settings:enableUnitFramesTooltip"])

    -- ClassPanel toggle
    local cpSetting = Settings.RegisterProxySetting(
        category,
        "ClassPanelEnabled",
        Settings.VarType.Boolean,
        L["settings:enableClassPanel"],
        true,
        function() return model.GetClassPanelEnabled() end,
        OnToggle(model.SetClassPanelEnabled)
    )
    Settings.CreateCheckBox(category, cpSetting, L["settings:enableClassPanelTooltip"])
end)

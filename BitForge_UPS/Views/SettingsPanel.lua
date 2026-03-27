local ns = select(2, ...)
local E = BitForge.Events

local Settings = Settings
local CreateFrame = CreateFrame

local model = ns.Model
local L = ns.L

ns:Subscribe(E.PLAYER_READY, function()
    local category      = Settings.RegisterVerticalLayoutSubcategory(
        BitForge.settingsCategory, L["panel:title"]
    )

    -- Enable UPS
    local enableSetting = Settings.RegisterAddOnSetting(
        category, L["settings:enabled"], "UPSEnabled",
        Settings.VarType.Boolean, model.IsEnabled()
    )
    Settings.CreateCheckbox(category, enableSetting)
    enableSetting:SetValueChangedCallback(function(_, value)
        model.SetEnabled(value)
    end)

    -- Pull from Guild Bank
    local pullSetting = Settings.RegisterAddOnSetting(
        category, L["settings:guildBankPull"], "UPSGuildBankPull",
        Settings.VarType.Boolean, model.GetGuildBankPull()
    )
    Settings.CreateCheckbox(category, pullSetting, L["settings:guildBankPullTip"])
    pullSetting:SetValueChangedCallback(function(_, value)
        model.SetGuildBankPull(value)
    end)

    -- Push to Guild Bank
    local pushSetting = Settings.RegisterAddOnSetting(
        category, L["settings:guildBankPush"], "UPSGuildBankPush",
        Settings.VarType.Boolean, model.GetGuildBankPush()
    )
    Settings.CreateCheckbox(category, pushSetting, L["settings:guildBankPushTip"])
    pushSetting:SetValueChangedCallback(function(_, value)
        model.SetGuildBankPush(value)
    end)

    -- Manage Assignments button
    local layout = category:GetLayout()
    if layout and layout.AddLayoutChildren then
        local container = CreateFrame("Frame", nil, layout)
        container:SetHeight(64)

        local manageBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        manageBtn:SetSize(200, 24)
        manageBtn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        manageBtn:SetText(L["settings:manageAssignments"])
        manageBtn:SetScript("OnClick", function()
            ns.AssignmentFrame.Open()
        end)

        local wizardBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
        wizardBtn:SetSize(200, 24)
        wizardBtn:SetPoint("TOPLEFT", manageBtn, "BOTTOMLEFT", 0, -4)
        wizardBtn:SetText(L["settings:setupWizard"])
        wizardBtn:SetScript("OnClick", function()
            ns.SetupDialog.Open(true) -- true = rerun mode
        end)

        layout:AddLayoutChildren(container)
    end
end)

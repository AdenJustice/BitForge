local ns = select(2, ...)
local E  = BitForge.Events

local format = string.format

local L = ns.L

ns.BankButton    = {}
local BankButton = ns.BankButton

local button
local badge

local function CreateButton()
    button = CreateFrame("Button", "UPSParcelButton", BankFrame, "UIPanelButtonTemplate")
    button:SetSize(80, 22)
    button:SetPoint("BOTTOMRIGHT", BankFrame, "BOTTOMRIGHT", -10, 10)
    button:SetText(L["btn:parcel"])
    button:SetScript("OnClick", function()
        ns.Controller.Resolve()
    end)

    -- Unclassified badge (red dot)
    badge = button:CreateTexture(nil, "OVERLAY")
    badge:SetSize(10, 10)
    badge:SetPoint("TOPRIGHT", button, "TOPRIGHT", 2, 2)
    badge:SetColorTexture(1, 0, 0, 1)
    badge:Hide()

    button:SetScript("OnEnter", function(self)
        if badge:IsShown() then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["msg:unclassified"], 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function UpdateEnabled()
    if not button then return end
    button:SetEnabled(ns.Controller.IsBankButtonEnabled())
end

function BankButton.SetIdle()
    if not button then return end
    button:SetText(L["btn:parcel"])
    UpdateEnabled()
end

function BankButton.SetParceling(count)
    if not button then return end
    button:SetText(format(L["btn:parceling"], count))
    button:SetEnabled(false)
end

function BankButton.ShowUnclassifiedBadge(show)
    if badge then
        if show then badge:Show() else badge:Hide() end
    end
end

ns:Subscribe(E.BANK_OPENED, function()
    if not button then
        CreateButton()
    end
    button:Show()
    UpdateEnabled()
    ns.Controller.CheckUnclassified()
end)

ns:Subscribe(E.BANK_CLOSED, function()
    if button then button:Hide() end
end)

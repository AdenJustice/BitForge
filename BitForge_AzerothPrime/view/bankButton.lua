---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...
local format = string.format
local CreateFrame = CreateFrame

local model = ns.model
local locale = ns.locale
local control = ns.control

---@class BitForge.AzerothPrime.View
local view = ns.view

local BUTTON_NAME = ADDON_NAME .. "DepositButton"

---@class BitForge.AzerothPrime.View.BankButton
local bankButton = {}

local button

local function onDepositClick()
    -- Resolved at click time. control/control.lua loads after this file, so
    -- capturing control.deposit at file-read time would capture nil.
    control.deposit.Run()
end

local function build()
    button = CreateFrame("Button", BUTTON_NAME, BankFrame, "UIPanelButtonTemplate")
    button:SetSize(100, 24)
    button:SetPoint("BOTTOMRIGHT", BankFrame, "BOTTOMRIGHT", -10, 10)
    button:SetText(locale["btn:deposit"])
    button:SetScript("OnClick", onDepositClick)
end

function bankButton.SetIdle()
    if not button then return end
    button:SetText(locale["btn:deposit"])
    button:SetEnabled(model.IsBankEnabled())
end

---@param count number  moves completed so far
function bankButton.SetWorking(count)
    if not button then return end
    button:SetText(format(locale["btn:depositing"], count))
    button:SetEnabled(false)
end

function bankButton.OnBankOpened()
    if not button then build() end
    button:Show()
    bankButton.SetIdle()
end

function bankButton.OnBankClosed()
    if button then button:Hide() end
end

view.bankButton = bankButton

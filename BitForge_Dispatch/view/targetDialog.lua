---@type string, BitForge.Dispatch
local ADDON_NAME, ns = ...

local format = string.format
local tonumber = tonumber
local tostring = tostring

local CreateFrame = CreateFrame
local tinsert = table.insert

local UI = BitForge.UI
local model = ns.model
local locale = ns.locale

---@class BitForge.Dispatch.View
local view = ns.view

---@class BitForge.Dispatch.View.TargetDialog
local targetDialog = {}

-- The title bar UI.CreateFrame draws is 32px tall (APIs/UI/Templates/Frame.lua),
-- so anything anchored below it starts at -32.
local TITLE_BAR_HEIGHT = 32

local TARGET_GLOBAL_NAME = ADDON_NAME .. "TargetDialog"

local targetFrame
local pendingTargetAccept

local function onTargetAccept()
    local accept = pendingTargetAccept
    pendingTargetAccept = nil

    -- tonumber rather than a pattern: the box accepts whatever the player
    -- types, and a blank or unparseable entry means "no limit", which is the
    -- safe reading -- it takes the whole stack, the behaviour the item already
    -- had before anyone opened this dialog.
    local value = tonumber(targetFrame.input:GetText())
    if value and value < 1 then value = nil end

    targetFrame:Hide()
    if accept then accept(value) end
end

local function onTargetHide()
    pendingTargetAccept = nil
end

local function buildTargetDialog()
    local frame = UI.CreateFrame(UIParent, locale["target:title"])
    frame:SetSize(300, 150)
    frame:SetPoint("CENTER")
    -- Above the curation window, which is what opened it and which stays up
    -- underneath so the row being edited remains visible.
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:EnableMouse(true)
    frame:SetScript("OnHide", onTargetHide)

    _G[TARGET_GLOBAL_NAME] = frame
    tinsert(UISpecialFrames, TARGET_GLOBAL_NAME)

    local prompt = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    prompt:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -(TITLE_BAR_HEIGHT + 8))
    prompt:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -(TITLE_BAR_HEIGHT + 8))
    prompt:SetJustifyH("LEFT")
    prompt:SetWordWrap(true)
    frame.prompt = prompt

    local input = UI.CreateEditBox(frame)
    input:SetSize(120, 24)
    input:SetPoint("TOP", prompt, "BOTTOM", 0, -12)
    input:SetNumeric(true)
    input:SetScript("OnEnterPressed", onTargetAccept)
    input:SetScript("OnEscapePressed", function() frame:Hide() end)
    frame.input = input

    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(90, 24)
    cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    cancelButton:SetText(locale["btn:cancel"])
    cancelButton:SetScript("OnClick", function() frame:Hide() end)

    local acceptButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    acceptButton:SetSize(90, 24)
    acceptButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    acceptButton:SetText(locale["btn:confirm"])
    acceptButton:SetScript("OnClick", onTargetAccept)

    frame:Hide()
    return frame
end

--- Asks for a target quantity. onAccept receives a number, or nil for no limit.
---@param itemID number
---@param itemName string
---@param onAccept fun(target: number|nil)
function targetDialog.Show(itemID, itemName, onAccept)
    if not targetFrame then targetFrame = buildTargetDialog() end

    pendingTargetAccept = onAccept
    targetFrame.prompt:SetText(format(locale["target:prompt"], itemName))
    -- Seeded with the current target so raising 20 to 25 is an edit rather than
    -- a re-entry, and so the dialog reports what is set before it changes it.
    targetFrame.input:SetText(tostring(model.overrides.GetTarget(itemID) or ""))
    targetFrame:Show()
    targetFrame.input:SetFocus()
end

view.targetDialog = targetDialog

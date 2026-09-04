---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...

local format = string.format
local ipairs = ipairs
local tinsert = table.insert
local tostring = tostring

local CreateFrame = CreateFrame
local C_Item = C_Item
local CreateDataProvider = CreateDataProvider
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local PixelUtil = PixelUtil
local ScrollUtil = ScrollUtil

local UI = BitForge.UI
local enum = ns.enum
local model = ns.model
local locale = ns.locale

---@class BitForge.AzerothPrime.View
local view = ns.view

---@class BitForge.AzerothPrime.View.PreviewDialog
local previewDialog = {}

local ROW_HEIGHT = 24

-- The title bar UI.CreateFrame draws is 32px tall
-- (Libs/LibBitForgeUI/Templates/Frame.lua), so anything anchored below it
-- starts at -32.
local TITLE_BAR_HEIGHT = 32

-- UISpecialFrames closes frames by looking their name up in _G, so the dialog
-- needs a global name to answer to ESC.
local DIALOG_GLOBAL_NAME = ADDON_NAME .. "PreviewDialog"

local dialog
local pendingPlan
local pendingConfirm

--- Which of the three directions a descriptor travels.
---
--- The reclaim pass and the deposit pass share one dialog, so the row has to
--- say which it is: "to your bank" from your own bags and "to your bank" out of
--- shared storage mean different things to a player deciding whether to confirm.
---@param descriptor table
---@return string
local function directionText(descriptor)
    if descriptor.destination == enum.DESTINATION.PRIVATE then
        return descriptor.fromWarband
            and locale["preview:reclaim"]
            or locale["preview:toPrivate"]
    end

    return locale["preview:toWarband"]
end

local function initRow(row, elementData)
    if not row.icon then
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)

        row.label = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.label:SetJustifyH("LEFT")

        row.destination = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        row.destination:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        row.destination:SetJustifyH("RIGHT")
    end

    row.icon:SetTexture(C_Item.GetItemIconByID(elementData.itemID))
    row.label:SetText(format("%s x%d",
        C_Item.GetItemNameByID(elementData.itemID) or tostring(elementData.itemID),
        elementData.count))
    row.destination:SetText(directionText(elementData))
end

local function onConfirmClick()
    local plan, confirm = pendingPlan, pendingConfirm
    pendingPlan, pendingConfirm = nil, nil

    -- Applied here, not on the checkbox's own click: ticking the box and then
    -- cancelling is the natural "actually, never mind" gesture, and it must not
    -- leave the confirmation gate switched off for every future deposit.
    if dialog.dontAsk:GetChecked() then
        model.SetPreviewMoves(false)
    end

    dialog:Hide()
    if confirm then confirm(plan) end
end

local function onCancelClick()
    dialog:Hide()
end

--- Also runs when ESC closes the dialog through UISpecialFrames, and when the
--- bank closes underneath it. Dropping the plan is what every one of those means.
local function onDialogHide()
    pendingPlan, pendingConfirm = nil, nil
end

local function buildDialog()
    local frame = UI.CreateFrame(UIParent, locale["preview:title"])
    frame:SetSize(360, 320)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnHide", onDialogHide)

    _G[DIALOG_GLOBAL_NAME] = frame
    tinsert(UISpecialFrames, DIALOG_GLOBAL_NAME)

    local summary = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
    summary:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -(TITLE_BAR_HEIGHT + 4))
    summary:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -(TITLE_BAR_HEIGHT + 4))
    summary:SetJustifyH("LEFT")
    frame.summary = summary

    local buttonRow = CreateFrame("Frame", nil, frame)
    PixelUtil.SetHeight(buttonRow, 28, 1)
    buttonRow:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
    buttonRow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 8)

    local cancelButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    cancelButton:SetSize(90, 24)
    cancelButton:SetPoint("LEFT", buttonRow, "LEFT", 0, 0)
    cancelButton:SetText(locale["btn:cancel"])
    cancelButton:SetScript("OnClick", onCancelClick)

    local confirmButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    confirmButton:SetSize(90, 24)
    confirmButton:SetPoint("RIGHT", buttonRow, "RIGHT", 0, 0)
    confirmButton:SetText(locale["btn:confirm"])
    confirmButton:SetScript("OnClick", onConfirmClick)

    local dontAsk = UI.CreateCheckButton(nil, frame, locale["preview:dontAskAgain"])
    dontAsk:SetPoint("BOTTOMLEFT", buttonRow, "TOPLEFT", 0, 6)
    frame.dontAsk = dontAsk

    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

    scrollBox:SetPoint("TOPLEFT", summary, "BOTTOMLEFT", 0, -6)
    scrollBox:SetPoint("BOTTOMRIGHT", dontAsk, "TOPRIGHT", -20, 6)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(ROW_HEIGHT)
    scrollView:SetElementInitializer("Frame", initRow)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

    -- No data provider is seeded here: Show builds one from the plan and sets it
    -- on every call, so anything installed at build time is replaced unread.
    frame.scrollBox = scrollBox

    frame:Hide()
    return frame
end

--- Shows the plan for confirmation. onConfirm receives the plan; cancelling
--- calls nothing and moves nothing.
---@param plan table
---@param onConfirm fun(plan: table)
function previewDialog.Show(plan, onConfirm)
    if not dialog then dialog = buildDialog() end

    pendingPlan = plan
    pendingConfirm = onConfirm

    local items = 0
    for _, descriptor in ipairs(plan) do
        items = items + descriptor.count
    end
    dialog.summary:SetText(format(locale["preview:summary"], items, #plan))

    dialog.dontAsk:SetChecked(false)

    local provider = CreateDataProvider()
    for _, descriptor in ipairs(plan) do
        provider:Insert(descriptor)
    end
    dialog.dataProvider = provider
    dialog.scrollBox:SetDataProvider(provider)

    dialog:Show()
end

--- Closes the dialog and drops the plan it was holding. Called when the bank
--- closes: a preview left on screen after the player walks away can only confirm
--- moves against slots that have since changed.
function previewDialog.Hide()
    if dialog then dialog:Hide() end
end

view.previewDialog = previewDialog

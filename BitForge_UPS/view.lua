---@class BitForge.UPS
---@field view BitForge.UPS.View

---@type string, BitForge.UPS
local ADDON_NAME, ns = ...

local format = string.format
local ipairs = ipairs
local match = string.match
local tinsert = table.insert
local tconcat = table.concat
local tonumber = tonumber
local tostring = tostring

local CreateFrame = CreateFrame
local C_Item = C_Item
local CreateDataProvider = CreateDataProvider
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local CreateSettingsButtonInitializer = CreateSettingsButtonInitializer
local GameTooltip = GameTooltip
local MenuUtil = MenuUtil
local PixelUtil = PixelUtil
local ScrollUtil = ScrollUtil

local UI = BitForge.UI
local enum = ns.enum
local model = ns.model
local locale = ns.locale
local control = ns.control

---@class BitForge.UPS.View
local view = ns.view

-- ================================================================================
-- BankButton
-- ================================================================================

---@class BitForge.UPS.View.BankButton
local bankButton = {}

local button

local function onDepositClick()
    -- Resolved at click time. control.lua loads after this file, so capturing
    -- control.deposit at file-read time would capture nil.
    control.deposit.Run()
end

local function build()
    button = CreateFrame("Button", "BitForgeUPSDepositButton", BankFrame, "UIPanelButtonTemplate")
    button:SetSize(100, 24)
    button:SetPoint("BOTTOMRIGHT", BankFrame, "BOTTOMRIGHT", -10, 10)
    button:SetText(locale["btn:deposit"])
    button:SetScript("OnClick", onDepositClick)
end

--- Restores the resting label and re-enables the button.
function bankButton.SetIdle()
    if not button then return end
    button:SetText(locale["btn:deposit"])
    button:SetEnabled(model.IsEnabled())
end

--- Shows progress and locks the button for the duration of a run.
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

-- ================================================================================
-- PreviewDialog
-- ================================================================================

---@class BitForge.UPS.View.PreviewDialog
local previewDialog = {}

local ROW_HEIGHT = 24

-- The title bar UI.CreateFrame draws is 32px tall (APIs/UI/Templates/Frame.lua),
-- so anything anchored below it starts at -32.
local TITLE_BAR_HEIGHT = 32

-- UISpecialFrames closes frames by looking their name up in _G, so the dialog
-- needs a global name to answer to ESC.
local DIALOG_GLOBAL_NAME = "BitForgeUPSPreviewDialog"

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
    -- Discards the plan without touching an item.
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

-- ================================================================================
-- TargetDialog
-- ================================================================================

---@class BitForge.UPS.View.TargetDialog
local targetDialog = {}

local TARGET_GLOBAL_NAME = "BitForgeUPSTargetDialog"

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
    targetFrame.input:SetText(tostring(model.GetTarget(itemID) or ""))
    targetFrame:Show()
    targetFrame.input:SetFocus()
end

view.targetDialog = targetDialog

-- ================================================================================
-- CurationWindow
-- ================================================================================

---@class BitForge.UPS.View.CurationWindow
local curationWindow = {}

local CURATION_WIDTH = 660
local CURATION_HEIGHT = 480
local CURATION_ROW_HEIGHT = 22
local CURATION_PADDING = 8
local CURATION_CONTROL_HEIGHT = 24

-- Fixed columns, measured from the right edge inward, so the name column takes
-- whatever is left and stays readable at the window's fixed width.
local COLUMN_DESTINATION = 120
local COLUMN_HOLDERS = 130
local COLUMN_KIND = 110

-- Two lines of wrapped banner text, or a hairline when there is nothing to say.
-- The scroll box anchors to the banner frame, so it has to have a height either
-- way rather than being hidden.
local BANNER_HEIGHT = 30
local BANNER_HEIGHT_EMPTY = 1

local CURATION_GLOBAL_NAME = "BitForgeUPSCurationWindow"

local DESTINATION = enum.DESTINATION

local curationFrame
local ownedCache = {}
local activeSourceName

-- nil in any field means "no filter". Persisted for the session only: a filter
-- is a way of finding one item, not a setting.
local filters = { destination = nil, classID = nil, search = nil }

--- The character half of a "Name-Realm" key. Realms are long and identical
--- across the account, so a row that spelled them out would spend its whole
--- holders column saying the same thing.
---@param charKey string
---@return string
local function shortCharacterName(charKey)
    return match(charKey, "^([^-]+)") or charKey
end

---@param row table
---@return string
local function holderText(row)
    local count = #row.holders
    if count == 0 then return "" end

    if count == 1 then
        return format("%s (%d)", shortCharacterName(row.holders[1].charKey), row.holders[1].count)
    end

    -- The full breakdown is in the tooltip; the column only has to say "more
    -- than one, and here is the first".
    return format("%s +%d", shortCharacterName(row.holders[1].charKey), count - 1)
end

--- The destination column's text.
---
--- For a private row this names only the *current* owners, unlike the Owners
--- submenu, which lists every known character. The row reports state and the
--- menu offers a choice, and the two want opposite lists.
---@param row table
---@return string
local function destinationText(row)
    local text

    if row.destination == DESTINATION.WARBAND then
        text = locale["dest:warband"]
    elseif row.destination == DESTINATION.PRIVATE then
        if #row.owners > 0 then
            local names = {}
            for _, charKey in ipairs(row.owners) do
                names[#names + 1] = shortCharacterName(charKey)
            end
            text = format(locale["dest:privateOwned"], tconcat(names, ", "))
        else
            text = locale["dest:private"]
        end

        if row.target then
            text = text .. " " .. format(locale["curation:targetSuffix"], row.target)
        end
    else
        text = locale["dest:ignore"]
    end

    if row.isOverride then
        return enum.COLOR.OVERRIDE:WrapTextInColorCode(text)
    end

    return text
end

local function onCurationRowMouseDown(row, button)
    if button ~= "RightButton" then return end

    local data = row._data
    if not data then return end

    local itemID = data.itemID

    -- Built on demand for one row and discarded. Per-row destination widgets in
    -- a recycled WowScrollBoxList element would mean re-binding controls on
    -- every scroll.
    MenuUtil.CreateContextMenu(row, function(_, rootDescription)
        rootDescription:CreateTitle(data.name)

        -- The radio reflects the resolved destination rather than the stored
        -- override, so exactly one is always checked. A menu that opened with
        -- nothing selected -- which is what the override alone would give for
        -- almost every row -- reads as broken.
        local function isSelected(destination)
            return model.Resolve(itemID) == destination
        end

        local function setSelected(destination)
            model.SetDestination(itemID, destination)
            curationWindow.Refresh()
        end

        rootDescription:CreateRadio(locale["dest:warband"], isSelected, setSelected,
            DESTINATION.WARBAND)
        rootDescription:CreateRadio(locale["dest:private"], isSelected, setSelected,
            DESTINATION.PRIVATE)
        rootDescription:CreateRadio(locale["dest:ignore"], isSelected, setSelected,
            DESTINATION.IGNORE)

        -- Owners and targets only mean anything for a private item. Offering
        -- them on a warband row would be offering a setting that silently does
        -- nothing.
        if model.Resolve(itemID) == DESTINATION.PRIVATE then
            rootDescription:CreateDivider()

            -- Every known character, not only the assigned ones: listing only
            -- the assigned ones would make the set impossible to grow. The keys
            -- come from the core rather than from an adapter, because an owner
            -- key that can never equal GetCurrentCharacter() strands the item
            -- in shared storage with nobody entitled to reclaim it.
            local ownersMenu = rootDescription:CreateButton(locale["menu:owners"])
            for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
                local owner = charKey
                ownersMenu:CreateCheckbox(shortCharacterName(owner),
                    function() return model.IsOwner(itemID, owner) end,
                    function()
                        model.ToggleOwner(itemID, owner)
                        curationWindow.Refresh()
                    end)
            end

            local function isTarget(value) return model.GetTarget(itemID) == value end

            local function setTarget(value)
                model.SetTarget(itemID, value)
                curationWindow.Refresh()
            end

            local targetMenu = rootDescription:CreateButton(locale["menu:target"])
            targetMenu:CreateRadio(locale["menu:targetNone"], isTarget, setTarget, nil)
            for _, amount in ipairs(enum.TARGET_PRESETS) do
                targetMenu:CreateRadio(tostring(amount), isTarget, setTarget, amount)
            end
            targetMenu:CreateButton(locale["menu:targetOther"], function()
                view.targetDialog.Show(itemID, data.name, setTarget)
            end)
        end

        rootDescription:CreateDivider()

        -- Redundant with picking the rule's own answer, and kept anyway: it is
        -- the only phrasing that says "stop deciding this for me" without the
        -- user having to know what the rule would decide.
        rootDescription:CreateButton(locale["menu:resetToDefault"], function()
            model.ClearOverride(itemID)
            curationWindow.Refresh()
        end)
    end)
end

local function onCurationRowEnter(row)
    local data = row._data
    if not data then return end

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(data.itemID)

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(locale["curation:heldBy"], 1, 1, 1)
    for _, holder in ipairs(data.holders) do
        GameTooltip:AddDoubleLine(holder.charKey, holder.count, 0.8, 0.8, 0.8, 1, 1, 1)
    end

    -- What "your bank" actually means for this row, including who may claim it
    -- when nobody has been named. The destination column has room for the owner
    -- names but not for the rule.
    if data.destination == DESTINATION.PRIVATE then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(locale["curation:privateTooltip"], 1, 1, 1, true)
    end

    if data.isOverride then
        GameTooltip:AddLine(" ")
        local color = enum.COLOR.OVERRIDE
        GameTooltip:AddLine(locale["curation:overrideTooltip"], color.r, color.g, color.b, true)
    end

    GameTooltip:Show()
end

local function onCurationRowLeave()
    GameTooltip:Hide()
end

local function initCurationRow(row, data)
    if not row.icon then
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        PixelUtil.SetPoint(row.icon, "LEFT", row, "LEFT", 4, 0)

        row.destination = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.destination, "RIGHT", row, "RIGHT", -4, 0)
        row.destination:SetWidth(COLUMN_DESTINATION)
        row.destination:SetJustifyH("RIGHT")

        row.holders = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.holders, "RIGHT", row.destination, "LEFT", -6, 0)
        row.holders:SetWidth(COLUMN_HOLDERS)
        row.holders:SetJustifyH("RIGHT")

        row.kind = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.kind, "RIGHT", row.holders, "LEFT", -6, 0)
        row.kind:SetWidth(COLUMN_KIND)
        row.kind:SetJustifyH("RIGHT")

        row.label = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.label, "LEFT", row.icon, "RIGHT", 6, 0)
        PixelUtil.SetPoint(row.label, "RIGHT", row.kind, "LEFT", -6, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)

        -- Bare Frame elements take no mouse input, so without this neither the
        -- context menu nor the tooltip would ever fire.
        row:EnableMouse(true)
        row:SetScript("OnMouseDown", onCurationRowMouseDown)
        row:SetScript("OnEnter", onCurationRowEnter)
        row:SetScript("OnLeave", onCurationRowLeave)
    end

    row._data = data
    row.icon:SetTexture(data.icon or C_Item.GetItemIconByID(data.itemID))
    row.label:SetText(data.name)
    row.kind:SetText(data.subTypeName or data.className or "")
    row.holders:SetText(holderText(data))
    row.destination:SetText(destinationText(data))
end

local function buildCurationWindow()
    local frame = UI.CreateFrame(UIParent, locale["curation:title"])
    frame:SetSize(CURATION_WIDTH, CURATION_HEIGHT)
    frame:SetPoint("CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    _G[CURATION_GLOBAL_NAME] = frame
    tinsert(UISpecialFrames, CURATION_GLOBAL_NAME)

    -- UI.CreateFrame draws a title bar but no close affordance, and this window
    -- has no Cancel button to double as one. Without this the only way out is
    -- ESC, which the search box swallows on its first press.
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() curationWindow.Hide() end)

    -- Filter row
    local search = UI.CreateEditBox(frame)
    search:SetSize(200, CURATION_CONTROL_HEIGHT)
    PixelUtil.SetPoint(search, "TOPLEFT", frame, "TOPLEFT",
        CURATION_PADDING, -(TITLE_BAR_HEIGHT + CURATION_PADDING))
    -- SetScript rather than overriding EditBoxMixin.OnTextChanged: the mixin
    -- binds the function value at OnLoad time, so a later reassignment of the
    -- method would never be seen.
    search:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        filters.search = text ~= "" and text or nil
        curationWindow.Refresh()
    end)
    frame.search = search

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    searchLabel:SetPoint("BOTTOMLEFT", search, "TOPLEFT", 2, 2)
    searchLabel:SetText(locale["curation:search"])

    local destinationFilter = UI.CreateDropdown(frame, locale["curation:filterDestination"])
    destinationFilter:SetSize(170, CURATION_CONTROL_HEIGHT)
    PixelUtil.SetPoint(destinationFilter, "LEFT", search, "RIGHT", 6, 0)
    destinationFilter:SetupMenu(function(dropdown, rootDescription)
        local options = {
            { value = nil, label = locale["curation:filterDestination"] },
            { value = DESTINATION.WARBAND, label = locale["dest:warband"] },
            { value = DESTINATION.PRIVATE, label = locale["dest:private"] },
            { value = DESTINATION.IGNORE, label = locale["dest:ignore"] },
        }

        for _, option in ipairs(options) do
            local value, label = option.value, option.label
            rootDescription:CreateRadio(label,
                function() return filters.destination == value end,
                function()
                    filters.destination = value
                    dropdown.Label:SetText(label)
                    curationWindow.Refresh()
                end)
        end
    end)
    frame.destinationFilter = destinationFilter

    local classFilter = UI.CreateDropdown(frame, locale["curation:filterClass"])
    classFilter:SetSize(170, CURATION_CONTROL_HEIGHT)
    PixelUtil.SetPoint(classFilter, "LEFT", destinationFilter, "RIGHT", 6, 0)
    frame.classFilter = classFilter

    -- Source and count line
    local sourceLabel = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    sourceLabel:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -6)
    sourceLabel:SetJustifyH("LEFT")
    frame.sourceLabel = sourceLabel

    local countLabel = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    countLabel:SetPoint("TOPRIGHT", classFilter, "BOTTOMRIGHT", 0, -6)
    countLabel:SetJustifyH("RIGHT")
    frame.countLabel = countLabel

    -- Unscanned-character banner. A frame rather than a bare FontString so the
    -- scroll box has something with a stable height to anchor to whether or not
    -- there is anything to warn about.
    local bannerFrame = CreateFrame("Frame", nil, frame)
    bannerFrame:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -4)
    bannerFrame:SetPoint("TOPRIGHT", countLabel, "BOTTOMRIGHT", 0, -4)
    PixelUtil.SetHeight(bannerFrame, BANNER_HEIGHT_EMPTY, 1)

    local banner = bannerFrame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    banner:SetAllPoints(bannerFrame)
    banner:SetJustifyH("LEFT")
    banner:SetJustifyV("TOP")
    banner:SetWordWrap(true)
    banner:SetTextColor(enum.COLOR.OVERRIDE:GetRGB())
    frame.bannerFrame = bannerFrame
    frame.banner = banner

    -- Row list
    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

    scrollBox:SetPoint("TOPLEFT", bannerFrame, "BOTTOMLEFT", 0, -6)
    scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
        -(CURATION_PADDING + 20), CURATION_PADDING)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(CURATION_ROW_HEIGHT)
    scrollView:SetElementInitializer("Frame", initCurationRow)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
    frame.scrollBox = scrollBox

    frame:Hide()
    return frame
end

--- Rebuilds the class filter's options from what the account actually owns.
---
--- Derived from the owned table rather than from Enum.ItemClass: a filter
--- listing every class in the game when the account holds items in three is a
--- list of dead ends.
local function refreshClassFilter()
    local classes = model.GetOwnedClasses(ownedCache)
    local dropdown = curationFrame.classFilter

    dropdown:SetupMenu(function(_, rootDescription)
        local anyLabel = locale["curation:filterClass"]
        rootDescription:CreateRadio(anyLabel,
            function() return filters.classID == nil end,
            function()
                filters.classID = nil
                dropdown.Label:SetText(anyLabel)
                curationWindow.Refresh()
            end)

        for _, class in ipairs(classes) do
            local classID, name = class.classID, class.name
            rootDescription:CreateRadio(name,
                function() return filters.classID == classID end,
                function()
                    filters.classID = classID
                    dropdown.Label:SetText(name)
                    curationWindow.Refresh()
                end)
        end
    end)

    -- A class the user had filtered on can vanish when the source changes --
    -- closing the bank, for one. Leaving the filter set would show an empty
    -- window with no visible reason.
    if filters.classID then
        local stillPresent = false
        for _, class in ipairs(classes) do
            if class.classID == filters.classID then stillPresent = true end
        end
        if not stillPresent then
            filters.classID = nil
            dropdown.Label:SetText(locale["curation:filterClass"])
        end
    end
end

--- Re-applies the filters and re-resolves every destination against the current
--- overrides, without re-reading the source. This is what a menu click and a
--- keystroke in the search box both run.
function curationWindow.Refresh()
    if not curationFrame then return end

    local unscanned = model.GetUnscannedCharacters()
    if #unscanned > 0 then
        curationFrame.banner:SetText(format(locale["curation:unscanned"],
            tconcat(unscanned, ", ")))
        PixelUtil.SetHeight(curationFrame.bannerFrame, BANNER_HEIGHT, 1)
    else
        curationFrame.banner:SetText("")
        PixelUtil.SetHeight(curationFrame.bannerFrame, BANNER_HEIGHT_EMPTY, 1)
    end

    local rows = model.BuildCurationRows(ownedCache, filters)
    curationFrame.countLabel:SetText(format(locale["curation:count"], #rows))

    local provider = CreateDataProvider()
    for _, row in ipairs(rows) do
        provider:Insert(row)
    end
    curationFrame.scrollBox:SetDataProvider(provider)
end

--- Re-reads the active source, then refreshes.
---
--- Separate from Refresh because a source read walks every container the
--- adapter can see, and typing in the search box must not do that per keystroke.
function curationWindow.Reload()
    -- Shown, not merely built: a source read walks every container the adapter
    -- can see, and the bank events below fire whether or not this window is up.
    if not curationFrame or not curationFrame:IsShown() then return end

    ownedCache, activeSourceName = control.adapters.GetOwned()

    -- The built-in source is the only one whose name is not an addon's, so it is
    -- the only one that needs translating; every other name is a proper noun.
    local displayName = activeSourceName == "builtin"
        and locale["curation:sourceBuiltIn"]
        or activeSourceName
    curationFrame.sourceLabel:SetText(format(locale["curation:source"], displayName))

    refreshClassFilter()
    curationWindow.Refresh()
end

function curationWindow.Show()
    if not curationFrame then curationFrame = buildCurationWindow() end
    curationFrame:Show()
    curationWindow.Reload()
end

function curationWindow.Hide()
    if curationFrame then curationFrame:Hide() end
end

function curationWindow.Toggle()
    if curationFrame and curationFrame:IsShown() then
        curationWindow.Hide()
        return
    end
    curationWindow.Show()
end

view.curationWindow = curationWindow

-- ================================================================================
-- SettingsPanel
-- ================================================================================

---@class BitForge.UPS.View.SettingsPanel
local settingsPanel = {}

function settingsPanel.Init()
    local category = BitForge.Settings.NewSubcategory(ADDON_NAME, locale["panel:title"], locale)

    -- Wrapped rather than passed straight through: with the bank open, a bank
    -- button left enabled after the module is switched off swallows the click in
    -- deposit.Run's IsEnabled guard and looks broken.
    category:AddCheckbox("enabled", model.IsEnabled, function(value)
        model.SetEnabled(value)
        bankButton.SetIdle()
    end)
    category:AddCheckbox("previewMoves", model.GetPreviewMoves, model.SetPreviewMoves)

    -- The settings panel is where a user looks for "what does this addon let me
    -- change", and curation is the answer for every item no rule can classify.
    -- The minimap entry is the other way in.
    category:AddInitializer(CreateSettingsButtonInitializer(
        "", locale["curation:open"], curationWindow.Toggle, nil, false))
end

view.settingsPanel = settingsPanel

---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...
local C_Item = C_Item

local model = ns.model
local locale = ns.locale
local control = ns.control

---@class BitForge.AzerothPrime.View
local view = ns.view

-- A standalone window rather than an inline settings section (see
-- view/settingsPanel.lua's manage-blacklist button for why). Owning the frame is
-- also what makes Refresh implementable: the list must change whenever a row is
-- removed, and there is no API to rebuild a settings initializer list after
-- registration.

local WINDOW_WIDTH = 420
local WINDOW_HEIGHT = 360
local HEADER_HEIGHT = 30
local FOOTER_HEIGHT = 40
local SCROLL_LEFT_INSET = 14
local SCROLL_RIGHT_INSET = 34
local CONTENT_WIDTH = WINDOW_WIDTH - SCROLL_LEFT_INSET - SCROLL_RIGHT_INSET
local BLACKLIST_ROW_HEIGHT = 24

-- The one `open` opinion this window is about. The merged store spells "never
-- offer this" as open = false and keeps true for its opposite, so the value is
-- what selects the list -- both the rows drawn and the set Clear All empties,
-- which is why the same constant feeds each.
local NEVER_OFFER = false

-- Item names arrive asynchronously. Rows render as an itemID placeholder until
-- ITEM_DATA_LOAD_RESULT fills them in; a stale itemID stays a placeholder rather
-- than erroring.
--
-- The load goes through the controller because a blacklisted item is often not
-- in the bags at all, so nothing else registers it as pending and the result
-- would be discarded before it could redraw this row.
local function BlacklistRowLabel(itemID)
    local name = C_Item.GetItemNameByID(itemID)
    if name then return name end
    control.openScanner.RequestItemData(itemID)
    return locale["blacklist:unknownItem"]:format(itemID)
end

---@class BitForge.AzerothPrime.View.BlacklistFrame
local blacklistFrame = {}

local mainFrame
local rowContainer
local blacklistRows = {}

local function AcquireRow(index)
    local row = blacklistRows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, rowContainer)
    row:SetHeight(BLACKLIST_ROW_HEIGHT)
    row:SetPoint("LEFT", rowContainer, "LEFT", 0, 0)
    row:SetPoint("RIGHT", rowContainer, "RIGHT", 0, 0)
    row:SetPoint("TOP", rowContainer, "TOP", 0, -(index - 1) * BLACKLIST_ROW_HEIGHT)

    row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.label:SetJustifyH("LEFT")

    row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.remove:SetSize(80, 20)
    row.remove:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.remove:SetText(locale["blacklist:remove"])

    blacklistRows[index] = row
    return row
end

function blacklistFrame.Refresh()
    if not rowContainer then return end

    local entries = model.overrides.GetOpenItems(NEVER_OFFER)

    for _, row in ipairs(blacklistRows) do
        row:Hide()
    end

    for index, itemID in ipairs(entries) do
        local row = AcquireRow(index)
        row.label:SetText(BlacklistRowLabel(itemID))
        row.remove:SetScript("OnClick", function()
            -- nil, not NEVER_OFFER's opposite: removing a row withdraws the
            -- player's opinion, and writing true would state the other one.
            model.overrides.SetOpen(itemID, nil)
            control.openScanner.RequestScan()
            blacklistFrame.Refresh()
        end)
        row:Show()
    end

    mainFrame.emptyLabel:SetShown(#entries == 0)
    mainFrame.clearAll:SetShown(#entries > 0)

    -- The scroll child grows to the full content height (rather than being capped)
    -- since scrolling, not clipping, is how overflow is handled here.
    rowContainer:SetHeight(math.max(#entries * BLACKLIST_ROW_HEIGHT, BLACKLIST_ROW_HEIGHT))
end

local function CreateMainFrame()
    mainFrame = CreateFrame("Frame", ADDON_NAME .. "BlacklistFrame", UIParent)
    mainFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:Hide()

    local shell = BitForge.UI.Skin.BuildWindowShell(mainFrame, {
        includeHeader = true,
        headerHeight = HEADER_HEIGHT,
    })
    local colors = BitForge.UI.Colors
    BitForge.UI.Skin.ApplyColorTexture(shell.background, colors.bg)
    BitForge.UI.Skin.ApplyColorTexture(shell.header, colors.surface)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderTop, colors.edge)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderBottom, colors.edge)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderLeft, colors.edge)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderRight, colors.edge)

    local closeButton = BitForge.UI.CreateCloseButton(mainFrame)
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    closeButton:SetScript("OnClick", function() mainFrame:Hide() end)
    mainFrame.closeButton = closeButton

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -8)
    title:SetText(locale["blacklist:windowTitle"])

    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", SCROLL_LEFT_INSET, -(HEADER_HEIGHT + 10))
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -SCROLL_RIGHT_INSET, FOOTER_HEIGHT)
    BitForge.UI.Skin.StyleScrollBar(scrollFrame.ScrollBar)

    rowContainer = CreateFrame("Frame", nil, scrollFrame)
    rowContainer:SetWidth(CONTENT_WIDTH)
    rowContainer:SetHeight(BLACKLIST_ROW_HEIGHT)
    scrollFrame:SetScrollChild(rowContainer)

    mainFrame.emptyLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    mainFrame.emptyLabel:SetPoint("TOP", scrollFrame, "TOP", 0, -8)
    mainFrame.emptyLabel:SetText(locale["blacklist:empty"])

    mainFrame.clearAll = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    mainFrame.clearAll:SetSize(120, 22)
    mainFrame.clearAll:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -12, 10)
    mainFrame.clearAll:SetText(locale["blacklist:clearAll"])
    mainFrame.clearAll:SetScript("OnClick", function()
        model.overrides.ClearAllOpen(NEVER_OFFER)
        control.openScanner.RequestScan()
        blacklistFrame.Refresh()
    end)
end

function blacklistFrame.Open()
    if not mainFrame then
        CreateMainFrame()
    end
    blacklistFrame.Refresh()
    mainFrame:Show()
end

view.blacklistFrame = blacklistFrame

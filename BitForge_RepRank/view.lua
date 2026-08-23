---@type string, BitForge.RepRank
local ADDON_NAME, ns = ...

local format = string.format
local ipairs = ipairs
local match = string.match

local AlertFrame = AlertFrame
local AlertFrame_OnClick = AlertFrame_OnClick
local CreateDataProvider = CreateDataProvider
local CreateFrame = CreateFrame
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local GameTooltip = GameTooltip
local PixelUtil = PixelUtil
local ScrollUtil = ScrollUtil
local UIParent = UIParent

---@type BitForge.RepRank.Locale
local locale = ns.locale
---@type BitForge.RepRank.Model
local model = ns.model

local UI = BitForge.UI

---@class BitForge.RepRank.View
local view = ns.view

-- =========================================================
-- Toast
-- =========================================================

---@class BitForge.RepRank.View.Toast
local toast = {}

local TOAST_TEMPLATE = "BitForge_RepRankToastTemplate"

-- The card's art keeps an icon well down its left side, so the text sits right
-- of centre and inside a fixed width. Both numbers are CriteriaAlertFrame's,
-- which is the template this one is shaped after.
local TOAST_TEXT_WIDTH = 160
local TOAST_TEXT_OFFSET_X = 27

-- The registered AlertFrame subsystem, or nil before Register runs.
local subSystem

--- What the toast says.
---
--- A count rather than a list: a login burst coalesces into one toast, and the
--- per-faction detail is already in chat. Two strings rather than one with a
--- number, because a singular and a plural are different sentences in most of
--- the languages this module ships.
---@param count number
---@return string
function toast.SummaryText(count)
    if count == 1 then
        return locale["toast:pendingOne"]
    end

    return format(locale["toast:pendingMany"], count)
end

--- Fills a toast frame for a pending count.
---@param frame table
---@param count number
local function setUpToast(frame, count)
    -- Lower-case, like every other region this module parks on a pooled frame:
    -- the template owns the PascalCase keys, and a clash with one would be
    -- silent.
    if not frame.summary then
        frame.summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.summary:SetWidth(TOAST_TEXT_WIDTH)
        frame.summary:SetJustifyH("CENTER")
        frame.summary:SetWordWrap(true)
        PixelUtil.SetPoint(frame.summary, "CENTER", frame, "CENTER", TOAST_TEXT_OFFSET_X, 0)

        -- Wired once, alongside the region it is set with: the subsystem reuses
        -- a pooled frame for every alert, so setting the script per toast would
        -- churn a fresh closure on each one.
        --
        -- Through AlertFrame_OnClick rather than instead of it, which is how
        -- Blizzard's own alert handlers open. It is what makes right-click
        -- dismiss the toast, and what honours the player's setting for blocking
        -- left clicks on alerts; a script that replaces it drops both.
        frame:SetScript("OnClick", function(self, button, down)
            if AlertFrame_OnClick(self, button, down) then return end

            view.window.Toggle()
        end)
    end

    frame.summary:SetText(toast.SummaryText(count))
end

--- Installs the alert subsystem. Safe to call more than once.
function toast.Register()
    if subSystem then return end

    subSystem = AlertFrame:AddSimpleAlertFrameSubSystem(TOAST_TEMPLATE, setUpToast)
end

--- Queues one toast for a pending count.
---@param count number
function toast.Show(count)
    toast.Register()

    if not subSystem then return end

    subSystem:AddAlert(count)
end

view.toast = toast

-- =========================================================
-- Window
-- =========================================================

---@class BitForge.RepRank.View.Window
local window = {}

local WINDOW_WIDTH = 460
local WINDOW_HEIGHT = 480
local ROW_HEIGHT = 20

-- The title bar UI.CreateFrame draws is 32px tall (APIs/UI/Templates/Frame.lua),
-- so everything below it starts at -32.
local TITLE_BAR_HEIGHT = 32
local PADDING = 8
local CONTROL_HEIGHT = 24
local COLUMN_HEADER_HEIGHT = 20
local GAP = 6
-- The strip kept clear down the right edge for the scroll bar, as UPS does.
local SCROLLBAR_GUTTER = 20

-- Fixed columns measured from the right edge inward, so the faction name takes
-- whatever is left. The insets are shared by the rows and the column header:
-- a header whose labels did not sit over the values they name is worse than no
-- header, and one shared number is the only way to keep them together.
local COLUMN_LEADER = 90
local COLUMN_STANDING = 110
local ROW_INSET_LEFT = 4
local ROW_INSET_RIGHT = 24

-- Distance from the frame's top to each control row.
local SEARCH_TOP = TITLE_BAR_HEIGHT + PADDING
local FILTER_TOP = SEARCH_TOP + CONTROL_HEIGHT + GAP
local COLUMN_HEADER_TOP = FILTER_TOP + CONTROL_HEIGHT + GAP

local SEARCH_WIDTH = 200

local WINDOW_NAME = ADDON_NAME .. "Window"
-- The atlas Blizzard's own reputation pane marks a pending paragon reward
-- with, so the row reads as the game's indicator rather than a second one.
local PARAGON_ATLAS = "ParagonReputation_Bag"

-- The window, or nil before the first open. Everything it is built from hangs
-- off it rather than off a second set of file locals, following UPS's curation
-- window: one handle, and no way for the two to disagree about what exists.
local frame

--- The character half of a "Name-Realm" key. Realms are identical across an
--- account and would fill the column saying nothing.
---@param charKey string
---@return string
local function shortCharacterName(charKey)
    return match(charKey, "^([^-]+)") or charKey
end

--- The three column strings for a row.
---@param row table
---@return string name, string leader, string label
function window.RowText(row)
    local leader = row.leader and shortCharacterName(row.leader) or ""
    return row.name, leader, row.label
end

--- The flat element list behind the scroll box.
---
--- One list rather than two, with header elements between the sections: the
--- scroll box takes a single data provider, and a section with no rows
--- contributes no header either -- an empty heading is noise, and a new account
--- has one of each.
---@return table[]
function window.Elements()
    local sections = model.BuildSections({
        showUntouched = model.GetShowUntouched(),
        search        = frame and frame.searchBox:GetText() or nil,
        sortByRank    = model.GetSortByRank(),
    })

    local elements = {}

    local function appendSection(title, rows)
        if #rows == 0 then return end

        elements[#elements + 1] = { isHeader = true, title = title }

        for _, row in ipairs(rows) do
            elements[#elements + 1] = row
        end
    end

    appendSection(locale["section:warband"], sections.warband)
    appendSection(locale["section:characters"], sections.characters)

    return elements
end

--- The paragon marker's tooltip body.
---
--- The one place a row reports more than its leader. Paragon is per character
--- on both kinds of faction, so a marker that did not say *who* would be
--- unactionable -- and in the warband section it is the row's only
--- per-character content.
---@param row table
---@return string[]
function window.PendingTooltipLines(row)
    local lines = {}

    for _, charKey in ipairs(row.pending or {}) do
        lines[#lines + 1] = shortCharacterName(charKey)
    end

    return lines
end

---@param marker table
local function onParagonEnter(marker)
    local lines = window.PendingTooltipLines(marker:GetParent())
    if #lines == 0 then return end

    GameTooltip:SetOwner(marker, "ANCHOR_RIGHT")
    GameTooltip:SetText(locale["tooltip:pendingTitle"])

    for _, line in ipairs(lines) do
        GameTooltip:AddLine(line, 1, 1, 1)
    end

    GameTooltip:Show()
end

local function onParagonLeave()
    GameTooltip:Hide()
end

--- Fills one row frame from its element.
---
--- The row's regions are created on first use and reused thereafter: the scroll
--- box pools its frames, so a row arriving here has usually been filled before.
--- Mirrors BitForge_UPS's initCurationRow rather than inventing a second shape.
---@param row     table
---@param element table
local function initRow(row, element)
    if not row.faction then
        row.faction = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.faction, "LEFT", row, "LEFT", ROW_INSET_LEFT, 0)
        row.faction:SetJustifyH("LEFT")
        row.faction:SetWordWrap(false)

        row.standing = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.standing, "RIGHT", row, "RIGHT", -ROW_INSET_RIGHT, 0)
        row.standing:SetWidth(COLUMN_STANDING)
        row.standing:SetJustifyH("RIGHT")

        row.leader = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.leader, "RIGHT", row.standing, "LEFT", -GAP, 0)
        row.leader:SetWidth(COLUMN_LEADER)
        row.leader:SetJustifyH("RIGHT")

        PixelUtil.SetPoint(row.faction, "RIGHT", row.leader, "LEFT", -GAP, 0)

        row.paragon = row:CreateTexture(nil, "ARTWORK")
        row.paragon:SetSize(14, 14)
        PixelUtil.SetPoint(row.paragon, "RIGHT", row, "RIGHT", -ROW_INSET_LEFT, 0)
        row.paragon:SetAtlas(PARAGON_ATLAS)

        -- A bare Frame takes no mouse input, so without this the marker's
        -- tooltip would never fire.
        row.paragonHit = CreateFrame("Frame", nil, row)
        row.paragonHit:SetAllPoints(row.paragon)
        row.paragonHit:EnableMouse(true)
        row.paragonHit:SetScript("OnEnter", onParagonEnter)
        row.paragonHit:SetScript("OnLeave", onParagonLeave)
    end

    row.pending = element.pending

    if element.isHeader then
        row.faction:SetText(element.title)
        row.leader:SetText("")
        row.standing:SetText("")
        row.paragon:Hide()
        row.paragonHit:Hide()
        return
    end

    local name, leader, label = window.RowText(element)
    row.faction:SetText(name)
    row.leader:SetText(leader)
    row.standing:SetText(label)

    local hasPending = #element.pending > 0
    row.paragon:SetShown(hasPending)
    row.paragonHit:SetShown(hasPending)
end

--- Flips between the relevance order and rank order, and persists the choice.
function window.ToggleRankSort()
    model.SetSortByRank(not model.GetSortByRank())
    window.Refresh()
end

--- Builds the column header: the three labels the rows are read against.
---
--- A frame of its own rather than three regions on the window, so it can share
--- the scroll box's left and right edges exactly and the labels can be anchored
--- against each other with the same insets initRow uses.
---@param parent table
---@return table
local function buildColumnHeader(parent)
    local columnHeader = CreateFrame("Frame", nil, parent)
    PixelUtil.SetPoint(columnHeader, "TOPLEFT", parent, "TOPLEFT",
        PADDING, -COLUMN_HEADER_TOP)
    PixelUtil.SetPoint(columnHeader, "TOPRIGHT", parent, "TOPRIGHT",
        -(PADDING + SCROLLBAR_GUTTER), -COLUMN_HEADER_TOP)
    PixelUtil.SetHeight(columnHeader, COLUMN_HEADER_HEIGHT)

    -- A button rather than a label, because this column is also the sort
    -- control: clicking it flips between the relevance order and rank order.
    local standing = UI.CreateButton(
        WINDOW_NAME .. "StandingHeader", columnHeader, nil, locale["column:standing"])
    standing:SetSize(COLUMN_STANDING, COLUMN_HEADER_HEIGHT)
    PixelUtil.SetPoint(standing, "RIGHT", columnHeader, "RIGHT", -ROW_INSET_RIGHT, 0)
    standing:SetScript("OnClick", window.ToggleRankSort)
    columnHeader.standing = standing

    local leader = columnHeader:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    leader:SetWidth(COLUMN_LEADER)
    leader:SetJustifyH("RIGHT")
    leader:SetText(locale["column:leader"])
    PixelUtil.SetPoint(leader, "RIGHT", standing, "LEFT", -GAP, 0)
    columnHeader.leader = leader

    local faction = columnHeader:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    faction:SetJustifyH("LEFT")
    faction:SetWordWrap(false)
    faction:SetText(locale["column:faction"])
    PixelUtil.SetPoint(faction, "LEFT", columnHeader, "LEFT", ROW_INSET_LEFT, 0)
    PixelUtil.SetPoint(faction, "RIGHT", leader, "LEFT", -GAP, 0)
    columnHeader.faction = faction

    return columnHeader
end

--- Builds the window. Deferred rather than run at file-read time so the module
--- stays loadable in the headless harness.
---
--- Every child is anchored here: UI.CreateFrame draws a backdrop and a title
--- bar and nothing else, and a region with no resolved rect is not drawn at all.
local function build()
    frame = UI.CreateFrame(UIParent, locale["window:title"])
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", model.GetWindowPos())
    frame:Hide()

    -- Before SetMovable, and not optional: a frame that takes no mouse input
    -- never fires OnDragStart, and FrameMixin:OnLoad does not enable it.
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        -- Stored as an offset from the screen centre rather than as absolute
        -- coordinates, so the window lands in the same visual place at a
        -- different resolution.
        local centreX, centreY = UIParent:GetCenter()
        local selfX, selfY = self:GetCenter()
        model.SetWindowPos(selfX - centreX, selfY - centreY)
    end)

    -- UI.CreateFrame draws a title bar but no close affordance, and this window
    -- has no button that doubles as one. Without this the only way out is the
    -- minimap entry, since the search box swallows the first ESC.
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    frame.closeButton = closeButton

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    searchLabel:SetJustifyH("LEFT")
    searchLabel:SetText(locale["filter:search"])
    PixelUtil.SetPoint(searchLabel, "TOPLEFT", frame, "TOPLEFT", PADDING, -SEARCH_TOP)
    PixelUtil.SetHeight(searchLabel, CONTROL_HEIGHT)
    frame.searchLabel = searchLabel

    local searchBox = UI.CreateEditBox(frame)
    searchBox:SetSize(SEARCH_WIDTH, CONTROL_HEIGHT)
    PixelUtil.SetPoint(searchBox, "LEFT", searchLabel, "RIGHT", GAP, 0)
    -- SetScript rather than overriding EditBoxMixin.OnTextChanged: the mixin
    -- binds the function value at OnLoad time, so a later reassignment of the
    -- method would never be seen.
    searchBox:SetScript("OnTextChanged", function() window.Refresh() end)
    frame.searchBox = searchBox

    -- Its own row rather than beside the search box: the label is a sentence,
    -- and in the longer of the eleven locales it would not fit alongside one.
    local showUntouched = UI.CreateCheckButton(
        WINDOW_NAME .. "ShowUntouched", frame, locale["filter:showUntouched"])
    PixelUtil.SetPoint(showUntouched, "TOPLEFT", frame, "TOPLEFT", PADDING, -FILTER_TOP)
    showUntouched:SetChecked(model.GetShowUntouched())
    showUntouched:SetScript("OnClick", function(self)
        model.SetShowUntouched(self:GetChecked() and true or false)
        window.Refresh()
    end)
    frame.showUntouched = showUntouched

    local columnHeader = buildColumnHeader(frame)
    frame.columnHeader = columnHeader

    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

    PixelUtil.SetPoint(scrollBox, "TOPLEFT", columnHeader, "BOTTOMLEFT", 0, -GAP)
    PixelUtil.SetPoint(scrollBox, "BOTTOMRIGHT", frame, "BOTTOMRIGHT",
        -(PADDING + SCROLLBAR_GUTTER), PADDING)
    PixelUtil.SetPoint(scrollBar, "TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    PixelUtil.SetPoint(scrollBar, "BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(ROW_HEIGHT)
    scrollView:SetElementInitializer("Button", initRow)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
    UI.Skin.StyleScrollBar(scrollBar)

    frame.scrollBox = scrollBox
    frame.scrollBar = scrollBar
end

--- Rebuilds the list from the current filter and sort state.
function window.Refresh()
    if not frame then return end

    frame.scrollBox:SetDataProvider(CreateDataProvider(window.Elements()))
end

--- Shows the window, or hides it if it is already up.
function window.Toggle()
    if not frame then build() end

    if frame:IsShown() then
        frame:Hide()
        return
    end

    window.Refresh()
    frame:Show()
end

view.window = window

-- =========================================================
-- Settings panel
-- =========================================================

---@class BitForge.RepRank.View.SettingsPanel
local settingsPanel = {}

--- Registers the module's subcategory under the BitForge settings root.
function settingsPanel.Init()
    local category = BitForge.Settings.NewSubcategory(ADDON_NAME, locale["panel:title"], locale)

    category:AddCheckbox("chatAlerts",
        function() return model.GetChatAlerts() end,
        function(value) model.SetChatAlerts(value) end)

    category:AddCheckbox("toastAlerts",
        function() return model.GetToastAlerts() end,
        function(value) model.SetToastAlerts(value) end)
end

view.settingsPanel = settingsPanel

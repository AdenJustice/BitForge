---@type string, BitForge.RepRank
local ADDON_NAME, ns = ...

local format = string.format
local ipairs = ipairs
local match = string.match

local AlertFrame = AlertFrame
local AlertFrame_OnClick = AlertFrame_OnClick
local BreakUpLargeNumbers = BreakUpLargeNumbers
local CreateColor = CreateColor
local CreateDataProvider = CreateDataProvider
local CreateFrame = CreateFrame
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local FACTION_BAR_COLORS = FACTION_BAR_COLORS
local GameTooltip = GameTooltip
local PixelUtil = PixelUtil
local REPUTATION_PROGRESS_FORMAT = REPUTATION_PROGRESS_FORMAT
local ScrollUtil = ScrollUtil
local UIParent = UIParent

---@type BitForge.RepRank.Enum
local enum = ns.enum
---@type BitForge.RepRank.Locale
local locale = ns.locale
---@type BitForge.RepRank.Model
local model = ns.model

local UI = BitForge.UI

---@class BitForge.RepRank.View
local view = ns.view

--- The character half of a "Name-Realm" key, painted in that character's class
--- colour.
---
--- Display only, and published rather than kept local so there is exactly one
--- of it: the key stays plain everywhere it is identity -- the record lookup,
--- the pending list, the sort -- and a second spelling is how markup ends up
--- inside a charKey, where it matches nothing.
---
--- No colour is the ordinary answer rather than a fault: core learns a class
--- only when that character logs in, and the client declines a colour for a
--- class file it does not recognise.
---@param charKey string
---@return string
function view.CharacterLabel(charKey)
    local shortName = match(charKey, "^([^-]+)") or charKey

    local color = BitForge:GetCharacterClassColor(charKey)
    if not color then return shortName end

    return color:WrapTextInColorCode(shortName)
end

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

---@class BitForge.RepRank.View.Window
local window = {}

local WINDOW_WIDTH = 570
local WINDOW_HEIGHT = 480
local ROW_HEIGHT = 20

-- The title bar UI.CreateFrame draws is 32px tall (APIs/UI/Templates/Frame.lua),
-- so everything below it starts at -32.
local TITLE_BAR_HEIGHT = 32
local PADDING = 8
local CONTROL_HEIGHT = 24
local COLUMN_HEADER_HEIGHT = 20
local GAP = 6
-- The strip kept clear down the right edge for the scroll bar, as Dispatch's
-- curation window does.
local SCROLLBAR_GUTTER = 20

-- Fixed columns measured from the right edge inward, so the faction name takes
-- whatever is left. The insets are shared by the rows and the column header:
-- a header whose labels did not sit over the values they name is worse than no
-- header, and one shared number is the only way to keep them together.
local COLUMN_LEADER = 90
local COLUMN_BAR = 100
local COLUMN_STANDING = 110
local ROW_INSET_LEFT = 4
-- One indent step. Depth 0 is a section heading, 1 an expansion heading beneath
-- it, 2 a faction row -- so a row reads as belonging to the heading above it
-- rather than sitting level with it.
local INDENT_STEP = 12
local ROW_INSET_RIGHT = 24

-- How tall the bar is inside a 20px row. Eight is the shared widget's own
-- default (APIs/UI/Templates/Bar.lua) and leaves six clear above and below it,
-- which is what keeps a scrolled column of bars reading as one per row rather
-- than as a single striped band down the middle of the list.
local BAR_HEIGHT = 8

-- Distance from the frame's top to each control row.
local SEARCH_TOP = TITLE_BAR_HEIGHT + PADDING
local FILTER_TOP = SEARCH_TOP + CONTROL_HEIGHT + GAP
local COLUMN_HEADER_TOP = FILTER_TOP + CONTROL_HEIGHT + GAP

local SEARCH_WIDTH = 200

local WINDOW_NAME = ADDON_NAME .. "Window"
-- The atlas Blizzard's own reputation pane marks a pending paragon reward
-- with, so the row reads as the game's indicator rather than a second one.
local PARAGON_ATLAS = "ParagonReputation_Bag"

-- Blizzard gives paragon no bar colour of its own -- its reputation panel
-- leaves paragon out of the bar entirely -- so the module has to pick one, and
-- picks it well away from the four the client already spends on standings. The
-- distance is the point: paragon is not more of the standing underneath it, it
-- is a separate track that empties again every chest.
local PARAGON_BAR_COLOR = CreateColor(0.64, 0.39, 0.90)

-- ReputationFrame.lua -- `local friendshipColorIndex = 5; -- Always color
-- friendships green`. A friendship has ranks but no reaction to index the
-- palette with, so Blizzard hardcodes the first green entry and so does this.
local FRIENDSHIP_COLOR_INDEX = 5

-- The window, or nil before the first open. Everything it is built from hangs
-- off it rather than off a second set of file locals, following Dispatch's
-- curation window: one handle, and no way for the two to disagree about what
-- exists.
local frame

--- The three column strings for a row.
---@param row table
---@return string name, string leader, string label
function window.RowText(row)
    local leader = row.leader and view.CharacterLabel(row.leader) or ""
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

    -- Two heading levels. The rows arrive already grouped -- model.BuildSections
    -- sorts by the heading's pane position before anything else -- so a change
    -- of group is a boundary rather than something to search for.
    local function appendSection(title, rows)
        if #rows == 0 then return end

        elements[#elements + 1] = { isHeader = true, title = title, depth = 0 }

        local currentGroup
        for _, row in ipairs(rows) do
            local group = row.group or locale["section:ungrouped"]
            if group ~= currentGroup then
                currentGroup = group
                elements[#elements + 1] = { isHeader = true, title = group, depth = 1 }
            end
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
        lines[#lines + 1] = view.CharacterLabel(charKey)
    end

    return lines
end

-- Which colour each kind of bar is painted, keyed by the kind the record
-- already carries. One lookup rather than a chain of tests, because the kinds
-- are a closed set named once in Init.lua -- a table keyed off that set cannot
-- fall out of step with it the way a fourth branch quietly could.
--
-- Every entry is a function rather than a colour, because the standard kind's
-- colour is not a constant: it is the client's per-standing palette entry, and
-- only the record knows which standing it is sitting at.
local BAR_KIND_COLORS = {
    [enum.BAR_KIND.STANDARD] = function(record)
        -- Hostile red through exalted green, exactly as the reputation panel
        -- picks it (ReputationFrame.lua).
        return FACTION_BAR_COLORS[record.tier]
    end,
    [enum.BAR_KIND.FRIENDSHIP] = function()
        return FACTION_BAR_COLORS[FRIENDSHIP_COLOR_INDEX]
    end,
    [enum.BAR_KIND.MAJOR] = function()
        -- Standing in for the panel's BLUE_FONT_COLOR: the addon's own accent
        -- says "renown track" inside this window without dragging a second blue
        -- in beside every other flat-design surface it ships.
        return UI.Colors.point
    end,
    [enum.BAR_KIND.PARAGON] = function()
        return PARAGON_BAR_COLOR
    end,
}

--- The colour a row's bar is painted.
---
--- Never raises. A record with no bar, a kind this build does not know, and a
--- standing outside the eight the client has colours for all answer the
--- palette's plain grey -- all three are shapes a stored record can arrive in,
--- the bar is painted from the same pass as the list around it, and a lookup
--- that threw here would take the whole window down with it.
---
--- Returned rather than unpacked, and typed colorRGB rather than colorRGBA:
--- FACTION_BAR_COLORS holds ColorMixins while PARAGON_BAR_COLOR is built without
--- an alpha, and BarMixin:SetBarColor resolves either.
---@param record table|nil
---@return colorRGB
function window.BarColor(record)
    local bar = record and record.bar
    local resolve = bar and BAR_KIND_COLORS[bar.kind]

    return (resolve and resolve(record)) or UI.Colors.text
end

--- The progress bar's tooltip body.
---
--- Three bars have no figures to offer and all three answer nothing, so the
--- hover shows no tooltip at all rather than one that says nothing new. A capped
--- bar's stored shape is one over one, so its figures would read `1 / 1` -- true
--- of the placeholder and of nothing the character earned, which is why Blizzard
--- suppresses the progress text there too (ReputationFrame.lua). An
--- unmeasurable range and a record written before bars existed carry no maximum
--- at all.
---@param row table
---@return string[]
function window.BarTooltipLines(row)
    local lines = {}

    local bar = row.record and row.record.bar
    if not bar or bar.capped or not bar.max then return lines end

    lines[#lines + 1] = format(REPUTATION_PROGRESS_FORMAT,
        BreakUpLargeNumbers(bar.value or 0), BreakUpLargeNumbers(bar.max))

    return lines
end

---@param marker table
local function onParagonEnter(marker)
    local element = marker:GetParent().element
    if not element then return end

    local lines = window.PendingTooltipLines(element)
    if #lines == 0 then return end

    GameTooltip:SetOwner(marker, "ANCHOR_RIGHT")
    GameTooltip:SetText(locale["tooltip:pendingTitle"])

    for _, line in ipairs(lines) do
        GameTooltip:AddLine(line, 1, 1, 1)
    end

    GameTooltip:Show()
end

---@param hitFrame table
local function onBarEnter(hitFrame)
    local element = hitFrame:GetParent().element
    if not element then return end

    local lines = window.BarTooltipLines(element)
    if #lines == 0 then return end

    -- Titled with the faction rather than with a fixed heading: the bar column
    -- carries no text of its own, and a tooltip anchored halfway across a
    -- twenty-pixel row is easy to read against the wrong line.
    GameTooltip:SetOwner(hitFrame, "ANCHOR_RIGHT")
    GameTooltip:SetText(element.name)

    for _, line in ipairs(lines) do
        GameTooltip:AddLine(line, 1, 1, 1)
    end

    GameTooltip:Show()
end

local function onTooltipLeave()
    GameTooltip:Hide()
end

--- Fills one row frame from its element.
---
--- The row's regions are created on first use and reused thereafter: the scroll
--- box pools its frames, so a row arriving here has usually been filled before.
--- Mirrors BitForge_Dispatch's curationWindow initCurationRow rather than
--- inventing a second shape.
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

        row.bar = UI.CreateBar(row)
        PixelUtil.SetSize(row.bar, COLUMN_BAR, BAR_HEIGHT)
        PixelUtil.SetPoint(row.bar, "RIGHT", row.standing, "LEFT", -GAP, 0)

        -- A bare Frame takes no mouse input, and neither does a StatusBar, so
        -- without this the bar's tooltip would never fire.
        --
        -- The bar's width but the row's height, rather than SetAllPoints: the
        -- figures behind the bar are the one thing the row does not print, so
        -- this is a tooltip players go looking for, and an eight-pixel strip
        -- inside a twenty-pixel row is a target they would have to hunt for.
        -- Nothing else occupies the bar's column, so the six clear pixels above
        -- and below it may as well answer the hover.
        row.barHit = CreateFrame("Frame", nil, row)
        PixelUtil.SetPoint(row.barHit, "LEFT", row.bar, "LEFT", 0, 0)
        PixelUtil.SetPoint(row.barHit, "RIGHT", row.bar, "RIGHT", 0, 0)
        PixelUtil.SetHeight(row.barHit, ROW_HEIGHT)
        row.barHit:EnableMouse(true)
        row.barHit:SetScript("OnEnter", onBarEnter)
        row.barHit:SetScript("OnLeave", onTooltipLeave)

        row.leader = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.leader, "RIGHT", row.bar, "LEFT", -GAP, 0)
        row.leader:SetWidth(COLUMN_LEADER)
        row.leader:SetJustifyH("RIGHT")

        PixelUtil.SetPoint(row.faction, "RIGHT", row.leader, "LEFT", -GAP, 0)

        row.paragon = row:CreateTexture(nil, "ARTWORK")
        row.paragon:SetSize(14, 14)
        PixelUtil.SetPoint(row.paragon, "RIGHT", row, "RIGHT", -ROW_INSET_LEFT, 0)
        row.paragon:SetAtlas(PARAGON_ATLAS)

        row.paragonHit = CreateFrame("Frame", nil, row)
        row.paragonHit:SetAllPoints(row.paragon)
        row.paragonHit:EnableMouse(true)
        row.paragonHit:SetScript("OnEnter", onParagonEnter)
        row.paragonHit:SetScript("OnLeave", onTooltipLeave)
    end

    -- The whole element rather than a field per tooltip. Both hit frames answer
    -- from it, and a pooled row is refilled constantly -- one stale half of a
    -- pair of stashed fields would be a tooltip describing the wrong faction.
    row.element = element

    -- Re-anchored per element rather than once at creation: rows are pooled, so
    -- the one reused for a faction may last have drawn a heading.
    PixelUtil.SetPoint(row.faction, "LEFT", row, "LEFT",
        ROW_INSET_LEFT + (element.isHeader and (element.depth or 0) or 2) * INDENT_STEP, 0)

    if element.isHeader then
        row.faction:SetText(element.title)
        row.leader:SetText("")
        row.standing:SetText("")
        row.bar:Hide()
        row.barHit:Hide()
        row.paragon:Hide()
        row.paragonHit:Hide()
        return
    end

    local name, leader, label = window.RowText(element)
    row.faction:SetText(name)
    row.leader:SetText(leader)
    row.standing:SetText(label)

    -- Shown for every data row, including one whose record predates bars or
    -- whose range the client could not measure. Those draw empty: a column that
    -- came and went as the list scrolled would be harder to read than one that
    -- is occasionally blank.
    local bar = element.record and element.record.bar
    row.bar:SetBarColor(window.BarColor(element.record))
    row.bar:SetProgress(bar and bar.value, bar and bar.max)
    row.bar:Show()
    row.barHit:Show()

    local hasPending = #element.pending > 0
    row.paragon:SetShown(hasPending)
    row.paragonHit:SetShown(hasPending)
end

--- Flips between the relevance order and rank order, and persists the choice.
function window.ToggleRankSort()
    model.SetSortByRank(not model.GetSortByRank())
    window.Refresh()
end

--- Builds the column header: the four labels the rows are read against.
---
--- A frame of its own rather than four regions on the window, so it can share
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

    -- Centred rather than right-aligned like its neighbours: the bar fills its
    -- whole column, so the label belongs over the middle of it and not over one
    -- end of a run of them.
    local progress = columnHeader:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    progress:SetWidth(COLUMN_BAR)
    progress:SetJustifyH("CENTER")
    progress:SetWordWrap(false)
    progress:SetText(locale["column:progress"])
    PixelUtil.SetPoint(progress, "RIGHT", standing, "LEFT", -GAP, 0)
    columnHeader.progress = progress

    local leader = columnHeader:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    leader:SetWidth(COLUMN_LEADER)
    leader:SetJustifyH("RIGHT")
    leader:SetText(locale["column:leader"])
    PixelUtil.SetPoint(leader, "RIGHT", progress, "LEFT", -GAP, 0)
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

    -- Not redundant with ESC: the search box swallows the first press, and
    -- without this the only other way out is the minimap entry.
    local closeButton = UI.CreateCloseButton(frame)
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

    -- Re-asserted from the model rather than left to the click that changed it.
    -- A CheckButton flips its checked flag in C, which does not route through
    -- the Lua SetChecked that CheckButtonMixin hooks its repaint to, so a
    -- clicked box keeps whatever state it was last painted with. This widget
    -- carries no tick icon, so that paint is the only thing distinguishing on
    -- from off.
    frame.showUntouched:SetChecked(model.GetShowUntouched())

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

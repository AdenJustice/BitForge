---@class BitForge.EUI
local ns = select(2, ...)

---@class BitForge.EUI.View
local view = ns.view
---@type BitForge.EUI.Control
local control = ns.control
---@type BitForge.EUI.Locale
local locale = ns.locale

local UI = BitForge.UI
local colors = UI.Colors

local format = string.format

-- The element list. Widgets only: control/editor.lua decided what every row is,
-- in what order, and which markers it carries. Ports the standalone addon's
-- Core/UI/List.lua and the 3x3 point picker's parent, its Core/UI/Grid.lua,
-- whose nine buttons are now two dropdowns in view/detail.lua.

local ROW_HEIGHT = 20
local LIST_WIDTH = 220
local PADDING = 16
local GAP = 6
local CONTROL_HEIGHT = 24

-- The title bar UI.CreateFrame draws is 32px tall
-- (BitForge/Libs/LibBitForgeUI/Templates/Frame.lua), so content below it
-- starts here.
local CONTENT_TOP = 42

-- Per-depth indent, then the tree view's top, bottom, left, right padding and
-- its row spacing. One level deep is all this list has: every element sits
-- under its folder's header.
local INDENT, PAD, SPACING = 12, 2, 1

-- The selected row is tinted with the accent at low alpha, so it reads as
-- picked without competing with its own text.
local SELECTION_ALPHA = 0.2

---@class BitForge.EUI.View.List
local list = {}

-- What the player has narrowed and folded the list to. Widget state, not saved
-- state: a search box that remembered its text across a session would open on a
-- list with most of itself missing and no clue why.
local state = { collapsed = {}, filter = nil }
local selectedKey
local scrollBox, scrollBar, searchBox

--- The key the form is showing, or nil while nothing is selected.
---@return string|nil
function list.Selected()
    return selectedKey
end

--- The rows as a tree: a node per group, its elements beneath it. Flat data
--- from control/editor.lua either way -- the nesting is what gives the widget
--- its indent, and a collapsed group contributes no children because the
--- controller already left them out.
---@return table
local function buildProvider()
    local provider = CreateTreeDataProvider()
    local root = provider:GetRootNode()
    local group = root

    for _, row in ipairs(control.editor.BuildRows(state)) do
        if row.kind == "group" then
            group = root:Insert(row)
        else
            group:Insert(row)
        end
    end

    return provider
end

--- Rebuild the list from the current filter and fold state.
function list.Refresh()
    if not scrollBox then return end

    -- RetainScrollPosition: a collapse or a marker change must not throw the
    -- player back to the top (ScrollBox.lua).
    scrollBox:SetDataProvider(buildProvider(), ScrollBoxConstants.RetainScrollPosition)
end

local function onRowClick(self)
    local row = self.row
    if not row then return end

    if row.kind == "group" then
        state.collapsed[row.folder] = not state.collapsed[row.folder]
        list.Refresh()
    elseif row.kind == "newanchor" then
        view.detail.ShowNewAnchor()
    else
        selectedKey = row.key
        view.detail.Show(row.key, row.kind)
        list.Refresh()
    end
end

--- The marker suffix for one row.
---@param row table
---@return string
local function markers(row)
    local marks = ""
    if row.attachedEui then marks = marks .. " " .. locale["ui:markAttachedEui"] end
    if row.attachedBitForge then marks = marks .. " " .. locale["ui:markAttachedBitForge"] end
    if row.unmanaged then marks = marks .. " " .. locale["list:unmanaged"] end
    if row.hidden then marks = marks .. " " .. locale["ui:markHidden"] end
    return marks
end

local accentRed, accentGreen, accentBlue = colors.point:GetRGB()

---@param row table  the row's data, from control.editor.BuildRows
---@return colorRGBA
local function rowColor(row)
    if row.kind == "group" then return colors.point end
    if row.kind == "newanchor" then return colors.text end
    if row.hidden then return colors.textDisabled end
    return colors.textHover
end

local function initRow(rowFrame, node)
    if not rowFrame.label then
        rowFrame.selection = rowFrame:CreateTexture(nil, "BACKGROUND")
        rowFrame.selection:SetAllPoints()
        rowFrame.selection:SetColorTexture(accentRed, accentGreen, accentBlue, SELECTION_ALPHA)

        rowFrame.label = rowFrame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        rowFrame.label:SetPoint("LEFT", rowFrame, "LEFT", 4, 0)
        rowFrame.label:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
        rowFrame.label:SetJustifyH("LEFT")

        rowFrame:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
        rowFrame:SetScript("OnClick", onRowClick)
    end

    local row = node:GetData()
    rowFrame.row = row

    if row.kind == "group" then
        rowFrame.label:SetText(format("%s (%d)", row.label, row.count))
    else
        rowFrame.label:SetText(row.label .. markers(row))
    end

    rowFrame.label:SetTextColor(rowColor(row):GetRGB())
    rowFrame.selection:SetShown(row.key ~= nil and row.key == selectedKey)
end

--- Build the search box and the list, and register the list's own repaint.
---@param parent table  the editor window
---@return table scrollBox
function list.Create(parent)
    local searchLabel = parent:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    searchLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, -CONTENT_TOP)
    searchLabel:SetJustifyH("LEFT")
    searchLabel:SetText(locale["ui:filter"])
    parent.searchLabel = searchLabel

    searchBox = UI.CreateEditBox(parent)
    searchBox:SetSize(LIST_WIDTH, CONTROL_HEIGHT)
    searchBox:SetPoint("TOPLEFT", searchLabel, "BOTTOMLEFT", 0, -GAP / 2)
    -- SetScript rather than overriding EditBoxMixin.OnTextChanged: the mixin
    -- binds the function value at OnLoad time, so a later reassignment of the
    -- method would never be seen.
    searchBox:SetScript("OnTextChanged", function(self)
        state.filter = self:GetText()
        list.Refresh()
    end)
    parent.searchBox = searchBox

    scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    -- MinimalScrollBar is an EventFrame, not a Frame (MinimalScrollBar.xml).
    scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")

    scrollBox:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -GAP)
    scrollBox:SetPoint("BOTTOMLEFT", parent.footer, "TOPLEFT", 0, GAP)
    scrollBox:SetWidth(LIST_WIDTH)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local treeView = CreateScrollBoxListTreeListView(INDENT, PAD, PAD, PAD, PAD, SPACING)
    -- Mandatory for a bare frame type: with no template there is no
    -- C_XMLUtil.GetTemplateInfo to measure the row with, and Init raises
    -- (ScrollBoxListView.lua).
    treeView:SetElementExtent(ROW_HEIGHT)
    treeView:SetElementFactory(function(factory)
        factory("Button", initRow)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, treeView)
    UI.Skin.StyleScrollBar(scrollBar)

    parent.scrollBox = scrollBox
    parent.scrollBar = scrollBar

    view.AddRefresher(list.Refresh)
    return scrollBox
end

--- Paint this pane's widgets in the host UI's theme. Each pane skins what it
--- built: the shell's handler has no business reaching into another's widgets,
--- and a widget added here would otherwise be skinned from a file that never
--- learns about it.
---
--- Facade names are verbatim from EllesmereUI's SKINNING_API.md -- core pcalls
--- the handler, so a name that is wrong fails silently and looks exactly like a
--- host that never answered.
---@param facade table
function list.ApplySkin(facade)
    facade.EditBox(searchBox)
    facade.ScrollBar(scrollBar)
end

view.list = list

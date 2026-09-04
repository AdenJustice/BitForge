---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...

local ipairs = ipairs
local max = math.max
local tinsert = table.insert

local CreateFrame = CreateFrame
local CreateDataProvider = CreateDataProvider
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local ScrollUtil = ScrollUtil
local SelectionBehaviorMixin = SelectionBehaviorMixin
local PixelUtil = PixelUtil

local UI = BitForge.UI
local colors = UI.Colors
local locale = ns.locale
---@class BitForge.AzerothPrime.View
local view = ns.view
---@type BitForge.AzerothPrime.View.RuleDescriptors
local ruleDescriptors = view.ruleDescriptors

-- UI.CreateFrame's third argument, so the frame is named at creation rather
-- than left anonymous like this suite's other standalone windows -- GetName()
-- has no way to answer a name after the fact.
local FRAME_NAME = ADDON_NAME .. "RuleWindow"

-- 530 rather than 520 because the detail pane's controls scroll now and their
-- scroll bar has to come out of somewhere. The extra ten give it a gutter of
-- its own rather than taking it off the rows: every width in
-- view/ruleControls.lua was measured across eleven locales against 316px of
-- content, and KIND.subclass's own comment records how little slack the worst
-- of them has.
--
-- 480 rather than 420 because it is the height the densest pane already fit at,
-- and scrolling you never have to do beats scrolling you do. Neither number is
-- a requirement -- an overflow is reachable rather than clipped.
local WIDTH, HEIGHT = 530, 480
local LIST_WIDTH = 170
local TITLE_BAR_HEIGHT = 32
local PADDING = 8
local ROW_HEIGHT = 24
-- MinimalScrollBar's own width (MinimalScrollBar.xml), and the gap both bars in
-- this window sit at.
local SCROLLBAR_WIDTH, SCROLLBAR_GAP = 8, 2
-- The controls' scroll child, which has to be told its own width: the window
-- less the criterion list and both scroll bars' gutters. Left as the
-- subtraction the anchors below make rather than collapsed into 316, so a
-- change to either reads here as arithmetic that stopped adding up.
local CONTROLS_WIDTH = WIDTH - PADDING - LIST_WIDTH - SCROLLBAR_GAP - SCROLLBAR_WIDTH
    - PADDING - PADDING - SCROLLBAR_GAP - SCROLLBAR_WIDTH

local HEADER_LABEL_KEY = { cross = "section:everyItem", class = "section:byItemType" }

---@class BitForge.AzerothPrime.View.RuleWindow
local ruleWindow = {}

local frame
local selectionBehavior

-- Built once inside BuildFrame's detail pane; RenderDetail below assumes all
-- six exist together, since nothing can select a criterion before the frame
-- that would need them.
local detailTitleText, detailSubText, detailBlurbText, detailLockedText
local detailScroll, detailControls

--- One row per section header plus one per criterion, in display order.
--- Built once from the descriptor table -- it needs no frame to exist, which
--- is what lets a test see it without reaching into the scrollbox's own
--- internals. A deliberate test seam, not an accessor meant for other files.
local rows = {}
do
    local lastGroup
    for _, criterion in ipairs(ruleDescriptors) do
        if criterion.group ~= lastGroup then
            rows[#rows + 1] = {
                isHeader = true,
                group = criterion.group,
                labelKey = HEADER_LABEL_KEY[criterion.group],
            }
            lastGroup = criterion.group
        end
        rows[#rows + 1] = {
            isHeader = false,
            key = criterion.key,
            group = criterion.group,
            locked = criterion.locked,
            controls = criterion.controls,
        }
    end
end
ruleWindow.__rows = rows

local function OnRowMouseDown(self)
    local data = self._data
    if not data or data.isHeader then return end
    ruleWindow.Select(data.key)
end

local function InitRowElement(row, data)
    if not row.label then
        row.label = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
        PixelUtil.SetPoint(row.label, "LEFT", row, "LEFT", 6, 0)
        PixelUtil.SetPoint(row.label, "RIGHT", row, "RIGHT", -6, 0)
        row.label:SetJustifyH("LEFT")

        -- The one thing a criterion row can look like that a header never
        -- does -- ruleWindow.Select never names a header row.
        row.highlight = row:CreateTexture(nil, "BACKGROUND")
        row.highlight:SetAllPoints(row)
        UI.Skin.ApplyColorTexture(row.highlight, colors.point.r, colors.point.g, colors.point.b, 0.25)
        row.highlight:Hide()

        -- A bare Frame element takes no mouse input, so without this a
        -- criterion row would never fire OnMouseDown.
        row:EnableMouse(true)
    end

    row._data = data
    row.highlight:SetShown(not data.isHeader and ruleWindow.Selected() == data.key)

    if data.isHeader then
        row.label:SetText(locale[data.labelKey])
        row.label:SetTextColor(colors.point:GetRGB())
        row:SetScript("OnMouseDown", nil)
    else
        row.label:SetText(locale["rule:" .. data.key])
        row.label:SetTextColor(colors.textHover:GetRGB())
        row:SetScript("OnMouseDown", OnRowMouseDown)
    end
end

--- Repaints the detail pane for one selected criterion. `__detail` is the
--- test seam this writes to -- a plain table, not an accessor -- so a test
--- can see what the pane shows without reaching into font string state.
---@param row table  a non-header entry from `rows`
local function RenderDetail(row)
    local locked = row.locked == true
    ruleWindow.__detail = {
        key = row.key,
        title = locale["rule:" .. row.key],
        sub = locale["rule:" .. row.key .. "Sub"],
        blurb = locale["rule:" .. row.key .. "Blurb"],
        locked = locked,
    }

    detailTitleText:SetText(ruleWindow.__detail.title)
    detailSubText:SetText(ruleWindow.__detail.sub)
    detailBlurbText:SetText(ruleWindow.__detail.blurb)
    detailLockedText:SetText(locale["ui:ruleWindowNothingToConfigure"])
    detailLockedText:SetShown(locked)
    -- For a locked criterion too: its pane is empty, and showing that empty
    -- pane is what takes the previous criterion's controls off the screen.
    local height = view.ruleControls.Render(detailControls, row)
    -- A scroll child has to carry its own height, and a locked criterion draws
    -- nothing -- a child of no height at all leaves the frame nothing to hold.
    detailControls:SetHeight(max(height, 1))
    -- A child that resized under the frame leaves the scroll range stale until
    -- the client's next layout pass, and the bar's own hideIfUnscrollable
    -- decision rides that range -- on a first open, that is the pass in which it
    -- decides whether to exist at all. Every Blizzard site that resizes a scroll
    -- child calls this; Blizzard_SharedXML/HybridScrollFrame.lua is the
    -- in-source example.
    detailScroll:UpdateScrollChildRect()
    -- Every criterion is read from the top, wherever the last one was left.
    detailScroll:SetVerticalScroll(0)
end

-- The window takes external skinning the same way view.merchantPanel does --
-- a suite that reskins one of its windows and not the other is worse than one
-- that reskins neither. Unlike BitForge_EUI/view/editor.lua, which hands its
-- close button (the same UI.CreateCloseButton widget) to facade.CloseButton
-- (editor.lua:131), this window's close button gets no facade call of its own
-- (docs/eui-integration.md, fact 10).
local function ApplyHostSkin(hostSkin, f)
    if not hostSkin or not f then return end
    hostSkin.Shell(f)
    -- Both of them: the criterion list's and the detail pane's. A host that
    -- repainted one and not the other would put two different scroll bars in
    -- one window.
    hostSkin.ScrollBar(f.scrollBar)
    hostSkin.ScrollBar(f.detailScrollBar)
end

local function BuildFrame()
    local f = UI.CreateFrame(UIParent, locale["ui:ruleWindowTitle"], FRAME_NAME)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    -- One above the merchant panel's HIGH (view/merchantPanel.lua). Sharing a
    -- strata would order by creation, which is not a guarantee.
    f:SetFrameStrata("DIALOG")

    -- Before SetMovable, and not optional: a frame that takes no mouse input
    -- never fires OnDragStart, and FrameMixin:OnLoad does not enable it.
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- UISpecialFrames closes Escape by looking the name up in _G rather than
    -- by asking a frame what it is called; UI.CreateFrame already forwarded
    -- FRAME_NAME to CreateFrame above, which sets _G[FRAME_NAME] for us.
    tinsert(UISpecialFrames, FRAME_NAME)

    local closeButton = UI.CreateCloseButton(f)
    PixelUtil.SetPoint(closeButton, "TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() f:Hide() end)
    f.closeButton = closeButton

    -- Bottom of the window itself, not the detail pane, so it stays visible
    -- whichever criterion is selected. Built before the scrollbox and detail
    -- pane below so their own bottom edges can anchor above it rather than
    -- overlapping it.
    local footer = f:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
    PixelUtil.SetPoint(footer, "BOTTOMLEFT", f, "BOTTOMLEFT", PADDING, PADDING)
    PixelUtil.SetPoint(footer, "BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, PADDING)
    footer:SetJustifyH("LEFT")
    footer:SetTextColor(colors.text:GetRGB())
    footer:SetText(locale["ui:ruleWindowDisclaimer"])
    f.footer = footer

    local scrollBox = CreateFrame("Frame", nil, f, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, f, "MinimalScrollBar")
    PixelUtil.SetPoint(scrollBox, "TOPLEFT", f, "TOPLEFT", PADDING, -(TITLE_BAR_HEIGHT + PADDING))
    PixelUtil.SetPoint(scrollBox, "BOTTOMLEFT", footer, "TOPLEFT", 0, PADDING)
    PixelUtil.SetWidth(scrollBox, LIST_WIDTH, 1)
    PixelUtil.SetPoint(scrollBar, "TOPLEFT", scrollBox, "TOPRIGHT", SCROLLBAR_GAP, 0)
    PixelUtil.SetPoint(scrollBar, "BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", SCROLLBAR_GAP, 0)
    f.scrollBar = scrollBar

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(ROW_HEIGHT)
    scrollView:SetElementInitializer("Frame", InitRowElement)
    -- Init before AddSelectionBehavior, matching every Blizzard call site,
    -- including Blizzard_CategoryList.lua. Blizzard's own
    -- SelectionBehaviorMixin:Init registers an OnDataProviderReassigned
    -- callback and wraps nothing; SetDataProvider itself comes from
    -- ScrollBoxListMixin on the WowScrollBoxList template. The harness models
    -- that reassignment-clear by wrapping SetDataProvider instead, which is
    -- why the same order is required under test.
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

    local function OnSelectionChanged(_, elementData, selected)
        local row = scrollBox:FindFrame(elementData)
        if row and row.highlight then
            row.highlight:SetShown(selected)
        end
        if selected and not elementData.isHeader then
            RenderDetail(elementData)
        end
    end

    selectionBehavior = ScrollUtil.AddSelectionBehavior(scrollBox)
    selectionBehavior:RegisterCallback(
        SelectionBehaviorMixin.Event.OnSelectionChanged, OnSelectionChanged, ruleWindow)

    -- Set once. The criterion list is static, and SelectionBehaviorMixin
    -- clears whatever is selected on every SetDataProvider call.
    local provider = CreateDataProvider()
    provider:InsertTable(rows)
    scrollBox:SetDataProvider(provider)
    f.scrollBox = scrollBox

    -- A criterion's title, sub-line and blurb; RenderDetail repaints these
    -- three whenever the selection changes.
    local detailPane = CreateFrame("Frame", nil, f)
    PixelUtil.SetPoint(detailPane, "TOPLEFT", scrollBar, "TOPRIGHT", PADDING, 0)
    PixelUtil.SetPoint(detailPane, "BOTTOMRIGHT", footer, "TOPRIGHT", 0, PADDING)
    f.detailPane = detailPane

    -- Stopping where the scroll child does rather than at the pane's own edge,
    -- so the heading and the controls under it share one right margin instead of
    -- the heading running out over the bar's gutter. The three regions below
    -- chain off this one, so this is the only place the inset is named.
    detailTitleText = detailPane:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutlineShadow")
    PixelUtil.SetPoint(detailTitleText, "TOPLEFT", detailPane, "TOPLEFT", 0, 0)
    PixelUtil.SetPoint(detailTitleText, "TOPRIGHT", detailPane, "TOPRIGHT",
        -(SCROLLBAR_GAP + SCROLLBAR_WIDTH), 0)
    detailTitleText:SetJustifyH("LEFT")
    detailTitleText:SetTextColor(colors.textHover:GetRGB())

    detailSubText = detailPane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
    PixelUtil.SetPoint(detailSubText, "TOPLEFT", detailTitleText, "BOTTOMLEFT", 0, -4)
    PixelUtil.SetPoint(detailSubText, "TOPRIGHT", detailTitleText, "BOTTOMRIGHT", 0, -4)
    detailSubText:SetJustifyH("LEFT")
    detailSubText:SetTextColor(colors.text:GetRGB())

    detailBlurbText = detailPane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
    PixelUtil.SetPoint(detailBlurbText, "TOPLEFT", detailSubText, "BOTTOMLEFT", 0, -8)
    PixelUtil.SetPoint(detailBlurbText, "TOPRIGHT", detailSubText, "BOTTOMRIGHT", 0, -8)
    detailBlurbText:SetJustifyH("LEFT")
    detailBlurbText:SetJustifyV("TOP")
    detailBlurbText:SetTextColor(colors.text:GetRGB())

    -- Shown only for a locked criterion (see RenderDetail), in the space
    -- view.ruleControls fills for everything else.
    detailLockedText = detailPane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
    PixelUtil.SetPoint(detailLockedText, "TOPLEFT", detailBlurbText, "BOTTOMLEFT", 0, -8)
    PixelUtil.SetPoint(detailLockedText, "TOPRIGHT", detailBlurbText, "BOTTOMRIGHT", 0, -8)
    detailLockedText:SetJustifyH("LEFT")
    detailLockedText:SetTextColor(colors.text:GetRGB())
    detailLockedText:Hide()

    -- The window the controls are read through. Its top edge follows the blurb,
    -- so a blurb that wraps to more lines in one locale than another takes the
    -- height off what is visible rather than off what is drawn -- which is the
    -- whole point of scrolling here: nothing measures a blurb's wrap, and a
    -- pane that no longer fits is reachable rather than cut.
    detailScroll = CreateFrame("ScrollFrame", nil, detailPane)
    local detailScrollBar = CreateFrame("EventFrame", nil, detailPane, "MinimalScrollBar")
    PixelUtil.SetPoint(detailScroll, "TOPLEFT", detailBlurbText, "BOTTOMLEFT", 0, -8)
    PixelUtil.SetPoint(detailScroll, "BOTTOMRIGHT", detailPane, "BOTTOMRIGHT",
        -(SCROLLBAR_GAP + SCROLLBAR_WIDTH), 0)
    PixelUtil.SetPoint(detailScrollBar, "TOPLEFT", detailScroll, "TOPRIGHT", SCROLLBAR_GAP, 0)
    PixelUtil.SetPoint(detailScrollBar, "BOTTOMLEFT", detailScroll, "BOTTOMRIGHT", SCROLLBAR_GAP, 0)
    -- Most criteria do not fill the pane, and a bar with nothing to scroll is
    -- an affordance that lies. ScrollBarMixin:Update re-reads this every time
    -- the range changes (Blizzard_SharedXML/Shared/Scroll/ScrollBar.lua).
    detailScrollBar:SetHideIfUnscrollable(true)
    -- InitScrollFrameWithScrollBar installs the OnMouseWheel handler and stops
    -- there; nothing in it enables the input that handler waits on.
    detailScroll:EnableMouseWheel(true)
    ScrollUtil.InitScrollFrameWithScrollBar(detailScroll, detailScrollBar)
    f.detailScroll = detailScroll
    f.detailScrollBar = detailScrollBar

    -- Only the space the controls get; view.ruleControls builds into it and
    -- owns everything inside. A scroll child is sized rather than anchored --
    -- the scroll frame places it -- and RenderDetail replaces the height on
    -- every repaint.
    detailControls = CreateFrame("Frame", nil, detailScroll)
    detailControls:SetSize(CONTROLS_WIDTH, 1)
    detailScroll:SetScrollChild(detailControls)

    -- The window may be built long after the host handed its facade over --
    -- the handler registered below runs only on that handover, so a lazily
    -- built window has to pick the facade up here for itself.
    ApplyHostSkin(view.skinBridge.GetSkin(), f)

    f:Hide()
    return f
end

-- Registered at file scope, not from BuildFrame: the window may never be
-- built during a session that never opens it, and the handler has to be on
-- the host's list before it dispatches either way.
view.skinBridge.OnSkin(function(hostSkin)
    ApplyHostSkin(hostSkin, frame)
end)

--- The window, or nil until Toggle has built it.
---@return table|nil
function ruleWindow.Frame()
    return frame
end

-- Nothing here subscribes to MERCHANT_CLOSED. view.merchantPanel hides on it
-- because its manifest belongs to one visit; this window is also reachable
-- from the settings panel, and a player reading a criterion has not finished
-- reading because a vendor walked off. Do not add that subscription.
function ruleWindow.Toggle()
    if frame and frame:IsShown() then
        frame:Hide()
        return
    end
    if not frame then frame = BuildFrame() end
    -- Show before Refresh: a refresh that bails on a hidden frame (the guard
    -- every panel in this suite uses) would otherwise run against nothing.
    frame:Show()
    -- First open has nothing selected yet, and Refresh below is a no-op with
    -- nothing to redraw -- without this the detail pane opens blank. Matches
    -- the approved wireframe (docs/dispatch-rule-window.html), which ends on
    -- the same select("gear").
    if not ruleWindow.Selected() then ruleWindow.Select("gear") end
    ruleWindow.Refresh()
end

--- Selects one criterion by its descriptor key. No-op for an unknown key or
--- before the window has been built.
---@param key string
function ruleWindow.Select(key)
    if not selectionBehavior then return end
    for _, row in ipairs(rows) do
        if not row.isHeader and row.key == key then
            selectionBehavior:SelectElementData(row)
            return
        end
    end
end

--- The selected criterion's key, or nil when nothing is selected yet.
---@return string|nil
function ruleWindow.Selected()
    if not selectionBehavior then return nil end
    local selected = selectionBehavior:GetSelectedElementData()[1]
    return selected and selected.key
end

--- Repaints whatever the current selection is showing. A no-op with nothing
--- selected yet -- reopening the window before any criterion has been picked
--- has nothing to redraw.
function ruleWindow.Refresh()
    if not frame or not frame:IsShown() or not selectionBehavior then return end
    local selected = selectionBehavior:GetSelectedElementData()[1]
    if selected then
        RenderDetail(selected)
    end
end

view.ruleWindow = ruleWindow

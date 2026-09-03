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

-- The detail pane. One form for both cases -- Screen and element-anchored --
-- because the two point pickers mean the same thing either way: my corner to
-- their corner. Where the numbers are stored differs, and
-- control.editor.Detail has already resolved that, so nothing here has to know.
--
-- Ports the standalone addon's Core/UI/Detail.lua. Its 3x3 grids of check
-- buttons are two dropdowns here: the grid was nine widgets spelling out a list
-- of nine names, and BitForge's widget library already draws that list.

local PANE_TOP = 42                -- clears the 32px title bar UI.CreateFrame draws
local PANE_LEFT = 264              -- clears the list and its scroll bar
local GAP = 8
local ROW_GAP = 22                 -- leaves room for a field's label above it
local CONTROL_HEIGHT = 24
local NUMBER_WIDTH = 90
local TEXT_WIDTH = 170
local DROPDOWN_WIDTH = 260
local BUTTON_HEIGHT = 24

-- ~70 elements will not fit on screen (Blizzard_Menu/Menu.lua).
local MENU_SCROLL_HEIGHT = 480

---@class BitForge.EUI.View.Detail
local detailPane = {}

local pane, currentKey, currentKind

-- What the target dropdown was last built for. Rebuilding it walks the anchor
-- graph once per candidate (control.editor.Targets), and Show runs on every
-- repaint: every edit anywhere in the form fires one, through
-- view.editor.Refresh, and most of them cannot have changed this list at all --
-- a width, a label, a delete held pending on some other row. The radio list
-- only changes when the element changes or the buffer does; anything else gets
-- SignalUpdate, which re-reads the selection from the descriptions already
-- built (DropdownButton.lua) without generating anything.
--
-- NOT the search box, which is the cheap thing to assume: view/list.lua's
-- OnTextChanged calls list.Refresh() directly and never view.Repaint(), so a
-- keystroke there rebuilds the list alone and never reaches this pane.
local menuKey, menuGeneration

--- What the form is showing, buffer laid over store, or nil when the key
--- stopped existing under the pane.
---@return table|nil
local function currentDetail()
    return currentKey and control.editor.Detail(currentKey) or nil
end

--- Route one field of the form into the pending buffer. Every widget below
--- writes through here and none writes to the model.
---@param field string
---@param value any
local function setPending(field, value)
    -- A commit can arrive after the pane has let go of its selection: hiding
    -- the pane while a number box has focus fires OnEditFocusLost, and deleting
    -- an anchor hides it.
    if currentKey == nil then return end

    control.editor.SetPending(currentKey, field, value)
    view.editor.Refresh()
end

--- A labelled box that commits on Enter or focus loss and restores on Escape,
--- matching EllesmereUI's own cog boxes (EUI_UnlockMode.lua:9573).
---@param parent table
---@param labelText string
---@param read fun(): number|nil
---@param write fun(value: number)
---@return table box
local function numberBox(parent, labelText, read, write)
    local box = UI.CreateEditBox(parent)
    box:SetSize(NUMBER_WIDTH, CONTROL_HEIGHT)

    local label = parent:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    label:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 0, 2)
    label:SetText(labelText)
    box.label = label

    local function commit()
        local value = tonumber(box:GetText())
        -- Unparseable text is not an error to report -- it is a half-typed
        -- number. Snap back to the held value and say nothing.
        if value == nil then
            box:SetText(tostring(read() or 0))
            return
        end
        -- Nothing typed, nothing to hold. Committing a value the buffer already
        -- shows would manufacture an unsaved change out of clicking into a box
        -- and out again, and the footer would then claim a save that writes
        -- nothing.
        if value == read() then return end
        write(value)
    end

    -- HookScript for these two: EditBoxMixin:OnLoad binds them first
    -- (BitForge/APIs/UI/Templates/EditBox.lua) to clear focus and repaint
    -- the border, and a hook runs after what is already there rather than
    -- replacing it.
    box:HookScript("OnEnterPressed", commit)
    box:HookScript("OnEditFocusLost", commit)

    -- SetScript for Escape, and this one is NOT a hook. The mixin's Escape
    -- handler clears focus, focus loss is what commits, and a hook runs after
    -- it -- so hooking here would commit the text being discarded and only then
    -- restore, leaving the box showing a value it had already saved. Escape
    -- would be Enter with extra steps. Taking the handler over loses nothing:
    -- clearing focus is all the mixin's does, and this does it too, after the
    -- restore, so the commit that focus loss triggers sees the held value and
    -- returns without writing.
    box:SetScript("OnEscapePressed", function()
        box:SetText(tostring(read() or 0))
        box:ClearFocus()
    end)

    return box
end

--- A labelled box that commits a string, on the same terms as numberBox above.
---@param parent table
---@param labelText string
---@param field string  the pending field it writes
---@param read fun(): string|nil
---@return table box
local function textBox(parent, labelText, field, read)
    local box = UI.CreateEditBox(parent)
    box:SetSize(TEXT_WIDTH, CONTROL_HEIGHT)

    local label = parent:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    label:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 0, 2)
    label:SetText(labelText)
    box.label = label

    local function commit()
        local value = box:GetText()
        if value == (read() or "") then return end
        setPending(field, value)
    end

    box:HookScript("OnEnterPressed", commit)
    box:HookScript("OnEditFocusLost", commit)
    box:SetScript("OnEscapePressed", function()
        box:SetText(read() or "")
        box:ClearFocus()
    end)

    return box
end

--- The menu builder for one of the two point pickers.
---@param field "point"|"relPoint"
---@return function
local function pointMenu(field)
    return function(_, rootDescription)
        for _, point in ipairs(control.editor.AnchorPoints()) do
            rootDescription:CreateRadio(point,
                function()
                    local shown = currentDetail()
                    return shown ~= nil and shown[field] == point
                end,
                function() setPending(field, point) end)
        end
    end
end

local function buildTargetMenu(_, rootDescription)
    rootDescription:SetScrollMode(MENU_SCROLL_HEIGHT)

    local function isSelected(target)
        local shown = currentDetail()
        return shown ~= nil and shown.target == target
    end

    local function setSelected(target)
        -- The Screen entry carries no data, so `target` is nil for it. The
        -- buffer cannot store nil -- it would read as "the player did not touch
        -- the target" -- so the sentinel says "explicitly cleared" instead.
        setPending("target", target == nil and control.editor.NONE or target)
    end

    -- "Screen", never "UIParent". EllesmereUI's own save anchors to UIParent
    -- when no anchor entry exists, so Screen is not a special mode -- it is the
    -- default relationship.
    rootDescription:CreateRadio(locale["ui:targetScreen"], isSelected, setSelected, nil)
    for _, target in ipairs(control.editor.Targets(currentKey)) do
        rootDescription:CreateRadio(target.label, isSelected, setSelected, target.key)
    end
end

local function onDeleteClick()
    local key = currentKey
    if key == nil then return end

    -- A separate confirmation from the layout wipe's, and worded harder: a
    -- discarded layout is rebuilt from EllesmereUI on the next login, but an
    -- anchor definition exists ONLY in our SavedVariables and nothing in the
    -- game can re-derive it. StaticPopup_ShowGenericConfirmation(text, callback)
    -- runs the callback on accept and nothing on cancel (StaticPopup.lua).
    StaticPopup_ShowGenericConfirmation(
        format(locale["ui:anchorDeleteConfirm"], key),
        function()
            -- A pending edit like any other: nothing is lost until Save.
            control.editor.SetPending(key, "delete", true)
            currentKey, currentKind = nil, nil
            pane:Hide()
            view.editor.Refresh()
        end)
end

--- Build the form and register its own repaint.
---@param parent table  the editor window
---@return table pane
function detailPane.Create(parent)
    pane = CreateFrame("Frame", nil, parent)
    pane:SetPoint("TOPLEFT", parent, "TOPLEFT", PANE_LEFT, -PANE_TOP)
    -- Against the footer rather than the window: the footer already carries the
    -- window's padding on both sides, so the pane inherits it and the two
    -- cannot drift apart.
    pane:SetPoint("BOTTOMRIGHT", parent.footer, "TOPRIGHT", 0, GAP)

    -- Each of the three text rows spans the pane and stacks under the one
    -- before it, so both of its horizontal anchors carry the SAME vertical
    -- offset: a region given two tops that disagree has no rectangle to draw
    -- itself in, and a note long enough to wrap is exactly what these are for.
    pane.title = pane:CreateFontString(nil, "OVERLAY", "BitForgeFontLarge")
    pane.title:SetPoint("TOPLEFT", pane, "TOPLEFT", 0, 0)
    pane.title:SetPoint("TOPRIGHT", pane, "TOPRIGHT", 0, 0)
    pane.title:SetJustifyH("LEFT")

    pane.channel = pane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    pane.channel:SetPoint("TOPLEFT", pane.title, "BOTTOMLEFT", 0, -GAP / 2)
    pane.channel:SetPoint("TOPRIGHT", pane.title, "BOTTOMRIGHT", 0, -GAP / 2)
    pane.channel:SetJustifyH("LEFT")
    pane.channel:SetTextColor(colors.text:GetRGB())

    pane.note = pane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    pane.note:SetPoint("TOPLEFT", pane.channel, "BOTTOMLEFT", 0, -GAP / 2)
    pane.note:SetPoint("TOPRIGHT", pane.channel, "BOTTOMRIGHT", 0, -GAP / 2)
    pane.note:SetJustifyH("LEFT")
    pane.note:SetWordWrap(true)
    pane.note:SetTextColor(colors.point:GetRGB())

    pane.targetLabel = pane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    pane.targetLabel:SetPoint("TOPLEFT", pane.note, "BOTTOMLEFT", 0, -ROW_GAP)
    pane.targetLabel:SetText(locale["ui:target"])

    pane.target = UI.CreateDropdown(pane, locale["ui:targetScreen"])
    pane.target:SetSize(DROPDOWN_WIDTH, CONTROL_HEIGHT)
    pane.target:SetPoint("TOPLEFT", pane.targetLabel, "BOTTOMLEFT", 0, -GAP / 2)

    pane.myPointLabel = pane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    pane.myPointLabel:SetPoint("TOPLEFT", pane.target, "BOTTOMLEFT", 0, -ROW_GAP)
    pane.myPointLabel:SetText(locale["ui:myPoint"])

    pane.myPoint = UI.CreateDropdown(pane)
    pane.myPoint:SetSize(TEXT_WIDTH, CONTROL_HEIGHT)
    pane.myPoint:SetPoint("TOPLEFT", pane.myPointLabel, "BOTTOMLEFT", 0, -GAP / 2)
    pane.myPoint:SetupMenu(pointMenu("point"))

    pane.theirPointLabel = pane:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    pane.theirPointLabel:SetPoint("TOPLEFT", pane.myPointLabel, "TOPLEFT", TEXT_WIDTH + GAP * 2, 0)
    pane.theirPointLabel:SetText(locale["ui:theirPoint"])

    pane.theirPoint = UI.CreateDropdown(pane)
    pane.theirPoint:SetSize(TEXT_WIDTH, CONTROL_HEIGHT)
    pane.theirPoint:SetPoint("TOPLEFT", pane.theirPointLabel, "BOTTOMLEFT", 0, -GAP / 2)
    pane.theirPoint:SetupMenu(pointMenu("relPoint"))

    pane.x = numberBox(pane, locale["ui:offsetX"],
        function() local shown = currentDetail() return shown and shown.x end,
        function(value) setPending("x", value) end)
    pane.x:SetPoint("TOPLEFT", pane.myPoint, "BOTTOMLEFT", 0, -ROW_GAP)

    pane.y = numberBox(pane, locale["ui:offsetY"],
        function() local shown = currentDetail() return shown and shown.y end,
        function(value) setPending("y", value) end)
    pane.y:SetPoint("TOPLEFT", pane.x, "TOPRIGHT", GAP * 2, 0)

    pane.width = numberBox(pane, locale["ui:width"],
        function() local shown = currentDetail() return shown and shown.w end,
        function(value) setPending("w", value) end)
    pane.width:SetPoint("TOPLEFT", pane.x, "BOTTOMLEFT", 0, -ROW_GAP)

    pane.height = numberBox(pane, locale["ui:height"],
        function() local shown = currentDetail() return shown and shown.h end,
        function(value) setPending("h", value) end)
    pane.height:SetPoint("TOPLEFT", pane.width, "TOPRIGHT", GAP * 2, 0)

    -- ANCHOR FRAMES ONLY. Ours carry a key and a label that ordinary elements
    -- do not, and they are created and destroyed here because nothing else in
    -- either addon can create them.
    pane.keyBox = textBox(pane, locale["ui:key"], "anchorKey",
        function() local shown = currentDetail() return shown and shown.anchorKey end)
    pane.keyBox:SetPoint("TOPLEFT", pane.width, "BOTTOMLEFT", 0, -ROW_GAP)
    pane.keyLabel = pane.keyBox.label

    pane.labelBox = textBox(pane, locale["ui:label"], "label",
        function() local shown = currentDetail() return shown and shown.label end)
    pane.labelBox:SetPoint("TOPLEFT", pane.keyBox, "TOPRIGHT", GAP * 2, 0)
    pane.labelLabel = pane.labelBox.label

    pane.delete = UI.CreateButton(nil, pane, nil, locale["ui:anchorDelete"])
    pane.delete:SetHeight(BUTTON_HEIGHT)
    pane.delete:SetPoint("TOPLEFT", pane.keyBox, "BOTTOMLEFT", 0, -GAP * 2)
    pane.delete:SetScript("OnClick", onDeleteClick)

    -- Every widget that commits on focus loss, in one place: releaseFocus walks
    -- these before the pane switches to another key.
    pane.boxes = { pane.x, pane.y, pane.width, pane.height, pane.keyBox, pane.labelBox }

    pane:Hide()
    parent.detail = pane

    view.AddRefresher(function()
        if currentKey then detailPane.Show(currentKey, currentKind) end
    end)
    return pane
end

--- Release any box still holding focus, so the commit that focus loss triggers
--- runs while `currentKey` is still the key that box was showing.
---
--- Show hides and disables widgets further down -- the key and label boxes for
--- an element, the size boxes for something that cannot be resized -- and doing
--- that to a focused box drops its focus, which commits. With `currentKey`
--- already moved on, that commit lands in the row the pane just switched TO:
--- an anchor key typed and not entered would be written into the element the
--- player clicked, and lost from the draft it was typed into.
---
--- ONLY on a switch -- see the guard at the call site.
local function releaseFocus()
    for _, box in ipairs(pane.boxes) do
        box:ClearFocus()
    end
end

--- Repaint one box, unless the player is typing in it.
---
--- Focus and the pending buffer are already preserved across a same-key
--- repaint, but the visible text is a third thing. Clicking a dropdown does not
--- clear an edit box's focus in the client, so "type into X, then pick a
--- corner" runs a repaint over a box that still holds the caret: rewriting it
--- would swallow the half-typed number, with nothing committed and nothing
--- said. The box a player is inside is the one place the form is not the
--- authority on its own contents.
---@param box table
---@param text string
local function setBoxText(box, text)
    if box:HasFocus() then return end
    box:SetText(text)
end

--- Open the form on one key.
---@param key string
---@param kind string  the row's kind, remembered so a repaint reopens the same thing
function detailPane.Show(key, kind)
    -- On a switch only, and before currentKey moves. See releaseFocus.
    --
    -- Most calls here are not switches: every commit anywhere in the form runs
    -- the refreshers, and this pane's own refresher re-opens it on the key it
    -- is already showing. Blurring on those would take the box the player is
    -- still typing into -- a dropdown pick, a delete, a refused save -- and
    -- write its unconfirmed text into the buffer with it.
    --
    -- A box that loses focus during a same-key repaint -- SetEnabled(false) on
    -- the size boxes when canResize flips -- still commits, and correctly:
    -- currentKey has not moved, so it commits to the row it belongs to.
    if key ~= currentKey or kind ~= currentKind then
        releaseFocus()
    end

    currentKey, currentKind = key, kind

    local shown = control.editor.Detail(key)
    if not shown then
        -- The key stopped existing under the pane -- a reverted draft, or an
        -- element whose module unregistered. Let go of it, or every later
        -- repaint retries.
        currentKey, currentKind = nil, nil
        pane:Hide()
        return
    end
    pane:Show()

    pane.title:SetText(shown.isDraft and locale["ui:anchorNew"] or key)

    if shown.channel == "eui" then
        pane.channel:SetText(format(locale["ui:channelEui"], tostring(shown.side or "?")))
    elseif shown.channel == "bitforge" then
        pane.channel:SetText(locale["ui:channelBitForge"])
    else
        pane.channel:SetText(locale["ui:channelScreen"])
    end

    -- One note line, showing WHY something is unavailable rather than hiding
    -- it. A refusal outranks the rest: it is the one thing that will stop the
    -- save, and it is the same sentence /bitforge eui apply prints for the same
    -- definition -- formatted by the resolver that owns the refusal's shape.
    local note = ""
    if shown.refusal then
        note = control.resolver.FormatRefusal(shown.refusal)
    elseif shown.noteKey then
        note = locale[shown.noteKey]
    end
    pane.note:SetText(note)

    -- control.editor.Targets already excluded everything a login would refuse,
    -- so this only renders the list.
    pane.target:SetEnabled(shown.canAnchorTo)
    local generation = control.editor.Generation()
    if menuKey ~= key or menuGeneration ~= generation then
        pane.target:SetupMenu(buildTargetMenu)
        menuKey, menuGeneration = key, generation
    else
        pane.target:SignalUpdate()
    end
    pane.target.Label:SetText(shown.targetLabel or locale["ui:targetScreen"])

    pane.myPoint.Label:SetText(shown.point)
    pane.theirPoint.Label:SetText(shown.relPoint)

    setBoxText(pane.x, tostring(shown.x or 0))
    setBoxText(pane.y, tostring(shown.y or 0))
    setBoxText(pane.width, tostring(shown.w or ""))
    setBoxText(pane.height, tostring(shown.h or ""))
    pane.width:SetEnabled(shown.canResize)
    pane.height:SetEnabled(shown.canResize)

    local isAnchor = shown.kind == "anchor"
    pane.keyBox:SetShown(isAnchor)
    pane.keyLabel:SetShown(isAnchor)
    pane.labelBox:SetShown(isAnchor)
    pane.labelLabel:SetShown(isAnchor)
    pane.delete:SetShown(isAnchor)

    if isAnchor then
        setBoxText(pane.keyBox, shown.anchorKey or "")
        -- Only a draft's key can be typed. An existing anchor's key is its
        -- identity in EllesmereUI's registry, so renaming it would orphan every
        -- layout entry that targets it -- delete and re-create instead, which
        -- is honest about what it costs. The definition itself is protected a
        -- layer down rather than by this widget: control.editor.Validate
        -- refuses any key that would land on a definition already there.
        pane.keyBox:SetEnabled(shown.isDraft)
        pane.delete:SetEnabled(not shown.isDraft)
        setBoxText(pane.labelBox, shown.label or "")
    end
end

--- Open the form on a new anchor frame.
---
--- Seeds nothing. The draft becomes a pending edit the moment the player types
--- into it, and not before: an unnamed draft is a problem Validate refuses, so
--- one created merely by opening this would leave a player who changed their
--- mind unable to save anything until they found the Revert button. Coming back
--- to it therefore also keeps whatever was already typed.
function detailPane.ShowNewAnchor()
    detailPane.Show(control.editor.DRAFT_KEY, "anchor")
end

--- Paint the form in the host UI's theme. Every widget of it: a window whose
--- frame is themed and whose form is not reads as two addons, and this module
--- exists to live inside EllesmereUI.
---
--- Facade names are verbatim from its SKINNING_API.md (S.Dropdown, S.EditBox,
--- S.Button) -- core pcalls the handler, so a name that is wrong fails silently
--- and is indistinguishable from a host that never answered.
---@param facade table
function detailPane.ApplySkin(facade)
    facade.Dropdown(pane.target)
    facade.Dropdown(pane.myPoint)
    facade.Dropdown(pane.theirPoint)

    for _, box in ipairs(pane.boxes) do
        facade.EditBox(box)
    end

    facade.Button(pane.delete)
end

view.detail = detailPane

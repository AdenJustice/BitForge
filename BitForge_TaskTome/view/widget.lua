---@class BitForge.TaskTome
local ns = select(2, ...)

local CreateFrame = CreateFrame
local UIParent = UIParent
local GameTooltip = GameTooltip

local ipairs = ipairs

---@type BitForge.TaskTome.Model
local model = ns.model
---@type BitForge.TaskTome.Control
local control = ns.control
---@type BitForge.TaskTome.Locale
local locale = ns.locale
---@type BitForge.TaskTome.Enum
local enum = ns.enum
local UI = BitForge.UI

---@type BitForge.TaskTome.View
local view = ns.view

do
    ---@class BitForge.TaskTome.View.Widget
    local widget = {}

    local frame = UI.CreateFrame(UIParent)
    local size = model.GetWidgetSize()
    frame:SetSize(size.w, size.h)
    frame:SetResizeBounds(200, 160)
    frame:SetResizable(true)
    frame:SetFrameStrata("MEDIUM")

    -- Not optional, and not something UI.CreateFrame does for its callers: a
    -- frame that takes no mouse input never sees the button press, so the drag
    -- registered below would arm a gesture OnDragStart is never told about.
    -- Without this the widget could not be moved at all, locked or not.
    frame:EnableMouse(true)

    -- Registered once, for the life of the frame. The lock is expressed by
    -- SetMovable and read back from IsMovable; registering the drag only in the
    -- unlocked branch left it armed for good, since the locked branch had no
    -- matching release.
    frame:RegisterForDrag("LeftButton")

    frame:Hide()

    local resizeGrip = CreateFrame("Button", nil, frame)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resizeGrip:SetNormalTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Highlight")

    local function OnResizeStart()
        if not model.IsWidgetLocked() then frame:StartSizing("BOTTOMRIGHT") end
    end
    local function OnResizeStop()
        frame:StopMovingOrSizing()
        model.SetWidgetSize(frame:GetWidth(), frame:GetHeight())
    end
    resizeGrip:SetScript("OnMouseDown", OnResizeStart)
    resizeGrip:SetScript("OnMouseUp", OnResizeStop)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    PixelUtil.SetHeight(header, 20, 1)

    local titleText = header:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    titleText:SetPoint("LEFT", header, "LEFT", 4, 0)
    titleText:SetText(locale["status:widgetTitle"])

    -- Close button. Anchored first and the header buttons chained leftwards off
    -- each other from here, so adding or removing one does not mean recomputing
    -- an absolute offset for every button to its left.
    --
    -- NoScripts rather than the UIPanelCloseButton every other window in the
    -- suite uses: that template's own OnClick hides its parent, which here is
    -- the header rather than the widget. The atlas textures scale, so the
    -- shared close art still sizes down to match the 16px icon buttons beside
    -- it.
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButtonNoScripts")
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)

    -- Through widget.Hide, not frame:Hide: closing records the widget as hidden
    -- so it stays down across a reload, exactly as the minimap toggle does.
    local function OnCloseClick() widget.Hide() end
    closeBtn:SetScript("OnClick", OnCloseClick)

    --- The hover affordance shared by the header's icon buttons.
    ---
    --- The close button brings its own from its template; the rest are a bare
    --- texture on a plain Button, and a 16px icon that does not react to the
    --- pointer does not read as something to click. That is how the gear -- the
    --- one way to the configuration window from here -- went unfound.
    ---@param button Button
    local function AddIconHighlight(button)
        button:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
    end

    -- Lock button
    local lockBtn = CreateFrame("Button", nil, header)
    lockBtn:SetSize(16, 16)
    lockBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    AddIconHighlight(lockBtn)
    local lockIcon = lockBtn:CreateTexture(nil, "ARTWORK")
    lockIcon:SetAllPoints()

    -- Gear button (opens Config)
    local gearBtn = CreateFrame("Button", nil, header)
    gearBtn:SetSize(16, 16)
    gearBtn:SetPoint("RIGHT", lockBtn, "LEFT", -2, 0)
    AddIconHighlight(gearBtn)
    local gearIcon = gearBtn:CreateTexture(nil, "ARTWORK")
    gearIcon:SetAllPoints()
    gearIcon:SetTexture("Interface/Buttons/UI-OptionsButton")

    local function OnGearClick() view.configFrame.Toggle() end
    gearBtn:SetScript("OnClick", OnGearClick)

    local function UpdateLockVisual()
        local locked = model.IsWidgetLocked()
        lockIcon:SetTexture(locked
            and "Interface/Buttons/LockButton-Locked-Up"
            or "Interface/Buttons/LockButton-Unlocked-Up")
        -- The whole of the lock, in one call. The drag stays registered either
        -- way and the handlers read this back, so there is a single place the
        -- locked state lives.
        frame:SetMovable(not locked)
    end

    local function OnLockClick()
        model.SetWidgetLocked(not model.IsWidgetLocked())
        UpdateLockVisual()
    end
    lockBtn:SetScript("OnClick", OnLockClick)

    -- Scope toggle: this character, or every character. Hidden on a
    -- single-character account, where the second mode says nothing new.
    local scopeBtn = CreateFrame("Button", nil, header)
    scopeBtn:SetSize(16, 16)
    scopeBtn:SetPoint("RIGHT", gearBtn, "LEFT", -2, 0)
    AddIconHighlight(scopeBtn)
    local scopeIcon = scopeBtn:CreateTexture(nil, "ARTWORK")
    scopeIcon:SetAllPoints()

    local orientBtn = CreateFrame("Button", nil, header)
    orientBtn:SetSize(16, 16)
    orientBtn:SetPoint("RIGHT", scopeBtn, "LEFT", -2, 0)
    AddIconHighlight(orientBtn)
    local orientIcon = orientBtn:CreateTexture(nil, "ARTWORK")
    orientIcon:SetAllPoints()

    local function UpdateModeVisuals()
        local isAll = model.GetWidgetScope() == enum.SCOPE_ALL
        scopeIcon:SetTexture(isAll
            and "Interface/FriendsFrame/UI-Toast-FriendOnlineIcon"
            or "Interface/Icons/INV_Misc_GroupLooking")
        scopeBtn:SetShown(#BitForge:GetKnownCharacters() > 1)
        orientBtn:SetShown(isAll)
        orientIcon:SetTexture(model.GetWidgetOrientation() == enum.ORIENT_BY_CHAR
            and "Interface/Buttons/UI-GuildButton-MOTD-Up"
            or "Interface/Buttons/UI-GuildButton-PublicNote-Up")
    end

    local function OnScopeClick()
        model.SetWidgetScope(model.GetWidgetScope() == enum.SCOPE_ALL
            and enum.SCOPE_ME or enum.SCOPE_ALL)
        UpdateModeVisuals()
        widget.Refresh()
    end
    scopeBtn:SetScript("OnClick", OnScopeClick)

    local function OnOrientClick()
        model.SetWidgetOrientation(model.GetWidgetOrientation() == enum.ORIENT_BY_CHAR
            and enum.ORIENT_BY_TASK or enum.ORIENT_BY_CHAR)
        UpdateModeVisuals()
        widget.Refresh()
    end
    orientBtn:SetScript("OnClick", OnOrientClick)

    -- Tooltips describe what a click will do from the current state, not what
    -- the icon currently shows, so the hint stays actionable rather than
    -- merely descriptive.
    local function OnGearEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(locale["tooltip:openConfig"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end

    local function OnLockEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(model.IsWidgetLocked()
            and locale["tooltip:widgetLocked"] or locale["tooltip:widgetUnlocked"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end

    local function OnScopeEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(model.GetWidgetScope() == enum.SCOPE_ALL
            and locale["tooltip:scopeAll"] or locale["tooltip:scopeMe"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end

    local function OnOrientEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(model.GetWidgetOrientation() == enum.ORIENT_BY_CHAR
            and locale["tooltip:orientByChar"] or locale["tooltip:orientByTask"], 1, 1, 1, 1, true)
        GameTooltip:Show()
    end

    local function OnHeaderButtonLeave()
        GameTooltip:Hide()
    end

    gearBtn:SetScript("OnEnter", OnGearEnter)
    gearBtn:SetScript("OnLeave", OnHeaderButtonLeave)
    lockBtn:SetScript("OnEnter", OnLockEnter)
    lockBtn:SetScript("OnLeave", OnHeaderButtonLeave)
    scopeBtn:SetScript("OnEnter", OnScopeEnter)
    scopeBtn:SetScript("OnLeave", OnHeaderButtonLeave)
    orientBtn:SetScript("OnEnter", OnOrientEnter)
    orientBtn:SetScript("OnLeave", OnHeaderButtonLeave)

    -- IsMovable is the lock, read back rather than tracked a second time. The
    -- drag registration is permanent, so a locked widget still gets these; the
    -- sizing grip guards itself the same way.
    local function OnDragStart(self)
        if not self:IsMovable() then return end
        self:StartMoving()
    end
    local function OnDragStop(self)
        if not self:IsMovable() then return end
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        model.SetWidgetPos(x, y)
    end

    frame:SetScript("OnDragStart", OnDragStart)
    frame:SetScript("OnDragStop", OnDragStop)

    function widget.Show()
        local pos = model.GetWidgetPos()
        frame:ClearAllPoints()
        if pos.x ~= 0 or pos.y ~= 0 then
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        UpdateLockVisual()
        UpdateModeVisuals()
        widget.Refresh()
        frame:Show()
        model.SetWidgetVisible(true)
    end

    function widget.Hide()
        frame:Hide()
        model.SetWidgetVisible(false)
    end

    function widget.Toggle()
        if frame:IsShown() then
            widget.Hide()
        else
            widget.Show()
        end
    end

    -- Task Tree (ScrollBoxListTreeListView)

    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -32)
    scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 8)

    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    local treeView = CreateScrollBoxListTreeListView(20, 2, 2, 2, 2, 1)
    treeView:SetElementExtent(22)

    -- How far a finished row's name is dimmed. Read by the row renderer and by
    -- the class-colour label alike: colour markup wins over SetTextColor, so a
    -- coloured name has to carry the same dim itself or it would read as
    -- brightly finished as outstanding.
    local COMPLETED_DIM = 0.5

    local function OnCheckboxClick(self)
        if model.GetWidgetScope() ~= enum.SCOPE_ME then return end
        local taskId = self:GetParent().taskId
        if not taskId then return end
        if model.IsCompleted(taskId) then
            control.tasks.UncompleteTask(taskId)
        else
            control.tasks.CompleteTask(taskId)
        end
        widget.Refresh()
    end

    -- Which headers the player has collapsed, by the stable key the provider
    -- builder stamps on each node. Keyed rather than held by node reference
    -- because every Refresh builds a brand-new provider and TreeNodeMixin:Init
    -- leaves every node expanded -- so without this a collapse would survive
    -- only until the next repaint, and a repaint follows every tick and every
    -- reset. Session-scoped on purpose: this is view state, not a preference.
    local collapsedKeys = {}

    local function OnRowMouseDown(self, mouseButton)
        local elementData = self._elementData
        if mouseButton ~= "LeftButton" or not elementData then return end
        -- GetSize, not HasChildren: TreeNodeMixin has no HasChildren, and
        -- Blizzard's own tree rows test the child count directly
        -- (Blizzard_SharedXML/TreeListDataProvider.lua:44).
        if elementData:GetSize() == 0 then return end

        -- No Refresh here. SetCollapsed invalidates the provider, which repaints
        -- the visible rows by itself; rebuilding the provider instead would
        -- discard the toggle that just happened.
        local collapsed = elementData:ToggleCollapsed()
        local collapseKey = elementData:GetData().collapseKey
        if collapseKey then
            collapsedKeys[collapseKey] = collapsed or nil
        end
    end

    treeView:SetElementFactory(function(factory, node)
        factory("Frame", function(rowFrame, elementData)
            -- One-time frame setup
            if not rowFrame._initialized then
                rowFrame._initialized = true

                -- Collapse arrow
                rowFrame.arrow = rowFrame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
                rowFrame.arrow:SetPoint("LEFT", rowFrame, "LEFT", 2, 0)
                rowFrame.arrow:SetWidth(12)

                -- Task name
                rowFrame.nameText = rowFrame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
                rowFrame.nameText:SetPoint("LEFT", rowFrame.arrow, "RIGHT", 2, 0)
                rowFrame.nameText:SetPoint("RIGHT", rowFrame, "RIGHT", -28, 0)
                rowFrame.nameText:SetJustifyH("LEFT")
                rowFrame.nameText:SetWordWrap(false)

                -- Checkbox
                rowFrame.checkbox = UI.CreateCheckButton(nil, rowFrame, nil, true)
                rowFrame.checkbox:SetSize(20, 20)
                rowFrame.checkbox:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
                rowFrame.checkbox:SetScript("OnClick", OnCheckboxClick)

                rowFrame.countText = rowFrame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
                rowFrame.countText:SetPoint("RIGHT", rowFrame.checkbox, "LEFT", -4, 0)
                rowFrame.countText:SetJustifyH("RIGHT")

                rowFrame:SetScript("OnMouseDown", OnRowMouseDown)
            end

            -- Data bind. A row is a (task, character) pair: in "me" mode the
            -- character is always the current one, and only then is the
            -- checkbox interactive. Cross-character rows report; they do not
            -- edit, so a mis-click cannot tick a chore off on an alt.
            local data = elementData:GetData()
            rowFrame._elementData = elementData

            -- Arrow
            if elementData:GetSize() > 0 then
                rowFrame.arrow:SetText(elementData:IsCollapsed() and "▶" or "▼")
                rowFrame.arrow:Show()
            else
                rowFrame.arrow:SetText("")
                rowFrame.arrow:Hide()
            end

            if data.isHeader then
                -- A character header, a task header, or the account-wide group
                -- heading. Marked explicitly by the builder rather than inferred
                -- from which of charKey/task happens to be set, so a task header
                -- (task set, no charKey) is never mistaken for a leaf row and
                -- never shows one character's personal completion next to a
                -- roster-wide count.
                rowFrame.taskId = nil
                rowFrame.nameText:SetText(data.label)
                -- Restated rather than assumed: row frames are recycled, so a
                -- header landing on a frame that last drew a finished task
                -- would otherwise inherit that row's dim.
                rowFrame.nameText:SetTextColor(1, 1, 1)
                rowFrame.checkbox:Hide()
                rowFrame.countText:SetText(data.doneCount .. "/" .. data.totalCount)
                rowFrame.countText:Show()
            else
                local task = data.task
                local charKey = data.charKey or BitForge:GetCurrentCharacter()
                local completed = model.IsCompletedFor(task.id, charKey)
                local editable = model.GetWidgetScope() == enum.SCOPE_ME

                rowFrame.taskId = task.id
                -- `label` overrides the task name where a row means something
                -- else: under a task header in "Character by Task", a row IS a
                -- character, and repeating the task name there would answer the
                -- one question that orientation exists to ask with the same
                -- string on every row.
                rowFrame.nameText:SetText(data.label or task.name)
                local shade = completed and COMPLETED_DIM or 1
                rowFrame.nameText:SetTextColor(shade, shade, shade)

                rowFrame.checkbox:SetChecked(completed)
                rowFrame.checkbox:SetEnabled(editable)
                rowFrame.checkbox:Show()

                if data.doneCount then
                    rowFrame.countText:SetText(data.doneCount .. "/" .. data.totalCount)
                    rowFrame.countText:Show()
                else
                    rowFrame.countText:Hide()
                end
            end
        end)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, treeView)

    local ACCOUNT_WIDE_KEY = "group:accountWide"

    --- Inserts one node, stamping it with the identity collapse state is keyed
    --- by and restoring whatever state that key last held.
    local function insertNode(parentNode, data, collapseKey)
        data.collapseKey = collapseKey
        local node = parentNode:Insert(data)
        if collapsedKeys[collapseKey] then
            -- affectChildren false, skipInvalidate true: the provider is not
            -- attached to the scroll box yet, so there is nothing to repaint.
            node:SetCollapsed(true, false, true)
        end
        return node
    end

    --- A character key, in that character's class colour.
    ---
    --- A character with no colour is the ordinary case rather than a fault --
    --- BitForge:GetCharacterClassColor documents the two ways it happens -- so
    --- both nil paths fall through to the bare key and render exactly as they
    --- always did.
    ---
    --- Only the label is coloured. charKey stays the plain string everywhere it
    --- is used as an identity -- completion lookups, collapse keys -- because
    --- markup in a key would match nothing.
    ---@param charKey    string
    ---@param completed? boolean  dim the colour, as a finished row's name is
    ---@return string
    local function CharacterLabel(charKey, completed)
        local color = BitForge:GetCharacterClassColor(charKey)
        if not color then return charKey end

        if completed then
            local red, green, blue = color:GetRGB()
            color = CreateColor(red * COMPLETED_DIM, green * COMPLETED_DIM,
                blue * COMPLETED_DIM)
        end

        return color:WrapTextInColorCode(charKey)
    end

    -- Note: must not be called from within the ScrollBox frame factory or
    -- initializer -- SetDataProvider is not re-entrant. Safe from user input
    -- handlers (OnClick/OnMouseDown).
    function widget.Refresh()
        local dataProvider = CreateTreeDataProvider()

        local function insertTasks(parentNode, subtree, charKey, keyPrefix)
            for _, entry in ipairs(subtree) do
                -- Path-shaped, because the same task appears under several
                -- character headers in all-characters mode and collapsing it for
                -- one must not collapse it for the rest.
                local key = keyPrefix .. "/task:" .. entry.task.id
                local node = insertNode(parentNode,
                    { task = entry.task, charKey = charKey }, key)
                if #entry.children > 0 then
                    insertTasks(node, entry.children, charKey, key)
                end
            end
        end

        if model.GetWidgetScope() == enum.SCOPE_ME then
            insertTasks(dataProvider, model.GetVisibleTaskTree(), nil, "me")
        elseif model.GetWidgetOrientation() == enum.ORIENT_BY_CHAR then
            for _, group in ipairs(model.GetTreeByCharacter()) do
                local key = group.isAccountWide and ACCOUNT_WIDE_KEY
                    or ("char:" .. group.charKey)
                local header = insertNode(dataProvider, {
                    isHeader   = true,
                    label      = group.isAccountWide
                        and locale["group:accountWide"] or CharacterLabel(group.charKey),
                    doneCount  = group.doneCount,
                    totalCount = group.totalCount,
                }, key)
                insertTasks(header, group.children,
                    group.isAccountWide and nil or group.charKey, key)
            end
        else
            for _, group in ipairs(model.GetTreeByTask()) do
                if group.isAccountWide then
                    local header = insertNode(dataProvider, {
                        isHeader   = true,
                        label      = locale["group:accountWide"],
                        doneCount  = group.doneCount,
                        totalCount = group.totalCount,
                    }, ACCOUNT_WIDE_KEY)
                    insertTasks(header, group.children, nil, ACCOUNT_WIDE_KEY)
                else
                    local key = "task:" .. group.task.id
                    local header = insertNode(dataProvider, {
                        isHeader   = true,
                        task       = group.task,
                        label      = group.task.name,
                        doneCount  = group.doneCount,
                        totalCount = group.totalCount,
                    }, key)
                    -- A child here is a character, so it is labelled with that
                    -- character. `charKey` alone would not do it: the row
                    -- renderer reads charKey for the completion lookup and never
                    -- displays it.
                    for _, child in ipairs(group.children) do
                        insertNode(header, {
                            charKey = child.charKey,
                            task    = group.task,
                            label   = CharacterLabel(child.charKey, child.completed),
                        }, key .. "/char:" .. child.charKey)
                    end
                end
            end
        end

        scrollBox:SetDataProvider(dataProvider)
    end

    view.widget = widget
end

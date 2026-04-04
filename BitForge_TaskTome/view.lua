---@class BitForge.TaskTome
---@field view BitForge.TaskTome.View

---@type string, BitForge.TaskTome
local ADDON_NAME, ns = ...

local CreateFrame = CreateFrame
local UIParent = UIParent

local ipairs = ipairs
local format = string.format

local model = ns.model
local control = ns.control
local UI = BitForge.UI
local locale = ns.locale
local enum = ns.enum

---@class BitForge.TaskTome.View
local view = ns.view

-- =============================================================================
-- Widget
-- =============================================================================

do
    local widget = {}

    local frame = UI.CreateFrame(UIParent)
    frame:SetSize(220, 300)
    frame:SetFrameStrata("MEDIUM")
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
    PixelUtil.SetHeight(header, 20, 1)

    local titleText = header:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    titleText:SetPoint("LEFT", header, "LEFT", 4, 0)
    titleText:SetText(locale["status:widgetTitle"])

    -- Gear button (opens Config)
    local gearBtn = CreateFrame("Button", nil, header)
    gearBtn:SetSize(16, 16)
    gearBtn:SetPoint("RIGHT", header, "RIGHT", -20, 0)
    local gearIcon = gearBtn:CreateTexture(nil, "ARTWORK")
    gearIcon:SetAllPoints()
    gearIcon:SetTexture("Interface/Buttons/UI-OptionsButton")

    local function OnGearClick() view.configFrame.Toggle() end
    gearBtn:SetScript("OnClick", OnGearClick)

    -- Lock button
    local lockBtn = CreateFrame("Button", nil, header)
    lockBtn:SetSize(16, 16)
    lockBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    local lockIcon = lockBtn:CreateTexture(nil, "ARTWORK")
    lockIcon:SetAllPoints()

    local function UpdateLockVisual()
        if model.IsWidgetLocked() then
            lockIcon:SetTexture("Interface/Buttons/LockButton-Locked-Up")
            frame:SetMovable(false)
        else
            lockIcon:SetTexture("Interface/Buttons/LockButton-Unlocked-Up")
            frame:SetMovable(true)
            frame:RegisterForDrag("LeftButton")
        end
    end

    local function OnLockClick()
        model.SetWidgetLocked(not model.IsWidgetLocked())
        UpdateLockVisual()
    end
    lockBtn:SetScript("OnClick", OnLockClick)

    local function OnDragStart(self) self:StartMoving() end
    local function OnDragStop(self)
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

    local function OnCheckboxClick(self)
        local taskId = self:GetParent().taskId
        if model.IsCompleted(taskId) then
            control.tasks.UncompleteTask(taskId)
        else
            control.tasks.CompleteTask(taskId)
        end
        widget.Refresh()
    end

    local function OnRowMouseDown(self, mouseButton)
        if mouseButton == "LeftButton" and self._elementData and self._elementData:HasChildren() then
            self._elementData:ToggleCollapsed()
            widget.Refresh()
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

                rowFrame:SetScript("OnMouseDown", OnRowMouseDown)
            end

            -- Data bind
            local data = elementData:GetData()
            local task = data.task
            rowFrame.taskId = task.id
            rowFrame._elementData = elementData

            -- Arrow
            if elementData:HasChildren() then
                rowFrame.arrow:SetText(elementData:IsCollapsed() and "▶" or "▼")
                rowFrame.arrow:Show()
            else
                rowFrame.arrow:SetText("")
                rowFrame.arrow:Hide()
            end

            -- Name (strikethrough if completed)
            local completed = model.IsCompleted(task.id)
            if completed then
                rowFrame.nameText:SetTextColor(0.5, 0.5, 0.5)
                -- No native strikethrough in WoW fonts; use gray + dim as visual cue
            else
                rowFrame.nameText:SetTextColor(1, 1, 1)
            end
            rowFrame.nameText:SetText(task.name)

            -- Checkbox
            rowFrame.checkbox:SetChecked(completed)
        end)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, treeView)

    -- Note: must not be called from within the ScrollBox frame factory or initializer —
    -- SetDataProvider is not re-entrant. Safe to call from user input handlers (OnClick/OnMouseDown).
    function widget.Refresh()
        local dataProvider = CreateTreeDataProvider()

        local function insertNodes(parentNode, subtree)
            for _, entry in ipairs(subtree) do
                local node = parentNode:Insert({ task = entry.task })
                if #entry.children > 0 then
                    insertNodes(node, entry.children)
                end
            end
        end

        insertNodes(dataProvider, model.GetVisibleTaskTree())
        scrollBox:SetDataProvider(dataProvider)
    end

    view.widget = widget
end

-- =============================================================================
-- Config Frame
-- =============================================================================

do
    local LEFT_WIDTH = 236
    local configFrame = {}

    local frame = CreateFrame("Frame", "BitForge_TaskTomeConfig", UIParent, "BackdropTemplate")
    Mixin(frame, UI.Mixins.Frame)
    frame:OnLoad(true)
    frame:SetTitle(locale["settings:configTitle"])
    frame:SetSize(600, 480)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    local function OnDragStart(self) self:StartMoving() end
    local function OnDragStop(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        model.SetConfigPos(x, y)
    end
    frame:SetScript("OnDragStart", OnDragStart)
    frame:SetScript("OnDragStop", OnDragStop)
    frame:Hide()

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    local function OnCloseClick() configFrame.Hide() end
    closeBtn:SetScript("OnClick", OnCloseClick)

    -- Divider line between panels
    local divider = frame:CreateTexture(nil, "ARTWORK")
    PixelUtil.SetWidth(divider, 1, 1)
    divider:SetColorTexture(0.3, 0.3, 0.3, 1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 244, -40)
    divider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 244, 8)

    -- Left Panel: Task Tree

    local leftPanel = CreateFrame("Frame", nil, frame)
    leftPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -40)
    leftPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 52)
    leftPanel:SetWidth(LEFT_WIDTH)

    local scrollBox = CreateFrame("Frame", nil, leftPanel, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, leftPanel, "MinimalScrollBar")
    scrollBox:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 0, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", leftPanel, "BOTTOMRIGHT", -12, 0)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 1, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 1, 0)

    -- "Add Root Task" button below the scroll
    local addRootBtn = UI.CreateButton(nil, leftPanel, nil, locale["btn:addRootTask"])
    addRootBtn:SetPoint("BOTTOMLEFT", leftPanel, "BOTTOMLEFT", 0, -44)
    addRootBtn:SetWidth(LEFT_WIDTH)
    local function OnAddRootTask()
        local id = control.tasks.CreateTask({
            name = "New Task",
            parentId = nil,
            reset = enum.RESET_NONE,
            warbandAssigned = false,
            completionScope = enum.SCOPE_CHAR,
        })
        configFrame.RefreshTree()
        configFrame.SelectTask(id)
    end
    addRootBtn:SetScript("OnClick", OnAddRootTask)

    -- Row Rendering

    local ROW_HEIGHT = 22
    local selectedId = nil

    local function OnRowClick(self)
        configFrame.SelectTask(self.taskId)
    end

    -- indent=20 matches the per-depth indent applied by the tree view automatically.
    -- Padding args: top=2, bottom=2, left=2, right=2, spacing=1
    local treeView = CreateScrollBoxListTreeListView(20, 2, 2, 2, 2, 1)
    treeView:SetElementExtent(ROW_HEIGHT)

    treeView:SetElementFactory(function(factory, node)
        factory("BitForge_TaskTomeRowTemplate", function(rowFrame, elementData)
            -- One-time frame setup
            if not rowFrame._initialized then
                rowFrame._initialized = true
                rowFrame:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
                rowFrame:SetScript("OnClick", OnRowClick)

                rowFrame.nameText = rowFrame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
                rowFrame.nameText:SetPoint("LEFT", rowFrame, "LEFT", 4, 0)
                rowFrame.nameText:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
                rowFrame.nameText:SetJustifyH("LEFT")

                local sel = rowFrame:CreateTexture(nil, "BACKGROUND")
                sel:SetAllPoints()
                sel:SetColorTexture(0.2, 0.4, 0.8, 0.3)
                sel:Hide()
                rowFrame.selTex = sel
            end

            -- Data bind
            local data = elementData:GetData()
            local task = data.task
            rowFrame.taskId = task.id
            rowFrame.nameText:SetText(task.name)
            rowFrame.selTex:SetShown(task.id == selectedId)
        end)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, treeView)

    -- Provider

    local function InsertChildrenIntoNode(parentNode, parentId)
        for _, task in ipairs(model.GetChildren(parentId)) do
            local node = parentNode:Insert({ task = task })
            InsertChildrenIntoNode(node, task.id)
        end
    end

    local function BuildProvider()
        local provider = CreateTreeDataProvider()
        InsertChildrenIntoNode(provider:GetRootNode(), nil)
        return provider
    end

    -- Walks the mutated provider after a drop and writes parentId + sortOrder back to the model.
    local function SyncProviderToModel(provider)
        local function syncNode(node, parentId)
            for i, child in ipairs(node:GetNodes()) do
                local task = child:GetData().task
                model.SetParent(task.id, parentId)
                model.SetSortOrder(task.id, i)
                syncNode(child, task.id)
            end
        end
        syncNode(provider:GetRootNode(), nil)
    end

    -- Drag-and-Drop Behavior

    -- Uses Blizzard's tree drag behavior: handles edge-scroll, Above/Below/Inside detection,
    -- and drop visuals via the built-in ScrollBoxDragLineTemplate / ScrollBoxDragBoxTemplate.
    local dragBehavior = ScrollUtil.InitDefaultTreeDragBehavior(scrollBox)
    dragBehavior:SetReorderable(true)
    dragBehavior:SetFinalizeDrop(function(contextData)
        SyncProviderToModel(contextData.dataProvider)
        configFrame.RefreshTree()
    end)

    function configFrame.RefreshTree()
        scrollBox:SetDataProvider(BuildProvider())
        view.widget.Refresh()
    end

    function configFrame.SelectTask(id)
        selectedId = id
        scrollBox:ForEachFrame(function(rowFrame)
            if rowFrame.selTex then
                rowFrame.selTex:SetShown(rowFrame.taskId == selectedId)
            end
        end)
        configFrame.PopulateForm(id)
    end

    -- configFrame.PopulateForm defined below in Form Binding section

    function configFrame.Show()
        local pos = model.GetConfigPos()
        frame:ClearAllPoints()
        if pos.x ~= 0 or pos.y ~= 0 then
            frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        configFrame.RefreshTree()
        frame:Show()
    end

    function configFrame.Hide()
        frame:Hide()
    end

    function configFrame.Toggle()
        if frame:IsShown() then
            configFrame.Hide()
        else
            configFrame.Show()
        end
    end

    -- Right Panel: Detail Editor

    local rightPanel = CreateFrame("Frame", nil, frame)
    rightPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 252, -40)
    rightPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 36)

    -- Name
    local nameLabel = rightPanel:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    nameLabel:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 4, -8)
    nameLabel:SetText(locale["settings:taskName"])

    local nameEdit = UI.CreateEditBox(rightPanel)
    nameEdit:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
    nameEdit:SetWidth(330)

    -- Reset dropdown
    local RESET_VALUES = { enum.RESET_NONE, enum.RESET_DAILY, enum.RESET_WEEKLY }
    local RESET_LABELS = { locale["menu:resetNone"], locale["menu:resetDaily"], locale["menu:resetWeekly"] }
    local resetValue = RESET_VALUES[1]

    local resetLabel = rightPanel:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    resetLabel:SetPoint("TOPLEFT", nameEdit, "BOTTOMLEFT", 0, -8)
    resetLabel:SetText(locale["settings:resetCycle"])

    local resetDropdown = UI.CreateDropdown(rightPanel, RESET_LABELS[1])
    resetDropdown:SetPoint("TOPLEFT", resetLabel, "BOTTOMLEFT", 0, -2)
    resetDropdown:SetWidth(200)
    resetDropdown:SetupMenu(function(dd, root)
        for i, resetVal in ipairs(RESET_VALUES) do
            local val, lbl = resetVal, RESET_LABELS[i]
            root:CreateRadio(lbl,
                function() return resetValue == val end,
                function()
                    resetValue = val
                    resetDropdown.Label:SetText(lbl)
                end
            )
        end
    end)

    -- Warband checkbox
    local warbandCheck = UI.CreateCheckButton(nil, rightPanel, locale["settings:warbandAssigned"], true)
    warbandCheck:SetPoint("TOPLEFT", resetDropdown, "BOTTOMLEFT", 0, -8)

    -- Completion scope dropdown
    local SCOPE_VALUES = { enum.SCOPE_CHAR, enum.SCOPE_WARBAND }
    local SCOPE_LABELS = { locale["menu:scopeChar"], locale["menu:scopeWarband"] }
    local scopeValue = SCOPE_VALUES[1]

    local scopeLabel = rightPanel:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    scopeLabel:SetPoint("TOPLEFT", warbandCheck, "BOTTOMLEFT", 0, -8)
    scopeLabel:SetText(locale["settings:completionScope"])

    local scopeDropdown = UI.CreateDropdown(rightPanel, SCOPE_LABELS[1])
    scopeDropdown:SetPoint("TOPLEFT", scopeLabel, "BOTTOMLEFT", 0, -2)
    scopeDropdown:SetWidth(200)
    scopeDropdown:SetupMenu(function(dd, root)
        for i, scopeVal in ipairs(SCOPE_VALUES) do
            local val, lbl = scopeVal, SCOPE_LABELS[i]
            root:CreateRadio(lbl,
                function() return scopeValue == val end,
                function()
                    scopeValue = val
                    scopeDropdown.Label:SetText(lbl)
                end
            )
        end
    end)

    -- Opt state dropdown
    local OPT_VALUES = { enum.OPT_FOLLOW, enum.OPT_IN, enum.OPT_OUT }
    local OPT_LABELS = { locale["menu:optFollow"], locale["menu:optIn"], locale["menu:optOut"] }
    local optValue = OPT_VALUES[1]

    local optLabel = rightPanel:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    optLabel:SetPoint("TOPLEFT", scopeDropdown, "BOTTOMLEFT", 0, -8)
    optLabel:SetText(locale["settings:optState"])

    local optDropdown = UI.CreateDropdown(rightPanel, OPT_LABELS[1])
    optDropdown:SetPoint("TOPLEFT", optLabel, "BOTTOMLEFT", 0, -2)
    optDropdown:SetWidth(200)
    optDropdown:SetupMenu(function(dd, root)
        for i, optVal in ipairs(OPT_VALUES) do
            local val, lbl = optVal, OPT_LABELS[i]
            root:CreateRadio(lbl,
                function() return optValue == val end,
                function()
                    optValue = val
                    optDropdown.Label:SetText(lbl)
                end
            )
        end
    end)

    -- Save button
    local saveBtn = UI.CreateButton(nil, rightPanel, nil, locale["btn:save"])
    saveBtn:SetPoint("BOTTOMLEFT", rightPanel, "BOTTOMLEFT", 4, 4)
    local function OnSaveClick()
        if selectedId == nil then return end
        local name = nameEdit:GetText()
        if not name or name:match("^%s*$") then
            BitForge:Print(locale["msg:nameRequired"])
            return
        end
        control.tasks.UpdateTask(selectedId, {
            name = name,
            reset = resetValue,
            warbandAssigned = warbandCheck:GetChecked(),
            completionScope = scopeValue,
        })
        control.tasks.SetOptState(selectedId, optValue)
        configFrame.RefreshTree()
    end
    saveBtn:SetScript("OnClick", OnSaveClick)

    -- Add Child button
    local addChildBtn = UI.CreateButton(nil, rightPanel, nil, locale["btn:addChildTask"])
    addChildBtn:SetPoint("LEFT", saveBtn, "RIGHT", 6, 0)
    local function OnAddChildTask()
        if selectedId == nil then return end
        local id = control.tasks.CreateTask({
            name = "New Task",
            parentId = selectedId,
            reset = enum.RESET_NONE,
            warbandAssigned = false,
            completionScope = enum.SCOPE_CHAR,
        })
        configFrame.RefreshTree()
        configFrame.SelectTask(id)
    end
    addChildBtn:SetScript("OnClick", OnAddChildTask)

    -- Delete button (danger styling)
    local deleteBtn = UI.CreateButton(nil, rightPanel, nil, locale["btn:deleteTask"])
    deleteBtn:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -4, 4)
    local redBg = { r = 0.60, g = 0.10, b = 0.10, a = 1.00 }
    local redHov = { r = 0.80, g = 0.20, b = 0.20, a = 1.00 }
    deleteBtn:GetNormalTexture():SetVertexColor(redBg.r, redBg.g, redBg.b, redBg.a)
    deleteBtn:GetPushedTexture():SetVertexColor(redBg.r * 0.7, redBg.g * 0.7, redBg.b * 0.7, redBg.a)
    deleteBtn:GetHighlightTexture():SetVertexColor(1, 0.4, 0.4, 0.3)
    deleteBtn:SetBackdropBorderColor(redBg.r, redBg.g, redBg.b, redBg.a)
    deleteBtn:HookScript("OnEnter", function(btn)
        btn:GetNormalTexture():SetVertexColor(redHov.r, redHov.g, redHov.b, redHov.a)
        btn:SetBackdropBorderColor(1, 0.4, 0.4, 1)
    end)
    deleteBtn:HookScript("OnLeave", function(btn)
        btn:GetNormalTexture():SetVertexColor(redBg.r, redBg.g, redBg.b, redBg.a)
        btn:SetBackdropBorderColor(redBg.r, redBg.g, redBg.b, redBg.a)
    end)
    local function OnDeleteClick()
        if selectedId == nil then return end
        local idToDelete = selectedId
        local task = model.GetTask(idToDelete)
        if not task then return end
        local descendants = model.GetDescendantIds(idToDelete)
        local msg
        if #descendants > 0 then
            msg = format(locale["msg:deleteConfirm"], task.name, #descendants)
        else
            msg = format(locale["msg:deleteSingle"], task.name)
        end
        StaticPopupDialogs["BFTASKTOME_DELETE"] = {
            text = msg,
            button1 = locale["btn:confirmDelete"],
            button2 = locale["btn:cancel"],
            OnAccept = function()
                control.tasks.DeleteTask(idToDelete)
                if selectedId == idToDelete then
                    selectedId = nil
                    configFrame.PopulateForm(nil)
                end
                configFrame.RefreshTree()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("BFTASKTOME_DELETE")
    end
    deleteBtn:SetScript("OnClick", OnDeleteClick)

    -- Form Binding

    local function SetFormEnabled(enabled)
        nameEdit:SetEnabled(enabled)
        resetDropdown:SetEnabled(enabled)
        warbandCheck:SetEnabled(enabled)
        scopeDropdown:SetEnabled(enabled)
        optDropdown:SetEnabled(enabled)
        saveBtn:SetEnabled(enabled)
        addChildBtn:SetEnabled(enabled)
        deleteBtn:SetEnabled(enabled)
        if enabled then
            nameEdit:SetTextColor(1, 1, 1)
        else
            nameEdit:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    function configFrame.PopulateForm(id)
        if id == nil then
            nameEdit:SetText("")
            resetValue = RESET_VALUES[1]
            resetDropdown.Label:SetText(RESET_LABELS[1])
            warbandCheck:SetChecked(false)
            scopeValue = SCOPE_VALUES[1]
            scopeDropdown.Label:SetText(SCOPE_LABELS[1])
            optValue = OPT_VALUES[1]
            optDropdown.Label:SetText(OPT_LABELS[1])
            SetFormEnabled(false)
            return
        end

        local task = model.GetTask(id)
        if not task then
            SetFormEnabled(false); return
        end

        nameEdit:SetText(task.name)

        -- Reset
        resetValue = task.reset
        for i, resetVal in ipairs(RESET_VALUES) do
            if resetVal == resetValue then
                resetDropdown.Label:SetText(RESET_LABELS[i]); break
            end
        end

        warbandCheck:SetChecked(task.warbandAssigned)

        -- Scope
        scopeValue = task.completionScope
        for i, scopeVal in ipairs(SCOPE_VALUES) do
            if scopeVal == scopeValue then
                scopeDropdown.Label:SetText(SCOPE_LABELS[i]); break
            end
        end

        -- Opt state
        optValue = model.GetOptState(id)
        for i, optVal in ipairs(OPT_VALUES) do
            if optVal == optValue then
                optDropdown.Label:SetText(OPT_LABELS[i]); break
            end
        end

        SetFormEnabled(true)
    end

    -- Called once at file load time to set initial state
    SetFormEnabled(false)

    view.configFrame = configFrame
end

-- =============================================================================
--  Settings Panel
-- =============================================================================

do
    local settingsPanel = {}

    local function OnOpenConfig()
        view.configFrame.Show()
    end

    function settingsPanel.Init()
        local cat = BitForge.Settings.NewSubcategory(ADDON_NAME, locale["settings:taskTomePanel"], locale)
        cat:AddInitializer(CreateSettingsButtonInitializer(
            locale["settings:config"],
            locale["settings:openConfig"],
            OnOpenConfig,
            nil, true
        ))
    end

    view.settingsPanel = settingsPanel
end

--- @type string, ns.Core
local ADDON_NAME, ns = ...
local utils          = ns.utils
local params         = ns.params
local assets         = ns.assets
local gui            = ns.gui
local L              = ns.locale
--- @class BF_CoreView
local view           = ns.view

--- =========================================================
--- Caches
--- =========================================================

local _ipairs        = ipairs
local _format        = string.format
local _cos           = math.cos
local _sin           = math.sin
local _rad           = math.rad
local _deg           = math.deg
local _atan2         = math.atan2
local _wipe          = table.wipe



local _CreateFrame                    = CreateFrame
local _CreateScrollBoxListLinearView  = CreateScrollBoxListLinearView
local _CreateDataProvider             = CreateDataProvider
local _InitScrollBoxListWithScrollBar = ScrollUtil.InitScrollBoxListWithScrollBar
local _GetCursorPosition              = GetCursorPosition

local _STANDARD_TEXT_FONT             = STANDARD_TEXT_FONT
local _UIParent                       = UIParent
local _Minimap                        = Minimap

--- =========================================================
--- Minimap Button
--- =========================================================

local MINIMAP_BUTTON_RADIUS           = 80

local function updateMinimapButtonPosition(btn, angle)
    local rad = _rad(angle)
    btn:SetPoint("CENTER", _Minimap, "CENTER",
        MINIMAP_BUTTON_RADIUS * _cos(rad),
        MINIMAP_BUTTON_RADIUS * _sin(rad))
end

function view:CreateMinimapButton(settings)
    local angle = settings.minimapPos or 220

    local btn = _CreateFrame("Button", ADDON_NAME .. "MinimapButton", _Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetClampedToScreen(false)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT")

    local background = btn:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    local classIcon = assets:GetClassIcon(params.character.class)
    iconTex:SetSize(17, 17)
    iconTex:SetTexture(classIcon or "Interface\\Icons\\INV_Misc_QuestionMark")
    iconTex:SetPoint("TOPLEFT", 7, -6)
    iconTex:SetTexCoord(0, 1, 0, 1)

    -- Border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    updateMinimapButtonPosition(btn, angle)

    btn:SetShown(not settings.hide)

    -- Drag to reposition
    btn:SetScript("OnDragStart", function(self)
        if settings.lock then return end
        self:SetScript("OnUpdate", function(self)
            local mx, my = _Minimap:GetCenter()
            local cx, cy = _GetCursorPosition()
            local scale = _UIParent:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            angle = _deg(_atan2(cy - my, cx - mx))
            updateMinimapButtonPosition(self, angle)
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        view:Trigger("BitForge.Core.MinimapMoved", angle)
    end)

    -- Click
    btn:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            view:Trigger("BitForge.Core.OpenSettings")
        end
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L["minimapButton:tooltip_settings"])
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return btn
end

--- =========================================================
--- Migration Dialog
--- =========================================================

--- @class frame
--- @field scrollBox ScrollBoxListMixin
local migrationDialog
local migrationDialogWidgets = {} -- Track dynamically created widgets for cleanup

local function clearMigrationDialogWidgets()
    if migrationDialog then
        migrationDialog.scrollBox:SetDataProvider(_CreateDataProvider())
        migrationDialog.migrateButton = nil
        migrationDialog.purgeButton = nil
    end
    for _, widget in _ipairs(migrationDialogWidgets) do
        widget:Hide()
    end
    _wipe(migrationDialogWidgets)
end

local function createMigrationDialog()
    if migrationDialog then
        return migrationDialog
    end

    ---@type table
    local dialog = gui:CreateFrame(_UIParent, {
        width = 500,
        height = 400,
        title = L["migration:title"],
    })

    dialog:SetFrameStrata("DIALOG")
    dialog:SetPoint("CENTER", _UIParent, "CENTER", 0, 0)
    dialog:EnableMouse(true)
    dialog:SetMovable(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    dialog:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    -- Content area (inset from title bar and bottom edge)
    local content = _CreateFrame("Frame", nil, dialog)
    content:SetPoint("TOPLEFT", dialog, "TOPLEFT", 20, -40)
    content:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -20, 60)
    dialog.content = content

    -- Description text
    local description = content:CreateFontString(nil, "OVERLAY")
    description:SetFont(_STANDARD_TEXT_FONT, 12)
    description:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -10)
    description:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -10)
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    description:SetWordWrap(true)
    dialog.description = description

    -- Scrollable list area
    local listArea = _CreateFrame("Frame", nil, content)
    listArea:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -60)
    listArea:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

    local scrollBox = _CreateFrame("Frame", nil, listArea, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", listArea, "TOPLEFT", 0, 0)
    scrollBox:SetPoint("BOTTOMRIGHT", listArea, "BOTTOMRIGHT", -16, 0)

    local scrollBar = _CreateFrame("EventFrame", nil, listArea, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    local linearView = _CreateScrollBoxListLinearView()
    linearView:SetElementInitializer("BitForgeScrollElementAsCheckTemplate", function(frame, data)
        frame.Label:SetText(data.label)
        frame:SetChecked(data.checked)
        frame:SetScript("OnClick", function(self)
            data.checked = self:GetChecked()
            if data.onClick then data.onClick(self) end
        end)
    end)
    linearView:SetElementExtent(35)
    _InitScrollBoxListWithScrollBar(scrollBox, scrollBar, linearView)

    dialog.scrollBox = scrollBox
    dialog.scrollBar = scrollBar

    -- Button container
    local buttonContainer = _CreateFrame("Frame", nil, dialog)
    buttonContainer:SetSize(dialog:GetWidth() - 40, 40)
    buttonContainer:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 10)
    dialog.buttonContainer = buttonContainer

    dialog:Hide()

    return dialog
end

function view:ShowMigrationDialog(invalidList, onSelect, onSkip, onSelectionChanged)
    if not migrationDialog then
        migrationDialog = createMigrationDialog()
    end

    -- Clear previous widgets
    clearMigrationDialogWidgets()

    -- Update title and description
    migrationDialog:SetTitle(L["migration:title"])
    migrationDialog.description:SetText(L["migration:desc"])

    -- Populate scroll list
    local dataObjects = {}
    local dataProvider = _CreateDataProvider()
    for _, entry in _ipairs(invalidList) do
        local data = {
            label   = _format("|cffff0000%s (Invalid)|r", entry.nameRealm),
            checked = false,
        }
        data.onClick = utils:SafeCallback(function(frame)
            -- Capture state before clearing (ForEachFrame also unsets this frame)
            local checked = frame:GetChecked()

            -- Radio: clear all others
            for _, d in _ipairs(dataObjects) do d.checked = false end
            migrationDialog.scrollBox:ForEachFrame(function(f) f:SetChecked(false) end)

            data.checked = checked
            frame:SetChecked(checked)

            if onSelectionChanged then
                onSelectionChanged(checked and entry.guid or nil)
            end
        end, "migration radio selection")
        dataObjects[#dataObjects + 1] = data
        dataProvider:Insert(data)
    end
    migrationDialog.scrollBox:SetDataProvider(dataProvider)

    -- Migrate button
    local migrateButton = gui:CreateButton(migrationDialog.buttonContainer, {
        text = L["migration:button_migrate"],
        width = 140,
        onClick = utils:SafeCallback(function()
            if onSelect then onSelect() end
        end, "migration migrate button"),
    })
    migrateButton:Disable()
    migrateButton:SetPoint("LEFT", migrationDialog.buttonContainer, "LEFT", 20, 0)
    migrationDialogWidgets[#migrationDialogWidgets + 1] = migrateButton
    migrationDialog.migrateButton = migrateButton

    -- Skip button
    local skipButton = gui:CreateButton(migrationDialog.buttonContainer, {
        text = L["migration:button_skip"],
        width = 100,
        onClick = utils:SafeCallback(function()
            if onSkip then
                onSkip()
            end
        end, "migration skip button"),
    })
    skipButton:SetPoint("RIGHT", migrationDialog.buttonContainer, "RIGHT", -20, 0)
    migrationDialogWidgets[#migrationDialogWidgets + 1] = skipButton

    migrationDialog:Show()
end

function view:ShowPurgeDialog(invalidList, onPurge, onKeepAll, onSelectionChanged)
    if not migrationDialog then
        migrationDialog = createMigrationDialog()
    end

    -- Clear previous widgets
    clearMigrationDialogWidgets()

    -- Update title and description
    migrationDialog:SetTitle(L["purge:title"])
    migrationDialog.description:SetText(L["purge:desc"])

    -- Populate scroll list
    local dataProvider = _CreateDataProvider()
    for _, entry in _ipairs(invalidList) do
        local data = {
            label   = _format(L["purge:label"], entry.nameRealm, entry.daysSince),
            checked = false,
        }
        data.onClick = utils:SafeCallback(function(frame)
            local checked = frame:GetChecked()
            data.checked = checked
            if onSelectionChanged then
                onSelectionChanged(entry.guid, checked)
            end
        end, "migration checkbox selection")
        dataProvider:Insert(data)
    end
    migrationDialog.scrollBox:SetDataProvider(dataProvider)

    -- Purge button
    local purgeButton = gui:CreateButton(migrationDialog.buttonContainer, {
        text = L["migration:button_purge"],
        width = 140,
        onClick = utils:SafeCallback(function()
            if onPurge then onPurge() end
        end, "migration purge button"),
    })
    purgeButton:Disable()
    purgeButton:SetPoint("LEFT", migrationDialog.buttonContainer, "LEFT", 20, 0)
    migrationDialogWidgets[#migrationDialogWidgets + 1] = purgeButton
    migrationDialog.purgeButton = purgeButton

    -- Keep All button
    local keepAllButton = gui:CreateButton(migrationDialog.buttonContainer, {
        text = L["migration:button_keep_all"],
        width = 120,
        onClick = utils:SafeCallback(function()
            if onKeepAll then
                onKeepAll()
            end
        end, "migration keep all button"),
    })
    keepAllButton:SetPoint("RIGHT", migrationDialog.buttonContainer, "RIGHT", -20, 0)
    migrationDialogWidgets[#migrationDialogWidgets + 1] = keepAllButton

    migrationDialog:Show()
end

function view:UpdateMigrateButton(enabled)
    if migrationDialog and migrationDialog.migrateButton then
        if enabled then
            migrationDialog.migrateButton:Enable()
        else
            migrationDialog.migrateButton:Disable()
        end
    end
end

function view:UpdatePurgeButton(count)
    if migrationDialog and migrationDialog.purgeButton then
        if count > 0 then
            migrationDialog.purgeButton:Enable()
            migrationDialog.purgeButton:SetText(_format("%s (%d)", L["migration:button_purge"], count))
        else
            migrationDialog.purgeButton:Disable()
            migrationDialog.purgeButton:SetText(L["migration:button_purge"])
        end
    end
end

function view:HideMigrationDialog()
    if migrationDialog then
        migrationDialog:Hide()
        clearMigrationDialogWidgets()
    end
end

--- @type string, ns_core
local ADDON_NAME, ns = ...
local params = ns.params
local utils = ns.utils
local L = ns.locale
local gui = ns.gui
--- @class BF_CoreView
local view = ns.view

--- =========================================================
--- Caches
--- =========================================================

local _pairs = pairs
local _ipairs = ipairs
local _format = string.format
local _cos = math.cos
local _sin = math.sin
local _rad = math.rad
local _deg = math.deg
local _atan2 = math.atan2
local _wipe = table.wipe

local _CreateFrame = CreateFrame
local _GetCursorPosition = GetCursorPosition

local _STANDARD_TEXT_FONT = STANDARD_TEXT_FONT
local _UIParent = UIParent
local _Minimap = Minimap

--- =========================================================
--- Minimap Button
--- =========================================================

local MINIMAP_BUTTON_RADIUS = 80

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

    -- Circular icon
    local iconTex = btn:CreateTexture(nil, "BACKGROUND")
    iconTex:SetTexture("Interface/ICONS/INV_Misc_QuestionMark")
    iconTex:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    iconTex:SetAllPoints()

    local mask = btn:CreateMaskTexture()
    mask:SetTexture("Interface/CharacterFrame/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(iconTex)
    iconTex:AddMaskTexture(mask)

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
        settings.minimapPos = angle
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

local migrationDialog
local migrationDialogWidgets = {} -- Track dynamically created widgets for cleanup

local function clearMigrationDialogWidgets()
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
        title = L["migration:step1_title"],
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

    -- List container for entries
    local listContainer = _CreateFrame("Frame", nil, content)
    listContainer:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -60)
    listContainer:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    dialog.listContainer = listContainer

    -- Button container
    local buttonContainer = _CreateFrame("Frame", nil, dialog)
    buttonContainer:SetSize(dialog:GetWidth() - 40, 40)
    buttonContainer:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 10)
    dialog.buttonContainer = buttonContainer

    dialog:Hide()

    return dialog
end

function view:ShowMigrationDialog(invalidList, onSelect, onSkip)
    if not migrationDialog then
        migrationDialog = createMigrationDialog()
    end

    -- Clear previous widgets
    clearMigrationDialogWidgets()

    -- Update title and description
    migrationDialog:SetTitle(L["migration:step1_title"])
    migrationDialog.description:SetText(L["migration:step1_desc"])

    -- Track selected radio button
    local selectedGuid = nil
    local radioButtons = {}
    local migrateButton -- Declare early for closure access

    -- Create radio button entries
    local yOffset = 0
    for _, entry in _ipairs(invalidList) do
        local row = _CreateFrame("Frame", nil, migrationDialog.listContainer)
        row:SetSize(migrationDialog.listContainer:GetWidth(), 30)
        row:SetPoint("TOPLEFT", migrationDialog.listContainer, "TOPLEFT", 0, yOffset)

        -- Radio checkbox (simulated with regular checkbox)
        local checkbox = gui:CreateCheckbox(row, {
            text = _format("|cffff0000%s (Invalid)|r", entry.nameRealm),
            checked = false,
            onClick = utils:SafeCallback(function(self)
                local checked = self:GetChecked()
                if checked then
                    -- Deselect all other radio buttons
                    for _, otherCheckbox in _ipairs(radioButtons) do
                        if otherCheckbox ~= self then
                            otherCheckbox:SetChecked(false)
                        end
                    end
                    selectedGuid = entry.guid
                else
                    selectedGuid = nil
                end

                -- Update migrate button state
                if migrateButton then
                    if selectedGuid then
                        migrateButton:Enable()
                    else
                        migrateButton:Disable()
                    end
                end
            end, "migration radio selection"),
        })
        checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)

        radioButtons[#radioButtons + 1] = checkbox
        migrationDialogWidgets[#migrationDialogWidgets + 1] = checkbox

        yOffset = yOffset - 35
    end

    -- Migrate button
    migrateButton = gui:CreateButton(migrationDialog.buttonContainer, {
        text = L["migration:button_migrate"],
        width = 140,
        onClick = utils:SafeCallback(function()
            if selectedGuid and onSelect then
                onSelect(selectedGuid)
            end
        end, "migration migrate button"),
    })
    migrateButton:Disable()
    migrateButton:SetPoint("LEFT", migrationDialog.buttonContainer, "LEFT", 20, 0)
    migrationDialogWidgets[#migrationDialogWidgets + 1] = migrateButton

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

function view:ShowPurgeDialog(invalidList, onPurge, onKeepAll)
    if not migrationDialog then
        migrationDialog = createMigrationDialog()
    end

    -- Clear previous widgets
    clearMigrationDialogWidgets()

    -- Update title and description
    migrationDialog:SetTitle(L["migration:step2_title"])
    migrationDialog.description:SetText(L["migration:step2_desc"])

    -- Track selected checkboxes
    local selectedGuids = {}
    local purgeButton -- Declare early for closure access

    -- Create checkbox entries
    local yOffset = 0
    for _, entry in _ipairs(invalidList) do
        local row = _CreateFrame("Frame", nil, migrationDialog.listContainer)
        row:SetSize(migrationDialog.listContainer:GetWidth(), 30)
        row:SetPoint("TOPLEFT", migrationDialog.listContainer, "TOPLEFT", 0, yOffset)

        -- Multi-select checkbox
        local checkbox = gui:CreateCheckbox(row, {
            text = _format("|cffff0000%s (Invalid)|r", entry.nameRealm),
            checked = false,
            onClick = utils:SafeCallback(function(self)
                local checked = self:GetChecked()
                if checked then
                    selectedGuids[entry.guid] = true
                else
                    selectedGuids[entry.guid] = nil
                end

                -- Update purge button state (count selected)
                local count = 0
                for _ in _pairs(selectedGuids) do
                    count = count + 1
                end

                if purgeButton then
                    if count > 0 then
                        purgeButton:Enable()
                    else
                        purgeButton:Disable()
                    end
                    purgeButton:SetText(_format("%s (%d)", L["migration:button_purge"], count))
                end
            end, "migration checkbox selection"),
        })
        checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)

        migrationDialogWidgets[#migrationDialogWidgets + 1] = checkbox

        yOffset = yOffset - 35
    end

    -- Purge button
    purgeButton = gui:CreateButton(migrationDialog.buttonContainer, {
        text = L["migration:button_purge"],
        width = 140,
        onClick = utils:SafeCallback(function()
            if onPurge then
                -- Convert selectedGuids table to array
                local guidArray = {}
                for guid in _pairs(selectedGuids) do
                    guidArray[#guidArray + 1] = guid
                end
                onPurge(guidArray)
            end
        end, "migration purge button"),
    })
    purgeButton:Disable()
    purgeButton:SetPoint("LEFT", migrationDialog.buttonContainer, "LEFT", 20, 0)
    migrationDialogWidgets[#migrationDialogWidgets + 1] = purgeButton

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

function view:HideMigrationDialog()
    if migrationDialog then
        migrationDialog:Hide()
        clearMigrationDialogWidgets()
    end
end

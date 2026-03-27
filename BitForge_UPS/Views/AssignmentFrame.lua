local ns = select(2, ...)

local ipairs = ipairs
local pairs = pairs
local next = next
local tostring = tostring
local wipe = table.wipe
local sort = table.sort
local abs = math.abs

local CreateFrame = CreateFrame
local C_Item = C_Item

local model = ns.Model
local L = ns.L
local constants = ns.Constants

ns.AssignmentFrame = {}
local frame = ns.AssignmentFrame

local mainFrame
local leftScroll
local rightPanel
local selectedKey = nil

local ROW_HEIGHT = 20
local INDENT = 16

-- =========================================================
-- Main frame
-- =========================================================

local function CreateMainFrame()
    mainFrame = CreateFrame("Frame", "UPSAssignmentFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(600, 480)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetUserPlaced(true)
    mainFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -14)
    title:SetText(L["panel:assignments"])

    -- Left scroll panel (200px wide)
    leftScroll = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    leftScroll:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16, -36)
    leftScroll:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 16, 16)
    leftScroll:SetWidth(200)

    local leftContent = CreateFrame("Frame", nil, leftScroll)
    leftContent:SetWidth(200)
    leftScroll:SetScrollChild(leftContent)
    leftScroll.content = leftContent

    -- Right panel
    rightPanel = CreateFrame("Frame", nil, mainFrame)
    rightPanel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 230, -36)
    rightPanel:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -16, 16)
    rightPanel:Hide()

    mainFrame:Hide()
end

-- =========================================================
-- Left panel tree
-- =========================================================

local expandedClasses = {}

local function OnRowClick(categoryKey)
    selectedKey = categoryKey
    frame.RefreshRightPanel()
end

local function BuildLeftTree()
    local content = leftScroll.content
    -- Clear existing rows
    for _, child in ipairs({ content:GetChildren() }) do
        child:SetParent(nil)
    end

    local assignments = model.GetAssignments()
    local charKey     = BitForge:GetCurrentCharacter()

    -- Group CONSUMER_MAP categories by classID
    local classGroups = {} -- classID -> { { subClassID, categoryKey }, ... }
    local classOrder  = {}

    for categoryKey in pairs(constants.CONSUMER_MAP) do
        local cID, sID = categoryKey:match("^(%d+):(%d+)$")
        if cID then
            cID = tonumber(cID)
            sID = tonumber(sID)
            if cID and not classGroups[cID] then
                classGroups[cID] = {}
                classOrder[#classOrder + 1] = cID
            end
            classGroups[cID][#classGroups[cID] + 1] = { sID = sID, key = categoryKey }
        end
    end
    sort(classOrder)

    local yOffset = 0

    local function AddRow(text, depth, categoryKey, isAssigned)
        local row = CreateFrame("Button", nil, content)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", depth * INDENT, yOffset)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, yOffset)

        local label = row:CreateFontString(nil, "OVERLAY",
            isAssigned and "GameFontNormalSmall" or "GameFontDisableSmall")
        label:SetPoint("LEFT", row, "LEFT", 4, 0)
        label:SetText(text)

        if categoryKey then
            row:SetScript("OnClick", function() OnRowClick(categoryKey) end)
            if categoryKey == selectedKey then
                row:LockHighlight()
            end
        end

        yOffset = yOffset - ROW_HEIGHT
        return row
    end

    -- Standard categories
    for _, cID in ipairs(classOrder) do
        local className = C_Item.GetItemClassInfo(cID) or tostring(cID)
        local classRow  = AddRow(className, 0, nil, false)

        -- Toggle expand on click
        classRow:SetScript("OnClick", function()
            expandedClasses[cID] = not expandedClasses[cID]
            BuildLeftTree()
        end)

        if expandedClasses[cID] then
            local subClasses = classGroups[cID]
            sort(subClasses, function(a, b) return a.sID < b.sID end)
            for _, sc in ipairs(subClasses) do
                local subName  = C_Item.GetItemSubClassInfo(cID, sc.sID) or sc.key
                local assigned = model.IsCharAssigned(sc.key, charKey)
                AddRow(subName, 1, sc.key, assigned)
            end
        end
    end

    -- Custom categories
    local hasCustom = false
    for key in pairs(assignments) do
        if model.IsCustomCategory(key) then
            hasCustom = true
            break
        end
    end

    if hasCustom then
        AddRow(L["panel:customSection"], 0, nil, false)
        for key, entry in pairs(assignments) do
            if model.IsCustomCategory(key) then
                local assigned = model.IsCharAssigned(key, charKey)
                AddRow(entry.name or key, 1, key, assigned)
            end
        end
    end

    content:SetHeight(abs(yOffset) + ROW_HEIGHT)
end

-- =========================================================
-- Public
-- =========================================================

function frame.Open()
    if not mainFrame then CreateMainFrame() end
    BuildLeftTree()
    mainFrame:Show()
end

function frame.RefreshLeftPanel()
    if mainFrame and mainFrame:IsShown() then
        BuildLeftTree()
    end
end

local charCheckboxes  = {}
local expacCheckboxes = {}
local allExpacCheckbox

local function ClearRightPanel()
    for _, child in ipairs({ rightPanel:GetChildren() }) do
        child:SetParent(nil)
    end
    for _, region in ipairs({ rightPanel:GetRegions() }) do
        region:Hide()
    end
    wipe(charCheckboxes)
    wipe(expacCheckboxes)
    allExpacCheckbox = nil
end

local function BuildRightPanel(categoryKey)
    ClearRightPanel()
    if not categoryKey then
        rightPanel:Hide()
        return
    end

    local entry   = model.GetAssignment(categoryKey)
    local charKey = BitForge:GetCurrentCharacter()

    rightPanel:Show()

    local yOffset = 0

    -- Delete Category button
    local deleteBtn = CreateFrame("Button", nil, rightPanel, "UIPanelButtonTemplate")
    deleteBtn:SetSize(120, 22)
    deleteBtn:SetPoint("TOPRIGHT", rightPanel, "TOPRIGHT", 0, yOffset)
    deleteBtn:SetText(L["btn:deleteCategory"])
    deleteBtn:SetScript("OnClick", function()
        model.RemoveAssignment(categoryKey)
        selectedKey = nil
        BuildLeftTree()
        ClearRightPanel()
        rightPanel:Hide()
    end)
    yOffset = yOffset - 30

    -- =========================================================
    -- Characters
    -- =========================================================
    local charLabel = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charLabel:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, yOffset)
    charLabel:SetText(L["panel:characters"])
    yOffset = yOffset - 20

    local knownChars = BitForge:GetKnownCharacters()
    for _, cKey in ipairs(knownChars) do
        local cb = CreateFrame("CheckButton", nil, rightPanel, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, yOffset)
        cb:SetChecked(entry and entry.chars ~= nil and entry.chars[cKey] == true)

        local cLabel = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cLabel:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cLabel:SetText(cKey:match("^(.-)%-") or cKey)

        -- Recommended badge
        if entry and entry.classID and entry.subClassID then
            local catKey    = entry.classID .. ":" .. entry.subClassID
            local consumers = constants.CONSUMER_MAP[catKey] or {}
            local profs     = model.GetProfessions(cKey)
            for _, pid in ipairs(profs) do
                for _, consumer in ipairs(consumers) do
                    if pid == consumer then
                        local badge = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontGreenSmall")
                        badge:SetPoint("LEFT", cLabel, "RIGHT", 6, 0)
                        badge:SetText("★")
                        break
                    end
                end
            end
        end

        cb:SetScript("OnClick", function(self)
            if self:GetChecked() then
                model.AssignChar(categoryKey, cKey)
            else
                model.UnassignChar(categoryKey, cKey)
            end
            frame.RefreshLeftPanel()
        end)

        charCheckboxes[#charCheckboxes + 1] = cb
        yOffset = yOffset - 24
    end

    yOffset = yOffset - 10

    -- =========================================================
    -- Expansions
    -- =========================================================
    local expLabel = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    expLabel:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, yOffset)
    expLabel:SetText(L["panel:expansions"])
    yOffset = yOffset - 20

    local currentExpansions = entry and entry.expansions

    allExpacCheckbox = CreateFrame("CheckButton", nil, rightPanel, "UICheckButtonTemplate")
    allExpacCheckbox:SetSize(20, 20)
    allExpacCheckbox:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, yOffset)
    allExpacCheckbox:SetChecked(currentExpansions == nil)

    local allLabel = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    allLabel:SetPoint("LEFT", allExpacCheckbox, "RIGHT", 4, 0)
    allLabel:SetText(L["settings:allExpansions"])
    yOffset = yOffset - 24

    for _, expac in ipairs(constants.EXPANSIONS) do
        local ecb = CreateFrame("CheckButton", nil, rightPanel, "UICheckButtonTemplate")
        ecb:SetSize(20, 20)
        ecb:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 16, yOffset)
        local isChecked = currentExpansions ~= nil and currentExpansions[expac.id] == true
        ecb:SetChecked(isChecked)

        local eLabel = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        eLabel:SetPoint("LEFT", ecb, "RIGHT", 4, 0)
        eLabel:SetText(L["expansion:" .. expac.key] or expac.key)

        ecb:SetScript("OnClick", function(self)
            local expansions = {}
            for _, saved in ipairs(expacCheckboxes) do
                if saved.cb:GetChecked() then
                    expansions[saved.id] = true
                end
            end
            if next(expansions) then
                model.SetExpansions(categoryKey, expansions)
            else
                model.SetExpansions(categoryKey, nil)
            end
            -- Re-render to sync checkbox states with persisted data
            BuildRightPanel(categoryKey)
        end)

        expacCheckboxes[#expacCheckboxes + 1] = { cb = ecb, id = expac.id }
        yOffset = yOffset - 24
    end

    allExpacCheckbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            model.SetExpansions(categoryKey, nil)
            for _, saved in ipairs(expacCheckboxes) do
                saved.cb:SetChecked(false)
            end
        end
    end)

    yOffset = yOffset - 10

    -- =========================================================
    -- Items grid
    -- =========================================================
    local gridLabel = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gridLabel:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, yOffset)
    gridLabel:SetText(L["panel:items"])
    yOffset            = yOffset - 20

    local ICON_SIZE    = 32
    local ICON_PADDING = 4
    local GRID_COLS    = 8
    local gridWidth    = rightPanel:GetWidth()

    -- Drop target background
    local dropTarget   = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    dropTarget:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 0, yOffset)
    dropTarget:SetSize(gridWidth, ICON_SIZE * 3 + ICON_PADDING * 2)
    dropTarget:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    dropTarget:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    dropTarget:EnableMouse(true)

    -- Empty state hint
    local hint = dropTarget:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("CENTER")
    hint:SetText(L["panel:itemsDropHint"])

    -- Icon grid
    local iconPool = {}
    local items    = entry and entry.items or {}

    local function RefreshGrid()
        local col, row = 0, 0
        local hasItems = false
        local idx = 0

        for itemID in pairs(items) do
            hasItems = true
            idx = idx + 1

            local icon = iconPool[idx]
            if not icon then
                icon = CreateFrame("Button", nil, dropTarget)
                icon:SetSize(ICON_SIZE, ICON_SIZE)
                local tex = icon:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints()
                icon.tex = tex
                icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
                icon:RegisterForClicks("RightButtonUp")
                iconPool[idx] = icon
            end

            icon:SetPoint("TOPLEFT", dropTarget, "TOPLEFT",
                col * (ICON_SIZE + ICON_PADDING) + ICON_PADDING,
                -(row * (ICON_SIZE + ICON_PADDING) + ICON_PADDING))

            local iconPath = C_Item.GetItemIconByID(itemID)
            if iconPath then icon.tex:SetTexture(iconPath) end

            local capturedID = itemID
            icon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(capturedID)
                GameTooltip:Show()
            end)
            icon:SetScript("OnClick", function(self, button)
                if button == "RightButton" then
                    model.RemoveItem(categoryKey, capturedID)
                    RefreshGrid()
                end
            end)

            icon:Show()
            col = col + 1
            if col >= GRID_COLS then
                col = 0; row = row + 1
            end
        end

        -- Hide unused pool entries
        for i = idx + 1, #iconPool do
            iconPool[i]:Hide()
        end

        hint:SetShown(not hasItems)
    end

    RefreshGrid()

    -- Highlight border when item is on cursor (throttled to 10 Hz)
    local pollElapsed = 0
    dropTarget:SetScript("OnUpdate", function(_, elapsed)
        pollElapsed = pollElapsed + elapsed
        if pollElapsed < 0.1 then return end
        pollElapsed = 0
        if GetCursorInfo() == "item" then
            dropTarget:SetBackdropBorderColor(1, 1, 0, 1)
        else
            dropTarget:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
    end)

    -- Accept dropped items
    dropTarget:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            local cursorType, _, itemID = GetCursorInfo()
            if cursorType == "item" and itemID then
                model.AddItem(categoryKey, itemID)
                ClearCursor()
                RefreshGrid()
            end
        end
    end)
end

function frame.RefreshRightPanel()
    BuildRightPanel(selectedKey)
end

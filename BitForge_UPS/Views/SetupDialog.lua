local ns = select(2, ...)

local ipairs = ipairs
local format = string.format
local wipe = table.wipe
local remove = table.remove

local CreateFrame = CreateFrame
local C_Item = C_Item

local model = ns.Model
local L = ns.L
local constants = ns.Constants

ns.SetupDialog = {}
local dialog = ns.SetupDialog

local frame
local contentFrame
local isRerun  = false -- true when opened from Settings Panel
local isOpen   = false -- reentry guard

-- =========================================================
-- Frame creation
-- =========================================================

local function CreateDialogFrame()
    frame = CreateFrame("Frame", "UPSSetupDialog", UIParent, "BackdropTemplate")
    frame:SetSize(420, 240)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    -- Content area
    contentFrame = CreateFrame("Frame", nil, frame)
    contentFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -20)
    contentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 50)

    -- Skip Setup button (always visible)
    local skipBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    skipBtn:SetSize(100, 22)
    skipBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 14)
    skipBtn:SetText(L["btn:skipSetup"])
    skipBtn:SetScript("OnClick", function()
        model.SetInitialized(true)
        isOpen = false
        frame:Hide()
    end)

    frame:Hide()
end

-- =========================================================
-- Content helpers
-- =========================================================

local function ClearContent()
    for _, child in ipairs({ contentFrame:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
    for _, region in ipairs({ contentFrame:GetRegions() }) do
        region:Hide()
    end
end

local function AddText(text, yOffset)
    local label = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset or 0)
    label:SetWidth(contentFrame:GetWidth())
    label:SetJustifyH("LEFT")
    label:SetText(text)
    return label
end

local function AddButton(text, y, onClick)
    local btn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    btn:SetSize(160, 22)
    btn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, y)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- =========================================================
-- Mode prompt (re-run only)
-- =========================================================

local function ShowModePrompt(charName, onChosen)
    ClearContent()

    AddText(format(L["setup:modePrompt"], charName), -10)

    AddButton(L["btn:setupReset"], -50, function()
        ns.Controller.ResetCharAssignments(BitForge:GetCurrentCharacter())
        onChosen()
    end)

    AddButton(L["btn:setupAppend"], -80, function()
        onChosen()
    end)
end

-- =========================================================
-- Question flow
-- =========================================================

-- Forward declaration
local ShowNextQuestion

local questionQueue = {}

local function EnqueueQuestions(charKey)
    local charName = charKey:match("^(.-)%-")
    local profs    = model.GetProfessions(charKey)

    for _, skillLine in ipairs(profs) do
        local categories = constants.PROFESSION_CATEGORIES[skillLine]
        if categories then
            for _, categoryKey in ipairs(categories) do
                -- In Append mode, skip categories already assigned
                if not model.IsCharAssigned(categoryKey, charKey) then
                    local cID, sID = categoryKey:match("^(%d+):(%d+)$")
                    if cID then
                        local subClassName                = C_Item.GetItemSubClassInfo(tonumber(cID), tonumber(sID))
                        local label                       = format(
                            L["setup:categoryOptIn"], charName,
                            subClassName or categoryKey
                        )
                        questionQueue[#questionQueue + 1] = {
                            categoryKey = categoryKey,
                            cID         = tonumber(cID),
                            sID         = tonumber(sID),
                            label       = label,
                        }
                    end
                end
            end
        end
    end
end

local function ShowCompletion()
    ClearContent()
    AddText(L["setup:complete"], -20)

    local doneBtn = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    doneBtn:SetSize(80, 22)
    doneBtn:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, -60)
    doneBtn:SetText(L["btn:done"])
    doneBtn:SetScript("OnClick", function()
        model.SetInitialized(true)
        isOpen = false
        frame:Hide()
    end)
end

local function ShowExpansionQuestion(categoryKey, cID, sID, onAnswered)
    ClearContent()
    local subClassName = C_Item.GetItemSubClassInfo(cID, sID)
    AddText(format(L["setup:expansionFilter"], subClassName or categoryKey), -10)

    AddButton(L["settings:allExpansions"], -50, function()
        model.SetExpansions(categoryKey, nil)
        onAnswered()
    end)

    AddButton(L["btn:currentExpacOnly"], -80, function()
        -- GetExpansionLevel() returns 0-based expansion index matching Constants.EXPANSIONS
        local expacID = GetExpansionLevel()
        model.SetExpansions(categoryKey, { [expacID] = true })
        onAnswered()
    end)
end

ShowNextQuestion = function()
    if #questionQueue == 0 then
        ShowCompletion()
        return
    end

    local q = remove(questionQueue, 1)
    ClearContent()
    AddText(q.label, -10)

    -- Yes
    AddButton(L["btn:yes"], -50, function()
        local charKey = BitForge:GetCurrentCharacter()
        local entry = model.GetAssignment(q.categoryKey)
        if not entry then
            model.SetAssignment(q.categoryKey, {
                name       = nil,
                classID    = q.cID,
                subClassID = q.sID,
                chars      = {},
                expansions = nil,
                items      = {},
            })
        end
        model.AssignChar(q.categoryKey, charKey)
        ShowExpansionQuestion(q.categoryKey, q.cID, q.sID, ShowNextQuestion)
    end)

    -- No
    AddButton(L["btn:no"], -80, function()
        ShowNextQuestion()
    end)
end

-- =========================================================
-- Public API
-- =========================================================

function dialog.Open(rerun)
    if isOpen then return end -- prevent reentry while a flow is in progress
    if not frame then CreateDialogFrame() end
    isRerun = rerun or false
    isOpen = true

    wipe(questionQueue)

    local charKey  = BitForge:GetCurrentCharacter()
    local charName = charKey:match("^(.-)%-") or charKey

    frame:Show()

    if isRerun then
        ShowModePrompt(charName, function()
            EnqueueQuestions(charKey)
            ShowNextQuestion()
        end)
    else
        EnqueueQuestions(charKey)
        ShowNextQuestion()
    end
end

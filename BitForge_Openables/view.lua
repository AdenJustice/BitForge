---@class BitForge.Openables
---@field view BitForge.Openables.View

---@type string, BitForge.Openables
local ADDON_NAME, ns = ...
local C_Item = C_Item
local InCombatLockdown = InCombatLockdown

local model = ns.model
local enum = ns.enum
local locale = ns.locale
local control = ns.control

---@class BitForge.Openables.View
local view = ns.view

local BUTTON_NAME = ADDON_NAME .. "Button"
local HIDER_NAME = ADDON_NAME .. "Hider"

local pendingCandidate
local pendingDirty = false
local currentCandidate

local function applyAttributes(candidate)
    local button = view.button
    button:SetAttribute("type1", nil)
    button:SetAttribute("item", nil)
    button:SetAttribute("macrotext1", nil)

    if not candidate then return end

    if candidate.locked then
        -- Two actions are needed, so a macro rather than a plain item attribute.
        -- Casting the unlock on an already-open box is a no-op, so the same macro
        -- serves both the picking click and the opening click.
        local spellID = IsPlayerSpell(enum.SPELL_PICK_LOCK)
            and enum.SPELL_PICK_LOCK or enum.SPELL_SKELETON_PINKIE
        local spellName = C_Spell.GetSpellName(spellID)
        -- string.format raises on a nil %s in WoW's Lua 5.1 rather than
        -- coercing. IsPlayerSpell already gates this, but stay defensive:
        -- leave the attributes cleared (from above) rather than error.
        if not spellName then return end
        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext1",
            ("/cast %s\n/use %d %d"):format(spellName, candidate.bag, candidate.slot))
    else
        button:SetAttribute("type1", "item")
        button:SetAttribute("item", "item:" .. candidate.itemID)
    end
end

-- ================================================================================
-- Tooltip
-- ================================================================================

-- Debug output is deliberately not routed through ns.locale: it appears only
-- for a profile that has hand-set the module's debug flag, so translating it
-- into all eleven locale files would be upkeep for text no player sees.
local DEBUG_COLOR = CreateColor(0.55, 0.55, 0.55)

-- Inverted on first use rather than at file read: unflagged, nothing ever
-- asks for a name, and Enum.TooltipDataLineType carries dozens of members.
local lineTypeNames

local function LineTypeName(lineType)
    if not lineType then return "?" end
    lineTypeNames = lineTypeNames or tInvert(Enum.TooltipDataLineType)
    return lineTypeNames[lineType] or ("type " .. lineType)
end

local priorityNames

local function PriorityName(priority)
    priorityNames = priorityNames or tInvert(enum.PRIORITY)
    return priorityNames[priority] or "?"
end

-- The one line that answers "why is this on the button?" -- which branch of
-- detector.Classify accepted the item, and on what evidence.
local function DebugBasis(candidate)
    local reason = candidate.reason
    if reason == enum.REASON.TOOLTIP_LINE then
        return ("tooltip line %s"):format(LineTypeName(candidate.reasonDetail))
    elseif reason == enum.REASON.QUEST_GATE then
        return ("quest %s not accepted or completed"):format(tostring(candidate.reasonDetail))
    elseif reason == enum.REASON.ALLOW_LIST then
        return "ALLOW_LIST entry in ItemData.lua"
    elseif reason == enum.REASON.LOCKED_BOX then
        return "LOCKED_BOX tooltip line, unlock spell known"
    elseif reason == enum.REASON.ITEM_SPELL then
        return "ITEM_SPELL fallback: GetItemSpell and IsUsableItem both answered"
    end
    return ("unrecorded (%s)"):format(tostring(reason))
end

-- Why this item, and what would tell it apart from an item that should not be
-- here. Item class is the discriminator the pipeline leans on hardest, so it
-- is reported even though nothing in the reason string mentions it.
local function addDebugLines(candidate)
    if not model.IsDebug() then return end

    local _, itemType, itemSubType, _, _, classID, subClassID =
        C_Item.GetItemInfoInstant(candidate.itemID)

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(("[debug] item %d  bag %d slot %d"):format(
        candidate.itemID, candidate.bag, candidate.slot), DEBUG_COLOR:GetRGB())
    GameTooltip:AddLine(("[debug] shown because: %s"):format(DebugBasis(candidate)),
        DEBUG_COLOR:GetRGB())
    GameTooltip:AddLine(("[debug] class %s / %s (%s/%s)"):format(
        tostring(itemType), tostring(itemSubType), tostring(classID), tostring(subClassID)),
        DEBUG_COLOR:GetRGB())
    GameTooltip:AddLine(("[debug] priority %s (%d)  locked %s  cooldown %s"):format(
        PriorityName(candidate.priority), candidate.priority,
        tostring(candidate.locked), tostring(candidate.onCooldown)), DEBUG_COLOR:GetRGB())
end

local function showTooltip(candidate)
    -- SetOwner also clears the accumulated lines, which is what makes this
    -- safe to call on an already-open tooltip.
    GameTooltip:SetOwner(view.button, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(candidate.bag, candidate.slot)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(locale["tooltip:use"])
    GameTooltip:AddLine(locale["tooltip:skip"])
    GameTooltip:AddLine(locale["tooltip:blacklist"])
    if not model.GetLocked() then
        GameTooltip:AddLine(locale["tooltip:drag"])
    end
    addDebugLines(candidate)
    GameTooltip:Show()
end

-- OnEnter fires only when the cursor crosses the button's edge, and every click
-- swaps the candidate under a cursor that never moved: right-click skips or
-- blacklists, left-click consumes the item and the bag update rescans. Without
-- this the tooltip kept describing the previous item until the player moved the
-- mouse away and back. IsOwned keeps it to our own tooltip -- some other frame's
-- tooltip is not ours to rebuild or hide.
local function refreshTooltip(candidate)
    if not GameTooltip:IsOwned(view.button) then return end
    if not candidate then
        GameTooltip:Hide()
        return
    end
    showTooltip(candidate)
end

local function updateFace(candidate)
    local button = view.button
    if not candidate then
        button:Hide()
        refreshTooltip(nil)
        return
    end

    local icon = select(5, C_Item.GetItemInfoInstant(candidate.itemID))
    button.icon:SetTexture(icon)

    if model.GetShowCount() and candidate.stackCount > 1 then
        button.Count:SetText(candidate.stackCount)
        button.Count:Show()
    else
        button.Count:Hide()
    end

    view.RefreshCooldown()
    button:Show()
    refreshTooltip(candidate)
end

function view.SetItem(candidate)
    -- The event chain (bag updates, quest updates, etc.) is live from
    -- ADDON_LOADED, but view.Init() does not create the button until
    -- PLAYER_LOGIN — and, per the combat guard below, may defer past that.
    -- No-op here; the Init()->RequestScan() sequence re-drives this once the
    -- button exists.
    if not view.button then return end

    currentCandidate = candidate
    if InCombatLockdown() then
        -- The button is hidden by the state driver throughout combat, so this
        -- queue exists only so it is correct the moment it reappears. A nil
        -- candidate is a valid queued value (a queued clear), so a separate
        -- flag — not nil-checking pendingCandidate — tracks "is anything queued".
        pendingCandidate = candidate
        pendingDirty = true
        return
    end
    applyAttributes(candidate)
    updateFace(candidate)
end

function view.ClearItem()
    view.SetItem(nil)
end

function view.FlushPending()
    if not pendingDirty then return end
    applyAttributes(pendingCandidate)
    updateFace(pendingCandidate)
    pendingCandidate = nil
    pendingDirty = false
end

-- Populates the keybind text every other action button in the UI shows.
-- Refreshed on UPDATE_BINDINGS (control.lua) since the player can rebind at
-- any time after this first runs.
function view.RefreshHotKey()
    if not view.button then return end
    local key = GetBindingKey("CLICK " .. BUTTON_NAME .. ":LeftButton")
    local text = key and GetBindingText(key, 1) or ""
    view.button.HotKey:SetText(text)
    view.button.HotKey:SetShown(text ~= "")
end

function view.RefreshCooldown()
    local button = view.button
    if not button then return end
    if not currentCandidate or not model.GetShowCooldown() then
        button.cooldown:Clear()
        return
    end
    -- GetItemCooldown's third return is enableCooldownTimer, a bool; SetCooldown's
    -- third parameter is modRate, a number. CooldownFrame_Set is the Blizzard
    -- helper that reads the flag and clears instead of swiping when the timer is
    -- disabled or the item is ready.
    local startTime, duration, enable = C_Item.GetItemCooldown(currentCandidate.itemID)
    CooldownFrame_Set(button.cooldown, startTime, duration, enable)
end

function view.ApplyClickRegistration()
    if not view.button then return end
    if InCombatLockdown() then return end
    local useKeyDown = GetCVarBool("ActionButtonUseKeyDown")
    -- Registering both up and down would fire the action twice.
    view.button:RegisterForClicks(useKeyDown and "AnyDown" or "AnyUp")
end

function view.ApplySize()
    -- Reachable from the settings slider while the Blizzard Settings UI is
    -- open in combat. Skipped here, then re-applied from onRegenEnabled once
    -- combat ends, so the change is never lost — see view.ApplyClickRegistration.
    if InCombatLockdown() then return end
    local size = model.GetButtonSize()
    view.button:SetSize(size, size)
end

function view.ResetPosition()
    -- The DB write is not protected and always happens; only the button
    -- update needs the guard. view.RestorePosition() re-applies this exact
    -- model value from onRegenEnabled if combat swallows it here.
    model.SetPoint("CENTER", "CENTER", 0, -150)
    if InCombatLockdown() then return end
    view.button:ClearAllPoints()
    view.button:SetPoint("CENTER", view.hider, "CENTER", 0, -150)
end

function view.RestorePosition()
    if InCombatLockdown() then return end
    local point = model.GetPoint()
    view.button:ClearAllPoints()
    view.button:SetPoint(point.point, view.hider, point.relPoint, point.x, point.y)
end

function view.Init()
    if view.button then return end
    -- PLAYER_READY (and thus this call) can land mid-combat after a
    -- mid-combat /reload. Every subsequent line touches a protected frame
    -- (RegisterStateDriver, RegisterForDrag, SetAttribute, SetMovable,
    -- SetSize, SetPoint, Hide), so bail before creating anything rather than
    -- half-building state. view.button stays nil, so this guard is a no-op
    -- next time and control.lua's onRegenEnabled retries the full Init()
    -- once combat ends — no partial frame, script, or category to duplicate.
    if InCombatLockdown() then return end

    view.hider = CreateFrame("Frame", HIDER_NAME, UIParent, "SecureHandlerStateTemplate")
    view.hider:SetAllPoints(UIParent)
    -- Evaluated inside the secure environment: the button disappears on combat
    -- entry without taint, and without calling Hide() on a protected frame, which
    -- is itself blocked in combat.
    RegisterStateDriver(view.hider, "visibility", "[petbattle][vehicleui][combat] hide; show")

    -- Deliberately NOT ActionButtonTemplate. In 12.0 that template is a CheckButton
    -- inheriting FlyoutButtonTemplate, PingableActionButtonTemplate, and
    -- BaseActionButtonMixin — action-bar machinery that expects a real action slot.
    -- Creating our own four regions is ~15 lines and inherits no behaviour we then
    -- have to suppress. Verified against wow-ui-source
    -- Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml.
    local button = CreateFrame("Button", BUTTON_NAME, view.hider, "SecureActionButtonTemplate")
    view.button = button

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.Count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

    button.HotKey = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    button.HotKey:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button)

    button:SetFrameStrata("MEDIUM")
    button:RegisterForDrag("LeftButton")
    -- type2 stays nil so right-click performs no secure action and falls through
    -- to PostClick, which Task 8 installs.
    button:SetAttribute("type2", nil)

    button:SetScript("OnDragStart", function(self)
        if model.GetLocked() then return end
        -- Alt is required because the button's whole job is to be left-clicked.
        -- A plain left-drag is too easy to produce while clicking, and moving
        -- the button out from under the cursor mid-click is worse than doing
        -- nothing. Bailing here leaves the drag inert rather than moving it.
        if not IsAltKeyDown() then return end
        self:StartMoving()
    end)
    button:SetScript("OnDragStop", function(self)
        -- A drag can span the combat boundary (start out of combat, get
        -- pulled into combat mid-drag, release). StopMovingOrSizing is
        -- protected, so bail rather than throw.
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        model.SetPoint(point, relPoint, x, y)
    end)

    button:SetScript("PostClick", function(self, mouseButton)
        if mouseButton ~= "RightButton" then return end
        if not currentCandidate then return end

        if IsControlKeyDown() then
            model.SetBlacklisted(currentCandidate.itemID, true)
        else
            model.Skip(currentCandidate.itemID)
        end
        control.scanner.RequestScan()
    end)

    button:SetScript("OnEnter", function()
        if not currentCandidate then return end
        showTooltip(currentCandidate)
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    button:SetMovable(true)

    -- Colours are not optional here. GetSolidBackdrop's bgFile and edgeFile are
    -- both WHITE8X8, and CreateBackdropUnderlay skips SetBackdropColor entirely
    -- when no colour is passed, so an unstyled underlay is an opaque white
    -- square the size of the button. button.icon covers it, which hides it right
    -- up until a candidate change leaves the icon undrawn for the frames its new
    -- texture takes to stream in -- the white flash between two items.
    local colors = BitForge.UI.Colors
    BitForge.UI.Skin.CreateBackdropUnderlay(button, {
        backgroundColor = colors.bg,
        borderColor = colors.edge,
    })

    view.ApplySize()
    view.ApplyClickRegistration()
    view.RestorePosition()
    button:Hide()

    _G["BINDING_HEADER_BITFORGE_OPENABLES"] = locale["binding:header"]
    _G["BINDING_NAME_CLICK " .. BUTTON_NAME .. ":LeftButton"] = locale["binding:use"]
    view.RefreshHotKey()

    view.settingsPanel.Init()
end

-- ================================================================================
-- Settings panel
-- ================================================================================

local settingsPanel = {}

local function OnSetButtonSize(value)
    model.SetButtonSize(value)
    view.ApplySize()
end

local function OnSetShowCount(value)
    model.SetShowCount(value)
    control.scanner.RequestScan()
end

local function OnSetShowCooldown(value)
    model.SetShowCooldown(value)
    view.RefreshCooldown()
end

local function OnSetEnabled(value)
    model.SetEnabled(value)
    control.scanner.RequestScan()
end

function settingsPanel.Init()
    local category = BitForge.Settings.NewSubcategory(ADDON_NAME, locale["panel:title"], locale)

    category:AddCheckbox("enabled", model.IsEnabled, OnSetEnabled)
    category:AddCheckbox("locked", model.GetLocked, model.SetLocked)
    category:AddSlider("buttonSize", model.GetButtonSize, OnSetButtonSize,
        enum.BUTTON_SIZE_MIN, enum.BUTTON_SIZE_MAX, enum.BUTTON_SIZE_STEP)
    category:AddCheckbox("showCount", model.GetShowCount, OnSetShowCount)
    category:AddCheckbox("showCooldown", model.GetShowCooldown, OnSetShowCooldown)
    category:AddInitializer(CreateSettingsButtonInitializer(
        "", locale["settings:resetPosition"], view.ResetPosition, nil, false))
    -- The blacklist list cannot live inline in the settings panel: the vertical
    -- layout mixin returned by RegisterVerticalLayoutSubcategory accepts
    -- initializers only, and has no way to parent a raw frame into the list.
    -- A settings button opening a standalone window (ns.view.blacklistFrame) is
    -- this suite's established pattern instead — see BitForge_UPS's
    -- assignmentFrame.
    category:AddInitializer(CreateSettingsButtonInitializer(
        "", locale["settings:manageBlacklist"], view.blacklistFrame.Open, nil, false))
end

view.settingsPanel = settingsPanel

-- ================================================================================
-- Blacklist frame
-- ================================================================================
--
-- A standalone window rather than an inline settings section (see the comment in
-- settingsPanel.Init above for why). Owning the frame is also what makes Refresh
-- implementable: the list must change whenever a row is removed, and there is no
-- API to rebuild a settings initializer list after registration.

local WINDOW_WIDTH = 420
local WINDOW_HEIGHT = 360
local HEADER_HEIGHT = 30
local FOOTER_HEIGHT = 40
local SCROLL_LEFT_INSET = 14
local SCROLL_RIGHT_INSET = 34
local CONTENT_WIDTH = WINDOW_WIDTH - SCROLL_LEFT_INSET - SCROLL_RIGHT_INSET
local BLACKLIST_ROW_HEIGHT = 24

-- Item names arrive asynchronously. Rows render as an itemID placeholder until
-- ITEM_DATA_LOAD_RESULT fills them in; a stale itemID stays a placeholder rather
-- than erroring.
local function BlacklistRowLabel(itemID)
    local name = C_Item.GetItemNameByID(itemID)
    if name then return name end
    C_Item.RequestLoadItemDataByID(itemID)
    return locale["blacklist:unknownItem"]:format(itemID)
end

local blacklistFrame = {}

local mainFrame
local rowContainer
local blacklistRows = {}

local function AcquireRow(index)
    local row = blacklistRows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, rowContainer)
    row:SetHeight(BLACKLIST_ROW_HEIGHT)
    row:SetPoint("LEFT", rowContainer, "LEFT", 0, 0)
    row:SetPoint("RIGHT", rowContainer, "RIGHT", 0, 0)
    row:SetPoint("TOP", rowContainer, "TOP", 0, -(index - 1) * BLACKLIST_ROW_HEIGHT)

    row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.label:SetJustifyH("LEFT")

    row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.remove:SetSize(80, 20)
    row.remove:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.remove:SetText(locale["blacklist:remove"])

    blacklistRows[index] = row
    return row
end

function blacklistFrame.Refresh()
    if not rowContainer then return end

    local entries = model.GetBlacklist()

    for _, row in ipairs(blacklistRows) do
        row:Hide()
    end

    for index, itemID in ipairs(entries) do
        local row = AcquireRow(index)
        row.label:SetText(BlacklistRowLabel(itemID))
        row.remove:SetScript("OnClick", function()
            model.SetBlacklisted(itemID, false)
            control.scanner.RequestScan()
            blacklistFrame.Refresh()
        end)
        row:Show()
    end

    mainFrame.emptyLabel:SetShown(#entries == 0)
    mainFrame.clearAll:SetShown(#entries > 0)

    -- The scroll child grows to the full content height (rather than being capped)
    -- since scrolling, not clipping, is how overflow is handled here.
    rowContainer:SetHeight(math.max(#entries * BLACKLIST_ROW_HEIGHT, BLACKLIST_ROW_HEIGHT))
end

local function CreateMainFrame()
    mainFrame = CreateFrame("Frame", ADDON_NAME .. "BlacklistFrame", UIParent)
    mainFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:Hide()

    local shell = BitForge.UI.Skin.BuildWindowShell(mainFrame, {
        includeHeader = true,
        headerHeight = HEADER_HEIGHT,
    })
    local colors = BitForge.UI.Colors
    BitForge.UI.Skin.ApplyColorTexture(shell.background, colors.bg)
    BitForge.UI.Skin.ApplyColorTexture(shell.header, colors.surface)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderTop, colors.edge)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderBottom, colors.edge)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderLeft, colors.edge)
    BitForge.UI.Skin.ApplyColorTexture(shell.borderRight, colors.edge)

    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    closeButton:SetScript("OnClick", function() mainFrame:Hide() end)

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", mainFrame, "TOP", 0, -8)
    title:SetText(locale["blacklist:windowTitle"])

    local scrollFrame = CreateFrame("ScrollFrame", nil, mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", SCROLL_LEFT_INSET, -(HEADER_HEIGHT + 10))
    scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -SCROLL_RIGHT_INSET, FOOTER_HEIGHT)
    BitForge.UI.Skin.StyleScrollBar(scrollFrame.ScrollBar)

    rowContainer = CreateFrame("Frame", nil, scrollFrame)
    rowContainer:SetWidth(CONTENT_WIDTH)
    rowContainer:SetHeight(BLACKLIST_ROW_HEIGHT)
    scrollFrame:SetScrollChild(rowContainer)

    mainFrame.emptyLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    mainFrame.emptyLabel:SetPoint("TOP", scrollFrame, "TOP", 0, -8)
    mainFrame.emptyLabel:SetText(locale["blacklist:empty"])

    mainFrame.clearAll = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    mainFrame.clearAll:SetSize(120, 22)
    mainFrame.clearAll:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -12, 10)
    mainFrame.clearAll:SetText(locale["blacklist:clearAll"])
    mainFrame.clearAll:SetScript("OnClick", function()
        model.ClearBlacklist()
        control.scanner.RequestScan()
        blacklistFrame.Refresh()
    end)
end

function blacklistFrame.Open()
    if not mainFrame then
        CreateMainFrame()
    end
    blacklistFrame.Refresh()
    mainFrame:Show()
end

view.blacklistFrame = blacklistFrame

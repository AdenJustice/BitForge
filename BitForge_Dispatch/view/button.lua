---@type string, BitForge.Dispatch
local ADDON_NAME, ns = ...
local C_Item = C_Item
local InCombatLockdown = InCombatLockdown
local TooltipDataProcessor = TooltipDataProcessor
-- The stub still names the second parameter `prefix`, from a signature the
-- client dropped; 12.0 reads it as `abbreviate`, and Blizzard's own
-- Blizzard_ActionBar/ActionButton.lua spells that flag 1 rather than true.
---@type fun(key: string, abbreviate: boolean|number|nil): string
local GetBindingText = GetBindingText

local model = ns.model
local enum = ns.enum
local locale = ns.locale
local control = ns.control

---@class BitForge.Dispatch.View
local view = ns.view

local BUTTON_NAME = ADDON_NAME .. "Button"
local HIDER_NAME = ADDON_NAME .. "Hider"

-- Not translated, and deliberately not a locale key: it is a symbol rather than
-- a sentence, and every locale writes it the same way.
local QUEST_MARK = "!"

-- Sampled from the glyph in Interface/ContainerFrame/UI-Icon-QuestBang, whose
-- body is a flat 255/209/0 -- the game's own gold, so the drawn mark matches the
-- one the bags show without borrowing the texture that carries it.
local QUEST_MARK_COLOR = CreateColor(1, 0.82, 0)

-- A fraction of the button rather than a fixed height, so the mark holds its
-- proportion across the 24-64 the size slider allows.
local QUEST_MARK_RATIO = 0.5

---@class BitForge.Dispatch.View.Button
local button = {}

local pendingCandidate
local pendingDirty = false
local currentCandidate

-- The secure visibility driver button.frame is parented to.
local hider

local function applyAttributes(candidate)
    local frame = button.frame
    frame:SetAttribute("type1", nil)
    frame:SetAttribute("item", nil)
    frame:SetAttribute("macrotext1", nil)

    if not candidate then return end

    if candidate.locked then
        -- Two actions are needed, so a macro rather than a plain item attribute.
        -- Casting the unlock on an already-open box is a no-op, so the same macro
        -- serves both the picking click and the opening click.
        local knowsPickLock = C_SpellBook.IsSpellKnown(
            enum.SPELL_PICK_LOCK, Enum.SpellBookSpellBank.Player)
        local spellID = knowsPickLock and enum.SPELL_PICK_LOCK
            or enum.SPELL_SKELETON_PINKIE
        local spellName = C_Spell.GetSpellName(spellID)
        -- string.format raises on a nil %s in WoW's Lua 5.1 rather than
        -- coercing. C_SpellBook.IsSpellKnown already gates this, but stay
        -- defensive: leave the attributes cleared (from above) rather than error.
        if not spellName then return end
        frame:SetAttribute("type1", "macro")
        frame:SetAttribute("macrotext1",
            ("/cast %s\n/use %d %d"):format(spellName, candidate.bag, candidate.slot))
    else
        frame:SetAttribute("type1", "item")
        frame:SetAttribute("item", "item:" .. candidate.itemID)
    end
end

local function addDebugLines(tooltip, candidate)
    local debugLines = view.debugLines
    if debugLines then debugLines.AddOpen(tooltip, candidate) end
end

-- What the open tooltip is describing. The post-call below fires for every item
-- tooltip in the game and is handed no context of its own, so it reads this
-- rather than trying to re-derive what the button is showing.
local shownCandidate

-- The lines the player reads on the button: what each click does, and the debug
-- basis behind the pick.
--
-- Added from a post-call rather than appended after SetBagItem. For an item the
-- client has not cached, SetBagItem starts an asynchronous load and rebuilds the
-- tooltip once the data lands, discarding everything the first build
-- accumulated -- so an appended line is lost exactly once per item, on the first
-- hover after a login. A post-call runs on every build, that rebuild included.
local function OnItemTooltip(tooltip)
    if tooltip ~= GameTooltip then return end
    -- Another frame's tooltip is not ours to write into.
    if not GameTooltip:IsOwned(button.frame) then return end

    local candidate = shownCandidate
    if not candidate then return end

    tooltip:AddLine(" ")
    tooltip:AddLine(locale["tooltip:use"])
    tooltip:AddLine(locale["tooltip:skip"])
    tooltip:AddLine(locale["tooltip:blacklist"])
    tooltip:AddLine(locale["tooltip:report"])
    if not model.GetLocked() then
        tooltip:AddLine(locale["tooltip:drag"])
    end
    addDebugLines(tooltip, candidate)
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)

local function showTooltip(candidate)
    shownCandidate = candidate
    -- SetOwner also clears the accumulated lines, which is what makes this safe
    -- to call on an already-open tooltip. SetBagItem builds the item's own
    -- tooltip and runs the post-call above, which appends the rest.
    GameTooltip:SetOwner(button.frame, "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(candidate.bag, candidate.slot)
    GameTooltip:Show()
end

-- OnEnter fires only when the cursor crosses the button's edge, and every click
-- swaps the candidate under a cursor that never moved: right-click skips or
-- blacklists, left-click uses the item and defers it. Without this the tooltip
-- kept describing the previous item until the player moved the mouse away and
-- back. IsOwned keeps it to our own tooltip -- some other frame's tooltip is
-- not ours to rebuild or hide.
local function refreshTooltip(candidate)
    if not GameTooltip:IsOwned(button.frame) then return end
    if not candidate then
        shownCandidate = nil
        GameTooltip:Hide()
        return
    end
    showTooltip(candidate)
end

local function updateFace(candidate)
    local frame = button.frame
    if not candidate then
        frame:Hide()
        refreshTooltip(nil)
        return
    end

    local icon = select(5, C_Item.GetItemInfoInstant(candidate.itemID))
    frame.icon:SetTexture(icon)

    if model.GetShowCount() and candidate.stackCount > 1 then
        frame.Count:SetText(candidate.stackCount)
        frame.Count:Show()
    else
        frame.Count:Hide()
    end

    -- Set on every candidate, not only the quest ones: the button is reused, so
    -- a mark left up from the last item would follow the next one.
    frame.QuestBang:SetShown(candidate.startsQuest == true)

    button.RefreshCooldown()
    frame:Show()
    refreshTooltip(candidate)
end

function button.SetItem(candidate)
    -- The event chain (bag updates, quest updates, etc.) is live from
    -- ADDON_LOADED, but button.Init() does not create the frame until
    -- PLAYER_LOGIN — and, per the combat guard below, may defer past that.
    -- No-op here; the Init()->RequestScan() sequence re-drives this once the
    -- frame exists.
    if not button.frame then return end

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

function button.ClearItem()
    button.SetItem(nil)
end

function button.FlushPending()
    if not pendingDirty then return end
    applyAttributes(pendingCandidate)
    updateFace(pendingCandidate)
    pendingCandidate = nil
    pendingDirty = false
end

-- The keybind text every other action button in the UI shows. Refreshed on
-- UPDATE_BINDINGS (control.lua), since the player can rebind at any time after
-- this first runs.
function button.RefreshHotKey()
    if not button.frame then return end
    local key = GetBindingKey("CLICK " .. BUTTON_NAME .. ":LeftButton")
    local text = key and GetBindingText(key, 1) or ""
    button.frame.HotKey:SetText(text)
    button.frame.HotKey:SetShown(text ~= "")
end

function button.RefreshCooldown()
    local frame = button.frame
    if not frame then return end
    if not currentCandidate or not model.GetShowCooldown() then
        frame.cooldown:Clear()
        return
    end
    -- GetItemCooldown's third return is enableCooldownTimer, a bool; SetCooldown's
    -- third parameter is modRate, a number. CooldownFrame_Set is the Blizzard
    -- helper that reads the flag and clears instead of swiping when the timer is
    -- disabled or the item is ready.
    local startTime, duration, enable = C_Item.GetItemCooldown(currentCandidate.itemID)
    CooldownFrame_Set(frame.cooldown, startTime, duration, enable)
end

function button.ApplyClickRegistration()
    if not button.frame then return end
    if InCombatLockdown() then return end
    local useKeyDown = GetCVarBool("ActionButtonUseKeyDown")
    -- Registering both up and down would fire the action twice.
    button.frame:RegisterForClicks(useKeyDown and "AnyDown" or "AnyUp")
end

function button.ApplySize()
    if not button.frame then return end
    -- Reachable from the settings slider while the Blizzard Settings UI is
    -- open in combat. Skipped here, then re-applied from onRegenEnabled once
    -- combat ends, so the change is never lost — see button.ApplyClickRegistration.
    if InCombatLockdown() then return end
    local size = model.GetButtonSize()
    button.frame:SetSize(size, size)
    -- The one region that does not follow the button on its own. Height and
    -- weight ride on the same SetFont: WoW has no bold face, THICKOUTLINE is
    -- reachable only as a SetFont flag, and re-setting both together is what
    -- keeps the mark bold across a resize. GetFont answers the FontFamily
    -- member already resolved for this client's alphabet, so the face survives.
    local face = button.frame.QuestBang:GetFont()
    button.frame.QuestBang:SetFont(face, math.floor(size * QUEST_MARK_RATIO), "THICKOUTLINE")
end

function button.ResetPosition()
    -- The DB write is not protected and always happens; only the button
    -- update needs the guard. button.RestorePosition() re-applies this exact
    -- model value from onRegenEnabled if combat swallows it here.
    model.SetPoint("CENTER", "CENTER", 0, -150)
    if InCombatLockdown() then return end
    button.frame:ClearAllPoints()
    button.frame:SetPoint("CENTER", hider, "CENTER", 0, -150)
end

function button.RestorePosition()
    if InCombatLockdown() then return end
    local point = model.GetPoint()
    button.frame:ClearAllPoints()
    button.frame:SetPoint(point.point, hider, point.relPoint, point.x, point.y)
end

function button.Init()
    if button.frame then return end
    -- PLAYER_READY (and thus this call) can land mid-combat after a
    -- mid-combat /reload. Every subsequent line touches a protected frame
    -- (RegisterStateDriver, RegisterForDrag, SetAttribute, SetMovable,
    -- SetSize, SetPoint, Hide), so bail before creating anything rather than
    -- half-building state. button.frame stays nil, so this guard is a no-op
    -- next time and control.lua's onRegenEnabled retries the full Init()
    -- once combat ends — no partial frame, script, or category to duplicate.
    if InCombatLockdown() then return end

    hider = CreateFrame("Frame", HIDER_NAME, UIParent, "SecureHandlerStateTemplate")
    hider:SetAllPoints(UIParent)
    -- Evaluated inside the secure environment: the button disappears on combat
    -- entry without taint, and without calling Hide() on a protected frame, which
    -- is itself blocked in combat.
    RegisterStateDriver(hider, "visibility", "[petbattle][vehicleui][combat] hide; show")

    -- Deliberately NOT ActionButtonTemplate. In 12.0 that template is a CheckButton
    -- inheriting FlyoutButtonTemplate, PingableActionButtonTemplate, and
    -- BaseActionButtonMixin — action-bar machinery that expects a real action slot.
    -- Creating our own four regions is ~15 lines and inherits no behaviour we then
    -- have to suppress. Verified against wow-ui-source
    -- Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml.
    local frame = CreateFrame("Button", BUTTON_NAME, hider, "SecureActionButtonTemplate")
    button.frame = frame

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints(frame)
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    frame.Count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.Count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)

    frame.HotKey = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmallGray")
    frame.HotKey:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)

    -- Marks an item that offers a quest, on Blizzard's own rule of questID and
    -- not isActive (ContainerFrame.lua), which is exactly what earns
    -- PRIORITY.QUEST here.
    --
    -- Drawn rather than textured. UI-Icon-QuestBang is a framed tile, not a
    -- glyph: a 64x64 rounded border with a transparent middle and the mark in
    -- its upper left. Blizzard gets away with that over a bag slot, where the
    -- border is the point, but over this button it reads as a frame with a
    -- small mark in the corner, and cropping to the glyph leaves it stretched
    -- to a square it was never drawn for.
    --
    -- Outlined, because it sits over an item icon that can be any colour.
    -- Sublevel 2 mirrors the bag slot's own ordering, holding the mark above
    -- Count and HotKey by declaration rather than by creation order.
    frame.QuestBang = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
    frame.QuestBang:SetDrawLayer("OVERLAY", 2)
    -- Top left because Count and HotKey both sit on the right edge, so the
    -- mark clears them at every size the slider allows.
    frame.QuestBang:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    frame.QuestBang:SetText(QUEST_MARK)
    frame.QuestBang:SetTextColor(QUEST_MARK_COLOR:GetRGB())
    frame.QuestBang:Hide()

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame)

    frame:SetFrameStrata("MEDIUM")
    frame:RegisterForDrag("LeftButton")
    -- type2 stays nil so right-click performs no secure action and falls through
    -- to the PostClick handler installed below.
    frame:SetAttribute("type2", nil)

    frame:SetScript("OnDragStart", function(self)
        if model.GetLocked() then return end
        -- Alt is required because the button's whole job is to be left-clicked.
        -- A plain left-drag is too easy to produce while clicking, and moving
        -- the button out from under the cursor mid-click is worse than doing
        -- nothing. Bailing here leaves the drag inert rather than moving it.
        if not IsAltKeyDown() then return end
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        -- A drag can span the combat boundary (start out of combat, get
        -- pulled into combat mid-drag, release). StopMovingOrSizing is
        -- protected, so bail rather than throw.
        if InCombatLockdown() then return end
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        model.SetPoint(point, relPoint, x, y)
    end)

    frame:SetScript("PostClick", function(self, mouseButton)
        if not currentCandidate then return end

        -- Two modifiers, because plain right click is Skip and this sits on the
        -- same button.
        if mouseButton == "RightButton" and IsShiftKeyDown() and IsAltKeyDown() then
            BitForge:ShowReport(
                control.OpenReportText(currentCandidate.bag, currentCandidate.slot,
                    currentCandidate.itemID),
                locale["report:blurbOpen"])
            return
        end

        if mouseButton == "LeftButton" then
            -- A modified left click uses nothing, so there is nothing to defer.
            -- type1 answers an unmodified click only: SecureButton_GetModifiedAttribute
            -- resolves "type" through SecureButton_GetModifierPrefix, so a held
            -- modifier looks up alt-type1 (or ctrl-, or shift-), none of which
            -- is set, then the wildcards, then a bare "type" this button never
            -- sets -- and no secure action runs. Blizzard writes "*type1" in
            -- SecureUnitButton_OnLoad for exactly that reason. Alt is the move
            -- gesture's own modifier, so without this the drag deferred an item
            -- it had not opened and the button moved on (#377).
            if IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then return end
            -- Recorded whether the use worked or not: the secure click's
            -- outcome is invisible from here, a failed use changes no bags so
            -- nothing fires a rescan, and a rescan on its own would not help
            -- either -- model.openRules.Rank is deterministic over bags that
            -- have not moved. The deferral is the state change that makes the
            -- next click reach a different item while leaving this one in the
            -- queue; the in-flight mark is what holds the button through a
            -- cast-time use, since the scan a slot lock triggers mid-cast
            -- checks it before repainting.
            model.openRules.Defer(currentCandidate.itemID)
            model.openRules.MarkInFlight(currentCandidate.itemID)
        elseif mouseButton == "RightButton" then
            if IsControlKeyDown() then
                -- false, not true. The blacklist this replaced stored true for
                -- "never offer"; the merged field spells the same opinion
                -- open = false, and true is its opposite. Writing true here
                -- would hide nothing and openRules.Claim would fall through it
                -- as though the player had said nothing at all.
                model.overrides.SetOpen(currentCandidate.itemID, false)
            else
                model.openRules.Skip(currentCandidate.itemID)
            end
        else
            -- Only type1 is ever set, so no other button acted on the item and
            -- nothing about the queue has changed.
            return
        end

        control.openScanner.RequestScan()
    end)

    frame:SetScript("OnEnter", function()
        if not currentCandidate then return end
        showTooltip(currentCandidate)
    end)

    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    frame:SetMovable(true)

    -- Colours are not optional here. GetSolidBackdrop's bgFile and edgeFile are
    -- both WHITE8X8, and CreateBackdropUnderlay skips SetBackdropColor entirely
    -- when no colour is passed, so an unstyled underlay is an opaque white
    -- square the size of the button. frame.icon covers it, which hides it right
    -- up until a candidate change leaves the icon undrawn for the frames its new
    -- texture takes to stream in -- the white flash between two items.
    local colors = BitForge.UI.Colors
    BitForge.UI.Skin.CreateBackdropUnderlay(frame, {
        backgroundColor = colors.bg,
        borderColor = colors.edge,
    })

    button.ApplySize()
    button.ApplyClickRegistration()
    button.RestorePosition()
    frame:Hide()

    _G["BINDING_HEADER_BITFORGE_DISPATCH"] = locale["binding:header"]
    _G["BINDING_NAME_CLICK " .. BUTTON_NAME .. ":LeftButton"] = locale["binding:use"]
    button.RefreshHotKey()
end

view.button = button

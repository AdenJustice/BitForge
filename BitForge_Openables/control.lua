---@type string, BitForge.Openables
local ADDON_NAME, ns = ...
local E = BitForge.Events

local ipairs = ipairs
local pairs = pairs
local wipe = table.wipe

local C_Container = C_Container
local C_Item = C_Item
local C_QuestLog = C_QuestLog
local C_TooltipInfo = C_TooltipInfo
local IsPlayerSpell = IsPlayerSpell

-- GlobalStrings, so localized: the "<Right Click to Open>" line on a container's
-- tooltip. Comparisons are guarded on it being non-nil, or `line.leftText == nil`
-- would match every line without left text.
local ITEM_OPENABLE = ITEM_OPENABLE

local enum = ns.enum
local model = ns.model
local view = ns.view

---@class BitForge.Openables.Control
local control = ns.control

function ns:Subscribe(event, callback)
    BitForge.Subscribe(event, callback, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

-- ================================================================================
-- Detector
-- ================================================================================

local detector = {}

local LINE_TYPE = Enum.TooltipDataLineType
local REASON = enum.REASON
local REJECTED = enum.REJECTED

-- Typed lines that mean "this item does nothing", full stop. Typed rather than
-- colour-matched, which secret values made unreliable.
local REJECT_LINES = {
    [LINE_TYPE.DisabledLine] = true,
    [LINE_TYPE.ErrorLine]    = true,
}

-- UsageRequirement is present whenever an item *has* a requirement, met or not --
-- every recipe carries its profession line. It rejects only when IsUsableItem
-- agrees the requirement is unmet.
local CONDITIONAL_REJECT_LINES = {
    [LINE_TYPE.UsageRequirement] = true,
}

-- Typed lines that mean "this item does something when used".
local ACCEPT_LINES = {
    [LINE_TYPE.ItemSpellTriggerOnUse] = true,
    [LINE_TYPE.ItemSpellTriggerLearn] = true,
    [LINE_TYPE.ToyEffect]             = true,
    [LINE_TYPE.LearnTransmogSet]      = true,
    [LINE_TYPE.LearnTransmogIllusion] = true,
    [LINE_TYPE.LearnableSpell]        = true,
}

function detector.CanUnlock()
    return IsPlayerSpell(enum.SPELL_PICK_LOCK) or IsPlayerSpell(enum.SPELL_SKELETON_PINKIE)
end

-- Enum.TooltipDataLineType has no Locked member, and C_Item.IsLocked reports the
-- transient "being moved" state instead, so the localized global is the only
-- signal. `data` lets a caller reuse a tooltip it already fetched.
function detector.IsLockedBox(bag, slot, data)
    data = data or C_TooltipInfo.GetBagItem(bag, slot)
    if not data or not data.lines then return false end
    for _, line in ipairs(data.lines) do
        if line.leftText == LOCKED then
            return true
        end
    end
    return false
end

local function isContainer(itemID)
    local classID = select(6, C_Item.GetItemInfoInstant(itemID))
    return classID == Enum.ItemClass.Container
end

local function isRecipe(itemID)
    local classID = select(6, C_Item.GetItemInfoInstant(itemID))
    return classID == Enum.ItemClass.Recipe
end

-- Whole classes an accept branch cannot tell from a genuine openable:
--   Key -- answers both GetItemSpell and IsUsableItem.
--   ItemEnhancement -- enchanting scrolls carry ItemSpellTriggerOnUse as a recipe
--     does, but using one opens a targeting cursor, not an item.
local DENIED_CLASSES = {
    [Enum.ItemClass.Key]             = true,
    [Enum.ItemClass.ItemEnhancement] = true,
}

-- Classes where only part of the class is junk, mapped to the reason to report.
-- Only Consumable's buff subclasses are denied: Consumable/Other holds conduits,
-- reputation tokens and use-to-unlock items.
local DENIED_SUBCLASSES = {
    [Enum.ItemClass.Consumable] = {
        [Enum.ItemConsumableSubclass.Potion]       = REJECTED.DENIED_CLASS,
        [Enum.ItemConsumableSubclass.Elixir]       = REJECTED.DENIED_CLASS,
        [Enum.ItemConsumableSubclass.Flasksphials] = REJECTED.DENIED_CLASS,
        [Enum.ItemConsumableSubclass.Fooddrink]    = REJECTED.DENIED_CLASS,
        [Enum.ItemConsumableSubclass.Bandage]      = REJECTED.DENIED_CLASS,
    },
    -- Holiday items (firecrackers, snowballs, ...) carry a Use: line like any
    -- openable, but using one fires a seasonal effect rather than opening
    -- anything.
    [Enum.ItemClass.Miscellaneous] = {
        [Enum.ItemMiscellaneousSubclass.Holiday] = REJECTED.HOLIDAY,
    },
}

-- Profession names as this client prints them, gathered from the character's own
-- trade skill lines. Rebuilt rather than derived per item: a scan touches every
-- bag slot, and the answer changes only when a profession is learned or dropped.
local professionNames = {}

--- Re-reads the character's professions. Called at startup and whenever the
--- skill lines change, so learning a profession makes its knowledge items
--- appear without a reload.
---
--- Both names are recorded, because the API may hand back base lines or the
--- expansion's child lines and the requirement names whichever the item was
--- gated on. The match below is a substring, so the base name ("Skinning") also
--- catches the child ("Midnight Skinning") -- which is what makes this
--- independent of which the client returns.
function detector.RefreshProfessions()
    wipe(professionNames)
    local skillLines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
    if not skillLines then return end
    for _, skillLineID in ipairs(skillLines) do
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
        if info then
            if info.professionName then professionNames[info.professionName] = true end
            if info.parentProfessionName then
                professionNames[info.parentProfessionName] = true
            end
        end
    end
end

-- True when a usage requirement line names a profession this character has.
--
-- Profession knowledge items -- "Study to increase your <Profession> Knowledge
-- by N" -- are Miscellaneous/Other carrying a plain Use: line, which is exactly
-- the shape the junk gate below turns away. What tells them apart from that junk
-- is the requirement: a firecracker is gated on nothing, a knowledge item is
-- gated on a trade skill.
--
-- Matched by name because the client exposes no required-skill API to an addon:
-- Enum.TooltipDataLineType has no member for it, C_TradeSkillUI has no
-- knowledge function, and GetItemInfo does not return the item's reqskill.
-- Both sides of the comparison come from the client in the same locale, so this
-- compares two of the client's own strings rather than scraping a translation.
--
-- An empty set matches nothing, so a character with no professions is not
-- handed every Miscellaneous/Other item in their bags.
local function requiresKnownProfession(data)
    if not (data and data.lines) then return false end
    for _, line in ipairs(data.lines) do
        if line.type == LINE_TYPE.UsageRequirement and type(line.leftText) == "string" then
            for name in pairs(professionNames) do
                if line.leftText:find(name, 1, true) then return true end
            end
        end
    end
    return false
end

-- True when the weakest evidence accepted the item: a plain Use: line, or the
-- API fallback that matched no typed line. Class rules consult this so they do
-- not also swallow the learn-style acceptances sharing the class.
local function acceptedOnPlainUse(acceptedLine)
    return acceptedLine == nil or acceptedLine == LINE_TYPE.ItemSpellTriggerOnUse
end

-- Which of the two non-container verdicts an accepted item earns.
--
-- LEARN is for what the player can learn from and then no longer needs, and it
-- outranks everything -- see enum.PRIORITY. The rest of ACCEPT_LINES names a
-- teaching effect outright (ItemSpellTriggerLearn, ToyEffect, LearnTransmogSet,
-- LearnTransmogIllusion, LearnableSpell), so the accepting line answers first:
-- the same predicate the class rules use for "weakest evidence" answers "not
-- learnable" here. Everything else is USE -- the item does something, and that
-- is all the pipeline established.
--
-- The line cannot have the last word, though. Two things carry knowledge on
-- nothing but a plain Use: line, and both would sink to the bottom tier if it
-- did:
--
--   Recipes. Enum.ItemClass.Recipe holds nothing but learnables, yet its items
--   carry a plain Use: line -- the very line that makes enchanting scrolls
--   indistinguishable from them, which is why DENIED_CLASSES has to turn
--   ItemEnhancement away by class rather than by line.
--
--   Profession knowledge items. Miscellaneous/Other with a plain Use: line is
--   exactly the shape isRejectedByClass discards, and the trade skill gating it
--   is the only thing that tells one from a firecracker. That same requirement
--   is what makes it knowledge rather than an effect, so it answers here too --
--   otherwise the rule that rescues these items from being hidden would hand
--   them straight to the tier nothing ever outranks.
local function learnVerdict(itemID, acceptedLine, data)
    if not acceptedOnPlainUse(acceptedLine) then return enum.PRIORITY.LEARN end
    if isRecipe(itemID) then return enum.PRIORITY.LEARN end
    if requiresKnownProfession(data) then return enum.PRIORITY.LEARN end
    return enum.PRIORITY.USE
end

-- The class policy an item must clear once an accept branch has matched it.
-- Both branches consult this, so an item denied here cannot reappear through
-- the other one.
local function isRejectedByClass(bag, slot, itemID, acceptedLine, data)
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))
    if DENIED_CLASSES[classID] then return true, REJECTED.DENIED_CLASS end

    local deniedSubclasses = DENIED_SUBCLASSES[classID]
    local subclassReason = deniedSubclasses and deniedSubclasses[subClassID]
    if subclassReason then return true, subclassReason end

    -- Classify resolves quest starters before this runs, so a quest item reaching
    -- here starts nothing: it is a quest objective or a leftover.
    if classID == Enum.ItemClass.Questitem then
        -- Classified by ID, so the quest check could not run. Unevaluated is not
        -- the same as rejected.
        if not bag then return false end
        return true, REJECTED.QUESTLESS_ITEM
    end

    -- On-use armor -- trinkets, cloaks -- carries the same Use: line an openable
    -- does. Gated rather than denied outright so an armor piece that teaches an
    -- appearance still reaches the button.
    if classID == Enum.ItemClass.Armor and acceptedOnPlainUse(acceptedLine) then
        return true, REJECTED.ON_USE_ARMOR
    end

    -- Miscellaneous/Other holds junk with a plain Use: line alongside genuine
    -- toys, which arrive on ToyEffect -- the accepting line is what separates
    -- them. Never widen this to the whole subclass: Enum.ItemClass.Container
    -- means equippable bags, so the loot caches live here too.
    if classID == Enum.ItemClass.Miscellaneous
        and subClassID == Enum.ItemMiscellaneousSubclass.Other
        and acceptedOnPlainUse(acceptedLine) then
        -- Unless a trade skill gates it. Profession knowledge items land in
        -- this class pair with nothing but a plain Use: line to show for
        -- themselves, and the requirement is the only thing that separates them
        -- from what this branch exists to discard.
        if requiresKnownProfession(data) then return false end
        return true, REJECTED.ON_USE_MISC
    end

    return false
end

-- Accepted: priority, isLocked, reason (enum.REASON), detail.
-- Rejected: nil, reason (enum.REJECTED), detail.
-- Everything past the first return is diagnostics; callers test the priority and
-- stop. `data` supplies a tooltip for an item in no bag; production omits it.
--
-- The order is cheapest and most authoritative first:
--
--   1. What the player said -- blacklist, session skip. Nothing outranks it.
--   2. Hand-curated denials, stack gates, quest gates. Still table lookups.
--   3. Whether the item starts a quest -- it can accept, so it precedes anything
--      that might reject first.
--   4. The tooltip, fetched once and shared with IsLockedBox.
--   5. What the client states outright: locked, unusable, already known. Facts
--      beat every heuristic below.
--   6. ALLOW_LIST -- after those facts, before the heuristics it overrides.
--   7. Evidence, strongest first: hasLoot, the openable line, a typed accept
--      line, the GetItemSpell fallback. Structural signals precede text ones,
--      which are localized and depend on where the item is. Class rules filter
--      only the last two, where the evidence is weak enough to need them.
function detector.Classify(bag, slot, itemID, data)
    if model.IsBlacklisted(itemID) then return nil, REJECTED.BLACKLIST end
    if model.IsSkipped(itemID) then return nil, REJECTED.SESSION_SKIP end
    if enum.DENY_LIST[itemID] then return nil, REJECTED.DENY_LIST end

    -- Counted across the bags, not off this slot: unsorted bags split an item
    -- into partial stacks, and 3 + 3 converts as well as one stack of six.
    -- GetItemCount excludes the bank, matching what the button can act on.
    local requiredStack = enum.STACK_GATED[itemID]
    if requiredStack and C_Item.GetItemCount(itemID) < requiredStack then
        return nil, REJECTED.SHORT_STACK
    end

    -- One gate, two sources: GetContainerItemQuestInfo names the quest an item
    -- starts whatever its class, QUEST_GATED covers items a quest consumes
    -- instead, which no API reports. The client's answer wins, being current.
    -- Either way the item is worth the button only while the quest can be taken.
    --
    -- questInfo.isActive answers the same question as IsOnQuest for a starter,
    -- and IsOnQuest also serves a curated entry, which has no questInfo.
    --
    -- Ahead of the class policy so a quest starter is not buried by a rule aimed
    -- at the junk sharing its class.
    local containerInfo = bag and C_Container.GetContainerItemInfo(bag, slot)
    local questInfo = bag and C_Container.GetContainerItemQuestInfo(bag, slot)
    local questID = (questInfo and questInfo.questID) or enum.QUEST_GATED[itemID]
    if questID then
        if C_QuestLog.IsOnQuest(questID) or C_QuestLog.IsQuestFlaggedCompleted(questID) then
            return nil, REJECTED.QUEST_TAKEN
        end
        return enum.PRIORITY.QUEST, false, REASON.QUEST_GATE, questID
    end

    -- Fetched once and shared with IsLockedBox.
    data = data or C_TooltipInfo.GetBagItem(bag, slot)

    local locked = detector.IsLockedBox(bag, slot, data)
    if locked then
        if not detector.CanUnlock() then return nil, REJECTED.NO_UNLOCK end
        return enum.PRIORITY.OPEN, true, REASON.LOCKED_BOX
    end

    -- One pass, acted on below. The first accepting line is recorded rather than
    -- a bare flag, but the walk continues: a reject line anywhere overrules it.
    local acceptedLine, opensOnRightClick
    if data and data.lines then
        for _, line in ipairs(data.lines) do
            if REJECT_LINES[line.type] then return nil, REJECTED.REJECT_LINE, line.type end
            if CONDITIONAL_REJECT_LINES[line.type] and not C_Item.IsUsableItem(itemID) then
                return nil, REJECTED.UNUSABLE, line.type
            end
            if ITEM_OPENABLE and line.leftText == ITEM_OPENABLE then
                opensOnRightClick = true
            end
            if not acceptedLine and ACCEPT_LINES[line.type] then acceptedLine = line.type end
        end
    end

    -- After the tooltip, not before: the list answers "the pipeline cannot detect
    -- this", not "ignore what the client just said". An entry therefore cannot
    -- pin an already-known or unusable item to the button. Still ahead of the
    -- class rules, which are the heuristics it exists to override.
    local allowed = enum.ALLOW_LIST[itemID]
    if allowed then return allowed, false, REASON.ALLOW_LIST end

    -- The same fact twice, structural first. hasLoot is the client's own "we can
    -- loot this" flag (ContainerFrame.lua:1494) -- typed, locale-free, and it
    -- needs no tooltip. ITEM_OPENABLE says it in text and is the weaker fallback:
    -- a localized match, present only on a bag item's tooltip.
    --
    -- Either one means openable, which outranks the class rules -- those exist
    -- because a class pair cannot tell a cache from junk, and these can.
    if containerInfo and containerInfo.hasLoot then
        return enum.PRIORITY.OPEN, false, REASON.HAS_LOOT
    end

    if opensOnRightClick then
        return enum.PRIORITY.OPEN, false, REASON.OPENABLE_LINE
    end

    if acceptedLine then
        if isContainer(itemID) then
            return enum.PRIORITY.OPEN, false, REASON.TOOLTIP_LINE, acceptedLine
        end
        local rejected, why = isRejectedByClass(bag, slot, itemID, acceptedLine, data)
        if rejected then return nil, why end
        return learnVerdict(itemID, acceptedLine, data), false,
            REASON.TOOLTIP_LINE, acceptedLine
    end

    -- No typed line matched at all, so by acceptedOnPlainUse's own definition
    -- this is the merely-usable case -- unless the class or the requirement
    -- says otherwise.
    if C_Item.GetItemSpell(itemID) and C_Item.IsUsableItem(itemID) then
        if isContainer(itemID) then return enum.PRIORITY.OPEN, false, REASON.ITEM_SPELL end
        local rejected, why = isRejectedByClass(bag, slot, itemID)
        if rejected then return nil, why end
        return learnVerdict(itemID, nil, data), false, REASON.ITEM_SPELL
    end

    return nil, REJECTED.NO_EVIDENCE
end

control.detector = detector

-- ================================================================================
-- Scanner
-- ================================================================================

local C_Timer = C_Timer

local scanner = {}

local current
local ranked
local scanQueued = false
local pendingItems = {}

function scanner.GetCurrent()
    return current
end

--- The whole ranked field the last scan produced, winner first, or nil when it
--- found nothing.
---
--- The button shows candidates[1] and discards the rest, which is exactly what
--- makes a surprising pick hard to explain: the interesting part is what it
--- beat. Held rather than recomputed so the dump reports the decision that was
--- actually taken, not one taken again against bags that have since changed.
--- It costs nothing to keep -- the table would otherwise be collected, and
--- `current` already pins one of its entries.
---@return table|nil
function scanner.GetRanked()
    return ranked
end

-- Reviewed once per session per item: a verdict cannot change while the item
-- sits there, and bag updates fire scans constantly.
local allowListReviewed = {}
local questGatedReviewed = {}

-- Records what the pipeline would decide about an allow-listed item with its
-- entry suppressed -- an entry that the pipeline can now detect unaided is dead
-- weight. Only answerable with the item in hand, since hasLoot and the openable
-- line exist only for an item the player holds, so it runs opportunistically and
-- leaves the verdict in the SavedVariable to be reported back.
--
-- Two table lookups for anything unlisted, which is nearly everything.
local function reviewAllowListEntry(bag, slot, itemID)
    local listed = enum.ALLOW_LIST[itemID]
    if listed == nil or allowListReviewed[itemID] then return end
    allowListReviewed[itemID] = true

    -- Suppressed so the entry cannot vouch for itself; pcall so an error cannot
    -- leave the table permanently short an entry.
    enum.ALLOW_LIST[itemID] = nil
    local ok, priority, second, third = pcall(detector.Classify, bag, slot, itemID)
    enum.ALLOW_LIST[itemID] = listed

    local verdict
    if not ok then
        verdict = "errored: " .. tostring(priority)
    elseif priority then
        verdict = ("REDUNDANT priority=%s reason=%s"):format(
            tostring(priority), tostring(third))
    else
        verdict = ("needed: %s"):format(tostring(second))
    end

    model.RecordCurationReview("ALLOW_LIST", itemID, verdict)

    if model.IsDebug() and priority then
        BitForge:Print(("Openables: ALLOW_LIST entry %d looks redundant (%s)")
            :format(itemID, verdict))
    end
end

-- QUEST_GATED hard-codes each listed item's quest, on the premise that no API
-- maps one to the other. Where GetContainerItemQuestInfo answers, the entry is
-- dead weight -- Classify already prefers the client. A disagreement matters
-- more than either: the table would name the wrong quest.
local function reviewQuestGatedEntry(bag, slot, itemID)
    local curated = enum.QUEST_GATED[itemID]
    if curated == nil or questGatedReviewed[itemID] then return end
    questGatedReviewed[itemID] = true

    local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
    local reported = questInfo and questInfo.questID

    local verdict
    if not reported then
        verdict = ("needed: client reports no quest, table says %d"):format(curated)
    elseif reported == curated then
        verdict = ("REDUNDANT client reports quest %d, matching the table"):format(reported)
    else
        verdict = ("MISMATCH client reports quest %d, table says %d"):format(reported, curated)
    end

    model.RecordCurationReview("QUEST_GATED", itemID, verdict)

    if model.IsDebug() and reported then
        BitForge:Print(("Openables: QUEST_GATED entry %d -- %s"):format(itemID, verdict))
    end
end

local function collectCandidates()
    local candidates = {}
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                if not C_Item.IsItemDataCachedByID(info.itemID) then
                    -- Ask the server and rescan when it answers.
                    pendingItems[info.itemID] = true
                    C_Item.RequestLoadItemDataByID(info.itemID)
                else
                    reviewAllowListEntry(bag, slot, info.itemID)
                    reviewQuestGatedEntry(bag, slot, info.itemID)

                    local priority, locked, reason, detail =
                        detector.Classify(bag, slot, info.itemID)
                    if priority then
                        local startTime, duration = C_Item.GetItemCooldown(info.itemID)
                        candidates[#candidates + 1] = {
                            itemID       = info.itemID,
                            bag          = bag,
                            slot         = slot,
                            priority     = priority,
                            stackCount   = info.stackCount or 1,
                            onCooldown   = (startTime or 0) > 0 and (duration or 0) > 0,
                            locked       = locked or false,
                            -- Diagnostics for the debug tooltip; see enum.REASON.
                            reason       = reason,
                            reasonDetail = detail,
                        }
                    end
                end
            end
        end
    end
    return candidates
end

function scanner.Scan()
    scanQueued = false

    if not model.IsEnabled() then
        current, ranked = nil, nil
        view.ClearItem()
        return
    end

    local candidates = collectCandidates()
    if #candidates == 0 then
        current, ranked = nil, nil
        view.ClearItem()
        return
    end

    model.Rank(candidates)
    -- Cleared on both early returns above, so the field never outlives the scan
    -- that produced it and read back as a decision still standing.
    ranked = candidates
    current = candidates[1]
    view.SetItem(current)
end

-- Debounced to one scan per frame. A loot burst that empties a container fires
-- many bag events; without this the scan would run for each of them.
function scanner.RequestScan()
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(enum.RESCAN_DELAY, scanner.Scan)
end

control.scanner = scanner

-- ================================================================================
-- Events
-- ================================================================================

local function onBagUpdate()
    scanner.RequestScan()
end

-- ITEM_DATA_LOAD_RESULT payload is (itemID, success).
local function onItemDataLoaded(itemID, success)
    if not pendingItems[itemID] then return end
    pendingItems[itemID] = nil
    if success then
        scanner.RequestScan()
    end

    if view.blacklistFrame and view.blacklistFrame.Refresh then
        view.blacklistFrame.Refresh()
    end
end

local function onCooldownUpdate()
    view.RefreshCooldown()
end

local function onRegenEnabled()
    -- Retries everything view.lua defers under InCombatLockdown: a mid-combat
    -- /reload leaves Init() unrun, and a settings change leaves ApplySize and
    -- RestorePosition un-applied. Init() is idempotent and the rest re-apply
    -- current model state, so calling them on every regen is harmless.
    view.Init()
    view.FlushPending()
    view.ApplyClickRegistration()
    view.ApplySize()
    view.RestorePosition()
    scanner.RequestScan()
end

local function onQuestChanged()
    scanner.RequestScan()
end

local function onLevelUp()
    scanner.RequestScan()
end

-- Learning or dropping a profession changes which knowledge items are worth
-- surfacing, and the names the requirement lines are matched against are
-- cached, so both have to be refreshed before the rescan reads them.
local function onSkillLinesChanged()
    detector.RefreshProfessions()
    scanner.RequestScan()
end

-- CVAR_UPDATE payload is (cvarName, value).
local function onCVarUpdate(name)
    if name == "ActionButtonUseKeyDown" then
        view.ApplyClickRegistration()
    end
end

local function onUpdateBindings()
    view.RefreshHotKey()
end

local function startModule()
    detector.RefreshProfessions()
    view.Init()
    scanner.RequestScan()
end

local function Init()
    -- Allocated under the full addon name, unlike every other module.
    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        steps   = {
            -- Data written before this module was versioned already matches the
            -- version-1 shape, so adopting the version is the whole migration.
            [1] = function() end,
        },
    }, startModule)
end

ns:Subscribe(E.BAG_UPDATE_DELAYED, onBagUpdate)
ns:Subscribe(E.ITEM_DATA_LOAD_RESULT, onItemDataLoaded)
ns:Subscribe(E.ACTIONBAR_UPDATE_COOLDOWN, onCooldownUpdate)
ns:Subscribe(E.PLAYER_REGEN_ENABLED, onRegenEnabled)
ns:Subscribe(E.QUEST_ACCEPTED, onQuestChanged)
ns:Subscribe(E.QUEST_TURNED_IN, onQuestChanged)
ns:Subscribe(E.QUEST_REMOVED, onQuestChanged)
ns:Subscribe(E.PLAYER_LEVEL_UP, onLevelUp)
ns:Subscribe(E.SKILL_LINES_CHANGED, onSkillLinesChanged)
ns:Subscribe(E.CVAR_UPDATE, onCVarUpdate)
ns:Subscribe(E.UPDATE_BINDINGS, onUpdateBindings)
ns:Subscribe(E.PLAYER_READY, Init)

-- ================================================================================
-- Debug dump
-- ================================================================================
--
-- /bfodump [itemID] captures everything detector.Classify reads about an item
-- into the SavedVariable, so a surprising decision can be inspected offline.
-- With no argument it dumps whatever is on the button.
--
-- /bfodump all captures the other half of the question. A single item's record
-- says why that item was accepted but not why it was the one shown: the button
-- takes candidates[1] and the rest are discarded unseen, so a surprising pick
-- reads as a verdict with nothing to compare it against. The field dump files
-- the whole ranked list, winner first, which turns the pick back into a margin.
--
-- Guarded at file scope, so a profile that has not set the module's debug flag
-- defines none of this. model.lua runs before this file and core is loaded
-- before either, so the flag is already readable here. Toggling it mid-session
-- therefore reaches the checks inside the pipeline but not this command; that
-- needs a reload.
--
-- It writes into the module's own debug container, beside the flag that gates
-- it -- the same place BatchSell's dump goes. Core empties every module's dump
-- on a fresh login, so what is on disk is one diagnostics session rather than
-- an accumulation since the flag went on.
if model.IsDebug() then

    -- Every field is flattened with tostring: tooltip data can carry secret
    -- values in 12.0, and a SavedVariable has to survive serialization.
    -- What the pipeline would decide if this item were not allow-listed. A
    -- listed item otherwise hides whether its entry still earns its place, since
    -- ALLOW_LIST answers first. The entry is restored immediately, through a
    -- pcall so a Classify error cannot drop it.
    -- The names a usage requirement is matched against. Recorded so a report
    -- about an item that was or was not surfaced explains itself without
    -- another round trip in-game.
    local function KnownProfessions()
        local names = {}
        for _, skillLineID in ipairs(C_TradeSkillUI.GetAllProfessionTradeSkillLines() or {}) do
            local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
            if info then
                names[#names + 1] = ("%s [%s]"):format(
                    tostring(info.professionName), tostring(info.parentProfessionName))
            end
        end
        return #names > 0 and table.concat(names, ", ") or "none"
    end

    local function ClassifyIgnoringAllowList(bag, slot, itemID)
        local listed = enum.ALLOW_LIST[itemID]
        if listed == nil then return "n/a, not allow-listed" end

        enum.ALLOW_LIST[itemID] = nil
        -- Positional names: accepted returns priority, locked, reason, detail;
        -- rejected returns nil, reason, detail.
        local ok, priority, second, third = pcall(detector.Classify, bag, slot, itemID)
        enum.ALLOW_LIST[itemID] = listed

        if not ok then return "errored: " .. tostring(priority) end
        if priority then
            return ("REDUNDANT -- pipeline finds it anyway: priority=%s reason=%s")
                :format(tostring(priority), tostring(third))
        end
        return ("earns its place: pipeline rejects with %s (detail=%s)")
            :format(tostring(second), tostring(third))
    end

    local function BuildDump(bag, slot, itemID)
        local _, itemType, itemSubType, _, _, classID, subClassID =
            C_Item.GetItemInfoInstant(itemID)
        local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
        -- Positional again: accepted is priority, locked, reason, detail;
        -- rejected is nil, reason, detail. Reading one shape as the other put
        -- the rejection reason under "locked".
        local priority, second, third, fourth = detector.Classify(bag, slot, itemID)
        local verdict
        if priority then
            verdict = ("accepted priority=%s locked=%s reason=%s detail=%s"):format(
                tostring(priority), tostring(second), tostring(third), tostring(fourth))
        else
            verdict = ("rejected reason=%s detail=%s"):format(
                tostring(second), tostring(third))
        end

        local dump = {
            itemID      = itemID,
            name        = tostring(C_Item.GetItemNameByID(itemID)),
            where       = ("bag %d slot %d"):format(bag, slot),
            class       = ("%s / %s (%s/%s)"):format(tostring(itemType),
                tostring(itemSubType), tostring(classID), tostring(subClassID)),
            isQuestItem = tostring(questInfo and questInfo.isQuestItem),
            questID     = tostring(questInfo and questInfo.questID),
            isActive    = tostring(questInfo and questInfo.isActive),
            hasSpell    = tostring(C_Item.GetItemSpell(itemID) ~= nil),
            isUsable    = tostring(C_Item.IsUsableItem(itemID)),
            professions = KnownProfessions(),
            verdict     = verdict,
            allowList   = ClassifyIgnoringAllowList(bag, slot, itemID),
            lines       = {},
        }

        local data = C_TooltipInfo.GetBagItem(bag, slot)
        if data and data.lines then
            for index, line in ipairs(data.lines) do
                dump.lines[index] = ("type=%s | left=%s | right=%s"):format(
                    tostring(line.type), tostring(line.leftText), tostring(line.rightText))
            end
        end

        return dump
    end

    -- Where /bfodump all files the field. Item records are filed under a numeric
    -- string, so a word cannot collide with one.
    local FIELD_KEY = "rankedField"

    local priorityNames

    local function PriorityName(priority)
        priorityNames = priorityNames or tInvert(enum.PRIORITY)
        return priorityNames[priority] or "?"
    end

    -- One flattened line per candidate, in the order model.Rank left them.
    --
    -- The index is carried in the text rather than left to the array order
    -- alone: the record has to be pastable verbatim and still read as a
    -- ranking. Everything the sort actually consults is reported -- priority,
    -- cooldown, stack -- so a pick that looks wrong can be checked against the
    -- comparison that produced it instead of guessed at.
    local function BuildFieldDump(candidates)
        local field = {}
        for index, candidate in ipairs(candidates) do
            field[index] = ("#%d %s [%s] priority=%s (%s) reason=%s detail=%s"
                .. " bag=%s slot=%s stack=%s locked=%s onCooldown=%s"):format(
                index,
                tostring(C_Item.GetItemNameByID(candidate.itemID)),
                tostring(candidate.itemID),
                tostring(candidate.priority),
                PriorityName(candidate.priority),
                tostring(candidate.reason),
                tostring(candidate.reasonDetail),
                tostring(candidate.bag),
                tostring(candidate.slot),
                tostring(candidate.stackCount),
                tostring(candidate.locked),
                tostring(candidate.onCooldown))
        end
        return field
    end

    local function FindInBags(itemID)
        for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID == itemID then return bag, slot end
            end
        end
    end

    function control.DumpItem(itemID)
        local bag, slot

        if itemID then
            bag, slot = FindInBags(itemID)
            if not bag then
                BitForge:Print(("Openables: item %d is not in your bags"):format(itemID))
                return
            end
        else
            local candidate = scanner.GetCurrent()
            if not candidate then
                BitForge:Print("Openables: nothing on the button to dump")
                return
            end
            bag, slot, itemID = candidate.bag, candidate.slot, candidate.itemID
        end

        local dump = model.GetDebugDump()
        if not dump then
            BitForge:Print("Openables: diagnostics are off for this module")
            return
        end

        dump[tostring(itemID)] = BuildDump(bag, slot, itemID)
        BitForge:Print(("Openables: dumped item %d. /reload, then read"
            .. " BitForgeDB.modules.Openables.debug.dump"):format(itemID))
    end

    --- Files the whole ranked field from the last scan, winner first.
    ---
    --- Read from the scan rather than recomputed: the question being asked is
    --- why the button shows what it shows, and a fresh scan would answer it
    --- against bags that may already have moved on.
    function control.DumpField()
        local candidates = scanner.GetRanked()
        if not candidates or #candidates == 0 then
            BitForge:Print("Openables: the last scan produced no candidates to rank")
            return
        end

        local dump = model.GetDebugDump()
        if not dump then
            BitForge:Print("Openables: diagnostics are off for this module")
            return
        end

        dump[FIELD_KEY] = BuildFieldDump(candidates)
        BitForge:Print(("Openables: dumped %d ranked candidates. /reload, then read"
            .. " BitForgeDB.modules.Openables.debug.dump.%s"):format(#candidates, FIELD_KEY))
    end

    SLASH_BITFORGEOPENABLESDUMP1 = "/bfodump"
    SlashCmdList["BITFORGEOPENABLESDUMP"] = function(input)
        local argument = input and input:match("%S+")
        -- Matched before the item ID, not after: "all" carries no digits, so the
        -- ID parse would silently read it as "no argument" and dump the button.
        if argument and argument:lower() == "all" then
            control.DumpField()
            return
        end
        control.DumpItem(tonumber(argument and argument:match("%d+")))
    end
end

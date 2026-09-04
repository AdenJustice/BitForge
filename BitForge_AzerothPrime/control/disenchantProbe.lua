---@class BitForge.AzerothPrime
local ns = select(2, ...)

local ipairs = ipairs

local SpellIsTargeting = SpellIsTargeting

local C_SpellBook = C_SpellBook
local C_TooltipInfo = C_TooltipInfo

local model = ns.model

---@class BitForge.AzerothPrime.Control
local control = ns.control
local sellScanner = control.sellScanner

-- Disenchantability is inferred everywhere else in this module -- uncommon or
-- better, armour or a weapon, absent from a crawled table of exceptions. The
-- client knows the real answer, but says it only about the item under the
-- cursor while a spell that targets items is pending: the tooltip line, and the
-- grey wash over bag slots that cannot take the spell. Casting is protected, so
-- no addon can create that state; the probe can only be in the room when the
-- player enters it, and it reads every carried item at that instant.
--
-- The pending spell is never identified, and does not need to be: the line
-- appears only while a disenchant waits for a target, and a pending Prospecting
-- produces no such line on anything. The screen on quality and class is there
-- to keep the cost down -- a tooltip read per bag slot per raise -- and cannot
-- change an answer, since nothing outside uncommon-or-better armour and weapons
-- is disenchantable anyway.
--
-- Never go back to C_Item.DoesItemMatchSpellItemCondition, the call the
-- greyed-out bag slots go through: it answers about a pending spell carrying an
-- item condition, and a Disenchant is not one --
-- C_Spell.TargetSpellChecksItemCondition is false throughout, so the probe
-- refused every item and learned nothing. The legacy SpellIsTargeting, which
-- the C_Spell predicates read as superseding, is what reports the state.

---@class BitForge.AzerothPrime.Control.DisenchantProbe
local disenchantProbe = {}

--- Whether a spell is waiting for an item target and this character could have
--- put a disenchant there.
---
--- The spell check is an early-out rather than a correctness fence -- the
--- tooltip line does the identifying -- but it spares every non-enchanter a bag
--- walk each time they raise anything at all. ContainsAnyDisenchantSpell asks
--- exactly the right question, where the profession scan behind
--- model.GetIsEnchanter only approaches it.
---@return boolean
local function disenchantPending()
    if not SpellIsTargeting() then return false end
    return C_SpellBook.ContainsAnyDisenchantSpell()
end

--- Reads the client's answer for one occupied bag slot.
---
--- Returns nil rather than false for a slot the probe declines to judge, so a
--- caller can tell "the client says no" from "the probe did not ask".
---@param bagIndex number
---@param slotIndex number
---@param knownSlotInfo table|nil  C_Container.GetContainerItemInfo's own
---   return for this slot, from model.facts.Walk's shared entries -- passed
---   straight through to sellScanner.Gather, which is what lets Harvest ride
---   the walk sellScanner.Scan or openScanner.Scan may already have paid for
---   this generation instead of re-reading the container itself.
---@return table|nil facts
---@return boolean|nil canDisenchant
local function readSlot(bagIndex, slotIndex, knownSlotInfo)
    local facts = sellScanner.Gather(bagIndex, slotIndex, knownSlotInfo)
    if not facts then return nil, nil end

    -- The second fence. Quality and class are the part of the prediction that
    -- is not in doubt -- the crawled table is the doubtful part -- so screening
    -- on them costs no truth and keeps a pending Prospecting out of the data.
    --
    -- Quality can come back secret in 12.0+, the same fact model.Decide guards
    -- before its own quality comparisons. This one runs over every bag slot
    -- each time Disenchant is raised, with no pcall around the dispatch that
    -- calls it, so an unread quality has to abstain here rather than crash the
    -- handler outright.
    if model.IsUnread(facts.quality) then return nil, nil end
    if facts.quality < Enum.ItemQuality.Uncommon then return nil, nil end
    if facts.classID ~= Enum.ItemClass.Armor and facts.classID ~= Enum.ItemClass.Weapon then
        return nil, nil
    end

    local data = C_TooltipInfo.GetBagItem(bagIndex, slotIndex)
    if not data or not data.lines then return nil, nil end

    -- Matched against the constants rather than their text, so one comparison
    -- covers all eleven locales and survives Blizzard rewording the line. The
    -- line type is deliberately not part of the test: the two answers arrive on
    -- different types -- 0 for the affirmative, an error line for the refusal --
    -- and neither type is exclusive to this question.
    --
    -- ITEM_DISENCHANT_MIN_SKILL is a format string, so it cannot be compared
    -- this way and is left alone. An item carrying it is simply not learned
    -- about, and the crawled prediction stands, which is where it started.
    for _, line in ipairs(data.lines) do
        local text = line.leftText
        if text == ITEM_DISENCHANT_ANY_SKILL then return facts, true end
        if text == ITEM_DISENCHANT_NOT_DISENCHANTABLE then return facts, false end
    end

    -- Neither line present. Absence is not evidence: a tooltip that has not
    -- finished loading looks exactly like an item the server declined to
    -- comment on, and reading it as "cannot be disenchanted" would sell gear
    -- the player was keeping. Learning requires one of the two lines.
    return nil, nil
end

--- Harvests every occupied bag slot into the learned table, and -- when the
--- debug file is loaded and a dump is open -- hands what the crawled table
--- got wrong to it.
---
--- Reads model.facts.Walk's shared entries rather than the bags directly, so
--- a Disenchant raised during a merchant visit or a bank session rides the
--- walk that visit already paid for instead of taking a second one.
function disenchantProbe.Harvest()
    if not disenchantPending() then return end

    local debugNotices = control.debugNotices
    local dump = debugNotices and model.GetDebugDump()
    -- Raw (facts, canDisenchant) pairs rather than the formatted mismatch
    -- strings themselves: the comparison against model.PredictDisenchantable
    -- and the string formatting are debug/lines.lua's job, not this file's.
    local sweep = dump and {}
    local scanned = 0

    for _, entry in ipairs(model.facts.Walk()) do
        local facts, canDisenchant = readSlot(entry.bagIndex, entry.slotIndex, entry.slotInfo)
        if facts then
            scanned = scanned + 1

            if sweep then sweep[#sweep + 1] = { facts = facts, canDisenchant = canDisenchant } end

            model.LearnDisenchantable(facts.itemID, canDisenchant)
        end
    end

    if dump then debugNotices.RecordDisenchantSweep(dump, scanned, sweep) end
end

control.disenchantProbe = disenchantProbe

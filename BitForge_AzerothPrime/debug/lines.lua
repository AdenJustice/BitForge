---@class BitForge.AzerothPrime
local ns = select(2, ...)

local ipairs = ipairs
local format = string.format
local concat = table.concat
local tInvert = tInvert
local C_Item = C_Item

---@type BitForge.AzerothPrime.Enum
local enum = ns.enum

---@class BitForge.AzerothPrime.Model
local model = ns.model

---@class BitForge.AzerothPrime.View
local view = ns.view

---@class BitForge.AzerothPrime.Control
local control = ns.control

-- Everything a release build ships no source file for: the two tooltip blocks
-- a developer profile renders, and the chat/dump notices the rest of the
-- module publishes across two more layers -- ns.control.debugNotices for
-- control/disenchantProbe.lua's dump write, ns.model.debugNotices for
-- model/bankRules.lua's recipe-spell notice, kept apart from the control one
-- so a model file never reaches into ns.control (model/openRules.lua's own
-- comment states why that invariant holds). BitForge_AzerothPrime.toc wraps this
-- whole file in #@debug@, so a release build carries the flag a profile can
-- set but never this file to answer it -- every call site nil-checks the
-- sub-key it reads through rather than calling it directly.

---@class BitForge.AzerothPrime.View.DebugLines
local debugLines = {}

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

-- Distinct from debug/dumps.lua's own local PriorityName, which names the
-- ranks in the /bfdump ranked field -- this one serves only this block.
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
        return "ALLOW_LIST entry in OpenableData.lua"
    elseif reason == enum.REASON.LOCKED_BOX then
        return "LOCKED_BOX tooltip line, unlock spell known"
    elseif reason == enum.REASON.ITEM_SPELL then
        return "ITEM_SPELL fallback: GetItemSpell and IsUsableItem both answered"
    end
    return ("unrecorded (%s)"):format(tostring(reason))
end

--- The [OP] block on the open button's tooltip. Item class is the
--- discriminator the pipeline leans on hardest, so it is reported even
--- though nothing in the reason string mentions it.
---@param tooltip GameTooltip
---@param candidate table  a detector.Classify candidate
function debugLines.AddOpen(tooltip, candidate)
    if not model.IsDebug() then return end

    local _, itemType, itemSubType, _, _, classID, subClassID =
        C_Item.GetItemInfoInstant(candidate.itemID)

    tooltip:AddLine(" ")
    tooltip:AddLine(("[OP] item %d  bag %d slot %d"):format(
        candidate.itemID, candidate.bag, candidate.slot), DEBUG_COLOR:GetRGB())
    tooltip:AddLine(("[OP] shown because: %s"):format(DebugBasis(candidate)),
        DEBUG_COLOR:GetRGB())
    tooltip:AddLine(("[OP] class %s / %s (%s/%s)"):format(
        tostring(itemType), tostring(itemSubType), tostring(classID), tostring(subClassID)),
        DEBUG_COLOR:GetRGB())
    tooltip:AddLine(
        ("[OP] priority %s (%d)  locked %s  slotLocked %s  cooldown %s  deferred %s"):format(
            PriorityName(candidate.priority), candidate.priority,
            tostring(candidate.locked), tostring(candidate.slotLocked),
            tostring(candidate.onCooldown), tostring(candidate.deferred)),
        DEBUG_COLOR:GetRGB())
end

-- bindType arrives as a number and reads as noise; enum.BIND_TYPE names
-- every value Enum.ItemBind defines, and anything else falls back to the
-- number. The account verdict is printed beside it because that is the fact
-- the cascade actually reads -- the raw type alone hid the ON_ACCOUNT bug.
local BIND_TYPE_NAMES = tInvert(enum.BIND_TYPE)

local function AddDebugLine(tooltip, text)
    tooltip:AddLine(text, enum.COLOR.DEBUG:GetRGB())
end

--- The items equipped in the slots this item could occupy, or nil when it is
--- not equippable. Both entries of a dual slot are shown rather than reduced,
--- because model.CompareToEquipped is existential over them: a ring only has
--- to satisfy the test against one.
---
--- An unreadable entry (see model/facts.lua's equippedItems) carries no
--- level or quality to format, so it is reported by name instead -- the
--- debug line is how a developer would otherwise notice
--- model.CompareToEquipped decided KEEP without any level comparison at all.
local function EquippedSummary(facts)
    local items = facts.equippedItems
    if not items or #items == 0 then return nil end
    local parts = {}
    for _, equipped in ipairs(items) do
        parts[#parts + 1] = equipped.unreadable
            and "unreadable"
            or format("%d(q%d)", equipped.level, equipped.quality)
    end
    return concat(parts, "/")
end

local function StatusName(itemID, scope)
    return model.overrides.GetSell(itemID, scope) or "none"
end

--- The [BS] block on a bag item tooltip. Deliberately unlocalized: this is
--- developer output, and a locale key per line would put eleven translations
--- behind a flag no player sets.
---@param tooltip GameTooltip
---@param report table  a control.sellScanner.Explain report
function debugLines.AddSellReport(tooltip, report)
    local facts, settings = report.facts, report.settings

    tooltip:AddLine(" ")
    AddDebugLine(tooltip, format("[BS] verdict %s  rule %s", report.verdict, report.rule))

    local equipped = EquippedSummary(facts)
    AddDebugLine(tooltip, format("[BS] item %d  bag %d slot %d  ilvl %d%s",
        facts.itemID, facts.bagIndex, facts.slotIndex, facts.level,
        equipped and format("  equipped %s", equipped) or ""))

    AddDebugLine(tooltip, format("[BS] class %s/%s",
        tostring(facts.classID), tostring(facts.subclassID)))

    AddDebugLine(tooltip, format("[BS] quality %d  bind %s%s  expac %d  price %d x%d = %d",
        facts.quality, BIND_TYPE_NAMES[facts.bindType] or facts.bindType,
        facts.isBindOnAccount and " (account)" or "", facts.expacID,
        facts.sellPrice, facts.stackCount, model.GetTotalSellValue(facts)))

    AddDebugLine(tooltip, format("[BS] list: char=%s warband=%s%s",
        StatusName(facts.itemID, enum.LIST_SCOPE.CHAR),
        StatusName(facts.itemID, enum.LIST_SCOPE.GLOBAL),
        facts.isCharOverride and "  (override)" or ""))

    -- The derived facts the rule cascade branches on. None is stored on
    -- the facts table, so without them the rule that fired cannot be
    -- reconciled against the raw values on the lines above. disenchantable
    -- is the item's own property; reachable is whether it can ever get to
    -- an enchanter. Step 8 needs both, and they disagree often enough that
    -- one value would not explain a verdict.
    AddDebugLine(tooltip, format(
        "[BS] equippable %s  disenchantable %s  reachable %s  locked %s  refundable %s  set %s  excluded %s",
        tostring(model.IsEquippableBy(facts, settings.playerClass)),
        tostring(model.IsDisenchantable(facts)),
        tostring(model.CanReachAnEnchanter(facts, settings.isEnchanter)),
        tostring(facts.isLocked), tostring(facts.isRefundable),
        tostring(facts.inEquipmentSet), tostring(facts.isTempExcluded)))
end

view.debugLines = debugLines

---@class BitForge.AzerothPrime.Control.DebugNotices
local controlNotices = {}

--- Turns one Harvest sweep into the crawled-table mismatch report and files
--- it into the debug dump, formatted so it survives a SavedVariable and can
--- be pasted verbatim -- item data can carry secret values in 12.0.
---
--- Filed even when nothing disagreed, and even when nothing was eligible. A
--- dump that is simply absent cannot distinguish a crawled table that was
--- right from a probe that never ran -- which is the first thing to rule out
--- if Disenchant turns out not to reach the item-condition system at all.
---@param dump table  model.GetDebugDump()'s own table
---@param scanned number  slots that passed control/disenchantProbe.lua's fence
---@param sweep table  { { facts = table, canDisenchant = boolean }, ... }
function controlNotices.RecordDisenchantSweep(dump, scanned, sweep)
    local mismatches = {}

    for _, entry in ipairs(sweep) do
        local facts, canDisenchant = entry.facts, entry.canDisenchant
        local predicted = model.PredictDisenchantable(facts)
        if predicted ~= canDisenchant then
            mismatches[#mismatches + 1] = format(
                "%s %s q=%s cls=%s/%s predicted=%s client=%s",
                tostring(facts.itemID), tostring(facts.name),
                tostring(facts.quality), tostring(facts.classID),
                tostring(facts.subclassID),
                tostring(predicted), tostring(canDisenchant))
        end
    end

    dump.disenchantProbe = {
        scanned    = tostring(scanned),
        mismatches = mismatches,
    }
end

control.debugNotices = controlNotices

---@class BitForge.AzerothPrime.Model.DebugNotices
local modelNotices = {}

-- Item IDs already named by the 5.6 diagnostic below. Session-scoped, never
-- persisted -- it is a development aid, not state the module reasons about.
local reportedSpells = {}

--- The design (#55) 5.6 unknown, made observable in play rather than left to a
--- macro run at a remembered moment: if this ID is the recipe's own then it
--- turns up in some character's knownRecipes once they have been scanned, and
--- if it is a separate teaching spell it never will. Once per item per session.
---@param itemID number
---@param spellID number
function modelNotices.RecipeSpellObserved(itemID, spellID)
    if not model.IsDebug() then return end
    if reportedSpells[itemID] then return end
    reportedSpells[itemID] = true
    BitForge:Print(format("UPS debug: recipe item %d casts spell %d", itemID, spellID))
end

model.debugNotices = modelNotices

---@class BitForge.AzerothPrime
local ns = select(2, ...)

local ipairs = ipairs
local pairs = pairs
local wipe = table.wipe

local C_SpellBook = C_SpellBook
local C_TooltipInfo = C_TooltipInfo

local enum = ns.enum
local model = ns.model

---@class BitForge.AzerothPrime.Control
local control = ns.control

---@class BitForge.AzerothPrime.Control.Detector
local detector = {}

local LINE_TYPE = Enum.TooltipDataLineType
local USAGE_REQUIREMENT = Enum.TooltipDataUsageRequirementType
local PLAYER_SPELL_BANK = Enum.SpellBookSpellBank.Player

function detector.CanUnlock()
    return C_SpellBook.IsSpellKnown(enum.SPELL_PICK_LOCK, PLAYER_SPELL_BANK)
        or C_SpellBook.IsSpellKnown(enum.SPELL_SKELETON_PINKIE, PLAYER_SPELL_BANK)
end

-- Enum.TooltipDataLineType has no Locked member, and C_Item.IsLocked reports the
-- transient "being moved" state instead, so the localized global is the only
-- signal. `data` lets a caller reuse a tooltip it already fetched.
--
-- bag and slot are both documented Nilable = false on
-- C_TooltipInfo.GetBagItem (TooltipInfoDocumentation.lua), and
-- model/openRules.lua's Claim calls this with both nil for a record built
-- with no bag slot behind it (control/sellScanner.lua's GatherByID). Guarded
-- here rather than at that call site, so every caller is safe against a nil
-- bag/slot -- the same guard model/facts.lua's LAZY.tooltipData carries.
function detector.IsLockedBox(bag, slot, data)
    data = data or (bag and slot and C_TooltipInfo.GetBagItem(bag, slot))
    if not data or not data.lines then return false end
    for _, line in ipairs(data.lines) do
        if line.leftText == LOCKED then
            return true
        end
    end
    return false
end

-- Profession names as this client prints them, gathered from the character's own
-- trade skill lines. Rebuilt rather than derived per item: a scan touches every
-- bag slot, and the answer changes only when a profession is learned or dropped.
local professionNames = {}

--- Re-reads which profession names this character can honestly claim a rank
--- for. Called at startup, whenever the skill lines change, and after a
--- profession window has been harvested.
---
--- Three sources, in this order, because each corrects the one before it:
---
---   1. The harvested cache -- every expansion's line at its own rank. A
---      cached rank is a floor and never a ceiling: it lags until the player
---      next opens that profession, so a stale entry can only refuse an item
---      they could in fact study. That is the safe direction, which is why
---      there is no expiry.
---   2. The line the client states right now, which cannot be stale, so it
---      overwrites a cached entry for the same name rather than the larger of
---      the two winning.
---   3. Each base profession name at rank ZERO, which is exactly what a
---      requirement naming no rank asks. It must never be a real rank:
---      recording the base name at the character's overall rank made "Dragon
---      Isles Mining (25)" match on the substring "Mining" and answer with a
---      Midnight rank of 62.
---
--- Never go back to GetAllProfessionTradeSkillLines plus
--- GetProfessionInfoBySkillLineID: the first returns every profession line in
--- the game despite its name, and the second answers skillLevel 0 for all of
--- them, including the ones the character holds (#265) -- so the pair can only
--- ever hand every line the parent's single rank.
function detector.RefreshProfessions()
    wipe(professionNames)

    for _, lines in pairs(model.GetProfessionRanks()) do
        for name, skillLevel in pairs(lines) do
            professionNames[name] = skillLevel
        end
    end

    local slots = { GetProfessions() }
    for index = 1, 5 do
        local slot = slots[index]
        if slot then
            -- Return 1 is the base profession, 3 the rank, 11 the
            -- expansion-qualified name of the line that rank belongs to.
            -- Guarded with `if` rather than `slot and GetProfessionInfo(slot)`:
            -- Lua adjusts an `and` expression to a single value, so every
            -- return but the first would arrive nil.
            local name, _, rank, _, _, _, _, _, _, _, lineName =
                GetProfessionInfo(slot)
            if name then
                -- A nil lineName drops the live rank and leaves only the
                -- base name at zero, refusing every ranked requirement for a
                -- profession they do hold -- the safe direction again.
                if lineName then professionNames[lineName] = rank or 0 end
                if professionNames[name] == nil then professionNames[name] = 0 end
            end
        end
    end
end

--- The names a usage requirement is matched against, each at the rank that
--- answers for it. professionNames is private to this file, so control.lua's
--- dump commands reach it through here.
---@return table<string, number>
function detector.GetKnownProfessions()
    return professionNames
end

-- The rank a requirement names, as digits in parentheses -- "Requires Dragon
-- Isles Mining (25)". Every locale prints it that way, and its absence reads as
-- no rank required. A character who has the line at rank 1 does not meet it, and
-- C_Item.IsUsableItem answers true regardless, so nothing else catches that.
local function requiredRank(text)
    return tonumber(text:match("%((%d+)%)")) or 0
end

--- Whether a usage requirement gates this item on a trade skill at all, met or
--- not. The question requiresKnownProfession cannot answer: a profession the
--- character has not learned is absent from professionNames, so matching by name
--- reports "no requirement" for exactly the items that carry the strictest one.
---
--- requirementType is what the client states it in, and what Blizzard's own
--- tooltip code reads (Blizzard_PerksProgramElements.lua). It is absent from the
--- generated struct documentation, so a name match stays behind it for a build
--- that leaves the field nil -- rank ignored there, since a requirement is one
--- whether or not it is met.
local function hasSkillRequirement(data)
    if not (data and data.lines) then return false end
    for _, line in ipairs(data.lines) do
        if line.type == LINE_TYPE.UsageRequirement then
            if line.requirementType == USAGE_REQUIREMENT.Skill then return true end
            if type(line.leftText) == "string" then
                -- professionNames holds only the lines this character can
                -- claim a rank for, so a build that leaves requirementType nil
                -- and names an expansion line that is neither cached nor
                -- current falls through unnoticed. Acceptable because
                -- requirementType above is the primary test; this loop is only
                -- its second line of defence.
                for name in pairs(professionNames) do
                    if line.leftText:find(name, 1, true) then return true end
                end
            end
        end
    end
    return false
end

-- True when a usage requirement line names a profession this character has, at
-- the rank it asks for.
--
-- Profession knowledge items -- "Study to increase your <Profession> Knowledge
-- by N" -- are Miscellaneous/Other carrying a plain Use: line, which is exactly
-- the shape the junk gate turns away. The requirement is what tells them apart:
-- a firecracker is gated on nothing, a knowledge item on a trade skill.
--
-- Matched by name because the client exposes no required-skill API to an addon:
-- Enum.TooltipDataLineType has no member for it, C_TradeSkillUI has no
-- knowledge function, and GetItemInfo does not return the item's reqskill. Both
-- sides of the comparison come from the client in the same locale, so this
-- compares two of the client's own strings rather than scraping a translation.
-- An empty set matches nothing, so a character with no professions is not
-- handed every Miscellaneous/Other item in their bags.
local function requiresKnownProfession(data)
    if not (data and data.lines) then return false end
    for _, line in ipairs(data.lines) do
        if line.type == LINE_TYPE.UsageRequirement and type(line.leftText) == "string" then
            -- Longest match wins. The requirement names the expansion's own line
            -- ("Dragon Isles Mining") and the base name ("Mining") is a
            -- substring of it, so answering on whichever matched first would let
            -- a maxed classic profession satisfy a current-expansion rank.
            local matchedName, matchedRank
            for name, skillLevel in pairs(professionNames) do
                if line.leftText:find(name, 1, true)
                    and (not matchedName or #name > #matchedName) then
                    matchedName, matchedRank = name, skillLevel
                end
            end
            if matchedName then
                return matchedRank >= requiredRank(line.leftText)
            end
        end
    end
    return false
end

--- What the open path decides about one bag slot, in the two shapes its
--- callers have always read:
---
---   accepted: priority, isLocked, reason (enum.REASON), detail
---             [, startsQuest]
---   rejected: nil, reason (enum.REJECTED), detail
---
--- Everything past the first return is diagnostics; callers test the priority
--- and stop. `data` supplies a tooltip for an item in no bag; production omits
--- it. `suppress` rides through unchanged to model.openRules.Claim's own
--- opt-out, naming which curated-list rung to switch off -- the question
--- control/control.lua's allowList dump field puts of one item, and
--- debug/allowListAudit.lua of a whole list at once.
---
--- The judgement itself is model.openRules.Claim; this is the translation
--- back. isLocked and startsQuest are open-path detail rather than part of the
--- claim contract, so Claim returns them past its five contract values, where
--- model.arbiter's own destructuring drops them -- `detail`, the fifth, IS
--- destructured and rides the claim entry, because control/openScanner.lua
--- reads it back off the verdict rather than calling here a second time.
---
--- The dump path, not the scan path: control/openScanner.lua asks the arbiter
--- for a resolved record (#356), so what reaches here is /bfdump and the one
--- slot per scan whose record never resolved.
---@param suppress AzerothPrime.OpenRulesSuppress|nil
function detector.Classify(bag, slot, itemID, data, suppress)
    -- The shared cached record when a scan has already resolved this slot,
    -- and GetPartial's otherwise -- a record that has not resolved (item data
    -- not yet cached), or a bag=nil classification with no slot at all. Both
    -- come from the same lazy machinery in model/facts.lua, so a rung Claim
    -- never reaches costs nothing either way.
    local record = (bag and model.facts.Get(bag, slot))
        or model.facts.GetPartial(bag, slot, itemID)

    local claim, strength, reason, _, detail, isLocked, startsQuest =
        model.openRules.Claim(record, data, suppress)

    if not claim then return nil, reason, detail end
    return strength, isLocked, reason, detail, startsQuest
end

-- The four client probes model/openRules.lua's ladder cannot own itself. Its
-- own comment above `probes` says why they are pushed rather than pulled.
model.openRules.SetProbes({
    IsLockedBox             = detector.IsLockedBox,
    CanUnlock               = detector.CanUnlock,
    HasSkillRequirement     = hasSkillRequirement,
    RequiresKnownProfession = requiresKnownProfession,
})

control.detector = detector

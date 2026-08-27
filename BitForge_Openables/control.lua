---@type string, BitForge.Openables
local ADDON_NAME, ns = ...
local events = BitForge.Events

local ipairs = ipairs
local pairs = pairs
local wipe = table.wipe
local format = string.format
local concat = table.concat

local C_Container = C_Container
local C_Item = C_Item
local C_QuestLog = C_QuestLog
local C_TooltipInfo = C_TooltipInfo
local C_TradeSkillUI = C_TradeSkillUI
local IsPlayerSpell = IsPlayerSpell

-- GlobalStrings, so localized: the "<Right Click to Open>" line on a container's
-- tooltip. Comparisons are guarded on it being non-nil, or `line.leftText == nil`
-- would match every line without left text.
local ITEM_OPENABLE = ITEM_OPENABLE

local enum = ns.enum
local locale = ns.locale
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

--- Subscribes to one of core's two command events. Separate from ns:Subscribe
--- because core also has to be told which addon is answering: the bus knows
--- only an owner table, and /bitforge's roster names modules.
function ns:SubscribeCommand(event, callback)
    BitForge.SubscribeCommand(ADDON_NAME, event, callback, self)
end

local detector = {}

local LINE_TYPE = Enum.TooltipDataLineType
local USAGE_REQUIREMENT = Enum.TooltipDataUsageRequirementType
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

-- Housing decor, dyes and room customizations. Learned on use and then no longer
-- needed, so the class answers the learn question outright the way Recipe does.
local function isHousing(itemID)
    local classID = select(6, C_Item.GetItemInfoInstant(itemID))
    return classID == Enum.ItemClass.Housing
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
-- Consumable's buff subclasses are denied, and so is Generic -- which the client
-- prints as "Explosives and Devices" and fills with gadgets: bombs, target
-- dummies, repair bots, remote auction house access. Not Consumable/Other,
-- which holds conduits, reputation tokens and use-to-unlock items.
--
-- Denying a whole subclass is safe in a way a class rule alone would not be:
-- ALLOW_LIST, hasLoot and the openable line are all consulted before
-- isRejectedByClass runs, so a genuine cache shipping in one of these is
-- surfaced on the evidence that it is one and never reaches here.
local DENIED_SUBCLASSES = {
    [Enum.ItemClass.Consumable] = {
        [Enum.ItemConsumableSubclass.Generic]      = REJECTED.DENIED_CLASS,
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

--- Re-reads which profession names this character can honestly claim a rank
--- for. Called at startup, whenever the skill lines change, and after a
--- profession window has been harvested, so learning or levelling a profession
--- reaches the match without a reload.
---
--- Three sources, in this order, because each can correct the one before it:
---
---   1. The harvested cache -- every expansion's line, each at its own rank.
---      A cached rank is a floor and never a ceiling: it lags until the player
---      next opens that profession, so a stale entry can only refuse an item
---      they could in fact study. That is the direction this gate already errs
---      in, which is why there is no expiry.
---   2. The line the client states right now, which cannot be stale, so it
---      overwrites a cached entry for the same name rather than the larger of
---      the two winning.
---   3. Each base profession name at rank ZERO. Zero means "you have this
---      profession" and no more, which is exactly what a requirement naming no
---      rank asks. It must never be a real rank: recording the base name at the
---      character's overall rank is the bug this function was rewritten to fix
---      -- "Dragon Isles Mining (25)" matched on the substring "Mining" and was
---      answered with a Midnight rank of 62.
---
--- The old two-API pass is gone. GetAllProfessionTradeSkillLines returns every
--- profession line in the game despite its name, and
--- GetProfessionInfoBySkillLineID answers skillLevel 0 for all of them --
--- including the ones the character holds, confirmed in play (#265) -- so
--- together they could only ever hand every line the parent's single rank.
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
                -- If a build ever answers lineName nil, the live rank is
                -- dropped and only the base name at zero survives, refusing
                -- every ranked requirement for a profession they do hold --
                -- the same safe direction this whole cache already errs in.
                if lineName then professionNames[lineName] = rank or 0 end
                if professionNames[name] == nil then professionNames[name] = 0 end
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
--
-- The name alone is not the whole requirement, though. "Requires Dragon Isles
-- Mining (25)" names a rank as well, and a character who has the line at rank 1
-- does not meet it -- C_Item.IsUsableItem answers true for these regardless, so
-- nothing else catches it. The rank is digits in parentheses, which every locale
-- prints the same way, and its absence reads as no rank required.
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
                -- professionNames no longer holds every expansion's line, only
                -- the ones this character can claim a rank for, so this
                -- recognises fewer requirements than it once did -- a build
                -- that leaves requirementType nil and names an expansion line
                -- that is neither cached nor current falls through unnoticed.
                -- Acceptable because requirementType above is the primary
                -- test; this loop is only its second line of defence.
                for name in pairs(professionNames) do
                    if line.leftText:find(name, 1, true) then return true end
                end
            end
        end
    end
    return false
end

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

-- A met trade skill requirement makes an item knowledge only in the class pair
-- knowledge items actually occupy. Miscellaneous/Other is that pair -- it is the
-- shape isRejectedByClass discards and the requirement exists to rescue. Plenty
-- of other things are gated on a profession without teaching anything: a
-- Consumable/Other skinning bait requires Khaz Algar Skinning and is a thing you
-- use, not a thing you study, and promoting it to LEARN parked it above every
-- genuine learnable in the bags. isRejectedByClass turns that pair away before
-- this runs now, leaving this the second line of defence rather than the only
-- one.
--- A toy the player has not added to the toy box yet.
---
--- Typed rather than read off the tooltip. A toy says so on a plain unnumbered
--- line -- locale text, and never the line that accepted the item: the reported
--- key (253629) is accepted on its teleport's ItemSpellTriggerOnUse and carries
--- no ToyEffect line at all, so the branch that recognises toys by their
--- accepting line cannot see it.
---
--- Learned is the other half of the question. An item still in the bags after
--- the toy is collected has nothing left to give, so it goes back to being what
--- its class pair says it is.
local function isUnlearnedToy(itemID)
    if C_ToyBox.GetToyInfo(itemID) == nil then return false end
    return not PlayerHasToy(itemID)
end

local function isProfessionKnowledge(itemID, data)
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))
    if classID ~= Enum.ItemClass.Miscellaneous
        or subClassID ~= Enum.ItemMiscellaneousSubclass.Other then
        return false
    end
    return requiresKnownProfession(data)
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
--   Housing items. Enum.ItemClass.Housing is the same shape as Recipe -- every
--   subclass of it so far is learned on use, on nothing but a plain Use: line.
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
    if isHousing(itemID) then return enum.PRIORITY.LEARN end
    if isProfessionKnowledge(itemID, data) then return enum.PRIORITY.LEARN end
    if isUnlearnedToy(itemID) then return enum.PRIORITY.LEARN end
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
        if isUnlearnedToy(itemID) then return false end
        return true, REJECTED.ON_USE_MISC
    end

    -- The mirror of the branch above. There a met trade skill rescues the item:
    -- Miscellaneous/Other is where knowledge lives, and studying is what the
    -- requirement gates. Here the same evidence condemns it -- Consumable/Other
    -- holds bait and lures, where a trade skill gates a tool you use out in the
    -- world, which a plain Use: line cannot tell from an openable. The conduits
    -- and reputation tokens sharing this pair are gated on nothing and never
    -- reach here.
    --
    -- Whether the requirement is met is beside the point on this side. A bait
    -- for a profession the character has not learned is no more an openable for
    -- being unusable, and IsUsableItem answers true for these regardless, so
    -- nothing downstream would catch it.
    if classID == Enum.ItemClass.Consumable
        and subClassID == Enum.ItemConsumableSubclass.Other
        and acceptedOnPlainUse(acceptedLine)
        and hasSkillRequirement(data) then
        return true, REJECTED.PROFESSION_TOOL
    end

    return false
end

-- The tail both accept branches share. Never re-inline it: the two differ only
-- in the reason they report, and while each spelled the call out for itself the
-- fallback branch quietly stopped handing over the tooltip, leaving every rule
-- that reads a usage requirement to answer on no evidence.
local function acceptedVerdict(bag, slot, itemID, acceptedLine, data, reason)
    if isContainer(itemID) then
        return enum.PRIORITY.OPEN, false, reason, acceptedLine
    end

    local rejected, why = isRejectedByClass(bag, slot, itemID, acceptedLine, data)
    if rejected then return nil, why end

    -- Below the class rules rather than above them: an item that is both
    -- unusable and class-rejected reports the class reason, which is the more
    -- specific fact and the one a dump should show. Above this line the guard
    -- would report UNUSABLE for an out-of-season firecracker and bury HOLIDAY.
    -- Scoped to acceptedOnPlainUse rather than every accept, so it also covers
    -- what learnVerdict below is about to promote to LEARN -- a recipe, a
    -- housing decor, an unlearned toy -- whenever any of those arrived on a
    -- plain Use: line rather than a typed one. Ruled on in #299: an item the
    -- client says cannot be used is not something to act on now, whatever
    -- class it belongs to. The exemption is for a typed accepting line
    -- (ToyEffect, ItemSpellTriggerLearn, LearnTransmogSet,
    -- LearnTransmogIllusion, LearnableSpell) -- that names what the item IS,
    -- and a toy or a taught recipe you cannot use today is still that thing.
    -- Reported through #266, where an item needing a component the player had
    -- not got was offered on nothing but its Use: line.
    if acceptedOnPlainUse(acceptedLine) and not C_Item.IsUsableItem(itemID) then
        return nil, REJECTED.UNUSABLE
    end

    return learnVerdict(itemID, acceptedLine, data), false, reason, acceptedLine
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
        -- Which of the two sources answered, reported separately from the gate
        -- itself. Only the client's questInfo means the item *offers* a quest;
        -- a QUEST_GATED entry is an item some quest consumes, which earns the
        -- same priority and none of the exclamation mark.
        local startsQuest = questInfo ~= nil and questInfo.questID ~= nil
        return enum.PRIORITY.QUEST, false, REASON.QUEST_GATE, questID, startsQuest
    end

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
        return acceptedVerdict(bag, slot, itemID, acceptedLine, data, REASON.TOOLTIP_LINE)
    end

    -- No typed line matched at all, so by acceptedOnPlainUse's own definition
    -- this is the merely-usable case -- unless the class or the requirement
    -- says otherwise.
    if C_Item.GetItemSpell(itemID) and C_Item.IsUsableItem(itemID) then
        return acceptedVerdict(bag, slot, itemID, nil, data, REASON.ITEM_SPELL)
    end

    return nil, REJECTED.NO_EVIDENCE
end

control.detector = detector

local C_Timer = C_Timer

local scanner = {}

local current
local ranked
local scanQueued = false
local pendingItems = {}

--- Start an async load for an item's data, returning true when one was needed.
---
--- onItemDataLoaded discards any result whose itemID is not pending, so a
--- caller that requests a load on its own never hears back about it.
---@param itemID number
---@return boolean started
function scanner.RequestItemData(itemID)
    if C_Item.IsItemDataCachedByID(itemID) then return false end
    pendingItems[itemID] = true
    C_Item.RequestLoadItemDataByID(itemID)
    return true
end

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
            if info and info.itemID and not scanner.RequestItemData(info.itemID) then
                reviewAllowListEntry(bag, slot, info.itemID)
                reviewQuestGatedEntry(bag, slot, info.itemID)

                local priority, locked, reason, detail, startsQuest =
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
                        -- The client locks a slot for the duration of a cast
                        -- and unlocks it when the cast ends, however it ended.
                        -- Not `locked`, which is detector.IsLockedBox -- a
                        -- lockbox needing a key, and a different fact.
                        slotLocked   = info.isLocked or false,
                        -- Rank's first key. Boolean, never nil -- see
                        -- model.IsDeferred.
                        deferred     = model.IsDeferred(info.itemID),
                        locked       = locked or false,
                        -- Drives the button's quest bang, so it is state the
                        -- view reads rather than diagnostics.
                        startsQuest  = startsQuest or false,
                        -- Diagnostics for the debug tooltip; see enum.REASON.
                        reason       = reason,
                        reasonDetail = detail,
                    }
                end
            end
        end
    end
    return candidates
end

--- Whether a click is still resolving, in which case the button stays as it is.
---
--- The bag slot's lock is what separates a cast in flight from a use that
--- simply failed, and the difference is load-bearing: a failed use changes no
--- bags and never locks, so it is not in flight and the deferral advances the
--- button at once, which is the whole of #39's fix.
---
--- The mark is itemID-scoped, like the deferral it rides beside -- so with the
--- same item stacked across slots (lockboxes, Knowledge Tomes are typical),
--- any locked copy holds. Stopping at the first matching candidate would judge
--- the hold by whichever slot collectCandidates happened to reach first, not
--- the one the cast actually locked.
---
--- Clears the mark as a side effect once it cannot hold. Absent, or present
--- with every copy unlocked, both mean the use resolved -- including an
--- interrupted cast, which is why unlocked releases rather than only absent.
local function holdsForInFlight(candidates)
    local itemID = model.InFlightItem()
    if not itemID then return false end

    for _, candidate in ipairs(candidates) do
        if candidate.itemID == itemID and candidate.slotLocked then
            return true
        end
    end

    model.ClearInFlight()
    return false
end

function scanner.Scan()
    scanQueued = false

    if not model.IsEnabled() then
        current, ranked = nil, nil
        model.ClearInFlight()
        view.ClearItem()
        return
    end

    local candidates = collectCandidates()
    -- A held scan returns before `ranked` is reassigned below, so the
    -- ranked-field dump (/bfdump o all) never captures a locked row -- the
    -- single-item report (/bfdump o <id>) reads the slot live and is where a
    -- hold is actually visible.
    if holdsForInFlight(candidates) then return end

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

local function onBagUpdate()
    scanner.RequestScan()
end

-- An interrupted cast unlocks its slot without changing what is in any bag, so
-- BAG_UPDATE_DELAYED never fires for it and the hold in scanner.Scan would
-- otherwise sit until some unrelated event happened to rescan.
local function onItemLockChanged()
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

-- Item data and tooltip data resolve through two separate caches, and
-- collectCandidates only waits on the first: an item past the
-- IsItemDataCachedByID guard can still hand Classify a sparse tooltip, which
-- walks no lines and drops it as NO_EVIDENCE. ITEM_DATA_LOAD_RESULT cannot
-- cover that -- the item data was already cached -- so the button stays stale
-- until an unrelated bag change happens to fire BAG_UPDATE_DELAYED.
--
-- The payload's dataInstanceID is ignored: the scan retains no instance IDs to
-- match it against, and a nil means "every tooltip" in any case. RequestScan
-- debounces to one scan per frame, so a burst of resolutions costs one pass.
local function onTooltipDataUpdate()
    scanner.RequestScan()
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

-- Every expansion's line of the open profession, each at its own rank.
--
-- This is the only call that states them. GetProfessionInfo names the newest
-- line the character holds and nothing else, so a requirement gated on an older
-- expansion has no live answer at all -- and GetChildProfessionInfos answers
-- only for the profession whose window is open. So the ranks are harvested
-- whenever the player happens to open one and kept in the saved variables
-- between times. Blizzard's own rank bar reads the same call
-- (Blizzard_ProfessionsRankBar.lua:51-62).
--
-- The window test is not a formality: the call answers for whatever window was
-- last open, so without it any raise of this event would re-file a stale answer
-- under whichever profession it happened to belong to.
local function harvestOpenProfession()
    local current = C_TradeSkillUI.GetChildProfessionInfo()
    if not (current and (current.professionID or 0) ~= 0) then return end

    local children = C_TradeSkillUI.GetChildProfessionInfos()
    if not children then return end

    local parent, lines = nil, {}
    for _, info in ipairs(children) do
        if info.professionName and info.skillLevel then
            parent = parent or info.parentProfessionName
            lines[info.professionName] = info.skillLevel
        end
    end
    if not parent then return end

    model.SetProfessionRanks(parent, lines)
    -- The cache is what the match reads, and the button may be showing a
    -- verdict taken before this harvest -- the same pair onSkillLinesChanged
    -- runs above, for the same reason.
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
    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        steps   = {
            -- Data written before this module was versioned already matches the
            -- version-1 shape, so adopting the version is the whole migration.
            [1] = function() end,
        },
    }, startModule)
end

ns:Subscribe(events.BAG_UPDATE_DELAYED, onBagUpdate)
ns:Subscribe(events.ITEM_LOCK_CHANGED, onItemLockChanged)
ns:Subscribe(events.ITEM_DATA_LOAD_RESULT, onItemDataLoaded)
ns:Subscribe(events.TOOLTIP_DATA_UPDATE, onTooltipDataUpdate)
ns:Subscribe(events.ACTIONBAR_UPDATE_COOLDOWN, onCooldownUpdate)
ns:Subscribe(events.PLAYER_REGEN_ENABLED, onRegenEnabled)
ns:Subscribe(events.QUEST_ACCEPTED, onQuestChanged)
ns:Subscribe(events.QUEST_TURNED_IN, onQuestChanged)
ns:Subscribe(events.QUEST_REMOVED, onQuestChanged)
ns:Subscribe(events.PLAYER_LEVEL_UP, onLevelUp)
ns:Subscribe(events.SKILL_LINES_CHANGED, onSkillLinesChanged)
ns:Subscribe(events.TRADE_SKILL_LIST_UPDATE, harvestOpenProfession)
ns:Subscribe(events.CVAR_UPDATE, onCVarUpdate)
ns:Subscribe(events.UPDATE_BINDINGS, onUpdateBindings)
ns:Subscribe(events.PLAYER_READY, Init)

-- Debug dump
--
-- /bfdump o [itemID] shows everything detector.Classify reads about an item in
-- the report window, so a surprising decision can be inspected without a
-- /reload. With no argument it dumps whatever is on the button.
--
-- /bfdump o all shows the other half of the question. A single item's record
-- says why that item was accepted but not why it was the one shown: the button
-- takes candidates[1] and the rest are discarded unseen, so a surprising pick
-- reads as a verdict with nothing to compare it against. The field dump shows
-- the whole ranked list, winner first, which turns the pick back into a margin.
--
-- Never gate this block on model.IsDebug(). The commands record nothing -- the
-- record goes to the player, not to disk -- so there is nothing left to gate.
do

    -- The names a usage requirement is matched against, each at the rank that
    -- answers for it. This is professionNames itself rather than a re-read of
    -- the API: the two now differ, and the one that decides is this one.
    -- "Midnight Mining = 62, Mining = 0, Dragon Isles Mining = 40" says
    -- immediately which line answered and why.
    local function KnownProfessions()
        local names = {}
        for name, skillLevel in pairs(professionNames) do
            names[#names + 1] = ("%s = %d"):format(name, skillLevel)
        end
        -- Sorted so two reports can be diffed; pairs order is not stable.
        table.sort(names)
        return #names > 0 and table.concat(names, ", ") or "none"
    end

    -- What the pipeline would decide if this item were not allow-listed. A
    -- listed item otherwise hides whether its entry still earns its place, since
    -- ALLOW_LIST answers first. The entry is restored immediately, through a
    -- pcall so a Classify error cannot drop it.
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

    -- Every field is flattened with tostring: tooltip data can carry secret
    -- values in 12.0, and a SavedVariable has to survive serialization.
    local function BuildDump(bag, slot, itemID)
        local _, itemType, itemSubType, _, _, classID, subClassID =
            C_Item.GetItemInfoInstant(itemID)
        local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
        local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
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
            -- The slot's own lock, read live. Distinct from verdict's
            -- "locked" above, which is detector.IsLockedBox -- a lockbox
            -- needing a key -- and from the ranked-field dump's slotLocked,
            -- which only ever shows the pre-hold state; see scanner.Scan.
            isLocked    = tostring(containerInfo and containerInfo.isLocked),
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

    -- The scalar keys BuildDump's table literal writes, excluding "lines" (that
    -- one is rendered separately, as tooltip[n] rather than a field=value line).
    -- Fixed here rather than read with pairs: a table literal's pairs() order is
    -- unspecified, and a report has to render identically for every player who
    -- copies one out, not reshuffle from one /reload to the next.
    local DUMP_FIELDS = {
        "itemID",
        "name",
        "where",
        "isLocked",
        "class",
        "isQuestItem",
        "questID",
        "isActive",
        "hasSpell",
        "isUsable",
        "professions",
        "verdict",
        "allowList",
    }

    --- One item's classification as text a player can select and paste.
    --- Both entry points render the same way -- the tooltip's report gesture
    --- and /bfdump o differ only in how they resolve the item.
    ---@param bag number
    ---@param slot number
    ---@param itemID number
    ---@return string
    local function RenderItemReport(bag, slot, itemID)
        local dump = BuildDump(bag, slot, itemID)
        local lines = {
            "BitForge Openables -- item report",
            BitForge:ReportHeader(ADDON_NAME),
            "",
        }

        for _, field in ipairs(DUMP_FIELDS) do
            lines[#lines + 1] = format("%s = %s", field, tostring(dump[field]))
        end

        if #dump.lines > 0 then
            lines[#lines + 1] = ""
            for index, line in ipairs(dump.lines) do
                lines[#lines + 1] = format("tooltip[%d] = %s", index, line)
            end
        end

        return concat(lines, "\n")
    end

    --- One item's classification as text a player can select and paste, for
    --- the item currently under the tooltip's report gesture.
    ---@param bag number
    ---@param slot number
    ---@param itemID number
    ---@return string
    function control.ReportText(bag, slot, itemID)
        return RenderItemReport(bag, slot, itemID)
    end

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
                .. " bag=%s slot=%s stack=%s locked=%s slotLocked=%s onCooldown=%s deferred=%s"):format(
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
                tostring(candidate.slotLocked),
                tostring(candidate.onCooldown),
                tostring(candidate.deferred))
        end
        return field
    end

    --- The whole ranked field from the last scan as text a player can select
    --- and paste, winner first.
    ---@param candidates table[]
    ---@return string
    local function RenderFieldDump(candidates)
        local lines = {
            "BitForge Openables -- ranked field",
            BitForge:ReportHeader(ADDON_NAME),
            "",
        }

        for _, line in ipairs(BuildFieldDump(candidates)) do
            lines[#lines + 1] = line
        end

        return concat(lines, "\n")
    end

    local function FindInBags(itemID)
        for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID == itemID then return bag, slot end
            end
        end
    end

    --- Show one item's whole classification in the report window.
    ---
    --- Nothing is stored: the record used to be parked in the module's debug
    --- container for a later session to dig out of SavedVariables, which is
    --- why it needed the debug flag to stop it accumulating unasked. Rendered
    --- and shown, it records nothing, so it needs no flag and no /reload.
    ---@param itemID number|nil
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

        BitForge:ShowReport(RenderItemReport(bag, slot, itemID), locale["report:blurb"],
            BitForge:DiagnosticReportTitle())
    end

    --- Show the whole ranked field from the last scan in the report window,
    --- winner first.
    ---
    --- Read from the scan rather than recomputed: the question being asked is
    --- why the button shows what it shows, and a fresh scan would answer it
    --- against bags that may already have moved on. Like control.DumpItem,
    --- nothing is stored -- see its comment for why the debug gate this used
    --- to need is gone with it.
    function control.DumpField()
        local candidates = scanner.GetRanked()
        if not candidates or #candidates == 0 then
            BitForge:Print("Openables: the last scan produced no candidates to rank")
            return
        end

        BitForge:ShowReport(RenderFieldDump(candidates), locale["report:blurbField"],
            BitForge:DiagnosticReportTitle())
    end

    ns:SubscribeCommand(events.MODULE_DUMP, function(addon, argument)
        if addon ~= ADDON_NAME then return end

        local subcommand = argument:match("%S+")
        -- Matched before the item ID, not after: "all" carries no digits, so the
        -- ID parse would silently read it as "no argument" and dump the button.
        if subcommand and subcommand:lower() == "all" then
            control.DumpField()
            return
        end
        control.DumpItem(tonumber(subcommand and subcommand:match("%d+")))
    end)
end

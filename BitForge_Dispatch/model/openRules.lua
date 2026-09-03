---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs
local select = select
local sort = table.sort
local wipe = wipe or function(target)
    for key in pairs(target) do target[key] = nil end
end

local C_Item = C_Item

-- GlobalStrings, so localized: the "<Right Click to Open>" line on a container's
-- tooltip. Comparisons are guarded on it being non-nil, or `line.leftText == nil`
-- would match every line without left text.
local ITEM_OPENABLE = ITEM_OPENABLE

---@class BitForge.Dispatch.Model
local model = ns.model
---@type BitForge.Dispatch.Enum
local enum = ns.enum

local CLAIM = enum.CLAIM
local REASON = enum.REASON
local REJECTED = enum.REJECTED
local LINE_TYPE = Enum.TooltipDataLineType

---@class BitForge.Dispatch.Model.OpenRules
local openRules = {}

--- The name this file registers its claimant under, stated once. Read back by
--- control/openScanner.lua, which asks this one claimant alone before deciding
--- whether a slot is worth a full model.arbiter.Resolve -- a bare "open"
--- there would be a second definition of the same string with nothing tying
--- the two together.
openRules.CLAIMANT = "open"

-- Session skips are deliberately not persisted: a session skip that survived a
-- reload would be indistinguishable from a permanent blacklist.
openRules.sessionSkip = {}

-- Items already clicked this round. The back of the queue rather than out of
-- it: openRules.Rank sorts a deferred item last instead of dropping it, so it
-- comes back the moment nothing else is left. Not persisted, for the same
-- reason session skips are not, and weaker still -- a deferral is meant to
-- outlast one click, not one session.
openRules.deferred = {}

function openRules.IsSkipped(itemID)
    return openRules.sessionSkip[itemID] == true
end

-- Both invalidate, for the reason model/overrides.lua's SetField gives: a
-- session skip is read by Claim and stored nowhere a record holds, so the
-- verdict model/arbiter.lua memoised on the record before the skip would
-- otherwise keep the item on the button until some unrelated bag event
-- happened to turn the generation over. The setter does it so no caller has
-- to remember to.
function openRules.Skip(itemID)
    openRules.sessionSkip[itemID] = true
    model.facts.Invalidate()
end

function openRules.ClearSkips()
    wipe(openRules.sessionSkip)
    model.facts.Invalidate()
end

--- Whether this item has already been clicked and sent to the back of the queue.
---
--- A real boolean, never nil: openRules.Rank compares this field between two
--- candidates, and a field that is nil on some and false on others makes the
--- comparator inconsistent -- table.sort raises on that rather than merely
--- misordering.
---@return boolean
function openRules.IsDeferred(itemID)
    return openRules.deferred[itemID] == true
end

--- Send this item to the back of the queue, and start a new round when it was
--- already at the back.
---
--- Deferring twice is the wrap: every other candidate has been clicked through
--- to get back here. Leaving the flag set would change no state at all, and
--- openRules.Rank is deterministic over bags that have not moved -- so the
--- next scan would return this same item, and every click after it.
function openRules.Defer(itemID)
    if openRules.deferred[itemID] then
        wipe(openRules.deferred)
    end
    openRules.deferred[itemID] = true
end

function openRules.ClearDeferred()
    wipe(openRules.deferred)
end

-- What the last click acted on, while its use is still resolving. Session
-- state like openRules.deferred: nothing persists it, and a fresh login starts
-- with an empty button anyway.
local inFlight

--- Mark what a click acted on, so the scan it triggers does not repaint.
---
--- Separate from Defer even though the same click sets both: the deferral is
--- durable and outlives the round, while this lives only until the use
--- resolves.
function openRules.MarkInFlight(itemID)
    inFlight = itemID
end

function openRules.InFlightItem()
    return inFlight
end

function openRules.ClearInFlight()
    inFlight = nil
end

-- Pure: no API calls, no frame access. Cooldown and deferral state arrive as
-- candidate fields so this stays testable outside the game.
function openRules.Rank(candidates)
    sort(candidates, function(left, right)
        -- Ahead of cooldown and priority both: a deferral is the click that
        -- has already happened, and the whole point of it is that the next
        -- click reaches something else. It rejects nothing -- once every
        -- candidate is deferred the key is equal across the field, drops out of
        -- the comparison, and the ordinary order resumes, which is what puts
        -- the wrapped round back on its first item. openRules.Defer clears the
        -- field on that item's next click; ranking holds no reset of its own.
        if left.deferred ~= right.deferred then
            return not left.deferred
        end
        if left.onCooldown ~= right.onCooldown then
            return not left.onCooldown
        end
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        if left.stackCount ~= right.stackCount then
            return left.stackCount < right.stackCount
        end
        return left.itemID < right.itemID
    end)
    return candidates
end

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

-- Read through GetItemInfoInstant rather than the record's own classID, for
-- the reason model/facts.lua's isProfessionKnowledgeClass gives: it answers
-- even for an item whose full data has not cached, which is exactly the
-- record GetPartial hands back.
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
--   Gem -- a socket gem's stats are implemented as an enchant, so GetItemSpell
--     answers for one and IsUsableItem is true for every class. Using it sockets
--     into another item rather than opening anything.
local DENIED_CLASSES = {
    [Enum.ItemClass.Key]             = true,
    [Enum.ItemClass.ItemEnhancement] = true,
    [Enum.ItemClass.Gem]             = true,
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

-- The client probes the ladder below cannot own. Each is a question only the
-- control layer can answer: the locked-box tooltip line, the unlock spell,
-- and the profession names control/detector.lua's RefreshProfessions rebuilds
-- whenever the character's trade skills change -- player state no scan
-- generation invalidates, which is why model/facts.lua deliberately caches
-- neither of the last two.
--
-- Installed by control/detector.lua at file scope rather than reached for
-- through ns.control: a claimant belongs in the model, and the model calling
-- the control layer is the inversion that moving this judgement out of
-- control/detector.lua exists to avoid (plan #356). No model file in this
-- addon names a controller and this one must not be the first.
--
-- Left unset, Claim raises on the first probe it reaches -- "attempt to index
-- a nil value (upvalue 'probes')" -- and only the model.arbiter route catches
-- it, as an abstention naming this claimant. control/detector.lua's Classify
-- and control/openScanner.lua's own call have no pcall between them, so there
-- the raise propagates and the scan dies. Both are loud, which is the point:
-- a probe defaulting to "not locked, no profession known" would answer a
-- different verdict and say nothing at all.
---@type table
local probes

--- Hands the ladder the four client probes above. Called once, at file scope,
--- by control/detector.lua -- which loads after this file.
---@param installed table  IsLockedBox, CanUnlock, HasSkillRequirement and
---   RequiresKnownProfession, each with the signature it carries there
function openRules.SetProbes(installed)
    probes = installed
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
local function learnVerdict(facts, acceptedLine, data)
    if not acceptedOnPlainUse(acceptedLine) then return enum.PRIORITY.LEARN end
    if isRecipe(facts.itemID) then return enum.PRIORITY.LEARN end
    if isHousing(facts.itemID) then return enum.PRIORITY.LEARN end
    -- A met trade skill requirement makes an item knowledge only in the class
    -- pair knowledge items actually occupy. Miscellaneous/Other is that pair --
    -- it is the shape isRejectedByClass discards and the requirement exists to
    -- rescue. Plenty of other things are gated on a profession without
    -- teaching anything: a Consumable/Other skinning bait requires Khaz Algar
    -- Skinning and is a thing you use, not a thing you study, and promoting it
    -- to LEARN parked it above every genuine learnable in the bags.
    -- isRejectedByClass turns that pair away before this runs now, leaving
    -- this the second line of defence rather than the only one.
    --
    -- facts.isProfessionKnowledge is the class-pair fact alone (see
    -- model/facts.lua); the probe is the live comparison against the
    -- character's own professions, together reproducing what this branch
    -- tested as one question before the fact moved.
    if facts.isProfessionKnowledge and probes.RequiresKnownProfession(data) then
        return enum.PRIORITY.LEARN
    end
    if facts.isUnlearnedToy then return enum.PRIORITY.LEARN end
    return enum.PRIORITY.USE
end

-- The class policy an item must clear once an accept branch has matched it.
-- Both branches consult this, so an item denied here cannot reappear through
-- the other one.
local function isRejectedByClass(facts, acceptedLine, data)
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(facts.itemID))
    if DENIED_CLASSES[classID] then return true, REJECTED.DENIED_CLASS end

    local deniedSubclasses = DENIED_SUBCLASSES[classID]
    local subclassReason = deniedSubclasses and deniedSubclasses[subClassID]
    if subclassReason then return true, subclassReason end

    -- Claim resolves quest starters before this runs, so a quest item reaching
    -- here starts nothing: it is a quest objective or a leftover.
    if classID == Enum.ItemClass.Questitem then
        -- Classified by ID, so the quest check could not run. Unevaluated is not
        -- the same as rejected.
        if not facts.bagIndex then return false end
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
        if probes.RequiresKnownProfession(data) then return false end
        if facts.isUnlearnedToy then return false end
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
        and probes.HasSkillRequirement(data) then
        return true, REJECTED.PROFESSION_TOOL
    end

    return false
end

-- The tail both accept branches share. Never re-inline it: the two differ only
-- in the reason they report, and while each spelled the call out for itself the
-- fallback branch quietly stopped handing over the tooltip, leaving every rule
-- that reads a usage requirement to answer on no evidence.
local function acceptedVerdict(facts, acceptedLine, data, reason)
    if isContainer(facts.itemID) then
        return CLAIM.OPEN, enum.PRIORITY.OPEN, reason, nil, acceptedLine, false
    end

    local rejected, why = isRejectedByClass(facts, acceptedLine, data)
    if rejected then return nil, nil, why end

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
    if acceptedOnPlainUse(acceptedLine) and not C_Item.IsUsableItem(facts.itemID) then
        return nil, nil, REJECTED.UNUSABLE
    end

    return CLAIM.OPEN, learnVerdict(facts, acceptedLine, data), reason, nil,
        acceptedLine, false
end

--- Which curated-list rung Claim is being asked to skip. Named keys rather
--- than trailing booleans: the two rungs sit at opposite ends of the ladder and
--- suppressing the wrong one silently audits the wrong list, which is a
--- verdict, not an error. control/detector.lua passes this through unchanged,
--- so `Classify(bag, slot, itemID, nil, true)` would have grown a sixth
--- positional argument whose two boolean neighbours nothing distinguishes.
---
--- Never both at once: each pass asks what the rest of the ladder says about
--- one list, and the deny pass in particular needs the allow rung answering --
--- an item on both lists is surfaced by its allow entry the moment the deny
--- entry goes, which is the deny entry doing work.
---@class Dispatch.OpenRulesSuppress
---@field allowList boolean|nil
---@field denyList boolean|nil

--- What the open path wants done with one item: CLAIM.OPEN at the
--- enum.PRIORITY tier the rung that accepted it awards, or an abstention
--- naming the rung that turned it away. Registered with model.arbiter as the
--- "open" claimant; control/detector.lua's Classify is the other caller and
--- rebuilds its own tuple from the same returns.
---
--- The ladder is ordered cheapest and most authoritative first, and that
--- order is behaviour rather than tidiness -- each rung returns a reason the
--- report window prints, and facts.tooltipData is lazy precisely so an item
--- a cheap rung turns away pays for no tooltip at all:
---
---   1. What the player said -- blacklist, session skip. Nothing outranks it.
---   2. Hand-curated denials, stack gates, quest gates. Still table lookups.
---   3. Whether the item starts a quest -- it can accept, so it precedes
---      anything that might reject first.
---   4. The tooltip, fetched once and shared with the locked-box probe.
---   5. What the client states outright: locked, unusable, already known.
---      Facts beat every heuristic below.
---   6. ALLOW_LIST -- after those facts, before the heuristics it overrides.
---   7. Evidence, strongest first: hasLoot, the openable line, a typed accept
---      line, the GetItemSpell fallback. Structural signals precede text
---      ones, which are localized and depend on where the item is. Class
---      rules filter only the last two, where the evidence is weak enough to
---      need them.
---@param facts table  a model.facts record
---@param tooltipData table|nil  a tooltip the caller already has in hand, for
---   an item in no bag -- the allow-list review classifies an item link with
---   no slot behind it. model.arbiter and every production scan omit it and
---   the record's own lazy tooltipData answers instead. Taken as an argument
---   rather than written onto the record: model.facts.Get caches its records
---   for the generation, so an injected tooltip stored there would answer for
---   every later reader of that slot.
---@param suppress Dispatch.OpenRulesSuppress|nil  which of this file's two
---   curated-list rungs to skip, so a caller auditing one of them (#389) can
---   read what the rest of the ladder makes of an entry that is on the button,
---   or off it, only because it is listed. Omitted by the arbiter and by every
---   production scan, where both rungs answer.
---@return string|nil claim  enum.CLAIM.OPEN, or nil to abstain
---@return number|nil strength  the enum.PRIORITY tier the rung awarded
---@return string|nil reason  enum.REASON on a claim, enum.REJECTED on an
---   abstention; diagnostics only, and the only thing that tells two items
---   apart that reached the same verdict through different rungs
---@return boolean? overridden  true when the player's own stored `open`
---   opinion suppressed the claim
---@return any? detail  the fifth and last value model.arbiter destructures:
---   it carries this onto the claim entry, and control/openScanner.lua reads
---   it back off the verdict for the button's debug line -- the accepting line
---   type, the gating questID, or the rejecting line type.
---   control/detector.lua's Classify rebuilds its own tuple from this and the
---   two below
---@return boolean? isLocked  past the claim contract, with startsQuest
---   below: model.arbiter drops both. A locked box the character can open --
---   not the record's own isLocked, which is the transient "being moved" flag.
---   control/openScanner.lua derives this from REASON.LOCKED_BOX instead,
---   which is the only rung that reports one
---@return boolean? startsQuest  whether the client says the item offers a
---   quest, as opposed to a curated QUEST_GATED entry a quest consumes.
---   control/openScanner.lua reads the record's own field instead
function openRules.Claim(facts, tooltipData, suppress)
    local itemID = facts.itemID

    -- A record with no bag slot behind it -- control/sellScanner.lua's
    -- GatherByID, which /bfdump dispatch and /bfdump dispatch sell both
    -- resolve an itemID through with the arbiter -- carries none of
    -- model/facts.lua's LAZY fields: carriedCount, questID/questTaken/
    -- startsQuest, tooltipData, isProfessionKnowledge, isUnlearnedToy and
    -- isUncollectedAppearance are all nil rather than computed. Every rung
    -- below that reads one of them already treats nil as "no evidence" and
    -- falls through rather than condemning or claiming on it -- that is what
    -- lets this one ladder answer honestly for a carried item and a
    -- bag-less one alike, with no branch of its own for either case. Two
    -- rungs did NOT already degrade safely, and both are guarded where they
    -- read the field rather than re-explained here: the carriedCount
    -- comparison just below raised nil < number rather than reading "cannot
    -- verify", and IsLockedBox's own C_TooltipInfo call raised on a nil
    -- bag/slot rather than answering "not a lockbox". A third joined them in
    -- #378 -- the GetItemSpell fallback read a missing tooltip as proof that
    -- no line refused the item -- and is guarded the same way, at its own rung.

    -- The player's own `open` opinion is a suppressing override (spec #331
    -- section 5), so it abstains with `overridden` rather than merely
    -- returning nil: that flag is what lets a dump tell "the player said
    -- never" from "the rules had no opinion". A session skip is deliberately
    -- not one -- it reaches no field of the merged store at all, and it is
    -- revoked by a login rather than by the player.
    --
    -- `== false` rather than a truth test, and the difference is the whole
    -- feature: model.overrides.GetOpen answers nil (no opinion), false (never
    -- offer) or true (always offer), where the blacklist this replaced stored
    -- true for "never". A truthiness test here would offer precisely the
    -- items the player hid and hide nothing.
    --
    -- true falls through as though it were nil. "Always offer" would have to
    -- claim, and every rung below that could bury it is the client refusing
    -- rather than the player's opinion -- a locked box with no key, a quest
    -- already taken, a stack too short to convert -- so claiming past them
    -- would put an item on the button that clicking cannot act on.
    --
    -- No surface writes true: ctrl+right-click on the button writes false, and
    -- the blacklist window's per-row remove and Clear All write nil. Shipping
    -- an "always offer" toggle means reopening this rung in the same change,
    -- or the toggle is a silent no-op.
    if model.overrides.GetOpen(itemID) == false then
        return nil, nil, REJECTED.BLACKLIST, true
    end
    if openRules.IsSkipped(itemID) then return nil, nil, REJECTED.SESSION_SKIP end
    if enum.DENY_LIST[itemID] and not (suppress and suppress.denyList) then
        return nil, nil, REJECTED.DENY_LIST
    end

    -- Counted across the bags, not off this slot: unsorted bags split an item
    -- into partial stacks, and 3 + 3 converts as well as one stack of six.
    -- carriedCount excludes the bank, matching what the button can act on.
    -- Guarded against nil, not just against a real short stack: see this
    -- function's own opening comment for why carriedCount can be absent
    -- rather than a number, and unknown is read the same direction as
    -- every other LAZY-missing rung here -- fall through, not condemn.
    local requiredStack = enum.STACK_GATED[itemID]
    if requiredStack and facts.carriedCount and facts.carriedCount < requiredStack then
        return nil, nil, REJECTED.SHORT_STACK
    end

    -- The same family as the rung above: a fact about the world rather than
    -- about the item's class, answerable from a table, and the client will
    -- refuse the click anywhere else. Before the quest gate rather than after,
    -- and that is behaviour rather than tidiness -- the quest rung RETURNS a
    -- claim, so a zone gate below it would never run for a quest starter,
    -- which is exactly the population most likely to be place-bound.
    --
    -- No nil guard on model.zone: `zones` stands in for one. Matches degrades
    -- toward offering the item (spec #390 section 3) -- an unreadable location
    -- matches everything -- so the rung condemns only on a positive answer.
    local zones = enum.ZONE_GATED[itemID]
    if zones and not model.zone.Matches(zones) then
        return nil, nil, REJECTED.WRONG_ZONE
    end

    -- questID and startsQuest resolve as model/facts.lua's questEvidence
    -- describes. Either way the item is worth the button only while the
    -- quest can be taken, and this runs ahead of the class policy so a
    -- quest starter is not buried by a rule aimed at the junk sharing its
    -- class.
    local questID = facts.questID
    if questID then
        if facts.questTaken then
            return nil, nil, REJECTED.QUEST_TAKEN
        end
        return CLAIM.OPEN, enum.PRIORITY.QUEST, REASON.QUEST_GATE, nil,
            questID, false, facts.startsQuest
    end

    -- facts.tooltipData is lazy (model/facts.lua's own comment says why the
    -- reason differs from every other field's), so the five rungs above --
    -- blacklist, session skip, deny list, short stack, quest taken -- have
    -- cost this item no tooltip at all.
    local data = tooltipData or facts.tooltipData

    -- probes.IsLockedBox (control/detector.lua) is itself guarded against a
    -- nil bag/slot -- see its own comment for why a bag-less record (this
    -- function's own opening comment lists what else that record is missing)
    -- needed that guard, and why it lives there rather than here.
    if probes.IsLockedBox(facts.bagIndex, facts.slotIndex, data) then
        if not probes.CanUnlock() then return nil, nil, REJECTED.NO_UNLOCK end
        return CLAIM.OPEN, enum.PRIORITY.OPEN, REASON.LOCKED_BOX, nil, nil, true
    end

    -- One pass, acted on below. The first accepting line is recorded rather than
    -- a bare flag, but the walk continues: a reject line anywhere overrules it.
    local acceptedLine, opensOnRightClick
    if data and data.lines then
        for _, line in ipairs(data.lines) do
            if REJECT_LINES[line.type] then
                return nil, nil, REJECTED.REJECT_LINE, nil, line.type
            end
            if CONDITIONAL_REJECT_LINES[line.type] and not C_Item.IsUsableItem(itemID) then
                return nil, nil, REJECTED.UNUSABLE, nil, line.type
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
    -- class rules, which are the heuristics it exists to override. Hand-curated
    -- in OpenableData.lua rather than set by the player, so it is no override in
    -- the arbiter's sense and never promotes.
    --
    -- Stops applying to a Poor item (#365): grey is this family's retirement
    -- mark, so a listed item Blizzard has downgraded drops off the button on
    -- its own rather than needing an edit here. model.IsUnread guards the
    -- comparison the opposite way from every other quality read in this addon
    -- -- an unread quality must NOT withhold the item, or a client that
    -- declines to answer (a secret value in 12.0, or item data that has not
    -- loaded) would silently empty the button for every entry on it. The list
    -- exists for items known good by name, so the unread case defers to the
    -- name, not to the missing number.
    local allowed = enum.ALLOW_LIST[itemID]
    if allowed and not (suppress and suppress.allowList)
        and (model.IsUnread(facts.quality) or facts.quality ~= Enum.ItemQuality.Poor) then
        return CLAIM.OPEN, allowed, REASON.ALLOW_LIST, nil, nil, false
    end

    -- The same fact twice, structural first. hasLoot is the client's own "we can
    -- loot this" flag (ContainerFrame.lua:1494) -- typed, locale-free, and it
    -- needs no tooltip. ITEM_OPENABLE says it in text and is the weaker fallback:
    -- a localized match, present only on a bag item's tooltip.
    --
    -- Either one means openable, which outranks the class rules -- those exist
    -- because a class pair cannot tell a cache from junk, and these can.
    if facts.hasLoot then
        return CLAIM.OPEN, enum.PRIORITY.OPEN, REASON.HAS_LOOT, nil, nil, false
    end

    if opensOnRightClick then
        return CLAIM.OPEN, enum.PRIORITY.OPEN, REASON.OPENABLE_LINE, nil, nil, false
    end

    -- Ahead of acceptedVerdict rather than inside it, because both questions it
    -- would ask on the way are ones collecting an appearance does not turn on: a
    -- cosmetic weapon is class Weapon, and the client says a hunter cannot use a
    -- bow. Neither bears on whether the warband may collect it. Same standing as
    -- hasLoot above -- evidence specific enough to outrank a class heuristic.
    if facts.isUncollectedAppearance then
        return CLAIM.OPEN, enum.PRIORITY.LEARN, REASON.UNCOLLECTED_APPEARANCE,
            nil, nil, false
    end

    if acceptedLine then
        return acceptedVerdict(facts, acceptedLine, data, REASON.TOOLTIP_LINE)
    end

    -- The fallback below reads the tooltip's silence as an answer, so it needs
    -- a tooltip that actually came back. C_TooltipInfo.GetBagItem is documented
    -- MayReturnNothing, and a record with no bag slot behind it never asks at
    -- all; either way the four rungs above that read the tooltip --
    -- REJECT_LINES, CONDITIONAL_REJECT_LINES, the ITEM_OPENABLE match and
    -- IsLockedBox -- were skipped in the same breath, so a line refusing this
    -- item has not been read rather than read and found absent. Accepting on
    -- GetItemSpell alone put an item the client refuses on a click target, and
    -- sank the whole LEARN tier to USE while the tooltip was unresolved (#378).
    --
    -- Its own reason rather than NO_EVIDENCE: "the tooltip has not arrived" and
    -- "nothing accepted it" are different answers to a player asking why an
    -- item is missing. Abstaining costs nothing durable -- control/control.lua
    -- invalidates and rescans on TOOLTIP_DATA_UPDATE, which is what that
    -- handler is for. Here rather than at the `data` read above, because
    -- hasLoot, the allow list and the quest gate answer without a tooltip at
    -- all and must keep claiming.
    --
    -- An empty lines array counts as absence too, the way
    -- control/sellScanner.lua's linesContain already counts it: a genuinely
    -- loaded item tooltip carries at least its name line.
    if not (data and data.lines and #data.lines > 0) then
        return nil, nil, REJECTED.NO_TOOLTIP
    end

    -- No typed line matched at all, so by acceptedOnPlainUse's own definition
    -- this is the merely-usable case -- unless the class or the requirement
    -- says otherwise.
    if C_Item.GetItemSpell(itemID) and C_Item.IsUsableItem(itemID) then
        return acceptedVerdict(facts, nil, data, REASON.ITEM_SPELL)
    end

    return nil, nil, REJECTED.NO_EVIDENCE
end

model.openRules = openRules

-- The first of the three claimants (spec #331 section 3). model/arbiter.lua
-- loads before this file, so the registry is there to take it. After the
-- publication above, never before: Register asserts on a duplicate name, and
-- a raise here would otherwise leave ns.model.openRules nil for the rest of
-- the session -- every later IsDeferred, IsSkipped and Rank call with it.
model.arbiter.Register(openRules.CLAIMANT, openRules.Claim)

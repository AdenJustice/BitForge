---@class BitForge.Dispatch
local ns = select(2, ...)

---@class BitForge.Dispatch.Model
local model = ns.model
---@type BitForge.Dispatch.Enum
local enum = ns.enum

local CLAIM = enum.CLAIM
local REASON = enum.REASON
local REJECTED = enum.REJECTED

---@class BitForge.Dispatch.Model.AllowAudit
local allowAudit = {}

--- What one open-ladder verdict says about the ALLOW_LIST entry that produced
--- it, once model/openRules.lua has been asked with the entry's own rung
--- suppressed. Exactly one of these licenses a deletion; spec #389's
--- "Certainty is the constraint" is why the other eight do not, and widening
--- any of them is a change to that spec rather than to this file.
local BUCKET = {
    -- The ladder surfaces the item without the entry, on evidence about the
    -- item, at the rank the entry pins it to. The only deletion this pass may
    -- propose.
    REDUNDANT         = "REDUNDANT",
    -- Surfaced, but only by the GetItemSpell fallback #378 tightened, which
    -- reports what the client feels like answering rather than what the item
    -- is. Reported in a grouping of its own, never deleted.
    REDUNDANT_UNTYPED = "REDUNDANT_UNTYPED",
    -- Refused by a heuristic the entry exists to override, or surfaced at a
    -- rank the entry corrects. Either way the entry is doing work.
    LOAD_BEARING      = "LOAD_BEARING",
    -- Answered above the entry's own rung, on a fact about the item, so the
    -- entry is never consulted at all. Not "earning its place" -- doing
    -- nothing, which is a different thing to read and to act on.
    INERT             = "INERT",
    -- Surfaced, but the class policy abstained instead of judging because the
    -- record carried no bag slot, so the accept is not evidence of anything.
    UNJUDGED_CLASS    = "UNJUDGED_CLASS",
    -- Refused only for want of a fact this pass's record cannot carry.
    UNDECIDABLE       = "UNDECIDABLE",
    -- No tooltip came back, so no tooltip rung ran at all.
    UNREADABLE        = "UNREADABLE",
    -- Answered by something true of whoever ran the audit. The list ships to
    -- everyone, so nothing about the entry follows either way.
    PLAYER_STATE      = "PLAYER_STATE",
    -- A verdict this pass cannot legitimately produce. Reported as a fault in
    -- the caller, never read as a fact about the entry.
    ANOMALY           = "ANOMALY",
}

-- Two axes decide a bucket, and where both apply they are weighed in this
-- order:
--
--   1. Does the answer turn on who ran the audit? Then nothing about the entry
--      follows, whatever else is true -- PLAYER_STATE.
--   2. Does the ladder answer above the entry's own rung? Then the entry was
--      never consulted -- INERT.
--
-- REJECTED.UNUSABLE is the row that needs the order written down: it is both,
-- and PLAYER_STATE is the half a person can act on.
--
-- Axis 1 governs the deny mapping below as well, and it is the harder call
-- there: on that side a rejection is the verdict that could retire an entry,
-- so a rung answering for this character looks like evidence and is not. Only
-- axis 2 is allow-side, because the deny list has no rung of its own for the
-- ladder to answer above -- the pass suppresses it.

-- Every enum.REASON the ladder can report for an item in hand, and what seeing
-- it says about the entry. BAGLESS_ACCEPT below corrects the rows a record
-- with no bag slot cannot honestly produce.
--
-- REASON.ALLOW_LIST is deliberately absent rather than mapped to ANOMALY: the
-- fallthrough in acceptedBucket already answers that, and a row spelling it
-- out would be a line no mutation could redden. What the absence means is that
-- the pass suppresses that rung, so an accept from it says the caller did not
-- pass openRules.Claim's allowList suppression key -- and reading that as
-- redundant would propose deleting all 152 entries in one run. Any accept rung
-- added to enum.REASON later rides the same fallthrough, so it is reported
-- rather than silently read as a deletion.
local BUCKET_BY_ACCEPT = {
    -- Evidence about the item, and the same evidence for every player: a typed
    -- accepting line, the client's own "right click to open" text, and its own
    -- "this container holds loot" flag. All three return above the class
    -- policy in the ladder, so none of them depends on those rules having run.
    -- Only the first is deletable evidence on the record this pass builds --
    -- BAGLESS_ACCEPT reads the other two as faults, each for its own reason.
    [REASON.TOOLTIP_LINE]  = BUCKET.REDUNDANT,
    [REASON.OPENABLE_LINE] = BUCKET.REDUNDANT,
    [REASON.HAS_LOOT]      = BUCKET.REDUNDANT,

    [REASON.ITEM_SPELL] = BUCKET.REDUNDANT_UNTYPED,

    -- The locked-box rung answers on the tooltip's own Locked line, which
    -- needs no bag -- but which of its two exits it takes turns on
    -- probes.CanUnlock(), whether the auditing character knows Pick Lock.
    -- REJECTED.NO_UNLOCK is the other exit and carries the same bucket.
    [REASON.LOCKED_BOX] = BUCKET.PLAYER_STATE,

    -- Both surface the item for whoever ran the audit and for nobody else: the
    -- quest gate opens only while this character has not taken the quest, and
    -- the appearance rung only while this warband has not collected it.
    [REASON.QUEST_GATE]             = BUCKET.PLAYER_STATE,
    [REASON.UNCOLLECTED_APPEARANCE] = BUCKET.PLAYER_STATE,
}

-- Every enum.REJECTED the ladder can report for an item in hand.
-- BAGLESS_REJECTION below corrects the rows that change meaning without one.
local BUCKET_BY_REJECTION = {
    -- Facts about whoever ran the audit rather than about the item.
    [REJECTED.BLACKLIST]    = BUCKET.PLAYER_STATE,
    [REJECTED.SESSION_SKIP] = BUCKET.PLAYER_STATE,
    -- C_Item.IsUsableItem, asked of this character. The ladder has two UNUSABLE
    -- exits -- one in the tooltip walk, above the entry's rung, one inside
    -- acceptedVerdict below it -- so the axis order above is what settles this
    -- row rather than where it fired.
    [REJECTED.UNUSABLE]     = BUCKET.PLAYER_STATE,
    -- The locked-box rung's other exit: probes.CanUnlock(). Reachable with no
    -- bag at all, because detector.IsLockedBox reads the `data` it is handed
    -- and handing it a C_TooltipInfo.GetItemByID tooltip is this pass's whole
    -- method.
    [REJECTED.NO_UNLOCK]    = BUCKET.PLAYER_STATE,
    -- What this character is carrying, which quests they have taken, and where
    -- they were standing. All three answer above the entry's own rung, which
    -- would read as INERT -- axis 1 settles it first: the list ships to
    -- everyone and the next player's answer is not this one.
    [REJECTED.SHORT_STACK]  = BUCKET.PLAYER_STATE,
    [REJECTED.QUEST_TAKEN]  = BUCKET.PLAYER_STATE,
    [REJECTED.WRONG_ZONE]   = BUCKET.PLAYER_STATE,

    -- Refused above the entry's own rung on a fact about the item, so the
    -- ladder never reaches the entry and the entry overrides nothing.
    -- DENY_LIST says something further that only a person can settle: the same
    -- item is on both curated lists.
    [REJECTED.DENY_LIST]   = BUCKET.INERT,
    [REJECTED.REJECT_LINE] = BUCKET.INERT,

    -- The heuristics the entry exists to override -- class, subclass, or class
    -- plus the accepting line -- each below the entry's rung and each
    -- answering the same for an item nobody is carrying.
    [REJECTED.DENIED_CLASS]    = BUCKET.LOAD_BEARING,
    [REJECTED.HOLIDAY]         = BUCKET.LOAD_BEARING,
    [REJECTED.PROFESSION_TOOL] = BUCKET.LOAD_BEARING,
    [REJECTED.ON_USE_ARMOR]    = BUCKET.LOAD_BEARING,
    -- Weaker than the rest of this group and still in it: isRejectedByClass
    -- rescues an ON_USE_MISC item on facts.isUnlearnedToy, and that field is
    -- absent from this pass's record -- not because a toy needs a bag
    -- (C_ToyBox.GetToyInfo and PlayerHasToy both answer from an itemID) but
    -- because GatherByID attaches none of model/facts.lua's lazy machinery. So
    -- a bag-less run can refuse an unlearned toy a carried one would spare,
    -- which errs toward keeping the entry -- the direction spec #389 requires.
    -- The deny list weighs this same rung the other way round and must not
    -- copy the row.
    [REJECTED.ON_USE_MISC]     = BUCKET.LOAD_BEARING,
    -- The same class policy, on a quest item that starts no quest.
    [REJECTED.QUESTLESS_ITEM]  = BUCKET.LOAD_BEARING,
    -- Nothing accepted it with every bag fact in hand, which is the entry
    -- earning its place outright.
    [REJECTED.NO_EVIDENCE]     = BUCKET.LOAD_BEARING,

    [REJECTED.NO_TOOLTIP] = BUCKET.UNREADABLE,
}

-- The two ways the pass can fail to reach a verdict at all, and what each one
-- is filed as. Named here rather than in debug/allowListAudit.lua because
-- the bucket is decided here: a caller that named its own would be making a
-- bucket decision outside this file, which is the one thing spec #389 asks it
-- not to do.
--
-- Neither says anything about the item. Both say the client that ran the audit
-- had not cached what the pass asked for, which is why the report's own
-- footnote names them separately from the rungs.
local UNREAD = {
    NO_ITEM_DATA = "noItemData",
    NO_TOOLTIP   = "noTooltip",
}

-- NO_TOOLTIP reads the rejection row rather than naming UNREADABLE a second
-- time. The ladder's own NO_TOOLTIP rung answers the same absence -- a tooltip
-- that told the pass nothing -- and the two are indistinguishable in the
-- report. Written out twice, a reclassification of one would split them across
-- two buckets with nothing failing anywhere.
local BUCKET_BY_UNREAD = {
    [UNREAD.NO_ITEM_DATA] = BUCKET.UNREADABLE,
    [UNREAD.NO_TOOLTIP]   = BUCKET_BY_REJECTION[REJECTED.NO_TOOLTIP],
}

-- What the two tables above mean instead when the record has no bag slot and
-- none of model/facts.lua's lazy fields -- the audit pass's own premise. Rows
-- absent from these answer the same either way.
--
-- Only two of the seven ANOMALY rows are about the bag as such. facts.hasLoot
-- comes from the slot's own ContainerItemInfo, and isRejectedByClass tests
-- facts.bagIndex itself before reporting QUESTLESS_ITEM. Four more are absent
-- because of the constructor this pass uses: control/sellScanner.lua's
-- GatherByID returns a plain table, so carriedCount, questID and
-- isUncollectedAppearance are never computed -- yet each of them answers from
-- an itemID alone (C_Item.GetItemCount, enum.QUEST_GATED, and
-- hyperlink-or-itemID respectively). A caller that switched to
-- model.facts.GetPartial(nil, nil, itemID) -- which model/bankRules.lua
-- already uses -- would make those four rungs live again and falsify four of
-- these rows, with nothing here to catch it. That constructor is the
-- invariant, not the missing bag.
--
-- REASON.OPENABLE_LINE is the seventh and is neither. model/openRules.lua
-- matches ITEM_OPENABLE by leftText against a localized global string -- the
-- class of evidence this repo distrusts everywhere else -- and that file's own
-- comment says the line is "present only on a bag item's tooltip". This row is
-- what turns an unverifiable comment into a detectable fact: if the claim
-- holds the row never fires and costs nothing, and if it does not the pass
-- reports an anomaly instead of quietly proposing a deletion on matched text.
-- Carried, the row above stands -- there the line is the client naming this
-- item openable.
local BAGLESS_ACCEPT = {
    [REASON.OPENABLE_LINE]          = BUCKET.ANOMALY,
    [REASON.HAS_LOOT]               = BUCKET.ANOMALY,
    [REASON.QUEST_GATE]             = BUCKET.ANOMALY,
    [REASON.UNCOLLECTED_APPEARANCE] = BUCKET.ANOMALY,
}

local BAGLESS_REJECTION = {
    [REJECTED.SHORT_STACK]    = BUCKET.ANOMALY,
    [REJECTED.QUEST_TAKEN]    = BUCKET.ANOMALY,
    [REJECTED.QUESTLESS_ITEM] = BUCKET.ANOMALY,
    -- Not the entry earning its place here: the accept paths a bag-less record
    -- is missing are exactly the ones that would have answered.
    [REJECTED.NO_EVIDENCE]    = BUCKET.UNDECIDABLE,
}

-- The two accepts that reach model/openRules.lua's acceptedVerdict, which is
-- where its class policy runs. Every other accept returns above that function
-- and owes the policy nothing.
--
-- "Reach acceptedVerdict" rather than "run the policy", because the two are
-- not the same: acceptedVerdict returns PRIORITY.OPEN for a container before
-- isRejectedByClass, so one of these accepts can arrive at a verdict the
-- policy never saw. That only ever adds doubt the pairing below does not need,
-- and Enum.ItemClass.Container is not a class that abstains, so the two
-- populations are disjoint today.
local CLASS_JUDGED_ACCEPT = {
    [REASON.TOOLTIP_LINE] = true,
    [REASON.ITEM_SPELL]   = true,
}

-- Item classes whose branch of isRejectedByClass abstains -- "unevaluated is
-- not the same as rejected", in its own words -- rather than answering, when
-- the record has no bagIndex. An accept that walked past an abstention proves
-- nothing: carried, the same item is refused by the same policy. Keyed by
-- class because that is what isRejectedByClass branches on; a second class
-- given the same guard there belongs here in the same commit.
--
-- Nothing derives this from that function, so the pairing is pinned by driving
-- the real ladder instead: tests/test_dispatch_allowaudit.lua runs a bag-less
-- and a carried record through every branch of isRejectedByClass, and a guard
-- added to one of them makes that class's two verdicts disagree there. Without
-- it the failure is invisible -- an unlisted abstention reads as an ordinary
-- typed accept, lands in REDUNDANT, and deletes an entry the live ladder
-- needs.
local CLASS_ABSTAINS_BAGLESS = {
    [Enum.ItemClass.Questitem] = true,
}

--- What the caller knows that the verdict does not. Every field is about the
--- item or the record, never about the ladder's answer.
---
--- Never the model.facts record itself: a carried one carries that file's
--- recordMeta, so indexing it for a field it has not computed calls the client
--- and allowAudit.Bucket stops being pure.
---@class Dispatch.AllowAuditContext
---@field bagless boolean  the record was built from an itemID alone, with no
---   bag slot and none of model/facts.lua's lazy fields --
---   control/sellScanner.lua's GatherByID is the only constructor that makes
---   one today. The audit pass's premise, and false at the call sites that
---   classify an item the player is holding, where every rung is a legitimate
---   verdict
---@field classID number|nil  from C_Item.GetItemInfoInstant, which is what
---   isRejectedByClass branches on -- not the record's own classID field,
---   which model/facts.lua sources from GetItemInfo and which is absent for an
---   item whose full data has not cached
---@field listedPriority number|nil  enum.ALLOW_LIST[itemID], the rank the
---   entry pins the item at. nil compares unequal to every real priority, so a
---   caller that omits it is answered LOAD_BEARING rather than a deletion

--- The accept half. Ordered so a doubt about the accept is spent before any
--- claim is built on it: an accept the class policy never judged cannot
--- support a statement about the rank it was awarded.
---@param reason string|nil
---@param priority number|nil
---@param context Dispatch.AllowAuditContext
---@return string bucket
local function acceptedBucket(reason, priority, context)
    if context.bagless then
        local unreachable = BAGLESS_ACCEPT[reason]
        if unreachable then return unreachable end
    end

    local bucket = BUCKET_BY_ACCEPT[reason] or BUCKET.ANOMALY
    if bucket ~= BUCKET.REDUNDANT and bucket ~= BUCKET.REDUNDANT_UNTYPED then
        return bucket
    end

    if context.bagless and CLASS_JUDGED_ACCEPT[reason]
        and CLASS_ABSTAINS_BAGLESS[context.classID] then
        return BUCKET.UNJUDGED_CLASS
    end

    -- enum.ALLOW_LIST is not a set: its value is the priority the entry pins
    -- the item at, and the rung returns it as the claim's own. So surfacing
    -- the item is not enough -- an entry the ladder accepts at a different
    -- tier is holding a rank nothing else produces (PRIORITY.TOKEN has no
    -- other producer in this module at all), and deleting it would move the
    -- item on the button even though it still appears. The report names both
    -- numbers; the pass cannot weigh them.
    if priority ~= context.listedPriority then return BUCKET.LOAD_BEARING end

    return bucket
end

---@param reason string|nil
---@param context Dispatch.AllowAuditContext
---@return string bucket
local function rejectedBucket(reason, context)
    if context.bagless then
        local baglessBucket = BAGLESS_REJECTION[reason]
        if baglessBucket then return baglessBucket end
    end

    return BUCKET_BY_REJECTION[reason] or BUCKET.ANOMALY
end

--- Sorts one verdict from openRules.Claim into the bucket its ALLOW_LIST entry
--- belongs in. Pure: it reads nothing but its four arguments.
---@param claim string|nil  enum.CLAIM.OPEN, or nil for a rejection
---@param reason string|nil  the enum.REASON or enum.REJECTED value alongside it
---@param priority number|nil  the enum.PRIORITY tier the accepting rung awarded
---@param context Dispatch.AllowAuditContext  required, and indexed directly
---   rather than defaulted: a caller that forgets it raises here instead of
---   being answered as though the record were carried, which is the one
---   direction spec #389 says a mistake must never fall. The same choice
---   model/openRules.lua makes about its own probes, for the same reason
---@return string bucket  one allowAudit.BUCKET value
function allowAudit.Bucket(claim, reason, priority, context)
    if claim == CLAIM.OPEN then
        return acceptedBucket(reason, priority, context)
    end

    return rejectedBucket(reason, context)
end

-- enum.DENY_LIST's own mapping, and this file's whole asymmetry. That list
-- holds items the pipeline accepts but should not surface, so an entry is
-- overtaken by a REJECTION rather than by an accept -- and a record with no bag
-- slot is biased toward rejection, for exactly the reasons BAGLESS_ACCEPT above
-- is written around. So the direction that was proof for the allow list proves
-- nothing here on its own: a rejection is evidence only where the rejecting
-- rung is one a bag slot could not have changed.
--
-- Its own tables rather than a shared one keyed by list. The two disagree about
-- ON_USE_MISC, NO_EVIDENCE, UNUSABLE, NO_UNLOCK, ITEM_SPELL, LOCKED_BOX and
-- ALLOW_LIST, in both directions, and every one of those is a spec #389 row
-- rather than an accident. Sharing a table would save a dozen lines and lose
-- all seven.
--
-- Bag-less is a premise here rather than a context field: the deny pass in
-- debug/allowListAudit.lua is the only caller and builds its record from an
-- itemID alone. Carried, several rows move -- NO_EVIDENCE retires the entry
-- outright once every accept path has run -- so a carried caller needs rows
-- written for it rather than a flag flipped, and none exist to be got wrong.

-- Spec #389's "certain without a bag" rows are the whole of the deletable
-- bucket: class, subclass, a typed line, class plus the accepting line, class
-- plus a tooltip requirement. None of the five reads a field a bag slot
-- supplies, so every player's ladder reaches the same refusal and the rules
-- have caught up with the entry.
--
-- The two below them are each one fact short of that, and short of a different
-- fact -- the fact being one this pass's record could not carry, which is what
-- UNDECIDABLE means. ON_USE_MISC rescues an unlearned toy on
-- facts.isUnlearnedToy, which control/sellScanner.lua's GatherByID never
-- computes, so this refuses what a carried item is spared. NO_EVIDENCE is the
-- bag-only accept paths being absent, which are precisely the ones that would
-- have kept the entry.
--
-- BUCKET_BY_REJECTION reads both differently, and the difference is the
-- question rather than the rung: there a rejection was never going to retire an
-- entry, so it is the entry earning its place; here it was going to, and one
-- fact defeated it.
local DENY_BUCKET_BY_REJECTION = {
    [REJECTED.DENIED_CLASS]    = BUCKET.REDUNDANT,
    [REJECTED.HOLIDAY]         = BUCKET.REDUNDANT,
    [REJECTED.REJECT_LINE]     = BUCKET.REDUNDANT,
    [REJECTED.ON_USE_ARMOR]    = BUCKET.REDUNDANT,
    [REJECTED.PROFESSION_TOOL] = BUCKET.REDUNDANT,

    [REJECTED.ON_USE_MISC] = BUCKET.UNDECIDABLE,
    [REJECTED.NO_EVIDENCE] = BUCKET.UNDECIDABLE,

    -- Four rungs that answer for whoever ran the audit rather than about the
    -- item, which the axis order at the top of this file settles ahead of
    -- everything else -- and it names REJECTED.UNUSABLE as the row it was
    -- written for. C_Item.IsUsableItem and probes.CanUnlock both ask this
    -- character; the blacklist and the session skip both hid the item from
    -- this player whatever either curated list says. The record carried every
    -- fact each of them needed and each of them answered, so none is
    -- UNDECIDABLE -- what makes them useless here is that the list ships to
    -- everyone and the next player's answer is not this one.
    [REJECTED.UNUSABLE]     = BUCKET.PLAYER_STATE,
    [REJECTED.NO_UNLOCK]    = BUCKET.PLAYER_STATE,
    [REJECTED.BLACKLIST]    = BUCKET.PLAYER_STATE,
    [REJECTED.SESSION_SKIP] = BUCKET.PLAYER_STATE,
    -- And where they were standing. Not in BAGLESS_REJECTION with SHORT_STACK
    -- and QUEST_TAKEN: the zone rung reads facts.itemID and the client's own
    -- location, so a bag-less record produces it exactly as a carried one does.
    [REJECTED.WRONG_ZONE]   = BUCKET.PLAYER_STATE,

    [REJECTED.NO_TOOLTIP] = BUCKET.UNREADABLE,
}

-- Every accept says the same thing here: the ladder still surfaces the item, so
-- the entry is the only thing keeping it off the button.
--
-- REDUNDANT_UNTYPED does not cross over. It exists above because a weak accept
-- must not license a deletion; here no accept licenses one at all, and the safe
-- direction is the one an accept already argues for -- so splitting ITEM_SPELL
-- out again would be a distinction with nothing behind it.
--
-- LOCKED_BOX and ALLOW_LIST are the two rows BUCKET_BY_ACCEPT reads otherwise.
-- A locked box the auditor can pick is an accept for every player who can pick
-- one, which is the entry doing work rather than a fact about the auditor. And
-- the deny pass leaves the allow rung answering, so an item on both curated
-- lists is surfaced by its allow entry the moment the deny entry goes -- also
-- the entry doing work, and the rung named beside it in the report is what
-- tells a person the two lists are arguing over one item.
local DENY_BUCKET_BY_ACCEPT = {
    [REASON.TOOLTIP_LINE] = BUCKET.LOAD_BEARING,
    [REASON.ITEM_SPELL]   = BUCKET.LOAD_BEARING,
    [REASON.LOCKED_BOX]   = BUCKET.LOAD_BEARING,
    [REASON.ALLOW_LIST]   = BUCKET.LOAD_BEARING,
}

-- Absent from both tables on purpose, riding the fallthrough to ANOMALY the way
-- REASON.ALLOW_LIST does above and for the same reason -- a row no mutation
-- could redden is not a row:
--
--   The seven verdicts BAGLESS_ACCEPT and BAGLESS_REJECTION name as impossible
--   on this pass's record -- OPENABLE_LINE, HAS_LOOT, QUEST_GATE,
--   UNCOLLECTED_APPEARANCE, SHORT_STACK, QUEST_TAKEN, QUESTLESS_ITEM. They are
--   impossible here for the same reasons, this pass building the same record.
--
--   REJECTED.DENY_LIST, the rung under audit. Seeing it means the caller did
--   not pass openRules.Claim's denyList key, and reading it as a refusal the
--   rules reached on their own would retire all 15 entries in one run.

--- Sorts one verdict from openRules.Claim into the bucket its DENY_LIST entry
--- belongs in. Pure, and deliberately narrower than allowAudit.Bucket: the
--- bag-less record is a premise of the tables above rather than a parameter,
--- and enum.DENY_LIST pins no priority for an accept to be weighed against --
--- its values are `true`, where enum.ALLOW_LIST's are ranks.
---@param claim string|nil  enum.CLAIM.OPEN, or nil for a rejection
---@param reason string|nil  the enum.REASON or enum.REJECTED value alongside it
---@return string bucket  one allowAudit.BUCKET value
function allowAudit.DenyBucket(claim, reason)
    if claim == CLAIM.OPEN then
        return DENY_BUCKET_BY_ACCEPT[reason] or BUCKET.ANOMALY
    end

    return DENY_BUCKET_BY_REJECTION[reason] or BUCKET.ANOMALY
end

--- The bucket for an entry the pass never put a verdict to, named by what it
--- could not read. Raises on an unnamed cause for the reason allowAudit.Bucket
--- raises on a missing context: a third way of failing to read an item, filed
--- silently under the two that exist, would read as a client that answered.
---@param cause string  one allowAudit.UNREAD value
---@return string bucket
function allowAudit.UnreadBucket(cause)
    local bucket = BUCKET_BY_UNREAD[cause]
    assert(bucket, "BitForge_Dispatch/model/allowAudit.lua: no bucket for the "
        .. "unread cause " .. tostring(cause))
    return bucket
end

--- Whether a bucket licenses deleting the entry that produced it -- one
--- answer for both mappings, because the two reach REDUNDANT on opposite
--- evidence and mean the same thing by it.
---@param bucket string
---@return boolean
function allowAudit.IsDeletable(bucket)
    return bucket == BUCKET.REDUNDANT
end

allowAudit.BUCKET = BUCKET
allowAudit.UNREAD = UNREAD

model.allowAudit = allowAudit

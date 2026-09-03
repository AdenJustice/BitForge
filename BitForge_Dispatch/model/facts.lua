---@class BitForge.Dispatch
local ns = select(2, ...)

local pairs = pairs
local ipairs = ipairs
local select = select
local format = string.format
local wipe = wipe or function(target)
    for key in pairs(target) do target[key] = nil end
end

local C_Container = C_Container
local C_Item = C_Item
local C_QuestLog = C_QuestLog
local C_ToyBox = C_ToyBox
local C_TooltipInfo = C_TooltipInfo
local C_TransmogCollection = C_TransmogCollection
local PlayerHasToy = PlayerHasToy

local enum = ns.enum

---@class BitForge.Dispatch.Model
local model = ns.model

-- The evidence one bag slot carries -- itemID, quality, bind state, list
-- status, and the rest of what any consumer needs regardless of context --
-- read once here and reused for the rest of the generation.
-- control/sellScanner.lua's Gather wraps Get below thinly and keeps only what
-- is sell-specific: the IsItemDataCachedByID gate, the pending-load protocol a
-- scan drives, and supplement(), which mutates the record with class-scoped
-- lookups. model.Decide (model.lua) touches no API of its own.

-- A field that legitimately computes to nil has to be distinguishable from one
-- nobody has asked for yet. rawset(record, key, nil) stores nothing, so a cache
-- keyed on the record itself would recompute a nil field on every read -- and
-- several of these fields are MEANT to be nil: a secret value that did not
-- resolve, an item whose details have not loaded, a slot the client declined to
-- answer about. Those are exactly the reads worth doing once.
local NIL = {}

-- fieldName -> fun(record): any. A field in here is computed on first ask;
-- everything else is set when the record is built.
local LAZY = {}

local recordMeta = {
    __index = function(record, key)
        local compute = LAZY[key]
        if not compute then return nil end

        local cached = record.__computed[key]
        if cached ~= nil then
            if cached == NIL then return nil end
            return cached
        end

        local value = compute(record)
        record.__computed[key] = value == nil and NIL or value
        return value
    end,
}

-- Timewalking gear carries the difficulty it dropped at as a tooltip subtext,
-- immediately under the item name. Nothing in the item APIs reports it:
-- C_Item.GetItemInfo has no such field, and "timewalking" exists elsewhere only
-- as an instance difficulty. DifficultyUtil maps both DungeonTimewalker and
-- RaidTimewalker to this one string, so it covers dungeon and raid alike.
--
-- Matched against the constant rather than its text, the same way the disenchant
-- probe reads its two lines: one comparison covers all eleven locales and
-- survives Blizzard rewording it.
--
-- Chromie Time levelling gear is deliberately NOT caught by this. It carries no
-- difficulty subtext, so it is judged on item level like any other past
-- expansion piece -- which is the right answer anyway, since it scales into the
-- current band and therefore competes on level without needing the exemption.
local function isTimewalkingSlot(inventorySlotID)
    local data = C_TooltipInfo.GetInventoryItem("player", inventorySlotID)
    if not data or not data.lines then return false end
    for _, line in ipairs(data.lines) do
        if line.leftText == PLAYER_DIFFICULTY_TIMEWALKER then return true end
    end
    return false
end

--- The items equipped in the slots this equip location could fill, or nil when
--- the location names none. Depends only on equipLoc -- what the game
--- currently has equipped, not anything about the candidate's own bag slot --
--- so this is shared verbatim by sellScanner.GatherByID (through
--- facts.EquippedItems below), which has no bag slot to ask about at all.
---
--- Lazy for the reason the sell-only note below gives, and the most expensive
--- of that set by some way: isTimewalkingSlot is a live tooltip scan, once per
--- equipped slot the location maps to (at most two). Eager, that would be paid
--- by every piece of gear a scan reaches regardless of whether anything
--- downstream ever asks -- and most of what a scan walks is not equippable at
--- all, while the rest is routinely excluded before any rule reads this.
---@param equipLoc string
---@return table|nil
local function equippedItems(equipLoc)
    local slots = enum.SLOT_LOOKUP[equipLoc]
    if not slots then return nil end

    local items = {}
    for _, slotID in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotID)
        if equippedLink then
            local equippedLevel = C_Item.GetDetailedItemLevelInfo(equippedLink)
            local equippedInfo = { C_Item.GetItemInfo(equippedLink) }
            local equippedQuality = equippedInfo[3]
            local equippedExpac = equippedInfo[15]
            if equippedLevel and equippedQuality then
                items[#items + 1] = {
                    level         = equippedLevel,
                    quality       = equippedQuality,
                    expacID       = equippedExpac or 0,
                    isTimewalking = isTimewalkingSlot(slotID),
                }
            else
                -- Something occupies the slot but its item data has not arrived
                -- yet (right after login, or a /reload at a vendor) -- unlike a
                -- slot that genuinely holds nothing, this is not permission to
                -- sell. A sentinel keeps it in the list rather than silently
                -- dropping it, so model.CompareToEquipped can treat it as
                -- inconclusive instead of letting the candidate fall through to
                -- the equipment terminal unopposed.
                items[#items + 1] = { unreadable = true }
            end
        end
    end
    return items
end

--- Items bought and still inside their refund window must not be sold: doing so
--- turns a full refund into vendor gold. Mirrors Blizzard's own test in
--- Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua.
---
--- Lazy: sell-only (nothing in the open or bank paths reads it), and the
--- open path is now the record's hottest consumer -- it runs on every
--- BAG_UPDATE_DELAYED, not just a merchant visit, so an eager
--- GetContainerItemPurchaseInfo call here would be paid for every occupied
--- slot on every bag change whether or not a merchant is even open.
---
--- Stale for as long as the record it is on survives regardless of eager or
--- lazy, which is why it was accepted as eager to begin with: refundSeconds
--- counts down in real time, and nothing in BitForge.Events fires when it
--- reaches zero, so there is no cheap way to invalidate on the clock and
--- building a timer for one field is not worth the machinery. A record lives
--- from one invalidation to the next -- a bag change, a lock change, an
--- equipment change, a level-up, or an edit to the blacklist/whitelist/temp
--- lists -- which in practice is frequent but has no upper bound. The stale
--- direction is the safe one: refundSeconds only counts down, so a cached
--- true can only outlive the real window, never predate it, and Decide's
--- step 3 already reads a true here as KEEP -- the failure mode is an item
--- that could now be sold staying in the bags a little longer, not one still
--- refundable reaching the vendor.
local function isRefundable(bagIndex, slotIndex)
    local info = C_Container.GetContainerItemPurchaseInfo(bagIndex, slotIndex, false)
    if not info or not info.refundSeconds then return false end
    return (info.itemCount or 0) > 0
        or (info.money or 0) > 0
        or (info.currencyCount or 0) > 0
end

--- Whether this item binds to the account rather than to one character.
---
--- C_Item.IsItemBindToAccount is the authority -- it is what Blizzard's own UI
--- reads for isWarbandItem, and it answers for warband, Battle.net account and
--- the until-equipped variant without the caller knowing their numbers. The
--- bindType fallback stands in only where there is no item to ask about, which
--- is why enum.BIND_TYPE_ACCOUNT exists at all.
---
--- IsItemBindToAccount is SecretArguments = "AllowedWhenUntainted" and can
--- decline to answer, the same as C_Item.IsBound in Get below. Returned
--- unwrapped, not `== true`: a decline must reach facts.isBindOnAccount as nil,
--- or the gear ladder's `facts.isBindOnAccount == nil` guard folds an unread
--- answer into "not account bound" and condemns gear on evidence that never
--- arrived. The bindType fallback below is not this kind of call -- it is a
--- plain table lookup on an already-resolved number, never a secret, so it
--- stays a definite boolean.
---@param itemInfo string|number|nil  item link or ID
---@param bindType number|nil
---@return boolean|nil
local function isBindOnAccount(itemInfo, bindType)
    if itemInfo then return C_Item.IsItemBindToAccount(itemInfo) end
    return enum.BIND_TYPE_ACCOUNT[bindType] == true
end

LAZY.equippedItems = function(record)
    return equippedItems(record.equipLoc)
end

-- Sell-path fields, all lazy for the same reason: the open path is the
-- record's hottest consumer (it runs on every BAG_UPDATE_DELAYED, not just a
-- merchant visit), and nothing downstream of an eager field here can be
-- skipped once the call has already been paid.
--
-- "Sell-only" is what these were, and no longer: model.arbiter puts the sell
-- claimant in front of the open path too, so every one of them is read for a
-- slot the open claimant claims -- and isCosmetic is read for every slot that
-- reaches supplement(), claimed or not. control/openScanner.lua's gate is what
-- keeps that to the claimed slots rather than the whole bag, and it only
-- works because these are lazy: making one eager would put its call back on
-- every slot of every bag update, where no gate can reach it.
--
-- A lazy field's overhead is one table lookup; an eager field's cost
-- here is a client call -- or, for the O(1) local lookups among them
-- (inEquipmentSet, isProhibited/isEnforced, isTempExcluded/isTempIncluded,
-- isCharOverride, reagentProfessions), the closure/cache indirection is no
-- worse than the lookup itself, and still saves paying it at all for an
-- open-only scan.

-- itemLink is set by Get and not by GetPartial, so the two fields that hand it
-- to a client call -- level here and isCosmetic below -- fall back to
-- record.itemID. Both take ItemInfo (an ID, a link or a name) with the argument
-- documented Nilable = false (ItemDocumentation.lua), so a nil link raises
-- rather than abstaining, and the ID names the kind of item, which is all a
-- record with no copy behind it has to offer. The same fallback
-- isUncollectedAppearance and sellScanner.GatherByID already use, and a no-op
-- on a Get record, which never has a nil link.
--
-- The rest of the fields reading a Get-only key need no guard: equippedItems
-- degrades through SLOT_LOOKUP[nil], isBindOnAccount has its own itemInfo
-- branch, and isTempExcluded/isTempIncluded are plain Lua table reads, which
-- tolerate a nil key.
LAZY.level = function(record)
    return C_Item.GetDetailedItemLevelInfo(record.itemLink or record.itemID) or 0
end

LAZY.isBindOnAccount = function(record)
    return isBindOnAccount(record.itemLink, record.bindType)
end

--- Whether THIS instance is bound, which bindType cannot answer: a looted
--- BoE is not bound, the same BoE once equipped is. Ladder step 4 asks the
--- second question. A secret value that did not resolve stays nil, so the
--- ladder abstains rather than condemning.
---
--- Guarded on bagIndex like inEquipmentSet and isRefundable below, but to
--- nil rather than false, and that difference is the whole answer:
--- sellScanner.GatherByID leaves this one nil on purpose for an item with no
--- slot, because no by-ID call can say whether a particular copy is bound and
--- the ladder must abstain rather than guess. Reaching the client with an
--- empty ItemLocation would be asking it about no copy at all.
LAZY.isBound = function(record)
    if not record.bagIndex then return nil end
    return C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(record.bagIndex, record.slotIndex))
end

--- Deliberately unwrapped, unlike isCraftingReagent: the result is Nilable
--- and the call is SecretArguments = "AllowedWhenUntainted", so a decline
--- has to arrive as nil. Coercing it with == true would read "could not
--- tell" as "not cosmetic", which is exactly the direction that sells an
--- appearance (#32).
---
--- Falls back to record.itemID for a link-less record, for the reason
--- LAZY.level's own note above gives.
LAZY.isCosmetic = function(record)
    return C_Item.IsCosmeticItem(record.itemLink or record.itemID)
end

--- Which professions want this as a reagent, or nil for an item the
--- catalogue has no entry for. Read by both the sell path and the bank
--- path -- BitForge:GetReagentProfessions(itemID) is the one question
--- either ever asks the catalogue.
LAZY.reagentProfessions = function(record)
    return BitForge:GetReagentProfessions(record.itemID)
end

-- Bank-only field, lazy whatever it costs: the bank path only runs with a
-- bank window open, so an eager client call here would be paid on every bag
-- change -- unlike the fields the open path itself needs -- for a question
-- nothing outside a bank session ever asks.

--- The spell a recipe item casts, or nil for an item that is not one. Return
--- 2 of 2 (ItemDocumentation.lua). Whether this is the recipe's own spellID or
--- a separate teaching spell is the design (#55) 5.6 unknown;
--- bankRules.WantedByAlt is where that ambiguity is resolved and reported, not
--- here.
LAZY.recipeSpellID = function(record)
    return select(2, C_Item.GetItemSpell(record.itemID))
end

-- Guarded on bagIndex, the same way tooltipData and questEvidence are: both
-- ask about a particular COPY, and a record built with no bag slot behind it
-- names a kind of item instead. false rather than nil is what
-- sellScanner.GatherByID already reports for such an item -- the answer the
-- hard gates would reach for an unencumbered copy -- so the two entry points
-- agree rather than one of them raising. Unguarded, format() rejected the nil
-- and GetContainerItemPurchaseInfo was called with one.
LAZY.inEquipmentSet = function(record)
    if not record.bagIndex then return false end
    return model.IsInEquipmentSet(format("%d:%d", record.bagIndex, record.slotIndex))
end

LAZY.isRefundable = function(record)
    if not record.bagIndex then return false end
    return isRefundable(record.bagIndex, record.slotIndex)
end

-- The sell opinion is the only one of the three with two scopes, and
-- model/overrides.lua has no opinion about how they compose -- it is pure
-- data, and the policy belongs to whichever claimant reads the field (its own
-- file comment says so). The two functions below are that policy, and they
-- live here because both entry points that build these three fields are here
-- or reach through here: the lazy fields, and control/sellScanner.lua's
-- GatherByID for an item with no bag slot, which takes them off facts the way
-- it already takes EquippedItems and IsBindOnAccount. Two compositions of one
-- store is precisely the disagreement plan #368 exists to end.
local CHAR, GLOBAL = enum.LIST_SCOPE.CHAR, enum.LIST_SCOPE.GLOBAL

--- The sell status that actually governs this item for this character.
--- Character scope wins outright whichever way it points -- a character
--- whitelist beats a warband blacklist just as a character blacklist beats a
--- warband whitelist -- and warband applies only where the character has no
--- entry. Which scope answered is deliberately not reported: model/arbiter.lua
--- records that as the reason the arbiter cannot do this tie-break itself, and
--- model.overrides.GetSell is what a caller that needs the scope asks instead.
---@param itemID number
---@return string|nil  enum.LIST_STATUS value, or nil when neither scope holds one
local function effectiveSell(itemID)
    return model.overrides.GetSell(itemID, CHAR)
        or model.overrides.GetSell(itemID, GLOBAL)
end

--- True only when BOTH scopes hold a status and they disagree. A character
--- entry that merely agrees with the warband one is not an override: the
--- merchant panel marks these rows so an item reaching the sell list despite a
--- warband blacklist is pointed at before the player presses Sell, and a row
--- marked for agreeing would point at nothing.
---@param itemID number
---@return boolean
local function hasCharSellOverride(itemID)
    local charStatus = model.overrides.GetSell(itemID, CHAR)
    if not charStatus then return false end
    local globalStatus = model.overrides.GetSell(itemID, GLOBAL)
    return globalStatus ~= nil and globalStatus ~= charStatus
end

-- isProhibited and isEnforced each compose the scopes independently rather
-- than sharing one computed listStatus, unlike when both were eager:
-- effectiveSell is two table lookups, and neither rung asking is common
-- enough that paying it twice for one item outweighs the record no longer
-- computing both unconditionally for every item.
LAZY.isProhibited = function(record)
    return effectiveSell(record.itemID) == enum.LIST_STATUS.BLACKLIST
end

LAZY.isEnforced = function(record)
    return effectiveSell(record.itemID) == enum.LIST_STATUS.WHITELIST
end

LAZY.isTempExcluded = function(record)
    return model.IsTempExcluded(record.itemLink)
end

LAZY.isTempIncluded = function(record)
    return model.IsTempIncluded(record.itemLink)
end

--- Read by the merchant panel only; model.Decide never consults it.
LAZY.isCharOverride = function(record)
    return hasCharSellOverride(record.itemID)
end

--- Which quest this item is tied to, and whether the client itself is
--- naming it. Two sources, the client winning: GetContainerItemQuestInfo
--- names the quest an item starts whatever its class; QUEST_GATED covers
--- items a quest consumes instead, which no API reports. Only the client's
--- own answer means the item *offers* a quest -- a QUEST_GATED entry earns
--- the same priority and none of the exclamation mark startsQuest drives.
---@param bagIndex number|nil
---@param slotIndex number|nil
---@param itemID number
---@return number|nil questID
---@return boolean startsQuest
local function questEvidence(bagIndex, slotIndex, itemID)
    local questInfo = bagIndex and C_Container.GetContainerItemQuestInfo(bagIndex, slotIndex)
    local questID = (questInfo and questInfo.questID) or enum.QUEST_GATED[itemID]
    local startsQuest = questInfo ~= nil and questInfo.questID ~= nil
    return questID, startsQuest
end

--- Whether questID is already in the log or has already been turned in.
---@param questID number
---@return boolean
local function questAlreadyTaken(questID)
    return C_QuestLog.IsOnQuest(questID) or C_QuestLog.IsQuestFlaggedCompleted(questID)
end

--- How many of this item the player carries across all bags. Excludes the
--- bank, matching what the open button can act on.
---@param itemID number
---@return number
local function carriedCount(itemID)
    return C_Item.GetItemCount(itemID)
end

--- A toy the player has not added to the toy box yet.
---
--- Typed rather than read off the tooltip: a toy states itself on a plain
--- unnumbered line, locale text, and never the line that accepted the item
--- in the first place. Learned is the other half of the question -- an item
--- still in the bags after the toy is collected has nothing left to give.
---@param itemID number
---@return boolean
local function isUnlearnedToy(itemID)
    if C_ToyBox.GetToyInfo(itemID) == nil then return false end
    return not PlayerHasToy(itemID)
end

--- A cosmetic item whose appearance the warband has not collected.
---
--- Two flags rather than the tooltip: Enum.TooltipDataLineType carries
--- members for transmog sets and illusions, none for a single appearance --
--- the item states what it does on an untyped line no pipeline can tell
--- from any other prose. hyperlink is the slot's own raw bag link, not the
--- record's resolved itemLink: an appearance is modified-appearance keyed
--- and the bonusIDs a bare itemID drops are what pick the right one. Both
--- calls may decline to answer (SecretArguments = "AllowedWhenUntainted"),
--- and each declined answer falls out as false -- the direction that leaves
--- the item alone.
---@param hyperlink string|nil
---@param itemID number
---@return boolean
local function isUncollectedAppearance(hyperlink, itemID)
    local itemInfo = hyperlink or itemID
    if not C_Item.IsCosmeticItem(itemInfo) then return false end
    local _, modifiedAppearanceID = C_TransmogCollection.GetItemInfo(itemInfo)
    if not modifiedAppearanceID then return false end
    return not C_TransmogCollection
        .PlayerHasTransmogItemModifiedAppearance(modifiedAppearanceID)
end

--- Whether this item occupies the class pair profession knowledge lives in
--- (Miscellaneous/Other) -- a fact about its identity, not whether its
--- trade skill requirement is met. Read through GetItemInfoInstant rather
--- than the record's own GetItemInfo-sourced classID/subclassID: it answers
--- even for an item whose full data has not cached, the same reason
--- model/openRules.lua's other class checks (isContainer, isRecipe,
--- isHousing) read it instead of the record. The requirement match itself
--- stays a live comparison in control/detector.lua's requiresKnownProfession,
--- which reads the profession names detector.RefreshProfessions rebuilds --
--- player state nothing here invalidates on. Caching the full predicate
--- would let a rescan triggered by SKILL_LINES_CHANGED, which does not turn
--- this generation over, answer with the profession state from before the
--- change.
---@param itemID number
---@return boolean
local function isProfessionKnowledgeClass(itemID)
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))
    return classID == Enum.ItemClass.Miscellaneous
        and subClassID == Enum.ItemMiscellaneousSubclass.Other
end

--- The tooltip a bag slot carries. Lazy for a reason none of the other
--- twenty-one share: here laziness preserves an ORDER, not just a cost.
--- model/openRules.lua's ladder rejects a blacklisted, session-skipped,
--- denied, short-stacked or quest-taken item before it ever asks for this,
--- and where the read sits in that ladder is part of the behaviour -- an item
--- a cheap gate turns away must still pay for no tooltip at all. Every other
--- lazy field here is deferred to save the call; this one is deferred to keep
--- the rung it belongs to.
---
--- Guarded on bagIndex for the same reason questEvidence is: a record built
--- for an itemID with no bag slot behind it has no tooltip to fetch, and this
--- is the read openRules.Claim reaches for whenever its caller supplied none
--- of its own.
LAZY.tooltipData = function(record)
    return record.bagIndex and C_TooltipInfo.GetBagItem(record.bagIndex, record.slotIndex)
end

--- questID and startsQuest are one client call (questEvidence), not two:
--- whichever of the pair is asked first computes both and memoises the
--- other directly into __computed, the same NIL-wrapping recordMeta's own
--- __index uses, so the second ask finds its answer already cached instead
--- of paying for GetContainerItemQuestInfo again. Classify reads both
--- together on every quest-gated item, which is exactly the case this
--- guards against paying for twice.
LAZY.questID = function(record)
    local questID, startsQuest = questEvidence(record.bagIndex, record.slotIndex, record.itemID)
    record.__computed.startsQuest = startsQuest == nil and NIL or startsQuest
    return questID
end

LAZY.startsQuest = function(record)
    local questID, startsQuest = questEvidence(record.bagIndex, record.slotIndex, record.itemID)
    record.__computed.questID = questID == nil and NIL or questID
    return startsQuest
end

--- Only meaningful once questID exists, which is why this is lazy rather
--- than eager: most scanned items are not quest-gated at all.
LAZY.questTaken = function(record)
    local questID = record.questID
    return questID ~= nil and questAlreadyTaken(questID)
end

LAZY.carriedCount = function(record)
    return carriedCount(record.itemID)
end

LAZY.isUnlearnedToy = function(record)
    return isUnlearnedToy(record.itemID)
end

LAZY.isUncollectedAppearance = function(record)
    return isUncollectedAppearance(record.hyperlink, record.itemID)
end

LAZY.isProfessionKnowledge = function(record)
    return isProfessionKnowledgeClass(record.itemID)
end

--- The shared skeleton every record gets, resolved or not: identity
--- (bagIndex/slotIndex/itemID/hyperlink) plus the structural facts
--- slotInfo already carries for free (hasLoot/isLocked/stackCount), with
--- the LAZY table's metatable attached so every lazy field -- tooltipData,
--- questID/startsQuest/questTaken, carriedCount, isUnlearnedToy,
--- isUncollectedAppearance, isProfessionKnowledge, and every sell-only or
--- bank-only field besides -- computes identically regardless of which
--- entry point below built the record.
---
--- slotInfo may be nil (a bag=nil classification, an item link resolved
--- outside any bag), in which case bagIndex, slotIndex and hyperlink stay nil
--- too -- and GetPartial sets no itemLink whatever slotInfo it got. That is
--- what "identically" above has to survive, and it did not until five fields
--- were guarded. Each now answers what sellScanner.GatherByID reports for an
--- item with no slot behind it: tooltipData nil, questID from the curated
--- table alone with startsQuest false, inEquipmentSet and isRefundable false,
--- isBound nil, and level and isCosmetic read off the itemID rather than the
--- link. tests/test_dispatch_facts.lua drives every LAZY field against a
--- GetPartial record to keep the claim honest -- it reads the field names out
--- of this file rather than listing them, so a new lazy field is covered
--- without anyone remembering to add it.
---@param bagIndex number|nil
---@param slotIndex number|nil
---@param itemID number
---@param slotInfo table|nil  C_Container.GetContainerItemInfo's return
---@return table
local function buildRecord(bagIndex, slotIndex, itemID, slotInfo)
    return setmetatable({
        __computed = {},

        bagIndex   = bagIndex,
        slotIndex  = slotIndex,
        itemID     = itemID,
        -- The slot's own raw bag link -- see isUncollectedAppearance's own
        -- comment for why the open path needs this one specifically, not
        -- Get's own resolved itemLink below.
        hyperlink  = slotInfo and slotInfo.hyperlink,
        -- Free where slotInfo exists: the caller already made this exact
        -- call. See control/detector.lua's own rung for what the flag means.
        hasLoot    = slotInfo ~= nil and slotInfo.hasLoot == true,
        isLocked   = slotInfo ~= nil and slotInfo.isLocked == true,
        stackCount = (slotInfo and slotInfo.stackCount) or 1,
    }, recordMeta)
end

local generation = 0
local records = {}

-- Walk's own return, cached the same way records are: a second consumer
-- asking in the same generation -- the sell path after the open path, say --
-- gets this same array back rather than a second pass over every bag.
-- walkedGeneration starts below any real generation (which is never
-- negative) so the very first Walk, before anything has invalidated, still
-- performs its one pass. Deliberately the only cross-call cache in this
-- file: Get caches by resolved record, keyed on bag:slot, and GetPartial
-- caches nothing at all (its own comment says why), but neither remembers a
-- bare container read on its own, because a bag:slot
-- pair reused for an unrelated ask later in the same generation -- a
-- /bfdump command, a dropped-item lookup -- must see the container as it
-- stands right now, not an answer some earlier, unrelated ask happened to
-- leave behind. Get and Gather instead take the read as a parameter when a
-- Walk-driven caller already has it in hand, which is what lets the shared
-- walk save the second read without keeping a cache that could go stale
-- under an unrelated caller.
local walked = {}
local walkedGeneration = -1

---@class BitForge.Dispatch.Model.Facts
local facts = {}

--- The current generation number. Advanced only by Invalidate.
---@return number
function facts.Generation()
    return generation
end

--- Turns the generation over and drops every cached record. Nothing already
--- handed out is mutated by this -- a caller still holding an earlier record
--- (the sell manifest, an open report) keeps a valid table; only a later Get
--- for that slot is affected.
function facts.Invalidate()
    generation = generation + 1
    wipe(records)
    wipe(walked)
end

local function keyFor(bagIndex, slotIndex)
    return format("%d:%d", bagIndex, slotIndex)
end

--- One pass over the carried bags -- enum.BAG_INDICES, the same set of six
--- containers the open path's own BACKPACK_CONTAINER..NUM_TOTAL_EQUIPPED_BAG_SLOTS
--- range and the sell path's own copy of it each name (openScanner.lua,
--- sellScanner.lua) -- producing { bagIndex, slotIndex, itemID, slotInfo }
--- for every occupied slot, bag then slot ascending. slotInfo is
--- C_Container.GetContainerItemInfo's own return, so a caller that needs
--- isLocked, hasLoot, hyperlink or stackCount without a resolved record reads
--- it here rather than asking the container again -- and a caller that goes
--- on to resolve a full record hands this same table to Get (or Gather) as
--- its own knownSlotInfo, which is what lets a slot Walk has already read
--- skip a second container call.
---
--- The one place GetContainerNumSlots and GetContainerItemInfo are called for
--- the whole bag range in a generation, with two exceptions: a second consumer
--- asking in the same generation gets this same array back rather than a
--- second pass over every bag.
---
--- The exceptions are both on-demand and both say so themselves.
--- debug/dumps.lua's FindInBags, which /bfdump dispatch open <id> uses to turn
--- an itemID into a bag:slot, wants a live read of where the item is right
--- now, before any record is built, and stops at the first match rather than
--- covering the range. control/inventory.lua's explicit-list branch reads
--- whatever containers it is handed, and with the bank closed
--- inventory.GetCurationContainers hands it exactly enum.BAG_INDICES -- see
--- that branch's own comment for why the curation window pays the duplicate
--- read rather than special-casing it. control.ScanDisenchant is the /bfdump
--- diagnostic that used to be a third and no longer is; it reads these
--- entries like everything else.
---
--- A slot whose item data has not resolved yet is still listed here -- Walk
--- never calls C_Item.GetItemInfo -- which is what lets a consumer request its
--- load; Get is what retries resolution against it on every ask, whether or
--- not the resolution arrived with a generation of its own (see Get's own
--- comment for when ITEM_DATA_LOAD_RESULT turns one over and when it does
--- not).
---@return table[]
function facts.Walk()
    if walkedGeneration == generation then return walked end

    wipe(walked)
    for _, bagIndex in ipairs(enum.BAG_INDICES) do
        local numSlots = C_Container.GetContainerNumSlots(bagIndex)
        for slotIndex = 1, numSlots do
            local slotInfo = C_Container.GetContainerItemInfo(bagIndex, slotIndex)
            if slotInfo and slotInfo.itemID then
                walked[#walked + 1] = {
                    bagIndex  = bagIndex,
                    slotIndex = slotIndex,
                    itemID    = slotInfo.itemID,
                    slotInfo  = slotInfo,
                }
            end
        end
    end
    walkedGeneration = generation
    return walked
end

--- The items equipped in the slots equipLoc could fill. Exposed so
--- sellScanner.GatherByID -- which has no bag slot to key a cached record by,
--- and so cannot go through Get -- reads the same answer Get's lazy field
--- would give it, rather than a second copy of this function.
---@param equipLoc string
---@return table|nil
function facts.EquippedItems(equipLoc)
    return equippedItems(equipLoc)
end

--- Whether an item binds to the account rather than to one character. Exposed
--- for the same reason as EquippedItems above.
---@param itemInfo string|number|nil  item link or ID
---@param bindType number|nil
---@return boolean|nil
function facts.IsBindOnAccount(itemInfo, bindType)
    return isBindOnAccount(itemInfo, bindType)
end

--- The sell status governing one item, and whether the character scope is
--- actively overriding the warband one. Exposed for the same reason as
--- EquippedItems above: sellScanner.GatherByID sets isProhibited, isEnforced
--- and isCharOverride on a record it builds itself, and has to compose the two
--- scopes exactly as the lazy fields do rather than a second time of its own.
---@param itemID number
---@return string|nil  enum.LIST_STATUS value, or nil when neither scope holds one
function facts.EffectiveSell(itemID)
    return effectiveSell(itemID)
end

---@param itemID number
---@return boolean
function facts.HasCharSellOverride(itemID)
    return hasCharSellOverride(itemID)
end

--- The record for one bag slot in the current generation, built on first ask
--- and reused for the rest of it. nil for an empty slot, and nil for an item
--- whose details have not loaded -- IsItemDataCachedByID reports on the base
--- item, so it can pass while this specific hyperlink's GetItemInfo still
--- returns nothing. Get does not distinguish the two, and requests a load for
--- neither: the pending-load protocol belongs to sellScanner.Gather, which
--- checks IsItemDataCachedByID itself before ever calling here.
---
--- Never caches an unresolved attempt -- the record built when GetItemInfo
--- fails is thrown away rather than stored under key, so the next Get for
--- this slot retries resolution from scratch instead of replaying the same
--- failure. A slot's record is only ever cached once it has fully resolved,
--- so there is never a stale unresolved RECORD for ITEM_DATA_LOAD_RESULT to
--- invalidate. GetPartial below relies on this too -- it never writes to this
--- cache, so it can never leave the name-less record a resolved Get would
--- have to see through.
---
--- That is a property of the record and not of the fields on it, and reading
--- it as both cost a regression. equippedItems is a lazy field on records
--- that DID resolve, and what it reads is what the character is wearing: a
--- /reload at a vendor caches { unreadable = true } for every gear candidate,
--- and a rescan trusting this property read the sentinel straight back. So
--- control.lua's sell-side ITEM_DATA_LOAD_RESULT handler does invalidate,
--- while the open-side one beside it does not -- none of the fields the open
--- path reads is answered by the item-data cache this event reports on.
---@param bagIndex number
---@param slotIndex number
---@param knownSlotInfo table|nil  C_Container.GetContainerItemInfo's own
---   return for this slot, when a caller already has it (facts.Walk's own
---   entries) -- taken instead of read again, which is what lets a
---   Walk-driven caller share one container read across Get rather than
---   asking the container a second time for a slot Walk has already
---   covered. A caller with no such read in hand omits this and Get reads
---   the container itself, exactly as it always has.
---@return table|nil
function facts.Get(bagIndex, slotIndex, knownSlotInfo)
    local key = keyFor(bagIndex, slotIndex)
    local cached = records[key]
    if cached then return cached end

    local slotInfo = knownSlotInfo or C_Container.GetContainerItemInfo(bagIndex, slotIndex)
    if not slotInfo or not slotInfo.itemID then return nil end

    local name, itemLink, quality, _, _, _, _, _, equipLoc, _, sellPrice,
    classID, subclassID, bindType, expacID, _, isCraftingReagent =
        C_Item.GetItemInfo(slotInfo.hyperlink)
    if not name then return nil end

    local record = buildRecord(bagIndex, slotIndex, slotInfo.itemID, slotInfo)
    record.itemLink           = itemLink or slotInfo.hyperlink
    record.name               = name
    record.quality            = quality
    record.sellPrice          = sellPrice or 0
    record.equipLoc           = equipLoc
    record.classID            = classID
    record.subclassID         = subclassID
    record.bindType           = bindType
    record.expacID            = expacID or 0
    record.isCraftingReagent  = isCraftingReagent == true

    records[key] = record
    return record
end

--- The record for one item with no resolved Get record behind it -- an item
--- whose data has not cached yet (Get's own gate above failed), or a
--- bag=nil classification (an item link resolved outside any bag; bagIndex
--- and slotIndex may then be nil too). Built by the same buildRecord every
--- Get record is, so every field the open path reads -- tooltipData,
--- questID, startsQuest, questTaken, carriedCount, isUnlearnedToy,
--- isUncollectedAppearance, isProfessionKnowledge -- computes on first ask
--- here exactly as it would off a cached Get record, rather than the whole
--- set paying for itself the moment a record exists regardless of what the
--- ladder actually reaches.
---
--- Deliberately uncached, for the reason Get's own comment gives: nothing
--- here is known to be resolved, and caching an unresolved attempt under
--- the same key a later, now-resolved Get checks would let that Get see a
--- name-less table instead of retrying resolution.
---@param bagIndex number|nil
---@param slotIndex number|nil
---@param itemID number
---@return table
function facts.GetPartial(bagIndex, slotIndex, itemID)
    local slotInfo = bagIndex and C_Container.GetContainerItemInfo(bagIndex, slotIndex)
    return buildRecord(bagIndex, slotIndex, itemID, slotInfo)
end

model.facts = facts

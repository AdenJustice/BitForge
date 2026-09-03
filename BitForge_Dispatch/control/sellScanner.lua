---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs
local wipe = table.wipe

local C_Container = C_Container
local C_HousingCatalog = C_HousingCatalog
local C_Item = C_Item
local C_MountJournal = C_MountJournal
local C_TooltipInfo = C_TooltipInfo
local C_TransmogCollection = C_TransmogCollection

local enum = ns.enum
local model = ns.model
local view = ns.view

---@class BitForge.Dispatch.Control
local control = ns.control

-- The record's own fields -- itemID, quality, bind state, list status, and the
-- rest every consumer needs regardless of context -- belong to model.facts.
-- What stays here is sell-specific: the pending-load protocol a scan drives,
-- and supplement()'s class-scoped lookups, which Gather and GatherByID share.
-- Every client read the sell path needs happens here, which is what keeps
-- model.Decide touching no API of its own.

---@class BitForge.Dispatch.Control.SellScanner
local sellScanner = {}

-- A reuse cache keyed by "itemID:marker" -- not a claim that these answers
-- cannot change while it stands. A recipe or a pet can be learned at any
-- moment, so this saves N copies of one recipe from costing N tooltip reads
-- instead of one; it is not a guarantee the next read would still agree.
--
-- Cleared on MERCHANT_SHOW and MERCHANT_CLOSED, so nothing survives a visit
-- boundary -- but it is FILLED away from a vendor too, and by more than the
-- debug tooltip it was written for: control/openScanner.lua's gate reaches
-- supplement() for every slot the open claimant claims, on every bag update,
-- with no merchant in sight. So the window it spans is the whole gap between
-- visits rather than one visit, which is where its one visible edge lives:
-- learning one of two copies of a recipe away from a vendor leaves the other
-- copy's verdict on the pre-learn answer until the next boundary clears this,
-- for an item the player never hovered.
--
-- Only the two tooltip lookups go through this; they are the only expensive
-- reads here.
local visitMemo = {}

function sellScanner.ClearVisitMemo() wipe(visitMemo) end

--- Whether already-fetched tooltip data carries a line equal to `marker`.
--- nil when the tooltip has not arrived, which is unknown, not false. An empty
--- lines array is not evidence either: a tooltip whose data has not finished
--- loading looks exactly like one the client had nothing to append, and a
--- genuinely loaded item tooltip always carries at least its name line.
---@return boolean|nil
local function linesContain(data, marker)
    if not data or not data.lines or #data.lines == 0 then return nil end
    for _, line in ipairs(data.lines) do
        if line.leftText == marker then return true end
    end
    return false
end

--- Whether a tooltip for this item carries a line equal to `marker`, read from
--- a bag slot. nil when the tooltip has not arrived, which is unknown, not
--- false. Not memoized when unresolved, for the same reason linesContain
--- returns nil rather than false for it: nil here means "ask again," not "the
--- marker is absent."
---@return boolean|nil
local function tooltipSays(bagIndex, slotIndex, itemID, marker)
    local memoKey = itemID .. ":" .. marker
    local cached = visitMemo[memoKey]
    if cached ~= nil then return cached end

    local found = linesContain(C_TooltipInfo.GetBagItem(bagIndex, slotIndex), marker)
    if found == nil then return nil end
    visitMemo[memoKey] = found
    return found
end

--- The same fact, read from the item's ID alone rather than a bag slot -- used
--- by GatherByID, which has no slot to ask. Shares visitMemo with tooltipSays:
--- the cache key is already "itemID:marker" with no slot in it, so the two
--- agree on the same item within one visit rather than each keeping a private
--- answer.
---@return boolean|nil
local function tooltipSaysByID(itemID, marker)
    local memoKey = itemID .. ":" .. marker
    local cached = visitMemo[memoKey]
    if cached ~= nil then return cached end

    local found = linesContain(C_TooltipInfo.GetItemByID(itemID), marker)
    if found == nil then return nil end
    visitMemo[memoKey] = found
    return found
end

-- Named MISC_SUBCLASS in rules.lua too. One set of numbers, one name, so the
-- two files cannot drift apart.
local MISC_SUBCLASS = {
    REAGENT = 1,
    PET = 2,
    HOLIDAY = 3,
    OTHER = 4,
    MOUNT = 5,
    MOUNT_EQUIPMENT = 6
}

local HOUSING_SUBCLASS = { DECOR = 0 }

--- The facts only some classes need. Gathered per class rather than for every
--- slot: a weapon has no reason to pay for a pet journal lookup.
---
--- readTooltip is the one lookup that needs a bag slot at all -- everything
--- else here is already answerable from the item's ID and link alone, which is
--- why sellScanner.Gather and sellScanner.GatherByID can share this whole
--- function and differ only in what they pass for it.
---@param facts table
---@param readTooltip fun(itemID: number, marker: string): boolean|nil
local function supplement(facts, readTooltip)
    local classID, sub = facts.classID, facts.subclassID

    -- Outside the class chain below, and that is the whole of #32: cosmetic is
    -- not a class or a subclass. Both items in the report are filed under real
    -- weapon classes and both answer IsCosmeticItem true, so a lookup scoped to
    -- Armor's Cosmetic (5) never ran for them, appearanceCollected stayed nil,
    -- and an uncollected appearance was sold. There is no cosmetic weapon
    -- subclass to widen the gate to -- the item's own flag is the only thing
    -- that answers.
    if facts.isCosmetic then
        local _, modifiedAppearanceID = C_TransmogCollection.GetItemInfo(facts.itemLink)
        if modifiedAppearanceID then
            local hasAppearance =
                C_TransmogCollection.PlayerHasTransmogItemModifiedAppearance
            facts.appearanceCollected = hasAppearance(modifiedAppearanceID)
        end
    end

    if classID == Enum.ItemClass.Miscellaneous then
        if sub == MISC_SUBCLASS.MOUNT then
            local mountID = C_MountJournal.GetMountFromItem(facts.itemID)
            if mountID then
                facts.mountCollected = select(11, C_MountJournal.GetMountInfoByID(mountID))
            end
        elseif sub == MISC_SUBCLASS.PET then
            facts.petCollected = readTooltip(facts.itemID, ITEM_PET_KNOWN)
        end

        -- Left nil for anything that is not a toy, which makes "is it a toy"
        -- and "is it collected" one question rather than two.
        if C_ToyBox.GetToyInfo(facts.itemID) then
            facts.toyCollected = PlayerHasToy(facts.itemID) and true or false
        end
    elseif classID == Enum.ItemClass.Recipe then
        facts.recipeKnown = readTooltip(facts.itemID, ITEM_SPELL_KNOWN)

        -- nil for a subclass RECIPE_SUBCLASS_PROFESSION has no entry for
        -- (Book, 0), which is what the criterion abstains on: a generic
        -- pattern belongs to no one profession, so there is nothing to judge
        -- the recipe against.
        facts.recipeProfession = enum.RECIPE_SUBCLASS_PROFESSION[sub]
    elseif classID == Enum.ItemClass.Housing then
        if sub == HOUSING_SUBCLASS.DECOR then
            local info = C_HousingCatalog.GetCatalogEntryInfoByItem(facts.itemLink)
            if info then
                facts.decorCollected = (info.totalNumStored or 0) > 0
                    or (info.totalNumPlaced or 0) > 0
                    or (info.remainingRedeemable or 0) > 0
            end
        end
    end
end

--- The record for this slot, or nil for an empty one and nil for an item
--- whose details have not loaded.
---
--- The record is model.facts.Get's job now; this keeps only what Get's
--- table|nil contract cannot carry -- which of those two nils happened. An
--- empty slot and IsItemDataCachedByID failing are both ruled out here,
--- before Get is even called, because the second one needs a pending ID
--- registered and Get has nowhere to hand one back. Once both pass, any nil
--- Get still returns is a third case by elimination: IsItemDataCachedByID
--- reports on the base item, so it can pass while this specific hyperlink's
--- GetItemInfo -- inside Get -- still returns nothing.
---
--- Deliberately no pending ID for that third case. Requesting a load would
--- resolve immediately, clear the pending entry, rescan, and land right back
--- here — an unbounded loop for as long as the merchant is open.
---
--- Does not invalidate. The generation turns over on the events that mean a
--- record could be wrong -- BAG_UPDATE_DELAYED, ITEM_LOCK_CHANGED,
--- EQUIPMENT_SETS_CHANGED -- in control.lua, once per event rather than once
--- per slot, so a scan of a hundred slots shares one generation instead of
--- each Gather call discarding the record the slot before it just built.
---@param bagIndex number
---@param slotIndex number
---@param knownSlotInfo table|nil  C_Container.GetContainerItemInfo's own
---   return for this slot, when the caller already has it (sellScanner.Scan
---   walks model.facts.Walk's own entries and hands this straight through) --
---   taken instead of read again, and passed on to model.facts.Get the same
---   way. A caller with no such read in hand omits this and Gather reads the
---   container itself, exactly as it always has.
---@return table|nil facts
---@return number|nil pendingItemID
function sellScanner.Gather(bagIndex, slotIndex, knownSlotInfo)
    local slotInfo = knownSlotInfo or C_Container.GetContainerItemInfo(bagIndex, slotIndex)
    if not slotInfo or not slotInfo.itemID then return nil, nil end

    if not C_Item.IsItemDataCachedByID(slotInfo.itemID) then
        return nil, slotInfo.itemID
    end

    local facts = model.facts.Get(bagIndex, slotIndex, slotInfo)
    if not facts then return nil, nil end

    supplement(facts, function(itemID, marker)
        return tooltipSays(bagIndex, slotIndex, itemID, marker)
    end)
    return facts
end

-- One entry per distinct gather failure, so a broken slot is reported once
-- rather than once per slot per bag update. Keyed on the message for the
-- reason model/arbiter.lua's printedFailures is: a claimant, or a client call
-- under it, is not one bug.
local reportedGatherFailures = {}

--- sellScanner.Gather, guarded, for the three scan paths that walk every slot.
---
--- supplement() reaches five client APIs that take an item link -- the
--- transmog, mount, toy, housing and tooltip lookups -- and 12.0's secret
--- values give each of them a way to refuse. A raise in there used to cost the
--- sell manifest, and only while a merchant was open. All three paths gather
--- now, so an unguarded one would take the openables button and the bank plan
--- down with it on every BAG_UPDATE_DELAYED: the button would freeze on a
--- stale item and deposit.BuildPlan would stop returning a plan at all.
---
--- That is the outcome model/arbiter.lua's per-claimant pcall exists to
--- prevent -- "an exception in one module leaves the other two working" -- and
--- this call sits just outside it, so the promise has to be kept here instead.
--- The slot is skipped and the failure reported, which is how sellScanner.Scan
--- already treats an item whose decision throws.
---@return table|nil facts
---@return number|nil pendingItemID
function sellScanner.SafeGather(bagIndex, slotIndex, knownSlotInfo)
    local ok, facts, pendingItemID = pcall(sellScanner.Gather, bagIndex, slotIndex, knownSlotInfo)
    if ok then return facts, pendingItemID end

    local cause = tostring(facts)
    if not reportedGatherFailures[cause] then
        reportedGatherFailures[cause] = true
        CallErrorHandler(facts)
    end
    return nil, nil
end

--- Re-reads the mutable fields before selling. Returns false when the slot no
--- longer holds the same item.
---@return boolean
function sellScanner.Refresh(facts)
    local slotInfo = C_Container.GetContainerItemInfo(facts.bagIndex, facts.slotIndex)
    if not slotInfo or slotInfo.itemID ~= facts.itemID then return false end
    facts.isLocked = slotInfo.isLocked == true
    facts.stackCount = slotInfo.stackCount or 1
    return true
end

-- Items whose data had not arrived when the scan reached them. Asking the server
-- and rescanning when it answers is what keeps a just-logged-in manifest from
-- silently omitting items, which returning nil alone did.
local pendingItems = {}

--- @param itemID number
function sellScanner.RequestLoad(itemID)
    if pendingItems[itemID] then return end
    pendingItems[itemID] = true
    C_Item.RequestLoadItemDataByID(itemID)
end

--- @param itemID number
--- @return boolean  true when this item was awaited
function sellScanner.ResolveLoad(itemID)
    if not pendingItems[itemID] then return false end
    pendingItems[itemID] = nil
    return true
end

--- Rebuilds the manifest from the bags and refreshes the merchant panel.
---
--- Walks model.facts.Walk's shared entries rather than the bags directly, so
--- a scan run in the same generation as the open path or a bank snapshot
--- reuses their container read instead of taking a second one.
function sellScanner.Scan()
    local items = {}

    for _, entry in ipairs(model.facts.Walk()) do
        local facts, pendingItemID =
            sellScanner.SafeGather(entry.bagIndex, entry.slotIndex, entry.slotInfo)
        if facts then
            -- The manifest is what the arbiter awarded SELL, not what
            -- model.Decide alone would: an item the open path wants opened or
            -- the bank path wants deposited is claimed by them first, and this
            -- is where a player stops seeing a cache, a wanted reagent or a
            -- recipe an alt still needs offered for sale. Resolve memoises per
            -- record, so a slot the open path already resolved this generation
            -- costs no second pass over the claimants.
            --
            -- One item's resolution throwing must not cost the rest of the
            -- bags their scan. Resolve already guards each claimant with its
            -- own pcall, so this covers only the arbitration around them --
            -- but the whole manifest going blank over one bad item is a worse
            -- failure than that one item being silently skipped and reported.
            local ok, verdict = pcall(model.arbiter.Resolve, facts)
            if ok then
                if verdict.disposition == enum.CLAIM.SELL then
                    items[#items + 1] = facts
                end
            else
                CallErrorHandler(verdict)
            end
        elseif pendingItemID then
            sellScanner.RequestLoad(pendingItemID)
        end
    end

    model.SetManifest(items)
    view.merchantPanel.Refresh()
end

--- One item's facts from its ID alone, with no bag slot behind it, or nil when
--- the client has not cached the item yet.
---
--- Everything else the class criteria read is answerable from an ID: the
--- equipped items in the slots this one could fill -- which is the half of the
--- comparison a bag-only gather loses the moment the item leaves the bags --
--- and the same collection-state facts supplement() gathers for a bag slot
--- (mount, pet, transmog, housing and recipe state), read here from the
--- item's ID and link instead of a tooltip pinned to a slot.
---
--- isBound is the one fact genuinely out of reach: whether THIS copy is bound
--- is a property of a specific instance, not of the item, and no by-ID call
--- can answer it. It is left nil, which the class criteria read as unknown
--- rather than unbound -- so a piece already condemned or kept on its own
--- merits (an upgrade, or a stale bar it beats) still reports that verdict,
--- but a piece the ladder would only sell after asking whether it is bound
--- abstains instead of guessing, and reaches the global KEEP.
---
--- The bag-slot fields have no answer here either: whether this copy is
--- locked, in an equipment set, or inside its refund window are all questions
--- about a particular copy, and an ID names a kind of item rather than a copy.
--- Each is reported false rather than guessed, which is the same answer the
--- hard gates would reach for an unencumbered item.
---@param itemID number
---@return table|nil facts
function sellScanner.GatherByID(itemID)
    if not C_Item.IsItemDataCachedByID(itemID) then
        C_Item.RequestLoadItemDataByID(itemID)
        return nil
    end

    local name, itemLink, quality, _, _, _, _, _, equipLoc, _, sellPrice,
    classID, subclassID, bindType, expacID, _, isCraftingReagent = C_Item.GetItemInfo(itemID)
    if not name then return nil end

    local listStatus = model.facts.EffectiveSell(itemID)

    local facts = {
        itemID             = itemID,
        itemLink           = itemLink,
        name               = name,
        quality            = quality,
        sellPrice          = sellPrice or 0,
        stackCount         = 1,
        level              = C_Item.GetDetailedItemLevelInfo(itemLink) or 0,
        equipLoc           = equipLoc,
        classID            = classID,
        subclassID         = subclassID,
        bindType           = bindType,
        isBindOnAccount    = model.facts.IsBindOnAccount(itemLink or itemID, bindType),
        expacID            = expacID or 0,
        isCraftingReagent  = isCraftingReagent == true,
        -- Unwrapped, for the reason model.facts.Get's own copy gives.
        isCosmetic         = C_Item.IsCosmeticItem(itemLink or itemID),
        reagentProfessions = BitForge:GetReagentProfessions(itemID),

        isLocked           = false,
        inEquipmentSet     = false,
        isRefundable       = false,
        equippedItems      = model.facts.EquippedItems(equipLoc),

        isProhibited       = listStatus == enum.LIST_STATUS.BLACKLIST,
        isEnforced         = listStatus == enum.LIST_STATUS.WHITELIST,
        isTempExcluded     = model.IsTempExcluded(itemLink),
        isTempIncluded     = model.IsTempIncluded(itemLink),
        isCharOverride     = model.facts.HasCharSellOverride(itemID),
    }
    supplement(facts, tooltipSaysByID)
    return facts
end

--- The full decision one slot would receive: the facts, the settings they were
--- judged against, the verdict, and the rule that produced it.
---
--- Deliberately re-decides rather than reading the manifest back. The manifest
--- holds only the items that decided SELL and keeps no rule, so it can answer
--- neither "why was this kept" nor "which step decided". Re-deciding also means
--- the answer is current with the lists and settings as they stand now, not as
--- they stood at the last scan, and stays available away from a merchant.
---
--- One gather per call. The item tooltip calls this only when it has
--- something to render -- the player-facing verdict while the merchant is
--- open, the debug block while the module's debug flag is set -- and skips it
--- entirely when neither applies, rather than gathering for nothing on every
--- bag item a player hovers away from a vendor.
---
--- Follows model.arbiter.Resolve rather than model.Decide, because what this
--- renders is a player-facing "will be sold / will be kept" line beside the
--- item, and the manifest stopped being model.Decide's answer the moment the
--- open and bank paths could outrank it. Deciding here on its own put both
--- answers on one screen: the manifest row correctly omitting a cache, and
--- this tooltip on that same row saying it would be sold.
---
--- `rule` still comes from the sell claimant alone, and it is still always an
--- enum.RULE -- model/rules.lua's Claim returns model.Decide's rule whether it
--- claims or abstains -- because that is the key the tooltip's reason line and
--- the dump both look up. A raise inside it is the one case with no rule to
--- report, and it reads as the global default: the claimant abstained, so
--- nothing claimed the item, which is what RULE.DEFAULT already says.
---
--- `claimedBy` is the disposition that beat the sell path, or nil when nothing
--- did. Without it the reason line contradicts its own heading -- "will be
--- kept" over "No box keeps this, so it is sold" -- because the rule that
--- decided is no longer the rule this claimant answered with.
---@return table|nil report  { facts, settings, verdict, rule, claimedBy }, or
---                          nil when the slot is empty or its item data has
---                          not arrived
local function explain(facts)
    if not facts then return nil end

    local settings = model.GetSettingsSnapshot()
    local awarded = model.arbiter.Resolve(facts)
    local sellClaim = model.arbiter.Claim(facts, model.rules.CLAIMANT)

    local isSell = awarded.disposition == enum.CLAIM.SELL
    return {
        facts     = facts,
        settings  = settings,
        verdict   = isSell and enum.DECISION.SELL or enum.DECISION.KEEP,
        rule      = sellClaim.failed and enum.RULE.DEFAULT or sellClaim.reason,
        claimedBy = (not isSell and awarded.disposition ~= enum.CLAIM.KEEP)
            and awarded.disposition or nil,
    }
end

--- "current with the lists and settings as they stand now" (see explain's own
--- doc above) is a promise model.facts' cache does not keep on its own:
--- editing the blacklist, the whitelist, or a character override changes
--- nothing a bag/lock/equipment event fires for, so a cached record would
--- keep answering with the list status it had when it was built. Explain is
--- the one caller with that promise to keep, so it is the one place that
--- forces a fresh record rather than waiting for the generation to turn over.
--- Scan does not do this: it wants exactly the opposite, one generation
--- shared across the slots one walk builds.
function sellScanner.Explain(bagIndex, slotIndex)
    model.facts.Invalidate()
    return explain(sellScanner.Gather(bagIndex, slotIndex))
end

--- The same report for an item that need not be in the bags at all.
---@param itemID number
---@return table|nil
function sellScanner.ExplainByID(itemID)
    return explain(sellScanner.GatherByID(itemID))
end

control.sellScanner = sellScanner

---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local huge = math.huge
local format = string.format
local concat = table.concat
local wipe = table.wipe

local ClearCursor = ClearCursor
local GetCursorInfo = GetCursorInfo
local SpellCanTargetItem = SpellCanTargetItem
local SpellCanTargetItemID = SpellCanTargetItemID
local SpellIsTargeting = SpellIsTargeting

local C_Container = C_Container
local C_EquipmentSet = C_EquipmentSet
local C_HousingCatalog = C_HousingCatalog
local C_Item = C_Item
local C_MerchantFrame = C_MerchantFrame
local C_MountJournal = C_MountJournal
local C_SpellBook = C_SpellBook
local C_TooltipInfo = C_TooltipInfo
local C_TradeSkillUI = C_TradeSkillUI
local C_TransmogCollection = C_TransmogCollection

local enum = ns.enum
local model = ns.model
local view = ns.view
local locale = ns.locale
local events = BitForge.Events

---@class BitForge.BatchSell.Control
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

local merchantOpen = false

-- The only code that reads item state from the game. It produces plain fact
-- tables; model.Decide consumes them and never touches an API. Anything that
-- needs only data — class equippability, disenchantability, expansion age —
-- lives in the model, not here.

local scanner = {}

-- Timewalking gear carries the difficulty it dropped at as a tooltip subtext,
-- immediately under the item name. Nothing in the item APIs reports it:
-- C_Item.GetItemInfo has no such field, and "timewalking" exists elsewhere only
-- as an instance difficulty. DifficultyUtil maps both DungeonTimewalker and
-- RaidTimewalker to this one string, so it covers dungeon and raid alike.
--
-- Matched against the constant rather than its text, the same way the disenchant
-- probe below reads its two lines: one comparison covers all eleven locales and
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
--- decline to answer, the same as C_Item.IsBound below. Returned unwrapped, not
--- `== true`: a decline must reach facts.isBindOnAccount as nil, or the gear
--- ladder's `facts.isBindOnAccount == nil` guard folds an unread answer into
--- "not account bound" and condemns gear on evidence that never arrived. The
--- bindType fallback below is not this kind of call -- it is a plain table
--- lookup on an already-resolved number, never a secret, so it stays a
--- definite boolean.
---
--- Gathered here rather than derived inside Decide, which makes no API calls.
---@param itemInfo string|number|nil  item link or ID
---@param bindType number|nil
---@return boolean|nil
local function isBindOnAccount(itemInfo, bindType)
    if itemInfo then return C_Item.IsItemBindToAccount(itemInfo) end
    return enum.BIND_TYPE_ACCOUNT[bindType] == true
end

-- A per-visit reuse cache, keyed by "itemID:marker" -- not a claim that these
-- answers cannot change while a vendor is open. A recipe or a pet can be
-- learned mid-visit, so this only saves five copies of one recipe from
-- costing five tooltip reads instead of one; it is not a guarantee the sixth
-- read within the same visit would still agree. Cleared on both MERCHANT_SHOW
-- and MERCHANT_CLOSED, so a stale answer never survives past the visit that
-- produced it -- view.lua's debug tooltip can call scanner.Explain, and
-- therefore this, while no vendor is open at all. Only the two tooltip
-- lookups go through this -- they are the only expensive reads here.
local visitMemo = {}

function scanner.ClearVisitMemo() wipe(visitMemo) end

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
--- why scanner.Gather and scanner.GatherByID can share this whole function and
--- differ only in what they pass for it.
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

function scanner.Gather(bagIndex, slotIndex)
    local slotInfo = C_Container.GetContainerItemInfo(bagIndex, slotIndex)
    if not slotInfo or not slotInfo.itemID then return nil, nil end

    if not C_Item.IsItemDataCachedByID(slotInfo.itemID) then
        return nil, slotInfo.itemID
    end

    local hyperlink = slotInfo.hyperlink
    local name, itemLink, quality, _, _, _, _, _, equipLoc, _, sellPrice,
    classID, subclassID, bindType, expacID, _, isCraftingReagent = C_Item.GetItemInfo(hyperlink)
    -- Deliberately no pending ID here. IsItemDataCachedByID reports on the base
    -- item, so it can succeed while GetItemInfo on this specific hyperlink does
    -- not; requesting a load would resolve immediately, clear the pending entry,
    -- rescan, and land right back here — an unbounded loop for as long as the
    -- merchant is open.
    if not name then return nil, nil end

    local resolvedLink = itemLink or hyperlink
    local listStatus = model.GetEffectiveStatus(slotInfo.itemID)

    local facts = {
        bagIndex           = bagIndex,
        slotIndex          = slotIndex,
        itemID             = slotInfo.itemID,
        itemLink           = resolvedLink,
        name               = name,
        quality            = quality,
        sellPrice          = sellPrice or 0,
        stackCount         = slotInfo.stackCount or 1,
        level              = C_Item.GetDetailedItemLevelInfo(resolvedLink) or 0,
        equipLoc           = equipLoc,
        classID            = classID,
        subclassID         = subclassID,
        bindType           = bindType,
        isBindOnAccount    = isBindOnAccount(resolvedLink, bindType),
        -- Whether THIS instance is bound, which bindType cannot answer: a
        -- looted BoE is not bound, the same BoE once equipped is. Ladder step 4
        -- asks the second question. A secret value that did not resolve stays
        -- nil, so the ladder abstains rather than condemning.
        isBound            = C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bagIndex, slotIndex)),
        expacID            = expacID or 0,
        isCraftingReagent  = isCraftingReagent == true,
        -- Deliberately unwrapped, unlike isCraftingReagent above: the result is
        -- Nilable and the call is SecretArguments = "AllowedWhenUntainted", so
        -- a decline has to arrive as nil. Coercing it with == true would read
        -- "could not tell" as "not cosmetic", which is exactly the direction
        -- that sells an appearance (#32).
        isCosmetic         = C_Item.IsCosmeticItem(resolvedLink),
        -- Which professions want this as a reagent, or nil for an item the
        -- catalogue has no entry for. Gathered here because model.Decide makes
        -- no API calls and cannot ask core itself.
        reagentProfessions = BitForge:GetReagentProfessions(slotInfo.itemID),

        isLocked           = slotInfo.isLocked == true,
        inEquipmentSet     = model.IsInEquipmentSet(format("%d:%d", bagIndex, slotIndex)),
        isRefundable       = isRefundable(bagIndex, slotIndex),
        equippedItems      = equippedItems(equipLoc),

        isProhibited       = listStatus == enum.LIST_STATUS.BLACKLIST,
        isEnforced         = listStatus == enum.LIST_STATUS.WHITELIST,
        isTempExcluded     = model.IsTempExcluded(resolvedLink),
        isTempIncluded     = model.IsTempIncluded(resolvedLink),

        -- Read by the merchant panel only; model.Decide never consults it.
        isCharOverride     = model.HasCharOverride(slotInfo.itemID),
    }
    supplement(facts, function(itemID, marker)
        return tooltipSays(bagIndex, slotIndex, itemID, marker)
    end)
    return facts
end

--- Re-reads the mutable fields before selling. Returns false when the slot no
--- longer holds the same item.
---@return boolean
function scanner.Refresh(facts)
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
function scanner.RequestLoad(itemID)
    if pendingItems[itemID] then return end
    pendingItems[itemID] = true
    C_Item.RequestLoadItemDataByID(itemID)
end

--- @param itemID number
--- @return boolean  true when this item was awaited
function scanner.ResolveLoad(itemID)
    if not pendingItems[itemID] then return false end
    pendingItems[itemID] = nil
    return true
end

--- Rebuilds the manifest from the bags and refreshes the merchant panel.
function scanner.Scan()
    local settings = model.GetSettingsSnapshot()
    local items = {}

    -- BACKPACK_CONTAINER..NUM_TOTAL_EQUIPPED_BAG_SLOTS includes the reagent bag.
    for bagIndex = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bagIndex)
        for slotIndex = 1, numSlots do
            local facts, pendingItemID = scanner.Gather(bagIndex, slotIndex)
            if facts then
                -- One item's decision throwing must not cost the rest of the
                -- bags their scan -- model.Decide is pure and should never
                -- raise, but "should never" is not a guarantee an unforeseen
                -- fact shape cannot break, and the whole manifest going blank
                -- over one bad item is a worse failure than that one item
                -- being silently skipped and reported.
                local ok, verdict = pcall(model.Decide, facts, settings)
                if ok then
                    if verdict == enum.DECISION.SELL then
                        items[#items + 1] = facts
                    end
                else
                    CallErrorHandler(verdict)
                end
            elseif pendingItemID then
                scanner.RequestLoad(pendingItemID)
            end
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
function scanner.GatherByID(itemID)
    if not C_Item.IsItemDataCachedByID(itemID) then
        C_Item.RequestLoadItemDataByID(itemID)
        return nil
    end

    local name, itemLink, quality, _, _, _, _, _, equipLoc, _, sellPrice,
    classID, subclassID, bindType, expacID, _, isCraftingReagent = C_Item.GetItemInfo(itemID)
    if not name then return nil end

    local listStatus = model.GetEffectiveStatus(itemID)

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
        isBindOnAccount    = isBindOnAccount(itemLink or itemID, bindType),
        expacID            = expacID or 0,
        isCraftingReagent  = isCraftingReagent == true,
        -- Unwrapped, for the reason scanner.Gather's own copy gives.
        isCosmetic         = C_Item.IsCosmeticItem(itemLink or itemID),
        reagentProfessions = BitForge:GetReagentProfessions(itemID),

        isLocked           = false,
        inEquipmentSet     = false,
        isRefundable       = false,
        equippedItems      = equippedItems(equipLoc),

        isProhibited       = listStatus == enum.LIST_STATUS.BLACKLIST,
        isEnforced         = listStatus == enum.LIST_STATUS.WHITELIST,
        isTempExcluded     = model.IsTempExcluded(itemLink),
        isTempIncluded     = model.IsTempIncluded(itemLink),
        isCharOverride     = model.HasCharOverride(itemID),
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
---@return table|nil report  { facts, settings, verdict, rule }, or nil when the
---                          slot is empty or its item data has not arrived
local function explain(facts)
    if not facts then return nil end

    local settings = model.GetSettingsSnapshot()
    local verdict, rule = model.Decide(facts, settings)
    return {
        facts    = facts,
        settings = settings,
        verdict  = verdict,
        rule     = rule,
    }
end

function scanner.Explain(bagIndex, slotIndex)
    return explain(scanner.Gather(bagIndex, slotIndex))
end

--- The same report for an item that need not be in the bags at all.
---@param itemID number
---@return table|nil
function scanner.ExplainByID(itemID)
    return explain(scanner.GatherByID(itemID))
end

control.scanner = scanner

local seller = {}

--- Vendors the manifest, up to the merchant's per-batch limit when enabled.
function seller.SellBatch()
    local manifest = model.GetManifest()
    local limit = model.GetLimitBatchTo12() and 12 or huge
    local count = 0

    for _, facts in ipairs(manifest) do
        if count >= limit then break end
        if scanner.Refresh(facts) and not facts.isLocked then
            C_Container.UseContainerItem(facts.bagIndex, facts.slotIndex)
            count = count + 1
        end
    end
end

control.seller = seller

-- Dragging a bag item onto the manifest includes it in this merchant visit's
-- sale, overriding rules that merely did not select it. The item never moves:
-- the cursor is cleared immediately, before anything else can fail, so the
-- item always lands back in the slot it came from and a refusal never
-- strands it on the cursor.

--- Accepts an item dropped onto the manifest.
---
--- Matches the cursor's item to a bag slot primarily by itemID -- a
--- hyperlink read off the cursor may be a secret value and is not guaranteed
--- to compare equal to the container's own hyperlink for the same item --
--- but prefers a candidate whose own hyperlink equals the cursor's link when
--- one is found, falling back to the first itemID match otherwise. Without
--- that preference, two bag slots sharing an itemID with different links
--- (different bonus IDs, two upgrade tracks of the same piece) could
--- force-sell the wrong variant: AddTempInclude is link-keyed, and Gather
--- recomputes isTempIncluded per slot from its own resolved link.
---
--- Everything below keys on facts.itemLink -- the value Gather actually
--- produced for the matched slot -- rather than the cursor's own link, for
--- the same secret-value reason.
---
--- model.CanTempInclude is checked before anything is mutated. It is
--- deliberately silent about a temporary exclusion, so an item that is both
--- excluded and blacklisted keeps its exclusion rather than losing it to a
--- drop that gets refused anyway.
function control.AcceptManifestDrop()
    local cursorType, cursorItemID, cursorItemLink = GetCursorInfo()
    if cursorType ~= "item" then return end
    ClearCursor()

    local bagIndex, slotIndex
    local fallbackBag, fallbackSlot
    for candidateBag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(candidateBag)
        for candidateSlot = 1, numSlots do
            local slotInfo = C_Container.GetContainerItemInfo(candidateBag, candidateSlot)
            if slotInfo and slotInfo.itemID == cursorItemID then
                if cursorItemLink and slotInfo.hyperlink == cursorItemLink then
                    bagIndex, slotIndex = candidateBag, candidateSlot
                    break
                elseif not fallbackBag then
                    fallbackBag, fallbackSlot = candidateBag, candidateSlot
                end
            end
        end
        if bagIndex then break end
    end
    bagIndex = bagIndex or fallbackBag
    slotIndex = slotIndex or fallbackSlot
    if not bagIndex then return end

    local facts, pendingItemID = scanner.Gather(bagIndex, slotIndex)
    if not facts then
        -- Item data has not arrived yet. scanner.Scan handles the same
        -- signal by requesting the load; a silent no-op here would leave the
        -- drop unexplained on a slot that would resolve moments later.
        if pendingItemID then scanner.RequestLoad(pendingItemID) end
        return
    end
    local itemLink = facts.itemLink

    local blockingRule = model.CanTempInclude(facts)
    if blockingRule then
        BitForge:Print(format(locale["msg:dropRefused"], itemLink, locale["reason:" .. blockingRule]))
        return
    end

    if model.IsTempExcluded(itemLink) then
        model.RemoveTempExclude(itemLink)
        BitForge:Print(format(locale["msg:dropUnexcluded"], itemLink))
    end

    model.AddTempInclude(itemLink)
    scanner.Scan()
end

-- Disenchantability is inferred everywhere else in this module -- uncommon or
-- better, armour or a weapon, absent from a crawled table of exceptions. The
-- client knows the real answer and will say so, but only about the item under
-- the cursor while a spell that targets items is pending: that is the tooltip
-- line, and the grey wash over bag slots that cannot take the spell.
--
-- No addon can create that state. Casting is protected, so the probe cannot ask
-- the question on its own; it can only be in the room when the player asks it.
-- So it listens, and when the player puts Disenchant on the cursor it reads the
-- answer for every item they are carrying at that instant and files it. The
-- cost to the player is nothing, and coverage grows over the items they
-- actually handle -- which are the ones a wrong verdict would have cost them.
--
-- The pending spell is never identified, and does not need to be. The line only
-- appears while a disenchant is what waits for a target, so it identifies
-- itself: a pending Prospecting produces no such line on anything. The screen on
-- quality and class that remains is there to keep the cost down -- a tooltip
-- read per bag slot per raise -- and cannot change an answer, because nothing
-- outside uncommon-or-better armour and weapons is disenchantable anyway.
--
-- The first attempt at this read C_Item.DoesItemMatchSpellItemCondition, the
-- call the greyed-out bag slots go through. It answers about a pending spell
-- carrying an item condition, and a Disenchant is not one:
-- C_Spell.TargetSpellChecksItemCondition is false throughout, so the probe
-- refused every item and learned nothing. The legacy SpellIsTargeting, which
-- the C_Spell predicates read as superseding, is what reports the state.

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
---@return table|nil facts
---@return boolean|nil canDisenchant
local function readSlot(bagIndex, slotIndex)
    local facts = scanner.Gather(bagIndex, slotIndex)
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
    if type(facts.quality) ~= "number" then return nil, nil end
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

--- Harvests every bag slot into the learned table, and reports what the crawled
--- table got wrong into the debug dump.
function disenchantProbe.Harvest()
    if not disenchantPending() then return end

    local dump = model.GetDebugDump()
    local mismatches = dump and {}
    local scanned = 0

    for bagIndex = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bagIndex)
        for slotIndex = 1, numSlots do
            local facts, canDisenchant = readSlot(bagIndex, slotIndex)
            if facts then
                scanned = scanned + 1

                local predicted = model.PredictDisenchantable(facts)
                if mismatches and predicted ~= canDisenchant then
                    -- Flattened, like every other record filed here: item data
                    -- can carry secret values in 12.0, and the record has to
                    -- survive a SavedVariable and be pastable verbatim.
                    mismatches[#mismatches + 1] = format(
                        "%s %s q=%s cls=%s/%s predicted=%s client=%s",
                        tostring(facts.itemID), tostring(facts.name),
                        tostring(facts.quality), tostring(facts.classID),
                        tostring(facts.subclassID),
                        tostring(predicted), tostring(canDisenchant))
                end

                model.LearnDisenchantable(facts.itemID, canDisenchant)
            end
        end
    end

    -- Filed even when nothing disagreed, and even when nothing was eligible.
    -- A dump that is simply absent cannot distinguish a crawled table that was
    -- right from a probe that never ran -- which is the first thing to rule out
    -- if Disenchant turns out not to reach the item-condition system at all.
    if dump then
        dump.disenchantProbe = {
            scanned    = tostring(scanned),
            mismatches = mismatches,
        }
    end
end

control.disenchantProbe = disenchantProbe

local function buildEquipmentSetCache()
    local cache = {}
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        for _, location in ipairs(C_EquipmentSet.GetItemLocations(setID) or {}) do
            local data = EquipmentManager_GetLocationData(location)
            if data.isBags then
                cache[data.bag .. ":" .. data.slot] = true
            end
        end
    end
    model.SetEquipmentSetCache(cache)
end

--- GetProfessions returns spellbook skill-line INDICES, not skill line IDs, so
--- the ID has to be converted before it can be compared -- the same conversion
--- Blizzard's own WorldMapFrame does. Comparing the two directly never matches,
--- which reads as "nobody is an enchanter" rather than as an error.
---
--- GetSkillLineIndexByID answers nil for a line the player does not have, so
--- the prof1/prof2 test is what confirms it is one of the two primary slots
--- rather than some other tracked line.
local function detectEnchanting()
    local lineID = C_TradeSkillUI.GetProfessionSkillLineID(Enum.Profession.Enchanting)
    local index = lineID and C_SpellBook.GetSkillLineIndexByID(lineID)
    local prof1, prof2 = GetProfessions()
    model.SetIsEnchanter(index ~= nil and (index == prof1 or index == prof2))
end

local function onMerchantShow()
    merchantOpen = true
    -- A fresh visit gets a fresh memo: what this caches -- the pet and recipe
    -- tooltip answers -- is a property of this visit, not of the item, and the
    -- player may have learned either since the last one.
    scanner.ClearVisitMemo()
    if model.GetRule("junk").sell and C_MerchantFrame.IsSellAllJunkEnabled() then
        C_MerchantFrame.SellAllJunkItems()
    end
    -- Unconditional, and not an alternative to the sweep above. Leaving the
    -- scan to the BAG_UPDATE_DELAYED the sweep provokes assumed the sweep
    -- always moves something: it does not when the bags hold no junk, which is
    -- every visit after the first has cleared them. No bag update, no scan, and
    -- onMerchantClosed had already emptied the manifest -- so the panel opened
    -- blank until the player pressed Refresh.
    --
    -- When the sweep does sell something the scan simply runs twice: this one
    -- against bags that still hold the junk, then the bag update's against bags
    -- that do not. The second is the one the player sees, and seller.SellBatch
    -- re-reads every slot before acting, so a manifest entry outlived by its
    -- item cannot mis-sell in between.
    scanner.Scan()
    view.merchantPanel.Show()
end

local function onMerchantClosed()
    merchantOpen = false
    -- Cleared here too, not only on the next MERCHANT_SHOW: view.lua's debug
    -- tooltip calls scanner.Explain away from a vendor, and without this a
    -- recipe learned right after closing would still read the stale answer
    -- memoized during the visit, until the player opened a vendor again.
    scanner.ClearVisitMemo()
    model.ClearTempExcludes()
    model.ClearTempIncludes()
    -- The manifest is this visit's decisions, not a durable record: leaving it
    -- in place let a temporary include re-sell an item on a later visit after
    -- its one-visit-only inclusion had already been cleared above, and let a
    -- blacklist entry added between visits go unnoticed by that first Sell.
    model.SetManifest({})
    view.merchantPanel.Hide()
end

--- Whether the merchant window is open right now. The item tooltip's
--- player-facing verdict reads this live to decide whether to render at all --
--- gating on the module's own tracked state rather than MerchantFrame:IsShown(),
--- since MerchantFrame does not exist in the test harness.
function control.IsMerchantOpen()
    return merchantOpen
end

local function onBagUpdateDelayed()
    if merchantOpen then
        scanner.Scan()
    end
end

local function onEquipmentSetsChanged()
    buildEquipmentSetCache()
    if merchantOpen then
        scanner.Scan()
    end
end

-- ITEM_DATA_LOAD_RESULT payload is (itemID, success).
local function onItemDataLoaded(itemID, success)
    if not scanner.ResolveLoad(itemID) then return end
    if success and merchantOpen then
        scanner.Scan()
    end
end

-- The player put a spell on the cursor, or took it off. Harvest declines the
-- latter, and declines a raise that is not a disenchant, so nothing here needs
-- to know which of the two just happened.
local function onCurrentSpellCastChanged()
    disenchantProbe.Harvest()
end

-- Learning or unlearning Enchanting changes what counts as disenchantable.
local function onSkillLinesChanged()
    detectEnchanting()
    if merchantOpen then
        scanner.Scan()
    end
end

local function startModule()
    -- The tooltip hook goes in first, deliberately: it is what explains a
    -- module whose later startup misbehaves, so it must not be downstream of
    -- anything that can fail.
    view.itemTooltip.Init()

    local classFilename = UnitClassBase("player")
    model.SetPlayerClass(classFilename)
    buildEquipmentSetCache()
    detectEnchanting()
    view.settingsPanel.Init()
end

local function onPlayerReady()
    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        steps   = {
            -- Data written before this module was versioned already matches the
            -- version-1 shape, so adopting the version is the whole migration.
            [1] = function() end,
            -- The classification rework retired four settings. Nothing reads
            -- them afterwards, and the logout prune only visits keys present in
            -- DB_DEFAULTS, so one left behind would sit in the saved variables
            -- forever. Assigning nil unconditionally is idempotent, which
            -- matters because a step that throws is re-invoked from the top.
            --
            -- Values are not carried forward. keepEquippable's two states map
            -- onto the item level margin, whose default reproduces its
            -- on-state; the other three have no successor. This
            -- step is char-scoped, so it reaches only the character logging in
            -- when the account-wide version is stamped -- every other character
            -- keeps its stale entries, which is why nothing is migrated rather
            -- than migrated partially.
            [2] = function(moduleDB)
                moduleDB.char.keepEquippable = nil
                moduleDB.char.qualityThreshold = nil
                moduleDB.char.sellPastExpansion = nil
                moduleDB.char.expansionThreshold = nil
            end,
            -- The item level margin became a proportion of the equipped item
            -- rather than a flat number of levels, and changed sign with it: the
            -- old -20 meant "twenty levels below", the new 0.9 means "nine
            -- tenths of the slot". A stored -20 read as the new setting is not
            -- merely wrong, it is off the slider entirely, so the old key is
            -- dropped and the new default seeded rather than converted -- twenty
            -- levels is 3% of a 620 slot and 33% of a 60 one, so there is no one
            -- proportion the old number translates to.
            --
            -- Detects the OLD key rather than the absence of the new one: the
            -- defaults have already been seeded by the time a step runs, so
            -- ilvlMarginRatio is always present here. Assigning nil is
            -- idempotent, which matters because a step that throws is re-invoked
            -- from the top.
            [3] = function(moduleDB)
                moduleDB.char.ilvlThreshold = nil
            end,
            -- The three per-direction margin toggles are retired. The margin
            -- now reaches every quality gap through a single exponent, and
            -- granting it to one direction while withholding it from another
            -- is precisely what made the comparison non-monotonic: with the
            -- margin on same quality and off below it, an Uncommon outlived
            -- the Rare beside it at the same item level.
            --
            -- Nothing carries forward, because nothing succeeds them -- there
            -- is no setting left for an off-state to mean. The margin they
            -- governed is untouched, so a player who had tuned it keeps it.
            [4] = function(moduleDB)
                moduleDB.char.marginOnHigherQuality = nil
                moduleDB.char.marginOnSameQuality = nil
                moduleDB.char.marginOnLowerQuality = nil
            end,
            -- The margin went back to a flat number of item levels. Midnight
            -- squished the scale, so the span one number has to cover is narrow
            -- enough for a flat margin to mean something across it -- which is
            -- what a proportion was introduced to solve and no longer needs to.
            --
            -- Not carried across, for the same reason step 3 could not carry the
            -- other direction: 0.9 is 29 levels against an equipped 290 and 6
            -- against an equipped 60, so there is no single number it becomes.
            -- The old key is dropped and the seeded default stands.
            [5] = function(moduleDB)
                moduleDB.char.ilvlMarginRatio = nil
            end,
            -- The rule tree is warband-wide, and the whole of the old
            -- char-scoped block is retired with the three-bucket
            -- classification it configured.
            --
            -- Nothing is carried forward, and that is deliberate rather than
            -- lazy. Promoting one character's tuning to govern the account has
            -- no correct source: this step is char-scoped, so the answer would
            -- be whoever happened to log in when the version was stamped.
            -- Seeding the defaults is honest; promoting an arbitrary character
            -- silently is not. limitBatchTo12 keeps its old default of true in
            -- its new home, so the batch stays capped either way.
            [6] = function(moduleDB)
                moduleDB.char.limitBatchTo12 = nil
                moduleDB.char.sellJunk = nil
                moduleDB.char.sellEquipment = nil
                moduleDB.char.materialsMode = nil
                moduleDB.char.materialsExpansion = nil
                moduleDB.char.otherMode = nil
                moduleDB.char.ilvlMargin = nil
                moduleDB.char.emphasizeQuality = nil
                moduleDB.char.keepBindOnAccount = nil
                moduleDB.char.keepBindOnAccountPastExpac = nil
                moduleDB.char.keepDisenchantables = nil
                moduleDB.char.keepUsedReagents = nil
                moduleDB.char.keepDisenchantablesPastExpac = nil
            end,
            -- Two rule-tree keys retire together.
            --
            -- housing.sellLearnedDyes governed a branch that could never fire:
            -- a dye is a one-time consumable, so nothing is ever collected or
            -- learned for one. Its successor, housing.keepTradeableDyes, asks
            -- whether the copy still has somewhere to go, which is a question
            -- about a consumable.
            --
            -- armor.keepUncollectedCosmetic moves to a rules.cosmetics of its
            -- own, because the rule it governs stopped being an armor rule: a
            -- cosmetic is not a class or a subclass, and the two items in #32
            -- are weapons. The protection now reaches them.
            --
            -- Neither value is carried across. Both successors ship on, which
            -- is where anyone who left the defaults alone already was. The step
            -- exists only because the logout prune visits the keys DB_DEFAULTS
            -- declares, so a retired one left behind would sit in the saved
            -- variables forever. Assigning nil unconditionally is idempotent,
            -- which matters because a step that throws is re-invoked from the
            -- top.
            [7] = function(moduleDB)
                local rules = moduleDB.global.rules
                rules.housing.sellLearnedDyes = nil
                rules.armor.keepUncollectedCosmetic = nil
            end,
            -- The decor rule ships off. Nothing ever chose the old default --
            -- no control reaches it -- so a stored true is a seed rather than
            -- a preference, and rewriting it is the only way the new default
            -- reaches a database that already carries the key. Idempotent for
            -- the same reason step 7 is.
            [8] = function(moduleDB)
                moduleDB.global.rules.housing.sellCollectedDecor = false
            end,
            -- ilvlMargin never was an item level margin: it priced a quality
            -- tier, and emphasizeQuality doubled it while granting a tolerance
            -- of the same size. The two effects are now two keys, and the one
            -- whose meaning changed takes a new name so no stored value is
            -- silently reinterpreted.
            --
            -- Unlike steps 3, 4 and 5, this one COULD have carried the tuning
            -- across exactly -- emphasis off maps to qualityMargin = ilvlMargin
            -- with margin 0, emphasis on to double and equal. That was declined
            -- rather than unavailable, and the neighbouring comments would
            -- otherwise read as though it had been unavailable here too. The
            -- seeded defaults reproduce the shipped comparison, so a player who
            -- never touched these two notices nothing.
            [9] = function(moduleDB)
                local gear = moduleDB.global.rules.gear
                gear.ilvlMargin = nil
                gear.emphasizeQuality = nil
            end,

            -- The two gear toggles are retired, and neither transition is
            -- lossless, which is why no value is carried forward. A player who
            -- had compareItemLevel off was having no item level comparison at
            -- all, and no tolerance reproduces that -- the widest is 30 -- so
            -- they get the ladder's answer now. A player who had compareQuality
            -- on gets what qualityMargin charges a tier instead of an absolute
            -- veto. The defaults are unchanged, so a player who touched neither
            -- notices nothing. Idempotent for the same reason step 9 is.
            [10] = function(moduleDB)
                local gear = moduleDB.global.rules.gear
                gear.compareItemLevel = nil
                gear.compareQuality = nil
            end,

            -- keepForDisenchant was a boolean with no age limit at all, so a
            -- stored true maps to ALL rather than to the new default -- every
            -- existing player goes on keeping exactly what they kept. A fresh
            -- profile gets CURRENT instead, so the migration and the default
            -- deliberately disagree: narrowing someone's stored setting would
            -- start selling gear they were keeping, and they never asked.
            --
            -- Typed rather than truthy: the old value is a boolean and the new
            -- one a string, so re-running this against a migrated profile has
            -- to be a no-op, which is what makes it idempotent.
            [11] = function(moduleDB)
                local gear = moduleDB.global.rules.gear
                if type(gear.keepForDisenchant) == "boolean" then
                    gear.keepForDisenchant = gear.keepForDisenchant and "ALL" or "NONE"
                end
            end,
        },
    }, startModule)
end

ns:Subscribe(events.MERCHANT_SHOW, onMerchantShow)
ns:Subscribe(events.MERCHANT_CLOSED, onMerchantClosed)
ns:Subscribe(events.BAG_UPDATE_DELAYED, onBagUpdateDelayed)
ns:Subscribe(events.EQUIPMENT_SETS_CHANGED, onEquipmentSetsChanged)
ns:Subscribe(events.ITEM_DATA_LOAD_RESULT, onItemDataLoaded)
ns:Subscribe(events.SKILL_LINES_CHANGED, onSkillLinesChanged)
ns:Subscribe(events.CURRENT_SPELL_CAST_CHANGED, onCurrentSpellCastChanged)
ns:Subscribe(events.PLAYER_READY, onPlayerReady)

-- /bfdump b <itemID> captures a whole verdict -- the item, what is equipped in
-- the slot it would fill, the settings that judged the pair, and the rule that
-- decided -- and shows it in the report window, for the player to paste rather
-- than dig out of SavedVariables.
--
-- It takes an ID rather than a bag slot on purpose. The tooltip could already
-- explain anything you were holding, live, and nothing else: a verdict reported
-- after the fact was uninvestigable, because both operands had gone. An ID
-- resolves the candidate from the client's cache and the equipped side from the
-- slots its equip location maps to, so neither has to still be in your bags.
--
-- Never gate this block on model.IsDebug(). The command records nothing -- the
-- record goes to the player, not to disk -- so there is nothing left to gate.
do
    -- Every field is flattened with tostring. Item data can carry secret values
    -- in 12.0, the record has to survive being written to a SavedVariable, and
    -- it is meant to be pasted into an issue verbatim.
    local function Flatten(value)
        return tostring(value)
    end

    -- The paired half. equippedItems feeds the pure comparison and carries only
    -- what that reads, so the slot and link are gathered again here -- a record
    -- naming neither cannot be checked against the character it came from.
    --
    -- The two gaps are computed rather than left implicit: they are what the
    -- comparison actually branches on, and a reader should not have to subtract
    -- to find out why a verdict landed.
    local function EquippedPairs(facts)
        local slots = enum.SLOT_LOOKUP[facts.equipLoc]
        if not slots then return nil end

        local paired = {}
        for _, slotID in ipairs(slots) do
            local link = GetInventoryItemLink("player", slotID)
            if link then
                local level = C_Item.GetDetailedItemLevelInfo(link)
                local quality = select(3, C_Item.GetItemInfo(link))
                paired[#paired + 1] = {
                    slot       = Flatten(slotID),
                    link       = Flatten(link),
                    level      = Flatten(level),
                    quality    = Flatten(quality),
                    qualityGap = level and quality
                        and Flatten(facts.quality - quality) or "unreadable",
                    itemGap    = level and quality
                        and Flatten(facts.level - level) or "unreadable",
                }
            end
        end
        return paired
    end

    -- Only the settings the gear comparison consults. The whole snapshot would
    -- bury them, and these are the ones that explain a surprising verdict.
    local function DecidingSettings(settings)
        local gear = settings.rules and settings.rules.gear or {}
        -- The top position is a word on the slider for a reason: pasted into an
        -- issue as a bare 32 it reads as thirty-two item levels, the exact
        -- misreading the word exists to prevent.
        local qualityMargin = gear.qualityMargin >= enum.QUALITY_MARGIN_ALWAYS
            and "ALWAYS" or Flatten(gear.qualityMargin)
        return {
            margin             = Flatten(gear.margin),
            qualityMargin      = qualityMargin,
            spareBindOnAccount = Flatten(gear.spareBindOnAccount),
            keepForDisenchant  = Flatten(gear.keepForDisenchant),
            playerClass        = Flatten(settings.playerClass),
            isEnchanter        = Flatten(settings.isEnchanter),
        }
    end

    local function BuildDump(report)
        local facts = report.facts
        return {
            itemID     = Flatten(facts.itemID),
            name       = Flatten(facts.name),
            link       = Flatten(facts.itemLink),
            quality    = Flatten(facts.quality),
            level      = Flatten(facts.level),
            equipLoc   = Flatten(facts.equipLoc),
            class      = ("%s/%s"):format(Flatten(facts.classID), Flatten(facts.subclassID)),
            bindType   = Flatten(facts.bindType),
            expacID    = Flatten(facts.expacID),
            sellPrice  = Flatten(facts.sellPrice),
            listStatus = ("blacklisted=%s whitelisted=%s"):format(Flatten(facts.isProhibited), Flatten(facts.isEnforced)),
            equipped   = EquippedPairs(facts),
            verdict    = Flatten(report.verdict),
            rule       = Flatten(report.rule),
            settings   = DecidingSettings(report.settings),
        }
    end

    -- Fixed here rather than taken from pairs: a report whose lines shuffle
    -- between two players is a report nobody can diff.
    local DUMP_FIELDS = {
        "itemID", "name", "link", "quality", "level", "equipLoc", "class",
        "bindType", "expacID", "sellPrice", "listStatus", "verdict", "rule",
    }

    local EQUIPPED_FIELDS = { "slot", "link", "level", "quality", "qualityGap", "itemGap" }

    local SETTING_FIELDS = {
        "margin", "qualityMargin", "spareBindOnAccount", "keepForDisenchant",
        "playerClass", "isEnchanter",
    }

    --- One report as text. Both entry points render the same way -- the
    --- tooltip's copy affordance and /bfdump differ only in how they resolve
    --- the item. BuildDump has already flattened every value with tostring,
    --- which is what makes an item's secret values safe to put in front of a
    --- player in 12.0.
    ---@param report table
    ---@return string
    local function RenderItemReport(report)
        local dump = BuildDump(report)
        local lines = {
            "BitForge BatchSell -- item report",
            BitForge:ReportHeader(ADDON_NAME),
            "",
        }

        for _, field in ipairs(DUMP_FIELDS) do
            lines[#lines + 1] = format("%s = %s", field, dump[field])
        end

        -- Absent for an item that fills no slot, which is most of them.
        if dump.equipped then
            lines[#lines + 1] = ""
            for index, entry in ipairs(dump.equipped) do
                for _, field in ipairs(EQUIPPED_FIELDS) do
                    lines[#lines + 1] = format("equipped[%d] %s = %s", index, field, entry[field])
                end
            end
        end

        lines[#lines + 1] = ""
        for _, field in ipairs(SETTING_FIELDS) do
            lines[#lines + 1] = format("settings.%s = %s", field, dump.settings[field])
        end

        return concat(lines, "\n")
    end

    --- One item's whole verdict as text a player can select and paste, for
    --- the item currently under the tooltip's cursor.
    ---@param bagIndex number
    ---@param slotIndex number
    ---@return string|nil  nil when the slot is empty or its item data has not arrived
    function control.ReportText(bagIndex, slotIndex)
        local report = scanner.Explain(bagIndex, slotIndex)
        if not report then return nil end

        return RenderItemReport(report)
    end

    --- Show one item's whole verdict in the report window.
    ---
    --- Nothing is stored: the record used to be parked in db.debug.dump for a
    --- later session to dig out of SavedVariables, which is why it needed the
    --- debug flag to stop it accumulating unasked. Rendered and shown, it
    --- records nothing, so it needs no flag and no /reload.
    ---@param itemID number|nil
    function control.DumpItem(itemID)
        if not itemID then
            BitForge:Print("BatchSell: /bfdump batchsell <itemID> | disenchant")
            return
        end

        local report = scanner.ExplainByID(itemID)
        if not report then
            BitForge:Print(("BatchSell: item %d is not cached yet -- try again in a moment")
                :format(itemID))
            return
        end

        BitForge:ShowReport(RenderItemReport(report), locale["report:blurb"],
            BitForge:DiagnosticReportTitle())
    end

    -- The disenchant probe is scaffolding for one open question: which signal
    -- distinguishes an item the player can disenchant from one they cannot. The
    -- obvious candidate was wrong -- C_Spell.TargetSpellChecksItemCondition is
    -- false with a disenchant pending, so the item-condition system the bag
    -- slots use does not cover it -- and the answer turns out to be an ordinary
    -- tooltip line the server adds while the spell waits for a target.
    --
    -- Everything needed to pin that down is captured in a single subcommand
    -- deliberately. The state under investigation is destroyed by the act of
    -- investigating it any other way: a pending spell does not survive being
    -- studied one pasted line at a time, and a bag does not hold still between
    -- them. Run it once with the spell up and once with it down -- the report
    -- window is reused, not stacked, so copy the first result out before
    -- running the second, or it is gone.

    local SCAN_ITEM_LIMIT = 8

    -- Every string in _G, indexed by its value, so a captured tooltip line can
    -- be traced back to the global constant it was built from. A line matched
    -- by constant is matched in all eleven locales; a line matched by its text
    -- is matched in one, and only until the text is reworded.
    --
    -- First key wins. Several constants share a value -- the duplicates are
    -- aliases of each other and naming either one answers the question.
    local function GlobalStringIndex()
        local index = {}
        for key, value in pairs(_G) do
            if type(value) == "string" and value ~= "" and index[value] == nil then
                index[value] = key
            end
        end
        return index
    end

    -- One slot's whole tooltip, flattened. Every line is kept rather than only
    -- the error lines: the line that marks an item as disenchantable has not
    -- been seen yet, and filtering to the type the *negative* line uses would
    -- be assuming the answer.
    local function CaptureTooltip(bagIndex, slotIndex, names)
        local data = C_TooltipInfo.GetBagItem(bagIndex, slotIndex)
        if not data or not data.lines then return { "no tooltip data" } end

        local captured = {}
        for index, line in ipairs(data.lines) do
            local text = tostring(line.leftText)
            captured[#captured + 1] = ("%s type=%s global=%s | %s"):format(
                tostring(index), tostring(line.type),
                tostring(names[text] or "-"), text)
        end
        return captured
    end

    --- One disenchant-probe scan as text: the client's whole state, followed
    --- by every captured item's tooltip lines.
    ---@param scan table
    ---@return string
    local function RenderDisenchantReport(scan)
        local lines = {
            "BitForge BatchSell -- disenchant scan",
            BitForge:ReportHeader(ADDON_NAME),
            "",
            scan.state,
        }

        -- Sorted rather than walked in hash order: two runs over the same bag
        -- render their items in whatever order pairs() happens to reach them,
        -- and the reason to run twice is to compare the two texts.
        local keys = {}
        for key in pairs(scan.items) do
            keys[#keys + 1] = key
        end
        table.sort(keys)

        for _, key in ipairs(keys) do
            lines[#lines + 1] = ""
            lines[#lines + 1] = key
            for _, line in ipairs(scan.items[key]) do
                lines[#lines + 1] = line
            end
        end

        return concat(lines, "\n")
    end

    --- Show the client's whole answer about disenchanting in the report window.
    ---
    --- Rendered and shown rather than filed, like control.DumpItem -- see its
    --- comment for why the debug gate this used to need is gone with it.
    function control.ScanDisenchant()
        local names = GlobalStringIndex()

        local items = {}
        local seen = 0
        for bagIndex = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
            local numSlots = C_Container.GetContainerNumSlots(bagIndex)
            for slotIndex = 1, numSlots do
                if seen < SCAN_ITEM_LIMIT then
                    local facts = scanner.Gather(bagIndex, slotIndex)
                    -- The same coarse shape the real rule screens on, so the
                    -- capture is of the items the question is actually about.
                    if facts and facts.quality >= Enum.ItemQuality.Uncommon
                        and (facts.classID == Enum.ItemClass.Armor
                            or facts.classID == Enum.ItemClass.Weapon) then
                        seen = seen + 1
                        local key = ("%s:%s %s %s q=%s cls=%s/%s predicted=%s"):format(
                            tostring(bagIndex), tostring(slotIndex),
                            tostring(facts.itemID), tostring(facts.name),
                            tostring(facts.quality), tostring(facts.classID),
                            tostring(facts.subclassID),
                            tostring(model.PredictDisenchantable(facts)))
                        items[key] = CaptureTooltip(bagIndex, slotIndex, names)
                    end
                end
            end
        end

        local scan = {
            state = ("targeting=%s canTargetItem=%s canTargetItemID=%s"
                .. " hasDisenchantSpell=%s isEnchanter=%s"):format(
                tostring(SpellIsTargeting()),
                tostring(SpellCanTargetItem()),
                tostring(SpellCanTargetItemID()),
                tostring(C_SpellBook.ContainsAnyDisenchantSpell()),
                tostring(model.GetIsEnchanter())),
            items = items,
        }

        BitForge:ShowReport(RenderDisenchantReport(scan), locale["report:blurbDisenchant"],
            BitForge:DiagnosticReportTitle())
    end

    -- One handler, two subcommands. `disenchant` carries no digits and an item
    -- ID carries nothing else, so the word is matched first and the remainder
    -- reads as an ID -- the same order Openables matches `all` in.
    ns:SubscribeCommand(events.MODULE_DUMP, function(addon, argument)
        if addon ~= ADDON_NAME then return end

        local subcommand = argument:match("%S+")
        if subcommand and subcommand:lower() == "disenchant" then
            control.ScanDisenchant()
            return
        end
        control.DumpItem(tonumber(subcommand and subcommand:match("%d+")))
    end)
end

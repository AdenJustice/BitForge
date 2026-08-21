---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local huge = math.huge
local format = string.format

local ClearCursor = ClearCursor
local GetCursorInfo = GetCursorInfo

local C_Container = C_Container
local C_EquipmentSet = C_EquipmentSet
local C_Item = C_Item
local C_MerchantFrame = C_MerchantFrame
local C_TradeSkillUI = C_TradeSkillUI

local enum = ns.enum
local model = ns.model
local view = ns.view
local L = ns.locale
local E = BitForge.Events

---@class BitForge.BatchSell.Control
local control = ns.control

function ns:Subscribe(event, callback)
    BitForge.Subscribe(event, callback, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

local merchantOpen = false

-- ================================================================================
-- Scanner
-- ================================================================================
--
-- The only code that reads item state from the game. It produces plain fact
-- tables; model.Decide consumes them and never touches an API. Anything that
-- needs only data — class equippability, disenchantability, expansion age —
-- lives in the model, not here.

local scanner = {}

--- The equipped items occupying the slots this item could fill, or nil when the
--- item is not equippable at all. Rings and trinkets yield up to two entries.
---
--- Deliberately returns the raw list rather than reducing it: the comparison is
--- existential over slots, and model.CompareToEquipped owns that loop where it
--- can be unit-tested. Reducing here -- to a max or a min -- would move the one
--- piece of real logic into the one file that cannot be tested.
---
--- Quality travels with the level because the comparison's tolerance depends on
--- the gap between the candidate's quality and the equipped one's.
local function equippedItems(equipLoc)
    local slots = enum.SLOT_LOOKUP[equipLoc]
    if not slots then return nil end

    local items = {}
    for _, slotID in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotID)
        if equippedLink then
            local equippedLevel = C_Item.GetDetailedItemLevelInfo(equippedLink)
            local equippedQuality = select(3, C_Item.GetItemInfo(equippedLink))
            if equippedLevel and equippedQuality then
                items[#items + 1] = { level = equippedLevel, quality = equippedQuality }
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

--- Gathers one slot's facts, or nil when the slot is empty or its item data has
--- not arrived yet. Uncached items are requested and rescanned; see Events.
---@return table|nil facts
---@return number|nil pendingItemID  set when the slot was skipped pending a load
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
    -- merchant is open. The pre-renovation code also dropped the item here.
    if not name then return nil, nil end

    local resolvedLink = itemLink or hyperlink
    local listStatus = model.GetEffectiveStatus(slotInfo.itemID)

    return {
        bagIndex       = bagIndex,
        slotIndex      = slotIndex,
        itemID         = slotInfo.itemID,
        itemLink       = resolvedLink,
        name           = name,
        quality        = quality,
        sellPrice      = sellPrice or 0,
        stackCount     = slotInfo.stackCount or 1,
        level          = C_Item.GetDetailedItemLevelInfo(resolvedLink) or 0,
        equipLoc       = equipLoc,
        classID        = classID,
        subclassID     = subclassID,
        bindType       = bindType,
        expacID        = expacID or 0,
        isCraftingReagent = isCraftingReagent == true,

        isLocked       = slotInfo.isLocked == true,
        inEquipmentSet = model.IsInEquipmentSet(format("%d:%d", bagIndex, slotIndex)),
        isRefundable   = isRefundable(bagIndex, slotIndex),
        equippedItems  = equippedItems(equipLoc),

        isProhibited   = listStatus == enum.LIST_STATUS.BLACKLIST,
        isEnforced     = listStatus == enum.LIST_STATUS.WHITELIST,
        isTempExcluded = model.IsTempExcluded(resolvedLink),
        isTempIncluded = model.IsTempIncluded(resolvedLink),

        -- Read by the merchant panel only; model.Decide never consults it.
        isCharOverride = model.HasCharOverride(slotInfo.itemID),
    }
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

    -- BACKPACK_CONTAINER..NUM_TOTAL_EQUIPPED_BAG_SLOTS includes the reagent bag,
    -- which a hardcoded 0..4 silently skipped.
    for bagIndex = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bagIndex)
        for slotIndex = 1, numSlots do
            local facts, pendingItemID = scanner.Gather(bagIndex, slotIndex)
            if facts then
                if model.Decide(facts, settings) == enum.DECISION.SELL then
                    items[#items + 1] = facts
                end
            elseif pendingItemID then
                scanner.RequestLoad(pendingItemID)
            end
        end
    end

    model.SetManifest(items)
    view.merchantPanel.Refresh()
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
function scanner.Explain(bagIndex, slotIndex)
    local facts = scanner.Gather(bagIndex, slotIndex)
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

control.scanner = scanner

-- ================================================================================
-- Seller
-- ================================================================================

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

-- ================================================================================
-- Manifest Drop
-- ================================================================================
--
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
        BitForge:Print(format(L["msg:dropRefused"], itemLink, L["reason:" .. blockingRule]))
        return
    end

    if model.IsTempExcluded(itemLink) then
        model.RemoveTempExclude(itemLink)
        BitForge:Print(format(L["msg:dropUnexcluded"], itemLink))
    end

    model.AddTempInclude(itemLink)
    scanner.Scan()
end

-- ================================================================================
-- Caches
-- ================================================================================

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

local function detectEnchanting()
    local enchantingLineID = C_TradeSkillUI.GetProfessionSkillLineID(Enum.Profession.Enchanting)
    for _, lineID in ipairs(C_TradeSkillUI.GetAllProfessionTradeSkillLines()) do
        if lineID == enchantingLineID then
            model.SetIsEnchanter(true)
            return
        end
    end
    model.SetIsEnchanter(false)
end

-- ================================================================================
-- Events
-- ================================================================================

local function onMerchantShow()
    merchantOpen = true
    if model.GetSellJunk() and C_MerchantFrame.IsSellAllJunkEnabled() then
        C_MerchantFrame.SellAllJunkItems()
        -- BAG_UPDATE_DELAYED fires once the junk leaves the bags and rescans.
    else
        scanner.Scan()
    end
    view.merchantPanel.Show()
end

local function onMerchantClosed()
    merchantOpen = false
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

-- Learning or unlearning Enchanting changes what counts as disenchantable.
-- Detection previously ran once at login and never again.
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
            -- onto ilvlThreshold and marginOnSameQuality, whose defaults
            -- reproduce its on-state; the other three have no successor. This
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
        },
    }, startModule)
end

ns:Subscribe(E.MERCHANT_SHOW, onMerchantShow)
ns:Subscribe(E.MERCHANT_CLOSED, onMerchantClosed)
ns:Subscribe(E.BAG_UPDATE_DELAYED, onBagUpdateDelayed)
ns:Subscribe(E.EQUIPMENT_SETS_CHANGED, onEquipmentSetsChanged)
ns:Subscribe(E.ITEM_DATA_LOAD_RESULT, onItemDataLoaded)
ns:Subscribe(E.SKILL_LINES_CHANGED, onSkillLinesChanged)
ns:Subscribe(E.PLAYER_READY, onPlayerReady)

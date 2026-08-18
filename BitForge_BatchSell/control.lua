---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local huge = math.huge
local format = string.format

local C_Container = C_Container
local C_EquipmentSet = C_EquipmentSet
local C_Item = C_Item
local C_MerchantFrame = C_MerchantFrame
local C_TradeSkillUI = C_TradeSkillUI

local enum = ns.enum
local model = ns.model
local view = ns.view
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

--- Item levels currently equipped in the slots this item could occupy, or nil
--- when the item is not equippable at all. Rings and trinkets yield up to two
--- entries.
---
--- Deliberately returns the raw list rather than reducing it: the comparison is
--- existential over slots, and model.IsCloseToEquipped owns that loop where it
--- can be unit-tested. Reducing here — to a max or a min — would move the one
--- piece of real logic into the one file that cannot be tested.
local function equippedIlvls(equipLoc)
    local slots = enum.SLOT_LOOKUP[equipLoc]
    if not slots then return nil end

    local levels = {}
    for _, slotID in ipairs(slots) do
        local equippedLink = GetInventoryItemLink("player", slotID)
        if equippedLink then
            local equippedIlvl = C_Item.GetDetailedItemLevelInfo(equippedLink)
            if equippedIlvl then
                levels[#levels + 1] = equippedIlvl
            end
        end
    end
    return levels
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
local function gather(bagIndex, slotIndex)
    local slotInfo = C_Container.GetContainerItemInfo(bagIndex, slotIndex)
    if not slotInfo or not slotInfo.itemID then return nil, nil end

    if not C_Item.IsItemDataCachedByID(slotInfo.itemID) then
        return nil, slotInfo.itemID
    end

    local hyperlink = slotInfo.hyperlink
    local name, itemLink, quality, _, _, _, _, _, equipLoc, _, sellPrice,
    classID, subclassID, bindType, expacID = C_Item.GetItemInfo(hyperlink)
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

        isLocked       = slotInfo.isLocked == true,
        inEquipmentSet = model.IsInEquipmentSet(format("%d:%d", bagIndex, slotIndex)),
        isRefundable   = isRefundable(bagIndex, slotIndex),
        equippedIlvls  = equippedIlvls(equipLoc),

        isProhibited   = listStatus == enum.LIST_STATUS.BLACKLIST,
        isEnforced     = listStatus == enum.LIST_STATUS.WHITELIST,
        isTempExcluded = model.IsTempExcluded(resolvedLink),

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
            local facts, pendingItemID = gather(bagIndex, slotIndex)
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
    view.merchantPanel.Hide()
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

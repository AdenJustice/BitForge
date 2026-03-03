--- @type ns.BatchSell
local ns = select(2, ...)
local model = ns.model --[[@as BitForge.Models.BatchSell]]
local view = ns.view
local L = ns.locale
local params = ns.params
--- @class BitForge.Controls.BatchSell:BitForge.Controls.Base
local control = ns.control

--- =========================================================
--- Caches
--- =========================================================

local _wipe = table.wipe
local _tinsert = table.insert
local _tremove = table.remove
local _min = math.min
local _format = string.format
local _select = select
local _ipairs = ipairs
local _pairs = pairs
local _print = print

local _GetContainerNumSlots = C_Container.GetContainerNumSlots
local _GetContainerItemInfo = C_Container.GetContainerItemInfo
local _GetContainerItemPurchaseInfo = C_Container.GetContainerItemPurchaseInfo
local _GetItemInfo = C_Item.GetItemInfo
local _IsItemDisenchantable = C_Item.IsItemDisenchantable
local _GetInventoryItemLink = GetInventoryItemLink
local _UseContainerItem = C_Container.UseContainerItem
local _GetProfessions = GetProfessions
local _GetProfessionInfo = GetProfessionInfo
local _GetItemLocations = C_EquipmentSet.GetItemLocations
local _GetLocationData = EquipmentManager_GetLocationData
local _CreateItemLocation = ItemLocation.CreateFromBagAndSlot
local _CreateItemFromLocation = Item.CreateFromItemLocation
local _StaticPopup_Show = StaticPopup_Show
local _GetMoneyString = GetMoneyString
local _After = C_Timer.After
local _EnumItemClass = Enum.ItemClass
local _EnumItemArmorSubclass = Enum.ItemArmorSubclass

-- State management
local sellQueue = {}
local scanInProgress = false
local scanVersion = 0
local sellInProgress = false
local currentSellIndex = 0
local playerClass = params.character.class
local primaryArmorType
local hasEnchanting = false

-- Constants
local BAG_TO_SCAN = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
    Enum.BagIndex.ReagentBag,
}




-- --- [ helpers ]======================================================================

-- local function _RefreshWhitelistView()
--     local view = ns.GetView()
--     local whitelist = model:GetWhitelist()
--     local data = {}
--     for itemLink in _pairs(whitelist) do
--         local status, isGlobal = model:GetListedStatus(itemLink)
--         if status == "whitelist" then
--             _tinsert(data, {
--                 itemLink = itemLink,
--                 isGlobal = isGlobal,
--             })
--         end
--     end
--     view:RefreshWhitelist(data)
-- end

-- local function _RefreshBlacklistView()
--     local view = ns.GetView()
--     local blacklist = model:GetBlacklist()
--     local data = {}
--     for itemLink in _pairs(blacklist) do
--         local status, isGlobal = model:GetListedStatus(itemLink)
--         if status == "blacklist" then
--             _tinsert(data, {
--                 itemLink = itemLink,
--                 isGlobal = isGlobal,
--             })
--         end
--     end
--     view:RefreshBlacklist(data)
-- end


-- local function _RefreshEnchantingState()
--     local p1, p2 = _GetProfessions()
--     local s1 = p1 and _select(7, _GetProfessionInfo(p1))
--     local s2 = p2 and _select(7, _GetProfessionInfo(p2))
--     hasEnchanting = (s1 and ENCHANTING_SKILL_LINES[s1]) or (s2 and ENCHANTING_SKILL_LINES[s2]) or false
-- end

-- ---Refresh equipment sets and cache item locations for fast lookup
-- local function _RefreshEquipmentSets()
--     _wipe(equipmentSetMembers)

--     local setIDs = _GetEquipmentSetIDs()
--     if not setIDs then return end

--     for _, setID in _ipairs(setIDs) do
--         local locations = _GetItemLocations(setID)
--         if locations then
--             for _, location in _pairs(locations) do
--                 local locationData = _GetLocationData(location)
--                 if next(locationData) and locationData.isBags then
--                     local bagIndex = locationData.bag
--                     local slotIndex = locationData.slot

--                     local locationKey = _format("%d:%d", bagIndex, slotIndex)
--                     equipmentSetMembers[locationKey] = true
--                 end
--             end
--         end
--     end
-- end

-- ---Build the sell queue by scanning all bags asynchronously
-- ---@param callback function? Optional callback function(sellQueue, stats)
-- ---@return boolean success
-- ---@return string? error
-- local function _BuildSellManifest(callback)
--     if scanInProgress then
--         return false, L["error:scan_in_progress"]
--     end

--     scanInProgress = true
--     scanVersion = scanVersion + 1
--     local currentScan = scanVersion

--     _wipe(sellQueue)

--     local pendingItems = 0
--     local stats = {
--         totalItems = 0,
--         trashItems = 0,
--         skippedReasons = {}
--     }

--     local function onItemDone(reason)
--         pendingItems = pendingItems - 1

--         if reason and not stats.skippedReasons[reason] then
--             stats.skippedReasons[reason] = 0
--         end
--         if reason then
--             stats.skippedReasons[reason] = stats.skippedReasons[reason] + 1
--         end

--         if pendingItems == 0 and currentScan == scanVersion then
--             scanInProgress = false

--             if callback then
--                 callback(sellQueue, stats)
--             end
--         end
--     end

--     for _, bagIndex in _ipairs(BAG_TO_SCAN) do
--         local numSlots = _GetContainerNumSlots(bagIndex)

--         for slotIndex = 1, numSlots do
--             local info = _GetContainerItemInfo(bagIndex, slotIndex)

--             if info and info.hyperlink then
--                 stats.totalItems = stats.totalItems + 1

--                 local itemLocation = _CreateItemLocation(ItemLocation, bagIndex, slotIndex)
--                 if itemLocation:IsValid() then
--                     pendingItems = pendingItems + 1

--                     local item = _CreateItemFromLocation(Item, itemLocation)
--                     item:ContinueOnItemDataLoad(function()
--                         if currentScan ~= scanVersion then
--                             onItemDone("cancelled")
--                             return
--                         end

--                         local itemData = _GetContainerItemInfo(bagIndex, slotIndex)
--                         if not itemData or not itemData.hyperlink then
--                             onItemDone("item_gone")
--                             return
--                         end

--                         local isTrash, reason = _IsItemTrash(bagIndex, slotIndex, itemData)
--                         if isTrash then
--                             -- Fetch sell price from GetItemInfo (index 11) – this is the
--                             -- real per-item vendor price and is always available for
--                             -- vendorable items once item data is loaded.
--                             local sellPrice = _select(11, _GetItemInfo(itemData.hyperlink)) or 0

--                             _tinsert(sellQueue, {
--                                 bag   = bagIndex,
--                                 slot  = slotIndex,
--                                 id    = itemData.itemID,
--                                 link  = itemData.hyperlink,
--                                 stack = itemData.stackCount or 1,
--                                 price = sellPrice,
--                             })

--                             stats.trashItems = stats.trashItems + 1
--                         end

--                         onItemDone(reason)
--                     end)
--                 end
--             end
--         end
--     end

--     if pendingItems == 0 then
--         scanInProgress = false

--         if callback then
--             callback(sellQueue, stats)
--         end
--     end

--     return true
-- end

-- --- [ lifecycle ]======================================================================

-- function controller:Initialize()
--     base:RegisterEvent("EQUIPMENT_SETS_CHANGED", _RefreshEquipmentSets)
--     base:RegisterEvent("SKILL_LINES_CHANGED", _RefreshEnchantingState)
--     _RefreshEquipmentSets()
--     _RefreshEnchantingState()
-- end

-- function controller:Enable()
--     local view = ns.GetView()

--     -- Register view messages via AceEvent
--     base:RegisterMessage("BITFORGE_BATCHSELL_onSellRequested", function()
--         local queueCount = #sellQueue
--         local limitTo12 = model:GetPersonalArgs("limitBatchTo12")
--         local itemsToSell = limitTo12 and _min(queueCount, 12) or queueCount

--         -- Show confirmation dialog
--         _StaticPopup_Show("BITFORGE_BATCHSELL_CONFIRM", itemsToSell, _GetMoneyString(self:GetQueueValue()))
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onSellConfirmed", function()
--         self:StartSelling(
--             function(success)
--                 if success then
--                     _print(L["msg:sell_complete"])
--                 end
--                 self:RefreshManifestView()
--             end,
--             function(current, total)
--                 self:RefreshManifestView()
--             end
--         )
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onRequestManifest", function()
--         self:RefreshManifestView()
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onRequestBlacklist", function()
--         _RefreshBlacklistView()
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onRequestWhitelist", function()
--         _RefreshWhitelistView()
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onRemoveFromManifest", function(_, bag, slot)
--         self:RemoveFromQueue(bag, slot)
--         self:RefreshManifestView()
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onAddToBlacklist", function(_, itemLink, isGlobal, bag, slot)
--         model:UpdateListedStatus(itemLink, "blacklist", isGlobal)
--         if bag and slot then
--             self:RemoveFromQueue(bag, slot)
--         end
--         self:RefreshManifestView()
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onAddToWhitelist", function(_, itemLink, isGlobal, bag, slot)
--         model:UpdateListedStatus(itemLink, "whitelist", isGlobal)
--         if bag and slot then
--             self:RemoveFromQueue(bag, slot)
--         end
--         self:RefreshManifestView()
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onResetItemStatus", function(_, itemLink)
--         model:UpdateListedStatus(itemLink, nil)
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onMoveToList", function(_, itemLink, listType, isGlobal)
--         model:UpdateListedStatus(itemLink, listType, isGlobal)
--         if listType == "blacklist" then
--             _RefreshBlacklistView()
--         elseif listType == "whitelist" then
--             _RefreshWhitelistView()
--         end
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onRemoveFromList", function(_, itemLink)
--         model:UpdateListedStatus(itemLink, nil)
--         -- Refresh both lists since we don't track which tab is active
--         _RefreshBlacklistView()
--         _RefreshWhitelistView()
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onItemDropped", function(_, itemLink, listType, isGlobal)
--         model:UpdateListedStatus(itemLink, listType, isGlobal)
--         if listType == "blacklist" then
--             _RefreshBlacklistView()
--         elseif listType == "whitelist" then
--             _RefreshWhitelistView()
--         end
--     end)

--     base:RegisterMessage("BITFORGE_BATCHSELL_onSettingChanged", function(_, settingName, value)
--         model:SetPersonalArgs(settingName, value)
--         _UpdateViewSettings()
--     end)

--     -- Initialize view with current settings
--     _UpdateViewSettings()
-- end

-- function controller:Disable()
--     self:CancelScan()
-- end

-- --- [ public API ]======================================================================

-- ---Start a scan of all bags to build the sell queue
-- ---@param callback function? Optional callback(sellQueue, stats)
-- ---@return boolean success
-- ---@return string? error
-- function controller:StartScan(callback)
--     return _BuildSellManifest(callback)
-- end

-- ---Get the current sell queue
-- ---@return table sellQueue Array of items to sell
-- function controller:GetSellQueue()
--     return sellQueue
-- end

-- ---Get the total value of items in the sell queue
-- ---@return number totalValue Total copper value
-- function controller:GetQueueValue()
--     local total = 0
--     for _, item in _ipairs(sellQueue) do
--         total = total + (item.price * item.stack)
--     end
--     return total
-- end

-- ---Get the number of items in the sell queue
-- ---@return number count
-- function controller:GetQueueCount()
--     return #sellQueue
-- end

-- ---Check if a scan is currently in progress
-- ---@return boolean inProgress
-- function controller:IsScanInProgress()
--     return scanInProgress
-- end

-- ---Cancel the current scan if one is in progress
-- ---@return boolean wasCancelled
-- function controller:CancelScan()
--     if scanInProgress then
--         scanVersion = scanVersion + 1
--         scanInProgress = false
--         _wipe(sellQueue)
--         return true
--     end
--     return false
-- end

-- ---Remove an item from the sell queue
-- ---@param bagIndex number
-- ---@param slotIndex number
-- ---@return boolean removed
-- function controller:RemoveFromQueue(bagIndex, slotIndex)
--     for i, item in _ipairs(sellQueue) do
--         if item.bag == bagIndex and item.slot == slotIndex then
--             _tremove(sellQueue, i)
--             return true
--         end
--     end
--     return false
-- end

-- ---Clear the entire sell queue
-- function controller:ClearQueue()
--     _wipe(sellQueue)
-- end

-- ---Force refresh of equipment sets
-- function controller:RefreshEquipmentSets()
--     _RefreshEquipmentSets()
-- end

-- ---Start selling items from the queue
-- ---@param onComplete function? Callback when selling completes
-- ---@param onProgress function? Callback(current, total) on each item sold
-- ---@return boolean started
-- function controller:StartSelling(onComplete, onProgress)
--     if sellInProgress then return false end
--     if #sellQueue == 0 then return false end

--     sellInProgress = true
--     currentSellIndex = 0

--     local limitTo12 = model:GetPersonalArgs("limitBatchTo12")
--     local itemsToSell = limitTo12 and _min(#sellQueue, 12) or #sellQueue

--     local function sellNextItem()
--         if not sellInProgress then
--             if onComplete then onComplete(false) end
--             return
--         end

--         currentSellIndex = currentSellIndex + 1

--         if currentSellIndex > itemsToSell then
--             sellInProgress = false
--             if onComplete then onComplete(true) end
--             return
--         end

--         local item = sellQueue[currentSellIndex]
--         if item then
--             -- Verify item still exists at this location
--             local info = _GetContainerItemInfo(item.bag, item.slot)
--             if info and info.hyperlink == item.link then
--                 _UseContainerItem(item.bag, item.slot)
--             end

--             if onProgress then
--                 onProgress(currentSellIndex, itemsToSell)
--             end
--         end

--         -- Throttle sells to avoid issues
--         _After(0.1, sellNextItem)
--     end

--     sellNextItem()
--     return true
-- end

-- ---Stop selling if in progress
-- ---@return boolean wasStopped
-- function controller:StopSelling()
--     if sellInProgress then
--         sellInProgress = false
--         return true
--     end
--     return false
-- end

-- ---Check if selling is in progress
-- ---@return boolean inProgress
-- function controller:IsSellInProgress()
--     return sellInProgress
-- end

-- ---Get current sell progress
-- ---@return number current
-- ---@return number total
-- function controller:GetSellProgress()
--     return currentSellIndex, #sellQueue
-- end

-- --- [ internal helpers ]======================================================================

-- function controller:RefreshManifestView()
--     local view = ns.GetView()
--     view:RefreshManifest(sellQueue)
--     _UpdateViewSettings()
-- end

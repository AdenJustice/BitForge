local ns = select(2, ...)
local E  = BitForge.Events

function ns:Subscribe(event, fn)
    BitForge.EventBus:RegisterCallback(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.EventBus:UnregisterCallback(event, self)
end

local ipairs = ipairs
local huge = math.huge

local C_EquipmentSet = C_EquipmentSet
local C_Container = C_Container
local C_MerchantFrame = C_MerchantFrame
local C_TradeSkillUI = C_TradeSkillUI
local CreateFrame = CreateFrame

local model = ns.Model
local itemInfo = ns.ItemInfo

ns.Controller = {}
local controller = ns.Controller

-- =========================================================
-- Helpers
-- =========================================================

local _merchantOpen = false

local function BuildEquipmentSetCache()
    local cache = {}
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        for _, loc in ipairs(C_EquipmentSet.GetItemLocations(setID) or {}) do
            local data = EquipmentManager_GetLocationData(loc)
            if data.isBags then
                cache[data.bag .. ":" .. data.slot] = true
            end
        end
    end
    model.SetEquipmentSetCache(cache)
end

local function DetectEnchanting()
    local enchantingLineID = C_TradeSkillUI.GetProfessionSkillLineID(Enum.Profession.Enchanting)
    for _, lineID in ipairs(C_TradeSkillUI.GetAllProfessionTradeSkillLines()) do
        if lineID == enchantingLineID then
            model.SetIsEnchanter(true)
            return
        end
    end
    model.SetIsEnchanter(false)
end

-- =========================================================
-- Eligibility
-- =========================================================

local function IsEligible(item)
    if model.IsTempExcluded(item.itemLink) then return false end

    -- 1. Blacklist
    if item:IsProhibited() then return false end

    -- 2. Hard gates
    if item:IsLocked() then return false end
    if item:IsInEquipmentSet() then return false end
    if not item:HasSellPrice() then return false end
    if item:CanBeRefunded() then return false end

    -- 3. Whitelist override
    if item:IsEnforced() then return true end

    -- 4. Bind on Account
    if model.GetKeepBindOnAccount() and item:IsBindOnAccount() then
        if model.GetKeepBindOnAccountPastExpac() or not item:IsPastExpansion() then
            return false
        end
    end

    -- 5. Equippable branch
    if item:IsEquippableByPlayer() then
        -- 5a. Keep all equippable
        if model.GetKeepEquippable() then return false end
        -- 5b. Better than equipped
        if item:IsBetterThanEquipped() then return false end
    end

    -- 6. Disenchantable (equippable and non-equippable)
    if model.GetKeepDisenchantables() and item:IsDisenchantable() then
        if model.GetKeepDisenchantablesPastExpac() or not item:IsPastExpansion() then
            return false
        end
    end

    -- 7. Sell past expansion
    if model.GetSellPastExpansion() and item:IsPastExpansion() then return true end

    -- 8. Quality threshold
    if item.quality > model.GetQualityThreshold() then return false end

    -- 9. Default: include
    return true
end

-- =========================================================
-- Manifest
-- =========================================================

function controller.RefreshManifest()
    local items = {}
    for bag = 0, 4 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local item = itemInfo:New(bag, slot)
            if item and IsEligible(item) then
                items[#items + 1] = item
            end
        end
    end
    model.SetManifest(items)
    ns.View.MerchantPanel.Refresh()
end

-- =========================================================
-- Sell batch
-- =========================================================

function controller.SellBatch()
    local manifest = model.GetManifest()
    local count = 0
    local limit = model.GetLimitBatchTo12() and 12 or huge
    for _, item in ipairs(manifest) do
        if count >= limit then break end
        if item:Update() and not item:IsLocked() then
            C_Container.UseContainerItem(item.bagIndex, item.slotIndex)
            count = count + 1
        end
    end
end

-- =========================================================
-- Event registration
-- =========================================================

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        _merchantOpen = true
        if model.GetSellJunk() and C_MerchantFrame.IsSellAllJunkEnabled() then
            C_MerchantFrame.SellAllJunkItems()
            -- BAG_UPDATE_DELAYED will fire after items leave the bag and trigger RefreshManifest
        else
            controller.RefreshManifest()
        end
        ns.View.MerchantPanel.Show()
    elseif event == "MERCHANT_CLOSED" then
        _merchantOpen = false
        model.ClearTempExcludes()
        ns.View.MerchantPanel.Hide()
    elseif event == "BAG_UPDATE_DELAYED" then
        if _merchantOpen then
            controller.RefreshManifest()
        end
    elseif event == "EQUIPMENT_SETS_CHANGED" then
        BuildEquipmentSetCache()
    end
end)

ns:Subscribe(E.CORE_LOADED, function()
    BitForge:AllocateModuleDB("BatchSell", ns.DB_DEFAULTS, function(db)
        model.Init(db)
        frame:RegisterEvent("MERCHANT_SHOW")
        frame:RegisterEvent("MERCHANT_CLOSED")
        frame:RegisterEvent("BAG_UPDATE_DELAYED")
        frame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
    end)
end)

ns:Subscribe(E.PLAYER_READY, function()
    BuildEquipmentSetCache()
    DetectEnchanting()
end)

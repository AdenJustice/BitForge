---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local next = next

local wipe = table.wipe

local DB_DEFAULTS = {
    global = {
        -- Warband-wide list: itemID → enum.LIST_STATUS value
        list = {},
    },
    char = {
        -- Sell behaviour
        limitBatchTo12 = true,
        sellJunk = true,
        -- Keep rules
        keepEquippable = true,
        keepBindOnAccount = true,
        keepBindOnAccountPastExpac = false,
        keepDisenchantables = false,
        keepDisenchantablesPastExpac = false,
        -- Quality / ilvl filters
        qualityThreshold = 2, -- Uncommon
        ilvlThreshold = -20,
        -- Expansion filter
        sellPastExpansion = false,
        expansionThreshold = 0, -- 0 = disabled (all expansions)
        -- Character-specific list: itemID → enum.LIST_STATUS value
        list = {},
    },
}
local db

BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB)
    db = moduleDB
end)

---@class BitForge.BatchSell.Model
local model = ns.model
local enum = ns.enum

-- =========================================================
-- Settings getters / setters
-- =========================================================

function model.GetSellJunk() return db.char.sellJunk end

function model.SetSellJunk(v) db.char.sellJunk = v end

function model.GetQualityThreshold() return db.char.qualityThreshold end

function model.SetQualityThreshold(v) db.char.qualityThreshold = v end

function model.GetIlvlThreshold() return db.char.ilvlThreshold end

function model.SetIlvlThreshold(v) db.char.ilvlThreshold = v end

function model.GetKeepDisenchantables() return db.char.keepDisenchantables end

function model.SetKeepDisenchantables(v) db.char.keepDisenchantables = v end

function model.GetExpansionThreshold() return db.char.expansionThreshold end

function model.SetExpansionThreshold(v) db.char.expansionThreshold = v end

function model.GetLimitBatchTo12() return db.char.limitBatchTo12 end

function model.SetLimitBatchTo12(v) db.char.limitBatchTo12 = v end

function model.GetKeepEquippable() return db.char.keepEquippable end

function model.SetKeepEquippable(v) db.char.keepEquippable = v end

function model.GetKeepBindOnAccount() return db.char.keepBindOnAccount end

function model.SetKeepBindOnAccount(v) db.char.keepBindOnAccount = v end

function model.GetKeepBindOnAccountPastExpac() return db.char.keepBindOnAccountPastExpac end

function model.SetKeepBindOnAccountPastExpac(v) db.char.keepBindOnAccountPastExpac = v end

function model.GetKeepDisenchantablesPastExpac() return db.char.keepDisenchantablesPastExpac end

function model.SetKeepDisenchantablesPastExpac(v) db.char.keepDisenchantablesPastExpac = v end

function model.GetSellPastExpansion() return db.char.sellPastExpansion end

function model.SetSellPastExpansion(v) db.char.sellPastExpansion = v end

-- =========================================================
-- List management
-- =========================================================
--
-- Each scope keeps one table, itemID → enum.LIST_STATUS value. One value per
-- item per scope is what makes blacklist and whitelist mutually exclusive:
-- writing a status overwrites whatever was there, so there is no second flag
-- left to contradict it.
--
-- Warband-wide entries live in db.global, character-specific ones in db.char.
-- enum.LIST_SCOPE's values are those key names, so a scope indexes db directly.
--
-- Keys are itemIDs, not item links: a link carries bonus IDs, so link keys would
-- treat two upgrades of the same item as unrelated entries.

--- @param itemID number
--- @param scope string  enum.LIST_SCOPE value
--- @return string|nil   enum.LIST_STATUS value, or nil when unset
function model.GetStatus(itemID, scope)
    return db[scope].list[itemID]
end

--- @param itemID number
--- @param scope  string      enum.LIST_SCOPE value
--- @param status string|nil  enum.LIST_STATUS value; nil removes the entry
function model.SetStatus(itemID, scope, status)
    db[scope].list[itemID] = status or nil
end

--- The status that actually governs this item for this character.
--- Character scope wins outright whichever way it points — a character
--- whitelist beats a warband blacklist just as a character blacklist beats a
--- warband whitelist. Global applies only where the character has no entry.
--- @param itemID number
--- @return string|nil  enum.LIST_STATUS value, or nil when neither scope holds one
function model.GetEffectiveStatus(itemID)
    return model.GetStatus(itemID, enum.LIST_SCOPE.CHAR)
        or model.GetStatus(itemID, enum.LIST_SCOPE.GLOBAL)
end

--- True when both scopes hold a status and they disagree, meaning the character
--- entry is actively overriding the warband one. The merchant panel marks these
--- rows: an item reaching the sell list despite a warband blacklist is worth
--- pointing at before the player presses Sell.
--- @param itemID number
--- @return boolean
function model.HasCharOverride(itemID)
    local charStatus = model.GetStatus(itemID, enum.LIST_SCOPE.CHAR)
    if not charStatus then return false end
    local globalStatus = model.GetStatus(itemID, enum.LIST_SCOPE.GLOBAL)
    return globalStatus ~= nil and globalStatus ~= charStatus
end

--- Removes every entry of one status from one scope, leaving the other status's
--- entries in that scope alone — both now share a single table, so wiping it
--- would clear a list the player did not ask to reset.
--- @param scope  string  enum.LIST_SCOPE value
--- @param status string  enum.LIST_STATUS value
function model.ClearList(scope, status)
    local list = db[scope].list
    for itemID, entry in next, list do
        if entry == status then
            list[itemID] = nil
        end
    end
end

-- =========================================================
-- Equipment set cache  (populated by Controller, queried by the scanner)
-- =========================================================

local equipmentSetCache = {}

--- @param cache table<string, true>  bagSlotKey → true
function model.SetEquipmentSetCache(cache)
    equipmentSetCache = cache
end

--- @param bagSlotKey string  "bagIndex:slotIndex"
--- @return boolean
function model.IsInEquipmentSet(bagSlotKey)
    return equipmentSetCache[bagSlotKey] == true
end

-- =========================================================
-- Enchanting cache  (populated by Controller)
-- =========================================================

local isEnchanter = false

--- @param value boolean
function model.SetIsEnchanter(value)
    isEnchanter = value
end

-- =========================================================
-- Manifest  (in-memory, not persisted)
-- =========================================================

local manifest = {}

function model.SetManifest(items)
    manifest = items
end

function model.GetManifest()
    return manifest
end

function model.GetManifestCount()
    return #manifest
end

function model.GetManifestTotalValue()
    local total = 0
    for _, item in ipairs(manifest) do
        total = total + model.GetTotalSellValue(item)
    end
    return total
end

-- =========================================================
-- Temporary excludes  (cleared on MERCHANT_CLOSED)
-- =========================================================

local tempExcludes = {}

function model.AddTempExclude(itemLink)
    tempExcludes[itemLink] = true
end

function model.IsTempExcluded(itemLink)
    return tempExcludes[itemLink] == true
end

function model.ClearTempExcludes()
    wipe(tempExcludes)
end

-- ================================================================================
-- Player class cache  (populated by Controller)
-- ================================================================================

local playerClass

--- @param value string  Class filename, e.g. "WARRIOR"
function model.SetPlayerClass(value)
    playerClass = value
end

-- ================================================================================
-- Decision core
-- ================================================================================
--
-- Everything below is pure: no API calls, no frame access, no db reads. Facts
-- arrive as a plain table gathered by ns.control.scanner, settings as a snapshot
-- from model.GetSettingsSnapshot. That is what lets the cascade be tested outside
-- the game.

--- @return number
function model.GetTotalSellValue(facts)
    return facts.sellPrice * facts.stackCount
end

--- True when the item predates the configured expansion threshold.
--- A threshold of 0 disables the check.
function model.IsPastExpansion(facts, expansionThreshold)
    if expansionThreshold == 0 then return false end
    return facts.expacID < expansionThreshold
end

--- True when the item is within ilvlThreshold of ANY item equipped in a slot it
--- could occupy. ilvlThreshold is negative, so this means "not more than N item
--- levels worse than something already equipped there" — worth keeping.
---
--- Existential over slots, exactly as the original loop was: for the dual slots
--- (rings 11/12, trinkets 13/14) an item only has to be close to the weaker of
--- the two equipped items, not the stronger. Comparing against the highest would
--- sell rings the current addon keeps.
---
--- Renamed from IsBetterThanEquipped, which stated the opposite of what it tested.
function model.IsCloseToEquipped(facts, ilvlThreshold)
    local equippedIlvls = facts.equippedIlvls
    if not equippedIlvls then return false end
    for _, equippedIlvl in ipairs(equippedIlvls) do
        if facts.level >= (equippedIlvl + ilvlThreshold) then
            return true
        end
    end
    return false
end

--- True when the item is worth keeping to disenchant or resell:
--- enchanters get value from BoP as well; everyone else only from BoE and BoA.
function model.IsDisenchantable(facts, isEnchanter)
    if facts.quality < Enum.ItemQuality.Uncommon then return false end
    if facts.classID ~= Enum.ItemClass.Armor and facts.classID ~= Enum.ItemClass.Weapon then
        return false
    end
    if enum.NON_DISENCHANTABLE_IDS[tostring(facts.itemID)] then return false end

    local bindType = facts.bindType
    if isEnchanter then
        return bindType == enum.BIND_TYPE.ON_PICKUP
            or bindType == enum.BIND_TYPE.ON_EQUIP
            or bindType == enum.BIND_TYPE.ON_ACCOUNT
    end
    return bindType == enum.BIND_TYPE.ON_EQUIP
        or bindType == enum.BIND_TYPE.ON_ACCOUNT
end

--- True when the given class can equip the item.
function model.IsEquippableBy(facts, playerClassName)
    if not facts.equipLoc or facts.equipLoc == "" then return false end

    local prefs = enum.CLASS_PREFS[playerClassName]
    if not prefs then return false end

    -- Off-hand slots are separate equip restrictions, not armor subclasses.
    if facts.equipLoc == "INVTYPE_SHIELD" then return prefs.Shield == true end
    if facts.equipLoc == "INVTYPE_HOLDABLE" then return prefs.Holdable == true end

    if facts.classID == Enum.ItemClass.Armor then
        for _, armorSubclass in ipairs(prefs.Armor) do
            if facts.subclassID == armorSubclass then return true end
        end
        -- Generic and cosmetic armor is equippable by everyone.
        if facts.subclassID == Enum.ItemArmorSubclass.Generic
            or facts.subclassID == Enum.ItemArmorSubclass.Cosmetic then
            return true
        end
        return false
    end

    if facts.classID == Enum.ItemClass.Weapon then
        for _, weaponSubclass in ipairs(prefs.Weapons) do
            if facts.subclassID == weaponSubclass then return true end
        end
        return false
    end

    return true
end

--- Decides whether one item should be sold.
--- Pure: no API calls, no frame access, no db reads.
---@param facts    table  One item's gathered facts
---@param settings table  Snapshot from model.GetSettingsSnapshot
---@return string verdict  enum.DECISION.SELL or enum.DECISION.KEEP
---@return string rule     enum.RULE.* — which step decided
function model.Decide(facts, settings)
    local DECISION, RULE = enum.DECISION, enum.RULE

    -- 0. Excluded for this merchant visit only.
    if facts.isTempExcluded then return DECISION.KEEP, RULE.TEMP_EXCLUDED end

    -- 1. Blacklist, either scope.
    if facts.isProhibited then return DECISION.KEEP, RULE.BLACKLISTED end

    -- 2. Hard gates. These are not overridable by the whitelist.
    if facts.isLocked then return DECISION.KEEP, RULE.LOCKED end
    if facts.inEquipmentSet then return DECISION.KEEP, RULE.EQUIPMENT_SET end
    if facts.sellPrice <= 0 then return DECISION.KEEP, RULE.NO_SELL_PRICE end
    if facts.isRefundable then return DECISION.KEEP, RULE.REFUNDABLE end

    -- 3. Whitelist override.
    if facts.isEnforced then return DECISION.SELL, RULE.WHITELISTED end

    -- Computed once; steps 4, 6, and 7 all consult it.
    local isPastExpansion = model.IsPastExpansion(facts, settings.expansionThreshold)

    -- 4. Bind on Account.
    if settings.keepBindOnAccount and facts.bindType == enum.BIND_TYPE.ON_ACCOUNT then
        if settings.keepBindOnAccountPastExpac or not isPastExpansion then
            return DECISION.KEEP, RULE.BIND_ON_ACCOUNT
        end
    end

    -- 5. Equippable branch.
    if model.IsEquippableBy(facts, settings.playerClass) then
        if settings.keepEquippable then return DECISION.KEEP, RULE.EQUIPPABLE end
        if model.IsCloseToEquipped(facts, settings.ilvlThreshold) then
            return DECISION.KEEP, RULE.CLOSE_TO_EQUIPPED
        end
    end

    -- 6. Disenchantable, equippable or not.
    if settings.keepDisenchantables and model.IsDisenchantable(facts, settings.isEnchanter) then
        if settings.keepDisenchantablesPastExpac or not isPastExpansion then
            return DECISION.KEEP, RULE.DISENCHANTABLE
        end
    end

    -- 7. Sell past expansion. Deliberately short-circuits the quality threshold.
    if settings.sellPastExpansion and isPastExpansion then
        return DECISION.SELL, RULE.PAST_EXPANSION
    end

    -- 8. Quality threshold.
    if facts.quality > settings.qualityThreshold then
        return DECISION.KEEP, RULE.QUALITY_THRESHOLD
    end

    -- 9. Default: sell.
    return DECISION.SELL, RULE.DEFAULT
end

-- ================================================================================
-- Settings snapshot  (impure — reads the db)
-- ================================================================================

--- Reads the nine settings the cascade consults, once per scan rather than per
--- item. sellJunk and limitBatchTo12 are deliberately absent: they govern the
--- merchant visit and the sell loop, not the per-item decision.
---@return table
function model.GetSettingsSnapshot()
    return {
        keepEquippable               = db.char.keepEquippable,
        keepBindOnAccount            = db.char.keepBindOnAccount,
        keepBindOnAccountPastExpac   = db.char.keepBindOnAccountPastExpac,
        keepDisenchantables          = db.char.keepDisenchantables,
        keepDisenchantablesPastExpac = db.char.keepDisenchantablesPastExpac,
        qualityThreshold             = db.char.qualityThreshold,
        ilvlThreshold                = db.char.ilvlThreshold,
        sellPastExpansion            = db.char.sellPastExpansion,
        expansionThreshold           = db.char.expansionThreshold,
        isEnchanter                  = isEnchanter,
        playerClass                  = playerClass,
    }
end

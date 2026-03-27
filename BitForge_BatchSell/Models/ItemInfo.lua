local _, ns       = ...

local Model       = ns.Model

-- =========================================================
-- Class preferences: which armor/weapon types each class can use
-- =========================================================

local CLASS_PREFS = {
    WARRIOR = {
        Armor    = { Enum.ItemArmorSubclass.Plate },
        Shield   = true,
        Holdable = false,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Axe2H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Sword2H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Mace2H,
            Enum.ItemWeaponSubclass.Polearm,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Unarmed,
        },
    },
    PALADIN = {
        Armor    = { Enum.ItemArmorSubclass.Plate },
        Shield   = true,
        Holdable = false,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Axe2H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Sword2H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Mace2H,
            Enum.ItemWeaponSubclass.Polearm,
        },
    },
    HUNTER = {
        Armor    = { Enum.ItemArmorSubclass.Mail },
        Shield   = false,
        Holdable = false,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Axe2H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Sword2H,
            Enum.ItemWeaponSubclass.Polearm,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Unarmed,
            Enum.ItemWeaponSubclass.Bows,
            Enum.ItemWeaponSubclass.Crossbow,
            Enum.ItemWeaponSubclass.Guns,
        },
    },
    ROGUE = {
        Armor    = { Enum.ItemArmorSubclass.Leather },
        Shield   = false,
        Holdable = false,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Unarmed,
        },
    },
    PRIEST = {
        Armor    = { Enum.ItemArmorSubclass.Cloth },
        Shield   = false,
        Holdable = true,
        Weapons  = {
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Wand,
        },
    },
    DEATHKNIGHT = {
        Armor    = { Enum.ItemArmorSubclass.Plate },
        Shield   = false,
        Holdable = false,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Axe2H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Sword2H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Mace2H,
            Enum.ItemWeaponSubclass.Polearm,
        },
    },
    SHAMAN = {
        Armor    = { Enum.ItemArmorSubclass.Mail },
        Shield   = true,
        Holdable = true,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Axe2H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Mace2H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Unarmed,
            Enum.ItemWeaponSubclass.Staff,
        },
    },
    MAGE = {
        Armor    = { Enum.ItemArmorSubclass.Cloth },
        Shield   = false,
        Holdable = true,
        Weapons  = {
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Wand,
        },
    },
    WARLOCK = {
        Armor    = { Enum.ItemArmorSubclass.Cloth },
        Shield   = false,
        Holdable = true,
        Weapons  = {
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Wand,
        },
    },
    MONK = {
        Armor    = { Enum.ItemArmorSubclass.Leather },
        Shield   = false,
        Holdable = true,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Unarmed,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Polearm,
        },
    },
    DRUID = {
        Armor    = { Enum.ItemArmorSubclass.Leather },
        Shield   = false,
        Holdable = true,
        Weapons  = {
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Mace2H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Unarmed,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Polearm,
        },
    },
    DEMONHUNTER = {
        Armor    = { Enum.ItemArmorSubclass.Leather },
        Shield   = false,
        Holdable = false,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Unarmed,
            Enum.ItemWeaponSubclass.Warglaive,
        },
    },
    EVOKER = {
        Armor    = { Enum.ItemArmorSubclass.Mail },
        Shield   = false,
        Holdable = true,
        Weapons  = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Unarmed,
            Enum.ItemWeaponSubclass.Staff,
        },
    },
}

-- =========================================================
-- Slot mappings
-- =========================================================

local SLOT_MAP    = {
    INVTYPE_HEAD           = 1,
    INVTYPE_NECK           = 2,
    INVTYPE_SHOULDER       = 3,
    INVTYPE_BODY           = 4,
    INVTYPE_CHEST          = 5,
    INVTYPE_ROBE           = 5,
    INVTYPE_WAIST          = 6,
    INVTYPE_LEGS           = 7,
    INVTYPE_FEET           = 8,
    INVTYPE_WRIST          = 9,
    INVTYPE_HAND           = 10,
    INVTYPE_FINGER         = 11,
    INVTYPE_TRINKET        = 13,
    INVTYPE_CLOAK          = 15,
    INVTYPE_WEAPON         = 16,
    INVTYPE_SHIELD         = 17,
    INVTYPE_2HWEAPON       = 16,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND  = 17,
    INVTYPE_HOLDABLE       = 17,
    INVTYPE_RANGED         = 18,
    INVTYPE_THROWN         = 18,
    INVTYPE_RANGEDRIGHT    = 18,
    INVTYPE_RELIC          = 18,
}

-- Slots that may have two equipped items
local DUAL_SLOTS  = {
    INVTYPE_FINGER  = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
}

-- Merged lookup: invType → slot array (avoids per-call table allocation in IsBetterThanEquipped)
local SLOT_LOOKUP = {}
do
    for invType, slots in next, DUAL_SLOTS do
        SLOT_LOOKUP[invType] = slots
    end
    for invType, slotID in next, SLOT_MAP do
        if not SLOT_LOOKUP[invType] then
            SLOT_LOOKUP[invType] = { slotID }
        end
    end
end

-- =========================================================
-- ItemInfo class
-- =========================================================

local ItemInfo                  = {}
ItemInfo.__index                = ItemInfo
ns.ItemInfo                     = ItemInfo

local _playerClass -- cached on first use; class never changes mid-session
local _GetItemInfo              = C_Item.GetItemInfo
local _GetDetailedItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local _IsItemDataCached         = C_Item.IsItemDataCached
local _GetContainerItemInfo     = C_Container.GetContainerItemInfo
local _GetInventoryItemLink     = GetInventoryItemLink
local _format                   = string.format

--- @param bagIndex number
--- @param slotIndex number
--- @return ItemInfo|nil
function ItemInfo:New(bagIndex, slotIndex)
    local location = ItemLocation:CreateFromBagAndSlot(bagIndex, slotIndex) --[[@as ItemLocation]]
    if not location:IsValid() then return nil end
    if not _IsItemDataCached(location) then return nil end

    local slotInfo = _GetContainerItemInfo(bagIndex, slotIndex)
    if not slotInfo then return nil end

    local itemID = slotInfo.itemID
    if not itemID then return nil end

    local hyperlink = slotInfo.hyperlink
    local name, itemLink, quality, _, _, _, _, _, equipLoc, _, sellPrice, classID, subclassID, bindType, expacID = _GetItemInfo(hyperlink)
    if not name then return nil end

    local obj      = setmetatable({}, ItemInfo)
    obj.bagIndex   = bagIndex
    obj.slotIndex  = slotIndex
    obj.itemLink   = itemLink or hyperlink
    obj.itemID     = itemID
    obj.name       = name
    obj.quality    = quality
    obj.sellPrice  = sellPrice or 0
    obj.stackCount = slotInfo.stackCount or 1
    obj.isLocked   = slotInfo.isLocked
    obj.equipLoc   = equipLoc
    obj.classID    = classID
    obj.subclassID = subclassID
    obj.bindType   = bindType
    obj.expacID    = expacID or 0

    -- Fetch item level
    local ilvl     = _GetDetailedItemLevelInfo(obj.itemLink)
    obj.level      = ilvl or 0

    -- Refundable / tradeable flags from tooltip data
    obj.refundable = slotInfo.hasNoValue == true -- approximate via hasNoValue
    obj.isFiltered = slotInfo.isFiltered

    return obj --[[@as ItemInfo]]
end

--- Refresh mutable state (lock status, stack count) without creating a new object.
--- @return boolean  false if the slot is now empty
function ItemInfo:Update()
    local slotInfo = _GetContainerItemInfo(self.bagIndex, self.slotIndex)
    if not slotInfo or slotInfo.itemID ~= self.itemID then return false end
    self.isLocked   = slotInfo.isLocked
    self.stackCount = slotInfo.stackCount or 1
    return true
end

--- @return string  "bagIndex:slotIndex"
function ItemInfo:GetBagSlotKey()
    return _format("%d:%d", self.bagIndex, self.slotIndex)
end

--- @return number
function ItemInfo:GetTotalSellValue()
    return self.sellPrice * self.stackCount
end

-- =========================================================
-- Hard-gate checks
-- =========================================================

function ItemInfo:IsLocked()
    return self.isLocked == true
end

function ItemInfo:IsInEquipmentSet()
    return Model.IsInEquipmentSet(self:GetBagSlotKey())
end

function ItemInfo:HasSellPrice()
    return self.sellPrice > 0
end

--- Items sold recently that can still be refunded have hasNoValue set in ContainerItemInfo.
function ItemInfo:CanBeRefunded()
    return self.refundable == true
end

--- bindType 4 = Bind on Account (BoA); players generally want to keep these.
function ItemInfo:IsBindOnAccount()
    return self.bindType == 4
end

-- =========================================================
-- List checks
-- =========================================================

--- Returns true if the item is in the warband blacklist OR the character blacklist.
function ItemInfo:IsProhibited()
    return Model.IsEnlisted(self.itemLink, "blacklist")
        or Model.IsEnlisted(self.itemLink, "charBlacklist")
end

--- Returns true if the item is in the warband whitelist OR the character whitelist.
function ItemInfo:IsEnforced()
    return Model.IsEnlisted(self.itemLink, "whitelist")
        or Model.IsEnlisted(self.itemLink, "charWhitelist")
end

-- =========================================================
-- Optional filter checks
-- =========================================================

--- Returns true when the item is worth keeping for disenchanting/AH/alts:
--- - Enchanter: Uncommon+ Armor/Weapon, BOP/BOE/BOA, not in exception list
--- - Non-enchanter: Uncommon+ Armor/Weapon, BOE/BOA only (BOP has no value without DE)
function ItemInfo:IsDisenchantable()
    if self.quality < Enum.ItemQuality.Uncommon then return false end
    if self.classID ~= Enum.ItemClass.Armor and self.classID ~= Enum.ItemClass.Weapon then return false end
    local idStr = tostring(self.itemID)
    if ns.NON_DISENCHANTABLE_IDS[idStr] then return false end

    if Model.IsEnchanter() then
        -- BOP=1, BOE=2, BOA=4
        return self.bindType == 1 or self.bindType == 2 or self.bindType == 4
    else
        -- Non-enchanter: BOE for AH, BOA for alts
        return self.bindType == 2 or self.bindType == 4
    end
end

--- Returns true when the item is at least as good as the equipped item(s) within the
--- configured ilvl margin.  Formula: itemIlvl >= equippedIlvl + threshold  (threshold < 0).
--- When true, the item is worth keeping → IsEligible should return false.
function ItemInfo:IsBetterThanEquipped()
    local slots = SLOT_LOOKUP[self.equipLoc]
    if not slots then return false end

    local threshold = Model.GetIlvlThreshold() -- negative value e.g. -20
    for _, slotID in ipairs(slots) do
        local equippedLink = _GetInventoryItemLink("player", slotID)
        if equippedLink then
            local equippedIlvl = _GetDetailedItemLevelInfo(equippedLink)
            if equippedIlvl and self.level >= (equippedIlvl + threshold) then
                return true
            end
        end
    end
    return false
end

--- Returns true if the item comes from an expansion older than the configured threshold.
--- expansionThreshold = 0 means disabled.
function ItemInfo:IsPastExpansion()
    local threshold = Model.GetExpansionThreshold()
    if threshold == 0 then return false end
    return self.expacID < threshold
end

--- Returns true if the item is equippable by the current player's class.
function ItemInfo:IsEquippableByPlayer()
    if not self.equipLoc or self.equipLoc == "" then return false end
    if not _playerClass then _, _playerClass = UnitClassBase("player") end
    local prefs = CLASS_PREFS[_playerClass]
    if not prefs then return false end

    -- Off-hand checks (shield and holdable are separate equip restrictions)
    if self.equipLoc == "INVTYPE_SHIELD" then
        return prefs.Shield == true
    end
    if self.equipLoc == "INVTYPE_HOLDABLE" then
        return prefs.Holdable == true
    end

    -- Armor check
    if self.classID == Enum.ItemClass.Armor then
        for _, armorSubclass in ipairs(prefs.Armor) do
            if self.subclassID == armorSubclass then return true end
        end
        -- Generic/Misc armor (cosmetic) is equippable by everyone
        if self.subclassID == Enum.ItemArmorSubclass.Generic
            or self.subclassID == Enum.ItemArmorSubclass.Cosmetic then
            return true
        end
        return false
    end

    -- Weapon check
    if self.classID == Enum.ItemClass.Weapon then
        for _, weaponSubclass in ipairs(prefs.Weapons) do
            if self.subclassID == weaponSubclass then return true end
        end
        return false
    end

    return true
end

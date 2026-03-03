--- @type ns.BatchSell
local ns = select(2, ...)
local params = ns.params
--- @class BitForge.Models.BatchSell
local model = ns.model

--- =========================================================
--- Caches
--- =========================================================

local _next = next
local _format = string.format
local _setmetatable = setmetatable
local _min = math.min

local _GetProfessions = GetProfessions
local _GetProfessionInfo = GetProfessionInfo
local _GetContainerItemInfo = C_Container.GetContainerItemInfo
local _GetItemInfo = C_Item.GetItemInfo
local _GetItemLevelInfo = C_Item.GetDetailedItemLevelInfo
local _CanBeRefunded = C_Item.CanBeRefunded
local _GetInventoryItemLink = GetInventoryItemLink

local _ITEM_CLASS = Enum.ItemClass
local _WEAPONS = Enum.ItemWeaponSubclass
local _ARMORS = Enum.ItemArmorSubclass

local curExpansionID = GetExpansionLevel()

--- =========================================================
--- Constants
--- =========================================================

-- Per-class equipment preferences.
-- Fields:
--   Armor  – the armor type the class wears
--   Shield         – true if the class can equip shields (nil otherwise)
--   Weapons        – map of equippable weapon subclasses (including Generic for off-hand frills)
-- NOTE: Shield is a separate field because _ARMORS.Shield == _WEAPONS.Polearm == 6
local CLASS_PREFS = {
    WARRIOR = {
        Armor = _ARMORS.Plate,
        Shield = true,
        Weapons = {
            [_WEAPONS.Axe1H]   = true, -- 0
            [_WEAPONS.Axe2H]   = true, -- 1
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Mace2H]  = true, -- 5
            [_WEAPONS.Polearm] = true, -- 6
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Sword2H] = true, -- 8
            -- [_WEAPONS.Unarmed] = true, -- 13 Unarmed with strength???
        },
    },
    PALADIN = {
        Armor = _ARMORS.Plate,
        Shield = true,
        Weapons = {
            [_WEAPONS.Axe1H]   = true, -- 0
            [_WEAPONS.Axe2H]   = true, -- 1
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Mace2H]  = true, -- 5
            [_WEAPONS.Polearm] = true, -- 6
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Sword2H] = true, -- 8
            -- [_WEAPONS.Generic] = true, -- can equip off-hand frills but usually use shields
        },
    },
    DEATHKNIGHT = {
        Armor = _ARMORS.Plate,
        Weapons = {
            [_WEAPONS.Axe1H]   = true, -- 0
            [_WEAPONS.Axe2H]   = true, -- 1
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Mace2H]  = true, -- 5
            [_WEAPONS.Polearm] = true, -- 6
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Sword2H] = true, -- 8
        },
    },
    HUNTER = {
        Armor = _ARMORS.Mail,
        Weapons = {
            [_WEAPONS.Axe1H]    = true, -- 0
            [_WEAPONS.Axe2H]    = true, -- 1
            [_WEAPONS.Bows]     = true, -- 2
            [_WEAPONS.Guns]     = true, -- 3
            [_WEAPONS.Mace1H]   = true, -- 4
            [_WEAPONS.Mace2H]   = true, -- 5
            [_WEAPONS.Polearm]  = true, -- 6
            [_WEAPONS.Sword1H]  = true, -- 7
            [_WEAPONS.Sword2H]  = true, -- 8
            [_WEAPONS.Staff]    = true, -- 10
            [_WEAPONS.Unarmed]  = true, -- 13
            [_WEAPONS.Dagger]   = true, -- 15
            [_WEAPONS.Crossbow] = true, -- 17
        },
    },
    SHAMAN = {
        Armor = _ARMORS.Mail,
        Shield = true,
        Weapons = {
            [_WEAPONS.Axe1H]   = true, -- 0
            [_WEAPONS.Axe2H]   = true, -- 1
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Mace2H]  = true, -- 5
            [_WEAPONS.Staff]   = true, -- 10
            [_WEAPONS.Unarmed] = true, -- 13
            [_WEAPONS.Dagger]  = true, -- 15
            [_WEAPONS.Generic] = true, -- can equip off-hand frills
        },
    },
    ROGUE = {
        Armor = _ARMORS.Leather,
        Weapons = {
            [_WEAPONS.Axe1H]   = true, -- 0
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Unarmed] = true, -- 13
            [_WEAPONS.Dagger]  = true, -- 15
        },
    },
    DRUID = {
        Armor = _ARMORS.Leather,
        Weapons = {
            [_WEAPONS.Mace1H]   = true, -- 4
            [_WEAPONS.Mace2H]   = true, -- 5
            [_WEAPONS.Polearm]  = true, -- 6
            [_WEAPONS.Staff]    = true, -- 10
            [_WEAPONS.Bearclaw] = true, -- 11
            [_WEAPONS.Catclaw]  = true, -- 12
            [_WEAPONS.Unarmed]  = true, -- 13
            [_WEAPONS.Dagger]   = true, -- 15
            [_WEAPONS.Generic]  = true, -- can equip off-hand frills
        },
    },
    MONK = {
        Armor = _ARMORS.Leather,
        Weapons = {
            [_WEAPONS.Axe1H]   = true, -- 0
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Polearm] = true, -- 6
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Staff]   = true, -- 10
            [_WEAPONS.Unarmed] = true, -- 13
            [_WEAPONS.Generic] = true, -- can equip off-hand frills
        },
    },
    DEMONHUNTER = {
        Armor = _ARMORS.Leather,
        Weapons = {
            [_WEAPONS.Axe1H]     = true, -- 0
            [_WEAPONS.Sword1H]   = true, -- 7
            [_WEAPONS.Warglaive] = true, -- 9
            [_WEAPONS.Unarmed]   = true, -- 13
        },
    },
    MAGE = {
        Armor = _ARMORS.Cloth,
        Weapons = {
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Staff]   = true, -- 10
            [_WEAPONS.Dagger]  = true, -- 15
            [_WEAPONS.Wand]    = true, -- 18
            [_WEAPONS.Generic] = true, -- can equip off-hand frills
        },
    },
    PRIEST = {
        Armor = _ARMORS.Cloth,
        Weapons = {
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Staff]   = true, -- 10
            [_WEAPONS.Dagger]  = true, -- 15
            [_WEAPONS.Wand]    = true, -- 18
            [_WEAPONS.Generic] = true, -- can equip off-hand frills
        },
    },
    WARLOCK = {
        Armor = _ARMORS.Cloth,
        Weapons = {
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Staff]   = true, -- 10
            [_WEAPONS.Dagger]  = true, -- 15
            [_WEAPONS.Wand]    = true, -- 18
            [_WEAPONS.Generic] = true, -- can equip off-hand frills
        },
    },
    EVOKER = {
        Armor = _ARMORS.Mail,
        Weapons = {
            [_WEAPONS.Axe1H]   = true, -- 0
            [_WEAPONS.Axe2H]   = true, -- 1
            [_WEAPONS.Mace1H]  = true, -- 4
            [_WEAPONS.Mace2H]  = true, -- 5
            [_WEAPONS.Sword1H] = true, -- 7
            [_WEAPONS.Sword2H] = true, -- 8
            [_WEAPONS.Staff]   = true, -- 10
            [_WEAPONS.Unarmed] = true, -- 13
            [_WEAPONS.Dagger]  = true, -- 15
            [_WEAPONS.Generic] = true, -- can equip off-hand frills
        },
    },
}
local playerPrefs = CLASS_PREFS[params.character.class]

-- Slot mapping for equipment comparison
local SLOT_MAP = {
    INVTYPE_HEAD           = 1,
    INVTYPE_NECK           = 2,
    INVTYPE_SHOULDER       = 3,
    INVTYPE_BODY           = 4,
    INVTYPE_CHEST          = 5,
    INVTYPE_ROBE           = 5, -- Cloth chest pieces share the chest slot
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

-- Dual slot handling (rings and trinkets)
local DUAL_SLOTS = {
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
}


--- =========================================================
--- Item Info Class
--- =========================================================

--- @class BitForgeItemInfo
--- @field bagIndex number
--- @field slotIndex number
--- @field itemID number
--- @field itemLink string
--- @field itemLocation ItemLocation
--- @field containerInfo ContainerItemInfo
--- @field itemInfoSet table { GetItemInfo() }

local BitForgeItemInfo = {}
BitForgeItemInfo.__index = BitForgeItemInfo

do
    --- Factory method to create a BitForgeItemInfo from bag and slot indices
    --- @param bagIndex number
    --- @param slotIndex number
    --- @return BitForgeItemInfo? info Returns a BitForgeItemInfo object or nil
    function BitForgeItemInfo:New(bagIndex, slotIndex)
        --- empty slot
        local itemLocation = ItemLocation:CreateFromBagAndSlot(bagIndex, slotIndex) --[[@as ItemLocation]]
        if not itemLocation:IsValid() then return end

        local containerItemInfo = _GetContainerItemInfo(bagIndex, slotIndex)
        local itemLink = containerItemInfo.hyperlink
        local itemData = { _GetItemInfo(itemLink) }
        itemData[4] = _GetItemLevelInfo(itemLink)


        ---@debug not loaded yet?
        if not _next(itemData) then
            print("Item data not loaded for " .. itemLink)
            return
        end

        local obj = {
            bagIndex = bagIndex,
            slotIndex = slotIndex,
            itemLocation = itemLocation,
            itemID = containerItemInfo.itemID,
            itemLink = itemLink,
            containerInfo = containerItemInfo,
            itemInfoSet = itemData,
        }

        _setmetatable(obj, self)
        return obj
    end

    function BitForgeItemInfo:Update()
        --- is it empty now?
        if not self.itemLocation:IsValid() then return false end

        local containerInfo = _GetContainerItemInfo(self.bagIndex, self.slotIndex)
        --- another item?
        if self.itemLink ~= containerInfo.hyperlink then return false end
        --- same item but need to update info like lock status
        --- note: item info like name, quality, etc. won't change while in bags, so we can skip updating those for performance
        self.containerInfo = containerInfo

        return true
    end

    function BitForgeItemInfo:GetBagSlotKey()
        return _format("%d:%d", self.bagIndex, self.slotIndex)
    end

    --- Check if the item is listed in the blacklist (prohibited to sell)
    --- @return boolean isProhibitedToSell
    function BitForgeItemInfo:IsProhibitedToSell()
        return model:GetListedStatus(self.itemLink) == "blacklist"
    end

    --- Check if the item is currently locked (e.g. being moved or used)
    --- @return boolean isLocked
    function BitForgeItemInfo:IsLocked()
        return not not self.containerItemInfo.isLocked
    end

    --- Check if item is part of any equipment set
    --- @return boolean isInSet
    function BitForgeItemInfo:IsInEquipmentSet()
        return model:IsInEquipmentSet(self.bagSlotKey)
    end

    --- Check if the item has a vendor sell price greater than 0
    --- @return boolean hasSellPrice
    function BitForgeItemInfo:HasSellPrice()
        local sellPrice = self.itemInfo[11]

        return sellPrice and sellPrice > 0
    end

    --- Check if the item is still refundable (i.e. within refund window)
    --- @return boolean isRefundable
    function BitForgeItemInfo:CanBeRefunded()
        return _CanBeRefunded(self.itemLocation)
    end

    --- Check if the item is listed in the whitelist (enforced to sell)
    --- @return boolean isEnforcedToSell
    function BitForgeItemInfo:IsEnforcedToSell()
        return model:GetListedStatus(self.itemLink) == "whitelist"
    end

    --- Check if the item has higher quality than a given threshold
    --- @param baseQuality number Quality threshold
    --- @return boolean hasBetterQuality
    function BitForgeItemInfo:HasBetterQuality(baseQuality)
        local quality = self.itemInfo[3]
        return quality and quality > baseQuality
    end

    function BitForgeItemInfo:IsWeapon()
        return self.itemInfo[12] == _ITEM_CLASS.Weapon
    end

    function BitForgeItemInfo:IsArmor()
        return self.itemInfo[12] == _ITEM_CLASS.Armor
    end

    --- Check if the item can be equipped by the player's class based on its subclass and type
    --- @return boolean isEquippable
    function BitForgeItemInfo:IsEquippableByPlayer()
        if not playerPrefs then return false end

        local itemSubClass = self.itemInfo[13]
        if not itemSubClass then return false end

        local equipLocation = self.itemInfo[9]
        if not (equipLocation and SLOT_MAP[equipLocation]) then return false end

        if self:IsArmor() then
            if itemSubClass == _ARMORS.Shield then
                return not not playerPrefs.Shield
            end
            return itemSubClass == _ARMORS.Generic or itemSubClass == playerPrefs.Armor
        elseif self:IsWeapon() then
            -- Weapons table covers all equippable subclasses for the player's class,
            -- including Generic (off-hand frills) for eligible classes.
            return not not playerPrefs.Weapons[itemSubClass]
        end

        return true
    end

    --- Check if the item can be disenchanted
    --- @return boolean canBeDisenchanted
    function BitForgeItemInfo:CanBeDisenchanted()
        --- only armors and weapons can be disenchanted
        if not (self:IsArmor() or self:IsWeapon()) then return false end

        --- check quality threshold (uncommon to epic)
        local itemQuality = self.itemInfo[3]
        if itemQuality < Enum.ItemQuality.Uncommon or itemQuality > Enum.ItemQuality.Epic then return false end

        --- non-enchanter can't disenchant soulbound items
        if not model:IsEnchanter() and self.containerInfo.isBound then return false end

        return not model.nonDisenchantableItemIDs[self.itemID]
    end

    --- @return number? itemLevel
    local function getInventoryItemLevel(slotIndex)
        local link = _GetInventoryItemLink("player", slotIndex)
        if not link then return end

        return _GetItemLevelInfo(link) or 0
    end

    --- Check if the item has lower item level than currently equipped item in the same slot, based on a configurable threshold
    --- @return boolean isBetter
    function BitForgeItemInfo:IsBetterThanEquipped()
        local itemLevel = self.itemInfo[4]
        local equipLocation = self.itemInfo[9]
        local ilvlThreshold = model:GetItemLevelThreshold()
        local equippedLevel

        if DUAL_SLOTS[equipLocation] then
            -- Case A: Dual Slot (Rings / Trinkets)
            local slots = DUAL_SLOTS[equipLocation]
            local lv1 = getInventoryItemLevel(slots[1])
            local lv2 = getInventoryItemLevel(slots[2])

            if lv1 == nil and lv2 == nil then return false end
            --- @cast lv1 number
            equippedLevel = _min(lv1, lv2)
        else
            -- Case B: Standard Single Slot
            local slotID = SLOT_MAP[equipLocation]
            if not slotID then return false end

            equippedLevel = getInventoryItemLevel(slotID)
            if equippedLevel == nil then return false end
        end
        if equippedLevel == 0 then return false end

        return itemLevel < (equippedLevel - ilvlThreshold)
    end

    function BitForgeItemInfo:IsPastExpansionItem()
        local expID = self.itemInfo[15] or 0

        return expID ~= 0 and expID < curExpansionID
    end
end

--- =========================================================
--- Factory Methods
--- =========================================================

--- Factory method to get item info for a given bag and slot
--- @param bagIndex number
--- @param slotIndex number
--- @return BitForgeItemInfo? info Returns a BitForgeItemInfo object or nil
function model:CreateItemInfo(bagIndex, slotIndex)
    return BitForgeItemInfo:New(bagIndex, slotIndex)
end

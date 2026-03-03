--- @type string, ns.BatchSell
local ADDON_NAME, ns = ...
local params = ns.params
--- @class BitForge.Models.BatchSell: BitForge.Models.Base
local model = ns.model

--- =========================================================
--- Caches
--- =========================================================

local _type = type
local _pairs = pairs
local _error = error
local _select = select
local _tostring = tostring
local _wipe = table.wipe
local _format = string.format
local _ipairs = ipairs
local _next = next
local _setmetatable = setmetatable

local _GetEquipmentSetIDs = C_EquipmentSet.GetEquipmentSetIDs
local _GetItemLocations = C_EquipmentSet.GetItemLocations
local _GetEquipmentLocationData = EquipmentManager_GetLocationData
local _GetProfessions = GetProfessions
local _GetProfessionInfo = GetProfessionInfo

-- Enchanting skill line IDs across all expansions
local ENCHANTING_SKILL_LINES = {
    [333] = true,  -- Base skill line
    [2494] = true, -- World of Warcraft (Vanilla)
    [2493] = true, -- Burning Crusade
    [2492] = true, -- Wrath of the Lich King
    [2491] = true, -- Cataclysm
    [2489] = true, -- Mists of Pandaria
    [2488] = true, -- Warlords of Draenor
    [2487] = true, -- Legion
    [2486] = true, -- Battle for Azeroth
    [2753] = true, -- Shadowlands
    [2825] = true, -- Dragonflight
    [2874] = true, -- The War Within
    [2909] = true, -- Midnight
}

--- =========================================================
--- Defaults
--- =========================================================

local defaults = {
    global = {
        whitelist = {},
        blacklist = {},
    },
    char = {
        whitelist = {},
        blacklist = {},
        args = {
            sellJunk = false,
            includeDisenchantables = false,
            ilvlThreshold = 10,
            limitBatchTo12 = true,
        },
    },
}

local dbGlobal, dbChar


--- =========================================================
--- Helpers
--- =========================================================

local function mergeDatabases(listName)
    local mergedList = {}
    for itemLink in _pairs(dbGlobal[listName]) do
        mergedList[itemLink] = true
    end
    for itemLink in _pairs(dbChar[listName]) do
        mergedList[itemLink] = true
    end
    return mergedList
end


--- =========================================================
--- Caching Equipment Sets
--- =========================================================

local equipmentSetMembers = {}

--- Refresh equipment sets and cache item locations for fast lookup
function model:RefreshEquipmentSets()
    _wipe(equipmentSetMembers)

    local setIDs = _GetEquipmentSetIDs()
    if not setIDs then return end

    for _, setID in _ipairs(setIDs) do
        local locations = _GetItemLocations(setID)
        if locations then
            for _, location in _pairs(locations) do
                local locationData = _GetEquipmentLocationData(location)
                if _next(locationData) and locationData.isBags then
                    local bagIndex = locationData.bag
                    local slotIndex = locationData.slot

                    local bagSlotKey = _format("%d:%d", bagIndex, slotIndex)
                    equipmentSetMembers[bagSlotKey] = true
                end
            end
        end
    end
end

--- Check if a given bag/slot is part of any equipment set
--- @param bagSlotKey string in the format "bagIndex:slotIndex"
--- @return boolean IsInSet
function model:IsInEquipmentSet(bagSlotKey)
    return not not equipmentSetMembers[bagSlotKey]
end

--- =========================================================
--- Settings
--- =========================================================

function model:SetKeepEnchantables(value)
    dbChar.args.includeDisenchantables = value
end

function model:GetKeepEnchantables()
    return dbChar.args.includeDisenchantables
end

function model:SetItemLevelThreshold(value)
    local valType = _type(value)
    if valType ~= "number" then
        _error("Invalid value type: expected number, got " .. valType, 2)
    end

    dbChar.args.ilvlThreshold = value
end

function model:GetItemLevelThreshold()
    return dbChar.args.ilvlThreshold
end

function model:SetSellJunk(value)
    dbChar.args.sellJunk = value
end

function model:GetSellJunk()
    return dbChar.args.sellJunk
end

function model:SetLimitBatch(value)
    dbChar.args.limitBatchTo12 = value
end

function model:GetLimitBatch()
    return dbChar.args.limitBatchTo12
end

--- =========================================================
--- Public Methods
--- =========================================================

--- Set an item's status (whitelist/blacklist)
--- @param itemLink string
--- @param targetList "whitelist"|"blacklist"|nil nil to clear
--- @param isGlobal boolean? (default: false for character-specific)
function model:UpdateListedStatus(itemLink, targetList, isGlobal)
    if targetList and targetList ~= "whitelist" and targetList ~= "blacklist" then
        _error("Invalid target list: " .. _tostring(targetList), 2)
    end

    -- Clear existing status
    dbGlobal.whitelist[itemLink] = nil
    dbGlobal.blacklist[itemLink] = nil
    dbChar.whitelist[itemLink] = nil
    dbChar.blacklist[itemLink] = nil

    -- If no target list, unlist everywhere and return
    if not targetList then return end

    -- Set new status
    local db = isGlobal and dbGlobal or dbChar
    db[targetList][itemLink] = true
end

--- Get an item's status
--- @param itemLink string
--- @return "whitelist"|"blacklist"|nil list
--- @return boolean? isGlobal
function model:GetListedStatus(itemLink)
    local list, isGlobal

    if dbGlobal.whitelist[itemLink] then
        list, isGlobal = "whitelist", true
    elseif dbChar.whitelist[itemLink] then
        list, isGlobal = "whitelist", false
    elseif dbGlobal.blacklist[itemLink] then
        list, isGlobal = "blacklist", true
    elseif dbChar.blacklist[itemLink] then
        list, isGlobal = "blacklist", false
    end

    return list, isGlobal
end

--- Get merged whitelist (global + character)
--- @return table<string, boolean>
function model:GetWhitelist()
    return mergeDatabases("whitelist")
end

--- Get merged blacklist (global + character)
--- @return table<string, boolean>
function model:GetBlacklist()
    return mergeDatabases("blacklist")
end

local isEnchanter

function model:HasEnchantingProfession()
    local p1, p2 = _GetProfessions()
    local s1 = p1 and _select(7, _GetProfessionInfo(p1))
    local s2 = p2 and _select(7, _GetProfessionInfo(p2))
    isEnchanter = (s1 and ENCHANTING_SKILL_LINES[s1]) or (s2 and ENCHANTING_SKILL_LINES[s2]) or false
end

function model:IsEnchanter()
    return not not isEnchanter
end

--- =========================================================
--- Overridable Methods
--- =========================================================

function model:OnInit()
    self.db = BitForgeAPI.RegisterDatabase(ADDON_NAME, defaults)
    dbGlobal = self.db.global
    dbChar.whitelist = self.db.char.whitelist
    dbChar.blacklist = self.db.char.blacklist
    dbChar.args = self.db.char.args
end

function model:OnEnable()
    self:HasEnchantingProfession()
    self:RefreshEquipmentSets()
end

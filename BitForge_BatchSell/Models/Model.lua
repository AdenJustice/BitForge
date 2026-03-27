local ns = select(2, ...)

local ipairs = ipairs
local next   = next

local wipe = table.wipe

ns.Model = {}
local model = ns.Model
local db

function model.Init(_db)
    db = _db
end

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
-- list = "blacklist" | "whitelist" | "charBlacklist" | "charWhitelist"
-- =========================================================

-- Warband-wide lists live in db.global; character-specific lists in db.char.
local function listScope(list)
    return (list == "blacklist" or list == "whitelist") and db.global or db.char
end

--- @param itemLink string
--- @param list "blacklist"|"whitelist"|"charBlacklist"|"charWhitelist"
--- @return boolean
function model.IsEnlisted(itemLink, list)
    return listScope(list)[list][itemLink] == true
end

--- @param itemLink string
--- @param list "blacklist"|"whitelist"|"charBlacklist"|"charWhitelist"
--- @param value boolean  true = add, false/nil = remove
function model.SetEnlisted(itemLink, list, value)
    listScope(list)[list][itemLink] = value and true or nil
end

--- @param list "blacklist"|"whitelist"|"charBlacklist"|"charWhitelist"
--- @return string[]
function model.GetList(list)
    local result = {}
    for itemLink in next, listScope(list)[list] do
        result[#result + 1] = itemLink
    end
    return result
end

--- @param list "blacklist"|"whitelist"|"charBlacklist"|"charWhitelist"
function model.ClearList(list)
    wipe(listScope(list)[list])
end

-- =========================================================
-- Equipment set cache  (populated by Controller, queried by ItemInfo)
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

--- @return boolean
function model.IsEnchanter()
    return isEnchanter
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
        total = total + item:GetTotalSellValue()
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

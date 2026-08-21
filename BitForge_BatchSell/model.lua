---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local next = next
local huge = math.huge

local sort = table.sort
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
        -- Category gates. Materials and consumables are kept until the player
        -- opts in; equipment is what the module exists to vendor.
        sellEquipment = true,
        materialsMode = "KEEP_ALL",
        materialsExpansion = 11, -- LE_EXPANSION_MIDNIGHT; read only in KEEP_FROM
        otherMode = "KEEP_ALL",
        -- Equipment: the slot comparison. Each toggle off means "let quality
        -- decide" for that direction; see model.CompareToEquipped.
        ilvlThreshold = -20,
        marginOnHigherQuality = false,
        marginOnSameQuality = true,
        marginOnLowerQuality = false,
        -- Keep rules
        keepBindOnAccount = true,
        keepBindOnAccountPastExpac = false,
        keepDisenchantables = false,
        keepDisenchantablesPastExpac = false,
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
-- Diagnostics
-- =========================================================

--- The module's debug flag: a hand-written sibling of global and char in the
--- saved variables, deliberately outside the schema. Read live rather than
--- cached, so setting it with /run takes effect on the next tooltip without a
--- reload. db is private to this file, which is why view.lua reaches it here.
---
--- db.debug is the container core normalized, so the flag is .enabled inside it
--- and not the container itself -- one left behind with diagnostics switched
--- off is still a table, and returning it raw would read as permanently on.
---@return boolean
function model.IsDebug()
    local diagnostics = db.debug
    return (diagnostics and diagnostics.enabled) and true or false
end

-- =========================================================
-- Settings getters / setters
-- =========================================================

function model.GetSellJunk() return db.char.sellJunk end

function model.SetSellJunk(v) db.char.sellJunk = v end

function model.GetIlvlThreshold() return db.char.ilvlThreshold end

function model.SetIlvlThreshold(v) db.char.ilvlThreshold = v end

function model.GetKeepDisenchantables() return db.char.keepDisenchantables end

function model.SetKeepDisenchantables(v) db.char.keepDisenchantables = v end

function model.GetLimitBatchTo12() return db.char.limitBatchTo12 end

function model.SetLimitBatchTo12(v) db.char.limitBatchTo12 = v end

function model.GetKeepBindOnAccount() return db.char.keepBindOnAccount end

function model.SetKeepBindOnAccount(v) db.char.keepBindOnAccount = v end

function model.GetKeepBindOnAccountPastExpac() return db.char.keepBindOnAccountPastExpac end

function model.SetKeepBindOnAccountPastExpac(v) db.char.keepBindOnAccountPastExpac = v end

function model.GetKeepDisenchantablesPastExpac() return db.char.keepDisenchantablesPastExpac end

function model.SetKeepDisenchantablesPastExpac(v) db.char.keepDisenchantablesPastExpac = v end

function model.GetSellEquipment() return db.char.sellEquipment end

function model.SetSellEquipment(value) db.char.sellEquipment = value end

function model.GetMaterialsMode() return db.char.materialsMode end

function model.SetMaterialsMode(value) db.char.materialsMode = value end

function model.GetMaterialsExpansion() return db.char.materialsExpansion end

function model.SetMaterialsExpansion(value) db.char.materialsExpansion = value end

function model.GetOtherMode() return db.char.otherMode end

function model.SetOtherMode(value) db.char.otherMode = value end

function model.GetMarginOnHigherQuality() return db.char.marginOnHigherQuality end

function model.SetMarginOnHigherQuality(value) db.char.marginOnHigherQuality = value end

function model.GetMarginOnSameQuality() return db.char.marginOnSameQuality end

function model.SetMarginOnSameQuality(value) db.char.marginOnSameQuality = value end

function model.GetMarginOnLowerQuality() return db.char.marginOnLowerQuality end

function model.SetMarginOnLowerQuality(value) db.char.marginOnLowerQuality = value end

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

--- Every entry of one status, across both scopes, for the merchant panel's list
--- tabs to render.
---
--- One row per scope per item rather than a merged view: an item listed in both
--- scopes is two entries, because each is independently removable and that is
--- exactly what having two scopes means. GetEffectiveStatus answers the other
--- question -- which one governs -- and is unchanged.
---
--- Sorted by scope then itemID so the order is stable across refreshes. Sorting
--- by name would read better but cannot be relied on: a list holds itemIDs, and
--- an entry the client has never loaded has no name yet.
---@param status string  enum.LIST_STATUS value
---@return table  array of { itemID = number, scope = string }
function model.GetListEntries(status)
    local entries = {}
    for _, scope in ipairs({ enum.LIST_SCOPE.CHAR, enum.LIST_SCOPE.GLOBAL }) do
        for itemID, entryStatus in next, db[scope].list do
            if entryStatus == status then
                entries[#entries + 1] = { itemID = itemID, scope = scope }
            end
        end
    end
    sort(entries, function(left, right)
        if left.scope ~= right.scope then return left.scope < right.scope end
        return left.itemID < right.itemID
    end)
    return entries
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

function model.RemoveTempExclude(itemLink)
    tempExcludes[itemLink] = nil
end

-- =========================================================
-- Temporary includes  (cleared on MERCHANT_CLOSED)
-- =========================================================

local tempIncludes = {}

function model.AddTempInclude(itemLink)
    tempIncludes[itemLink] = true
end

function model.IsTempIncluded(itemLink)
    return tempIncludes[itemLink] == true
end

function model.ClearTempIncludes()
    wipe(tempIncludes)
end

--- The rule that would block a temporary include, or nil if one would stick.
---
--- Deliberately silent about isTempExcluded. A temporary exclusion and a drag
--- are the same class of gesture -- both last one merchant visit -- so the later
--- one wins rather than the earlier one refusing it. The caller retracts the
--- exclusion; this predicate only reports the rules that outrank both.
---
--- Kept separate from Decide rather than folded into it because the caller needs
--- the answer BEFORE it mutates anything: Decide reports TEMP_EXCLUDED first and
--- would mask a blacklist behind it, so clearing the exclusion and re-deciding
--- would retract the player's exclusion only to refuse the drop anyway.
---@param facts table
---@return string|nil  enum.RULE value that blocks the include, or nil
function model.CanTempInclude(facts)
    local RULE = enum.RULE
    if facts.isProhibited then return RULE.BLACKLISTED end
    if facts.isLocked then return RULE.LOCKED end
    if facts.inEquipmentSet then return RULE.EQUIPMENT_SET end
    if facts.sellPrice <= 0 then return RULE.NO_SELL_PRICE end
    if facts.isRefundable then return RULE.REFUNDABLE end
    return nil
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
-- Item categories
-- ================================================================================
--
-- The three buckets the cascade sorts an item into before any rule runs. An item
-- matching none of them is never a sale candidate.

local MATERIAL_CLASSES = {
    [Enum.ItemClass.Tradegoods]      = true,
    [Enum.ItemClass.Reagent]         = true,
    [Enum.ItemClass.Gem]             = true,
    [Enum.ItemClass.ItemEnhancement] = true,
    [Enum.ItemClass.Recipe]          = true,
}

local OTHER_CLASSES = {
    [Enum.ItemClass.Consumable]    = true,
    [Enum.ItemClass.Container]     = true,
    [Enum.ItemClass.Miscellaneous] = true,
    [Enum.ItemClass.Battlepet]     = true,
    [Enum.ItemClass.Profession]    = true,
    [Enum.ItemClass.Housing]       = true,
}

--- Which category governs this item, or nil when none does.
---
--- Materials leads with isCraftingReagent -- Blizzard's own flag, the 17th
--- return of C_Item.GetItemInfo -- rather than an item class, because it catches
--- a reagent whatever class it was filed under and self-maintains across
--- patches. The class list behind it is the backstop for materials the flag
--- misses, Recipe in particular.
---
--- Order matters: equipment first so a flagged piece of gear stays gear, and
--- materials before other so a consumable that is a crafting reagent is treated
--- as a reagent.
---
--- Profession gear sits in OTHER rather than EQUIPMENT deliberately. Its
--- INVTYPE_PROFESSION_TOOL and INVTYPE_PROFESSION_GEAR locations have no
--- enum.SLOT_LOOKUP entry, so the slot comparison has no reference for them; calling
--- them equipment would send them straight to the equipment terminal and sell
--- them.
---@param facts table
---@return string|nil  enum.CATEGORY_KEY value, or nil when unlisted
function model.GetCategory(facts)
    local classID = facts.classID
    if classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon then
        return enum.CATEGORY_KEY.EQUIPMENT
    end
    if facts.isCraftingReagent or MATERIAL_CLASSES[classID] then
        return enum.CATEGORY_KEY.MATERIALS
    end
    if OTHER_CLASSES[classID] then
        return enum.CATEGORY_KEY.OTHER
    end
    return nil
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
---
--- expacID uses LE_EXPANSION_* numbering, which is 0-based: Classic is 0, The
--- War Within 10, Midnight 11. Zero is therefore ambiguous -- it means either a
--- vanilla item or one Blizzard never assigned an expansion to, and current
--- content carries it often enough that reading it as Classic would sweep
--- current crafting materials into a past-expansion sell. An item with no
--- expansion is never past-expansion, whatever the threshold.
---
--- The consequence is that genuine vanilla items cannot be swept either. That is
--- the right trade: they are overwhelmingly Poor quality, which sellJunk already
--- clears, or carry no sell price at all.
function model.IsPastExpansion(facts, expansionThreshold)
    if facts.expacID == 0 then return false end
    return facts.expacID < expansionThreshold
end

--- The item level slack granted when comparing a candidate against one equipped
--- item, derived from the quality gap between them.
---
--- The tolerance is added to the equipped level, so -huge drops the bar to
--- negative infinity and keeps everything while huge raises it beyond reach and
--- keeps nothing. ilvlThreshold is negative.
---
--- Each toggle off means "let quality decide": a higher-quality item is kept, a
--- lower-quality one sold, and a quality tie leaves item level as the only
--- discriminator, so the tolerance drops to zero rather than to a blanket
--- verdict -- otherwise turning it off would sell a same-quality upgrade.
---
--- Two or more steps behind is a tightening rule and never a loosening one: an
--- Uncommon against an equipped Epic gets no slack whatever the margin says.
local function toleranceFor(candidateQuality, equippedQuality, settings)
    local gap = candidateQuality - equippedQuality
    if gap >= 1 then
        return settings.marginOnHigherQuality and settings.ilvlThreshold or -huge
    end
    if gap == 0 then
        return settings.marginOnSameQuality and settings.ilvlThreshold or 0
    end
    if gap == -1 then
        return settings.marginOnLowerQuality and settings.ilvlThreshold or huge
    end
    return settings.marginOnLowerQuality and 0 or huge
end

--- True when the item is worth keeping against what occupies a slot it could
--- fill.
---
--- Existential over slots, as IsCloseToEquipped was: for the dual slots (rings
--- 11/12, trinkets 13/14) an item only has to satisfy the test against one of
--- the two. Each slot carries its own equipped level and quality, so the two
--- rings are compared independently rather than reduced to a single number
--- first.
---
--- Answers false when there is no reference -- off-class gear never reaches
--- here, and a slot holding nothing yields an empty list. Both fall through to
--- the equipment terminal and sell.
---
--- An entry marked unreadable is different from an empty list: it means a slot
--- holds something whose level or quality the scanner could not read, rather
--- than a slot holding nothing at all. That is not evidence the candidate
--- outclasses it -- it is simply unknown, and unknown must not authorise a
--- sale -- so it short-circuits the whole comparison to true (worth keeping)
--- rather than being skipped as if it were not there.
---@param facts    table
---@param settings table
---@return boolean
function model.CompareToEquipped(facts, settings)
    local equippedItems = facts.equippedItems
    if not equippedItems then return false end
    for _, equipped in ipairs(equippedItems) do
        if equipped.unreadable then return true end
        local tolerance = toleranceFor(facts.quality, equipped.quality, settings)
        if facts.level >= equipped.level + tolerance then
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

--- The mode and pinned expansion governing one non-equipment category.
---
--- materialsExpansion is read only when the mode is KEEP_FROM -- KEEP_CURRENT
--- pins to the live current expansion instead, exactly like Other, so it keeps
--- tracking a moving expansion level rather than freezing at whatever
--- materialsExpansion happened to hold.
---
--- Other carries no expansion key of its own because the panel offers it only
--- KEEP_ALL and KEEP_CURRENT. Decide still honours KEEP_FROM if handed it, and
--- pins to the current expansion in that case -- the same answer KEEP_CURRENT
--- gives, which is the safe degradation.
local function categoryRule(category, settings)
    if category == enum.CATEGORY_KEY.MATERIALS then
        local pinnedExpansion = settings.materialsMode == enum.SELL_MODE.KEEP_FROM
            and settings.materialsExpansion or settings.currentExpansion
        return settings.materialsMode, pinnedExpansion
    end
    return settings.otherMode, settings.currentExpansion
end

--- Decides whether one item should be sold.
--- Pure: no API calls, no frame access, no db reads.
---@param facts    table  One item's gathered facts
---@param settings table  Snapshot from model.GetSettingsSnapshot
---@return string verdict  enum.DECISION.SELL or enum.DECISION.KEEP
---@return string rule     enum.RULE.* — which step decided
function model.Decide(facts, settings)
    local DECISION, RULE = enum.DECISION, enum.RULE
    local CATEGORY, MODE = enum.CATEGORY_KEY, enum.SELL_MODE

    -- 0. Excluded for this merchant visit only.
    if facts.isTempExcluded then return DECISION.KEEP, RULE.TEMP_EXCLUDED end

    -- 1. Blacklist, either scope.
    if facts.isProhibited then return DECISION.KEEP, RULE.BLACKLISTED end

    -- 2. Hard gates. These are not overridable by the whitelist.
    if facts.isLocked then return DECISION.KEEP, RULE.LOCKED end
    if facts.inEquipmentSet then return DECISION.KEEP, RULE.EQUIPMENT_SET end
    if facts.sellPrice <= 0 then return DECISION.KEEP, RULE.NO_SELL_PRICE end
    if facts.isRefundable then return DECISION.KEEP, RULE.REFUNDABLE end

    -- 3. Whitelist override. Sits above the category gate deliberately: it is
    -- the escape hatch for the one reagent the player does want vendored.
    if facts.isEnforced then return DECISION.SELL, RULE.WHITELISTED end

    -- 3b. Temporary include. Below the whitelist so a durable reason is reported
    -- in preference to a transient one when both apply, and below every KEEP
    -- guard above: a drag overrides what the rules merely did not select, never
    -- something the player protected or something the client cannot sell.
    if facts.isTempIncluded then return DECISION.SELL, RULE.TEMP_INCLUDED end

    -- 4. Category gate. An item its category declines never reaches a rule that
    -- can sell it.
    local category = model.GetCategory(facts)
    if not category then return DECISION.KEEP, RULE.CATEGORY end

    if category == CATEGORY.EQUIPMENT then
        if not settings.sellEquipment then return DECISION.KEEP, RULE.CATEGORY end
    else
        local mode, pinnedExpansion = categoryRule(category, settings)
        if mode == MODE.KEEP_ALL then
            return DECISION.KEEP, RULE.CATEGORY
        end
        if mode ~= MODE.SELL_ALL
            and not model.IsPastExpansion(facts, pinnedExpansion) then
            return DECISION.KEEP, RULE.CURRENT_EXPANSION
        end
    end

    -- 5. Bind on Account. Expansion age is measured against the live current
    -- expansion, so "Include Past Expansions" means what its label says without
    -- a second control being set to make it true.
    if settings.keepBindOnAccount and facts.bindType == enum.BIND_TYPE.ON_ACCOUNT then
        if settings.keepBindOnAccountPastExpac
            or not model.IsPastExpansion(facts, settings.currentExpansion) then
            return DECISION.KEEP, RULE.BIND_ON_ACCOUNT
        end
    end

    -- 6. Disenchantable, equippable or not. Above the equipment terminal so an
    -- outclassed green is still kept for the enchanter.
    if settings.keepDisenchantables and model.IsDisenchantable(facts, settings.isEnchanter) then
        if settings.keepDisenchantablesPastExpac
            or not model.IsPastExpansion(facts, settings.currentExpansion) then
            return DECISION.KEEP, RULE.DISENCHANTABLE
        end
    end

    -- 7-8. Equipment terminates here. The slot comparison is the only way gear
    -- survives; anything it declines is outclassed. Gear with no reference --
    -- off-class, or a slot holding nothing -- reaches the terminal too.
    if category == CATEGORY.EQUIPMENT then
        if model.IsEquippableBy(facts, settings.playerClass)
            and model.CompareToEquipped(facts, settings) then
            return DECISION.KEEP, RULE.EQUIPPABLE
        end
        return DECISION.SELL, RULE.OUTCLASSED
    end

    -- 9. Everything else its mode declared eligible.
    if category == CATEGORY.MATERIALS or category == CATEGORY.OTHER then
        return DECISION.SELL, RULE.SELL_MODE
    end

    -- 10. The defensive tail. Unreachable: GetCategory returns one of the three
    -- keys or nil, and nil was kept at step 4. It is here so a category added
    -- without a branch above keeps the item rather than selling it.
    return DECISION.KEEP, RULE.DEFAULT
end

-- ================================================================================
-- Settings snapshot  (impure — reads the db)
-- ================================================================================

--- Reads the settings the cascade consults, once per scan rather than per item.
--- sellJunk and limitBatchTo12 are deliberately absent: they govern the merchant
--- visit and the sell loop, not the per-item decision.
---
--- currentExpansion is read live rather than stored, so KEEP_CURRENT tracks a
--- new expansion launching without the player touching a setting.
---@return table
function model.GetSettingsSnapshot()
    return {
        sellEquipment                = db.char.sellEquipment,
        materialsMode                = db.char.materialsMode,
        materialsExpansion           = db.char.materialsExpansion,
        otherMode                    = db.char.otherMode,
        ilvlThreshold                = db.char.ilvlThreshold,
        marginOnHigherQuality        = db.char.marginOnHigherQuality,
        marginOnSameQuality          = db.char.marginOnSameQuality,
        marginOnLowerQuality         = db.char.marginOnLowerQuality,
        keepBindOnAccount            = db.char.keepBindOnAccount,
        keepBindOnAccountPastExpac   = db.char.keepBindOnAccountPastExpac,
        keepDisenchantables          = db.char.keepDisenchantables,
        keepDisenchantablesPastExpac = db.char.keepDisenchantablesPastExpac,
        isEnchanter                  = isEnchanter,
        playerClass                  = playerClass,
        currentExpansion             = GetExpansionLevel(),
    }
end

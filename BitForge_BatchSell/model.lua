---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local next = next

local band = bit.band
local sort = table.sort
local wipe = table.wipe

local DB_DEFAULTS = {
    global = {
        -- Warband-wide list: itemID → enum.LIST_STATUS value
        list = {},
        -- What the client itself answered about an item's disenchantability:
        -- itemID → boolean, harvested by control.disenchantProbe. Warband-wide
        -- because the answer is a property of the item, not of the character
        -- who happened to be holding it. Absent for anything never observed
        -- with a disenchant pending, which is most of the game -- so it
        -- supplements the crawled table rather than replacing it.
        disenchantTruth = {},
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
        -- Equipment: the slot comparison. One bar, moved by quality rather
        -- than switched by it -- see model.CompareToEquipped. The margin is a
        -- flat number of item levels, and one quality tier is worth exactly one
        -- more of them.
        ilvlMargin = 10,
        -- Issue #7's "usemargin". Off by default: emphasis is the opt-in
        -- amplifier, and the plain rule is one margin per quality tier.
        emphasizeQuality = false,
        -- Keep rules
        keepBindOnAccount = true,
        keepBindOnAccountPastExpac = false,
        keepDisenchantables = false,

        -- Defaults on. The catalogue only ever reports a profession somebody on
        -- this account actually has, so the items it protects are ones the
        -- player has a use for -- and selling a reagent is not undoable.
        keepUsedReagents = true,
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

--- The debug container's scratch table, or nil while diagnostics are off.
---
--- Handed out rather than written through: a caller assembles its whole record
--- and drops it in. The container a module holds is the stored one, so anything
--- filed here reaches the saved variables and survives the session that
--- produced it -- which is the entire reason the dump exists.
---
--- Deliberately outside the schema, like the flag beside it: never seeded, never
--- migrated, and left alone by the logout prune.
---@return table|nil
function model.GetDebugDump()
    local diagnostics = db.debug
    if not (diagnostics and diagnostics.enabled) then return nil end
    return diagnostics.dump
end

-- =========================================================
-- Settings getters / setters
-- =========================================================

function model.GetSellJunk() return db.char.sellJunk end

function model.SetSellJunk(v) db.char.sellJunk = v end

function model.GetIlvlMargin() return db.char.ilvlMargin end

function model.SetIlvlMargin(v) db.char.ilvlMargin = v end

function model.GetEmphasizeQuality() return db.char.emphasizeQuality end

function model.SetEmphasizeQuality(v) db.char.emphasizeQuality = v end

function model.GetKeepDisenchantables() return db.char.keepDisenchantables end

function model.SetKeepDisenchantables(v) db.char.keepDisenchantables = v end
function model.GetKeepUsedReagents() return db.char.keepUsedReagents end
function model.SetKeepUsedReagents(v) db.char.keepUsedReagents = v end

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

---@return boolean
function model.GetIsEnchanter()
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

--- One equipped item's answer about one candidate: DECISION.KEEP,
--- DECISION.SELL, or nil.
---
--- The three are not two outcomes plus a fallback. Gear is put to three
--- questions in order -- good for me, good for an alt, worth disenchanting --
--- and this is only the first:
---
---   KEEP  settles it, and nothing below is asked.
---   SELL  is the spec's PASS. It does not vendor anything by itself; it hands
---         the piece to the two questions below, and only gear none of the
---         three claims reaches the vendor.
---   nil   is not a PASS. It means there was nothing to compare against, which
---         only an unreadable slot or an empty one produces. The questions
---         presuppose something in the slot, and with nothing there the first
---         of them -- is this good for me? -- is answered by the slot being
---         empty. It reaches the default, which keeps.
---
--- The bar moves a whole margin per quality tier, and the tiers are not
--- symmetric about it:
---
---   a tier up or more    KEEP at  equipped - margin
---   same quality         KEEP at  above equipped
---   a tier down or more  KEEP at  above equipped + margin * tiers
---
--- So the margin is what one quality tier is worth, not a tolerance at your own
--- tier: at equal quality a piece has to be a strict item level upgrade, and
--- every tier given up is bought back a whole margin at a time. The discount
--- is capped at one margin however far up the ladder the candidate is, while
--- the debt keeps stacking downwards -- quality above what you wear is worth
--- having, but not worth an unbounded item level discount.
---
--- Whole item levels throughout. Margin, level and quality gap are integers, so
--- every bar is exact and there is nothing to round.
---
--- Monotonic by construction: the bar never rises as the candidate's quality
--- rises, so improving either axis can only move a piece towards being kept.
local function compareToSlot(facts, equipped, settings)
    -- Something occupies the slot but its level or quality could not be read.
    -- Unknown is not evidence, and must never pass an item towards the vendor.
    if equipped.unreadable then return nil end

    local qualityGap = facts.quality - equipped.quality

    -- Emphasis does two things at once, and both are needed to keep the rungs
    -- evenly spaced: it doubles what a tier costs, and it grants a tolerance at
    -- the candidate's own tier. Without the second the doubling would leave the
    -- gap between "same quality" and "one tier down" three times the gap below
    -- it. Without the first the tolerance alone would only ever be leniency,
    -- and the point of emphasis is that quality below yours gets dearer too.
    local step = settings.ilvlMargin * (settings.emphasizeQuality and 2 or 1)
    local tolerance = settings.emphasizeQuality and settings.ilvlMargin or 0
    local level = equipped.level - tolerance

    if qualityGap > 0 then
        -- Capped at one tier's discount however far up the ladder it is.
        -- Quality above the slot is worth having; it is not worth an unbounded
        -- item level rebate.
        if facts.level >= level - step then return enum.DECISION.KEEP end
        return enum.DECISION.SELL
    end

    if qualityGap == 0 then
        if facts.level > level then return enum.DECISION.KEEP end
        return enum.DECISION.SELL
    end

    -- qualityGap is negative here, so negating it is the number of tiers given
    -- up, and each one is a whole step the candidate has to make back.
    if facts.level > level + step * -qualityGap then
        return enum.DECISION.KEEP
    end
    return enum.DECISION.SELL
end

--- What the slots this item could fill make of it.
---
--- Existential over slots, as before: for the dual slots (rings 11/12, trinkets
--- 13/14) one satisfied slot is enough, and each carries its own level and
--- quality rather than being reduced to a single number first.
---
--- With three answers the combination has to say what a split decision means. A
--- slot that keeps wins outright. Condemnation has to be unanimous: a slot with
--- no opinion spares the item from a sibling that would have sold it, which is
--- the same "only has to satisfy one of the two" rule read from the other end.
---
--- An empty list -- a slot holding nothing, or an item whose equip location maps
--- to no slot -- yields no opinion rather than a sale. There is nothing to be
--- worse than, and levelling gear for a slot you have not filled is not junk.
---@param facts    table
---@param settings table
---@return string|nil  enum.DECISION.KEEP, enum.DECISION.SELL, or nil
function model.CompareToEquipped(facts, settings)
    local equippedItems = facts.equippedItems
    if not equippedItems then return nil end

    local condemned, undecided = false, false
    for _, equipped in ipairs(equippedItems) do
        local verdict = compareToSlot(facts, equipped, settings)
        if verdict == enum.DECISION.KEEP then return enum.DECISION.KEEP end
        if verdict == enum.DECISION.SELL then
            condemned = true
        else
            undecided = true
        end
    end

    if condemned and not undecided then return enum.DECISION.SELL end
    return nil
end

--- What the crawled table predicts about disenchantability, with no bind rules
--- folded in: uncommon or better, armour or a weapon, and absent from the list
--- of exceptions the crawl found. Pure client-side inference -- the same three
--- questions the tooltip's line answers authoritatively, guessed from item data
--- because the authoritative answer is only readable with a spell pending.
---@param facts table
---@return boolean
function model.PredictDisenchantable(facts)
    if facts.quality < Enum.ItemQuality.Uncommon then return false end
    if facts.classID ~= Enum.ItemClass.Armor and facts.classID ~= Enum.ItemClass.Weapon then
        return false
    end
    return not enum.NON_DISENCHANTABLE_IDS[facts.itemID]
end

--- Whether the item can be disenchanted at all.
---
--- The client's own answer wins where one has been harvested, in both
--- directions: it is the same value the game paints the bag slot with, so an
--- item the crawl missed stops being kept and one the crawl wrongly listed
--- starts being kept. Everything unobserved falls back to the prediction.
---@param facts table
---@return boolean
function model.CanDisenchant(facts)
    local learned = db.global.disenchantTruth[facts.itemID]
    if learned ~= nil then return learned end
    return model.PredictDisenchantable(facts)
end

--- The harvested answer for an item, or nil when the client has never been
--- asked about it while a disenchant was pending.
---@param itemID number
---@return boolean|nil
function model.GetLearnedDisenchantable(itemID)
    return db.global.disenchantTruth[itemID]
end

--- Files one observation. Called only from the probe, which has already
--- established that a disenchant is the spell awaiting a target.
---@param itemID number
---@param canDisenchant boolean
function model.LearnDisenchantable(itemID, canDisenchant)
    db.global.disenchantTruth[itemID] = canDisenchant
end

--- True when the item is worth keeping to disenchant or resell:
--- enchanters get value from BoP as well; everyone else only from BoE and BoA.
function model.IsDisenchantable(facts, isEnchanter)
    if not model.CanDisenchant(facts) then return false end

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

    -- 3c. Junk, when the player has not asked this module to handle it. Sell
    -- Junk off means the vendoring of poor-quality items is delegated -- to
    -- Blizzard's own button, or to another addon -- so judging them anyway put
    -- them straight back into the manifest and sold them, which is the one
    -- outcome the setting exists to prevent.
    --
    -- A declination, not a protection, so it sits below the whitelist and the
    -- drag: both are the player naming this item, and neither should be
    -- overruled by a blanket rule that merely did not select it. Below the hard
    -- gates for the same reason those precede everything -- an item the client
    -- cannot sell reports why rather than being written off as junk.
    --
    -- Nothing here when the setting is on: the merchant sweep only runs where
    -- C_MerchantFrame.IsSellAllJunkEnabled agrees, and at every other vendor
    -- this module is what sells the junk.
    if not settings.sellJunk and facts.quality == Enum.ItemQuality.Poor then
        return DECISION.KEEP, RULE.JUNK
    end

    -- 4. Category gate. An item its category declines never reaches a rule that
    -- can sell it.
    local category = model.GetCategory(facts)
    if not category then return DECISION.KEEP, RULE.CATEGORY end

    -- sellEquipment is deliberately absent here. It is permission to sell, not
    -- permission to judge: the three questions below run either way, so a
    -- tooltip can say what a piece is actually worth instead of flattening
    -- every answer into "this kind of item is kept". The flag is applied at
    -- step 7, where the sale it governs would happen. Nothing is gathered for
    -- their sake that a scan does not already gather.
    if category ~= CATEGORY.EQUIPMENT then
        local mode, pinnedExpansion = categoryRule(category, settings)
        if mode == MODE.KEEP_ALL then
            return DECISION.KEEP, RULE.CATEGORY
        end
        if mode ~= MODE.SELL_ALL
            and not model.IsPastExpansion(facts, pinnedExpansion) then
            return DECISION.KEEP, RULE.CURRENT_EXPANSION
        end
    end

    -- 4b. "Is it good for me?" -- the first of the three questions a piece of
    -- gear is put to. It does not terminate: a piece this rejects is condemned
    -- provisionally, and the two questions below get their turn at it. Only a
    -- keep settles the matter here, and clearing the slot's bar is what
    -- produces one, whatever tier the piece is.
    --
    -- Off-class gear is condemned the same provisional way. "My class cannot
    -- use it" is the plainest possible answer to the question, and it is the
    -- gear most likely to suit an alt -- so it is offered to the alt rather
    -- than vendored before the alt is asked.
    local condemnedRule
    if category == CATEGORY.EQUIPMENT then
        if not model.IsEquippableBy(facts, settings.playerClass) then
            condemnedRule = RULE.NOT_EQUIPPABLE
        else
            local verdict = model.CompareToEquipped(facts, settings)
            if verdict == DECISION.KEEP then return DECISION.KEEP, RULE.EQUIPPABLE end
            if verdict == DECISION.SELL then condemnedRule = RULE.OUTCLASSED end
        end
    end

    -- 5. "Is it good for my alts?" Expansion age is measured against the live
    -- current expansion, so "Include Past Expansions" means what its label says
    -- without a second control being set to make it true.
    if settings.keepBindOnAccount and facts.bindType == enum.BIND_TYPE.ON_ACCOUNT then
        if settings.keepBindOnAccountPastExpac
            or not model.IsPastExpansion(facts, settings.currentExpansion) then
            return DECISION.KEEP, RULE.BIND_ON_ACCOUNT
        end
    end

    -- 6. "Is it worth disenchanting?" Third of the three, so it answers only for
    -- gear the first two declined -- which is what keeps an outclassed green
    -- with the enchanter rather than the vendor.
    if settings.keepDisenchantables and model.IsDisenchantable(facts, settings.isEnchanter) then
        if settings.keepDisenchantablesPastExpac
            or not model.IsPastExpansion(facts, settings.currentExpansion) then
            return DECISION.KEEP, RULE.DISENCHANTABLE
        end
    end

    -- 6b. A reagent some profession on this account uses. Below the category
    -- gate, so an item its category already declined is not reconsidered, and
    -- above step 9, which is what would otherwise sell it.
    --
    -- No expansion companion, unlike the two rules above. Their value decays
    -- with age; a reagent's does not -- an Alchemy recipe that wants a Classic
    -- herb wants it exactly as much now as it did then.
    --
    -- facts.reagentProfessions is nil for an item the catalogue does not know,
    -- and nil means NOT KNOWN rather than "nobody wants this". The rule simply
    -- does not fire and the item falls through to the sell mode the player
    -- configured -- so a gap never causes a sale, it only fails to prevent one.
    if settings.keepUsedReagents
        and facts.reagentProfessions
        and band(facts.reagentProfessions, settings.accountProfessions) ~= 0 then
        return DECISION.KEEP, RULE.REAGENT_WANTED
    end

    -- 7. Gear all three questions declined. The rule carried down from 4b says
    -- which way it was declined, and the distinction is worth keeping: "worse
    -- than what you have equipped" is a lie about a mace a hunter was never
    -- able to hold.
    --
    -- This is the only place sellEquipment can change an outcome, so it is the
    -- only place it is read. Withheld, the category is what saved the piece and
    -- is reported as such -- a gear tooltip that said the default had claimed it
    -- would be untrue, since a rule did claim it and the flag overruled.
    if condemnedRule then
        if not settings.sellEquipment then return DECISION.KEEP, RULE.CATEGORY end
        return DECISION.SELL, condemnedRule
    end

    -- 8. Everything else its mode declared eligible.
    if category == CATEGORY.MATERIALS or category == CATEGORY.OTHER then
        return DECISION.SELL, RULE.SELL_MODE
    end

    -- 9. Nothing decided, so the item is kept. Reached in earnest now rather
    -- than defensively: gear that no question condemned and none kept outright
    -- -- an item level upgrade at the same quality, or a piece for a slot
    -- holding nothing -- arrives here, and keeping it is the answer.
    return DECISION.KEEP, RULE.DEFAULT
end

-- ================================================================================
-- Settings snapshot  (impure — reads the db)
-- ================================================================================

--- Reads the settings the cascade consults, once per scan rather than per item.
--- limitBatchTo12 is deliberately absent: it governs the sell loop, not the
--- per-item decision. sellJunk governs both -- which vendor sweep runs on
--- MERCHANT_SHOW, and whether poor-quality items are this module's to judge at
--- all.
---
--- currentExpansion is read live rather than stored, so KEEP_CURRENT tracks a
--- new expansion launching without the player touching a setting.
---@return table
function model.GetSettingsSnapshot()
    return {
        sellJunk                     = db.char.sellJunk,
        sellEquipment                = db.char.sellEquipment,
        materialsMode                = db.char.materialsMode,
        materialsExpansion           = db.char.materialsExpansion,
        otherMode                    = db.char.otherMode,
        ilvlMargin                   = db.char.ilvlMargin,
        emphasizeQuality             = db.char.emphasizeQuality,
        keepBindOnAccount            = db.char.keepBindOnAccount,
        keepBindOnAccountPastExpac   = db.char.keepBindOnAccountPastExpac,
        keepDisenchantables          = db.char.keepDisenchantables,
        keepUsedReagents             = db.char.keepUsedReagents,
        accountProfessions           = BitForge:GetAccountProfessions(),
        keepDisenchantablesPastExpac = db.char.keepDisenchantablesPastExpac,
        isEnchanter                  = isEnchanter,
        playerClass                  = playerClass,
        currentExpansion             = GetExpansionLevel(),
    }
end

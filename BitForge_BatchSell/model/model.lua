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

        -- Warband-wide from the start. A per-class rule tree is not something a
        -- player would configure once per character, and what genuinely varies
        -- between characters already arrives as a runtime fact -- isEnchanter,
        -- playerClass, what is equipped. The per-item exception is the list's
        -- character override, which already exists.
        limitBatchTo12 = true,
        rules = {
            junk        = { sell = false },
            reagents    = { keep = true, currentExpansionOnly = false },
            -- Beside reagents rather than under armor, because the rule it
            -- governs is cross-cutting for the same reason: a cosmetic is not
            -- a class or a subclass, and the two items in #32 are weapons.
            cosmetics   = { keepUncollectedCosmetic = true },

            -- Eight subclasses carry a stored key; the rest deliberately do
            -- not. A missing key is not an oversight: it is how an
            -- unconfigured subclass keeps a defined runtime answer -- its
            -- criterion abstains, and the item is kept.
            --
            -- The fourth column, lastExpansion, is on the four a character
            -- levelling through last expansion's content still drinks and
            -- eats: potions (1), elixirs (2), flasks (3) and food (5). The
            -- other four are left without it rather than handed a column
            -- nobody asked for.
            consumables = {
                [0] = { current = true, recipesNow = false, recipesOld = false },
                [1] = {
                    current = true,
                    recipesNow = false,
                    recipesOld = false,
                    lastExpansion = false
                },
                [2] = {
                    current = true,
                    recipesNow = false,
                    recipesOld = false,
                    lastExpansion = false
                },
                [3] = {
                    current = true,
                    recipesNow = false,
                    recipesOld = false,
                    lastExpansion = false
                },
                [5] = {
                    current = true,
                    recipesNow = false,
                    recipesOld = false,
                    lastExpansion = false
                },
                [7] = { current = true, recipesNow = false, recipesOld = false },
                [8] = { current = true, recipesNow = false, recipesOld = false },
                [9] = { current = true, recipesNow = false, recipesOld = false },
            },

            gear = {
                -- Off by default: the quality veto is the opt-in amplifier
                -- above the margin ladder, not a replacement for it (#236).
                compareQuality     = false,
                compareItemLevel   = true,
                ilvlMargin         = 10,
                emphasizeQuality   = false,
                spareBindOnAccount = "CURRENT",
                spareBindOnEquip   = "CURRENT",
                keepForDisenchant  = true,
            },
            armor = { sellRelics = true },

            gems        = {
                current = true,
                recipesNow = false,
                recipesOld = false,
                keepArtifactRelics = false
            },
            tradeGoods  = { professions = 0 },
            enhancements = { keepLastExpansion = false },
            recipes     = { keepLearnable = true, keepTradeable = true },
            misc        = {
                sellCollectedMounts = true,
                sellPets = false,
                sellHoliday = false,
                sellMountEquipment = false
            },
            housing     = { sellCollectedDecor = false, keepTradeableDyes = true },
        },
    },
    char = {
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

-- limitBatchTo12 lives in db.global beside the rule tree rather than inside it:
-- it governs the sell loop, not the per-item decision, so no criterion reads it.
-- Warband-wide for the same reason everything in db.global.rules is -- nothing
-- about how many items to sell per click varies by character.

function model.GetLimitBatchTo12() return db.global.limitBatchTo12 end

function model.SetLimitBatchTo12(v) db.global.limitBatchTo12 = v end

-- The per-class criteria's own settings, warband-wide (see DB_DEFAULTS.global
-- for why). model.Decide dispatches every rule off this tree.

--- @return table  the whole rule tree, keyed by section
function model.GetRules() return db.global.rules end

--- @param section string  a top-level key of the rule tree, e.g. "gear"
--- @return table
function model.GetRule(section) return db.global.rules[section] end

--- @param section string
--- @param key string
--- @param value any
function model.SetRuleValue(section, key, value) db.global.rules[section][key] = value end

--- Writes one key into one consumable subclass.
---
--- rules.consumables is the tree's only section keyed by subclass, so
--- SetRuleValue -- which indexes a section and assigns -- would replace the
--- subclass table with the value. One extra setter rather than a path walker:
--- there is one nested shape, not a family of them.
---
--- lastExpansion extends `current` rather than standing beside it, so clearing
--- current clears it too. The rule holds that dependency on read; holding it on
--- write as well is what stops a stored true surviving behind a greyed control.
---@param subclassID number
---@param key string
---@param value any
function model.SetConsumableRuleValue(subclassID, key, value)
    local subclass = db.global.rules.consumables[subclassID]
    if not subclass then return end

    subclass[key] = value
    if key == "current" and not value and subclass.lastExpansion ~= nil then
        subclass.lastExpansion = false
    end
end

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
--- question -- which one governs.
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

local isEnchanter = false

--- @param value boolean
function model.SetIsEnchanter(value)
    isEnchanter = value
end

---@return boolean
function model.GetIsEnchanter()
    return isEnchanter
end

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

local playerClass

--- @param value string  Class filename, e.g. "WARRIOR"
function model.SetPlayerClass(value)
    playerClass = value
end

-- Everything below is snapshot-driven: facts arrive as a plain table gathered
-- by ns.control.scanner, settings as a snapshot from model.GetSettingsSnapshot.
-- Nothing here calls an API or touches a frame, and the only db read is
-- db.global.disenchantTruth, which model.IsDisenchantable consults. That is what
-- lets the cascade be tested outside the game against a stub db.

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
--- the right trade: they are overwhelmingly Poor quality, which rules.junk.sell
--- already clears, or carry no sell price at all.
function model.IsPastExpansion(facts, expansionThreshold)
    if facts.expacID == 0 then return false end
    return facts.expacID < expansionThreshold
end

--- True when the piece *occupying* a slot is last expansion's, so the bar it
--- sets is no longer worth a quality discount.
---
--- Quality is a proxy for how hard a piece was to get, and it stops meaning that
--- the moment the expansion turns over. A levelling character wears last
--- expansion's epic and loots this expansion's green with more item level on it;
--- the quality ladder in compareToSlot makes the green buy back two whole tiers
--- to survive, and sells the better item. What has gone stale is the bar, not
--- the candidate, so the test is on what is equipped.
---
--- A timewalking piece is not stale. Its expansion ID is old and its item level
--- is current, so the ID is the one field that lies about the bar it sets.
--- Chromie Time gear needs no exemption: it carries no difficulty subtext, and
--- it scales into the current band, so its bar is honest as it stands.
---@param equipped table   One entry from facts.equippedItems
---@param settings table
---@return boolean
local function equippedIsOutdated(equipped, settings)
    if equipped.isTimewalking then return false end
    if (equipped.expacID or 0) == 0 then return false end
    return (equipped.expacID or 0) < settings.currentExpansion
end

--- One equipped item's answer about one candidate: DECISION.KEEP,
--- DECISION.SELL, or nil.
---
--- The three are not two outcomes plus a fallback. SELL condemns nothing by
--- itself: judgeGear hands the piece on to the alt and disenchant questions,
--- and only gear none of the three claims reaches the vendor. nil means the
--- slot could not be read at all.
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
--- every tier given up is bought back a whole margin at a time. The discount is
--- capped at one margin however far up the ladder the candidate is, while the
--- debt keeps stacking downwards -- quality above what you wear is worth having,
--- but not worth an unbounded item level rebate.
---
--- Monotonic by construction: the bar never rises as the candidate's quality
--- rises, so improving either axis can only move a piece towards being kept.
local function compareToSlot(facts, equipped, settings)
    -- Something occupies the slot but its level or quality could not be read.
    -- Unknown is not evidence, and must never pass an item towards the vendor.
    if equipped.unreadable then return nil end

    -- A bar set last expansion is answered on item level alone: no margin, no
    -- quality credit, no tolerance. Everything below this line prices one
    -- quality tier against some number of item levels, and that trade is exactly
    -- what a stale bar no longer earns.
    if equippedIsOutdated(equipped, settings) then
        if facts.level > equipped.level then
            return enum.DECISION.KEEP, enum.RULE.OUTDATED_EXPAC
        end
        return enum.DECISION.SELL
    end

    local qualityGap = facts.quality - equipped.quality

    -- Emphasis does two things at once, and both are needed to keep the rungs
    -- evenly spaced: it doubles what a tier costs, and it grants a tolerance at
    -- the candidate's own tier. Without the second the doubling would leave the
    -- gap between "same quality" and "one tier down" three times the gap below
    -- it. Without the first the tolerance alone would only ever be leniency,
    -- and the point of emphasis is that quality below yours gets dearer too.
    local gear = settings.rules.gear
    local step = gear.ilvlMargin * (gear.emphasizeQuality and 2 or 1)
    local tolerance = gear.emphasizeQuality and gear.ilvlMargin or 0
    local level = equipped.level - tolerance

    if qualityGap > 0 then
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
--- The rule travels out alongside the decision because it varies by slot: a ring
--- can face one current-expansion finger and one stale one, and only the slot
--- that actually produced the keep knows which of the two answered.
---@param facts    table
---@param settings table
---@return string|nil  enum.DECISION.KEEP, enum.DECISION.SELL, or nil
---@return string|nil  enum.RULE.* naming what decided a KEEP, or nil
function model.CompareToEquipped(facts, settings)
    local equippedItems = facts.equippedItems
    if not equippedItems then return nil end

    local condemned, undecided = false, false
    for _, equipped in ipairs(equippedItems) do
        local verdict, rule = compareToSlot(facts, equipped, settings)
        if verdict == enum.DECISION.KEEP then return enum.DECISION.KEEP, rule end
        if verdict == enum.DECISION.SELL then
            condemned = true
        else
            undecided = true
        end
    end

    if condemned and not undecided then return enum.DECISION.SELL end
    return nil
end

--- Whether this piece is a lower quality than everything the slot holds, or
--- nil when that cannot be determined.
---
--- Existential and unanimous in the same directions CompareToEquipped is: one
--- equipped piece this beats or matches on quality clears the veto outright,
--- whatever any sibling slot's readability -- but firing the veto the other
--- way needs every equipped piece to be both readable and lower. A single
--- unreadable slot, with nothing else already having cleared the veto, is not
--- evidence that the candidate is worse than what it could not read, so the
--- result is nil rather than true.
---@param facts table
---@param settings table
---@return boolean|nil
function model.IsLowerQualityThanEquipped(facts, settings)
    local equipped = facts.equippedItems
    if not equipped or #equipped == 0 then return false end
    local unreadable = false
    for _, item in ipairs(equipped) do
        if item.unreadable then
            unreadable = true
        elseif facts.quality >= item.quality then
            return false
        end
    end
    if unreadable then return nil end
    return true
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

--- Whether the item itself can be disenchanted -- a property of the thing, not
--- of who is holding it. model.CanReachAnEnchanter asks the other half.
---
--- The client's own answer wins where one has been harvested, in both
--- directions: it is the same value the game paints the bag slot with, so an
--- item the crawl missed stops being kept and one the crawl wrongly listed
--- starts being kept. Everything unobserved falls back to the prediction.
---@param facts table
---@return boolean
function model.IsDisenchantable(facts)
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

--- Whether this copy of the item can still reach anybody but the character
--- holding it -- an alt, a buyer, a guildmate.
---
--- Judged on isBound, not bindType: bindType is the item's rule, isBound is
--- what happened to this copy. A BoE worn once is soulbound for good, and
--- keeping it "for someone else" keeps it for nobody. Warband-bound stays
--- reachable because an alt can take it, and isBindOnAccount is a gathered
--- fact rather than a bindType comparison -- the scanner asks
--- C_Item.IsItemBindToAccount, which covers all three account bind types
--- without this file knowing their numbers.
---
--- Tri-state, and callers must test it against false rather than for
--- falsiness: nil is an unread bind state, which is not evidence that nobody
--- else can have it.
---@param facts table
---@return boolean|nil  nil when the bind state could not be read
function model.CanReachAnAlt(facts)
    if facts.isBound == nil then return nil end
    return facts.isBindOnAccount == true or not facts.isBound
end

--- Whether this item can ever reach an enchanter's hands. Says nothing about
--- whether it is disenchantable -- model.IsDisenchantable answers that.
---
--- My own enchanter reaches everything I am holding; for anyone else's it is
--- the ordinary reachability question, so the two share one answer rather
--- than two spellings of it.
---@param facts table
---@param isEnchanter boolean
---@return boolean|nil  nil when the bind state could not be read
function model.CanReachAnEnchanter(facts, isEnchanter)
    if isEnchanter then return true end
    return model.CanReachAnAlt(facts)
end

-- Slots whose contents every class wears, whatever armor it is proficient in.
-- Each is Cloth by subclass, which is the whole reason this table exists: judged
-- by subclass a cloak is clothie-only, and Cosmetic does not cover them either.
local UNIVERSAL_SLOTS = {
    INVTYPE_CLOAK  = true,
    INVTYPE_BODY   = true, -- shirt
    INVTYPE_TABARD = true,
}

--- True when the given class can equip the item, false when it definitely
--- cannot, or nil when the class identity itself could not be determined.
---
--- The nil case is deliberately distinct from false: playerClassName can
--- arrive unread (a secret UnitClassBase("player") answer, or a scan that ran
--- before the module's own startup ever set it) or as a name enum.CLASS_PREFS
--- has no entry for, and neither of those is evidence that this class cannot
--- use the item -- it is evidence that the question was never actually
--- answered. Folding the two together is how an unread class identity used
--- to read as NOT_EQUIPPABLE and skip the item-level comparison that could
--- have rescued a piece any class can wear.
---@return boolean|nil
function model.IsEquippableBy(facts, playerClassName)
    if not facts.equipLoc or facts.equipLoc == "" then return false end

    local prefs = enum.CLASS_PREFS[playerClassName]
    if not prefs then return nil end

    -- Off-hand slots are separate equip restrictions, not armor subclasses.
    if facts.equipLoc == "INVTYPE_SHIELD" then return prefs.Shield == true end
    if facts.equipLoc == "INVTYPE_HOLDABLE" then return prefs.Holdable == true end

    -- Slots every class wears whatever its armor proficiency. All three are
    -- Cloth by subclass, so the armor loop below would judge them against the
    -- class's proficiency and condemn a cloak on any character who is not a
    -- clothie -- which is how a hunter's cloak came to be judged SELL under
    -- NOT_EQUIPPABLE. The slot answers before the subclass gets a say.
    if UNIVERSAL_SLOTS[facts.equipLoc] then return true end

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
--- Snapshot-driven rather than pure: facts arrive already gathered and
--- settings as a snapshot, so nothing below calls an API or touches a frame
--- -- but the gear branch does read db.global.disenchantTruth, through
--- model.IsDisenchantable.
---
--- Three regions. The cross-cutting rules are a linear cascade because their
--- order IS the cascade -- expressing it as data would buy nothing and cost the
--- ability to write a sentence beside each step. Then exactly one dispatch on
--- the item class, because classes are disjoint and ordering could never decide
--- an outcome there. Then the global fallthrough.
---
--- A criterion may return nil to abstain, and an abstention is not a quiet
--- failure -- it is the design's (#65) central protection. An item whose facts
--- could not be read reaches the fallthrough and is kept.
---@param facts    table  One item's gathered facts
---@param settings table  Snapshot from model.GetSettingsSnapshot
---@return string verdict  enum.DECISION.SELL or enum.DECISION.KEEP
---@return string rule     enum.RULE.* -- which step decided
function model.Decide(facts, settings)
    local DECISION, RULE = enum.DECISION, enum.RULE
    -- rules.junk and rules.reagents are guarded below because either
    -- sub-key can be legitimately absent; the tree itself is guarded here
    -- for the same reason a settings table a test (or a future caller) built
    -- by hand can omit it entirely, and that must read as "no rules
    -- configured" rather than crash. Written back onto settings, not kept as
    -- a private local: Region 2's dispatch hands settings straight to
    -- whichever class criterion claims facts.classID, and every one of them
    -- reads settings.rules.<name> the same unguarded way -- so the same
    -- normalized table has to be what they see too, or the fallback here
    -- would protect Decide's own reads and nothing past them.
    local rules = settings.rules or {}
    settings.rules = rules

    -- 1. Excluded for this merchant visit only.
    if facts.isTempExcluded then return DECISION.KEEP, RULE.TEMP_EXCLUDED end

    -- 2. Never Sell list, either scope.
    if facts.isProhibited then return DECISION.KEEP, RULE.BLACKLISTED end

    -- 3. Hard gates. The client will not complete these sales, so the Always
    -- Sell list does not override them.
    if facts.isLocked then return DECISION.KEEP, RULE.LOCKED end
    if facts.inEquipmentSet then return DECISION.KEEP, RULE.EQUIPMENT_SET end
    if facts.sellPrice <= 0 then return DECISION.KEEP, RULE.NO_SELL_PRICE end
    if facts.isRefundable then return DECISION.KEEP, RULE.REFUNDABLE end

    -- 4. Always Sell list. The escape hatch for the one reagent the player does
    -- want vendored, so it sits above everything that could keep it.
    if facts.isEnforced then return DECISION.SELL, RULE.WHITELISTED end

    -- 5. Dragged into the manifest for this visit. Below the list so a durable
    -- naming is reported in preference to a transient one when both apply.
    if facts.isTempIncluded then return DECISION.SELL, RULE.TEMP_INCLUDED end

    -- 6. Quality itself unreadable. Everything after this step reads
    -- facts.quality -- the junk gate and the epic ceiling directly by
    -- comparison, the class dispatch arithmetically (an item-level margin is
    -- priced in quality tiers) -- and none of that can be answered honestly,
    -- or even safely, against a value that is not a number. Guarded once,
    -- here, rather than at every downstream comparison: an unread quality
    -- used to reach step 7's `>` unguarded and crash the comparison, which
    -- (scanner.Scan not wrapping the call) aborted the rest of the bag scan
    -- along with it.
    if type(facts.quality) ~= "number" then return DECISION.KEEP, RULE.DEFAULT end

    -- 7. Poor quality, both ways. On, this module clears greys; off, the job is
    -- delegated -- to Blizzard's own button or another addon -- and judging them
    -- anyway would put them straight back in the manifest, which is the one
    -- outcome the setting exists to prevent.
    if facts.quality == Enum.ItemQuality.Poor then
        if rules.junk and rules.junk.sell then
            return DECISION.SELL, RULE.JUNK_SOLD
        end
        return DECISION.KEEP, RULE.JUNK
    end

    -- 8. Above epic. The client reports a price for these and then refuses the
    -- sale, so sellPrice cannot stop them at step 3.
    if facts.quality > Enum.ItemQuality.Epic then
        return DECISION.KEEP, RULE.ABOVE_EPIC
    end

    -- 9. A reagent a profession that can actually get at this copy uses,
    -- whatever class it is filed under. Checked before the item's type because
    -- reagents turn up as potions, gems and trade goods alike.
    --
    -- Which mask vouches for it depends on the copy, not on the item. The
    -- account mask is the union over every character, and for a soulbound
    -- copy that union is a lie: no alt can ever touch this one, so no alt's
    -- profession may keep it. Tested against false rather than for falsiness
    -- -- an UNREAD bind state keeps the account mask, because keeping is the
    -- safe direction and only a definite "nobody else can have this" earns
    -- the narrower question.
    --
    -- Off by default, the expansion companion: a reagent's value does not
    -- decay with age, and an Alchemy recipe that wants a Classic herb wants it
    -- exactly as much now. currentExpansionOnly is there for players who
    -- disagree, and has to be switched on.
    local reagents = rules.reagents
    if reagents and reagents.keep and facts.reagentProfessions then
        local wanted = settings.accountProfessions
        if model.CanReachAnAlt(facts) == false then
            wanted = settings.characterProfessions
        end

        local tooOld = reagents.currentExpansionOnly
            and model.IsPastExpansion(facts, settings.currentExpansion)

        if not tooOld and band(facts.reagentProfessions, wanted) ~= 0 then
            return DECISION.KEEP, RULE.REAGENT_WANTED
        end
    end

    -- 10. An appearance this collection has never seen. Cross-cutting for the
    -- same reason step 9 is: a cosmetic can be filed under any class, and
    -- there is no cosmetic subclass to dispatch on -- both items in #32 are
    -- weapons, which is how a rule scoped to Armor's Cosmetic (5) came to sell
    -- an appearance the player had never collected.
    --
    -- Selling one is irreversible in a way nothing else in this cascade is: an
    -- unsold item can be sold next visit, and a destroyed appearance cannot be
    -- recovered at all. So BOTH unread facts keep rather than continue -- not
    -- knowing whether the item is cosmetic is as disqualifying as not knowing
    -- whether its appearance is collected, and neither may be read as a no.
    --
    -- A collected cosmetic is not condemned here, only released: it carries
    -- nothing left to protect, so it goes on to its class criterion and is
    -- judged as the weapon or armor it is.
    local cosmetics = rules.cosmetics
    if cosmetics and cosmetics.keepUncollectedCosmetic then
        if facts.isCosmetic == nil then return DECISION.KEEP, RULE.DEFAULT end
        if facts.isCosmetic then
            if facts.appearanceCollected == nil then return DECISION.KEEP, RULE.DEFAULT end
            if not facts.appearanceCollected then
                return DECISION.KEEP, RULE.NOT_COLLECTED
            end
        end
    end

    -- Region 2. One dispatch, because item classes are disjoint.
    local criterion = model.rules.CLASS_RULES[facts.classID]
    if criterion then
        local verdict, ruleKey = criterion(facts, settings)
        if verdict then return verdict, ruleKey end
    end

    -- Region 3. Nobody claimed it, or whoever did had no evidence to condemn on.
    return DECISION.KEEP, RULE.DEFAULT
end

--- Reads the settings the cascade consults, once per scan rather than per item.
--- limitBatchTo12 is deliberately absent: it governs the sell loop, not the
--- per-item decision, and lives behind its own accessor (model.GetLimitBatchTo12)
--- rather than in this snapshot.
---
--- currentExpansion is read live rather than stored, so every criterion that
--- prices an item against the current expansion follows a launch without the
--- player touching a setting.
---
--- Both profession masks travel, because which one vouches for a reagent is a
--- property of the copy in the bag: the account mask cannot speak for a
--- soulbound one (see step 9 of model.Decide), and neither mask can be
--- derived from the other.
---@return table
function model.GetSettingsSnapshot()
    return {
        accountProfessions   = BitForge:GetAccountProfessions(),
        characterProfessions = BitForge:GetCharacterProfessionMask(BitForge:GetCurrentCharacter()),
        isEnchanter          = isEnchanter,
        playerClass          = playerClass,
        currentExpansion     = GetExpansionLevel(),
        rules                = db.global.rules,
    }
end

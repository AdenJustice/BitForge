---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...

local ipairs = ipairs
local pairs = pairs
local next = next
local type = type
local wipe = wipe or function(target)
    for key in pairs(target) do target[key] = nil end
end

local band = bit.band
local lshift = bit.lshift

-- Aliased above DB_DEFAULTS rather than beside model: the literal names
-- enum.EXPANSION_* directly, and Init.lua is loaded first.
local enum = ns.enum

local DB_DEFAULTS = {
    global = {
        -- Warband-wide, because that is the scope Openables' own enable flag
        -- had. The three switches deliberately do not share a scope: each keeps
        -- the one its module used, so no player's stored value has to be
        -- re-homed to make the trio look symmetrical.
        openEnabled = true,
        -- Openables' five stored button properties, gathered under one key
        -- rather than left as five siblings of everything else this module now
        -- stores. The stored VALUES are unchanged; only their address is.
        button = {
            locked       = false,
            size         = 42,
            showCount    = true,
            showCooldown = true,
            point = { point = "CENTER", relPoint = "CENTER", x = 0, y = -150 },
        },

        -- The merged per-item override store, spec #331 section 5 (plan #368),
        -- and since schema 3 the only place a player's opinion about an item
        -- is kept. model/overrides.lua is the only file that ever touches this
        -- address -- see model.GetOverrideStore below.
        --
        -- MUST stay exactly {}, at every depth, forever. PruneMatchingDefaults
        -- (BitForge/model.lua) walks the DEFAULT's own keys, not the saved
        -- table's, so an empty default here is the only reason today's
        -- itemID-keyed records are invisible to it. Naming so much as one
        -- field here does not prune that field out of an item's record --
        -- itemIDs and field names live in disjoint key spaces, so nothing
        -- collides -- it instead seeds that field directly onto THIS
        -- collection on the very next login (SeedDefaults treats a missing
        -- key here exactly like a missing key anywhere else), and the logout
        -- prune then deletes it again next time, oscillating a stray key in
        -- and out of every profile's saved file forever.
        -- tests/test_azerothprime_overrides.lua drives the real prune and the
        -- real seed against this literal default to pin it.
        itemOverrides = {},

        -- The recipes a player says they actually craft (spec #379):
        -- [recipeID] = true, and nothing ever stores false. Account-wide
        -- because the reagent rule it narrows is account-wide too -- a reagent
        -- the alchemist's flagged recipe needs must not be sold by a scan
        -- running on the hunter. model/sparedRecipes.lua is the only file that
        -- touches this address; see model.GetSparedRecipeStore below.
        --
        -- MUST stay exactly {}, for the reason itemOverrides above gives at
        -- length: recipeID-keyed entries are invisible to the logout prune
        -- only while the default names no key of its own.
        -- tests/test_azerothprime_sparedrecipes.lua drives the real prune and the
        -- real seed against this literal to pin it.
        sparedRecipes = {},

        -- [charKey] = { [recipeSpellID] = true }. Absent means "never scanned",
        -- which reads as "knows nothing" and biases toward depositing --
        -- deliberately, see the design (#55) 5.5.
        knownRecipes = {},

        -- [charKey] = { [skillLineID] = timestamp }. Exists so the curation
        -- window can name characters that have never been scanned; an unscanned
        -- character is indistinguishable from one who knows nothing without it.
        recipeScans = {},

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
            -- EXPANSION_CURRENT, where this shipped as EXPANSION_ALL until
            -- spec #379. Keeping every catalogued reagent any profession on
            -- the account might one day use is the complaint in #354; what a
            -- player still wants out of a finished expansion is now named by
            -- flagging the recipe, which model.Decide's step 9 asks after
            -- this mask.
            --
            -- Existing profiles move with it, deliberately and with no
            -- migration: a player who never touched the setting has the old
            -- default stored, so the logout prune drops it and the next login
            -- seeds this one. Past-expansion reagents start being offered for
            -- sale without them doing anything.
            reagents    = { keep = true, expansions = enum.EXPANSION_CURRENT },
            -- Beside reagents rather than under armor, because the rule it
            -- governs is cross-cutting for the same reason: a cosmetic is not
            -- a class or a subclass, and the two items in #32 are weapons.
            cosmetics   = { keepUncollectedCosmetic = true },

            -- Eight subclasses carry a stored row; the rest deliberately do
            -- not. A missing row is not an oversight: it is how an
            -- unconfigured subclass keeps a defined runtime answer -- its
            -- criterion abstains, and the item is kept.
            --
            -- Every row now carries the same three keys. The fourth,
            -- lastExpansion, is gone: it existed to offer the one expansion a
            -- boolean could name, and the mask names any of them.
            consumables = {
                [0] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
                [1] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
                [2] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
                [3] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
                [5] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
                [7] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
                [8] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
                [9] = { expansions = enum.EXPANSION_CURRENT, recipesNow = false, recipesOld = false },
            },

            gear = {
                -- Two independent dials, and the whole comparison. margin is
                -- slack at the player's own quality; qualityMargin is what one
                -- tier costs. 0/10 is what ilvlMargin 10 with emphasis off
                -- resolved to, so the shipped comparison is unchanged.
                margin             = 0,
                qualityMargin      = 10,
                spareBindOnAccount = enum.EXPANSION_CURRENT,
                spareBindOnEquip   = enum.EXPANSION_CURRENT,
                keepForDisenchant  = enum.EXPANSION_CURRENT,
            },
            armor = { sellRelics = true },

            gems        = {
                expansions = enum.EXPANSION_CURRENT,
                recipesNow = false,
                recipesOld = false,
                keepArtifactRelics = false
            },
            tradeGoods  = { professions = 0 },
            enhancements = { expansions = enum.EXPANSION_CURRENT },
            recipes     = { keepLearnable = true, keepTradeable = true },
            misc        = {
                sellCollectedMounts = true,
                sellCollectedToys = true,
                sellPets = false,
                sellHoliday = false,
                sellMountEquipment = false
            },
            housing     = { sellCollectedDecor = false, keepTradeableDyes = true },
        },
    },
    char = {
        -- New. Selling never had a switch of its own, because turning the
        -- feature off meant disabling the addon -- which merging removes. On by
        -- default is safe: the shipped rules sell nothing until one is set.
        sellEnabled = true,
        -- UPS's own scope, kept.
        bankEnabled = true,
        previewMoves = true,

        -- Defaults on. Depositing a reagent nobody can craft with only moves it
        -- from one container to another, but the warband bank is finite, and a
        -- player who wants everything there for the auction house can say so.
        onlyWantedReagents = true,

        professionRanks = {},

        -- The merged store's character scope. Carries only `sell` -- the
        -- other two opinions had one scope each before the merge and gain
        -- nothing from a second, and spec #331 section 5 says scopes are
        -- preserved rather than unified. Same {}-only constraint as
        -- global.itemOverrides above, for the same reason.
        itemOverrides = {},
    },
}
local db

-- The sub-key files publish onto this table but must not widen it, so the
-- fields they add are declared here, on the file that owns the key.
---@class BitForge.AzerothPrime.Model
---@field arbiter BitForge.AzerothPrime.Model.Arbiter
---@field facts BitForge.AzerothPrime.Model.Facts
---@field openRules BitForge.AzerothPrime.Model.OpenRules
---@field zone BitForge.AzerothPrime.Model.Zone
---@field bankRules BitForge.AzerothPrime.Model.BankRules
---@field rules BitForge.AzerothPrime.Model.Rules
---@field overrides BitForge.AzerothPrime.Model.Overrides
---@field sparedRecipes BitForge.AzerothPrime.Model.SparedRecipes
---@field allowAudit BitForge.AzerothPrime.Model.AllowAudit
-- Nilable: a release build ships no debug/lines.lua at all.
---@field debugNotices BitForge.AzerothPrime.Model.DebugNotices|nil
local model = ns.model

BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB)
    db = moduleDB
end)

--- Whether a value the client answered with cannot be compared as a number.
---
--- Two different refusals, and both have to be caught here because the caller's
--- next move is an inequality that raises on either. A secret value is the
--- client declining to tell this addon; nil is an answer that has not arrived,
--- or an item with no such field at all.
---
--- issecretvalue is the documented test and the only one that works: a secret
--- is not a distinct Lua type, which is why Blizzard ships a predicate for it
--- rather than letting type() answer -- Blizzard_SharedXML/Dump.lua picks its
--- format from issecretvalue, and Blizzard_EventTrace formats the value first
--- and asks afterwards. A type() check alone catches only the nil half.
---
--- The global itself is guarded rather than assumed, the same way
--- BitForge/model.lua's own secret-value reads guard it: a client without
--- secret-value restrictions does not define it.
---@param value any
---@return boolean
function model.IsUnread(value)
    if issecretvalue and issecretvalue(value) then return true end
    return type(value) ~= "number"
end

--- The module's debug flag: a hand-written sibling of global and char in the
--- saved variables, deliberately outside the schema. Read live rather than
--- cached, so setting it with /run takes effect on the next tooltip without a
--- reload. db is private to this file, which is why view/button.lua reaches it here.
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

function model.IsOpenEnabled() return db.global.openEnabled end
function model.SetOpenEnabled(value) db.global.openEnabled = value end

function model.IsSellEnabled() return db.char.sellEnabled end
function model.SetSellEnabled(value) db.char.sellEnabled = value end

function model.IsBankEnabled() return db.char.bankEnabled end
function model.SetBankEnabled(value) db.char.bankEnabled = value end

function model.GetLocked() return db.global.button.locked end

function model.SetLocked(value) db.global.button.locked = value end

function model.GetButtonSize() return db.global.button.size end

function model.SetButtonSize(value) db.global.button.size = value end

function model.GetShowCount() return db.global.button.showCount end

function model.SetShowCount(value) db.global.button.showCount = value end

function model.GetShowCooldown() return db.global.button.showCooldown end

function model.SetShowCooldown(value) db.global.button.showCooldown = value end

function model.GetPoint()
    return db.global.button.point
end

function model.SetPoint(point, relPoint, x, y)
    local stored = db.global.button.point
    stored.point, stored.relPoint, stored.x, stored.y = point, relPoint, x, y
end

--- Every expansion line this character has been seen to hold, by profession.
---
--- The stored table itself rather than a copy: detector.RefreshProfessions
--- walks it on every skill-line change and at startup, and callers only read.
---@return table<string, table<string, number>>
function model.GetProfessionRanks()
    return db.char.professionRanks
end

--- Replaces one profession's lines with what the client just stated.
---
--- Wholesale rather than merged. A rank only ever rises, so merging looks safe
--- -- but the client stops reporting a line the player has dropped, and a merge
--- would keep answering requirements with it forever.
---@param parentName string
---@param lines table<string, number>
function model.SetProfessionRanks(parentName, lines)
    if not parentName then return end
    db.char.professionRanks[parentName] = lines
end

function model.GetPreviewMoves() return db.char.previewMoves end

function model.SetPreviewMoves(value) db.char.previewMoves = value end

function model.GetOnlyWantedReagents() return db.char.onlyWantedReagents end

-- Invalidates: model.bankRules.ResolveByRule reads this to decide whether an
-- uncatalogued reagent is deposited, and a deposit claim outranks a sell one,
-- so the switch changes what the manifest offers. See model/overrides.lua's
-- SetField.
function model.SetOnlyWantedReagents(value)
    db.char.onlyWantedReagents = value
    model.facts.Invalidate()
end

---@param charKey string
---@param spellID number
---@return boolean
function model.IsRecipeKnown(charKey, spellID)
    local known = db.global.knownRecipes[charKey]
    return known ~= nil and known[spellID] == true
end

--- Records or retracts one learned recipe.
---
--- Retraction is not symmetry for its own sake: a harvest reports both learned
--- and unlearned recipes, and the unlearned ones are how losing a profession
--- ever gets noticed. Retracting a recipe that was never recorded creates no
--- table, so a character this module has no record of stays absent from the DB
--- rather than gaining an empty entry the logout prune would have to clear.
---@param charKey string
---@param spellID number
---@param known boolean
function model.SetRecipeKnown(charKey, spellID, known)
    local recorded = db.global.knownRecipes[charKey]

    if not recorded then
        if not known then return end
        recorded = {}
        db.global.knownRecipes[charKey] = recorded
    end

    recorded[spellID] = known and true or nil
end

---@param charKey string
---@param skillLineID number
---@return number|nil timestamp
function model.GetRecipeScan(charKey, skillLineID)
    local scans = db.global.recipeScans[charKey]
    return scans and scans[skillLineID] or nil
end

---@param charKey string
---@param skillLineID number
---@param timestamp number
function model.SetRecipeScan(charKey, skillLineID, timestamp)
    local scans = db.global.recipeScans[charKey]

    if not scans then
        scans = {}
        db.global.recipeScans[charKey] = scans
    end

    scans[skillLineID] = timestamp
end

--- Whether a character has ever had any recipe scan recorded.
---
--- Deliberately "any", not "this skill line": this module cannot open a
--- profession window itself -- C_TradeSkillUI.OpenTradeSkill is protected --
--- so it only ever harvests the expansion tab the player happened to be
--- looking at. Which child lines that covers is not knowable in advance, so
--- the only honest question is whether this character has been seen at all.
---@param charKey string
---@return boolean
function model.HasAnyRecipeScan(charKey)
    local scans = db.global.recipeScans[charKey]
    return scans ~= nil and next(scans) ~= nil
end

--- Whether any private override exists at all.
---
--- The reclaim pass reads every purchased warband tab, which is the most
--- expensive read the module performs. This is the gate that skips it, and it
--- is false for every profile until the user curates a private item.
---
--- Asks model.overrides rather than reading a store of its own: this file
--- holds no override accessors any more, and control/deposit.lua's gate is
--- the one question about the merged store that is asked before any itemID
--- exists to ask it of.
---@return boolean
function model.HasPrivateOverrides()
    return model.overrides.AnyBank(enum.DESTINATION.PRIVATE)
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

--- Invalidates: model.Decide dispatches every criterion off this tree through
--- the settings snapshot, which no record holds, so a rule the player has just
--- changed would otherwise be judged against verdicts model/arbiter.lua
--- memoised before the change. See model/overrides.lua's SetField.
--- @param section string
--- @param key string
--- @param value any
function model.SetRuleValue(section, key, value)
    db.global.rules[section][key] = value
    model.facts.Invalidate()
end

--- Writes one key into one consumable subclass.
---
--- rules.consumables is the tree's only section keyed by subclass, so
--- SetRuleValue -- which indexes a section and assigns -- would replace the
--- subclass table with the value. One extra setter rather than a path walker:
--- there is one nested shape, not a family of them.
---@param subclassID number
---@param key string
---@param value any
function model.SetConsumableRuleValue(subclassID, key, value)
    local subclass = db.global.rules.consumables[subclassID]
    if not subclass then return end

    subclass[key] = value
    model.facts.Invalidate()
end

--- The merged per-item override collection for one scope. The one seam
--- db.itemOverrides crosses out of this file, and it exists for exactly one
--- reader: model/overrides.lua captures this function into its own upvalue
--- the moment it loads -- directly after this file in the .toc, with nothing
--- in between -- and immediately clears this field, so no file loaded after
--- it can ever see a non-nil model.GetOverrideStore. That is what makes "one
--- write path" a fact rather than a comment: a caller reaching for this
--- later does not silently bypass model/overrides.lua's invalidation, it
--- raises, "attempt to call a nil value".
---@param scope string  enum.LIST_SCOPE value
---@return table  itemID -> override record
function model.GetOverrideStore(scope)
    return db[scope].itemOverrides
end

--- The recipes a player has flagged as ones they craft. The one seam
--- db.global.sparedRecipes crosses out of this file, and it is captured and
--- revoked exactly as GetOverrideStore above is, by the one file allowed to
--- write the store: model/sparedRecipes.lua takes it as it loads, so no file
--- after it can reach past that file's single write path and change the flag
--- set without the reagent index and the fact generation following.
---@return table  recipeID -> true
function model.GetSparedRecipeStore()
    return db.global.sparedRecipes
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

-- Every mutator below invalidates model.facts: isTempExcluded and
-- isTempIncluded are fields read off tempExcludes/tempIncludes (lazily --
-- see model/facts.lua -- but still cached for the life of the record once
-- asked), so a record already holding an answer would otherwise keep it
-- after the drag or the exclude button changes the membership. The setter
-- invalidates rather than its caller, for the reason model/overrides.lua's
-- SetField gives.

function model.AddTempExclude(itemLink)
    tempExcludes[itemLink] = true
    model.facts.Invalidate()
end

function model.IsTempExcluded(itemLink)
    return tempExcludes[itemLink] == true
end

function model.ClearTempExcludes()
    wipe(tempExcludes)
    model.facts.Invalidate()
end

function model.RemoveTempExclude(itemLink)
    tempExcludes[itemLink] = nil
    model.facts.Invalidate()
end

local tempIncludes = {}

function model.AddTempInclude(itemLink)
    tempIncludes[itemLink] = true
    model.facts.Invalidate()
end

function model.IsTempIncluded(itemLink)
    return tempIncludes[itemLink] == true
end

function model.ClearTempIncludes()
    wipe(tempIncludes)
    model.facts.Invalidate()
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

-- Everything below is snapshot-driven: facts arrive as a plain table -- from
-- model.facts, through control.sellScanner's thin Gather wrapper, or from
-- GatherByID's own table for an item with no bag slot to key a record by --
-- and settings as a snapshot from model.GetSettingsSnapshot. Nothing here
-- calls an API or touches a frame, and the only db read is
-- db.global.disenchantTruth, which model.IsDisenchantable consults. That is
-- what lets the cascade be tested outside the game against a stub db.

--- @return number
function model.GetTotalSellValue(facts)
    return facts.sellPrice * facts.stackCount
end

--- True when the item predates the configured expansion threshold.
---
--- expacID uses LE_EXPANSION_* numbering, which is 0-based: Classic is 0, The
--- War Within 10, Midnight 11. Zero is Vanilla, and Vanilla is past against
--- every threshold above it like any other expansion. Never restore the
--- `expacID == 0 then return false` guard that used to stand ahead of the
--- comparison: it rested on current content carrying 0 often enough that
--- reading 0 as Vanilla would sweep current crafting materials into a
--- past-expansion sell, and that is false (spec #379). expacID is reliable for
--- an item exclusive to one expansion, which is nearly all of them.
---
--- The unreliable case is an item appearing in both late Vanilla and early
--- Burning Crusade -- it belongs to neither exclusively, so it reports the
--- CURRENT expansion and reads as not past. It answers to recipesNow, and
--- recipesOld can never reach it. Stated rather than fixed: no field tells it
--- apart from genuinely current content.
---
--- model.IsExpansionSelected reads 0 the same way, and the two must agree: a
--- zero that is Vanilla to one and unknown to the other is exactly the split
--- this file used to carry.
function model.IsPastExpansion(facts, expansionThreshold)
    return facts.expacID < expansionThreshold
end

--- Whether an expansion selection covers this item.
---
--- The one question every expansion setting asks, replacing sparesIt's three-way
--- and the `current` booleans beside it.
---
--- expacID 0 is Vanilla and answers to bit 0 like any other expansion. Never
--- restore the `expacID == 0 then return true` guard that used to stand ahead
--- of the mask, for the reason model.IsPastExpansion above gives about its own
--- (spec #379). Here the late-Vanilla/early-Burning-Crusade item reports the
--- CURRENT expansion, so it stays under a current-expansion mask and out of
--- reach of every tick -- the misreading errs toward keeping, which is why no
--- guard is owed.
---
--- An expansion newer than the threshold answers to CURRENT rather than to a bit
--- of its own -- the same direction IsPastExpansion takes, where anything not
--- past is current.
---@param mask number|nil
---@param facts table
---@param settings table
---@return boolean
function model.IsExpansionSelected(mask, facts, settings)
    mask = mask or 0
    if band(mask, enum.EXPANSION_ALL) ~= 0 then return true end
    if facts.expacID >= settings.currentExpansion then
        return band(mask, enum.EXPANSION_CURRENT) ~= 0
    end
    return band(mask, lshift(1, facts.expacID)) ~= 0
end

--- True when the piece *occupying* a slot is last expansion's.
---
--- It decides one thing: which reason a keep against this slot is reported
--- under. RULE.OUTDATED_EXPAC rather than RULE.EQUIPPABLE says the candidate
--- won against a bar the game has moved past, which is a different sentence in
--- the tooltip and a different thing for a player to act on. Nothing about
--- what is computed depends on it -- see compareToSlot, which used to branch
--- here and no longer does.
---
--- A timewalking piece is not stale. Its expansion ID is old and its item level
--- is current, so the ID is the one field that lies about the bar it sets.
--- Chromie Time gear needs no exemption: it carries no difficulty subtext, and
--- it scales into the current band, so its bar is honest as it stands.
---
--- It tells the truth about what the piece is made of, though: a rescue
--- asking what the item yields must NOT inherit this exemption. Same field,
--- two questions, two answers.
---
--- Nobody should reach for the other answer casually, either: the candidate in
--- the bags carries no isTimewalking at all. It is gathered per equipped
--- inventory slot, at most two per candidate (model/facts.lua's
--- equippedItems), so testing it on a candidate would cost a tooltip read
--- for every bag item on every scan.
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
--- Two dials, and the ladder they build. `margin` lowers the bar once at every
--- quality; `qualityMargin` is what one tier is worth. Writing the lowered bar
--- as `bar = equipped - margin`, the tiers are not symmetric about it:
---
---   a tier up or more    KEEP at  bar - qualityMargin
---   same quality         KEEP at  bar, or above
---   a tier down or more  KEEP at  bar + qualityMargin * tiers, or above
---
--- Every branch clears on a match, not only on a beat: a piece that merely
--- ties the bar is not worse than what you are wearing, and this criterion
--- condemns only on evidence -- a tie is not evidence of anything. Every tier
--- given up is bought back a whole qualityMargin at a time. The discount is
--- capped at one qualityMargin however far up the ladder the candidate is,
--- while the debt keeps stacking downwards -- quality above what you wear is
--- worth having, but not worth an unbounded item level rebate.
---
--- `qualityMargin` has one position above its range for the case that rebate
--- deliberately excludes: at enum.QUALITY_MARGIN_ALWAYS the step is unbounded,
--- so any higher quality is kept whatever its item level and no item level
--- buys a lower one back. Both halves are the same infinity read in the two
--- directions, which is why one substitution expresses them.
---
--- Monotonic by construction: the bar never rises as the candidate's quality
--- rises, so improving either axis can only move a piece towards being kept.
local function compareToSlot(facts, equipped, settings)
    -- Something occupies the slot but its level or quality could not be read.
    -- Unknown is not evidence, and must never pass an item towards the vendor.
    if equipped.unreadable then return nil end

    local qualityGap = facts.quality - equipped.quality

    -- One dial each, and nothing derives one from the other: tolerance moves
    -- the whole ladder down without changing its spacing, while step is
    -- asymmetric -- capped at one tier above the slot, uncapped below it (see
    -- the doc comment above).
    local gear = settings.rules.gear
    local step = gear.qualityMargin
    -- The multiplication below cannot go indeterminate: that limb runs only
    -- where qualityGap is negative, so the multiplier is at least 1.
    if step >= enum.QUALITY_MARGIN_ALWAYS then step = math.huge end
    local tolerance = gear.margin
    local level = equipped.level - tolerance

    local keep
    if qualityGap > 0 then
        keep = facts.level >= level - step
    elseif qualityGap == 0 then
        keep = facts.level >= level
    else
        -- qualityGap is negative here, so negating it is the number of tiers
        -- given up, and each one is a whole step the candidate has to make
        -- back.
        keep = facts.level >= level + step * -qualityGap
    end

    if not keep then return enum.DECISION.SELL end

    -- A bar set last expansion is answered by the same two margins as any
    -- other. That REVERSES what this function used to do -- it read a stale
    -- bar on item level alone, on the argument that the quality trade "is
    -- exactly what a stale bar no longer earns" -- and the reversal is
    -- deliberate: there is one arithmetic in this rule now. Do not restore the
    -- special case as a fix. What staleness still decides is the reason a keep
    -- is reported under, because a player reading the tooltip is owed the
    -- difference between beating what they wear and outliving it.
    if equippedIsOutdated(equipped, settings) then
        return enum.DECISION.KEEP, enum.RULE.OUTDATED_EXPAC
    end
    return enum.DECISION.KEEP
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
--- Judged on isBound alone. Bound is bound: a Warbound piece that has been
--- equipped is soulbound like any other, so isBindOnAccount is not consulted
--- here at all once a copy is bound -- it names what the item's bind TYPE
--- once allowed, not where this particular copy can go now, and reading it
--- would keep a piece for an alt who can never actually receive it.
---
--- Tri-state, and callers must test it against false rather than for
--- falsiness: nil is an unread bind state, which is not evidence that nobody
--- else can have it.
---@param facts table
---@return boolean|nil  nil when the bind state could not be read
function model.CanReachAnAlt(facts)
    if facts.isBound == nil then return nil end
    return not facts.isBound
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
    -- (sellScanner.Scan not wrapping the call) aborted the rest of the bag
    -- scan along with it.
    if model.IsUnread(facts.quality) then return DECISION.KEEP, RULE.DEFAULT end

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
    -- Two layers ask whether the item is wanted, in order (spec #379): the
    -- expansion picker, which ships at the current expansion, and then the
    -- recipes the player flagged. The second only ever ADDS -- it cannot take
    -- back what the mask already keeps -- so flagging a recipe cannot cause a
    -- sale, which is why it needs no setting of its own and why a player who
    -- has flagged nothing sees exactly the picker they had before.
    --
    -- Wanted by neither is released, not condemned. Falling through leaves
    -- every later rule able to keep the item, where a SELL here would bypass
    -- them -- which is why the second layer adds no rule key of its own.
    local reagents = rules.reagents
    if reagents and reagents.keep then
        local flagged = model.sparedRecipes.WantsReagent(facts.itemID)

        if facts.reagentProfessions then
            local wanted = settings.accountProfessions
            if model.CanReachAnAlt(facts) == false then
                wanted = settings.characterProfessions
            end

            local selected =
                model.IsExpansionSelected(reagents.expansions, facts, settings)
                or flagged

            if selected and band(facts.reagentProfessions, wanted) ~= 0 then
                return DECISION.KEEP, RULE.REAGENT_WANTED
            end
        elseif flagged then
            -- No catalogue entry, so there is no mask to test against: the
            -- catalogue is the only thing that answers which professions want
            -- an item, and it has never heard of this one.
            --
            -- The flagged layer never consulted the catalogue anyway --
            -- sparedRecipes reads the item off the recipe's own schematic --
            -- so the flag is the only answer that exists here, and a flag is
            -- an instruction rather than a preference. Dropping it on a
            -- question with no source is what #466 was.
            return DECISION.KEEP, RULE.REAGENT_WANTED
        end
    end

    -- 10. An appearance this collection has never seen. Cross-cutting rather
    -- than filed under the gear criterion -- #32's own shape is told in full
    -- at control.lua's isCosmetic gather and rules.lua's Armor criterion.
    -- What is only argued here is why it has to sit above the
    -- class-proficiency question rather than move into judgeGear: cosmetic
    -- armor already has an explicit exception in IsEquippableBy, so it is
    -- never charged NOT_EQUIPPABLE there, but cosmetic weapons have no such
    -- exception -- filed inside judgeGear, an off-class cosmetic weapon would
    -- carry that charge to step 8 and lose its uncollected appearance unless
    -- another rescue happened to catch it first.
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

--- Reads the settings the cascade consults.
---
--- Built once per generation rather than once per item, and the memo is
--- model/rules.lua's rather than this function's: the sell claimant is the
--- only caller in a per-item position, and every other one -- a dump, a
--- tooltip report -- wants a snapshot taken now. Before the manifest went
--- through the arbiter, sellScanner.Scan hoisted this out of its own loop and
--- the two amounted to the same thing; the claimant contract takes one item
--- and no scan, so the hoist had to move to where the claim is made.
---
--- limitBatchTo12 is deliberately absent, for the reason stated beside
--- model.GetLimitBatchTo12: no criterion reads it.
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

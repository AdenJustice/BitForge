---@class BitForge.Dispatch
local ns = select(2, ...)

---@class BitForge.Dispatch.Model
local model = ns.model
---@type BitForge.Dispatch.Enum
local enum = ns.enum
local ItemClass = Enum.ItemClass

local DECISION, RULE, CLAIM = enum.DECISION, enum.RULE, enum.CLAIM

local band = bit.band

local GEM_ARTIFACT_RELIC = 11

--- One criterion per item class. A class absent from this table is not judged
--- at all -- which is how quest items, projectiles, spell reagents and whatever
--- class Blizzard adds next reach the global KEEP without a branch of their own.
---@type table<number, fun(facts: table, settings: table): string|nil, string|nil>
local CLASS_RULES = {}

--- The two recipe columns, which Consumables and Gems ask identically.
---
--- ReagentData.lua is read as complete: an item it does not list is an item no
--- recipe crafts with, which is the same answer as a mask nothing overlaps. The
--- catalogue is a capture of a client build (enum.REAGENT_DATA_INTERFACE stamps
--- which), so this is a decision about how to read a gap in it rather than a
--- fact about the game -- ruled on in #330, where every uncatalogued past-
--- expansion consumable was held forever while catalogued real reagents sold.
--- Re-capture the table rather than restoring an abstain here.
---
--- Which column applies is resolved first, from isPast alone -- recipesOld for
--- a past item, recipesNow for a current one -- and only that column is ever
--- asked. Still the binary split, and deliberately: the two columns are a pair
--- of settings SELECTED BY the item's age, not settings about it.
---@param facts table
---@param opts table  the criterion's stored options
---@param isPast boolean
---@param keepRule string  enum.RULE.* to return when the column keeps it
---@return string|false
local function recipeColumnsKeep(facts, opts, isPast, keepRule)
    local ticked
    if isPast then
        ticked = opts.recipesOld
    else
        ticked = opts.recipesNow
    end
    if not ticked then return false end

    if (facts.reagentProfessions or 0) == 0 then return false end

    return keepRule
end

--- Bags and profession gear are never sold. Which bags you carry is the
--- player's own arrangement, and profession gear is either worth money on the
--- auction house or was crafted for this character -- there is no case where
--- vendoring one is right. No terminal, because neither ever condemns.
CLASS_RULES[ItemClass.Container] = function()
    return DECISION.KEEP, RULE.BAG_KEPT
end

CLASS_RULES[ItemClass.Profession] = function()
    return DECISION.KEEP, RULE.PROFESSION_GEAR_KEPT
end

--- A new expansion caps the gear an enhancement can be applied to, so an
--- enhancement is worth exactly as much as the gear it still fits. Which
--- expansions those are is the player's answer, not this rule's: the shipped
--- default keeps the current one, and a character levelling through older
--- content can tick the expansion they are actually wearing.
CLASS_RULES[ItemClass.ItemEnhancement] = function(facts, settings)
    local opts = settings.rules.enhancements
    if not opts then return nil end

    if model.IsExpansionSelected(opts.expansions, facts, settings) then
        return DECISION.KEEP, RULE.ENHANCEMENT_EXPANSION
    end
    return DECISION.SELL, RULE.NOT_WANTED
end

--- Pick what to keep for each kind of consumable; anything no box keeps is sold.
---
--- A subclass with no stored key has no rule here, so it abstains -- which is
--- how the subclasses DB_DEFAULTS leaves out keep a defined runtime answer
--- without owning a setting.
---
--- The two recipe columns test the catalogue for ANY profession, not this
--- account's: an item this account's professions want was already kept by the
--- cross-cutting Crafting Reagents rule, so these columns exist for everyone
--- else's recipes.
CLASS_RULES[ItemClass.Consumable] = function(facts, settings)
    local opts = settings.rules.consumables and settings.rules.consumables[facts.subclassID]
    if not opts then return nil end

    if model.IsExpansionSelected(opts.expansions, facts, settings) then
        return DECISION.KEEP, RULE.CONSUMABLE_EXPANSION
    end

    local isPast = model.IsPastExpansion(facts, settings.currentExpansion)
    local kept = recipeColumnsKeep(facts, opts, isPast, RULE.CONSUMABLE_REAGENT)
    if kept then return DECISION.KEEP, kept end

    return DECISION.SELL, RULE.NOT_WANTED
end

--- One set of choices for every gem. Gem subclasses are stat types --
--- Intellect, Agility, Strength -- and none of that bears on whether a gem is
--- worth keeping. Artifactrelic (11) is the one real distinction, and it is
--- decided alone: it is dead Legion content, socketed into an artifact, and
--- unrelated to Armor's own Relic (11), which was worn in a dedicated slot.
CLASS_RULES[ItemClass.Gem] = function(facts, settings)
    local opts = settings.rules.gems
    if not opts then return nil end

    if facts.subclassID == GEM_ARTIFACT_RELIC then
        if opts.keepArtifactRelics then
            return DECISION.KEEP, RULE.GEM_ARTIFACT_RELIC_KEPT
        end
        return DECISION.SELL, RULE.NOT_WANTED
    end

    if model.IsExpansionSelected(opts.expansions, facts, settings) then
        return DECISION.KEEP, RULE.GEM_EXPANSION
    end

    local isPast = model.IsPastExpansion(facts, settings.currentExpansion)

    local kept = recipeColumnsKeep(facts, opts, isPast, RULE.GEM_REAGENT)
    if kept then return DECISION.KEEP, kept end

    return DECISION.SELL, RULE.NOT_WANTED
end

--- Choose whose reagents to hold on to. This account's own are already kept by
--- the cross-cutting rule, so the mask here is for other people's professions --
--- stock for an alt who has not levelled the profession yet, or for the auction
--- house.
---
--- An uncatalogued trade good overlaps nobody, on the same reading of the
--- catalogue recipeColumnsKeep documents.
CLASS_RULES[ItemClass.Tradegoods] = function(facts, settings)
    local opts = settings.rules.tradeGoods
    if not opts then return nil end

    local spared = opts.professions or 0
    if spared ~= 0 and band(facts.reagentProfessions or 0, spared) ~= 0 then
        return DECISION.KEEP, RULE.TRADE_GOOD_SPARED
    end

    return DECISION.SELL, RULE.NOT_WANTED
end

-- Not GEM_ARTIFACT_RELIC above, which is also 11. This one is Classic
-- equipment -- an idol, libram, totem or sigil, worn in the relic slot
-- Cataclysm removed -- while the gem is the Legion object socketed into an
-- artifact. The number is all the two share.
local ARMOR_RELIC_SUB = 11

-- Where a copy of this item can still go. Bound is bound: once isBound is
-- true there is nothing further to ask, because a Warbound piece that has
-- been equipped is soulbound like any other -- only the bind TYPE would say
-- otherwise, and it describes what the item was, not where this copy can go
-- now. While a copy is still unbound, the account binding is what separates
-- one a buyer could take (ANYONE) from one that can only ever move between
-- this account's own characters (ALTS); once bound, neither the account
-- binding nor the ordinary bind type says anything more, and it is NOBODY
-- but this character's own enchanter. model.CanReachAnAlt carries the same
-- rule for the rest of the module, collapsing ALTS and ANYONE into one
-- true -- both reach an alt, and only NOBODY does not.
local REACH = { ANYONE = "ANYONE", ALTS = "ALTS", NOBODY = "NOBODY" }

--- Weapons and armor, judged against what is equipped. One function and one
--- settings block: the comparison, the two margins and what to spare are shared, and
--- the window says so rather than offering a switch.
---
--- The ladder's shape is load-bearing. Step 1 and step 2 route to 3 rather than
--- terminating, so a piece this character cannot use still gets the alt and
--- disenchant questions -- off-class gear is the gear most likely to suit an
--- alt, and vendoring it before the alt is asked is the mistake. Step 1 has a
--- third, earlier exit of its own: an unread class identity abstains the
--- whole criterion immediately, rather than being folded into "cannot use it"
--- and routed to 3 like a known off-class piece.
---
--- Step 3 routes to 6 while 4 and 5 route to 7, because a bound item can only be
--- disenchanted by me, so step 6 asks whether I am an enchanter. An unbound item
--- can reach any enchanter -- traded, mailed or sold -- so that question does
--- not apply to it.
---
--- Step 8 fires only when every fact consulted above was readable. An
--- inconclusive slot comparison or an unknown disenchant verdict makes the
--- criterion abstain, and the item falls through to the global KEEP.
local function judgeGear(facts, settings)
    local gear = settings.rules.gear
    if not gear then return nil end

    local condemnedRule

    -- 1. A kind this class can use? Proficiency, not a stored preference:
    -- cloaks, shirts and tabards are all filed as Cloth, and judging by subclass
    -- alone is what made a hunter's cloak read as unequippable.
    --
    -- IsEquippableBy can itself abstain (nil) when the player's own class
    -- identity could not be read. Every question below this one is a question
    -- about THIS character, and none of them can be answered honestly without
    -- knowing who is asking, so an unread class identity abstains the whole
    -- criterion here rather than falling into the "not equippable" branch and
    -- condemning gear the class may well be able to use -- a KNOWN off-class
    -- piece still gets that branch, and still falls through to steps 3-7.
    local equippable = model.IsEquippableBy(facts, settings.playerClass)
    if equippable == nil then return nil end

    if not equippable then
        condemnedRule = RULE.NOT_EQUIPPABLE
    else
        -- 2. The margin ladder: quality gap converted to item levels,
        -- existential over dual slots, an empty slot meaning no opinion rather
        -- than a sale. Nothing gates it any more: the toggle withheld the
        -- comparison rather than configuring it, and the veto above it sold on
        -- quality alone, which is this ladder's own quality margin taken to
        -- its limit.
        --
        -- settings is handed straight through: compareToSlot reads its
        -- margins off settings.rules.gear itself, and currentExpansion is
        -- already at the top level settings carries.
        local verdict, keptBy = model.CompareToEquipped(facts, settings)
        if verdict == DECISION.KEEP then
            return DECISION.KEEP, keptBy or RULE.EQUIPPABLE
        end
        if verdict == DECISION.SELL then
            condemnedRule = RULE.OUTCLASSED
        else
            -- nil: the comparison could not read the slot. No evidence, so no
            -- condemnation.
            return nil
        end
    end

    -- 3. Where this copy can still go, answered once. isBound can answer
    -- secret, and folding that into false here is the condemn-without-
    -- evidence failure this design exists to prevent.
    if facts.isBound == nil then return nil end

    local reaches
    if facts.isBound then
        reaches = REACH.NOBODY
    else
        -- The one place isBindOnAccount is read, and the only question it
        -- answers -- see REACH above for why a bound copy never consults it.
        if facts.isBindOnAccount == nil then return nil end
        reaches = facts.isBindOnAccount and REACH.ALTS or REACH.ANYONE
    end

    -- 4 and 5. Which rescue applies is read directly off `reaches`, computed
    -- once above rather than re-derived per step.
    if reaches == REACH.ALTS then
        -- 4. BoA. reaches == ALTS already IS "unbound and Warbound", which is
        -- exactly what spareBindOnAccount is about.
        if model.IsExpansionSelected(gear.spareBindOnAccount, facts, settings) then
            return DECISION.KEEP, RULE.BIND_ON_ACCOUNT
        end
    elseif reaches == REACH.ANYONE then
        -- 5. BoE. An unread bindType is unknown, not "definitely not BoE" --
        -- the same reasoning as isBindOnAccount above, and this fact is read
        -- only here because only this branch consults it: a secret or
        -- otherwise-unread bindType used to be read as "not BoE," losing the
        -- sparing.
        if facts.bindType == nil then return nil end
        if facts.bindType == enum.BIND_TYPE.ON_EQUIP then
            if model.IsExpansionSelected(gear.spareBindOnEquip, facts, settings) then
                return DECISION.KEEP, RULE.BIND_ON_EQUIP
            end
        end
    end

    -- 6 and 7. Both gated on the item actually being disenchantable: without
    -- that gate an enchanter would vendor no gear at all.
    if model.IsDisenchantable(facts) then
        -- What the item YIELDS, not how old the item is -- which is why the
        -- setting is worded about materials. A timewalking piece wears a
        -- current item level and disenchants into its own expansion's
        -- materials, so it is PAST here while being a real bar in the
        -- comparison above.
        --
        -- The player's own enchanter skips the whether-question and not the age
        -- one: with nobody else to keep it for, an empty selection means "I have
        -- not opted in", which does not apply to the one person who can always
        -- reach a bound piece -- but stale materials are stale in their bags
        -- too. So an empty mask floors to the current expansion for this limb
        -- only, and any mask that names something is used exactly as it stands.
        local selfSpares = gear.keepForDisenchant or 0
        if selfSpares == 0 then selfSpares = enum.EXPANSION_CURRENT end

        -- 6. My own enchanter can disenchant anything already bound to me,
        -- so this one does not wait to be opted into -- only asked whether
        -- the materials are still current.
        if reaches == REACH.NOBODY and settings.isEnchanter then
            if model.IsExpansionSelected(selfSpares, facts, settings) then
                return DECISION.KEEP, RULE.DISENCHANTABLE
            end
        end
        -- 7. Keeping it for someone else's enchanter is only worth anything
        -- if someone else can have it -- an alt's enchanter and any enchanter
        -- both count, so ALTS and ANYONE both reach this. A piece that
        -- reaches nobody is dead weight for this rescue however
        -- disenchantable it is.
        if reaches ~= REACH.NOBODY
            and model.IsExpansionSelected(gear.keepForDisenchant, facts, settings) then
            return DECISION.KEEP, RULE.DISENCHANTABLE
        end
    end

    -- 8. Nothing kept it, and every fact consulted was readable.
    if condemnedRule then return DECISION.SELL, condemnedRule end
    return DECISION.KEEP, RULE.EQUIPPABLE
end

CLASS_RULES[ItemClass.Weapon] = judgeGear

--- Armor takes one rule of its own ahead of the shared ladder.
---
--- Transmog is not it. Since The War Within, vendoring an item collects its
--- appearance and the class restriction on collecting is gone, so an ordinary
--- equippable source costs the player nothing on its way to the vendor.
--- Cosmetic items are the exception, and #32 settled its shape: they grant an
--- appearance on use rather than being a source, vendoring one does NOT
--- collect it, and they are not an armor subclass -- both items in the report
--- are weapons that answer C_Item.IsCosmeticItem true. So the rule is
--- cross-cutting and lives in model.Decide; nothing about it is filed here.
CLASS_RULES[ItemClass.Armor] = function(facts, settings)
    local armor = settings.rules.armor
    if armor and facts.subclassID == ARMOR_RELIC_SUB and armor.sellRelics then
        return DECISION.SELL, RULE.ARMOR_RELIC
    end
    return judgeGear(facts, settings)
end

-- Named MISC_SUBCLASS in control.lua too. One set of numbers, one name, so the
-- two files cannot drift apart.
local MISC_SUBCLASS = {
    REAGENT = 1,
    PET = 2,
    HOLIDAY = 3,
    OTHER = 4,
    MOUNT = 5,
    MOUNT_EQUIPMENT = 6
}
local HOUSING_SUBCLASS = { DECOR = 0, DYE = 1 }

--- Recipes are judged on whether this character already knows them.
---
--- IsUsableItem is not sufficient on its own: a profession recipe requirement
--- carries a rank it ignores, so it reports usable for a recipe the character
--- cannot train. recipeKnown reads the ITEM_SPELL_KNOWN tooltip line instead,
--- which answers directly.
---
--- recipeProfession gates it because a recipe filed under Book (0) belongs to
--- no profession, so there is nothing to judge it against -- not because the
--- profession has to have been visited.
CLASS_RULES[ItemClass.Recipe] = function(facts, settings)
    local opts = settings.rules.recipes
    if not opts then return nil end
    if facts.recipeProfession == nil then return nil end
    if facts.recipeKnown == nil then return nil end

    if opts.keepLearnable and not facts.recipeKnown then
        return DECISION.KEEP, RULE.RECIPE_LEARNABLE
    end
    if opts.keepTradeable then
        if facts.isBound == nil then return nil end
        if not facts.isBound then
            return DECISION.KEEP, RULE.STILL_TRADEABLE
        end
    end
    -- Two ways to reach a sale, and they are not the same sentence. A recipe
    -- this character already knows is finished with; one it could still learn
    -- is sold because the player turned that protection off.
    if facts.recipeKnown then return DECISION.SELL, RULE.ALREADY_LEARNED end
    return DECISION.SELL, RULE.NOT_WANTED
end

--- Pets, mounts, toys, holiday items and oddments.
---
--- Junk (0) has no rule here. Poor is a quality, not a class -- the
--- cross-cutting rule already covers every class, and a copy filed under 15/0
--- would catch only what Blizzard happened to classify there.
CLASS_RULES[ItemClass.Miscellaneous] = function(facts, settings)
    local opts = settings.rules.misc
    if not opts then return nil end
    local sub = facts.subclassID

    -- Keyed on the fact rather than the subclass: subclass 4 holds ordinary
    -- oddments beside the toys, and a toy shipping in some other Miscellaneous
    -- subclass would be missed by a subclass test.
    --
    -- Unbound wins over collection, as it does for mounts: a tradeable copy can
    -- still reach someone who wants it, so collection only decides the bound
    -- ones.
    if opts.sellCollectedToys and facts.toyCollected ~= nil then
        if facts.isBound == nil then return nil end
        if not facts.isBound then return DECISION.KEEP, RULE.STILL_TRADEABLE end
        if facts.toyCollected then return DECISION.SELL, RULE.ALREADY_COLLECTED end
        return DECISION.KEEP, RULE.NOT_COLLECTED
    end

    if sub == MISC_SUBCLASS.MOUNT then
        if not opts.sellCollectedMounts then return nil end
        if facts.isBound == nil then return nil end
        -- A tradeable mount can still reach a character who wants it, so
        -- collection only decides the bound ones.
        if not facts.isBound then return DECISION.KEEP, RULE.STILL_TRADEABLE end
        if facts.mountCollected == nil then return nil end
        if facts.mountCollected then return DECISION.SELL, RULE.ALREADY_COLLECTED end
        return DECISION.KEEP, RULE.NOT_COLLECTED
    end

    if sub == MISC_SUBCLASS.PET then
        if not opts.sellPets then return nil end
        if facts.petCollected == nil then return nil end
        if facts.petCollected then return DECISION.SELL, RULE.ALREADY_COLLECTED end
        return nil
    end

    if sub == MISC_SUBCLASS.HOLIDAY and opts.sellHoliday then
        return DECISION.SELL, RULE.HOLIDAY_ITEM
    end
    if sub == MISC_SUBCLASS.MOUNT_EQUIPMENT and opts.sellMountEquipment then
        return DECISION.SELL, RULE.MOUNT_EQUIPMENT
    end

    -- Spell reagents (1), oddments (4), and anything whose toggle is off.
    return nil
end

--- Decor is collected; a dye is consumed. They are different kinds of thing,
--- which is why the two branches below ask different questions -- grouping
--- them under one "already have it" is the mistake this asymmetry corrects.
---
--- Nothing is ever collected or learned for a dye: it is a one-time
--- consumable, spent when it is applied. Enum.HousingCatalogEntryType has no
--- Dye member because there is no catalogue entry to have, and IsDyeColorOwned
--- counts the copies in your bags -- the right model for a consumable, and
--- circular for the very copy being judged. What can be asked is whether that
--- copy still has somewhere to go: a dye is never bound, and some professions
--- craft it for trade.
---
--- Room (2), RoomCustomization (3), ExteriorCustomization (4) and ServiceItem
--- (5) have no rule yet, so they abstain.
CLASS_RULES[ItemClass.Housing] = function(facts, settings)
    local opts = settings.rules.housing
    if not opts then return nil end

    if facts.subclassID == HOUSING_SUBCLASS.DECOR and opts.sellCollectedDecor then
        if facts.decorCollected == nil then return nil end
        if facts.decorCollected then return DECISION.SELL, RULE.ALREADY_COLLECTED end
        return nil
    end
    if facts.subclassID == HOUSING_SUBCLASS.DYE then
        if not opts.keepTradeableDyes then return DECISION.SELL, RULE.NOT_WANTED end
        local reachable = model.CanReachAnAlt(facts)
        if reachable == nil then return nil end
        if reachable then return DECISION.KEEP, RULE.STILL_TRADEABLE end
        return DECISION.SELL, RULE.NOT_WANTED
    end
    return nil
end

-- Sell has no ladder of its own -- every sell claim carries the same weight,
-- unlike OPEN's five-tier enum.PRIORITY. A private constant rather than a
-- borrowed PRIORITY tier: those numbers are the open path's own and are
-- printed into player-visible curation-review text, so reusing one would tie
-- sell's strength to a renumbering that has nothing to do with it.
local SELL_STRENGTH = 1

-- The only two of model.Decide's terminals that come from an explicit list
-- entry (db.char.itemOverrides / db.global.itemOverrides, read through
-- model.facts.EffectiveSell as facts.isEnforced / facts.isProhibited) rather
-- than a setting, a hard gate, or a session gesture. TEMP_INCLUDED and
-- TEMP_EXCLUDED are deliberately absent: both are read off model.lua's
-- tempIncludes/tempExcludes, plain session tables that touch no `db` field at
-- all and are cleared by ClearTempIncludes/ClearTempExcludes rather than
-- revoked by the player -- exactly the reasoning that already keeps
-- openRules' session skip off this same flag (model/openRules.lua's own
-- comment, and Task 2's report). Every other terminal is a setting, a hard
-- client gate, or the class dispatch, none of which is a player override of
-- this one item.
local OVERRIDE_RULE = {
    [RULE.WHITELISTED] = true,
    [RULE.BLACKLISTED] = true,
}

-- A lookup, not an enumeration to keep in step with enum.RULE: any RULE this
-- table does not name reads OVERRIDE_RULE[rule] as nil, which is the correct
-- non-override answer BY CONSTRUCTION -- not because someone checked that
-- terminal and cleared it. A new enum.RULE member therefore needs no audit
-- of this table: it is already right, silently, the moment it is added. The
-- only edit this table ever actually needs is a change to what the sell
-- lists themselves can produce -- today that is exactly WHITELISTED and
-- BLACKLISTED; a third list, or retiring one of these two, is the one
-- reason to touch it.

---@class BitForge.Dispatch.Model.Rules
local rules = {
    CLASS_RULES = CLASS_RULES,

    --- The name this file registers its claimant under, stated once, the same
    --- way model/openRules.lua states its own. Read back by
    --- control/sellScanner.lua's explain(), which asks this one claimant for
    --- the enum.RULE the tooltip's reason line needs -- a rule the verdict
    --- itself no longer carries once another claimant can win.
    CLAIMANT = "sell",
}

-- The settings snapshot this claimant judged with, and the generation it was
-- built for. Rebuilt on the first claim of each generation and shared by every
-- claim after it.
--
-- model.GetSettingsSnapshot used to be called once per scan, by
-- sellScanner.Scan, which hoisted it out of the loop. Routing the manifest
-- through the arbiter took that hoist away: the claimant is handed one item
-- and nothing else, so an unmemoised read here is one snapshot table, one
-- GetCurrentCharacter, one GetCharacterProfessionMask and one
-- GetExpansionLevel PER BAG SLOT -- 120 of each on a full bag, on every bag
-- movement at a vendor.
--
-- A generation is the right lifetime rather than a convenient one: every input
-- the snapshot copies by value is either read from db.global.rules through a
-- live reference (so a rule edit is visible without rebuilding anything) or
-- changed by a setter that turns the generation over -- SetRuleValue,
-- SetConsumableRuleValue, and the SKILL_LINES_CHANGED pair that rewrite
-- isEnchanter and the profession masks. The one exception is
-- GetExpansionLevel, which can change mid-session at a launch and invalidates
-- nothing; it is picked up on the next bag event instead of the next item,
-- which is the same day and a great many generations sooner than the player
-- could notice.
local snapshot, snapshotGeneration

--- The snapshot for this generation, built once.
---@return table
local function generationSettings()
    local generation = model.facts.Generation()
    if snapshot == nil or snapshotGeneration ~= generation then
        snapshot = model.GetSettingsSnapshot()
        snapshotGeneration = generation
    end
    return snapshot
end

--- The sell claimant. A wrapper, not a second cascade: model.Decide already
--- walks the whole tree and already consults the sell lists to short-circuit
--- at WHITELISTED/BLACKLISTED, so this only has to say whether the terminal
--- it got back WAS that list -- see OVERRIDE_RULE above.
---
--- enum.DECISION.KEEP is not translated into a claim. It is the same answer
--- as never having claimed at all (model/arbiter.lua's pickWinner treats a
--- nil claim as an abstention either way), and mapping it onto CLAIM.SELL/
--- CLAIM.KEEP would make every item in the bags a claimant and remove the
--- arbiter's abstention default. A KEEP still carries `overridden` when the
--- rule that produced it was BLACKLISTED: the claimant abstains, but the
--- flag is what lets a dump tell "the player said never" from "the rules had
--- no opinion" -- the suppressing half of the contract, exactly as
--- openRules.Claim's own blacklist rung expresses it for the open path.
---@param facts table  a model.facts record, or an equivalent plain table
---@return string|nil claim       enum.CLAIM.SELL, or nil to abstain
---@return number|nil strength    SELL_STRENGTH when claiming, else nil
---@return string|nil reason      enum.RULE.* -- which step of Decide answered
---@return boolean|nil overridden true when `reason` is the player's own list entry
function rules.Claim(facts)
    local verdict, rule = model.Decide(facts, generationSettings())

    if verdict == DECISION.SELL then
        return CLAIM.SELL, SELL_STRENGTH, rule, OVERRIDE_RULE[rule]
    end

    return nil, nil, rule, OVERRIDE_RULE[rule]
end

model.rules = rules

-- The second of the three claimants (spec #331 section 3), registered after the
-- publication above and never before, for the reason model/openRules.lua's own
-- registration gives.
model.arbiter.Register(rules.CLAIMANT, rules.Claim)

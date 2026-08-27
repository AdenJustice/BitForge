---@class BitForge.BatchSell
local ns = select(2, ...)

---@class BitForge.BatchSell.Model
local model = ns.model
---@type BitForge.BatchSell.Enum
local enum = ns.enum
local ItemClass = Enum.ItemClass

local DECISION, RULE = enum.DECISION, enum.RULE

local band = bit.band

local GEM_ARTIFACT_RELIC = 11

--- One criterion per item class. A class absent from this table is not judged
--- at all -- which is how quest items, projectiles, spell reagents and whatever
--- class Blizzard adds next reach the global KEEP without a branch of their own.
---@type table<number, fun(facts: table, settings: table): string|nil, string|nil>
local CLASS_RULES = {}

--- The two recipe columns, which Consumables and Gems ask identically.
---
--- Three answers, not two, and that is the whole point. nil means the catalogue
--- has never seen the item; reading that as "nobody wants it" is the failure
--- this design exists to prevent. So the caller gets three outcomes: a rule key
--- to keep on, false to carry on to its terminal, or nil to abstain.
---
--- Which column applies is resolved first, from isPast alone -- recipesOld for
--- a past item, recipesNow for a current one -- and only that column is ever
--- asked. The mask is read only once that column is ticked: reading it earlier
--- would abstain on a nil mask even when the ticked column belongs to the
--- item's other era, where the catalogue was never the deciding question and a
--- gap in it cannot matter.
---@param facts table
---@param opts table  the criterion's stored options
---@param isPast boolean
---@param keepRule string  enum.RULE.* to return when the column keeps it
---@return string|false|nil
local function recipeColumnsKeep(facts, opts, isPast, keepRule)
    local ticked
    if isPast then
        ticked = opts.recipesOld
    else
        ticked = opts.recipesNow
    end
    if not ticked then return false end

    local mask = facts.reagentProfessions
    if mask == nil then return nil end
    if mask == 0 then return false end

    return keepRule
end

--- Whether the cross-cutting Crafting Reagents rule (model.lua step 9) asked
--- its own question and got no answer: the player wants reagents kept, and
--- the catalogue has never seen this item. When that is true, a terminal
--- below that would otherwise condemn the item for "not being a wanted
--- reagent" cannot honestly do so -- it does not know either, and reading the
--- silence as "nobody wants it" is exactly the failure this design exists to
--- prevent. Consumables, Gems and Trade Goods are the three classes where
--- being a reagent is plausible, so each guards its own UNWANTED terminal
--- with this. A KNOWN mask, even one that overlaps nothing, is a real answer
--- and does not trigger it -- only silence does.
---@param facts table
---@param settings table
---@return boolean
local function reagentQuestionUnanswered(facts, settings)
    local reagentRules = settings.rules.reagents
    return (reagentRules and reagentRules.keep and facts.reagentProfessions == nil) and true or false
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

--- A new expansion caps the gear an enhancement can be applied to, so last
--- expansion's stop being worth anything -- to a character who has finished
--- with last expansion's gear. One who is still levelling through that
--- content is wearing exactly what those enhancements fit, which is what the
--- option is for; only the expansion immediately behind is offered, since
--- nothing is levelling through the one before it.
CLASS_RULES[ItemClass.ItemEnhancement] = function(facts, settings)
    local opts = settings.rules.enhancements
    if not opts then return nil end

    if not model.IsPastExpansion(facts, settings.currentExpansion) then
        return DECISION.KEEP, RULE.ENHANCEMENT_CURRENT
    end
    if opts.keepLastExpansion and facts.expacID == settings.currentExpansion - 1 then
        return DECISION.KEEP, RULE.ENHANCEMENT_LAST_EXPANSION
    end
    return DECISION.SELL, RULE.ENHANCEMENT_OUTDATED
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

    local isPast = model.IsPastExpansion(facts, settings.currentExpansion)

    -- lastExpansion extends `current` rather than standing beside it: the
    -- window only lets it be ticked while `current` is, and the rule holds the
    -- same dependency rather than trusting the view to.
    if opts.current then
        if not isPast then
            return DECISION.KEEP, RULE.CONSUMABLE_CURRENT
        end
        if opts.lastExpansion and facts.expacID == settings.currentExpansion - 1 then
            return DECISION.KEEP, RULE.CONSUMABLE_LAST_EXPANSION
        end
    end

    local kept = recipeColumnsKeep(facts, opts, isPast, RULE.CONSUMABLE_REAGENT)
    if kept == nil then return nil end
    if kept then return DECISION.KEEP, kept end

    if reagentQuestionUnanswered(facts, settings) then return nil end
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

    local isPast = model.IsPastExpansion(facts, settings.currentExpansion)
    if opts.current and not isPast then
        return DECISION.KEEP, RULE.GEM_CURRENT
    end

    local kept = recipeColumnsKeep(facts, opts, isPast, RULE.GEM_REAGENT)
    if kept == nil then return nil end
    if kept then return DECISION.KEEP, kept end

    if reagentQuestionUnanswered(facts, settings) then return nil end
    return DECISION.SELL, RULE.NOT_WANTED
end

--- Choose whose reagents to hold on to. This account's own are already kept by
--- the cross-cutting rule, so the mask here is for other people's professions --
--- stock for an alt who has not levelled the profession yet, or for the auction
--- house.
---
--- An empty mask skips the spared-profession question entirely, since there is
--- nobody to spare -- but that is not the same as the catalogue having spoken.
--- reagentQuestionUnanswered still guards the terminal below: an empty mask
--- plus an uncatalogued item is silence, not "nobody wants it".
CLASS_RULES[ItemClass.Tradegoods] = function(facts, settings)
    local opts = settings.rules.tradeGoods
    if not opts then return nil end

    local spared = opts.professions or 0
    if spared ~= 0 then
        if facts.reagentProfessions == nil then return nil end
        if band(facts.reagentProfessions, spared) ~= 0 then
            return DECISION.KEEP, RULE.TRADE_GOOD_SPARED
        end
    end

    if reagentQuestionUnanswered(facts, settings) then return nil end
    return DECISION.SELL, RULE.NOT_WANTED
end

local SPARE = { CURRENT = "CURRENT", ALL = "ALL", NONE = "NONE" }

-- Not GEM_ARTIFACT_RELIC above, which is also 11. This one is Classic
-- equipment -- an idol, libram, totem or sigil, worn in the relic slot
-- Cataclysm removed -- while the gem is the Legion object socketed into an
-- artifact. The number is all the two share.
local ARMOR_RELIC_SUB = 11

--- Whether a spare setting covers this item.
---@return boolean
local function sparesIt(mode, facts, settings)
    if mode == SPARE.ALL then return true end
    if mode == SPARE.CURRENT then
        return not model.IsPastExpansion(facts, settings.currentExpansion)
    end
    return false
end

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
        -- isBindOnAccount is read only here, and only while still unbound:
        -- this is the one question it answers about where the copy can go.
        -- Bound is bound -- once isBound is true the account-bind type is
        -- never consulted again, because a Warbound piece that has been
        -- equipped is soulbound like any other, and asking which kind of
        -- account binding it once had would keep it for an alt who can
        -- never actually receive it.
        if facts.isBindOnAccount == nil then return nil end
        reaches = facts.isBindOnAccount and REACH.ALTS or REACH.ANYONE
    end

    -- 4 and 5. Which rescue applies is read directly off `reaches`, computed
    -- once above rather than re-derived per step.
    if reaches == REACH.ALTS then
        -- 4. BoA. reaches == ALTS already IS "unbound and Warbound", which is
        -- exactly what spareBindOnAccount is about.
        if sparesIt(gear.spareBindOnAccount, facts, settings) then
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
            if sparesIt(gear.spareBindOnEquip, facts, settings) then
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
        -- The player's own enchanter skips the whether-question and not the
        -- age one: at NONE there is nobody else to keep it for, which is
        -- what the setting says, but stale materials are stale in their bags
        -- too -- so NONE floors to CURRENT for this limb only, and ALL still
        -- reaches past materials the way it does for everyone else.
        local selfSpares = gear.keepForDisenchant
        if selfSpares == SPARE.NONE then selfSpares = SPARE.CURRENT end

        -- 6. My own enchanter can disenchant anything already bound to me,
        -- so this one does not wait to be opted into -- only asked whether
        -- the materials are still current.
        if reaches == REACH.NOBODY and settings.isEnchanter then
            if sparesIt(selfSpares, facts, settings) then
                return DECISION.KEEP, RULE.DISENCHANTABLE
            end
        end
        -- 7. Keeping it for someone else's enchanter is only worth anything
        -- if someone else can have it -- an alt's enchanter and any enchanter
        -- both count, so ALTS and ANYONE both reach this. A piece that
        -- reaches nobody is dead weight for this rescue however
        -- disenchantable it is.
        if reaches ~= REACH.NOBODY and sparesIt(gear.keepForDisenchant, facts, settings) then
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
        -- An unread bind state is unknown, not unbound -- C_Item.IsBound can
        -- answer secret, and folding nil into false here is the
        -- condemn-without-evidence failure this design exists to prevent.
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
        -- An unread bind state is unknown, not unbound -- C_Item.IsBound can
        -- answer secret, and folding nil into false here is the
        -- condemn-without-evidence failure this design exists to prevent.
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
        -- An unread bind state is unknown, not unbound -- C_Item.IsBound can
        -- answer secret, and folding nil into false here is the
        -- condemn-without-evidence failure this design exists to prevent.
        local reachable = model.CanReachAnAlt(facts)
        if reachable == nil then return nil end
        if reachable then return DECISION.KEEP, RULE.STILL_TRADEABLE end
        return DECISION.SELL, RULE.NOT_WANTED
    end
    return nil
end

local rules = {
    CLASS_RULES = CLASS_RULES,
}

model.rules = rules

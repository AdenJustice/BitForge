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

--- Weapons and armor, judged against what is equipped. One function and one
--- settings block: the comparison, the margin and what to spare are shared, and
--- the window says so rather than offering a switch.
---
--- The ladder's shape is load-bearing. Step 1 and step 2 route to 4 rather than
--- terminating, so a piece this character cannot use still gets the alt and
--- disenchant questions -- off-class gear is the gear most likely to suit an
--- alt, and vendoring it before the alt is asked is the mistake. Step 1 has a
--- third, earlier exit of its own: an unread class identity abstains the
--- whole criterion immediately, rather than being folded into "cannot use it"
--- and routed to 4 like a known off-class piece.
---
--- Step 4 routes to 7 while 5 and 6 route to 8, because a bound item can only be
--- disenchanted by me, so step 7 asks whether I am an enchanter. An unbound item
--- can reach any enchanter -- traded, mailed or sold -- so that question does
--- not apply to it.
---
--- Step 9 fires only when every fact consulted above was readable. An
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
    -- piece still gets that branch, and still falls through to steps 4-8.
    local equippable = model.IsEquippableBy(facts, settings.playerClass)
    if equippable == nil then return nil end

    if not equippable then
        condemnedRule = RULE.NOT_EQUIPPABLE
    else
        -- 2. The optional veto, above the ladder rather than replacing it.
        -- IsLowerQualityThanEquipped can itself abstain (nil) when a slot it
        -- would need unanimity over is unreadable; that is no less an
        -- inconclusive comparison than step 3's, so it ends the criterion the
        -- same way step 3's own nil does, rather than falling through to a
        -- question the veto never actually answered.
        local vetoed = false
        if gear.compareQuality and facts.equippedItems then
            vetoed = model.IsLowerQualityThanEquipped(facts, settings)
            if vetoed == nil then return nil end
        end

        if vetoed then
            condemnedRule = RULE.OUTCLASSED
        elseif gear.compareItemLevel then
            -- 3. The margin ladder: quality gap converted to item levels,
            -- existential over dual slots, an empty slot meaning no opinion
            -- rather than a sale.
            --
            -- settings is handed straight through: compareToSlot reads its
            -- margin off settings.rules.gear itself, and currentExpansion is
            -- already at the top level settings carries.
            local verdict, keptBy = model.CompareToEquipped(facts, settings)
            if verdict == DECISION.KEEP then
                return DECISION.KEEP, keptBy or RULE.EQUIPPABLE
            end
            if verdict == DECISION.SELL then
                condemnedRule = RULE.OUTCLASSED
            else
                -- nil: the comparison could not read the slot. No evidence, so
                -- no condemnation.
                return nil
            end
        end
    end

    -- 4. Is this instance already bound to me? An unread bind state is
    -- unknown, not unbound -- C_Item.IsBound can answer secret, and folding
    -- nil into false here is the condemn-without-evidence failure this
    -- design exists to prevent.
    if facts.isBound == nil then return nil end
    if not facts.isBound then
        -- 5. BoA and BoW reach an alt directly. Same rule for
        -- isBindOnAccount: the IsItemBindToAccount family can also answer
        -- secret, so an unread value abstains rather than reading as "not
        -- account bound".
        if facts.isBindOnAccount == nil then return nil end
        if facts.isBindOnAccount then
            if sparesIt(gear.spareBindOnAccount, facts, settings) then
                return DECISION.KEEP, RULE.BIND_ON_ACCOUNT
            end
        -- 6. BoE reaches an alt or a buyer. An unread bindType is unknown,
        -- not "definitely not BoE" -- same reasoning as isBound and
        -- isBindOnAccount just above, and steps 4 and 5 guard their own facts
        -- the same way; this one did not, and silently read a secret or
        -- otherwise-unread bindType as "not BoE," losing the sparing.
        elseif facts.bindType == nil then
            return nil
        elseif facts.bindType == enum.BIND_TYPE.ON_EQUIP then
            if sparesIt(gear.spareBindOnEquip, facts, settings) then
                return DECISION.KEEP, RULE.BIND_ON_EQUIP
            end
        end
    end

    -- 7 and 8. Both gated on the item actually being disenchantable: without
    -- that gate an enchanter would vendor no gear at all.
    if model.IsDisenchantable(facts) then
        -- 7. My own enchanter can disenchant a soulbound piece, and nobody
        -- else ever will, so this one does not wait to be opted into.
        if facts.isBound and settings.isEnchanter then
            return DECISION.KEEP, RULE.DISENCHANTABLE
        end
        -- 8. Keeping it for someone else's enchanter is only worth anything
        -- if someone else can have it. A piece already soulbound to a
        -- non-enchanter is dead weight, however disenchantable it is.
        if gear.keepForDisenchant then
            local reachable = model.CanReachAnEnchanter(facts, settings.isEnchanter)
            if reachable == nil then return nil end
            if reachable then return DECISION.KEEP, RULE.DISENCHANTABLE end
        end
    end

    -- 9. Nothing kept it, and every fact consulted was readable.
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

--- Pets, mounts, holiday items and oddments.
---
--- Junk (0) has no rule here. Poor is a quality, not a class -- the
--- cross-cutting rule already covers every class, and a copy filed under 15/0
--- would catch only what Blizzard happened to classify there.
CLASS_RULES[ItemClass.Miscellaneous] = function(facts, settings)
    local opts = settings.rules.misc
    if not opts then return nil end
    local sub = facts.subclassID

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

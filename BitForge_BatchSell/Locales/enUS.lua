---@class BitForge.BatchSell
local ns = select(2, ...)
---@class BitForge.BatchSell.Locale
local L = ns.locale

L["panel:batchSell"] = "Batch Sell"
L["panel:sellManifest"] = "Sell Manifest"
L["panel:blacklist"] = "Blacklist"
L["panel:whitelist"] = "Whitelist"

L["ui:ruleWindowTitle"] = "Batch Sell Rules"
L["ui:ruleWindowNothingToConfigure"] = "Nothing to configure here."
L["ui:ruleWindowDisclaimer"] =
"In combat and inside instances the game sometimes withholds an item's details. BatchSell keeps those items rather than guessing, so a few may be missing from the list -- that is expected. A verdict that looks wrong for any other reason is worth reporting."
L["ui:selectedCount"] = "Selected: %d"

L["btn:sellAll"] = "Sell All"
L["btn:refresh"] = "Refresh"
L["btn:rules"] = "Rules"

L["menu:temporaryExclude"] = "Temporarily Exclude"
L["menu:blacklisted"] = "Blacklisted"
L["menu:whitelisted"] = "Whitelisted"
L["menu:noStatus"] = "None"
L["menu:reportVerdict"] = "Report This Verdict"

L["status:noItemsToSell"] = "No items to sell"
L["status:itemsTotal"] = "%d items  |  Total: %s"

L["ui:manifestHint"] = "Expected something that isn't listed? Hover it in your bags to see why."

-- Merchant row
L["tooltip:charOverride"] = "This character's setting overrides the warband list — this item will be sold."

L["section:general"] = "General"
L["section:lists"] = "Lists"
L["section:everyItem"] = "Every Item"
L["section:byItemType"] = "By Item Type"

L["settings:openRuleWindow"] = "View Rules"
L["settings:openRuleWindowTooltip"] =
"Explains what each rule looks for, and why an item was kept or sold"
L["settings:sellJunk"] = "Sell Junk"
L["settings:sellJunkTooltip"] = "Sell all poor quality (grey) items automatically when visiting a vendor"
L["settings:limitBatch"] = "Limit Batch to 12"
L["settings:limitBatchTooltip"] = "Sell at most 12 items per click to avoid server throttling"
L["settings:keepUsedReagents"] = "Keep Reagents Your Professions Use"
L["settings:keepUsedReagentsTooltip"] =
"Keep crafting reagents a profession on this account can use. A soulbound copy can never reach an alt, so only this character's professions keep one"
L["settings:compareQuality"] = "Compare Quality"
L["settings:compareQualityTooltip"] =
"Sell gear whose quality is lower than what you have equipped, regardless of item level"
L["settings:compareItemLevel"] = "Compare Item Level"
L["settings:compareItemLevelTooltip"] =
"Weigh gear against what you have equipped by item level, using the margin below. With this off, item level plays no part in the decision"
L["settings:ilvlMargin"] = "Item Level Margin"
L["settings:ilvlMarginTooltip"] =
"What one quality tier is worth in item levels. At 10, gear a tier below what you have equipped has to beat it by 10 to be kept, and a tier above survives 10 under it. At your own quality a piece has to beat the slot outright. At 0 quality stops counting and item level alone decides"
L["settings:emphasizeQuality"] = "Emphasize Quality"
L["settings:emphasizeQualityTooltip"] =
"Count a quality tier for twice the margin, and allow a piece of your own quality that margin below the slot. Quality above what you have equipped becomes cheaper to keep, and quality below it dearer to excuse"
L["settings:keepForDisenchant"] = "Keep Disenchantable Gear"
L["settings:keepForDisenchantTooltip"] =
"Keep gear that could be disenchanted, for the auction house or an alt with the profession. Enchanters always keep their own bound disenchantable gear regardless of this setting"
L["settings:spareBindOnAccount"] = "Spare Bind on Account Gear"
L["settings:spareBindOnAccountTooltip"] =
"Which unbound Bind on Account gear to keep so a copy can reach another character: this expansion's, all of it, or none"
L["settings:spareBindOnEquip"] = "Spare Bind on Equip Gear"
L["settings:spareBindOnEquipTooltip"] =
"Which unbound Bind on Equip gear to keep for another character or the auction house: this expansion's, all of it, or none"
L["settings:reagentsCurrentOnly"] = "Only This Expansion's Reagents"
L["settings:reagentsCurrentOnlyTooltip"] =
"Narrow the rule above to reagents from the current expansion. A recipe that wants a Classic herb wants it exactly as much today, so this stays off unless you would rather not stockpile old ones"
L["settings:keepUncollectedCosmetic"] = "Keep Uncollected Appearances"
L["settings:keepUncollectedCosmeticTooltip"] =
"Keep any item whose appearance you have not collected. Vendoring an ordinary piece still collects it, but a cosmetic item grants its look on use -- sell that and the appearance is gone for good"
L["settings:sellRelics"] = "Sell Classic Relics"
L["settings:sellRelicsTooltip"] =
"Sell idols, librams, totems and sigils -- the relic slot Cataclysm removed. Not Legion's artifact relics, which are gems and share only the subclass number"
L["settings:gemsCurrent"] = "Keep This Expansion's Gems"
L["settings:gemsCurrentTooltip"] =
"Keep gems from the current expansion. Older ones fall through to the two questions below"
L["settings:gemsRecipesNow"] = "Keep Current Gems A Recipe Wants"
L["settings:gemsRecipesNowTooltip"] =
"Keep a current-expansion gem some profession's recipe uses as a reagent, whoever owns that profession. The question goes to the recipe catalogue, and a gem it has never seen is kept rather than guessed at"
L["settings:gemsRecipesOld"] = "Keep Older Gems A Recipe Wants"
L["settings:gemsRecipesOldTooltip"] =
"The same question for gems from past expansions. What your own professions use is already kept elsewhere, so this column is for everybody else's recipes"
L["settings:keepArtifactRelics"] = "Keep Artifact Relics"
L["settings:keepArtifactRelicsTooltip"] =
"Keep the relics socketed into Legion artifact weapons. Nothing has used them since Legion, so this is worth turning off unless you collect them"
L["settings:enhancementsKeepLast"] = "Keep Last Expansion's Enhancements"
L["settings:enhancementsKeepLastTooltip"] =
"Keep item enhancements from the expansion immediately behind, for a character still wearing the gear they fit. Only that one is offered -- nothing is levelling through the one before it"
L["settings:keepLearnable"] = "Keep Recipes You Can Learn"
L["settings:keepLearnableTooltip"] =
"Keep a recipe this character has not learned"
L["settings:keepTradeableRecipes"] = "Keep Tradeable Recipes"
L["settings:keepTradeableRecipesTooltip"] =
"Keep a recipe that is still unbound, so it can reach an alt or the auction house even when this character has already learned it"
L["settings:sellCollectedMounts"] = "Sell Collected Mounts"
L["settings:sellCollectedMountsTooltip"] =
"Sell a mount you already own, once the copy is soulbound. An unbound one is kept whatever this says, because it can still reach someone who wants it"
L["settings:sellCollectedPets"] = "Sell Collected Pets"
L["settings:sellCollectedPetsTooltip"] =
"Sell a battle pet you already have. One you have never collected is never sold by this rule, whichever way it is set"
L["settings:sellHoliday"] = "Sell Holiday Items"
L["settings:sellHolidayTooltip"] =
"Sell the tokens, costumes and oddments world events leave in your bags"
L["settings:sellMountEquipment"] = "Sell Mount Equipment"
L["settings:sellMountEquipmentTooltip"] =
"Sell mount equipment. Only one piece applies account-wide at a time, so the spares in your bags are doing nothing"
L["settings:sellCollectedDecor"] = "Sell Collected Decor"
L["settings:sellCollectedDecorTooltip"] =
"Sell housing decor your catalogue already holds. A piece it has never seen is kept, and so is one the catalogue could not be read for"
L["settings:keepTradeableDyes"] = "Keep Tradeable Dyes"
L["settings:keepTradeableDyesTooltip"] =
"A dye is spent when it is applied and never learned, so there is no collection to ask about. What is asked instead is whether this copy can still reach someone: unbound is kept, bound is sold"
L["settings:spareProfessions"] = "Spare For These Professions"
L["settings:spareProfessionsTooltip"] =
"Keep a trade good if any profession ticked here could use it as a reagent -- for an alt who has not learned it yet, or for the auction house. This account's own professions are already covered by Keep Reagents Your Professions Use"

L["spare:current"] = "Current Expansion"
L["spare:all"] = "All"
L["spare:none"] = "None"

-- The game's own profession names, so the picker reads as part of the
-- profession UI rather than a dictionary rendering of it.
L["profession:FirstAid"] = "First Aid"
L["profession:Blacksmithing"] = "Blacksmithing"
L["profession:Leatherworking"] = "Leatherworking"
L["profession:Alchemy"] = "Alchemy"
L["profession:Herbalism"] = "Herbalism"
L["profession:Cooking"] = "Cooking"
L["profession:Mining"] = "Mining"
L["profession:Tailoring"] = "Tailoring"
L["profession:Engineering"] = "Engineering"
L["profession:Enchanting"] = "Enchanting"
L["profession:Fishing"] = "Fishing"
L["profession:Skinning"] = "Skinning"
L["profession:Jewelcrafting"] = "Jewelcrafting"
L["profession:Inscription"] = "Inscription"
L["profession:Archaeology"] = "Archaeology"

-- Consumable rows, one per Enum.ItemConsumableSubclass that stores a rule.
-- The game's own item type names, so a row reads as the type the player sees
-- next to their bags. 4 (Scroll) and 6 (Item Enhancement) store nothing, so
-- neither is named here.
L["sub:0"] = "Generic"
L["sub:1"] = "Potion"
L["sub:2"] = "Elixir"
L["sub:3"] = "Flasks & Phials"
L["sub:5"] = "Food & Drink"
L["sub:7"] = "Bandage"
L["sub:8"] = "Other"
L["sub:9"] = "Vantus Rune"

-- The options inside one consumable row's menu. A menu entry carries no
-- tooltip, so each has to say what it keeps rather than name a column.
L["option:current"] = "Keep everything from this expansion"
L["option:lastExpansion"] = "And from last expansion, while levelling through it"
L["option:recipesNow"] = "Keep this expansion's unless no recipe wants it"
L["option:recipesOld"] = "Keep older ones unless no recipe wants it"

-- List tabs
L["btn:removeEntry"] = "Remove"
L["list:warband"] = "Warband"
L["list:character"] = "Character"
L["status:listEmpty"] = "This list is empty"
L["status:listCount"] = "%d entries"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Batch Sell: will be sold"
L["verdict:keep"] = "Batch Sell: will be kept"
L["reason:TEMP_EXCLUDED"] = "Excluded for this merchant visit"
L["reason:BLACKLISTED"] = "On your blacklist"
L["reason:LOCKED"] = "The item is locked"
L["reason:EQUIPMENT_SET"] = "Part of an equipment set"
L["reason:NO_SELL_PRICE"] = "No vendor will buy it"
L["reason:REFUNDABLE"] = "Still within its refund window"
L["reason:WHITELISTED"] = "On your whitelist"
L["reason:TEMP_INCLUDED"] = "Added for this merchant visit"
L["reason:JUNK"] = "Sell Junk is off, so junk is left alone"
L["reason:JUNK_SOLD"] = "Sell Junk is on, so junk is sold"
L["reason:ABOVE_EPIC"] = "Better than epic, so it is never sold"
L["reason:BIND_ON_ACCOUNT"] = "Bind on Account gear is kept"
L["reason:DISENCHANTABLE"] = "Worth keeping to disenchant or sell on"
L["reason:BAG_KEPT"] = "Bags are never sold"
L["reason:PROFESSION_GEAR_KEPT"] = "Profession gear is never sold"
L["reason:ENHANCEMENT_CURRENT"] = "Enhancements for this expansion are kept"
L["reason:ENHANCEMENT_LAST_EXPANSION"] = "Last expansion's enhancements are kept"
L["reason:ENHANCEMENT_OUTDATED"] = "Enhancements for past expansions are sold"
L["reason:CONSUMABLE_CURRENT"] = "This expansion's consumables are kept"
L["reason:CONSUMABLE_LAST_EXPANSION"] = "Last expansion's consumables are kept"
L["reason:CONSUMABLE_REAGENT"] = "A recipe somewhere wants this as a reagent"
L["reason:GEM_CURRENT"] = "This expansion's gems are kept"
L["reason:GEM_REAGENT"] = "A recipe somewhere wants this as a reagent"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "Artifact relics are kept"
L["reason:TRADE_GOOD_SPARED"] = "A profession you chose to spare wants this"
L["reason:NOT_WANTED"] = "No box keeps this, so it is sold"
L["reason:REAGENT_WANTED"] = "A profession that can use this wants it as a reagent"
L["reason:NOT_EQUIPPABLE"] = "Not equippable or not recommended for your class"
L["reason:EQUIPPABLE"] = "Good enough against what you have equipped"
L["reason:OUTCLASSED"] = "Outclassed by what you have equipped"
L["reason:OUTDATED_EXPAC"] = "Beats what you have equipped, which is last expansion's"
L["reason:BIND_ON_EQUIP"] = "Bind on Equip gear is kept"
L["reason:ARMOR_RELIC"] = "Nothing can equip a relic any more, so it is sold"
L["reason:RECIPE_LEARNABLE"] = "Not yet learned, so it is kept"
L["reason:HOLIDAY_ITEM"] = "Holiday items are sold"
L["reason:MOUNT_EQUIPMENT"] = "Mount equipment is sold"
L["reason:ALREADY_COLLECTED"] = "Already collected, so it is sold"
L["reason:NOT_COLLECTED"] = "Not yet collected, so it is kept"
L["reason:STILL_TRADEABLE"] = "Still tradeable, so it is kept"
L["reason:ALREADY_LEARNED"] = "Already learned, so it is sold"
L["reason:DEFAULT"] = "No rule claimed it, so it is kept"

L["listReset:warbandBlacklist"] = "Reset Warband Blacklist"
L["listReset:warbandWhitelist"] = "Reset Warband Whitelist"
L["listReset:charBlacklist"] = "Reset Character Blacklist"
L["listReset:charWhitelist"] = "Reset Character Whitelist"
L["listReset:confirm"] = "Are you sure you want to clear this list? This cannot be undone."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Cannot sell %s right now: %s"
L["msg:dropUnexcluded"] = "%s is no longer excluded and will be sold this visit"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "Temporarily Blocked"
L["rule:tempSub"] = "This vendor visit only"
L["rule:tempBlurb"] =
"Items you pulled out of the sell list before pressing Sell. They stay in your bags for this visit, and are judged normally again at the next vendor."
L["rule:black"] = "Never Sell"
L["rule:blackSub"] = "Your Never Sell list"
L["rule:blackBlurb"] =
"Anything on your Never Sell list stays in your bags. A setting on this character wins over the warband list, whichever way the two disagree."
L["rule:gates"] = "Can't Be Sold"
L["rule:gatesSub"] = "The vendor won't take these"
L["rule:gatesBlurb"] =
"Locked items, anything in an equipment set, items with no sell price, and purchases still inside their refund window. Your Always Sell list does not override these, because the vendor would refuse the sale anyway."
L["rule:white"] = "Always Sell"
L["rule:whiteSub"] = "Your Always Sell list"
L["rule:whiteBlurb"] =
"Anything on your Always Sell list is sold even when a later rule would have kept it. This is how you vendor the one crafting reagent you do not want."
L["rule:tempIn"] = "Included This Visit"
L["rule:tempInSub"] = "This vendor visit only"
L["rule:tempInBlurb"] =
"Items you dragged onto the sell list at this vendor. They are sold this visit and judged normally again at the next one."
L["rule:junk"] = "Poor Quality"
L["rule:junkSub"] = "Off by default"
L["rule:junkBlurb"] =
"Grey items, whatever kind of item they are. Off by default, because another addon usually handles this. If nothing else does, turn it on and BatchSell will clear them for you."
L["rule:epic"] = "Legendary And Above"
L["rule:epicSub"] = "Legendary, Artifact, Heirloom"
L["rule:epicBlurb"] =
"Never sold. The vendor shows a price for these and then refuses the sale, so BatchSell does not put them on the list."
L["rule:reagent"] = "Crafting Reagents"
L["rule:reagentSub"] = "Uses your profession list"
L["rule:reagentBlurb"] =
"Keeps any reagent a profession on this account can use, whatever kind of item it is. Reagents turn up as potions, gems and trade goods alike, so this is checked before the item's type. The list is read from the game's own recipes, so it already carries the optional reagents a recipe accepts and every quality tier of one -- there is nothing for you to open or scan."
L["rule:cosmetic"] = "Uncollected Appearances"
L["rule:cosmeticSub"] = "Cosmetic items you haven't collected"
L["rule:cosmeticBlurb"] =
"A cosmetic item you have not collected is kept. Selling one does not collect its appearance -- it is simply gone -- so this is the one place in the window where a mistake cannot be undone. A cosmetic you have already collected is not sold for being one; it just carries nothing left to protect, and goes on to be judged as the weapon or armor it is."
L["rule:consumables"] = "Consumables"
L["rule:consumablesSub"] = "Potions, food, scrolls, curios"
L["rule:consumablesBlurb"] =
"Pick what to keep for each kind of consumable. Anything no box keeps is sold. Potions, elixirs, flasks and food take one more option -- last expansion's as well -- which only applies while you are keeping this expansion's."
L["rule:bags"] = "Bags"
L["rule:bagsSub"] = "Containers of every kind"
L["rule:bagsBlurb"] =
"Never sold. Which bags you carry is your call, so BatchSell does not judge them."
L["rule:gear"] = "Weapons & Armor"
L["rule:gearSub"] = "Judged against what you have equipped"
L["rule:gearBlurb"] =
"One set of settings judges both. Every weapon and every piece of armor is put to the questions below in order, and the first one that answers Keep settles it."
L["rule:gems"] = "Gems"
L["rule:gemsSub"] = "Sockets and artifact relics"
L["rule:gemsBlurb"] =
"One set of choices for every gem. Artifact relics have their own option below, because nothing else about a gem's kind changes whether it is worth keeping."
L["rule:tradeGoods"] = "Trade Goods"
L["rule:tradeGoodsSub"] = "Crafting materials by profession"
L["rule:tradeGoodsBlurb"] =
"Choose whose reagents to hold on to. Anything you don't spare is sold -- though a reagent your professions actually use is already kept by the Crafting Reagents rule above."
L["rule:enhancements"] = "Item Enhancements"
L["rule:enhancementsSub"] = "Enchants, oils, stones"
L["rule:enhancementsBlurb"] =
"A new expansion caps the gear these can be applied to, so older ones stop being worth anything. This expansion's are kept, and last expansion's are kept too if you want to."
L["rule:recipes"] = "Recipes"
L["rule:recipesSub"] = "Patterns, plans, formulae"
L["rule:recipesBlurb"] =
"A recipe carries the profession it belongs to, so it is judged as soon as it turns up at a vendor. A recipe that belongs to no one profession -- a generic pattern or manual -- is left alone, since there is nothing to judge it against."
L["rule:misc"] = "Miscellaneous"
L["rule:miscSub"] = "Pets, mounts, holiday items"
L["rule:miscBlurb"] =
"Spell reagents and uncategorized oddments are left alone. Grey items are handled by the Poor Quality rule above, not here."
L["rule:profession"] = "Profession Gear"
L["rule:professionSub"] = "Tools and accessories"
L["rule:professionBlurb"] =
"Never sold. The tradeable ones are worth money, and the bound ones you crafted for yourself or are using right now, so there is no case where vendoring one is right."
L["rule:housing"] = "Housing"
L["rule:housingSub"] = "Decor and dyes"
L["rule:housingBlurb"] =
"Once a decoration is collected the item itself has no further use, so it can go to the vendor. A dye is not that kind of thing at all: it is a one-time consumable, used up when it is applied, so there is nothing to collect and nothing to have learned. It is never bound either, so the only question worth asking is whether it can still reach someone who wants it."
L["rule:none"] = "Everything Else"
L["rule:noneSub"] = "Quest items, keys, glyphs, tokens"
L["rule:noneBlurb"] =
"Item types BatchSell does not judge at all: quest items, keys, caged pets, glyphs, WoW Tokens, spell reagents, arrows and the other retired categories. They stay in your bags no matter how the rules above are set."

-- The report window's footnote. What BatchSell discloses is not what Openables
-- discloses, so each module states its own.
L["report:blurb"] = "This report carries the item's link, whatever you have equipped in the slot it would fill, and the settings that judged the pair. An item link states your character's level and specialization -- that is part of the link's own format, and removing it would lose the detail that makes the report reproducible. Nothing here names your character, realm, guild or faction, and nothing describes any other slot."

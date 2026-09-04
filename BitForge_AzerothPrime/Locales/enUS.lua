---@class BitForge.AzerothPrime
local ns = select(2, ...)

---@class BitForge.AzerothPrime.Locale
local L = ns.locale

-- Settings panel
L["panel:title"] = "AzerothPrime"
L["settings:openEnabled"] = "Enable the openables button"
L["settings:openEnabledTooltip"] = "Show a button for the next openable or usable item in your bags"
L["settings:sellEnabled"] = "Enable selling at vendors"
L["settings:sellEnabledTooltip"] = "Sell items a rule selects when you open a merchant. Nothing is sold until you set a rule"
L["settings:bankEnabled"] = "Enable depositing to the Warband Bank"
L["settings:bankEnabledTooltip"] = "Deposit reagents, recipes your alts need, and anything you curate when you visit a bank"

-- Leftover-install guard
L["msg:replacedInstalled"] = "AzerothPrime: Switched off %s — this addon replaces it."
L["msg:replacedInstalledFix"] = "Delete the old installation folder to stop seeing this message."

-- Openables button
L["settings:locked"] = "Lock button"
L["settings:lockedTooltip"] = "Prevent the button from being dragged"
L["settings:buttonSize"] = "Button size"
L["settings:buttonSizeTooltip"] = "Width and height of the button, in pixels"
L["settings:showCount"] = "Show stack count"
L["settings:showCountTooltip"] = "Display how many of the item you carry"
L["settings:showCooldown"] = "Show cooldown"
L["settings:showCooldownTooltip"] = "Display the cooldown sweep on the button"
L["settings:resetPosition"] = "Reset position"
L["settings:manageBlacklist"] = "Manage blacklist"

L["tooltip:use"] = "Left-click to open or use."
L["tooltip:skip"] = "Right-click to skip for this session."
L["tooltip:blacklist"] = "Ctrl + right-click to blacklist permanently."
L["tooltip:report"] = "Shift + Alt + right-click to report this verdict."
L["tooltip:drag"] = "Alt + drag to move."

-- The report window's footnote. What Openables discloses is not what the sell
-- verdict discloses -- no item link, so no level and no specialization -- so
-- each feature states its own.
L["report:blurbOpen"] = "This report carries the item, its bag and slot and whether it is locked, how BitForge classified it, the text of its tooltip, and which professions this character knows. Nothing here names your character, realm, guild or faction."

-- /bfdump azerothprime open all's own footnote: it discloses every ranked
-- candidate in the player's bags, not the single item report:blurbOpen
-- describes, and carries no tooltip text.
L["report:blurbField"] = "This report carries every candidate the last scan ranked to open next, in ranked order: each one's name, item ID, bag and slot, stack count, priority and the reason it ranked where it did, whether it is a lockbox needing a key, whether its slot is currently locked, and whether it is on cooldown or deferred. Nothing here names your character, realm, guild or faction, and no item's tooltip text is included."

-- /bfdump azerothprime allowlist's own footnote. It reads the shipped list and
-- each item's tooltip by ID rather than the player's bags, so what it does
-- disclose about them is the exception the sentence has to name.
L["report:blurbAllowList"] = "This report carries every item on the two lists the addon hand-maintains for the open path -- the openable allow list and the deny list, a section for each, or one section when you name a list. Each row gives the item's ID and name, the verdict the open rules reach for it when that list is ignored, the rung that reached it, the priority that rung awarded and, for the allow list alone, the priority it pins the item at, and the grouping the entry falls into. Where a row says instead that the item's data or its tooltip never came back, that reports this client's own cache at the moment you ran the command rather than anything about the item, and a first run says it of most of the allow list. It reads the shipped lists and each item's tooltip by item ID, so it describes nothing in your bags -- except that a listed item you have blacklisted or skipped for this session is reported as such, and so is a verdict that turned on this character's own state, such as whether you can use the item or open a locked box. Nothing here names your character, realm, guild or faction."

L["blacklist:windowTitle"] = "Blacklisted Items"
L["blacklist:empty"] = "No items are blacklisted."
L["blacklist:remove"] = "Remove"
L["blacklist:clearAll"] = "Clear all"
L["blacklist:unknownItem"] = "Item %d"

L["binding:header"] = "BitForge AzerothPrime"
L["binding:use"] = "Use openable item"

L["settings:previewMoves"] = "Preview before depositing"
L["settings:previewMovesTooltip"] = "Show a confirmation window listing every move before anything is deposited"
L["settings:onlyWantedReagents"] = "Only deposit reagents you can use"
L["settings:onlyWantedReagentsTooltip"] = "Deposit only reagents a profession on this account can craft with. Off deposits every reagent, for the auction house"

-- Bank button
L["btn:deposit"] = "Deposit"
L["btn:depositing"] = "Depositing… %d"

-- Preview dialog
L["preview:title"] = "Confirm Deposit"
L["preview:summary"] = "%d item(s) in %d move(s)"
L["preview:toWarband"] = "→ Warband Bank"
L["preview:dontAskAgain"] = "Don't ask again"
L["btn:confirm"] = "Confirm"
L["btn:cancel"] = "Cancel"

-- Messages
L["msg:nothingToDo"] = "AzerothPrime: Nothing to move."
L["msg:done"] = "AzerothPrime: Done. Moved %d item(s)."
L["msg:noVacancy"] = "AzerothPrime: The Warband Bank is full."
L["msg:blockedCombat"] = "AzerothPrime: Stopped — you are in combat."
L["msg:blockedBankClosed"] = "AzerothPrime: Stopped — the bank closed."
L["msg:blockedCursor"] = "AzerothPrime: Stopped — something is on your cursor."
L["msg:blockedLocked"] = "AzerothPrime: Stopped — an item is locked."
L["msg:moveFailed"] = "AzerothPrime: Stopped — a move did not complete."
L["msg:openProfession"] = "AzerothPrime: Open your %s window once so AzerothPrime can record which recipes you know."

-- Curation window
L["curation:title"] = "Item Curation"
L["curation:open"] = "Curate Items"
L["curation:search"] = "Search"
L["curation:filterDestination"] = "Any destination"
L["curation:filterClass"] = "Any item type"
L["curation:source"] = "Source: %s"
L["curation:sourceBuiltIn"] = "This character"
L["curation:count"] = "%d item(s)"
L["curation:unscanned"] = "Never scanned for recipes: %s. Until they are, every recipe for their professions looks wanted and will be deposited."
L["curation:heldBy"] = "Held by"
L["curation:overrideTooltip"] = "You chose this destination. Reset to default to follow the rules again."

-- Destinations
L["dest:warband"] = "Warband Bank"
L["dest:private"] = "Your Bank"
L["dest:privateOwned"] = "Your Bank (%s)"
L["dest:ignore"] = "Leave alone"

-- Private destination
L["preview:toPrivate"] = "→ Your Bank"
L["preview:reclaim"] = "Warband Bank → Your Bank"
L["msg:noVacancyPrivate"] = "AzerothPrime: Your bank is full."
L["curation:privateTooltip"] = "Kept in a character's own bank rather than shared storage. With no owner chosen, the first character to visit a bank claims it."

-- Target quantity
L["curation:targetSuffix"] = "keep %d"
L["target:title"] = "Target Quantity"
L["target:prompt"] = "How many %s should each owner keep?"

-- Row menu
L["menu:resetToDefault"] = "Reset to default"
L["menu:owners"] = "Owners"
L["menu:target"] = "Target quantity"
L["menu:targetNone"] = "No limit"
L["menu:targetOther"] = "Other…"

L["panel:batchSell"] = "Batch Sell"
L["panel:sellManifest"] = "Sell Manifest"
L["panel:blacklist"] = "Blacklist"
L["panel:whitelist"] = "Whitelist"

L["ui:ruleWindowTitle"] = "Batch Sell Rules"
L["ui:ruleWindowNothingToConfigure"] = "Nothing to configure here."
L["ui:ruleWindowDisclaimer"] =
"In combat and inside instances the game sometimes withholds an item's details. AzerothPrime keeps those items rather than guessing, so a few may be missing from the list -- that is expected. A verdict that looks wrong for any other reason is worth reporting."
L["ui:selectedCount"] = "Selected: %d"
L["ui:reagentsNoProfession"] =
"No character on this account has a profession yet, so this rule can keep nothing. Log in on one who does and these controls come back."

L["btn:sellAll"] = "Sell All"
L["btn:refresh"] = "Refresh"
L["btn:rules"] = "Rules"

L["menu:temporaryExclude"] = "Temporarily Exclude"
L["menu:blacklisted"] = "Blacklisted"
L["menu:whitelisted"] = "Whitelisted"
L["menu:noStatus"] = "None"
L["menu:reportVerdict"] = "Report This Verdict"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "Mark this recipe's reagents"

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
L["settings:reagentsExpansions"] = "Which Reagents To Keep"
L["settings:reagentsExpansionsTooltip"] =
"Which expansions' reagents the rule above keeps. It ships set to this expansion alone, so older reagents are offered for sale -- except the ones a recipe you marked still needs, which are kept whatever you tick here"
L["settings:margin"] = "Item Level Margin"
L["settings:marginTooltip"] =
"How far under the slot a piece of your own quality can sit before it must be sold. At 0 it only has to match the slot"
L["settings:qualityMargin"] = "Quality Margin"
L["settings:qualityMarginTooltip"] =
"What one quality tier is worth in item levels. At 10, gear a tier below what you have equipped needs 10 more item levels to be kept, and a tier above survives 10 under it. At 0 quality stops counting and item level alone decides. At Always, any higher quality is kept whatever its item level, and no item level saves a lower one"
L["settings:qualityMarginAlways"] = "Always"
L["settings:keepForDisenchant"] = "Keep Gear Yielding Materials From"
L["settings:keepForDisenchantTooltip"] =
"Keep gear an enchanter could break down, by the expansion of the materials it would yield rather than by the gear's own age -- gear from a finished expansion yields that expansion's materials. Your own enchanter always keeps what only they can reach, at any setting, but this still decides whether that reach extends to older materials"
L["settings:spareBindOnAccount"] = "Spare Bind on Account Gear"
L["settings:spareBindOnAccountTooltip"] =
"Which expansions' Bind on Account gear to keep while it can still be passed to another character"
L["settings:spareBindOnEquip"] = "Spare Bind on Equip Gear"
L["settings:spareBindOnEquipTooltip"] =
"Which expansions' Bind on Equip gear to keep while it can still reach another character or the auction house"
L["settings:keepUncollectedCosmetic"] = "Keep Uncollected Appearances"
L["settings:keepUncollectedCosmeticTooltip"] =
"Keep any item whose appearance you have not collected. Vendoring an ordinary piece still collects it, but a cosmetic item grants its look on use -- sell that and the appearance is gone for good"
L["settings:sellRelics"] = "Sell Classic Relics"
L["settings:sellRelicsTooltip"] =
"Sell idols, librams, totems and sigils -- the relic slot Cataclysm removed. Not Legion's artifact relics, which are gems and share only the subclass number"
L["settings:gemsExpansions"] = "Which Gems To Keep"
L["settings:gemsExpansionsTooltip"] =
"Which expansions' gems to keep. Anything not ticked falls through to the two questions below"
L["settings:gemsRecipesNow"] = "Keep Current Gems A Recipe Wants"
L["settings:gemsRecipesNowTooltip"] =
"Keep a current-expansion gem some profession's recipe uses as a reagent, whoever owns that profession. The question goes to the recipe catalogue, and a gem it does not list counts as one no recipe wants"
L["settings:gemsRecipesOld"] = "Keep Older Gems A Recipe Wants"
L["settings:gemsRecipesOldTooltip"] =
"The same question for gems from past expansions. What your own professions use is already kept elsewhere, so this column is for everybody else's recipes"
L["settings:keepArtifactRelics"] = "Keep Artifact Relics"
L["settings:keepArtifactRelicsTooltip"] =
"Keep the relics socketed into Legion artifact weapons. Nothing has used them since Legion, so this is worth turning off unless you collect them"
L["settings:enhancementsExpansions"] = "Which Enhancements To Keep"
L["settings:enhancementsExpansionsTooltip"] =
"Which expansions' item enhancements to keep. A new expansion caps the gear an enhancement fits, so tick the expansion whose gear you are actually wearing"
L["settings:keepLearnable"] = "Keep Recipes You Can Learn"
L["settings:keepLearnableTooltip"] =
"Keep a recipe this character has not learned"
L["settings:keepTradeableRecipes"] = "Keep Tradeable Recipes"
L["settings:keepTradeableRecipesTooltip"] =
"Keep a recipe that is still unbound, so it can reach an alt or the auction house even when this character has already learned it"
L["settings:sellCollectedMounts"] = "Sell Collected Mounts"
L["settings:sellCollectedMountsTooltip"] =
"Sell a mount you already own, once the copy is soulbound. An unbound one is kept whatever this says, because it can still reach someone who wants it"
L["settings:sellCollectedToys"] = "Sell Collected Toys"
L["settings:sellCollectedToysTooltip"] =
"Sells a toy already in your toy box, once the copy in your bags is bound. An unbound one is kept whatever your collection says, because it can still reach someone who wants it"
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

L["spare:none"] = "None"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "All expansions"
L["expansion:current"] = "Current expansion"

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
L["option:expansions"] = "Which expansions to keep"
L["option:recipesNow"] = "Also keep this expansion's if a recipe wants it"
L["option:recipesOld"] = "Also keep older ones if a recipe wants it"

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
-- Which claimant took an item the sell rules would otherwise have sold. These
-- displace the reason line rather than joining it: every reason: string below
-- asserts its own outcome, so pairing one with a heading another claimant
-- decided prints a contradiction. Keyed by enum.CLAIM, one per disposition
-- that can outrank a sell claim.
--
-- Written as clauses that follow the heading, the way every reason: string is,
-- and deliberately without an outcome prefix of their own: the heading above
-- them already says "will be kept", and "Kept: ..." underneath it said the
-- outcome twice.
L["claimed:OPEN"] = "The openables button has claimed it"
L["claimed:DEPOSIT_WARBAND"] = "Going to the Warband Bank instead"
L["claimed:DEPOSIT_PRIVATE"] = "Going to a character's own bank instead"
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
L["reason:ENHANCEMENT_EXPANSION"] = "Enhancements from this expansion are kept"
L["reason:CONSUMABLE_EXPANSION"] = "Consumables from this expansion are kept"
L["reason:CONSUMABLE_REAGENT"] = "A recipe somewhere wants this as a reagent"
L["reason:GEM_EXPANSION"] = "Gems from this expansion are kept"
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
"Grey items, whatever kind of item they are. Off by default, because another addon usually handles this. If nothing else does, turn it on and AzerothPrime will clear them for you."
L["rule:epic"] = "Legendary And Above"
L["rule:epicSub"] = "Legendary, Artifact, Heirloom"
L["rule:epicBlurb"] =
"Never sold. The vendor shows a price for these and then refuses the sale, so AzerothPrime does not put them on the list."
L["rule:reagent"] = "Crafting Reagents"
L["rule:reagentSub"] = "Uses your profession list"
L["rule:reagentBlurb"] =
"Keeps any reagent a profession on this account can use, whatever kind of item it is. Reagents turn up as potions, gems and trade goods alike, so this is checked before the item's type. Only this expansion's are kept unless you say otherwise; an older one is kept as well when a recipe you marked still needs it, whatever the expansion boxes say. The list is read from the game's own recipes, so it already carries the optional reagents a recipe accepts and every quality tier of one -- there is nothing for you to open or scan."
L["rule:cosmetic"] = "Uncollected Appearances"
L["rule:cosmeticSub"] = "Cosmetic items you haven't collected"
L["rule:cosmeticBlurb"] =
"A cosmetic item you have not collected is kept. Selling one does not collect its appearance -- it is simply gone -- so this is the one place in the window where a mistake cannot be undone. A cosmetic you have already collected is not sold for being one; it just carries nothing left to protect, and goes on to be judged as the weapon or armor it is."
L["rule:consumables"] = "Consumables"
L["rule:consumablesSub"] = "Potions, food, scrolls, curios"
L["rule:consumablesBlurb"] =
"Pick what to keep for each kind of consumable. Anything no box keeps is sold."
L["rule:bags"] = "Bags"
L["rule:bagsSub"] = "Containers of every kind"
L["rule:bagsBlurb"] =
"Never sold. Which bags you carry is your call, so AzerothPrime does not judge them."
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
"A new expansion caps the gear these can be applied to, so older ones stop being worth anything. Tick every expansion whose gear you are actually wearing, this one included -- none is kept automatically."
L["rule:recipes"] = "Recipes"
L["rule:recipesSub"] = "Patterns, plans, formulae"
L["rule:recipesBlurb"] =
"A recipe carries the profession it belongs to, so it is judged as soon as it turns up at a vendor. A recipe that belongs to no one profession -- a generic pattern or manual -- is left alone, since there is nothing to judge it against."
L["rule:misc"] = "Miscellaneous"
L["rule:miscSub"] = "Pets, mounts, toys, holiday items"
L["rule:miscBlurb"] =
"Spell reagents are left alone. Among uncategorized oddments, only a toy is judged: it is sold once your toy box already has it and the copy in your bags is bound. Grey items are handled by the Poor Quality rule above, not here."
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
"Item types AzerothPrime does not judge at all: quest items, keys, caged pets, glyphs, WoW Tokens, spell reagents, arrows and the other retired categories. They stay in your bags no matter how the rules above are set."

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "This report carries the item's link and its other stats, BitForge's own verdict and the rule that decided it, whether you have blacklisted or whitelisted this item yourself, whatever you have equipped in the slot it would fill, and the settings that judged the pair. An item link states your character's level and specialization -- that is part of the link's own format, and removing it would lose the detail that makes the report reproducible. Nothing here names your character, realm, guild or faction, and nothing describes any other slot."

-- The disenchant scan's own footnote: it discloses several bag items and
-- their tooltips, not the single item/link pair report:blurbSell describes.
L["report:blurbDisenchant"] = "This report carries the client's current spell-targeting state and whether this character can disenchant. It also carries up to eight weapons or pieces of armour from your bags that could be worth disenchanting, each with its bag and slot, item ID, name, quality, item type and BitForge's own prediction of whether it can be disenchanted, plus the full text of its tooltip. For any other bagged item it could not read the quality of, it carries that item's bag, slot, item ID and name too. Nothing here names your character, realm, guild or faction."

-- The combined verdict's own footnote: it discloses the item's link and
-- quality once, which bag and slot answered when the item is carried, the
-- disposition every rule path reached (with its own detail and whether it
-- came from an override), then every rule path's own claim, strength and
-- reason beside it, and -- for a Poor-quality item -- whether Blizzard's
-- own Sell Junk sweep would sell it regardless. Not the equipped-slot
-- comparison report:blurbSell describes, since a combined verdict has no
-- room for path-specific detail.
--
-- Two more since spec #379, and the second is a different KIND of disclosure
-- from everything above it: the reagent audit (what the catalogue says, which
-- profession mask answered for this copy, the expansion tick and the marked
-- recipe), and the marked-recipe list itself, which says what this player
-- crafts rather than what they are holding. That is why it is named twice
-- over -- once as a list and once as what the list means.
L["report:blurbDispatch"] = "This report carries the item's link and quality, which bag and slot it answered from when the item is carried, the disposition every rule path reached for it -- its own extra detail, and whether it came from a stored override -- and each path's own claim, strength and reason, including any path that could not answer at all. When the item is Poor quality, it also states whether Blizzard's own Sell Junk sweep will sell it regardless, given your own selling and junk-rule settings. When the item is a crafting reagent, it also carries the professions the shipped catalogue lists it for, the professions recorded for this account -- or for this character alone, when the copy is soulbound -- the expansion the item belongs to and whether you have that expansion ticked, whether a recipe you marked needs it, and which of those the reagent rule itself answered with -- its own verdict, which is not always what decided the item. It always lists the recipes you have marked, by ID and by name where the game can still name one, so it says what you craft and not only what you are carrying. With diagnostics enabled, it also carries the map you were standing on and the map that contains it, and, for an item that is gated to a place, the places that gate names and which of them matched where you were. An item link states your character's level and specialization -- that is part of the link's own format, and removing it would lose the detail that makes the report reproducible. Nothing here names your character, realm, guild or faction."

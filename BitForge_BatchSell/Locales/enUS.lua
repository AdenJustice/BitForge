---@class BitForge.BatchSell
local ns = select(2, ...)
---@class BitForge.BatchSell.Locale
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Batch Sell"
L["panel:sellManifest"] = "Sell Manifest"
L["panel:blacklist"] = "Blacklist"
L["panel:whitelist"] = "Whitelist"

-- Buttons
L["btn:sellAll"] = "Sell All"
L["btn:refresh"] = "Refresh"

-- Context menu
L["menu:addToBlacklist"] = "Add To Blacklist"
L["menu:addToWhitelist"] = "Add To Whitelist"
L["menu:addToBlacklistChar"] = "Add To Blacklist (Character)"
L["menu:addToWhitelistChar"] = "Add To Whitelist (Character)"
L["menu:clearCharOverride"] = "Clear Character Override"
L["menu:resetListEntry"] = "Remove From List"
L["menu:temporaryExclude"] = "Temporarily Exclude"

-- Status
L["status:noItemsToSell"] = "No items to sell"
L["status:itemsTotal"] = "%d items  |  Total: %s"

-- Merchant row
L["tooltip:charOverride"] = "This character's setting overrides the warband list — this item will be sold."

-- Section titles
L["section:general"] = "General"
L["section:equipment"] = "Equipment"
L["section:materials"] = "Crafting Materials"
L["section:other"] = "Consumables & Other"
L["section:lists"] = "Lists"

-- Settings
L["settings:sellJunk"] = "Sell Junk"
L["settings:sellJunkTooltip"] = "Sell all poor quality (grey) items automatically when visiting a vendor"
L["settings:limitBatch"] = "Limit Batch to 12"
L["settings:limitBatchTooltip"] = "Sell at most 12 items per click to avoid server throttling"
L["settings:sellEquipment"] = "Sell Equipment"
L["settings:sellEquipmentTooltip"] =
"Let armor and weapons be sold. With this off, no gear is ever vendored"
L["settings:ilvlMargin"] = "Item Level Margin"
L["settings:ilvlMarginTooltip"] =
"What one quality tier is worth in item levels. At 10, gear a tier below what you have equipped has to beat it by 10 to be kept, and a tier above survives 10 under it. At your own quality a piece has to beat the slot outright. At 0 quality stops counting and item level alone decides"
L["settings:emphasizeQuality"] = "  Emphasize Quality"
L["settings:emphasizeQualityTooltip"] =
"Count a quality tier for twice the margin, and allow a piece of your own quality that margin below the slot. Quality above what you have equipped becomes cheaper to keep, and quality below it dearer to excuse"
L["settings:keepBindOnAccount"] = "Keep Bind on Account"
L["settings:keepBindOnAccountTooltip"] = "Keep Bind on Account (heirloom) gear"
L["settings:keepBindOnAccountPastExpac"] = "  Include Past Expansions"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Also keep Bind on Account gear from past expansions"
L["settings:keepDisenchantables"] = "Keep Disenchantables"
L["settings:keepDisenchantablesTooltip"] = "Enchanters: keep BOP/BOE/BOA gear. Others: keep BOE/BOA gear for AH or alts"
L["settings:keepDisenchantablesPastExpac"] = "  Include Past Expansions"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Also keep disenchantable gear from past expansions"
L["settings:keepUsedReagents"] = "Keep Reagents Your Professions Use"
L["settings:keepUsedReagentsTooltip"] = "Keep crafting reagents any profession on this account can use"
L["settings:materialsMode"] = "Crafting Materials"
L["settings:materialsModeTooltip"] =
"What to do with reagents, trade goods, gems, enchantments and recipes"
L["settings:materialsExpansion"] = "  Keep From Expansion"
L["settings:materialsExpansionTooltip"] =
"Keep materials from this expansion onward and sell anything older. Used only when Crafting Materials is set to keep from a chosen expansion"
L["settings:otherMode"] = "Consumables & Other"
L["settings:otherModeTooltip"] =
"What to do with consumables, containers, battle pets, profession gear and housing decor"

-- Sell modes
L["mode:keepAll"] = "Keep All"
L["mode:keepCurrent"] = "Keep Current Expansion"
L["mode:keepFrom"] = "Keep From Expansion"
L["mode:sellAll"] = "Sell All"

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
L["reason:CATEGORY"] = "This kind of item is set to be kept"
L["reason:CURRENT_EXPANSION"] = "From an expansion you are keeping"
L["reason:BIND_ON_ACCOUNT"] = "Bind on Account gear is kept"
L["reason:DISENCHANTABLE"] = "Worth keeping to disenchant or sell on"
L["reason:REAGENT_WANTED"] = "A profession on this account uses this"
L["reason:NOT_EQUIPPABLE"] = "Not equippable or not recommended for your class"
L["reason:EQUIPPABLE"] = "Good enough against what you have equipped"
L["reason:OUTCLASSED"] = "Outclassed by what you have equipped"
L["reason:SELL_MODE"] = "This kind of item is set to be sold"
L["reason:DEFAULT"] = "No rule claimed it, so it is kept"

-- Expansion labels
L["expansion:classic"] = "Classic"
L["expansion:burningCrusade"] = "The Burning Crusade"
L["expansion:wrathOfTheLichKing"] = "Wrath of the Lich King"
L["expansion:cataclysm"] = "Cataclysm"
L["expansion:mistsOfPandaria"] = "Mists of Pandaria"
L["expansion:warlordsOfDraenor"] = "Warlords of Draenor"
L["expansion:legion"] = "Legion"
L["expansion:battleForAzeroth"] = "Battle for Azeroth"
L["expansion:shadowlands"] = "Shadowlands"
L["expansion:dragonflight"] = "Dragonflight"
L["expansion:theWarWithin"] = "The War Within"
L["expansion:midnight"] = "Midnight"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Reset Warband Blacklist"
L["listReset:warbandWhitelist"] = "Reset Warband Whitelist"
L["listReset:charBlacklist"] = "Reset Character Blacklist"
L["listReset:charWhitelist"] = "Reset Character Whitelist"
L["listReset:confirm"] = "Are you sure you want to clear this list? This cannot be undone."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Cannot sell %s right now: %s"
L["msg:dropUnexcluded"] = "%s is no longer excluded and will be sold this visit"

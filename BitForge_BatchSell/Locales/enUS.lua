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

-- Settings
L["settings:sellJunk"] = "Sell Junk"
L["settings:sellJunkTooltip"] = "Sell all poor quality (grey) items automatically when visiting a vendor"
L["settings:keepEquippable"] = "Keep Equippable"
L["settings:keepEquippableTooltip"] = "Keep all items equippable by your class"
L["settings:keepBindOnAccount"] = "Keep Bind on Account"
L["settings:keepBindOnAccountTooltip"] = "Keep Bind on Account (heirloom) gear"
L["settings:keepBindOnAccountPastExpac"] = "  Include Past Expansions"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Also keep Bind on Account gear from past expansions"
L["settings:keepDisenchantables"] = "Keep Disenchantables"
L["settings:keepDisenchantablesTooltip"] = "Enchanters: keep BOP/BOE/BOA gear. Others: keep BOE/BOA gear for AH or alts"
L["settings:keepDisenchantablesPastExpac"] = "  Include Past Expansions"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Also keep disenchantable gear from past expansions"
L["settings:limitBatch"] = "Limit Batch to 12"
L["settings:limitBatchTooltip"] = "Sell at most 12 items per click to avoid server throttling"
L["settings:qualityThreshold"] = "Quality Threshold"
L["settings:qualityThresholdTooltip"] = "Sell items at or below this quality"
L["settings:ilvlThreshold"] = "Item Level Margin"
L["settings:ilvlThresholdTooltip"] =
"Keep equippable items within this many ilvls of your equipped gear (negative = keep better items)"
L["settings:sellPastExpansion"] = "Sell Past Expansion Items"
L["settings:sellPastExpansionTooltip"] = "Sell items from expansions older than the selected threshold"
L["settings:expansionThreshold"] = "Expansion Threshold"
L["settings:expansionThresholdTooltip"] = "Sell items from expansions older than the selected one"

-- Quality labels
L["quality:poor"] = "Poor"
L["quality:common"] = "Common"
L["quality:uncommon"] = "Uncommon"
L["quality:rare"] = "Rare"
L["quality:epic"] = "Epic"

-- Expansion labels
L["expansion:all"] = "All Expansions"
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

-- List reset buttons
L["listReset:warbandBlacklist"] = "Reset Warband Blacklist"
L["listReset:warbandWhitelist"] = "Reset Warband Whitelist"
L["listReset:charBlacklist"] = "Reset Character Blacklist"
L["listReset:charWhitelist"] = "Reset Character Whitelist"
L["listReset:confirm"] = "Are you sure you want to clear this list? This cannot be undone."

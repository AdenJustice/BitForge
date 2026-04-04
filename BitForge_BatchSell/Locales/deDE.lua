if GetLocale() ~= "deDE" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Stapelverkauf"
L["panel:sellManifest"] = "Verkaufsliste"
L["panel:blacklist"] = "Sperrliste"
L["panel:whitelist"] = "Erlaubnisliste"

-- Buttons
L["btn:sellAll"] = "Alles verkaufen"
L["btn:refresh"] = "Aktualisieren"

-- Context menu
L["menu:addToBlacklist"] = "Zur Sperrliste hinzufügen"
L["menu:addToWhitelist"] = "Zur Erlaubnisliste hinzufügen"
L["menu:addToBlacklistChar"] = "Zur Sperrliste hinzufügen (Charakter)"
L["menu:addToWhitelistChar"] = "Zur Erlaubnisliste hinzufügen (Charakter)"
L["menu:clearCharOverride"] = "Charaktervorrang aufheben"
L["menu:resetListEntry"] = "Aus Liste entfernen"
L["menu:temporaryExclude"] = "Vorübergehend ausschließen"

-- Status
L["status:noItemsToSell"] = "Keine Gegenstände zum Verkaufen"
L["status:itemsTotal"] = "%d Gegenstände  |  Gesamt: %s"

-- Merchant row
L["tooltip:charOverride"] =
"Die Einstellung dieses Charakters hat Vorrang vor der Kriegerschar-Liste – dieser Gegenstand wird verkauft."

-- Settings
L["settings:sellJunk"] = "Schrott verkaufen"
L["settings:sellJunkTooltip"] = "Alle Gegenstände schlechter Qualität (grau) automatisch beim Besuch eines Händlers verkaufen"
L["settings:keepEquippable"] = "Anlegbare Gegenstände behalten"
L["settings:keepEquippableTooltip"] = "Alle von deiner Klasse anlegbaren Gegenstände behalten"
L["settings:keepBindOnAccount"] = "Kontogebundene Gegenstände behalten"
L["settings:keepBindOnAccountTooltip"] = "Kontogebundene (Erbstück-) Ausrüstung behalten"
L["settings:keepBindOnAccountPastExpac"] = "  Vergangene Erweiterungen einschließen"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Auch kontogebundene Ausrüstung aus vergangenen Erweiterungen behalten"
L["settings:keepDisenchantables"] = "Entzauberbare Gegenstände behalten"
L["settings:keepDisenchantablesTooltip"] = "Verzauberer: BOP/BOE/BOA-Ausrüstung behalten. Andere: BOE/BOA-Ausrüstung für AH oder Twinks behalten"
L["settings:keepDisenchantablesPastExpac"] = "  Vergangene Erweiterungen einschließen"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Auch entzauerbare Ausrüstung aus vergangenen Erweiterungen behalten"
L["settings:limitBatch"] = "Stapel auf 12 begrenzen"
L["settings:limitBatchTooltip"] = "Pro Klick höchstens 12 Gegenstände verkaufen, um Server-Drosselung zu vermeiden"
L["settings:qualityThreshold"] = "Qualitätsschwelle"
L["settings:qualityThresholdTooltip"] = "Gegenstände auf oder unter dieser Qualität verkaufen"
L["settings:ilvlThreshold"] = "Gegenstandsstufen-Toleranz"
L["settings:ilvlThresholdTooltip"] =
"Anlegbare Gegenstände innerhalb dieser Gegenstandsstufen-Toleranz zur ausgerüsteten Ausrüstung behalten (negativ = bessere Gegenstände behalten)"
L["settings:sellPastExpansion"] = "Gegenstände vergangener Erweiterungen verkaufen"
L["settings:sellPastExpansionTooltip"] = "Gegenstände aus Erweiterungen verkaufen, die älter als die ausgewählte Schwelle sind"
L["settings:expansionThreshold"] = "Erweiterungsschwelle"
L["settings:expansionThresholdTooltip"] = "Gegenstände aus Erweiterungen verkaufen, die älter als die ausgewählte sind"

-- Quality labels
L["quality:poor"] = "Schlecht"
L["quality:common"] = "Gewöhnlich"
L["quality:uncommon"] = "Ungewöhnlich"
L["quality:rare"] = "Selten"
L["quality:epic"] = "Episch"

-- Expansion labels
L["expansion:all"] = "Alle Erweiterungen"
L["expansion:classic"] = "Classic"
L["expansion:burningCrusade"] = "Der Brennende Kreuzzug"
L["expansion:wrathOfTheLichKing"] = "Zorn des Lichkönigs"
L["expansion:cataclysm"] = "Cataclysm"
L["expansion:mistsOfPandaria"] = "Nebel der Pandaria"
L["expansion:warlordsOfDraenor"] = "Kriegsherren von Draenor"
L["expansion:legion"] = "Legion"
L["expansion:battleForAzeroth"] = "Krieg um Azeroth"
L["expansion:shadowlands"] = "Shadowlands"
L["expansion:dragonflight"] = "Dragonflight"
L["expansion:theWarWithin"] = "The War Within"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Kriegerschar-Sperrliste zurücksetzen"
L["listReset:warbandWhitelist"] = "Kriegerschar-Erlaubnisliste zurücksetzen"
L["listReset:charBlacklist"] = "Charakter-Sperrliste zurücksetzen"
L["listReset:charWhitelist"] = "Charakter-Erlaubnisliste zurücksetzen"
L["listReset:confirm"] = "Bist du sicher, dass du diese Liste leeren möchtest? Dies kann nicht rückgängig gemacht werden."

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

-- Section titles
L["section:general"] = "Allgemein"
L["section:equipment"] = "Ausrüstung"
L["section:materials"] = "Handwerksmaterialien"
L["section:other"] = "Verbrauchsgegenstände & Sonstiges"
L["section:lists"] = "Listen"

-- Settings
L["settings:sellJunk"] = "Schrott verkaufen"
L["settings:sellJunkTooltip"] = "Alle Gegenstände schlechter Qualität (grau) automatisch beim Besuch eines Händlers verkaufen"
L["settings:limitBatch"] = "Stapel auf 12 begrenzen"
L["settings:limitBatchTooltip"] = "Pro Klick höchstens 12 Gegenstände verkaufen, um Server-Drosselung zu vermeiden"
L["settings:sellEquipment"] = "Ausrüstung verkaufen"
L["settings:sellEquipmentTooltip"] =
"Rüstung und Waffen dürfen verkauft werden. Ist dies aus, wird niemals Ausrüstung beim Händler verkauft"
L["settings:ilvlThreshold"] = "Gegenstandsstufen-Toleranz"
L["settings:ilvlThresholdTooltip"] =
"Wie viele Gegenstandsstufen unter dem in diesem Slot angelegten Gegenstand ein Teil liegen darf, um trotzdem behalten zu werden"
L["settings:marginOnHigherQuality"] = "  Toleranz auf höhere Qualität anwenden"
L["settings:marginOnHigherQualityTooltip"] =
"Wendet die Toleranz auf Ausrüstung an, deren Qualität höher ist als die deiner angelegten. Ist dies aus, wird jede Qualitätsverbesserung unabhängig von ihrer Gegenstandsstufe behalten"
L["settings:marginOnSameQuality"] = "  Toleranz auf gleiche Qualität anwenden"
L["settings:marginOnSameQualityTooltip"] =
"Wendet die Toleranz auf Ausrüstung derselben Qualität wie deine angelegte an. Ist dies aus, wird nur Ausrüstung auf oder über deiner angelegten Gegenstandsstufe behalten"
L["settings:marginOnLowerQuality"] = "  Toleranz auf niedrigere Qualität anwenden"
L["settings:marginOnLowerQualityTooltip"] =
"Wendet die Toleranz auf Ausrüstung an, deren Qualität niedriger ist als die deiner angelegten. Ist dies aus, wird jede Qualitätsverschlechterung unabhängig von ihrer Gegenstandsstufe verkauft. Ausrüstung, die zwei oder mehr Qualitätsstufen niedriger ist, erhält nie die Toleranz"
L["settings:keepBindOnAccount"] = "Kontogebundene Gegenstände behalten"
L["settings:keepBindOnAccountTooltip"] = "Kontogebundene (Erbstück-) Ausrüstung behalten"
L["settings:keepBindOnAccountPastExpac"] = "  Vergangene Erweiterungen einschließen"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Auch kontogebundene Ausrüstung aus vergangenen Erweiterungen behalten"
L["settings:keepDisenchantables"] = "Entzauberbare Gegenstände behalten"
L["settings:keepDisenchantablesTooltip"] = "Verzauberer: BOP/BOE/BOA-Ausrüstung behalten. Andere: BOE/BOA-Ausrüstung für AH oder Twinks behalten"
L["settings:keepDisenchantablesPastExpac"] = "  Vergangene Erweiterungen einschließen"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Auch entzauberbare Ausrüstung aus vergangenen Erweiterungen behalten"
L["settings:materialsMode"] = "Handwerksmaterialien"
L["settings:materialsModeTooltip"] =
"Was mit Reagenzien, Handelsgütern, Edelsteinen, Verzauberungen und Rezepten geschehen soll"
L["settings:materialsExpansion"] = "  Ab Erweiterung behalten"
L["settings:materialsExpansionTooltip"] =
"Materialien ab dieser Erweiterung behalten und alles Ältere verkaufen. Gilt nur, wenn Handwerksmaterialien auf Ab Erweiterung behalten eingestellt ist"
L["settings:otherMode"] = "Verbrauchsgegenstände & Sonstiges"
L["settings:otherModeTooltip"] =
"Was mit Verbrauchsgegenständen, Behältern, Kampfhaustieren, Berufsausrüstung und Hausdekoration geschehen soll"

-- Sell modes
L["mode:keepAll"] = "Alles behalten"
L["mode:keepCurrent"] = "Aktuelle Erweiterung behalten"
L["mode:keepFrom"] = "Ab Erweiterung behalten"
L["mode:sellAll"] = "Alles verkaufen"

-- List tabs
L["btn:removeEntry"] = "Entfernen"
L["list:warband"] = "Kriegerschar"
L["list:character"] = "Charakter"
L["status:listEmpty"] = "Diese Liste ist leer"
L["status:listCount"] = "%d Einträge"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Stapelverkauf: wird verkauft"
L["verdict:keep"] = "Stapelverkauf: wird behalten"
L["reason:TEMP_EXCLUDED"] = "Für diesen Händlerbesuch ausgeschlossen"
L["reason:BLACKLISTED"] = "Auf deiner Sperrliste"
L["reason:LOCKED"] = "Der Gegenstand ist gesperrt"
L["reason:EQUIPMENT_SET"] = "Teil eines Ausrüstungssets"
L["reason:NO_SELL_PRICE"] = "Kein Händler kauft ihn"
L["reason:REFUNDABLE"] = "Noch innerhalb der Rückerstattungsfrist"
L["reason:WHITELISTED"] = "Auf deiner Erlaubnisliste"
L["reason:TEMP_INCLUDED"] = "Für diesen Händlerbesuch hinzugefügt"
L["reason:CATEGORY"] = "Diese Art von Gegenstand ist zum Behalten eingestellt"
L["reason:CURRENT_EXPANSION"] = "Aus einer Erweiterung, die du behältst"
L["reason:BIND_ON_ACCOUNT"] = "Kontogebundene Ausrüstung wird behalten"
L["reason:DISENCHANTABLE"] = "Lohnt sich zum Entzaubern oder Weiterverkaufen"
L["reason:EQUIPPABLE"] = "Gut genug im Vergleich zu deiner angelegten Ausrüstung"
L["reason:OUTCLASSED"] = "Deiner angelegten Ausrüstung unterlegen"
L["reason:SELL_MODE"] = "Diese Art von Gegenstand ist zum Verkaufen eingestellt"
L["reason:DEFAULT"] = "Keine Regel hat ihn beansprucht, daher wird er behalten"

-- Expansion labels
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
L["expansion:midnight"] = "Midnight"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Kriegerschar-Sperrliste zurücksetzen"
L["listReset:warbandWhitelist"] = "Kriegerschar-Erlaubnisliste zurücksetzen"
L["listReset:charBlacklist"] = "Charakter-Sperrliste zurücksetzen"
L["listReset:charWhitelist"] = "Charakter-Erlaubnisliste zurücksetzen"
L["listReset:confirm"] = "Bist du sicher, dass du diese Liste leeren möchtest? Dies kann nicht rückgängig gemacht werden."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Kann %s gerade nicht verkaufen: %s"
L["msg:dropUnexcluded"] = "%s ist nicht mehr ausgeschlossen und wird bei diesem Händlerbesuch verkauft"

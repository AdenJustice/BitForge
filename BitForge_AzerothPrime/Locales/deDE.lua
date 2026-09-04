if GetLocale() ~= "deDE" then return end
---@class BitForge.AzerothPrime
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "AzerothPrime"
L["settings:openEnabled"] = "Schaltfläche für zu öffnende Gegenstände aktivieren"
L["settings:openEnabledTooltip"] = "Zeigt eine Schaltfläche für den nächsten Gegenstand in Euren Taschen, der geöffnet oder benutzt werden kann"
L["settings:sellEnabled"] = "Verkauf bei Händlern aktivieren"
L["settings:sellEnabledTooltip"] = "Verkauft Gegenstände, die eine Regel auswählt, sobald Ihr einen Händler öffnet. Es wird nichts verkauft, bis Ihr eine Regel festlegt"
L["settings:bankEnabled"] = "Einlagern in die Kriegsmeutenbank aktivieren"
L["settings:bankEnabledTooltip"] = "Verstaut Reagenzien, von Twinks benötigte Rezepte und selbst gewählte Gegenstände, sobald Ihr eine Bank besucht"

-- Leftover-install guard
L["msg:replacedInstalled"] = "AzerothPrime: %s deaktiviert — wird durch dieses Addon ersetzt."
L["msg:replacedInstalledFix"] = "Löscht den alten Installationsordner, um diese Meldung nicht mehr zu sehen."

-- Openables button
L["settings:locked"] = "Schaltfläche sperren"
L["settings:lockedTooltip"] = "Verhindert das Verschieben der Schaltfläche"
L["settings:buttonSize"] = "Schaltflächengröße"
L["settings:buttonSizeTooltip"] = "Breite und Höhe der Schaltfläche in Pixeln"
L["settings:showCount"] = "Anzahl anzeigen"
L["settings:showCountTooltip"] = "Zeigt an, wie viele Exemplare des Gegenstands Ihr bei Euch tragt"
L["settings:showCooldown"] = "Abklingzeit anzeigen"
L["settings:showCooldownTooltip"] = "Zeigt die Abklingzeit auf der Schaltfläche"
L["settings:resetPosition"] = "Position zurücksetzen"
L["settings:manageBlacklist"] = "Ausschlussliste verwalten"

L["tooltip:use"] = "Linksklick zum Öffnen oder Benutzen."
L["tooltip:skip"] = "Rechtsklick, um für diese Sitzung zu überspringen."
L["tooltip:blacklist"] = "Strg + Rechtsklick, um dauerhaft auszuschließen."
L["tooltip:report"] = "Umschalt + Alt + Rechtsklick, um dieses Urteil zu melden."
L["tooltip:drag"] = "Alt + Ziehen zum Verschieben."

L["report:blurbOpen"] = "Dieser Bericht enthält den Gegenstand, seine Tasche und seinen Platz sowie ob er gesperrt ist, wie BitForge ihn eingestuft hat, den Text seines Tooltips und welche Berufe dieser Charakter kennt. Nichts hier nennt Euren Charakter, Euren Realm, Eure Gilde oder Eure Fraktion."

L["blacklist:windowTitle"] = "Ausgeschlossene Gegenstände"
L["blacklist:empty"] = "Es sind keine Gegenstände ausgeschlossen."
L["blacklist:remove"] = "Entfernen"
L["blacklist:clearAll"] = "Alle löschen"
L["blacklist:unknownItem"] = "Gegenstand %d"

L["binding:header"] = "BitForge AzerothPrime"
L["binding:use"] = "Öffenbaren Gegenstand benutzen"

L["settings:previewMoves"] = "Vor dem Verstauen anzeigen"
L["settings:previewMovesTooltip"] = "Ein Bestätigungsfenster mit allen Bewegungen anzeigen, bevor etwas verstaut wird"
L["settings:onlyWantedReagents"] = "Nur verwendbare Reagenzien einlagern"
L["settings:onlyWantedReagentsTooltip"] = "Nur Reagenzien einlagern, mit denen ein Beruf auf diesem Konto arbeiten kann. Aus lagert alle Reagenzien ein, für das Auktionshaus"

L["btn:deposit"] = "Verstauen"
L["btn:depositing"] = "Verstaue… %d"

L["preview:title"] = "Verstauen bestätigen"
L["preview:summary"] = "%d Gegenstand/Gegenstände in %d Bewegung(en)"
L["preview:toWarband"] = "→ Kriegsmeutenbank"
L["preview:dontAskAgain"] = "Nicht erneut fragen"
L["btn:confirm"] = "Bestätigen"
L["btn:cancel"] = "Abbrechen"

L["msg:nothingToDo"] = "AzerothPrime: Nichts zu verschieben."
L["msg:done"] = "AzerothPrime: Fertig. %d Gegenstand/Gegenstände verschoben."
L["msg:noVacancy"] = "AzerothPrime: Die Kriegsmeutenbank ist voll."
L["msg:blockedCombat"] = "AzerothPrime: Abgebrochen — Ihr seid im Kampf."
L["msg:blockedBankClosed"] = "AzerothPrime: Abgebrochen — die Bank wurde geschlossen."
L["msg:blockedCursor"] = "AzerothPrime: Abgebrochen — Ihr haltet etwas am Cursor."
L["msg:blockedLocked"] = "AzerothPrime: Abgebrochen — ein Gegenstand ist gesperrt."
L["msg:moveFailed"] = "AzerothPrime: Abgebrochen — eine Bewegung wurde nicht abgeschlossen."
L["msg:openProfession"] = "AzerothPrime: Öffnet einmal Euer %s-Fenster, damit AzerothPrime erfassen kann, welche Rezepte Ihr kennt."

-- Curation window
L["curation:title"] = "Gegenstandsverwaltung"
L["curation:open"] = "Gegenstände verwalten"
L["curation:search"] = "Suchen"
L["curation:filterDestination"] = "Beliebiges Ziel"
L["curation:filterClass"] = "Beliebige Gegenstandsart"
L["curation:source"] = "Quelle: %s"
L["curation:sourceBuiltIn"] = "Dieser Charakter"
L["curation:count"] = "%d Gegenstand/Gegenstände"
L["curation:unscanned"] = "Nie nach Rezepten durchsucht: %s. Bis dahin gilt jedes Rezept ihrer Berufe als benötigt und wird verstaut."
L["curation:heldBy"] = "Im Besitz von"
L["curation:overrideTooltip"] = "Dieses Ziel habt Ihr selbst gewählt. Setzt es zurück, um wieder den Regeln zu folgen."

-- Destinations
L["dest:warband"] = "Kriegsmeutenbank"
L["dest:private"] = "Eigene Bank"
L["dest:privateOwned"] = "Eigene Bank (%s)"
L["dest:ignore"] = "Unangetastet lassen"

-- Private destination
L["preview:toPrivate"] = "→ Eigene Bank"
L["preview:reclaim"] = "Kriegsmeutenbank → Eigene Bank"
L["msg:noVacancyPrivate"] = "AzerothPrime: Eure Bank ist voll."
L["curation:privateTooltip"] = "Wird in der eigenen Bank eines Charakters aufbewahrt statt im gemeinsamen Lager. Ohne festgelegten Besitzer beansprucht es der erste Charakter, der eine Bank besucht."

-- Target quantity
L["curation:targetSuffix"] = "behalte %d"
L["target:title"] = "Zielmenge"
L["target:prompt"] = "Wie viele %s soll jeder Besitzer behalten?"

-- Row menu
L["menu:resetToDefault"] = "Auf Standard zurücksetzen"
L["menu:owners"] = "Besitzer"
L["menu:target"] = "Zielmenge"
L["menu:targetNone"] = "Kein Limit"
L["menu:targetOther"] = "Andere…"

L["panel:batchSell"] = "Stapelverkauf"
L["panel:sellManifest"] = "Verkaufsliste"
L["panel:blacklist"] = "Sperrliste"
L["panel:whitelist"] = "Erlaubnisliste"

L["ui:ruleWindowTitle"] = "Stapelverkauf-Regeln"
L["ui:ruleWindowNothingToConfigure"] = "Hier gibt es nichts einzustellen."
L["ui:ruleWindowDisclaimer"] =
"Im Kampf und in Instanzen verweigert das Spiel manchmal die Details eines Gegenstands. AzerothPrime behält solche Gegenstände, statt zu raten, daher können ein paar in der Liste fehlen -- das ist normal. Ein Urteil, das aus einem anderen Grund falsch aussieht, ist es wert, gemeldet zu werden."
L["ui:selectedCount"] = "Ausgewählt: %d"
L["ui:reagentsNoProfession"] =
"Noch kein Charakter auf diesem Konto hat einen Beruf, daher behält diese Regel nichts. Meldet Euch mit einem Charakter an, der einen hat, und diese Einstellungen kehren zurück."

L["btn:sellAll"] = "Alles verkaufen"
L["btn:refresh"] = "Aktualisieren"
L["btn:rules"] = "Regeln"

L["menu:temporaryExclude"] = "Vorübergehend ausschließen"
L["menu:blacklisted"] = "Sperrliste"
L["menu:whitelisted"] = "Erlaubnisliste"
L["menu:noStatus"] = "Keine"
L["menu:reportVerdict"] = "Dieses Urteil melden"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "Reagenzien dieses Rezepts markieren"

L["status:noItemsToSell"] = "Keine Gegenstände zum Verkaufen"
L["status:itemsTotal"] = "%d Gegenstände  |  Gesamt: %s"

L["ui:manifestHint"] = "Etwas erwartet, das nicht aufgeführt ist? Bewegt die Maus in Euren Taschen darüber, um den Grund zu sehen."

-- Merchant row
L["tooltip:charOverride"] =
"Die Einstellung dieses Charakters hat Vorrang vor der Kriegsmeuten-Liste – dieser Gegenstand wird verkauft."

L["section:general"] = "Allgemein"
L["section:lists"] = "Listen"
L["section:everyItem"] = "Jeder Gegenstand"
L["section:byItemType"] = "Nach Gegenstandstyp"

L["settings:openRuleWindow"] = "Regeln anzeigen"
L["settings:openRuleWindowTooltip"] =
"Erklärt, worauf jede Regel achtet und warum ein Gegenstand behalten oder verkauft wurde"
L["settings:sellJunk"] = "Schrott verkaufen"
L["settings:sellJunkTooltip"] = "Alle Gegenstände schlechter Qualität (grau) automatisch beim Besuch eines Händlers verkaufen"
L["settings:limitBatch"] = "Stapel auf 12 begrenzen"
L["settings:limitBatchTooltip"] = "Pro Klick höchstens 12 Gegenstände verkaufen, um Server-Drosselung zu vermeiden"
L["settings:keepUsedReagents"] = "Reagenzien für eigene Berufe behalten"
L["settings:keepUsedReagentsTooltip"] =
"Handwerksreagenzien behalten, die ein Beruf auf diesem Konto verwenden kann. Ein seelengebundenes Exemplar erreicht keinen Twink, dort behalten es nur die Berufe dieses Charakters"
L["settings:reagentsExpansions"] = "Welche Reagenzien behalten werden"
L["settings:reagentsExpansionsTooltip"] =
"Von welchen Erweiterungen die Regel darüber Reagenzien behält. Standardmäßig ist nur diese Erweiterung gesetzt, ältere Reagenzien werden also zum Verkauf angeboten -- außer denen, die ein von Euch markiertes Rezept noch braucht: die werden behalten, ganz gleich was Ihr hier anhakt"
L["settings:margin"] = "Gegenstandsstufen-Toleranz"
L["settings:marginTooltip"] =
"Wie weit unter dem Platz ein Teil Eurer eigenen Qualität liegen darf, bevor es verkauft wird. Bei 0 reicht es, wenn es mit dem Platz gleichzieht"
L["settings:qualityMargin"] = "Qualitätstoleranz"
L["settings:qualityMarginTooltip"] =
"Wie viele Gegenstandsstufen eine Qualitätsstufe wert ist. Bei 10 muss Ausrüstung eine Stufe unter Eurer angelegten 10 Gegenstandsstufen auf sie aufholen, um behalten zu werden, und eine Stufe darüber überlebt 10 darunter. Bei 0 zählt Qualität nicht mehr und allein die Gegenstandsstufe entscheidet. Bei Immer wird jede höhere Qualität behalten, ungeachtet ihrer Gegenstandsstufe, und keine Gegenstandsstufe rettet eine niedrigere"
L["settings:qualityMarginAlways"] = "Immer"
L["settings:keepForDisenchant"] = "Ausrüstung nach Erweiterung der Materialien behalten"
L["settings:keepForDisenchantTooltip"] =
"Behaltet Ausrüstung, die ein Verzauberer entzaubern könnte, nach der Erweiterung der Materialien, die sie einbringen würde, statt nach dem Alter der Ausrüstung selbst -- Ausrüstung aus einer abgeschlossenen Erweiterung liefert die Materialien dieser Erweiterung. Euer eigener Verzauberer behält immer, was nur er erreichen kann, bei jeder Einstellung, aber diese entscheidet weiterhin, ob das auch ältere Materialien einschließt"
L["settings:spareBindOnAccount"] = "Kontogebundene Ausrüstung schonen"
L["settings:spareBindOnAccountTooltip"] =
"Von welchen Erweiterungen kontogebundene Ausrüstung behalten wird, solange sie noch an einen anderen Charakter weitergegeben werden kann"
L["settings:spareBindOnEquip"] = "Beim Anlegen gebundene Ausrüstung schonen"
L["settings:spareBindOnEquipTooltip"] =
"Von welchen Erweiterungen beim Anlegen bindende Ausrüstung behalten wird, solange sie noch einen anderen Charakter oder das Auktionshaus erreichen kann"
L["settings:keepUncollectedCosmetic"] = "Nicht gesammelte Erscheinungsbilder behalten"
L["settings:keepUncollectedCosmeticTooltip"] =
"Behält jeden Gegenstand, dessen Erscheinungsbild Ihr noch nicht gesammelt habt. Ein gewöhnliches Teil wird beim Verkauf trotzdem gesammelt, ein kosmetischer Gegenstand gibt sein Aussehen aber erst beim Benutzen -- verkauft, ist das Erscheinungsbild endgültig fort"
L["settings:sellRelics"] = "Classic-Relikte verkaufen"
L["settings:sellRelicsTooltip"] =
"Verkauft Götzen, Buchbände, Totems und Siegel -- den Reliktplatz, den Cataclysm entfernt hat. Nicht die Artefaktrelikte aus Legion, die Edelsteine sind und nur die Unterklassennummer teilen"
L["settings:gemsExpansions"] = "Welche Edelsteine behalten werden"
L["settings:gemsExpansionsTooltip"] =
"Von welchen Erweiterungen Ihr Edelsteine behaltet. Was nicht angehakt ist, fällt auf die beiden Fragen darunter durch"
L["settings:gemsRecipesNow"] = "Aktuelle Edelsteine für Rezepte behalten"
L["settings:gemsRecipesNowTooltip"] =
"Behält einen Edelstein der aktuellen Erweiterung, den irgendein Berufsrezept als Reagenz nutzt, wem der Beruf auch gehört. Gefragt wird der Rezeptkatalog, und ein Stein, der nicht darin steht, gilt als einer, den kein Rezept braucht"
L["settings:gemsRecipesOld"] = "Ältere Edelsteine für Rezepte behalten"
L["settings:gemsRecipesOldTooltip"] =
"Dieselbe Frage für Edelsteine vergangener Erweiterungen. Was Eure eigenen Berufe brauchen, wird ohnehin anderswo behalten, also gilt diese Spalte den Rezepten aller anderen"
L["settings:keepArtifactRelics"] = "Artefaktrelikte behalten"
L["settings:keepArtifactRelicsTooltip"] =
"Behält die Relikte, die in Legions Artefaktwaffen gesockelt wurden. Seit Legion nutzt sie nichts mehr, also lohnt das Abschalten, sofern Ihr sie nicht sammelt"
L["settings:enhancementsExpansions"] = "Welche Gegenstandsverbesserungen behalten werden"
L["settings:enhancementsExpansionsTooltip"] =
"Von welchen Erweiterungen Ihr Gegenstandsverbesserungen behaltet. Eine neue Erweiterung begrenzt die Ausrüstung, auf die eine Verbesserung passt, also hakt die Erweiterung an, deren Ausrüstung Ihr tatsächlich tragt"
L["settings:keepLearnable"] = "Erlernbare Rezepte behalten"
L["settings:keepLearnableTooltip"] =
"Behält ein Rezept, das dieser Charakter noch nicht gelernt hat"
L["settings:keepTradeableRecipes"] = "Handelbare Rezepte behalten"
L["settings:keepTradeableRecipesTooltip"] =
"Behält ein noch ungebundenes Rezept, damit es einen Twink oder das Auktionshaus erreicht, selbst wenn dieser Charakter es längst gelernt hat"
L["settings:sellCollectedMounts"] = "Gesammelte Reittiere verkaufen"
L["settings:sellCollectedMountsTooltip"] =
"Verkauft ein Reittier, das Ihr bereits besitzt, sobald das Exemplar seelengebunden ist. Ein ungebundenes wird ungeachtet dieser Einstellung behalten, weil es noch jemanden erreichen kann"
L["settings:sellCollectedToys"] = "Gesammeltes Spielzeug verkaufen"
L["settings:sellCollectedToysTooltip"] =
"Verkauft ein Spielzeug, das bereits in Eurer Sammlung ist, sobald das Exemplar in Euren Taschen gebunden ist. Ein ungebundenes wird ungeachtet Eurer Sammlung behalten, weil es noch jemanden erreichen kann"
L["settings:sellCollectedPets"] = "Gesammelte Haustiere verkaufen"
L["settings:sellCollectedPetsTooltip"] =
"Verkauft ein Kampfhaustier, das Ihr bereits habt. Eines, das Ihr nie gesammelt habt, verkauft diese Regel in keiner Stellung"
L["settings:sellHoliday"] = "Feiertagsgegenstände verkaufen"
L["settings:sellHolidayTooltip"] =
"Verkauft die Marken, Kostüme und Kleinigkeiten, die Weltereignisse in Euren Taschen zurücklassen"
L["settings:sellMountEquipment"] = "Reittierausrüstung verkaufen"
L["settings:sellMountEquipmentTooltip"] =
"Verkauft Reittierausrüstung. Es wirkt immer nur ein Stück kontoweit, die Ersatzstücke in Euren Taschen tun also nichts"
L["settings:sellCollectedDecor"] = "Gesammelte Deko verkaufen"
L["settings:sellCollectedDecorTooltip"] =
"Verkauft Wohnungsdeko, die Euer Katalog bereits führt. Ein Stück, das er nie gesehen hat, wird behalten, und ebenso eines, für das der Katalog nicht gelesen werden konnte"
L["settings:keepTradeableDyes"] = "Handelbare Farben behalten"
L["settings:keepTradeableDyesTooltip"] =
"Eine Farbe wird beim Auftragen verbraucht und nie gelernt, es gibt also keine Sammlung zu befragen. Gefragt wird stattdessen, ob dieses Exemplar noch jemanden erreicht: ungebunden wird behalten, gebunden verkauft"
L["settings:spareProfessions"] = "Diese Berufe schonen"
L["settings:spareProfessionsTooltip"] =
"Behält ein Handelsgut, wenn es ein hier angehakter Beruf als Reagenz verwenden könnte -- für einen Zweitcharakter, der ihn noch nicht gelernt hat, oder für das Auktionshaus. Die eigenen Berufe dieses Accounts deckt bereits Reagenzien für eigene Berufe behalten ab"

L["spare:none"] = "Keine"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "Alle Erweiterungen"
L["expansion:current"] = "Aktuelle Erweiterung"

L["profession:FirstAid"] = "Erste Hilfe"
L["profession:Blacksmithing"] = "Schmiedekunst"
L["profession:Leatherworking"] = "Lederverarbeitung"
L["profession:Alchemy"] = "Alchemie"
L["profession:Herbalism"] = "Kräuterkunde"
L["profession:Cooking"] = "Kochkunst"
L["profession:Mining"] = "Bergbau"
L["profession:Tailoring"] = "Schneiderei"
L["profession:Engineering"] = "Ingenieurskunst"
L["profession:Enchanting"] = "Verzauberkunst"
L["profession:Fishing"] = "Angeln"
L["profession:Skinning"] = "Kürschnerei"
L["profession:Jewelcrafting"] = "Juwelierskunst"
L["profession:Inscription"] = "Inschriftenkunde"
L["profession:Archaeology"] = "Archäologie"

L["sub:0"] = "Allgemein"
L["sub:1"] = "Trank"
L["sub:2"] = "Elixier"
L["sub:3"] = "Fläschchen & Phiolen"
L["sub:5"] = "Essen & Trinken"
L["sub:7"] = "Verband"
L["sub:8"] = "Sonstiges"
L["sub:9"] = "Vantusrune"

L["option:expansions"] = "Welche Erweiterungen behalten werden"
L["option:recipesNow"] = "Behalte auch die aus dieser Erweiterung, wenn ein Rezept sie braucht"
L["option:recipesOld"] = "Behalte auch ältere, wenn ein Rezept sie braucht"

-- List tabs
L["btn:removeEntry"] = "Entfernen"
L["list:warband"] = "Kriegsmeute"
L["list:character"] = "Charakter"
L["status:listEmpty"] = "Diese Liste ist leer"
L["status:listCount"] = "%d Einträge"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Stapelverkauf: wird verkauft"
L["verdict:keep"] = "Stapelverkauf: wird behalten"
L["claimed:OPEN"] = "Der Öffnen-Knopf beansprucht diesen Gegenstand"
L["claimed:DEPOSIT_WARBAND"] = "Wandert stattdessen in die Kriegsmeutenbank"
L["claimed:DEPOSIT_PRIVATE"] = "Wandert stattdessen in die eigene Bank eines Charakters"
L["reason:TEMP_EXCLUDED"] = "Für diesen Händlerbesuch ausgeschlossen"
L["reason:BLACKLISTED"] = "Auf Eurer Sperrliste"
L["reason:LOCKED"] = "Der Gegenstand ist gesperrt"
L["reason:EQUIPMENT_SET"] = "Teil eines Ausrüstungssets"
L["reason:NO_SELL_PRICE"] = "Kein Händler kauft ihn"
L["reason:REFUNDABLE"] = "Noch innerhalb der Rückerstattungsfrist"
L["reason:WHITELISTED"] = "Auf Eurer Erlaubnisliste"
L["reason:TEMP_INCLUDED"] = "Für diesen Händlerbesuch hinzugefügt"
L["reason:JUNK"] = "„Schrott verkaufen“ ist aus, Schrott bleibt unangetastet"
L["reason:JUNK_SOLD"] = "„Schrott verkaufen“ ist an, Schrott wird verkauft"
L["reason:ABOVE_EPIC"] = "Besser als episch, wird daher nie verkauft"
L["reason:BIND_ON_ACCOUNT"] = "Kontogebundene Ausrüstung wird behalten"
L["reason:DISENCHANTABLE"] = "Lohnt sich zum Entzaubern oder Weiterverkaufen"
L["reason:BAG_KEPT"] = "Taschen werden nie verkauft"
L["reason:PROFESSION_GEAR_KEPT"] = "Berufsausrüstung wird nie verkauft"
L["reason:ENHANCEMENT_EXPANSION"] = "Gegenstandsverbesserungen dieser Erweiterung werden behalten"
L["reason:CONSUMABLE_EXPANSION"] = "Verbrauchsgegenstände dieser Erweiterung werden behalten"
L["reason:CONSUMABLE_REAGENT"] = "Ein Rezept irgendwo verwendet dies als Reagenz"
L["reason:GEM_EXPANSION"] = "Edelsteine dieser Erweiterung werden behalten"
L["reason:GEM_REAGENT"] = "Ein Rezept irgendwo verwendet dies als Reagenz"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "Artefaktrelikte werden behalten"
L["reason:TRADE_GOOD_SPARED"] = "Ein Beruf, den Ihr geschont habt, will dies"
L["reason:NOT_WANTED"] = "Kein Kästchen behält dies, daher wird es verkauft"
L["reason:REAGENT_WANTED"] = "Ein Beruf, der dies verwenden kann, braucht es als Reagenz"
L["reason:NOT_EQUIPPABLE"] = "Für Eure Klasse nicht anlegbar oder nicht empfohlen"
L["reason:EQUIPPABLE"] = "Gut genug im Vergleich zu Eurer angelegten Ausrüstung"
L["reason:OUTCLASSED"] = "Eurer angelegten Ausrüstung unterlegen"
L["reason:OUTDATED_EXPAC"] = "Besser als Eure angelegte Ausrüstung der letzten Erweiterung"
L["reason:BIND_ON_EQUIP"] = "Erst beim Anlegen gebundene Ausrüstung wird behalten"
L["reason:ARMOR_RELIC"] = "Relikte kann niemand mehr anlegen, daher werden sie verkauft"
L["reason:RECIPE_LEARNABLE"] = "Noch nicht gelernt, daher wird es behalten"
L["reason:HOLIDAY_ITEM"] = "Feiertagsgegenstände werden verkauft"
L["reason:MOUNT_EQUIPMENT"] = "Reittierausrüstung wird verkauft"
L["reason:ALREADY_COLLECTED"] = "Bereits gesammelt, daher wird es verkauft"
L["reason:NOT_COLLECTED"] = "Noch nicht gesammelt, daher wird es behalten"
L["reason:STILL_TRADEABLE"] = "Noch handelbar, daher wird es behalten"
L["reason:ALREADY_LEARNED"] = "Bereits gelernt, daher wird es verkauft"
L["reason:DEFAULT"] = "Keine Regel hat ihn beansprucht, daher wird er behalten"

L["listReset:warbandBlacklist"] = "Kriegsmeuten-Sperrliste zurücksetzen"
L["listReset:warbandWhitelist"] = "Kriegsmeuten-Erlaubnisliste zurücksetzen"
L["listReset:charBlacklist"] = "Charakter-Sperrliste zurücksetzen"
L["listReset:charWhitelist"] = "Charakter-Erlaubnisliste zurücksetzen"
L["listReset:confirm"] = "Seid Ihr sicher, dass Ihr diese Liste leeren möchtet? Dies kann nicht rückgängig gemacht werden."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Kann %s gerade nicht verkaufen: %s"
L["msg:dropUnexcluded"] = "%s ist nicht mehr ausgeschlossen und wird bei diesem Händlerbesuch verkauft"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "Vorübergehend blockiert"
L["rule:tempSub"] = "Nur für diesen Händlerbesuch"
L["rule:tempBlurb"] =
"Gegenstände, die Ihr vor dem Klick auf Verkaufen aus der Verkaufsliste genommen habt. Sie bleiben für diesen Besuch in Euren Taschen und werden beim nächsten Händler wieder normal beurteilt."
L["rule:black"] = "Nie verkaufen"
L["rule:blackSub"] = "Eure Nie-verkaufen-Liste"
L["rule:blackBlurb"] =
"Alles auf Eurer Nie-verkaufen-Liste bleibt in Euren Taschen. Eine Einstellung auf diesem Charakter gewinnt gegenüber der Kriegsmeuten-Liste, egal in welche Richtung sich die beiden widersprechen."
L["rule:gates"] = "Nicht verkäuflich"
L["rule:gatesSub"] = "Der Händler nimmt diese nicht an"
L["rule:gatesBlurb"] =
"Gesperrte Gegenstände, alles in einem Ausrüstungsset, Gegenstände ohne Verkaufspreis und Käufe, die noch innerhalb ihrer Rückerstattungsfrist sind. Eure Immer-verkaufen-Liste setzt dies nicht außer Kraft, weil der Händler den Verkauf ohnehin ablehnen würde."
L["rule:white"] = "Immer verkaufen"
L["rule:whiteSub"] = "Eure Immer-verkaufen-Liste"
L["rule:whiteBlurb"] =
"Alles auf Eurer Immer-verkaufen-Liste wird verkauft, selbst wenn eine spätere Regel es behalten hätte. So verkauft Ihr das eine Handwerksreagenz, das Ihr nicht wollt."
L["rule:tempIn"] = "Für diesen Besuch hinzugefügt"
L["rule:tempInSub"] = "Nur für diesen Händlerbesuch"
L["rule:tempInBlurb"] =
"Gegenstände, die Ihr bei diesem Händler auf die Verkaufsliste gezogen habt. Sie werden bei diesem Besuch verkauft und beim nächsten wieder normal beurteilt."
L["rule:junk"] = "Schlechte Qualität"
L["rule:junkSub"] = "Standardmäßig aus"
L["rule:junkBlurb"] =
"Graue Gegenstände, unabhängig davon, um welche Art von Gegenstand es sich handelt. Standardmäßig aus, weil das meist schon ein anderes Addon übernimmt. Wenn nichts anderes es tut, schaltet es ein, und AzerothPrime räumt sie für Euch weg."
L["rule:epic"] = "Legendär und höher"
L["rule:epicSub"] = "Legendär, Artefakt, Erbstück"
L["rule:epicBlurb"] =
"Wird nie verkauft. Der Händler zeigt für diese einen Preis an und lehnt den Verkauf dann trotzdem ab, weshalb AzerothPrime sie gar nicht erst auf die Liste setzt."
L["rule:reagent"] = "Handwerksreagenzien"
L["rule:reagentSub"] = "Nutzt Eure Berufsliste"
L["rule:reagentBlurb"] =
"Behält jedes Reagenz, das ein Beruf auf diesem Konto verwenden kann, unabhängig davon, um welche Art von Gegenstand es sich handelt. Reagenzien tauchen gleichermaßen als Tränke, Edelsteine und Handelsgüter auf, daher wird dies vor dem Gegenstandstyp geprüft. Behalten wird nur diese Erweiterung, solange Ihr nichts anderes einstellt; ein älteres Reagenz wird zusätzlich behalten, wenn ein von Euch markiertes Rezept es noch braucht, ganz gleich was bei den Erweiterungen angehakt ist. Die Liste wird aus den Rezepten des Spiels selbst gelesen und enthält daher bereits die optionalen Reagenzien, die ein Rezept annimmt, sowie jede Qualitätsstufe -- Ihr müsst dafür nichts öffnen und nichts einlesen."
L["rule:cosmetic"] = "Nicht gesammelte Erscheinungsbilder"
L["rule:cosmeticSub"] = "Kosmetische Gegenstände, die Ihr noch nicht gesammelt habt"
L["rule:cosmeticBlurb"] =
"Ein kosmetischer Gegenstand, den Ihr noch nicht gesammelt habt, wird behalten. Ihn zu verkaufen sammelt sein Erscheinungsbild nicht -- es ist einfach weg --, weshalb dies die einzige Stelle in diesem Fenster ist, an der ein Fehler nicht rückgängig gemacht werden kann. Ein kosmetischer Gegenstand, den Ihr bereits gesammelt habt, wird nicht verkauft, nur weil er einer ist; er trägt einfach nichts mehr, das es zu schützen gilt, und wird weiter als die Waffe oder Rüstung beurteilt, die er ist."
L["rule:consumables"] = "Verbrauchsgegenstände"
L["rule:consumablesSub"] = "Tränke, Nahrung, Schriftrollen, Kuriositäten"
L["rule:consumablesBlurb"] =
"Legt für jede Art von Verbrauchsgegenstand fest, was behalten wird. Alles, was kein Kästchen behält, wird verkauft."
L["rule:bags"] = "Taschen"
L["rule:bagsSub"] = "Behälter jeder Art"
L["rule:bagsBlurb"] =
"Werden nie verkauft. Welche Taschen Ihr tragt, ist Eure Entscheidung, deshalb beurteilt AzerothPrime sie nicht."
L["rule:gear"] = "Waffen & Rüstung"
L["rule:gearSub"] = "Wird gegen das verglichen, was Ihr tragt"
L["rule:gearBlurb"] =
"Ein Satz Einstellungen beurteilt beides. Jede Waffe und jedes Rüstungsteil wird der Reihe nach an den folgenden Fragen gemessen, und die erste, die mit Behalten antwortet, entscheidet."
L["rule:gems"] = "Edelsteine"
L["rule:gemsSub"] = "Sockelsteine und Artefaktrelikte"
L["rule:gemsBlurb"] =
"Ein Satz Optionen für jeden Edelstein. Artefaktrelikte haben unten eine eigene Option, weil sonst nichts an der Art eines Edelsteins ändert, ob er es wert ist, behalten zu werden."
L["rule:tradeGoods"] = "Handelsgüter"
L["rule:tradeGoodsSub"] = "Handwerksmaterial nach Beruf"
L["rule:tradeGoodsBlurb"] =
"Wählt, wessen Reagenzien Ihr behalten wollt. Alles, was Ihr nicht schont, wird verkauft -- auch wenn ein Reagenz, das Eure eigenen Berufe tatsächlich benutzen, bereits von der Regel Handwerksreagenzien oben behalten wird."
L["rule:enhancements"] = "Gegenstandsverbesserungen"
L["rule:enhancementsSub"] = "Verzauberungen, Öle, Steine"
L["rule:enhancementsBlurb"] =
"Eine neue Erweiterung begrenzt die Ausrüstung, auf die diese angewendet werden können, sodass ältere ihren Wert verlieren. Hakt jede Erweiterung an, deren Ausrüstung Ihr tatsächlich tragt -- auch diese hier, denn sie wird nicht mehr automatisch behalten."
L["rule:recipes"] = "Rezepte"
L["rule:recipesSub"] = "Muster, Baupläne, Formeln"
L["rule:recipesBlurb"] =
"Jedes Rezept nennt den Beruf, zu dem es gehört, und wird deshalb beurteilt, sobald es beim Händler auftaucht. Ein Rezept, das zu keinem einzelnen Beruf gehört -- ein allgemeines Muster oder ein Handbuch --, bleibt unangetastet, denn es gibt nichts, woran es gemessen werden könnte."
L["rule:misc"] = "Verschiedenes"
L["rule:miscSub"] = "Haustiere, Reittiere, Spielzeug, Feiertagsgegenstände"
L["rule:miscBlurb"] =
"Zauberreagenzien werden nicht angetastet. Unter den nicht kategorisierten Kleinigkeiten wird nur Spielzeug beurteilt: Es wird verkauft, sobald es bereits in Eurer Sammlung ist und das Exemplar in Euren Taschen gebunden ist. Graue Gegenstände werden von der Regel Schlechte Qualität weiter oben behandelt, nicht hier."
L["rule:profession"] = "Berufsausrüstung"
L["rule:professionSub"] = "Werkzeuge und Zubehör"
L["rule:professionBlurb"] =
"Wird nie verkauft. Die handelbaren sind Geld wert, und die gebundenen habt Ihr entweder für Euch selbst hergestellt oder benutzt sie gerade, sodass es keinen Fall gibt, in dem es richtig wäre, eine zu verkaufen."
L["rule:housing"] = "Wohnbereich"
L["rule:housingSub"] = "Dekoration und Farbstoffe"
L["rule:housingBlurb"] =
"Sobald eine Dekoration gesammelt ist, hat der Gegenstand selbst keinen weiteren Nutzen mehr, also kann er zum Händler gehen. Ein Farbstoff ist etwas ganz anderes: Er ist ein Einwegverbrauchsgegenstand, der beim Auftragen verbraucht wird, also gibt es nichts zu sammeln und nichts, was gelernt worden sein könnte. Er ist außerdem nie gebunden, sodass die einzige Frage, die sich lohnt, ist, ob er noch jemanden erreichen kann, der ihn will."
L["rule:none"] = "Alles andere"
L["rule:noneSub"] = "Questgegenstände, Schlüssel, Glyphen, Marken"
L["rule:noneBlurb"] =
"Gegenstandsarten, die AzerothPrime überhaupt nicht beurteilt: Questgegenstände, Schlüssel, eingesperrte Haustiere, Glyphen, WoW-Marken, Zauberreagenzien, Pfeile und die anderen ausrangierten Kategorien. Sie bleiben in Euren Taschen, egal wie die Regeln oben eingestellt sind."

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "Dieser Bericht enthält den Link des Gegenstands und seine übrigen Werte, das Urteil, das BitForge dafür fällte, und die entscheidende Regel, ob Ihr diesen Gegenstand selbst auf Eure Sperrliste oder Erlaubnisliste gesetzt habt, das, was Ihr in dem Platz tragt, den er einnehmen würde, und die Einstellungen, die das Paar beurteilt haben. Ein Gegenstandslink verrät die Stufe und Spezialisierung Eures Charakters -- das ist Teil des Formats des Links selbst, und ihn zu entfernen würde die Details verlieren, die den Bericht nachvollziehbar machen. Nichts hier nennt Euren Charakter, Euren Realm, Eure Gilde oder Eure Fraktion, und nichts beschreibt einen anderen Platz."

if GetLocale() ~= "deDE" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

L["panel:batchSell"] = "Stapelverkauf"
L["panel:sellManifest"] = "Verkaufsliste"
L["panel:blacklist"] = "Sperrliste"
L["panel:whitelist"] = "Erlaubnisliste"

L["ui:ruleWindowTitle"] = "Stapelverkauf-Regeln"
L["ui:ruleWindowNothingToConfigure"] = "Hier gibt es nichts einzustellen."
L["ui:ruleWindowDisclaimer"] =
"Im Kampf und in Instanzen verweigert das Spiel manchmal die Details eines Gegenstands. BatchSell behält solche Gegenstände, statt zu raten, daher können ein paar in der Liste fehlen -- das ist normal. Ein Urteil, das aus einem anderen Grund falsch aussieht, ist es wert, gemeldet zu werden."
L["ui:selectedCount"] = "Ausgewählt: %d"

L["btn:sellAll"] = "Alles verkaufen"
L["btn:refresh"] = "Aktualisieren"
L["btn:rules"] = "Regeln"

L["menu:temporaryExclude"] = "Vorübergehend ausschließen"
L["menu:blacklisted"] = "Sperrliste"
L["menu:whitelisted"] = "Erlaubnisliste"
L["menu:noStatus"] = "Keine"
L["menu:reportVerdict"] = "Dieses Urteil melden"

L["status:noItemsToSell"] = "Keine Gegenstände zum Verkaufen"
L["status:itemsTotal"] = "%d Gegenstände  |  Gesamt: %s"

L["ui:manifestHint"] = "Etwas erwartet, das nicht aufgeführt ist? Bewege die Maus in deinen Taschen darüber, um den Grund zu sehen."

-- Merchant row
L["tooltip:charOverride"] =
"Die Einstellung dieses Charakters hat Vorrang vor der Kriegerschar-Liste – dieser Gegenstand wird verkauft."

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
L["settings:compareQuality"] = "Qualität vergleichen"
L["settings:compareQualityTooltip"] =
"Ausrüstung verkaufen, deren Qualität niedriger ist als die Eurer angelegten, unabhängig von der Gegenstandsstufe"
L["settings:compareItemLevel"] = "Gegenstandsstufe vergleichen"
L["settings:compareItemLevelTooltip"] =
"Ausrüstung anhand der Gegenstandsstufe mit der angelegten vergleichen, mithilfe der Toleranz unten. Ist dies aus, spielt die Gegenstandsstufe für die Entscheidung keine Rolle"
L["settings:ilvlMargin"] = "Gegenstandsstufen-Toleranz"
L["settings:ilvlMarginTooltip"] =
"Wie viele Gegenstandsstufen eine Qualitätsstufe wert ist. Bei 10 muss Ausrüstung eine Stufe unter Eurer angelegten sie um 10 übertreffen, um behalten zu werden, und eine Stufe darüber überlebt 10 darunter. Bei gleicher Qualität muss ein Teil den Platz schlicht übertreffen. Bei 0 zählt Qualität nicht mehr und allein die Gegenstandsstufe entscheidet"
L["settings:emphasizeQuality"] = "Qualität betonen"
L["settings:emphasizeQualityTooltip"] =
"Zählt eine Qualitätsstufe doppelt so hoch wie die Toleranz und erlaubt einem Teil gleicher Qualität, diese Toleranz unter dem Platz zu liegen. Qualität über Eurer angelegten wird billiger zu behalten, Qualität darunter teurer zu entschuldigen"
L["settings:keepForDisenchant"] = "Entzauberbare Ausrüstung behalten"
L["settings:keepForDisenchantTooltip"] =
"Ausrüstung behalten, die entzaubert werden könnte, für das Auktionshaus oder einen Twink mit dem Beruf. Verzauberer behalten ihre eigene gebundene entzauberbare Ausrüstung unabhängig von dieser Einstellung immer"
L["settings:spareBindOnAccount"] = "Kontogebundene Ausrüstung schonen"
L["settings:spareBindOnAccountTooltip"] =
"Welche ungebundene kontogebundene Ausrüstung behalten wird, damit ein Exemplar einen anderen Charakter erreicht: die dieser Erweiterung, alle oder keine"
L["settings:spareBindOnEquip"] = "Beim Anlegen gebundene Ausrüstung schonen"
L["settings:spareBindOnEquipTooltip"] =
"Welche ungebundene, beim Anlegen bindende Ausrüstung für einen anderen Charakter oder das Auktionshaus behalten wird: die dieser Erweiterung, alle oder keine"
L["settings:reagentsCurrentOnly"] = "Nur Reagenzien dieser Erweiterung"
L["settings:reagentsCurrentOnlyTooltip"] =
"Schränkt die Regel darüber auf Reagenzien der aktuellen Erweiterung ein. Ein Rezept, das ein Classic-Kraut verlangt, verlangt es heute genauso, also bleibt dies aus, sofern Ihr alte Bestände nicht horten wollt"
L["settings:keepUncollectedCosmetic"] = "Nicht gesammelte Vorlagen behalten"
L["settings:keepUncollectedCosmeticTooltip"] =
"Behält jeden Gegenstand, dessen Vorlage Ihr noch nicht gesammelt habt. Ein gewöhnliches Teil wird beim Verkauf trotzdem gesammelt, ein kosmetischer Gegenstand gibt sein Aussehen aber erst beim Benutzen -- verkauft, ist die Vorlage endgültig fort"
L["settings:sellRelics"] = "Classic-Relikte verkaufen"
L["settings:sellRelicsTooltip"] =
"Verkauft Götzen, Buchbände, Totems und Siegel -- den Reliktplatz, den Cataclysm entfernt hat. Nicht die Artefaktrelikte aus Legion, die Edelsteine sind und nur die Unterklassennummer teilen"
L["settings:gemsCurrent"] = "Edelsteine dieser Erweiterung behalten"
L["settings:gemsCurrentTooltip"] =
"Behält Edelsteine der aktuellen Erweiterung. Ältere fallen auf die beiden Fragen darunter durch"
L["settings:gemsRecipesNow"] = "Aktuelle Edelsteine für Rezepte behalten"
L["settings:gemsRecipesNowTooltip"] =
"Behält einen Edelstein der aktuellen Erweiterung, den irgendein Berufsrezept als Reagenz nutzt, wem der Beruf auch gehört. Gefragt wird der Rezeptkatalog, und ein Stein, den er nie gesehen hat, wird behalten statt geraten"
L["settings:gemsRecipesOld"] = "Ältere Edelsteine für Rezepte behalten"
L["settings:gemsRecipesOldTooltip"] =
"Dieselbe Frage für Edelsteine vergangener Erweiterungen. Was Eure eigenen Berufe brauchen, wird ohnehin anderswo behalten, also gilt diese Spalte den Rezepten aller anderen"
L["settings:keepArtifactRelics"] = "Artefaktrelikte behalten"
L["settings:keepArtifactRelicsTooltip"] =
"Behält die Relikte, die in Legions Artefaktwaffen gesockelt wurden. Seit Legion nutzt sie nichts mehr, also lohnt das Abschalten, sofern Ihr sie nicht sammelt"
L["settings:enhancementsKeepLast"] = "Verbesserungen der letzten Erweiterung behalten"
L["settings:enhancementsKeepLastTooltip"] =
"Behält Gegenstandsverbesserungen der unmittelbar vorigen Erweiterung, für einen Charakter, der deren Ausrüstung noch trägt. Nur diese eine wird angeboten -- durch die davor levelt niemand mehr"
L["settings:keepLearnable"] = "Erlernbare Rezepte behalten"
L["settings:keepLearnableTooltip"] =
"Behält ein Rezept, das dieser Charakter noch nicht gelernt hat"
L["settings:keepTradeableRecipes"] = "Handelbare Rezepte behalten"
L["settings:keepTradeableRecipesTooltip"] =
"Behält ein noch ungebundenes Rezept, damit es einen Twink oder das Auktionshaus erreicht, selbst wenn dieser Charakter es längst gelernt hat"
L["settings:sellCollectedMounts"] = "Gesammelte Reittiere verkaufen"
L["settings:sellCollectedMountsTooltip"] =
"Verkauft ein Reittier, das Ihr bereits besitzt, sobald das Exemplar seelengebunden ist. Ein ungebundenes wird ungeachtet dieser Einstellung behalten, weil es noch jemanden erreichen kann"
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

L["spare:current"] = "Aktuelle Erweiterung"
L["spare:all"] = "Alle"
L["spare:none"] = "Keine"

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

L["option:current"] = "Alles aus dieser Erweiterung behalten"
L["option:lastExpansion"] = "Und aus der letzten, solange du dort noch levelst"
L["option:recipesNow"] = "Aus dieser Erweiterung behalten, außer kein Rezept braucht es"
L["option:recipesOld"] = "Ältere behalten, außer kein Rezept braucht sie"

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
L["reason:JUNK"] = "„Schrott verkaufen“ ist aus, Schrott bleibt unangetastet"
L["reason:JUNK_SOLD"] = "„Schrott verkaufen“ ist an, Schrott wird verkauft"
L["reason:ABOVE_EPIC"] = "Besser als episch, wird daher nie verkauft"
L["reason:BIND_ON_ACCOUNT"] = "Kontogebundene Ausrüstung wird behalten"
L["reason:DISENCHANTABLE"] = "Lohnt sich zum Entzaubern oder Weiterverkaufen"
L["reason:BAG_KEPT"] = "Taschen werden nie verkauft"
L["reason:PROFESSION_GEAR_KEPT"] = "Berufszubehör wird nie verkauft"
L["reason:ENHANCEMENT_CURRENT"] = "Verzauberungen für diese Erweiterung werden behalten"
L["reason:ENHANCEMENT_LAST_EXPANSION"] = "Verzauberungen der letzten Erweiterung werden behalten"
L["reason:ENHANCEMENT_OUTDATED"] = "Verzauberungen für frühere Erweiterungen werden verkauft"
L["reason:CONSUMABLE_CURRENT"] = "Verbrauchsgegenstände dieser Erweiterung werden behalten"
L["reason:CONSUMABLE_LAST_EXPANSION"] = "Verbrauchsgegenstände der letzten Erweiterung werden behalten"
L["reason:CONSUMABLE_REAGENT"] = "Ein Rezept irgendwo verwendet dies als Reagenz"
L["reason:GEM_CURRENT"] = "Edelsteine dieser Erweiterung werden behalten"
L["reason:GEM_REAGENT"] = "Ein Rezept irgendwo verwendet dies als Reagenz"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "Artefaktreliquien werden behalten"
L["reason:TRADE_GOOD_SPARED"] = "Ein Beruf, den du geschont hast, will dies"
L["reason:NOT_WANTED"] = "Kein Kästchen behält dies, daher wird es verkauft"
L["reason:REAGENT_WANTED"] = "Ein Beruf, der dies verwenden kann, braucht es als Reagenz"
L["reason:NOT_EQUIPPABLE"] = "Für deine Klasse nicht anlegbar oder nicht empfohlen"
L["reason:EQUIPPABLE"] = "Gut genug im Vergleich zu deiner angelegten Ausrüstung"
L["reason:OUTCLASSED"] = "Deiner angelegten Ausrüstung unterlegen"
L["reason:OUTDATED_EXPAC"] = "Besser als deine angelegte Ausrüstung der letzten Erweiterung"
L["reason:BIND_ON_EQUIP"] = "Erst beim Anlegen gebundene Ausrüstung wird behalten"
L["reason:ARMOR_RELIC"] = "Reliquien kann niemand mehr anlegen, daher werden sie verkauft"
L["reason:RECIPE_LEARNABLE"] = "Noch nicht gelernt, daher wird es behalten"
L["reason:HOLIDAY_ITEM"] = "Feiertagsgegenstände werden verkauft"
L["reason:MOUNT_EQUIPMENT"] = "Reittierausrüstung wird verkauft"
L["reason:ALREADY_COLLECTED"] = "Bereits gesammelt, daher wird es verkauft"
L["reason:NOT_COLLECTED"] = "Noch nicht gesammelt, daher wird es behalten"
L["reason:STILL_TRADEABLE"] = "Noch handelbar, daher wird es behalten"
L["reason:ALREADY_LEARNED"] = "Bereits gelernt, daher wird es verkauft"
L["reason:DEFAULT"] = "Keine Regel hat ihn beansprucht, daher wird er behalten"

L["listReset:warbandBlacklist"] = "Kriegerschar-Sperrliste zurücksetzen"
L["listReset:warbandWhitelist"] = "Kriegerschar-Erlaubnisliste zurücksetzen"
L["listReset:charBlacklist"] = "Charakter-Sperrliste zurücksetzen"
L["listReset:charWhitelist"] = "Charakter-Erlaubnisliste zurücksetzen"
L["listReset:confirm"] = "Bist du sicher, dass du diese Liste leeren möchtest? Dies kann nicht rückgängig gemacht werden."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Kann %s gerade nicht verkaufen: %s"
L["msg:dropUnexcluded"] = "%s ist nicht mehr ausgeschlossen und wird bei diesem Händlerbesuch verkauft"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "Vorübergehend blockiert"
L["rule:tempSub"] = "Nur für diesen Händlerbesuch"
L["rule:tempBlurb"] =
"Gegenstände, die du vor dem Klick auf Verkaufen aus der Verkaufsliste genommen hast. Sie bleiben für diesen Besuch in deinen Taschen und werden beim nächsten Händler wieder normal beurteilt."
L["rule:black"] = "Nie verkaufen"
L["rule:blackSub"] = "Deine Nie-verkaufen-Liste"
L["rule:blackBlurb"] =
"Alles auf deiner Nie-verkaufen-Liste bleibt in deinen Taschen. Eine Einstellung auf diesem Charakter gewinnt gegenüber der Kriegerschar-Liste, egal in welche Richtung sich die beiden widersprechen."
L["rule:gates"] = "Nicht verkäuflich"
L["rule:gatesSub"] = "Der Händler nimmt diese nicht an"
L["rule:gatesBlurb"] =
"Gesperrte Gegenstände, alles in einem Ausrüstungsset, Gegenstände ohne Verkaufspreis und Käufe, die noch innerhalb ihrer Rückerstattungsfrist sind. Deine Immer-verkaufen-Liste setzt dies nicht außer Kraft, weil der Händler den Verkauf ohnehin ablehnen würde."
L["rule:white"] = "Immer verkaufen"
L["rule:whiteSub"] = "Deine Immer-verkaufen-Liste"
L["rule:whiteBlurb"] =
"Alles auf deiner Immer-verkaufen-Liste wird verkauft, selbst wenn eine spätere Regel es behalten hätte. So verkaufst du das eine Handwerksreagenz, das du nicht willst."
L["rule:tempIn"] = "Für diesen Besuch hinzugefügt"
L["rule:tempInSub"] = "Nur für diesen Händlerbesuch"
L["rule:tempInBlurb"] =
"Gegenstände, die du bei diesem Händler auf die Verkaufsliste gezogen hast. Sie werden bei diesem Besuch verkauft und beim nächsten wieder normal beurteilt."
L["rule:junk"] = "Schlechte Qualität"
L["rule:junkSub"] = "Standardmäßig aus"
L["rule:junkBlurb"] =
"Graue Gegenstände, unabhängig davon, um welche Art von Gegenstand es sich handelt. Standardmäßig aus, weil das meist schon ein anderes Addon übernimmt. Wenn nichts anderes es tut, schalte es ein, und BatchSell räumt sie für dich weg."
L["rule:epic"] = "Legendär und höher"
L["rule:epicSub"] = "Legendär, Artefakt, Erbstück"
L["rule:epicBlurb"] =
"Wird nie verkauft. Der Händler zeigt für diese einen Preis an und lehnt den Verkauf dann trotzdem ab, weshalb BatchSell sie gar nicht erst auf die Liste setzt."
L["rule:reagent"] = "Handwerksreagenzien"
L["rule:reagentSub"] = "Nutzt deine Berufsliste"
L["rule:reagentBlurb"] =
"Behält jedes Reagenz, das ein Beruf auf diesem Konto verwenden kann, unabhängig davon, um welche Art von Gegenstand es sich handelt. Reagenzien tauchen gleichermaßen als Tränke, Edelsteine und Handelsgüter auf, daher wird dies vor dem Gegenstandstyp geprüft. Die Liste wird aus den Rezepten des Spiels selbst gelesen und enthält daher bereits die optionalen Reagenzien, die ein Rezept annimmt, sowie jede Qualitätsstufe -- du musst dafür nichts öffnen und nichts einlesen."
L["rule:cosmetic"] = "Nicht gesammelte Erscheinungsbilder"
L["rule:cosmeticSub"] = "Kosmetische Gegenstände, die du noch nicht gesammelt hast"
L["rule:cosmeticBlurb"] =
"Ein kosmetischer Gegenstand, den du noch nicht gesammelt hast, wird behalten. Ihn zu verkaufen sammelt sein Erscheinungsbild nicht -- es ist einfach weg --, weshalb dies die einzige Stelle in diesem Fenster ist, an der ein Fehler nicht rückgängig gemacht werden kann. Ein kosmetischer Gegenstand, den du bereits gesammelt hast, wird nicht verkauft, nur weil er einer ist; er trägt einfach nichts mehr, das es zu schützen gilt, und wird weiter als die Waffe oder Rüstung beurteilt, die er ist."
L["rule:consumables"] = "Verbrauchsgegenstände"
L["rule:consumablesSub"] = "Tränke, Nahrung, Schriftrollen, Kuriositäten"
L["rule:consumablesBlurb"] =
"Lege für jede Art von Verbrauchsgegenstand fest, was behalten wird. Alles, was kein Kästchen behält, wird verkauft. Tränke, Elixiere, Fläschchen sowie Essen & Trinken erhalten noch eine weitere Option -- auch die der letzten Erweiterung --, die nur gilt, solange du die dieser Erweiterung behältst."
L["rule:bags"] = "Taschen"
L["rule:bagsSub"] = "Behälter jeder Art"
L["rule:bagsBlurb"] =
"Werden nie verkauft. Welche Taschen du trägst, ist deine Entscheidung, deshalb beurteilt BatchSell sie nicht."
L["rule:gear"] = "Waffen & Rüstung"
L["rule:gearSub"] = "Wird gegen das verglichen, was du trägst"
L["rule:gearBlurb"] =
"Ein Satz Einstellungen beurteilt beides. Jede Waffe und jedes Rüstungsteil wird der Reihe nach an den folgenden Fragen gemessen, und die erste, die mit Behalten antwortet, entscheidet."
L["rule:gems"] = "Edelsteine"
L["rule:gemsSub"] = "Sockelsteine und Artefaktreliquien"
L["rule:gemsBlurb"] =
"Ein Satz Optionen für jeden Edelstein. Artefaktreliquien haben unten eine eigene Option, weil sonst nichts an der Art eines Edelsteins ändert, ob er es wert ist, behalten zu werden."
L["rule:tradeGoods"] = "Handelsgüter"
L["rule:tradeGoodsSub"] = "Handwerksmaterial nach Beruf"
L["rule:tradeGoodsBlurb"] =
"Wähle, wessen Reagenzien du behalten willst. Alles, was du nicht schonst, wird verkauft -- auch wenn ein Reagenz, das deine eigenen Berufe tatsächlich benutzen, bereits von der Regel Handwerksreagenzien oben behalten wird."
L["rule:enhancements"] = "Gegenstandsverbesserungen"
L["rule:enhancementsSub"] = "Verzauberungen, Öle, Steine"
L["rule:enhancementsBlurb"] =
"Eine neue Erweiterung begrenzt die Ausrüstung, auf die diese angewendet werden können, sodass ältere ihren Wert verlieren. Die dieser Erweiterung werden behalten, und die der letzten Erweiterung ebenfalls, wenn du das möchtest."
L["rule:recipes"] = "Rezepte"
L["rule:recipesSub"] = "Muster, Baupläne, Formeln"
L["rule:recipesBlurb"] =
"Jedes Rezept nennt den Beruf, zu dem es gehört, und wird deshalb beurteilt, sobald es beim Händler auftaucht. Ein Rezept, das zu keinem einzelnen Beruf gehört -- eine allgemeine Vorlage oder ein Handbuch --, bleibt unangetastet, denn es gibt nichts, woran es gemessen werden könnte."
L["rule:misc"] = "Verschiedenes"
L["rule:miscSub"] = "Begleiter, Reittiere, Feiertagsgegenstände"
L["rule:miscBlurb"] =
"Zauberreagenzien und nicht kategorisierte Kleinigkeiten werden nicht angetastet. Graue Gegenstände werden von der Regel Schlechte Qualität weiter oben behandelt, nicht hier."
L["rule:profession"] = "Berufsausrüstung"
L["rule:professionSub"] = "Werkzeuge und Zubehör"
L["rule:professionBlurb"] =
"Wird nie verkauft. Die handelbaren sind Geld wert, und die gebundenen hast du entweder für dich selbst hergestellt oder benutzt sie gerade, sodass es keinen Fall gibt, in dem es richtig wäre, eine zu verkaufen."
L["rule:housing"] = "Wohnbereich"
L["rule:housingSub"] = "Dekoration und Farbstoffe"
L["rule:housingBlurb"] =
"Sobald eine Dekoration gesammelt ist, hat der Gegenstand selbst keinen weiteren Nutzen mehr, also kann er zum Händler gehen. Ein Farbstoff ist etwas ganz anderes: Er ist ein Einwegverbrauchsgegenstand, der beim Auftragen verbraucht wird, also gibt es nichts zu sammeln und nichts, was gelernt worden sein könnte. Er ist außerdem nie gebunden, sodass die einzige Frage, die sich lohnt, ist, ob er noch jemanden erreichen kann, der ihn will."
L["rule:none"] = "Alles andere"
L["rule:noneSub"] = "Questgegenstände, Schlüssel, Glyphen, Marken"
L["rule:noneBlurb"] =
"Gegenstandsarten, die BatchSell überhaupt nicht beurteilt: Questgegenstände, Schlüssel, eingesperrte Begleiter, Glyphen, WoW-Marken, Zauberreagenzien, Pfeile und die anderen ausrangierten Kategorien. Sie bleiben in deinen Taschen, egal wie die Regeln oben eingestellt sind."

-- The report window's footnote. What BatchSell discloses is not what Openables
-- discloses, so each module states its own.
L["report:blurb"] = "Dieser Bericht enthält den Link des Gegenstands, das, was du in dem Platz trägst, den er einnehmen würde, und die Einstellungen, die das Paar beurteilt haben. Ein Gegenstandslink verrät die Stufe und Spezialisierung deines Charakters -- das ist Teil des Formats des Links selbst, und ihn zu entfernen würde die Details verlieren, die den Bericht nachvollziehbar machen. Nichts hier nennt deinen Charakter, deinen Realm, deine Gilde oder deine Fraktion, und nichts beschreibt einen anderen Platz."

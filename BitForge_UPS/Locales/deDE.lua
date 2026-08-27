if GetLocale() ~= "deDE" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Undermine Parcel Service"
L["settings:enabled"] = "UPS aktivieren"
L["settings:enabledTooltip"] = "Handwerksreagenzien bei einem Bankbesuch in der Kriegsmeutenbank verstauen"
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

L["msg:nothingToDo"] = "UPS: Nichts zu verschieben."
L["msg:done"] = "UPS: Fertig. %d Gegenstand/Gegenstände verschoben."
L["msg:noVacancy"] = "UPS: Die Kriegsmeutenbank ist voll."
L["msg:blockedCombat"] = "UPS: Abgebrochen — Ihr seid im Kampf."
L["msg:blockedBankClosed"] = "UPS: Abgebrochen — die Bank wurde geschlossen."
L["msg:blockedCursor"] = "UPS: Abgebrochen — Ihr haltet etwas am Cursor."
L["msg:blockedLocked"] = "UPS: Abgebrochen — ein Gegenstand ist gesperrt."
L["msg:moveFailed"] = "UPS: Abgebrochen — eine Bewegung wurde nicht abgeschlossen."
L["msg:openProfession"] = "UPS: Öffnet einmal Euer %s-Fenster, damit UPS erfassen kann, welche Rezepte Ihr kennt."

-- Curation window
L["curation:title"] = "UPS — Gegenstandsverwaltung"
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
L["msg:noVacancyPrivate"] = "UPS: Eure Bank ist voll."
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

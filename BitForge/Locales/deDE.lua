if GetLocale() ~= "deDE" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Linksklick für Optionen"
L["minimap:hintDrag"] = "Zum Verschieben ziehen"
L["minimap:compartmentTooltip"] = "BitForge-Menü öffnen"

-- Schema upgrade
L["msg:schemaResetBody"] = "Die gespeicherten Daten für %s stammen aus einer älteren Version und können nicht übernommen werden. Sie werden gelöscht und neu aufgebaut. Dies geschieht einmalig."
L["btn:schemaResetAccept"] = "Löschen und fortfahren"

-- Slash commands
L["cmd:usage"] = "/bitforge <Modul> [Argumente], /bfdump <Modul> [Argumente] -- ein Modulname darf auf jedes eindeutige Präfix gekürzt werden"
L["cmd:unknownModule"] = "kein Modul namens %s -- /bitforge zeigt die Liste"
L["cmd:ambiguousModule"] = "%s benennt mehr als ein Modul: %s"
L["cmd:noSuchCommand"] = "%s kennt keinen Befehl %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- zeigt, was sich in diesem Update geändert hat"

-- Report window
L["report:windowTitle"] = "Einen Gegenstand melden"
L["report:windowTitleDiagnostic"] = "Diagnosebericht"
L["report:howTo"] = "Alles auswählen, dann Strg+C. Fügt es als neues Issue ein unter:"
L["report:selectAll"] = "Alles auswählen"
L["report:encoded"] = "Dieser Bericht war zu lang zum Lesen und wurde deshalb komprimiert. Fügt ihn unverändert ein -- die Tools der Entwickler werden ihn wieder entpacken."

-- The release-notes popup
L["whatsNew:windowTitle"] = "Neuerungen in BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Schließen"

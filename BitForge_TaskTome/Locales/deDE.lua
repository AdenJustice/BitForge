if GetLocale() ~= "deDE" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "Aufgabenbuch"
L["btn:lockWidget"] = "Sperren"
L["btn:unlockWidget"] = "Entsperren"

-- Config Frame
L["settings:configTitle"] = "Aufgabenbuch — Konfiguration"
L["btn:addRootTask"] = "Hauptaufgabe hinzufügen"
L["btn:addChildTask"] = "Unteraufgabe hinzufügen"
L["btn:deleteTask"] = "Aufgabe löschen"
L["btn:save"] = "Speichern"
L["settings:taskName"] = "Name"
L["settings:resetCycle"] = "Zurücksetzen"
L["settings:warbandAssigned"] = "Kriegerschar-Aufgabe"
L["settings:completionScope"] = "Abschlussbereich"
L["settings:optState"] = "Mein Opt-Status"

-- Dropdowns
L["menu:resetNone"] = "Kein"
L["menu:resetDaily"] = "Täglich"
L["menu:resetWeekly"] = "Wöchentlich"
L["menu:scopeChar"] = "Charakter"
L["menu:scopeWarband"] = "Kriegerschar"
L["menu:optFollow"] = "Standard folgen"
L["menu:optIn"] = "Immer anzeigen"
L["menu:optOut"] = "Immer ausblenden"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "'%s' und alle %d Unteraufgabe(n) löschen?"
L["msg:deleteSingle"] = "'%s' löschen?"
L["btn:confirmDelete"] = "Löschen"
L["btn:cancel"] = "Abbrechen"
L["msg:nameRequired"] = "Der Aufgabenname darf nicht leer sein."

-- Settings panel
L["settings:taskTomePanel"] = "Aufgabenbuch"
L["settings:config"] = "Konfiguration"
L["settings:openConfig"] = "Öffnen"

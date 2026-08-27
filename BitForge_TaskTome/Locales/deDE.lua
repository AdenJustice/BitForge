if GetLocale() ~= "deDE" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

L["status:widgetTitle"] = "Task Tome"

L["settings:configTitle"] = "Task Tome — Konfiguration"
L["btn:addRootTask"] = "Hauptaufgabe hinzufügen"
L["btn:addChildTask"] = "Unteraufgabe hinzufügen"
L["btn:deleteTask"] = "Aufgabe löschen"
L["btn:save"] = "Speichern"
L["settings:taskName"] = "Name"
L["settings:resetCycle"] = "Zurücksetzen"
L["settings:warbandAssigned"] = "Allen Charakteren zugewiesen"
L["settings:completionScope"] = "Abschlussbereich"
L["settings:optState"] = "Meine Zuweisung"

L["menu:resetNone"] = "Nie"
L["menu:resetDaily"] = "Täglich"
L["menu:resetWeekly"] = "Wöchentlich"
L["menu:scopeChar"] = "Charakter"
L["menu:scopeWarband"] = "Geteilt — ein Abschluss für den gesamten Account"
L["menu:optFollow"] = "Standard folgen"
L["menu:optIn"] = "Immer anzeigen"
L["menu:optOut"] = "Immer ausblenden"

L["msg:deleteConfirm"] = "'%s' und alle %d Unteraufgabe(n) löschen?"
L["msg:deleteSingle"] = "'%s' löschen?"
L["btn:confirmDelete"] = "Löschen"
L["btn:cancel"] = "Abbrechen"
L["msg:nameRequired"] = "Der Aufgabenname darf nicht leer sein."

L["settings:taskTomePanel"] = "Task Tome"
L["settings:config"] = "Konfiguration"
L["settings:openConfig"] = "Öffnen"

L["group:accountWide"] = "Accountweit"
L["tooltip:scopeMe"] = "Zeigt nur diesen Charakter. Klicken, um alle Charaktere anzuzeigen."
L["tooltip:scopeAll"] = "Zeigt alle Charaktere. Klicken, um nur diesen Charakter anzuzeigen."
L["tooltip:orientByChar"] = "Nach Charakter gruppiert. Klicken, um nach Aufgabe zu gruppieren."
L["tooltip:orientByTask"] = "Nach Aufgabe gruppiert. Klicken, um nach Charakter zu gruppieren."
L["tooltip:openConfig"] = "Öffnet das Konfigurationsfenster des Aufgabenbuchs."
L["tooltip:widgetLocked"] = "Das Fenster ist gesperrt. Klicken, um es zum Verschieben und Ändern der Größe zu entsperren."
L["tooltip:widgetUnlocked"] = "Das Fenster ist entsperrt. Klicken, um Position und Größe zu sperren."

L["settings:editingFor"] = "Bearbeiten für"
L["settings:optStateFor"] = "Zuweisung von %s"

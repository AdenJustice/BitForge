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
L["settings:warbandAssigned"] = "Allen Charakteren zugewiesen"
L["settings:completionScope"] = "Abschlussbereich"
L["settings:optState"] = "Meine Zuweisung"

-- Dropdowns
L["menu:resetNone"] = "Kein"
L["menu:resetDaily"] = "Täglich"
L["menu:resetWeekly"] = "Wöchentlich"
L["menu:scopeChar"] = "Charakter"
L["menu:scopeWarband"] = "Geteilt — ein Abschluss für den gesamten Account"
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

-- Widget modes
L["group:accountWide"] = "Accountweit"
L["tooltip:scopeMe"] = "Zeigt nur diesen Charakter. Klicken, um alle Charaktere anzuzeigen."
L["tooltip:scopeAll"] = "Zeigt alle Charaktere. Klicken, um nur diesen Charakter anzuzeigen."
L["tooltip:orientByChar"] = "Nach Charakter gruppiert. Klicken, um nach Aufgabe zu gruppieren."
L["tooltip:orientByTask"] = "Nach Aufgabe gruppiert. Klicken, um nach Charakter zu gruppieren."

-- Config
L["settings:editingFor"] = "Bearbeiten für"
L["settings:optStateFor"] = "Zuweisung von %s"

---@class BitForge.Openables
local ns = select(2, ...)
if GetLocale() ~= "deDE" then return end
local L = ns.locale

-- Settings panel
L["panel:title"] = "Öffenbares"
L["settings:enabled"] = "Öffenbares aktivieren"
L["settings:enabledTooltip"] = "Zeigt eine Schaltfläche für den nächsten benutzbaren Gegenstand in deinen Taschen"
L["settings:locked"] = "Schaltfläche sperren"
L["settings:lockedTooltip"] = "Verhindert das Verschieben der Schaltfläche"
L["settings:buttonSize"] = "Schaltflächengröße"
L["settings:buttonSizeTooltip"] = "Breite und Höhe der Schaltfläche in Pixeln"
L["settings:showCount"] = "Anzahl anzeigen"
L["settings:showCountTooltip"] = "Zeigt an, wie viele des Gegenstands du trägst"
L["settings:showCooldown"] = "Abklingzeit anzeigen"
L["settings:showCooldownTooltip"] = "Zeigt die Abklingzeit auf der Schaltfläche"
L["settings:resetPosition"] = "Position zurücksetzen"
L["settings:manageBlacklist"] = "Ausschlussliste verwalten"

-- Button tooltip
L["tooltip:use"] = "Linksklick zum Öffnen oder Benutzen."
L["tooltip:skip"] = "Rechtsklick, um für diese Sitzung zu überspringen."
L["tooltip:blacklist"] = "Strg + Rechtsklick, um dauerhaft auszuschließen."
L["tooltip:drag"] = "Alt + Ziehen zum Verschieben."

-- Blacklist
L["blacklist:windowTitle"] = "Ausgeschlossene Gegenstände"
L["blacklist:empty"] = "Es sind keine Gegenstände ausgeschlossen."
L["blacklist:remove"] = "Entfernen"
L["blacklist:clearAll"] = "Alle löschen"
L["blacklist:unknownItem"] = "Gegenstand %d"

-- Key bindings
L["binding:header"] = "BitForge Öffenbares"
L["binding:use"] = "Öffenbaren Gegenstand benutzen"

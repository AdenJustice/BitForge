if GetLocale() ~= "deDE" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

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

L["tooltip:use"] = "Linksklick zum Öffnen oder Benutzen."
L["tooltip:skip"] = "Rechtsklick, um für diese Sitzung zu überspringen."
L["tooltip:blacklist"] = "Strg + Rechtsklick, um dauerhaft auszuschließen."
L["tooltip:report"] = "Umschalt + Alt + Rechtsklick, um dieses Urteil zu melden."
L["tooltip:drag"] = "Alt + Ziehen zum Verschieben."

L["report:blurb"] = "Dieser Bericht enthält den Gegenstand, wie BitForge ihn eingestuft hat, den Text seines Tooltips und welche Berufe dieser Charakter kennt. Nichts hier nennt deinen Charakter, deinen Realm, deine Gilde oder deine Fraktion."

L["blacklist:windowTitle"] = "Ausgeschlossene Gegenstände"
L["blacklist:empty"] = "Es sind keine Gegenstände ausgeschlossen."
L["blacklist:remove"] = "Entfernen"
L["blacklist:clearAll"] = "Alle löschen"
L["blacklist:unknownItem"] = "Gegenstand %d"

L["binding:header"] = "BitForge Öffenbares"
L["binding:use"] = "Öffenbaren Gegenstand benutzen"

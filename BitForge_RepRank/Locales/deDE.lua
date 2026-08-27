if GetLocale() ~= "deDE" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "RepRank"
L["window:title"] = "RepRank"
L["section:warband"] = "Kriegsmeute"
L["section:characters"] = "Charaktere"
L["section:ungrouped"] = "Sonstiges"
L["column:faction"] = "Fraktion"
L["column:leader"] = "Spitzenreiter"
L["column:standing"] = "Stand"
L["column:progress"] = "Fortschritt"
L["filter:showUntouched"] = "Fraktionen ohne Fortschritt anzeigen"
L["filter:search"] = "Suche"
L["tooltip:pendingTitle"] = "Paragon-Belohnung wartet"
L["minimap:label"] = "RepRank"
L["standing:unknown"] = "Unbekannt"
L["standing:renown"] = "Ansehen %d"
L["alert:pendingSelf"] = "Paragon-Belohnung bereit: %s"
L["alert:pendingAlt"] = "Paragon-Belohnung bereit für %s: %s"
L["toast:pendingOne"] = "1 Paragon-Belohnung wartet"
L["toast:pendingMany"] = "%d Paragon-Belohnungen warten"
L["settings:chatAlerts"] = "Chat-Benachrichtigungen"
L["settings:chatAlertsTooltip"] = "Gibt eine Zeile im Chat aus, wenn ein Charakter eine wartende Paragon-Belohnung hat."
L["settings:toastAlerts"] = "Popup-Benachrichtigungen"
L["settings:toastAlertsTooltip"] = "Zeigt eine Popup-Benachrichtigung an, wenn ein Charakter eine wartende Paragon-Belohnung hat."

if GetLocale() ~= "frFR" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "RepRank"
L["window:title"] = "RepRank"
L["section:warband"] = "Bataillon"
L["section:characters"] = "Personnages"
L["section:ungrouped"] = "Autres"
L["column:faction"] = "Faction"
L["column:leader"] = "Meilleur"
L["column:standing"] = "Niveau"
L["column:progress"] = "Progression"
L["filter:showUntouched"] = "Afficher les factions sans progression"
L["filter:search"] = "Recherche"
L["tooltip:pendingTitle"] = "Récompense de Parangon en attente"
L["minimap:label"] = "RepRank"
L["standing:unknown"] = "Inconnu"
L["standing:renown"] = "Estime %d"
L["alert:pendingSelf"] = "Récompense de Parangon prête : %s"
L["alert:pendingAlt"] = "Récompense de Parangon prête pour %s : %s"
L["toast:pendingOne"] = "1 récompense de Parangon en attente"
L["toast:pendingMany"] = "%d récompenses de Parangon en attente"
L["settings:chatAlerts"] = "Alertes de discussion"
L["settings:chatAlertsTooltip"] = "Affiche une ligne dans la discussion quand un personnage a une récompense de Parangon en attente."
L["settings:toastAlerts"] = "Alertes pop-up"
L["settings:toastAlertsTooltip"] = "Affiche une alerte pop-up quand un personnage a une récompense de Parangon en attente."

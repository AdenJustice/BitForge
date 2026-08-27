if GetLocale() ~= "esMX" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "RepRank"
L["window:title"] = "RepRank"
L["section:warband"] = "Tropa"
L["section:characters"] = "Personajes"
L["section:ungrouped"] = "Otros"
L["column:faction"] = "Facción"
L["column:leader"] = "Líder"
L["column:standing"] = "Rango"
L["column:progress"] = "Progreso"
L["filter:showUntouched"] = "Mostrar facciones sin progreso"
L["filter:search"] = "Buscar"
L["tooltip:pendingTitle"] = "Recompensa de paragón en espera"
L["minimap:label"] = "RepRank"
L["standing:unknown"] = "Desconocido"
L["standing:renown"] = "Fama %d"
L["alert:pendingSelf"] = "Recompensa de paragón lista: %s"
L["alert:pendingAlt"] = "Recompensa de paragón lista para %s: %s"
L["toast:pendingOne"] = "1 recompensa de paragón en espera"
L["toast:pendingMany"] = "%d recompensas de paragón en espera"
L["settings:chatAlerts"] = "Alertas de chat"
L["settings:chatAlertsTooltip"] = "Muestra una línea en el chat cuando un personaje tiene una recompensa de paragón en espera."
L["settings:toastAlerts"] = "Alertas emergentes"
L["settings:toastAlertsTooltip"] = "Muestra una alerta emergente cuando un personaje tiene una recompensa de paragón en espera."

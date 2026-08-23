if GetLocale() ~= "ptBR" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Classificação de Reputação"
L["window:title"] = "Classificação de Reputação"
L["section:warband"] = "Bando de Guerra"
L["section:characters"] = "Personagens"
L["column:faction"] = "Facção"
L["column:leader"] = "Melhor"
L["column:standing"] = "Nível"
L["column:progress"] = "Progresso"
L["filter:showUntouched"] = "Mostrar Facções sem Progresso"
L["filter:search"] = "Buscar"
L["tooltip:pendingTitle"] = "Recompensa de paragão esperando"
L["minimap:label"] = "Classificação de Reputação"
L["standing:unknown"] = "Desconhecido"
L["standing:renown"] = "Fama %d"
L["alert:pendingSelf"] = "Recompensa de paragão pronta: %s"
L["alert:pendingAlt"] = "Recompensa de paragão pronta para %s: %s"
L["toast:pendingOne"] = "1 recompensa de paragão esperando"
L["toast:pendingMany"] = "%d recompensas de paragão esperando"
L["settings:chatAlerts"] = "Alertas no Chat"
L["settings:chatAlertsTooltip"] = "Exibe uma linha no chat quando um personagem tiver uma recompensa de paragão esperando."
L["settings:toastAlerts"] = "Alertas Pop-up"
L["settings:toastAlertsTooltip"] = "Exibe um alerta pop-up quando um personagem tiver uma recompensa de paragão esperando."

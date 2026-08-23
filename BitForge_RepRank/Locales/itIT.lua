if GetLocale() ~= "itIT" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Classifica reputazione"
L["window:title"] = "Classifica reputazione"
L["section:warband"] = "Banda di Guerra"
L["section:characters"] = "Personaggi"
L["column:faction"] = "Fazione"
L["column:leader"] = "Migliore"
L["column:standing"] = "Livello"
L["column:progress"] = "Progresso"
L["filter:showUntouched"] = "Mostra fazioni senza progressi"
L["filter:search"] = "Cerca"
L["tooltip:pendingTitle"] = "Ricompensa Paragon in attesa"
L["minimap:label"] = "Classifica reputazione"
L["standing:unknown"] = "Sconosciuto"
L["standing:renown"] = "Fama %d"
L["alert:pendingSelf"] = "Ricompensa Paragon pronta: %s"
L["alert:pendingAlt"] = "Ricompensa Paragon pronta per %s: %s"
L["toast:pendingOne"] = "1 ricompensa Paragon in attesa"
L["toast:pendingMany"] = "%d ricompense Paragon in attesa"
L["settings:chatAlerts"] = "Avvisi in chat"
L["settings:chatAlertsTooltip"] = "Mostra una riga in chat quando un personaggio ha una ricompensa Paragon in attesa."
L["settings:toastAlerts"] = "Avvisi popup"
L["settings:toastAlertsTooltip"] = "Mostra un avviso popup quando un personaggio ha una ricompensa Paragon in attesa."

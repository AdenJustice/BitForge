if GetLocale() ~= "itIT" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "Bilanciamento automatico"

L["settings:useCharSettings"] = "Usa impostazioni personaggio"
L["settings:useCharSettingsTooltip"] = "Sostituisci le impostazioni dell'account con valori specifici per questo personaggio"

L["settings:desiredBalance"] = "Saldo desiderato"
L["settings:desiredBalanceTooltip"] = "Saldo in oro da mantenere nelle borse"

L["settings:marginalRatio"] = "Rapporto marginale"
L["settings:marginalRatioTooltip"] = "Salta il ribilanciamento se la differenza è entro desiderato × rapporto"

L["settings:collectorCharacter"] = "Personaggio raccoglitore"
L["settings:collectorCharacterTooltip"] = "Personaggio che raccoglie l'oro in eccesso dalla Banca del gruppo di guerra"

L["settings:none"] = "Nessuno"
L["settings:always"] = "Sempre"

L["msg:deposit"] = "Depositato %s nella Banca del gruppo di guerra"
L["msg:withdraw"] = "Prelevato %s dalla Banca del gruppo di guerra"
L["msg:collect"] = "Raccolto %s dalla Banca del gruppo di guerra"
L["msg:noFunds"] = "La Banca del gruppo di guerra non ha fondi da prelevare"

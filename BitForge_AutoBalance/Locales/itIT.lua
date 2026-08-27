if GetLocale() ~= "itIT" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Usa impostazioni personaggio"
L["settings:useCharSettingsTooltip"] = "Sostituisci le impostazioni dell'account con valori specifici per questo personaggio"

L["settings:desiredBalance"] = "Saldo desiderato"
L["settings:desiredBalanceTooltip"] = "Saldo in oro obiettivo da mantenere nelle tue borse"

L["settings:marginalRatio"] = "Rapporto marginale"
L["settings:marginalRatioTooltip"] = "Salta il ribilanciamento se la differenza è entro desiderato × rapporto"

L["settings:collectorCharacter"] = "Personaggio raccoglitore"
L["settings:collectorCharacterTooltip"] = "Personaggio che raccoglie l'oro in eccesso dalla Banca della Brigata"

L["settings:none"] = "Nessuno"
L["settings:always"] = "Sempre"

L["msg:deposit"] = "Depositato %s nella Banca della Brigata"
L["msg:withdraw"] = "Prelevato %s dalla Banca della Brigata"
L["msg:collect"] = "Raccolto %s dalla Banca della Brigata"
L["msg:noFunds"] = "La Banca della Brigata non ha fondi da prelevare"

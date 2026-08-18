if GetLocale() ~= "frFR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Clic gauche pour les options"
L["minimap:hintDrag"] = "Faites glisser pour déplacer"
L["minimap:compartmentTooltip"] = "Ouvrir le menu BitForge"

-- Schema upgrade
L["msg:schemaResetBody"] = "Les données enregistrées de %s proviennent d'une version antérieure et ne peuvent pas être conservées. Elles vont être effacées et reconstruites. Cela n'arrive qu'une fois."
L["btn:schemaResetAccept"] = "Effacer et continuer"

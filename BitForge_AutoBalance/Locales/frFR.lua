if GetLocale() ~= "frFR" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Utiliser les paramètres du personnage"
L["settings:useCharSettingsTooltip"] = "Remplacer les paramètres du compte par des valeurs spécifiques à ce personnage"

L["settings:desiredBalance"] = "Solde souhaité"
L["settings:desiredBalanceTooltip"] = "Solde d'or cible à maintenir dans vos sacs"

L["settings:marginalRatio"] = "Ratio marginal"
L["settings:marginalRatioTooltip"] = "Ignorer le rééquilibrage si la différence est inférieure à souhaité × ratio"

L["settings:collectorCharacter"] = "Personnage collecteur"
L["settings:collectorCharacterTooltip"] = "Personnage qui collecte l'or excédentaire de la banque de bataillon"

L["settings:none"] = "Aucun"
L["settings:always"] = "Toujours"

L["msg:deposit"] = "Déposé %s à la banque de bataillon"
L["msg:withdraw"] = "Retiré %s de la banque de bataillon"
L["msg:collect"] = "Collecté %s de la banque de bataillon"
L["msg:noFunds"] = "La banque de bataillon n'a pas de fonds à retirer"

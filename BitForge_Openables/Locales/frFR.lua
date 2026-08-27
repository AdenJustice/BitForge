if GetLocale() ~= "frFR" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Ouvrables"
L["settings:enabled"] = "Activer Ouvrables"
L["settings:enabledTooltip"] = "Affiche un bouton pour le prochain objet à ouvrir ou utiliser dans vos sacs"
L["settings:locked"] = "Verrouiller le bouton"
L["settings:lockedTooltip"] = "Empêche le déplacement du bouton"
L["settings:buttonSize"] = "Taille du bouton"
L["settings:buttonSizeTooltip"] = "Largeur et hauteur du bouton, en pixels"
L["settings:showCount"] = "Afficher la quantité"
L["settings:showCountTooltip"] = "Affiche le nombre d'exemplaires que vous transportez"
L["settings:showCooldown"] = "Afficher le temps de recharge"
L["settings:showCooldownTooltip"] = "Affiche le temps de recharge sur le bouton"
L["settings:resetPosition"] = "Réinitialiser la position"
L["settings:manageBlacklist"] = "Gérer la liste d'exclusion"

L["tooltip:use"] = "Clic gauche pour ouvrir ou utiliser."
L["tooltip:skip"] = "Clic droit pour ignorer durant cette session."
L["tooltip:blacklist"] = "Ctrl + clic droit pour exclure définitivement."
L["tooltip:report"] = "Maj + Alt + clic droit pour signaler ce verdict."
L["tooltip:drag"] = "Alt + faites glisser pour déplacer."

L["report:blurb"] = "Ce rapport contient l'objet, la façon dont BitForge l'a classé, le texte de son infobulle, et les métiers que connaît ce personnage. Rien ici ne mentionne votre personnage, royaume, guilde ou faction."

L["blacklist:windowTitle"] = "Objets exclus"
L["blacklist:empty"] = "Aucun objet n'est exclu."
L["blacklist:remove"] = "Retirer"
L["blacklist:clearAll"] = "Tout effacer"
L["blacklist:unknownItem"] = "Objet %d"

L["binding:header"] = "BitForge Ouvrables"
L["binding:use"] = "Utiliser l'objet ouvrable"

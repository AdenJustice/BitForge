if GetLocale() ~= "frFR" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Openables"
L["settings:enabled"] = "Activer Openables"
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

L["report:blurbField"] = "Ce rapport contient chaque candidat que le dernier scan a classé pour la prochaine ouverture, dans l'ordre du classement : le nom, l'ID de l'objet, le sac et l'emplacement, la quantité empilée, la priorité et la raison de son classement, ainsi que s'il est verrouillé, en recharge ou différé. Rien ici ne mentionne votre personnage, royaume, guilde ou faction, et le texte de l'infobulle d'aucun objet n'est inclus."

L["blacklist:windowTitle"] = "Objets exclus"
L["blacklist:empty"] = "Aucun objet n'est exclu."
L["blacklist:remove"] = "Retirer"
L["blacklist:clearAll"] = "Tout effacer"
L["blacklist:unknownItem"] = "Objet %d"

L["binding:header"] = "BitForge Openables"
L["binding:use"] = "Utiliser l'objet à ouvrir"

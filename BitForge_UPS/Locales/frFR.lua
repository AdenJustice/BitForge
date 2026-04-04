if GetLocale() ~= "frFR" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Service de colis d'Undercity"
L["settings:enabled"] = "Activer UPS"
L["settings:enabledTooltip"] = "Déposer les composants d'artisanat à la banque de bataillon lors d'une visite à la banque"
L["settings:previewMoves"] = "Aperçu avant dépôt"
L["settings:previewMovesTooltip"] = "Afficher une fenêtre de confirmation listant chaque déplacement avant tout dépôt"

L["btn:deposit"] = "Déposer"
L["btn:depositing"] = "Dépôt en cours… %d"

L["preview:title"] = "Confirmer le dépôt"
L["preview:summary"] = "%d objet(s) en %d déplacement(s)"
L["preview:toWarband"] = "→ Banque de bataillon"
L["preview:dontAskAgain"] = "Ne plus demander"
L["btn:confirm"] = "Confirmer"
L["btn:cancel"] = "Annuler"

L["msg:nothingToDo"] = "UPS : Rien à déplacer."
L["msg:done"] = "UPS : Terminé. %d objet(s) déplacé(s)."
L["msg:noVacancy"] = "UPS : La banque de bataillon est pleine."
L["msg:blockedCombat"] = "UPS : Arrêté — vous êtes en combat."
L["msg:blockedBankClosed"] = "UPS : Arrêté — la banque s'est fermée."
L["msg:blockedCursor"] = "UPS : Arrêté — vous tenez quelque chose au curseur."
L["msg:blockedLocked"] = "UPS : Arrêté — un objet est verrouillé."
L["msg:moveFailed"] = "UPS : Arrêté — un déplacement n'a pas abouti."
L["msg:openProfession"] = "UPS : Ouvrez une fois votre fenêtre %s pour que UPS puisse enregistrer les recettes que vous connaissez."

-- Curation window
L["curation:title"] = "UPS — Tri des objets"
L["curation:open"] = "Trier les objets"
L["curation:search"] = "Rechercher"
L["curation:filterDestination"] = "N'importe quelle destination"
L["curation:filterClass"] = "N'importe quel type d'objet"
L["curation:source"] = "Source : %s"
L["curation:sourceBuiltIn"] = "Ce personnage"
L["curation:count"] = "%d objet(s)"
L["curation:unscanned"] = "Jamais analysés pour les recettes : %s. D'ici là, toute recette de leurs métiers est considérée comme utile et sera déposée."
L["curation:heldBy"] = "Détenu par"
L["curation:overrideTooltip"] = "Vous avez choisi cette destination. Réinitialisez-la pour suivre de nouveau les règles."

-- Destinations
L["dest:warband"] = "Banque de bataillon"
L["dest:private"] = "Votre banque"
L["dest:privateOwned"] = "Votre banque (%s)"
L["dest:ignore"] = "Ne pas toucher"

-- Private destination
L["preview:toPrivate"] = "→ Votre banque"
L["preview:reclaim"] = "Banque de bataillon → Votre banque"
L["msg:noVacancyPrivate"] = "UPS : Votre banque est pleine."
L["curation:privateTooltip"] = "Conservé dans la banque propre d'un personnage plutôt que dans le stockage partagé. Sans propriétaire désigné, le premier personnage à visiter une banque le réclame."

-- Target quantity
L["curation:targetSuffix"] = "garder %d"
L["target:title"] = "Quantité cible"
L["target:prompt"] = "Combien de %s chaque propriétaire doit-il garder ?"

-- Row menu
L["menu:resetToDefault"] = "Réinitialiser par défaut"
L["menu:owners"] = "Propriétaires"
L["menu:target"] = "Quantité cible"
L["menu:targetNone"] = "Sans limite"
L["menu:targetOther"] = "Autre…"

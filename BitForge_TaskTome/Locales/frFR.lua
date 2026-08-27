if GetLocale() ~= "frFR" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

L["status:widgetTitle"] = "Tome des tâches"

L["settings:configTitle"] = "Tome des tâches — Configuration"
L["btn:addRootTask"] = "Ajouter une tâche racine"
L["btn:addChildTask"] = "Ajouter une sous-tâche"
L["btn:deleteTask"] = "Supprimer la tâche"
L["btn:save"] = "Enregistrer"
L["settings:taskName"] = "Nom"
L["settings:resetCycle"] = "Réinitialisation"
L["settings:warbandAssigned"] = "Attribuée à tous les personnages"
L["settings:completionScope"] = "Portée d'accomplissement"
L["settings:optState"] = "Mon attribution"

L["menu:resetNone"] = "Aucune"
L["menu:resetDaily"] = "Quotidienne"
L["menu:resetWeekly"] = "Hebdomadaire"
L["menu:scopeChar"] = "Personnage"
L["menu:scopeWarband"] = "Partagé — un accomplissement pour tout le compte"
L["menu:optFollow"] = "Suivre le défaut"
L["menu:optIn"] = "Toujours afficher"
L["menu:optOut"] = "Toujours masquer"

L["msg:deleteConfirm"] = "Supprimer '%s' et %d sous-tâche(s) ?"
L["msg:deleteSingle"] = "Supprimer '%s' ?"
L["btn:confirmDelete"] = "Supprimer"
L["btn:cancel"] = "Annuler"
L["msg:nameRequired"] = "Le nom de la tâche ne peut pas être vide."

L["settings:taskTomePanel"] = "Tome des tâches"
L["settings:config"] = "Configuration"
L["settings:openConfig"] = "Ouvrir"

L["group:accountWide"] = "À l'échelle du compte"
L["tooltip:scopeMe"] = "Affiche ce personnage. Cliquez pour afficher tous les personnages."
L["tooltip:scopeAll"] = "Affiche tous les personnages. Cliquez pour afficher uniquement ce personnage."
L["tooltip:orientByChar"] = "Regroupé par personnage. Cliquez pour regrouper par tâche."
L["tooltip:orientByTask"] = "Regroupé par tâche. Cliquez pour regrouper par personnage."
L["tooltip:openConfig"] = "Ouvre la fenêtre de configuration du Tome des tâches."
L["tooltip:widgetLocked"] = "La fenêtre est verrouillée. Cliquez pour la déverrouiller afin de la déplacer et la redimensionner."
L["tooltip:widgetUnlocked"] = "La fenêtre est déverrouillée. Cliquez pour verrouiller sa position et sa taille."

L["settings:editingFor"] = "Modification pour"
L["settings:optStateFor"] = "Attribution de %s"

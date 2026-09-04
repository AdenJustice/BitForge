if GetLocale() ~= "frFR" then return end
---@class BitForge.AzerothPrime
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "AzerothPrime"
L["settings:openEnabled"] = "Activer le bouton des objets à ouvrir"
L["settings:openEnabledTooltip"] = "Affiche un bouton pour le prochain objet à ouvrir ou utiliser dans vos sacs"
L["settings:sellEnabled"] = "Activer la vente chez les marchands"
L["settings:sellEnabledTooltip"] = "Vend les objets qu'une règle sélectionne lorsque vous ouvrez la fenêtre d'un marchand. Rien n'est vendu tant qu'aucune règle n'est définie"
L["settings:bankEnabled"] = "Activer le dépôt à la Banque de bataillon"
L["settings:bankEnabledTooltip"] = "Dépose les composants, les recettes utiles à vos autres personnages et les objets que vous triez lors d'une visite à la banque"

-- Leftover-install guard
L["msg:replacedInstalled"] = "AzerothPrime : %s désactivé — remplacé par cet addon."
L["msg:replacedInstalledFix"] = "Supprimez l'ancien dossier d'installation pour ne plus voir ce message."

-- Openables button
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

L["report:blurbOpen"] = "Ce rapport contient l'objet, son sac et son emplacement ainsi que s'il est verrouillé, la façon dont BitForge l'a classé, le texte de son infobulle, et les métiers que connaît ce personnage. Rien ici ne mentionne votre personnage, royaume, guilde ou faction."

L["blacklist:windowTitle"] = "Objets exclus"
L["blacklist:empty"] = "Aucun objet n'est exclu."
L["blacklist:remove"] = "Retirer"
L["blacklist:clearAll"] = "Tout effacer"
L["blacklist:unknownItem"] = "Objet %d"

L["binding:header"] = "BitForge AzerothPrime"
L["binding:use"] = "Utiliser l'objet à ouvrir"

L["settings:previewMoves"] = "Aperçu avant dépôt"
L["settings:previewMovesTooltip"] = "Afficher une fenêtre de confirmation listant chaque déplacement avant tout dépôt"
L["settings:onlyWantedReagents"] = "Ne déposer que les composants utilisables"
L["settings:onlyWantedReagentsTooltip"] = "Ne déposer que les composants qu'un métier de ce compte peut travailler. Désactivé, tout est déposé, pour l'hôtel des ventes"

L["btn:deposit"] = "Déposer"
L["btn:depositing"] = "Dépôt en cours… %d"

L["preview:title"] = "Confirmer le dépôt"
L["preview:summary"] = "%d objet(s) en %d déplacement(s)"
L["preview:toWarband"] = "→ Banque de bataillon"
L["preview:dontAskAgain"] = "Ne plus demander"
L["btn:confirm"] = "Confirmer"
L["btn:cancel"] = "Annuler"

L["msg:nothingToDo"] = "AzerothPrime : Rien à déplacer."
L["msg:done"] = "AzerothPrime : Terminé. %d objet(s) déplacé(s)."
L["msg:noVacancy"] = "AzerothPrime : La banque de bataillon est pleine."
L["msg:blockedCombat"] = "AzerothPrime : Arrêté — vous êtes en combat."
L["msg:blockedBankClosed"] = "AzerothPrime : Arrêté — la banque s'est fermée."
L["msg:blockedCursor"] = "AzerothPrime : Arrêté — vous tenez quelque chose au curseur."
L["msg:blockedLocked"] = "AzerothPrime : Arrêté — un objet est verrouillé."
L["msg:moveFailed"] = "AzerothPrime : Arrêté — un déplacement n'a pas abouti."
L["msg:openProfession"] = "AzerothPrime : Ouvrez une fois votre fenêtre %s pour que AzerothPrime puisse enregistrer les recettes que vous connaissez."

-- Curation window
L["curation:title"] = "Tri des objets"
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
L["msg:noVacancyPrivate"] = "AzerothPrime : Votre banque est pleine."
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

L["panel:batchSell"] = "Vente groupée"
L["panel:sellManifest"] = "Manifeste de vente"
L["panel:blacklist"] = "Liste noire"
L["panel:whitelist"] = "Liste blanche"

L["ui:ruleWindowTitle"] = "Règles de vente groupée"
L["ui:ruleWindowNothingToConfigure"] = "Rien à configurer ici."
L["ui:ruleWindowDisclaimer"] =
"En combat et dans les instances, le jeu refuse parfois de révéler les détails d'un objet. AzerothPrime garde ces objets plutôt que de deviner, donc il se peut que quelques-uns manquent à la liste -- c'est normal. Un verdict qui semble erroné pour toute autre raison mérite d'être signalé."
L["ui:selectedCount"] = "Sélection : %d"
L["ui:reagentsNoProfession"] =
"Aucun personnage de ce compte n'a encore de métier, donc cette règle ne garde rien. Connectez-vous avec un personnage qui en a un et ces réglages reviendront."

L["btn:sellAll"] = "Tout vendre"
L["btn:refresh"] = "Actualiser"
L["btn:rules"] = "Règles"

L["menu:temporaryExclude"] = "Exclure temporairement"
L["menu:blacklisted"] = "Liste noire"
L["menu:whitelisted"] = "Liste blanche"
L["menu:noStatus"] = "Aucune"
L["menu:reportVerdict"] = "Signaler ce verdict"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "Marquer les composants de cette recette"

L["status:noItemsToSell"] = "Aucun objet à vendre"
L["status:itemsTotal"] = "%d objets  |  Total : %s"

L["ui:manifestHint"] = "Vous attendiez un objet qui n'apparaît pas dans la liste ? Survolez-le dans vos sacs pour savoir pourquoi."

-- Merchant row
L["tooltip:charOverride"] =
"Le réglage de ce personnage prime sur la liste du bataillon – cet objet sera vendu."

L["section:general"] = "Général"
L["section:lists"] = "Listes"
L["section:everyItem"] = "Tous les objets"
L["section:byItemType"] = "Par type d'objet"

L["settings:openRuleWindow"] = "Voir les règles"
L["settings:openRuleWindowTooltip"] =
"Explique ce que recherche chaque règle, et pourquoi un objet a été conservé ou vendu"
L["settings:sellJunk"] = "Vendre les déchets"
L["settings:sellJunkTooltip"] = "Vendre automatiquement tous les objets de qualité médiocre (gris) lors d'une visite chez un marchand"
L["settings:limitBatch"] = "Limiter le lot à 12"
L["settings:limitBatchTooltip"] = "Vendre au maximum 12 objets par clic pour éviter la limitation du serveur"
L["settings:keepUsedReagents"] = "Garder les composants de vos métiers"
L["settings:keepUsedReagentsTooltip"] =
"Garder les composants d'artisanat qu'un métier de ce compte peut utiliser. Un exemplaire lié à l'âme n'atteindra jamais un autre personnage : seuls les métiers de ce personnage le gardent alors"
L["settings:reagentsExpansions"] = "Quels composants garder"
L["settings:reagentsExpansionsTooltip"] =
"De quelles extensions la règle ci-dessus garde les composants. Par défaut, seule l'extension actuelle est cochée : les composants plus anciens sont donc proposés à la vente, sauf ceux dont une recette que vous avez marquée a encore besoin, qui sont gardés quoi que vous cochiez ici"
L["settings:margin"] = "Marge de niveau d'objet"
L["settings:marginTooltip"] =
"De combien une pièce de votre propre qualité peut rester sous l'emplacement avant d'être vendue. À 0, il suffit qu'elle égale l'emplacement"
L["settings:qualityMargin"] = "Marge de qualité"
L["settings:qualityMarginTooltip"] =
"Ce que vaut un palier de qualité en niveaux d'objet. À 10, une pièce un palier sous celle que vous portez a besoin de 10 niveaux d'objet de plus pour être conservée, et un palier au-dessus survit 10 en dessous. À 0, la qualité cesse de compter et seul le niveau d'objet décide. À Toujours, toute qualité supérieure est conservée quel que soit son niveau d'objet, et aucun niveau d'objet ne sauve une qualité inférieure"
L["settings:qualityMarginAlways"] = "Toujours"
L["settings:keepForDisenchant"] = "Garder l'équipement selon l'extension de ses matériaux"
L["settings:keepForDisenchantTooltip"] =
"Gardez l'équipement qu'un enchanteur pourrait désenchanter, selon l'extension des matériaux qu'il produirait plutôt que selon l'âge de l'équipement lui-même -- l'équipement d'une extension terminée produit les matériaux de cette extension. Votre propre enchanteur garde toujours ce que lui seul peut atteindre, quel que soit ce réglage, mais cela décide toujours si cela s'étend aussi aux matériaux plus anciens"
L["settings:spareBindOnAccount"] = "Épargner l'équipement lié au compte"
L["settings:spareBindOnAccountTooltip"] =
"De quelles extensions garder l'équipement lié au compte tant qu'il peut encore être transmis à un autre personnage"
L["settings:spareBindOnEquip"] = "Épargner l'équipement lié à l'équipement"
L["settings:spareBindOnEquipTooltip"] =
"De quelles extensions garder l'équipement se liant à l'équipement tant qu'il peut encore atteindre un autre personnage ou l'hôtel des ventes"
L["settings:keepUncollectedCosmetic"] = "Garder les apparences non collectées"
L["settings:keepUncollectedCosmeticTooltip"] =
"Garde tout objet dont vous n'avez pas collecté l'apparence. Vendre une pièce ordinaire la collecte quand même, mais un objet cosmétique n'accorde son allure qu'à l'utilisation : vendez-le et l'apparence est perdue pour de bon"
L["settings:sellRelics"] = "Vendre les reliques Classic"
L["settings:sellRelicsTooltip"] =
"Vend les idoles, grimoires, totems et sceaux, l'emplacement de relique que Cataclysm a supprimé. Pas les reliques d'artefact de Legion, qui sont des gemmes et n'en partagent que le numéro de sous-classe"
L["settings:gemsExpansions"] = "Quelles gemmes garder"
L["settings:gemsExpansionsTooltip"] =
"De quelles extensions garder les gemmes. Tout ce qui n'est pas coché tombe sur les deux questions ci-dessous"
L["settings:gemsRecipesNow"] = "Garder les gemmes actuelles utiles à une recette"
L["settings:gemsRecipesNowTooltip"] =
"Garde une gemme de l'extension actuelle qu'une recette de métier utilise comme composant, quel que soit le propriétaire du métier. La question s'adresse au catalogue de recettes, et une gemme qui n'y figure pas compte comme une gemme dont aucune recette n'a besoin"
L["settings:gemsRecipesOld"] = "Garder les gemmes anciennes utiles à une recette"
L["settings:gemsRecipesOldTooltip"] =
"La même question pour les gemmes des extensions passées. Ce que vos propres métiers emploient est déjà gardé ailleurs, donc cette colonne vise les recettes de tous les autres"
L["settings:keepArtifactRelics"] = "Garder les reliques d'artefact"
L["settings:keepArtifactRelicsTooltip"] =
"Garde les reliques que l'on sertissait dans les armes d'artefact de Legion. Plus rien ne les emploie depuis Legion, il vaut donc mieux désactiver ceci sauf si vous les collectionnez"
L["settings:enhancementsExpansions"] = "Quelles améliorations garder"
L["settings:enhancementsExpansionsTooltip"] =
"De quelles extensions garder les améliorations d'objet. Une nouvelle extension plafonne l'équipement auquel une amélioration s'applique, alors cochez l'extension dont vous portez vraiment l'équipement"
L["settings:keepLearnable"] = "Garder les recettes que vous pouvez apprendre"
L["settings:keepLearnableTooltip"] =
"Garde une recette que ce personnage n'a pas apprise"
L["settings:keepTradeableRecipes"] = "Garder les recettes échangeables"
L["settings:keepTradeableRecipesTooltip"] =
"Garde une recette encore non liée, afin qu'elle atteigne un autre personnage ou l'hôtel des ventes même si ce personnage l'a déjà apprise"
L["settings:sellCollectedMounts"] = "Vendre les montures collectées"
L["settings:sellCollectedMountsTooltip"] =
"Vend une monture que vous possédez déjà, dès lors que l'exemplaire est lié à l'âme. Un exemplaire non lié est gardé quoi qu'en dise ce réglage, puisqu'il peut encore atteindre quelqu'un"
L["settings:sellCollectedToys"] = "Vendre les jouets collectés"
L["settings:sellCollectedToysTooltip"] =
"Vend un jouet que vous possédez déjà, dès lors que l'exemplaire dans vos sacs est lié. Un exemplaire non lié est gardé quoi qu'en dise votre collection, puisqu'il peut encore atteindre quelqu'un"
L["settings:sellCollectedPets"] = "Vendre les mascottes collectées"
L["settings:sellCollectedPetsTooltip"] =
"Vend une mascotte de combat que vous avez déjà. Une que vous n'avez jamais collectée n'est jamais vendue par cette règle, dans un sens comme dans l'autre"
L["settings:sellHoliday"] = "Vendre les objets de fête"
L["settings:sellHolidayTooltip"] =
"Vend les jetons, costumes et babioles que les événements mondiaux laissent dans vos sacs"
L["settings:sellMountEquipment"] = "Vendre l'équipement de monture"
L["settings:sellMountEquipmentTooltip"] =
"Vend l'équipement de monture. Une seule pièce s'applique à tout le compte à la fois, donc les exemplaires en trop dans vos sacs ne servent à rien"
L["settings:sellCollectedDecor"] = "Vendre le décor collecté"
L["settings:sellCollectedDecorTooltip"] =
"Vend le décor d'habitation que votre catalogue possède déjà. Une pièce qu'il n'a jamais vue est gardée, tout comme une pièce pour laquelle le catalogue n'a pas pu être lu"
L["settings:keepTradeableDyes"] = "Garder les teintures échangeables"
L["settings:keepTradeableDyesTooltip"] =
"Une teinture se consomme à l'application et ne s'apprend jamais : il n'y a donc pas de collection à interroger. On demande plutôt si cet exemplaire peut encore atteindre quelqu'un : non lié, il est gardé ; lié, il est vendu"
L["settings:spareProfessions"] = "Épargner pour ces métiers"
L["settings:spareProfessionsTooltip"] =
"Garde un bien de métier si un métier coché ici pourrait l'utiliser comme composant -- pour un personnage secondaire qui ne l'a pas encore appris, ou pour l'hôtel des ventes. Les métiers de ce compte sont déjà couverts par Garder les composants de vos métiers"

L["spare:none"] = "Aucun"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "Toutes les extensions"
L["expansion:current"] = "Extension actuelle"

L["profession:FirstAid"] = "Premiers soins"
L["profession:Blacksmithing"] = "Forge"
L["profession:Leatherworking"] = "Travail du cuir"
L["profession:Alchemy"] = "Alchimie"
L["profession:Herbalism"] = "Herboristerie"
L["profession:Cooking"] = "Cuisine"
L["profession:Mining"] = "Minage"
L["profession:Tailoring"] = "Couture"
L["profession:Engineering"] = "Ingénierie"
L["profession:Enchanting"] = "Enchantement"
L["profession:Fishing"] = "Pêche"
L["profession:Skinning"] = "Dépeçage"
L["profession:Jewelcrafting"] = "Joaillerie"
L["profession:Inscription"] = "Calligraphie"
L["profession:Archaeology"] = "Archéologie"

L["sub:0"] = "Générique"
L["sub:1"] = "Potion"
L["sub:2"] = "Élixir"
L["sub:3"] = "Flacons et fioles"
L["sub:5"] = "Nourriture et boisson"
L["sub:7"] = "Bandage"
L["sub:8"] = "Autre"
L["sub:9"] = "Rune de Vantus"

L["option:expansions"] = "Quelles extensions garder"
L["option:recipesNow"] = "Garder aussi ceux de cette extension si une recette en veut"
L["option:recipesOld"] = "Garder aussi les plus anciens si une recette en veut"

-- List tabs
L["btn:removeEntry"] = "Retirer"
L["list:warband"] = "Bataillon"
L["list:character"] = "Personnage"
L["status:listEmpty"] = "Cette liste est vide"
L["status:listCount"] = "%d entrées"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Vente groupée : sera vendu"
L["verdict:keep"] = "Vente groupée : sera gardé"
L["claimed:OPEN"] = "Le bouton d'ouverture l'a réclamé"
L["claimed:DEPOSIT_WARBAND"] = "Part plutôt à la Banque de bataillon"
L["claimed:DEPOSIT_PRIVATE"] = "Part plutôt à la banque propre d'un personnage"
L["reason:TEMP_EXCLUDED"] = "Exclu pour cette visite chez le marchand"
L["reason:BLACKLISTED"] = "Sur votre liste noire"
L["reason:LOCKED"] = "L'objet est verrouillé"
L["reason:EQUIPMENT_SET"] = "Fait partie d'un ensemble d'équipement"
L["reason:NO_SELL_PRICE"] = "Aucun marchand ne l'achètera"
L["reason:REFUNDABLE"] = "Encore dans son délai de remboursement"
L["reason:WHITELISTED"] = "Sur votre liste blanche"
L["reason:TEMP_INCLUDED"] = "Ajouté pour cette visite chez le marchand"
L["reason:JUNK"] = "« Vendre les déchets » est désactivé, les déchets ne sont pas touchés"
L["reason:JUNK_SOLD"] = "« Vendre les déchets » est activé, les déchets sont vendus"
L["reason:ABOVE_EPIC"] = "Mieux qu'épique, il n'est donc jamais vendu"
L["reason:BIND_ON_ACCOUNT"] = "L'équipement lié au compte est gardé"
L["reason:DISENCHANTABLE"] = "Vaut la peine d'être désenchanté ou revendu"
L["reason:BAG_KEPT"] = "Les sacs ne sont jamais vendus"
L["reason:PROFESSION_GEAR_KEPT"] = "L'équipement de métier n'est jamais vendu"
L["reason:ENHANCEMENT_EXPANSION"] = "Les améliorations d'objet de cette extension sont conservées"
L["reason:CONSUMABLE_EXPANSION"] = "Les consommables de cette extension sont conservés"
L["reason:CONSUMABLE_REAGENT"] = "Une recette quelque part utilise ceci comme composant"
L["reason:GEM_EXPANSION"] = "Les gemmes de cette extension sont conservées"
L["reason:GEM_REAGENT"] = "Une recette quelque part utilise ceci comme composant"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "Les reliques d'artefact sont conservées"
L["reason:TRADE_GOOD_SPARED"] = "Un métier que vous avez épargné veut ceci"
L["reason:NOT_WANTED"] = "Aucune case ne conserve l'objet, il est donc vendu"
L["reason:REAGENT_WANTED"] = "Un métier qui peut l'utiliser en a besoin comme composant"
L["reason:NOT_EQUIPPABLE"] = "Non équipable ou non recommandé pour votre classe"
L["reason:EQUIPPABLE"] = "Suffisant par rapport à votre équipement actuel"
L["reason:OUTCLASSED"] = "Surpassé par votre équipement actuel"
L["reason:OUTDATED_EXPAC"] = "Dépasse votre équipement actuel, qui date de l'extension précédente"
L["reason:BIND_ON_EQUIP"] = "L'objet lié à l'équipement est gardé"
L["reason:ARMOR_RELIC"] = "Plus personne ne peut équiper une relique, elle est donc vendue"
L["reason:RECIPE_LEARNABLE"] = "Pas encore apprise, elle est donc gardée"
L["reason:HOLIDAY_ITEM"] = "Les objets de fête sont vendus"
L["reason:MOUNT_EQUIPMENT"] = "L'équipement de monture est vendu"
L["reason:ALREADY_COLLECTED"] = "L'objet est déjà collectionné, il est donc vendu"
L["reason:NOT_COLLECTED"] = "L'objet n'est pas encore collectionné, il est donc gardé"
L["reason:STILL_TRADEABLE"] = "L'objet est encore échangeable, il est donc gardé"
L["reason:ALREADY_LEARNED"] = "L'objet est déjà appris, il est donc vendu"
L["reason:DEFAULT"] = "Aucune règle ne l'a réclamé, il est donc gardé"

L["listReset:warbandBlacklist"] = "Réinitialiser la liste noire du bataillon"
L["listReset:warbandWhitelist"] = "Réinitialiser la liste blanche du bataillon"
L["listReset:charBlacklist"] = "Réinitialiser la liste noire du personnage"
L["listReset:charWhitelist"] = "Réinitialiser la liste blanche du personnage"
L["listReset:confirm"] = "Êtes-vous sûr de vouloir effacer cette liste ? Cette action est irréversible."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Impossible de vendre %s pour le moment : %s"
L["msg:dropUnexcluded"] = "%s n'est plus exclu et sera vendu lors de cette visite"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "Bloqué temporairement"
L["rule:tempSub"] = "Pour cette visite chez le marchand uniquement"
L["rule:tempBlurb"] =
"Objets que vous avez retirés de la liste de vente avant de cliquer sur Vendre. Ils restent dans vos sacs pour cette visite et sont de nouveau jugés normalement lors de la prochaine visite chez un marchand."
L["rule:black"] = "Ne jamais vendre"
L["rule:blackSub"] = "Votre liste Ne jamais vendre"
L["rule:blackBlurb"] =
"Tout ce qui figure sur votre liste Ne jamais vendre reste dans vos sacs. Un réglage sur ce personnage prime sur la liste du bataillon, quel que soit le sens du désaccord entre les deux."
L["rule:gates"] = "Invendable"
L["rule:gatesSub"] = "Le marchand ne les reprend pas"
L["rule:gatesBlurb"] =
"Objets verrouillés, tout ce qui fait partie d'un ensemble d'équipement, objets sans prix de vente, et achats encore dans leur délai de remboursement. Votre liste Toujours vendre ne l'emporte pas sur ceux-ci, car le marchand refuserait la vente de toute façon."
L["rule:white"] = "Toujours vendre"
L["rule:whiteSub"] = "Votre liste Toujours vendre"
L["rule:whiteBlurb"] =
"Tout ce qui figure sur votre liste Toujours vendre est vendu, même quand une règle ultérieure l'aurait gardé. C'est ainsi que vous vendez ce composant d'artisanat dont vous ne voulez pas."
L["rule:tempIn"] = "Ajouté pour cette visite"
L["rule:tempInSub"] = "Pour cette visite chez le marchand uniquement"
L["rule:tempInBlurb"] =
"Objets que vous avez glissés sur la liste de vente chez ce marchand. Ils sont vendus lors de cette visite et de nouveau jugés normalement lors de la prochaine."
L["rule:junk"] = "Qualité médiocre"
L["rule:junkSub"] = "Désactivé par défaut"
L["rule:junkBlurb"] =
"Les objets gris, quel que soit leur type. Désactivé par défaut, car un autre addon s'en charge généralement. Si aucun ne le fait, activez cette option et AzerothPrime les videra pour vous."
L["rule:epic"] = "Légendaire et au-delà"
L["rule:epicSub"] = "Légendaire, Artefact, Objet de famille"
L["rule:epicBlurb"] =
"Jamais vendu. Le marchand affiche un prix pour ces objets puis refuse la vente, donc AzerothPrime ne les met pas sur la liste."
L["rule:reagent"] = "Composants d'artisanat"
L["rule:reagentSub"] = "Utilise votre liste de métiers"
L["rule:reagentBlurb"] =
"Garde tout composant qu'un métier de ce compte peut utiliser, quel que soit le type d'objet. Les composants apparaissent aussi bien en potions, en gemmes qu'en biens de métier, donc ceci est vérifié avant le type de l'objet. Seuls ceux de l'extension actuelle sont gardés tant que vous n'en décidez pas autrement ; un composant plus ancien l'est aussi dès qu'une recette que vous avez marquée en a encore besoin, quelles que soient les extensions cochées. La liste est lue depuis les recettes du jeu lui-même : elle contient donc déjà les composants optionnels qu'une recette accepte ainsi que chaque palier de qualité -- vous n'avez rien à ouvrir ni à parcourir."
L["rule:cosmetic"] = "Apparences non collectionnées"
L["rule:cosmeticSub"] = "Objets cosmétiques que vous n'avez pas collectionnés"
L["rule:cosmeticBlurb"] =
"Un objet cosmétique que vous n'avez pas collectionné est gardé. Le vendre ne collectionne pas son apparence -- elle disparaît tout simplement --, ce qui fait de cet endroit le seul de la fenêtre où une erreur ne peut pas être annulée. Un objet cosmétique que vous avez déjà collectionné n'est pas vendu pour cette seule raison ; il ne porte plus rien à protéger, et continue d'être jugé comme l'arme ou l'armure qu'il est."
L["rule:consumables"] = "Consommables"
L["rule:consumablesSub"] = "Potions, nourriture, parchemins, bibelots"
L["rule:consumablesBlurb"] =
"Choisissez quoi garder pour chaque type de consommable. Tout ce qu'aucune case ne garde est vendu."
L["rule:bags"] = "Sacs"
L["rule:bagsSub"] = "Conteneurs de toutes sortes"
L["rule:bagsBlurb"] =
"Jamais vendus. Quels sacs vous portez, c'est votre choix, donc AzerothPrime ne les juge pas."
L["rule:gear"] = "Armes et armure"
L["rule:gearSub"] = "Jugées par rapport à ce que vous portez"
L["rule:gearBlurb"] =
"Un seul jeu de réglages juge les deux. Chaque arme et chaque pièce d'armure passe par les questions ci-dessous dans l'ordre, et la première qui répond Garder tranche."
L["rule:gems"] = "Gemmes"
L["rule:gemsSub"] = "Emplacements et reliques d'artefact"
L["rule:gemsBlurb"] =
"Un seul jeu de choix pour chaque gemme. Les reliques d'artefact ont leur propre option ci-dessous, car rien d'autre dans le type d'une gemme ne change si elle vaut la peine d'être gardée."
L["rule:tradeGoods"] = "Biens de métier"
L["rule:tradeGoodsSub"] = "Matériaux d'artisanat par métier"
L["rule:tradeGoodsBlurb"] =
"Choisissez de qui garder les composants. Tout ce que vous n'épargnez pas est vendu -- même si un composant que vos propres métiers utilisent réellement est déjà gardé par la règle Composants d'artisanat ci-dessus."
L["rule:enhancements"] = "Améliorations d'objet"
L["rule:enhancementsSub"] = "Enchantements, huiles, pierres"
L["rule:enhancementsBlurb"] =
"Une nouvelle extension plafonne l'équipement auquel ceux-ci peuvent s'appliquer, donc les plus anciens perdent toute valeur. Cochez chaque extension dont vous portez vraiment l'équipement, celle-ci comprise -- plus rien n'est gardé automatiquement."
L["rule:recipes"] = "Recettes"
L["rule:recipesSub"] = "Patrons, plans, formules"
L["rule:recipesBlurb"] =
"Chaque recette porte le métier auquel elle appartient, elle est donc jugée dès qu'elle se présente chez le marchand. Une recette qui n'appartient à aucun métier en particulier -- un patron ou un manuel générique -- est laissée de côté, puisqu'il n'y a rien à quoi la comparer."
L["rule:misc"] = "Divers"
L["rule:miscSub"] = "Mascottes, montures, jouets, objets de fête"
L["rule:miscBlurb"] =
"Les composants de sort sont laissés de côté. Parmi les objets non classés, seul un jouet est jugé : il est vendu dès qu'il est déjà dans votre collection et que l'exemplaire dans vos sacs est lié. Les objets gris sont gérés par la règle Qualité médiocre ci-dessus, pas ici."
L["rule:profession"] = "Équipement de métier"
L["rule:professionSub"] = "Outils et accessoires"
L["rule:professionBlurb"] =
"Jamais vendu. Ceux qui sont échangeables valent de l'argent, et ceux qui sont liés, vous les avez fabriqués pour vous-même ou vous les utilisez en ce moment, donc il n'y a aucun cas où les vendre serait juste."
L["rule:housing"] = "Logement"
L["rule:housingSub"] = "Décorations et teintures"
L["rule:housingBlurb"] =
"Une fois qu'une décoration est collectionnée, l'objet lui-même n'a plus aucune utilité, donc il peut aller chez le marchand. Une teinture n'est pas du tout ce genre de chose : c'est un consommable à usage unique, épuisé une fois appliqué, donc il n'y a rien à collectionner ni rien qui ait pu être appris. Elle n'est jamais liée non plus, donc la seule question qui vaille est de savoir si elle peut encore atteindre quelqu'un qui la veut."
L["rule:none"] = "Tout le reste"
L["rule:noneSub"] = "Objets de quête, clés, glyphes, jetons"
L["rule:noneBlurb"] =
"Types d'objets que AzerothPrime ne juge pas du tout : objets de quête, clés, mascottes en cage, glyphes, jetons WoW, composants de sort, flèches et les autres catégories retirées. Ils restent dans vos sacs, quel que soit le réglage des règles ci-dessus."

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "Ce rapport contient le lien de l'objet et ses autres caractéristiques, le verdict auquel BitForge est arrivé et la règle qui l'a décidé, si vous avez vous-même mis cet objet sur votre liste noire ou blanche, ce que vous portez dans l'emplacement qu'il occuperait, et les paramètres qui ont jugé la paire. Un lien d'objet indique le niveau et la spécialisation de votre personnage -- cela fait partie du format du lien lui-même, et le retirer ferait perdre le détail qui rend le rapport reproductible. Rien ici ne nomme votre personnage, votre royaume, votre guilde ou votre faction, et rien ne décrit un autre emplacement."

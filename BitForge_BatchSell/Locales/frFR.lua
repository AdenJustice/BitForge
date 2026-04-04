if GetLocale() ~= "frFR" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Vente groupée"
L["panel:sellManifest"] = "Manifeste de vente"
L["panel:blacklist"] = "Liste noire"
L["panel:whitelist"] = "Liste blanche"

-- Buttons
L["btn:sellAll"] = "Tout vendre"
L["btn:refresh"] = "Actualiser"

-- Context menu
L["menu:addToBlacklist"] = "Ajouter à la liste noire"
L["menu:addToWhitelist"] = "Ajouter à la liste blanche"
L["menu:addToBlacklistChar"] = "Ajouter à la liste noire (Personnage)"
L["menu:addToWhitelistChar"] = "Ajouter à la liste blanche (Personnage)"
L["menu:clearCharOverride"] = "Annuler la dérogation du personnage"
L["menu:resetListEntry"] = "Retirer de la liste"
L["menu:temporaryExclude"] = "Exclure temporairement"

-- Status
L["status:noItemsToSell"] = "Aucun objet à vendre"
L["status:itemsTotal"] = "%d objets  |  Total : %s"

-- Merchant row
L["tooltip:charOverride"] =
"Le réglage de ce personnage prime sur la liste de la troupe de guerre – cet objet sera vendu."

-- Settings
L["settings:sellJunk"] = "Vendre les déchets"
L["settings:sellJunkTooltip"] = "Vendre automatiquement tous les objets de mauvaise qualité (gris) lors d'une visite chez un marchand"
L["settings:keepEquippable"] = "Garder les équipables"
L["settings:keepEquippableTooltip"] = "Garder tous les objets équipables par votre classe"
L["settings:keepBindOnAccount"] = "Garder les liaisons au compte"
L["settings:keepBindOnAccountTooltip"] = "Garder l'équipement lié au compte (héritage)"
L["settings:keepBindOnAccountPastExpac"] = "  Inclure les extensions passées"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Garder également l'équipement lié au compte des extensions passées"
L["settings:keepDisenchantables"] = "Garder les désenchantables"
L["settings:keepDisenchantablesTooltip"] = "Enchanteurs : garder l'équipement LPC/LPÉ/LàC. Autres : garder l'équipement LPÉ/LàC pour l'HV ou les alts"
L["settings:keepDisenchantablesPastExpac"] = "  Inclure les extensions passées"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Garder également l'équipement désenchantable des extensions passées"
L["settings:limitBatch"] = "Limiter le lot à 12"
L["settings:limitBatchTooltip"] = "Vendre au maximum 12 objets par clic pour éviter la limitation du serveur"
L["settings:qualityThreshold"] = "Seuil de qualité"
L["settings:qualityThresholdTooltip"] = "Vendre les objets ayant cette qualité ou inférieure"
L["settings:ilvlThreshold"] = "Marge de niveau d'objet"
L["settings:ilvlThresholdTooltip"] =
"Garder les objets équipables dans cette plage de niveaux d'objet par rapport à votre équipement (négatif = garder les meilleurs objets)"
L["settings:sellPastExpansion"] = "Vendre les objets des extensions passées"
L["settings:sellPastExpansionTooltip"] = "Vendre les objets des extensions plus anciennes que le seuil sélectionné"
L["settings:expansionThreshold"] = "Seuil d'extension"
L["settings:expansionThresholdTooltip"] = "Vendre les objets des extensions plus anciennes que celle sélectionnée"

-- Quality labels
L["quality:poor"] = "Médiocre"
L["quality:common"] = "Commun"
L["quality:uncommon"] = "Peu commun"
L["quality:rare"] = "Rare"
L["quality:epic"] = "Épique"

-- Expansion labels
L["expansion:all"] = "Toutes les extensions"
L["expansion:classic"] = "Classic"
L["expansion:burningCrusade"] = "La Croisade ardente"
L["expansion:wrathOfTheLichKing"] = "La Colère du roi-liche"
L["expansion:cataclysm"] = "Cataclysme"
L["expansion:mistsOfPandaria"] = "Brumes de Pandaria"
L["expansion:warlordsOfDraenor"] = "Seigneurs de guerre de Draenor"
L["expansion:legion"] = "Légion"
L["expansion:battleForAzeroth"] = "La Bataille pour Azeroth"
L["expansion:shadowlands"] = "Shadowlands"
L["expansion:dragonflight"] = "Dragonflight"
L["expansion:theWarWithin"] = "La Guerre intérieure"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Réinitialiser la liste noire de la troupe de guerre"
L["listReset:warbandWhitelist"] = "Réinitialiser la liste blanche de la troupe de guerre"
L["listReset:charBlacklist"] = "Réinitialiser la liste noire du personnage"
L["listReset:charWhitelist"] = "Réinitialiser la liste blanche du personnage"
L["listReset:confirm"] = "Êtes-vous sûr de vouloir effacer cette liste ? Cette action est irréversible."

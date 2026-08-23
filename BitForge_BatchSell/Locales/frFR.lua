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

-- Section titles
L["section:general"] = "Général"
L["section:equipment"] = "Équipement"
L["section:materials"] = "Matériaux d'artisanat"
L["section:other"] = "Consommables et divers"
L["section:lists"] = "Listes"

-- Settings
L["settings:sellJunk"] = "Vendre les déchets"
L["settings:sellJunkTooltip"] = "Vendre automatiquement tous les objets de mauvaise qualité (gris) lors d'une visite chez un marchand"
L["settings:limitBatch"] = "Limiter le lot à 12"
L["settings:limitBatchTooltip"] = "Vendre au maximum 12 objets par clic pour éviter la limitation du serveur"
L["settings:sellEquipment"] = "Vendre l'équipement"
L["settings:sellEquipmentTooltip"] =
"Autoriser la vente des armures et des armes. Si cette option est désactivée, aucun équipement n'est jamais vendu"
L["settings:ilvlMargin"] = "Marge de niveau d'objet"
L["settings:ilvlMarginTooltip"] =
"Ce que vaut un palier de qualité en niveaux d'objet. À 10, une pièce un palier sous celle que vous portez doit la dépasser de 10 pour être conservée, et un palier au-dessus survit 10 en dessous. À votre propre qualité, une pièce doit simplement dépasser l'emplacement. À 0, la qualité cesse de compter et seul le niveau d'objet décide"
L["settings:emphasizeQuality"] = "  Accentuer la qualité"
L["settings:emphasizeQualityTooltip"] =
"Compte un palier de qualité pour le double de la marge et autorise une pièce de votre propre qualité à rester cette marge sous l'emplacement. La qualité supérieure à celle que vous portez devient moins chère à conserver, et la qualité inférieure plus chère à excuser"
L["settings:keepBindOnAccount"] = "Garder les liaisons au compte"
L["settings:keepBindOnAccountTooltip"] = "Garder l'équipement lié au compte (héritage)"
L["settings:keepBindOnAccountPastExpac"] = "  Inclure les extensions passées"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Garder également l'équipement lié au compte des extensions passées"
L["settings:keepDisenchantables"] = "Garder les désenchantables"
L["settings:keepDisenchantablesTooltip"] = "Enchanteurs : garder l'équipement LPC/LPÉ/LàC. Autres : garder l'équipement LPÉ/LàC pour l'HV ou les alts"
L["settings:keepDisenchantablesPastExpac"] = "  Inclure les extensions passées"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Garder également l'équipement désenchantable des extensions passées"
L["settings:keepUsedReagents"] = "Garder les composants de vos métiers"
L["settings:keepUsedReagentsTooltip"] = "Garder les composants d'artisanat qu'un métier de ce compte peut utiliser"
L["settings:materialsMode"] = "Matériaux d'artisanat"
L["settings:materialsModeTooltip"] =
"Que faire des réactifs, biens commerciaux, gemmes, enchantements et recettes"
L["settings:materialsExpansion"] = "  Garder à partir de l'extension"
L["settings:materialsExpansionTooltip"] =
"Garder les matériaux à partir de cette extension et vendre tout ce qui est plus ancien. Utilisé uniquement lorsque Matériaux d'artisanat est réglé pour garder à partir d'une extension choisie"
L["settings:otherMode"] = "Consommables et divers"
L["settings:otherModeTooltip"] =
"Que faire des consommables, contenants, mascottes de combat, équipement de métier et décorations de logement"

-- Sell modes
L["mode:keepAll"] = "Tout garder"
L["mode:keepCurrent"] = "Garder l'extension actuelle"
L["mode:keepFrom"] = "Garder à partir de l'extension"
L["mode:sellAll"] = "Tout vendre"

-- List tabs
L["btn:removeEntry"] = "Retirer"
L["list:warband"] = "Troupe de guerre"
L["list:character"] = "Personnage"
L["status:listEmpty"] = "Cette liste est vide"
L["status:listCount"] = "%d entrées"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Vente groupée : sera vendu"
L["verdict:keep"] = "Vente groupée : sera gardé"
L["reason:TEMP_EXCLUDED"] = "Exclu pour cette visite chez le marchand"
L["reason:BLACKLISTED"] = "Sur votre liste noire"
L["reason:LOCKED"] = "L'objet est verrouillé"
L["reason:EQUIPMENT_SET"] = "Fait partie d'un ensemble d'équipement"
L["reason:NO_SELL_PRICE"] = "Aucun marchand ne l'achètera"
L["reason:REFUNDABLE"] = "Encore dans son délai de remboursement"
L["reason:WHITELISTED"] = "Sur votre liste blanche"
L["reason:TEMP_INCLUDED"] = "Ajouté pour cette visite chez le marchand"
L["reason:JUNK"] = "« Vendre les déchets » est désactivé, les déchets ne sont pas touchés"
L["reason:CATEGORY"] = "Ce type d'objet est réglé pour être gardé"
L["reason:CURRENT_EXPANSION"] = "Provient d'une extension que vous gardez"
L["reason:BIND_ON_ACCOUNT"] = "L'équipement lié au compte est gardé"
L["reason:DISENCHANTABLE"] = "Vaut la peine d'être désenchanté ou revendu"
L["reason:REAGENT_WANTED"] = "Un métier de ce compte utilise ceci"
L["reason:NOT_EQUIPPABLE"] = "Non équipable ou non recommandé pour votre classe"
L["reason:EQUIPPABLE"] = "Suffisant par rapport à votre équipement actuel"
L["reason:OUTCLASSED"] = "Surpassé par votre équipement actuel"
L["reason:SELL_MODE"] = "Ce type d'objet est réglé pour être vendu"
L["reason:DEFAULT"] = "Aucune règle ne l'a réclamé, il est donc gardé"

-- Expansion labels
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
L["expansion:midnight"] = "Midnight"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Réinitialiser la liste noire de la troupe de guerre"
L["listReset:warbandWhitelist"] = "Réinitialiser la liste blanche de la troupe de guerre"
L["listReset:charBlacklist"] = "Réinitialiser la liste noire du personnage"
L["listReset:charWhitelist"] = "Réinitialiser la liste blanche du personnage"
L["listReset:confirm"] = "Êtes-vous sûr de vouloir effacer cette liste ? Cette action est irréversible."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Impossible de vendre %s pour le moment : %s"
L["msg:dropUnexcluded"] = "%s n'est plus exclu et sera vendu lors de cette visite"

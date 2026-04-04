if GetLocale() ~= "esES" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Venta masiva"
L["panel:sellManifest"] = "Manifiesto de venta"
L["panel:blacklist"] = "Lista negra"
L["panel:whitelist"] = "Lista blanca"

-- Buttons
L["btn:sellAll"] = "Vender todo"
L["btn:refresh"] = "Actualizar"

-- Context menu
L["menu:addToBlacklist"] = "Añadir a la lista negra"
L["menu:addToWhitelist"] = "Añadir a la lista blanca"
L["menu:addToBlacklistChar"] = "Añadir a la lista negra (Personaje)"
L["menu:addToWhitelistChar"] = "Añadir a la lista blanca (Personaje)"
L["menu:clearCharOverride"] = "Quitar anulación del personaje"
L["menu:resetListEntry"] = "Eliminar de la lista"
L["menu:temporaryExclude"] = "Excluir temporalmente"

-- Status
L["status:noItemsToSell"] = "No hay objetos para vender"
L["status:itemsTotal"] = "%d objetos  |  Total: %s"

-- Merchant row
L["tooltip:charOverride"] =
"La configuración de este personaje anula la lista del Grupo de Guerra: este objeto se venderá."

-- Settings
L["settings:sellJunk"] = "Vender basura"
L["settings:sellJunkTooltip"] = "Vender automáticamente todos los objetos de calidad pobre (gris) al visitar un vendedor"
L["settings:keepEquippable"] = "Conservar equipables"
L["settings:keepEquippableTooltip"] = "Conservar todos los objetos que pueda equipar tu clase"
L["settings:keepBindOnAccount"] = "Conservar vinculados a cuenta"
L["settings:keepBindOnAccountTooltip"] = "Conservar el equipo vinculado a cuenta (reliquia)"
L["settings:keepBindOnAccountPastExpac"] = "  Incluir expansiones anteriores"
L["settings:keepBindOnAccountPastExpacTooltip"] = "También conservar el equipo vinculado a cuenta de expansiones anteriores"
L["settings:keepDisenchantables"] = "Conservar desencantables"
L["settings:keepDisenchantablesTooltip"] = "Encantadores: conservar equipo BOP/BOE/BOA. Otros: conservar equipo BOE/BOA para la Casa de subastas o alts"
L["settings:keepDisenchantablesPastExpac"] = "  Incluir expansiones anteriores"
L["settings:keepDisenchantablesPastExpacTooltip"] = "También conservar el equipo desencantable de expansiones anteriores"
L["settings:limitBatch"] = "Limitar lote a 12"
L["settings:limitBatchTooltip"] = "Vender como máximo 12 objetos por clic para evitar la limitación del servidor"
L["settings:qualityThreshold"] = "Umbral de calidad"
L["settings:qualityThresholdTooltip"] = "Vender objetos con esta calidad o inferior"
L["settings:ilvlThreshold"] = "Margen de nivel de objeto"
L["settings:ilvlThresholdTooltip"] =
"Conservar objetos equipables dentro de este número de niveles de objeto respecto a tu equipo equipado (negativo = conservar mejores objetos)"
L["settings:sellPastExpansion"] = "Vender objetos de expansiones anteriores"
L["settings:sellPastExpansionTooltip"] = "Vender objetos de expansiones más antiguas que el umbral seleccionado"
L["settings:expansionThreshold"] = "Umbral de expansión"
L["settings:expansionThresholdTooltip"] = "Vender objetos de expansiones más antiguas que la seleccionada"

-- Quality labels
L["quality:poor"] = "Pobre"
L["quality:common"] = "Común"
L["quality:uncommon"] = "Poco común"
L["quality:rare"] = "Poco frecuente"
L["quality:epic"] = "Épico"

-- Expansion labels
L["expansion:all"] = "Todas las expansiones"
L["expansion:classic"] = "Classic"
L["expansion:burningCrusade"] = "La Cruzada Ardiente"
L["expansion:wrathOfTheLichKing"] = "La Ira del Rey Exánime"
L["expansion:cataclysm"] = "Cataclismo"
L["expansion:mistsOfPandaria"] = "Nieblas de Pandaria"
L["expansion:warlordsOfDraenor"] = "Señores de la Guerra de Draenor"
L["expansion:legion"] = "Legión"
L["expansion:battleForAzeroth"] = "La Batalla por Azeroth"
L["expansion:shadowlands"] = "Tierras Sombrías"
L["expansion:dragonflight"] = "Vuelo de Dragón"
L["expansion:theWarWithin"] = "La Guerra Interior"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Restablecer lista negra del Grupo de Guerra"
L["listReset:warbandWhitelist"] = "Restablecer lista blanca del Grupo de Guerra"
L["listReset:charBlacklist"] = "Restablecer lista negra del personaje"
L["listReset:charWhitelist"] = "Restablecer lista blanca del personaje"
L["listReset:confirm"] = "¿Seguro que quieres vaciar esta lista? Esta acción no se puede deshacer."

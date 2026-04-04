if GetLocale() ~= "esMX" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Venta por lotes"
L["panel:sellManifest"] = "Manifiesto de venta"
L["panel:blacklist"] = "Lista negra"
L["panel:whitelist"] = "Lista blanca"

-- Buttons
L["btn:sellAll"] = "Vender todo"
L["btn:refresh"] = "Actualizar"

-- Context menu
L["menu:addToBlacklist"] = "Agregar a lista negra"
L["menu:addToWhitelist"] = "Agregar a lista blanca"
L["menu:addToBlacklistChar"] = "Agregar a lista negra (Personaje)"
L["menu:addToWhitelistChar"] = "Agregar a lista blanca (Personaje)"
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
L["settings:sellJunk"] = "Vender chatarra"
L["settings:sellJunkTooltip"] = "Vende automáticamente todos los objetos de calidad pobre (gris) al visitar un vendedor"
L["settings:keepEquippable"] = "Conservar equipables"
L["settings:keepEquippableTooltip"] = "Conserva todos los objetos equipables por tu clase"
L["settings:keepBindOnAccount"] = "Conservar vinculados a la cuenta"
L["settings:keepBindOnAccountTooltip"] = "Conserva el equipo vinculado a la cuenta (herencia)"
L["settings:keepBindOnAccountPastExpac"] = "  Incluir expansiones anteriores"
L["settings:keepBindOnAccountPastExpacTooltip"] = "También conserva el equipo vinculado a la cuenta de expansiones anteriores"
L["settings:keepDisenchantables"] = "Conservar desencantables"
L["settings:keepDisenchantablesTooltip"] = "Encantadores: conserva equipo VdP/VdC/VdC. Otros: conserva equipo VdC/VdC para la CA o alts"
L["settings:keepDisenchantablesPastExpac"] = "  Incluir expansiones anteriores"
L["settings:keepDisenchantablesPastExpacTooltip"] = "También conserva el equipo desencantable de expansiones anteriores"
L["settings:limitBatch"] = "Limitar lote a 12"
L["settings:limitBatchTooltip"] = "Vende como máximo 12 objetos por clic para evitar la limitación del servidor"
L["settings:qualityThreshold"] = "Umbral de calidad"
L["settings:qualityThresholdTooltip"] = "Vende objetos con esta calidad o inferior"
L["settings:ilvlThreshold"] = "Margen de nivel de objeto"
L["settings:ilvlThresholdTooltip"] =
"Conserva objetos equipables dentro de este margen de nivel de objeto respecto a tu equipo (negativo = conserva objetos mejores)"
L["settings:sellPastExpansion"] = "Vender objetos de expansiones anteriores"
L["settings:sellPastExpansionTooltip"] = "Vende objetos de expansiones más antiguas que el umbral seleccionado"
L["settings:expansionThreshold"] = "Umbral de expansión"
L["settings:expansionThresholdTooltip"] = "Vende objetos de expansiones más antiguas que la seleccionada"

-- Quality labels
L["quality:poor"] = "Pobre"
L["quality:common"] = "Común"
L["quality:uncommon"] = "Inusual"
L["quality:rare"] = "Raro"
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
L["listReset:confirm"] = "¿Estás seguro de que quieres borrar esta lista? Esta acción no se puede deshacer."

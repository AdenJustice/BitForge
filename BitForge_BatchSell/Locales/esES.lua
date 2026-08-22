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

-- Section titles
L["section:general"] = "General"
L["section:equipment"] = "Equipo"
L["section:materials"] = "Materiales de fabricación"
L["section:other"] = "Consumibles y otros"
L["section:lists"] = "Listas"

-- Settings
L["settings:sellJunk"] = "Vender basura"
L["settings:sellJunkTooltip"] = "Vender automáticamente todos los objetos de calidad pobre (gris) al visitar un vendedor"
L["settings:limitBatch"] = "Limitar lote a 12"
L["settings:limitBatchTooltip"] = "Vender como máximo 12 objetos por clic para evitar la limitación del servidor"
L["settings:sellEquipment"] = "Vender equipo"
L["settings:sellEquipmentTooltip"] =
"Permitir la venta de armaduras y armas. Con esto desactivado, nunca se vende ningún equipo"
L["settings:ilvlThreshold"] = "Margen de nivel de objeto"
L["settings:ilvlThresholdTooltip"] =
"Cuántos niveles de objeto por debajo del objeto equipado en esa ranura puede estar una pieza y aun así conservarse"
L["settings:marginOnHigherQuality"] = "  Aplicar margen a calidad superior"
L["settings:marginOnHigherQualityTooltip"] =
"Aplicar el margen al equipo de calidad superior a la que tienes equipada. Con esto desactivado, cualquier mejora de calidad se conserva sin importar su nivel de objeto"
L["settings:marginOnSameQuality"] = "  Aplicar margen a la misma calidad"
L["settings:marginOnSameQualityTooltip"] =
"Aplicar el margen al equipo de la misma calidad que el que tienes equipado. Con esto desactivado, solo se conserva el equipo igual o superior a tu nivel de objeto equipado"
L["settings:marginOnLowerQuality"] = "  Aplicar margen a calidad inferior"
L["settings:marginOnLowerQualityTooltip"] =
"Aplicar el margen al equipo de calidad inferior a la que tienes equipada. Con esto desactivado, cualquier reducción de calidad se vende sin importar su nivel de objeto. El equipo con dos o más calidades por debajo nunca recibe el margen"
L["settings:keepBindOnAccount"] = "Conservar vinculados a cuenta"
L["settings:keepBindOnAccountTooltip"] = "Conservar el equipo vinculado a cuenta (reliquia)"
L["settings:keepBindOnAccountPastExpac"] = "  Incluir expansiones anteriores"
L["settings:keepBindOnAccountPastExpacTooltip"] = "También conservar el equipo vinculado a cuenta de expansiones anteriores"
L["settings:keepDisenchantables"] = "Conservar desencantables"
L["settings:keepDisenchantablesTooltip"] = "Encantadores: conservar equipo BOP/BOE/BOA. Otros: conservar equipo BOE/BOA para la Casa de subastas o alts"
L["settings:keepDisenchantablesPastExpac"] = "  Incluir expansiones anteriores"
L["settings:keepDisenchantablesPastExpacTooltip"] = "También conservar el equipo desencantable de expansiones anteriores"
L["settings:keepUsedReagents"] = "Conservar reagentes de tus profesiones"
L["settings:keepUsedReagentsTooltip"] = "Conservar reagentes de artesanía que pueda usar cualquier profesión de esta cuenta"
L["settings:materialsMode"] = "Materiales de fabricación"
L["settings:materialsModeTooltip"] =
"Qué hacer con reactivos, materiales comerciales, gemas, encantamientos y recetas"
L["settings:materialsExpansion"] = "  Conservar desde la expansión"
L["settings:materialsExpansionTooltip"] =
"Conservar los materiales desde esta expansión en adelante y vender los más antiguos. Se usa solo cuando Materiales de fabricación está configurado para conservar desde una expansión elegida"
L["settings:otherMode"] = "Consumibles y otros"
L["settings:otherModeTooltip"] =
"Qué hacer con consumibles, contenedores, mascotas de combate, equipo de profesión y decoración de vivienda"

-- Sell modes
L["mode:keepAll"] = "Conservar todo"
L["mode:keepCurrent"] = "Conservar expansión actual"
L["mode:keepFrom"] = "Conservar desde la expansión"
L["mode:sellAll"] = "Vender todo"

-- List tabs
L["btn:removeEntry"] = "Quitar"
L["list:warband"] = "Grupo de Guerra"
L["list:character"] = "Personaje"
L["status:listEmpty"] = "Esta lista está vacía"
L["status:listCount"] = "%d entradas"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Venta masiva: se venderá"
L["verdict:keep"] = "Venta masiva: se conservará"
L["reason:TEMP_EXCLUDED"] = "Excluido para esta visita al vendedor"
L["reason:BLACKLISTED"] = "En tu lista negra"
L["reason:LOCKED"] = "El objeto está bloqueado"
L["reason:EQUIPMENT_SET"] = "Forma parte de un conjunto de equipo"
L["reason:NO_SELL_PRICE"] = "Ningún vendedor lo comprará"
L["reason:REFUNDABLE"] = "Aún dentro de su plazo de reembolso"
L["reason:WHITELISTED"] = "En tu lista blanca"
L["reason:TEMP_INCLUDED"] = "Añadido para esta visita al vendedor"
L["reason:CATEGORY"] = "Este tipo de objeto está configurado para conservarse"
L["reason:CURRENT_EXPANSION"] = "Proviene de una expansión que estás conservando"
L["reason:BIND_ON_ACCOUNT"] = "El equipo vinculado a cuenta se conserva"
L["reason:DISENCHANTABLE"] = "Vale la pena conservarlo para desencantar o revender"
L["reason:REAGENT_WANTED"] = "Una profesión de esta cuenta usa esto"
L["reason:EQUIPPABLE"] = "Suficientemente bueno frente a tu equipo actual"
L["reason:OUTCLASSED"] = "Superado por tu equipo actual"
L["reason:SELL_MODE"] = "Este tipo de objeto está configurado para venderse"
L["reason:DEFAULT"] = "Ninguna regla lo reclamó, así que se conserva"

-- Expansion labels
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
L["expansion:midnight"] = "Medianoche"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Restablecer lista negra del Grupo de Guerra"
L["listReset:warbandWhitelist"] = "Restablecer lista blanca del Grupo de Guerra"
L["listReset:charBlacklist"] = "Restablecer lista negra del personaje"
L["listReset:charWhitelist"] = "Restablecer lista blanca del personaje"
L["listReset:confirm"] = "¿Seguro que quieres vaciar esta lista? Esta acción no se puede deshacer."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "No se puede vender %s ahora mismo: %s"
L["msg:dropUnexcluded"] = "%s ya no está excluido y se venderá en esta visita"

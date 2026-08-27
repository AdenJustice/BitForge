if GetLocale() ~= "esMX" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

L["panel:batchSell"] = "Venta por lotes"
L["panel:sellManifest"] = "Manifiesto de venta"
L["panel:blacklist"] = "Lista negra"
L["panel:whitelist"] = "Lista blanca"

L["ui:ruleWindowTitle"] = "Reglas de venta por lotes"
L["ui:ruleWindowNothingToConfigure"] = "Aquí no hay nada que configurar."
L["ui:ruleWindowDisclaimer"] =
"En combate y dentro de instancias, el juego a veces no revela los detalles de un objeto. BatchSell conserva esos objetos en lugar de suponer, así que es posible que falten algunos en la lista -- eso es normal. Un veredicto que se vea incorrecto por cualquier otro motivo vale la pena reportarlo."
L["ui:selectedCount"] = "Selección: %d"

L["btn:sellAll"] = "Vender todo"
L["btn:refresh"] = "Actualizar"
L["btn:rules"] = "Reglas"

L["menu:temporaryExclude"] = "Excluir temporalmente"
L["menu:blacklisted"] = "Lista negra"
L["menu:whitelisted"] = "Lista blanca"
L["menu:noStatus"] = "Ninguna"
L["menu:reportVerdict"] = "Reportar este veredicto"

L["status:noItemsToSell"] = "No hay objetos para vender"
L["status:itemsTotal"] = "%d objetos  |  Total: %s"

L["ui:manifestHint"] = "¿Esperabas algo que no aparece en la lista? Pasa el cursor sobre él en tus bolsas para ver por qué."

-- Merchant row
L["tooltip:charOverride"] =
"La configuración de este personaje anula la lista de tropa: este objeto se venderá."

L["section:general"] = "General"
L["section:lists"] = "Listas"
L["section:everyItem"] = "Todos los objetos"
L["section:byItemType"] = "Por tipo de objeto"

L["settings:openRuleWindow"] = "Ver reglas"
L["settings:openRuleWindowTooltip"] =
"Explica qué busca cada regla, y por qué se conservó o se vendió un objeto"
L["settings:sellJunk"] = "Vender chatarra"
L["settings:sellJunkTooltip"] = "Vende automáticamente todos los objetos de calidad pobre (gris) al visitar un vendedor"
L["settings:limitBatch"] = "Limitar lote a 12"
L["settings:limitBatchTooltip"] = "Vende como máximo 12 objetos por clic para evitar la limitación del servidor"
L["settings:keepUsedReagents"] = "Conservar componentes de tus profesiones"
L["settings:keepUsedReagentsTooltip"] =
"Conservar componentes de artesanía que pueda usar una profesión de esta cuenta. Un objeto vinculado al alma nunca llega a otro personaje, así que solo lo conservan las profesiones de este personaje"
L["settings:margin"] = "Margen de nivel de objeto"
L["settings:marginTooltip"] =
"Qué tanto puede quedar una pieza de tu misma calidad por debajo de la ranura antes de que se venda. Con 0 basta con igualar la ranura"
L["settings:qualityMargin"] = "Margen de calidad"
L["settings:qualityMarginTooltip"] =
"Cuántos niveles de objeto vale un grado de calidad. Con 10, una pieza un grado por debajo de la que traes puesta necesita 10 niveles más para conservarse, y una un grado por encima sobrevive 10 por debajo. Con 0 la calidad deja de contar y solo decide el nivel de objeto. Con Siempre, cualquier calidad superior se conserva sea cual sea su nivel de objeto, y ningún nivel de objeto salva una inferior"
L["settings:qualityMarginAlways"] = "Siempre"
L["settings:keepForDisenchant"] = "Conservar equipo que vale la pena desencantar"
L["settings:keepForDisenchantTooltip"] =
"Conserva el equipo que un encantador podría desencantar, según lo que produciría. El equipo de una expansión terminada produce los materiales de esa expansión, por eso la elección trata sobre los materiales y no sobre el equipo. Tu propio encantador siempre conserva lo único que él puede alcanzar, sea cual sea este ajuste -- pero este ajuste sigue decidiendo si eso se extiende también a materiales antiguos"
L["settings:spareBindOnAccount"] = "Perdonar equipo vinculado a la cuenta"
L["settings:spareBindOnAccountTooltip"] =
"Qué equipo vinculado a la cuenta conservar mientras todavía pueda pasar a otro personaje: el de esta expansión, todo, o ninguno"
L["settings:spareBindOnEquip"] = "Perdonar equipo vinculado al equipar"
L["settings:spareBindOnEquipTooltip"] =
"Qué equipo que se vincula al equiparlo conservar mientras todavía pueda llegar a otro personaje o a la casa de subastas: el de esta expansión, todo, o ninguno"
L["settings:reagentsCurrentOnly"] = "Solo componentes de esta expansión"
L["settings:reagentsCurrentOnlyTooltip"] =
"Limita la regla anterior a los componentes de la expansión actual. Una receta que pide una hierba de Classic la sigue pidiendo igual hoy, así que esto queda apagado a menos que prefieras no juntar componentes viejos"
L["settings:keepUncollectedCosmetic"] = "Conservar apariencias sin coleccionar"
L["settings:keepUncollectedCosmeticTooltip"] =
"Mantiene cualquier objeto cuya apariencia no hayas coleccionado. Vender una pieza normal la colecciona de todos modos, pero un objeto cosmético da su aspecto al usarlo: si lo vendes, esa apariencia se pierde para siempre"
L["settings:sellRelics"] = "Vender reliquias de Classic"
L["settings:sellRelicsTooltip"] =
"Vende ídolos, grimorios, tótems y sigilos, la ranura de reliquia que Cataclysm quitó. No son las reliquias de artefacto de Legion, que son gemas y solo comparten el número de subclase"
L["settings:gemsCurrent"] = "Conservar gemas de esta expansión"
L["settings:gemsCurrentTooltip"] =
"Mantiene las gemas de la expansión actual. Las más viejas pasan a las dos preguntas de abajo"
L["settings:gemsRecipesNow"] = "Conservar gemas actuales que pida una receta"
L["settings:gemsRecipesNowTooltip"] =
"Mantiene una gema de la expansión actual que alguna receta de profesión use como componente, sin importar de quién sea esa profesión. La pregunta va al catálogo de recetas, y una gema que nunca ha visto se mantiene en lugar de adivinarse"
L["settings:gemsRecipesOld"] = "Conservar gemas viejas que pida una receta"
L["settings:gemsRecipesOldTooltip"] =
"La misma pregunta para las gemas de expansiones pasadas. Lo que usan tus propias profesiones ya se mantiene en otro punto, así que esta columna es para las recetas de los demás"
L["settings:keepArtifactRelics"] = "Conservar reliquias de artefacto"
L["settings:keepArtifactRelicsTooltip"] =
"Mantiene las reliquias que se engarzaban en las armas artefacto de Legion. Desde Legion nada las usa, así que conviene apagarlo a menos que las colecciones"
L["settings:enhancementsKeepLast"] = "Conservar mejoras de la expansión anterior"
L["settings:enhancementsKeepLastTooltip"] =
"Mantiene las mejoras de objeto de la expansión inmediatamente anterior, para un personaje que todavía usa ese equipo. Solo se ofrece esa: nadie sube niveles por la anterior a ella"
L["settings:keepLearnable"] = "Conservar recetas que puedas aprender"
L["settings:keepLearnableTooltip"] =
"Mantiene una receta que este personaje todavía no aprende"
L["settings:keepTradeableRecipes"] = "Conservar recetas intercambiables"
L["settings:keepTradeableRecipesTooltip"] =
"Mantiene una receta todavía sin vincular, para que llegue a un alt o a la casa de subastas aunque este personaje ya la haya aprendido"
L["settings:sellCollectedMounts"] = "Vender monturas coleccionadas"
L["settings:sellCollectedMountsTooltip"] =
"Vende una montura que ya tienes, siempre que la copia esté vinculada al alma. Una sin vincular se mantiene diga lo que diga esta opción, porque todavía puede llegar a alguien"
L["settings:sellCollectedToys"] = "Vender juguetes coleccionados"
L["settings:sellCollectedToysTooltip"] =
"Vende un juguete que ya está en tu colección, en cuanto la copia de tus bolsas quede vinculada. Uno sin vincular se mantiene diga lo que diga tu colección, porque todavía puede llegar a alguien"
L["settings:sellCollectedPets"] = "Vender mascotas coleccionadas"
L["settings:sellCollectedPetsTooltip"] =
"Vende una mascota de batalla que ya tienes. Una que nunca has coleccionado no la vende esta regla en ninguna posición"
L["settings:sellHoliday"] = "Vender objetos de festividad"
L["settings:sellHolidayTooltip"] =
"Vende las fichas, disfraces y curiosidades que los eventos del mundo dejan en tus bolsas"
L["settings:sellMountEquipment"] = "Vender equipo de montura"
L["settings:sellMountEquipmentTooltip"] =
"Vende el equipo de montura. Solo una pieza aplica a toda la cuenta a la vez, así que las de repuesto en tus bolsas no hacen nada"
L["settings:sellCollectedDecor"] = "Vender decoración coleccionada"
L["settings:sellCollectedDecorTooltip"] =
"Vende la decoración de vivienda que tu catálogo ya tiene. Una pieza que nunca ha visto se mantiene, igual que otra para la que no se pudo leer el catálogo"
L["settings:keepTradeableDyes"] = "Conservar tintes intercambiables"
L["settings:keepTradeableDyesTooltip"] =
"Un tinte se gasta al aplicarlo y nunca se aprende, así que no hay colección a la cual preguntar. Lo que se pregunta es si esta copia todavía puede llegar a alguien: sin vincular se mantiene, vinculada se vende"
L["settings:spareProfessions"] = "Perdonar para estas profesiones"
L["settings:spareProfessionsTooltip"] =
"Conserva un material de comercio si alguna profesión marcada aquí pudiera usarlo como componente -- para un personaje secundario que todavía no la haya aprendido, o para la casa de subastas. Las profesiones de esta cuenta ya están cubiertas por Conservar componentes de tus profesiones"

L["spare:current"] = "Expansión actual"
L["spare:all"] = "Todo"
L["spare:none"] = "Ninguno"

L["materials:current"] = "Materiales actuales"
L["materials:all"] = "Cualquier material"
L["materials:none"] = "No conservar"

L["profession:FirstAid"] = "Primeros auxilios"
L["profession:Blacksmithing"] = "Herrería"
L["profession:Leatherworking"] = "Peletería"
L["profession:Alchemy"] = "Alquimia"
L["profession:Herbalism"] = "Herboristería"
L["profession:Cooking"] = "Cocina"
L["profession:Mining"] = "Minería"
L["profession:Tailoring"] = "Sastrería"
L["profession:Engineering"] = "Ingeniería"
L["profession:Enchanting"] = "Encantamiento"
L["profession:Fishing"] = "Pesca"
L["profession:Skinning"] = "Desuello"
L["profession:Jewelcrafting"] = "Joyería"
L["profession:Inscription"] = "Inscripción"
L["profession:Archaeology"] = "Arqueología"

L["sub:0"] = "Genérico"
L["sub:1"] = "Poción"
L["sub:2"] = "Elixir"
L["sub:3"] = "Filtros y viales"
L["sub:5"] = "Comida y bebida"
L["sub:7"] = "Venda"
L["sub:8"] = "Otro"
L["sub:9"] = "Runa de Vantus"

L["option:current"] = "Conservar todo de esta expansión"
L["option:lastExpansion"] = "Y de la anterior, mientras subes de nivel ahí"
L["option:recipesNow"] = "Conservar los de esta expansión salvo que ninguna receta los pida"
L["option:recipesOld"] = "Conservar los más antiguos salvo que ninguna receta los pida"

-- List tabs
L["btn:removeEntry"] = "Quitar"
L["list:warband"] = "Tropa"
L["list:character"] = "Personaje"
L["status:listEmpty"] = "Esta lista está vacía"
L["status:listCount"] = "%d entradas"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Venta por lotes: se venderá"
L["verdict:keep"] = "Venta por lotes: se conservará"
L["reason:TEMP_EXCLUDED"] = "Excluido para esta visita al vendedor"
L["reason:BLACKLISTED"] = "En tu lista negra"
L["reason:LOCKED"] = "El objeto está bloqueado"
L["reason:EQUIPMENT_SET"] = "Forma parte de un conjunto de equipo"
L["reason:NO_SELL_PRICE"] = "Ningún vendedor lo comprará"
L["reason:REFUNDABLE"] = "Aún dentro de su plazo de reembolso"
L["reason:WHITELISTED"] = "En tu lista blanca"
L["reason:TEMP_INCLUDED"] = "Agregado para esta visita al vendedor"
L["reason:JUNK"] = "«Vender chatarra» está desactivado, la chatarra no se toca"
L["reason:JUNK_SOLD"] = "«Vender chatarra» está activado, la chatarra se vende"
L["reason:ABOVE_EPIC"] = "Mejor que épico, así que nunca se vende"
L["reason:BIND_ON_ACCOUNT"] = "El equipo vinculado a la cuenta se conserva"
L["reason:DISENCHANTABLE"] = "Vale la pena conservarlo para desencantar o revender"
L["reason:BAG_KEPT"] = "Las bolsas nunca se venden"
L["reason:PROFESSION_GEAR_KEPT"] = "El equipo de profesión nunca se vende"
L["reason:ENHANCEMENT_CURRENT"] = "Las mejoras de objeto de esta expansión se conservan"
L["reason:ENHANCEMENT_LAST_EXPANSION"] = "Las mejoras de objeto de la expansión anterior se conservan"
L["reason:ENHANCEMENT_OUTDATED"] = "Las mejoras de objeto de expansiones anteriores se venden"
L["reason:CONSUMABLE_CURRENT"] = "Los consumibles de esta expansión se conservan"
L["reason:CONSUMABLE_LAST_EXPANSION"] = "Los consumibles de la expansión anterior se conservan"
L["reason:CONSUMABLE_REAGENT"] = "Alguna receta usa esto como componente"
L["reason:GEM_CURRENT"] = "Las gemas de esta expansión se conservan"
L["reason:GEM_REAGENT"] = "Alguna receta usa esto como componente"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "Las reliquias de artefacto se conservan"
L["reason:TRADE_GOOD_SPARED"] = "Una profesión que decidiste perdonar quiere esto"
L["reason:NOT_WANTED"] = "Ninguna casilla conserva el objeto, así que se vende"
L["reason:REAGENT_WANTED"] = "Una profesión que puede usarlo lo quiere como componente"
L["reason:NOT_EQUIPPABLE"] = "No equipable o no recomendado para tu clase"
L["reason:EQUIPPABLE"] = "Suficientemente bueno frente a tu equipo actual"
L["reason:OUTCLASSED"] = "Superado por tu equipo actual"
L["reason:OUTDATED_EXPAC"] = "Supera a tu equipo actual, que es de la expansión anterior"
L["reason:BIND_ON_EQUIP"] = "El equipo que se vincula al equiparlo se conserva"
L["reason:ARMOR_RELIC"] = "Ya nadie puede equipar una reliquia, así que se vende"
L["reason:RECIPE_LEARNABLE"] = "Aún no aprendida, así que se conserva"
L["reason:HOLIDAY_ITEM"] = "Los objetos de festividad se venden"
L["reason:MOUNT_EQUIPMENT"] = "El equipo de montura se vende"
L["reason:ALREADY_COLLECTED"] = "El objeto ya está coleccionado, así que se vende"
L["reason:NOT_COLLECTED"] = "El objeto aún no está coleccionado, así que se conserva"
L["reason:STILL_TRADEABLE"] = "El objeto aún se puede comerciar, así que se conserva"
L["reason:ALREADY_LEARNED"] = "El objeto ya está aprendido, así que se vende"
L["reason:DEFAULT"] = "Ninguna regla lo reclamó, así que se conserva"

L["listReset:warbandBlacklist"] = "Restablecer lista negra de tropa"
L["listReset:warbandWhitelist"] = "Restablecer lista blanca de tropa"
L["listReset:charBlacklist"] = "Restablecer lista negra del personaje"
L["listReset:charWhitelist"] = "Restablecer lista blanca del personaje"
L["listReset:confirm"] = "¿Estás seguro de que quieres borrar esta lista? Esta acción no se puede deshacer."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "No se puede vender %s en este momento: %s"
L["msg:dropUnexcluded"] = "%s ya no está excluido y se venderá en esta visita"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "Bloqueado temporalmente"
L["rule:tempSub"] = "Solo para esta visita al vendedor"
L["rule:tempBlurb"] =
"Objetos que quitaste de la lista de venta antes de presionar Vender. Se quedan en tus bolsas durante esta visita y se evalúan de nuevo con normalidad en el siguiente vendedor."
L["rule:black"] = "Nunca vender"
L["rule:blackSub"] = "Tu lista de nunca vender"
L["rule:blackBlurb"] =
"Todo lo que esté en tu lista de nunca vender se queda en tus bolsas. Un ajuste de este personaje tiene prioridad sobre la lista de tropa, sin importar en qué sentido discrepen."
L["rule:gates"] = "No se pueden vender"
L["rule:gatesSub"] = "El vendedor no los acepta"
L["rule:gatesBlurb"] =
"Objetos bloqueados, cualquier cosa que forme parte de un conjunto de equipo, objetos sin precio de venta y compras que todavía están dentro de su plazo de reembolso. Tu lista de vender siempre no anula esto, porque el vendedor rechazaría la venta de cualquier forma."
L["rule:white"] = "Vender siempre"
L["rule:whiteSub"] = "Tu lista de vender siempre"
L["rule:whiteBlurb"] =
"Todo lo que esté en tu lista de vender siempre se vende, incluso cuando una regla posterior lo habría conservado. Así es como vendes ese componente de artesanía en particular que no quieres."
L["rule:tempIn"] = "Incluido en esta visita"
L["rule:tempInSub"] = "Solo para esta visita al vendedor"
L["rule:tempInBlurb"] =
"Objetos que arrastraste a la lista de venta con este vendedor. Se venden en esta visita y se evalúan de nuevo con normalidad en la siguiente."
L["rule:junk"] = "Calidad pobre"
L["rule:junkSub"] = "Desactivado de forma predeterminada"
L["rule:junkBlurb"] =
"Objetos grises, sea cual sea su tipo. Desactivado de forma predeterminada, porque normalmente otro addon ya se encarga de esto. Si ningún otro lo hace, actívalo y BatchSell los eliminará por ti."
L["rule:epic"] = "Legendario y superior"
L["rule:epicSub"] = "Legendaria, Artefacto, Reliquia"
L["rule:epicBlurb"] =
"Nunca se vende. El vendedor muestra un precio para estos y luego rechaza la venta, así que BatchSell no los pone en la lista."
L["rule:reagent"] = "Componentes de artesanía"
L["rule:reagentSub"] = "Usa tu lista de profesiones"
L["rule:reagentBlurb"] =
"Conserva cualquier componente que pueda usar una profesión de esta cuenta, sea cual sea el tipo de objeto. Los componentes aparecen tanto en pociones como en gemas y materiales de comercio, así que esto se revisa antes que el tipo de objeto. La lista se lee de las recetas del propio juego, así que ya trae los componentes opcionales que acepta una receta y todos sus niveles de calidad -- no tienes que abrir ni escanear nada."
L["rule:cosmetic"] = "Apariencias sin coleccionar"
L["rule:cosmeticSub"] = "Objetos cosméticos que todavía no has coleccionado"
L["rule:cosmeticBlurb"] =
"Un objeto cosmético que no has coleccionado se conserva. Venderlo no colecciona su apariencia -- simplemente desaparece --, así que este es el único lugar de la ventana donde un error no se puede deshacer. Un cosmético que ya coleccionaste no se vende solo por serlo; sencillamente ya no le queda nada que proteger, y pasa a evaluarse como el arma o la pieza de armadura que es."
L["rule:consumables"] = "Consumibles"
L["rule:consumablesSub"] = "Pociones, comida, pergaminos, objetos curiosos"
L["rule:consumablesBlurb"] =
"Elige qué conservar de cada tipo de consumible. Todo lo que ninguna casilla conserve se vende. Las pociones, elixires, filtros y la comida reciben una opción más -- también los de la expansión anterior --, que solo aplica mientras conservas los de esta expansión."
L["rule:bags"] = "Bolsas"
L["rule:bagsSub"] = "Contenedores de todo tipo"
L["rule:bagsBlurb"] =
"Nunca se venden. Qué bolsas llevas es decisión tuya, así que BatchSell no las evalúa."
L["rule:gear"] = "Armas y armadura"
L["rule:gearSub"] = "Se evalúan frente a lo que traes equipado"
L["rule:gearBlurb"] =
"Un solo conjunto de ajustes evalúa ambas cosas. Cada arma y cada pieza de armadura pasa por las preguntas de abajo en orden, y la primera que responde Conservar decide."
L["rule:gems"] = "Gemas"
L["rule:gemsSub"] = "Engarces y reliquias de artefacto"
L["rule:gemsBlurb"] =
"Un solo conjunto de opciones para cada gema. Las reliquias de artefacto tienen su propia opción abajo, porque nada más sobre el tipo de una gema cambia si vale la pena conservarla."
L["rule:tradeGoods"] = "Materiales de comercio"
L["rule:tradeGoodsSub"] = "Materiales de artesanía por profesión"
L["rule:tradeGoodsBlurb"] =
"Elige de quién conservar los componentes. Todo lo que no perdones se vende -- aunque un componente que tus propias profesiones usen de verdad ya lo conserva la regla Componentes de artesanía de arriba."
L["rule:enhancements"] = "Mejoras de objeto"
L["rule:enhancementsSub"] = "Encantamientos, aceites, piedras"
L["rule:enhancementsBlurb"] =
"Una nueva expansión limita el equipo al que se pueden aplicar, así que las antiguas dejan de valer nada. Las de esta expansión se conservan, y las de la expansión anterior también, si así lo quieres."
L["rule:recipes"] = "Recetas"
L["rule:recipesSub"] = "Patrones, planos, fórmulas"
L["rule:recipesBlurb"] =
"Cada receta trae consigo la profesión a la que pertenece, así que se evalúa en cuanto aparece ante el vendedor. Una receta que no pertenece a ninguna profesión en concreto -- un patrón o un manual genérico -- se deja intacta, porque no hay nada con qué evaluarla."
L["rule:misc"] = "Varios"
L["rule:miscSub"] = "Mascotas, monturas, juguetes, objetos de festividad"
L["rule:miscBlurb"] =
"Los componentes de hechizos se dejan intactos. Entre las cosas sin categorizar, solo se juzga un juguete: se vende en cuanto ya está en tu colección y la copia de tus bolsas queda vinculada. Los objetos grises los gestiona la regla Calidad pobre de arriba, no esta."
L["rule:profession"] = "Equipo de profesión"
L["rule:professionSub"] = "Herramientas y accesorios"
L["rule:professionBlurb"] =
"Nunca se vende. Los intercambiables valen dinero, y los vinculados los fabricaste para ti mismo o los estás usando ahora mismo, así que no hay ningún caso en el que sea correcto venderlos."
L["rule:housing"] = "Vivienda"
L["rule:housingSub"] = "Decoración y tintes"
L["rule:housingBlurb"] =
"Una vez que una decoración ya está coleccionada, el objeto en sí ya no tiene más utilidad, así que puede ir al vendedor. Un tinte no es ese tipo de cosa en absoluto: es un consumible de un solo uso que se gasta al aplicarlo, así que no hay nada que coleccionar ni nada que se haya podido aprender. Tampoco se vincula nunca, así que la única pregunta que vale la pena hacerse es si todavía puede llegar a alguien que lo quiera."
L["rule:none"] = "Todo lo demás"
L["rule:noneSub"] = "Objetos de misión, llaves, glifos, vales"
L["rule:noneBlurb"] =
"Tipos de objeto que BatchSell no evalúa en absoluto: objetos de misión, llaves, mascotas enjauladas, glifos, vales de WoW, componentes de hechizos, flechas y las demás categorías retiradas. Se quedan en tus bolsas sin importar cómo estén configuradas las reglas de arriba."

-- The report window's footnote. What BatchSell discloses is not what Openables
-- discloses, so each module states its own.
L["report:blurb"] = "Este reporte incluye el vínculo del objeto, lo que traigas puesto en la ranura que ocuparía, y los ajustes que evaluaron el par. Un vínculo de objeto indica el nivel y la especialización de tu personaje -- eso es parte del propio formato del vínculo, y quitarlo perdería el detalle que hace reproducible el reporte. Nada aquí nombra a tu personaje, tu reino, tu hermandad o tu facción, y nada describe ninguna otra ranura."

-- The disenchant scan's own footnote: it discloses several bag items and
-- their tooltips, not the single item/link pair report:blurb describes.
L["report:blurbDisenchant"] = "Este reporte incluye hasta ocho armas o piezas de armadura de tus bolsas que podrían valer la pena desencantar, junto con su bolsa y ranura y el texto completo de su tooltip. Nada aquí nombra a tu personaje, tu reino, tu hermandad o tu facción, y nada más en tus bolsas se describe."

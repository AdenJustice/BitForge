if GetLocale() ~= "esMX" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Servicio de Paquetería de Cabotaje"
L["settings:enabled"] = "Activar UPS"
L["settings:enabledTooltip"] = "Guardar materiales de artesanía en el Banco de tropa de guerra al visitar un banco"
L["settings:previewMoves"] = "Previsualizar antes de guardar"
L["settings:previewMovesTooltip"] = "Mostrar una ventana de confirmación con todos los movimientos antes de guardar nada"
L["settings:onlyWantedReagents"] = "Depositar solo reactivos que puedas usar"
L["settings:onlyWantedReagentsTooltip"] = "Depositar solo reactivos con los que pueda trabajar una profesión de esta cuenta. Desactivado deposita todos, para la Casa de subastas"

L["btn:deposit"] = "Guardar"
L["btn:depositing"] = "Guardando… %d"

L["preview:title"] = "Confirmar depósito"
L["preview:summary"] = "%d objeto(s) en %d movimiento(s)"
L["preview:toWarband"] = "→ Banco de tropa de guerra"
L["preview:dontAskAgain"] = "No preguntar de nuevo"
L["btn:confirm"] = "Confirmar"
L["btn:cancel"] = "Cancelar"

L["msg:nothingToDo"] = "UPS: No hay nada que mover."
L["msg:done"] = "UPS: Listo. Se movieron %d objeto(s)."
L["msg:noVacancy"] = "UPS: El Banco de tropa de guerra está lleno."
L["msg:blockedCombat"] = "UPS: Detenido — estás en combate."
L["msg:blockedBankClosed"] = "UPS: Detenido — se cerró el banco."
L["msg:blockedCursor"] = "UPS: Detenido — traes algo en el cursor."
L["msg:blockedLocked"] = "UPS: Detenido — un objeto está bloqueado."
L["msg:moveFailed"] = "UPS: Detenido — un movimiento no se completó."
L["msg:openProfession"] = "UPS: Abre una vez tu ventana de %s para que UPS registre qué recetas conoces."

-- Curation window
L["curation:title"] = "UPS — Clasificación de objetos"
L["curation:open"] = "Clasificar objetos"
L["curation:search"] = "Buscar"
L["curation:filterDestination"] = "Cualquier destino"
L["curation:filterClass"] = "Cualquier tipo de objeto"
L["curation:source"] = "Fuente: %s"
L["curation:sourceBuiltIn"] = "Este personaje"
L["curation:count"] = "%d objeto(s)"
L["curation:unscanned"] = "Nunca se revisaron sus recetas: %s. Mientras tanto, toda receta de sus profesiones se considera necesaria y se guardará."
L["curation:heldBy"] = "En posesión de"
L["curation:overrideTooltip"] = "Tú elegiste este destino. Restablece el valor predeterminado para volver a seguir las reglas."

-- Destinations
L["dest:warband"] = "Banco de tropa de guerra"
L["dest:private"] = "Tu banco"
L["dest:privateOwned"] = "Tu banco (%s)"
L["dest:ignore"] = "No tocar"

-- Private destination
L["preview:toPrivate"] = "→ Tu banco"
L["preview:reclaim"] = "Banco de tropa de guerra → Tu banco"
L["msg:noVacancyPrivate"] = "UPS: Tu banco está lleno."
L["curation:privateTooltip"] = "Se guarda en el banco propio de un personaje en lugar del almacenamiento compartido. Sin un propietario elegido, lo reclama el primer personaje que visite un banco."

-- Target quantity
L["curation:targetSuffix"] = "conservar %d"
L["target:title"] = "Cantidad objetivo"
L["target:prompt"] = "¿Cuántos %s debe conservar cada propietario?"

-- Row menu
L["menu:resetToDefault"] = "Restablecer valor predeterminado"
L["menu:owners"] = "Propietarios"
L["menu:target"] = "Cantidad objetivo"
L["menu:targetNone"] = "Sin límite"
L["menu:targetOther"] = "Otra…"

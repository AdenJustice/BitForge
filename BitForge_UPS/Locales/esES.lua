if GetLocale() ~= "esES" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Servicio de Paquetería de Cabotaje"
L["settings:enabled"] = "Activar UPS"
L["settings:enabledTooltip"] = "Depositar materiales de artesanía en el Banco de tropa de guerra al visitar un banco"
L["settings:previewMoves"] = "Previsualizar antes de depositar"
L["settings:previewMovesTooltip"] = "Mostrar una ventana de confirmación con todos los movimientos antes de depositar nada"

L["btn:deposit"] = "Depositar"
L["btn:depositing"] = "Depositando… %d"

L["preview:title"] = "Confirmar depósito"
L["preview:summary"] = "%d objeto(s) en %d movimiento(s)"
L["preview:toWarband"] = "→ Banco de tropa de guerra"
L["preview:dontAskAgain"] = "No volver a preguntar"
L["btn:confirm"] = "Confirmar"
L["btn:cancel"] = "Cancelar"

L["msg:nothingToDo"] = "UPS: Nada que mover."
L["msg:done"] = "UPS: Hecho. %d objeto(s) movido(s)."
L["msg:noVacancy"] = "UPS: El Banco de tropa de guerra está lleno."
L["msg:blockedCombat"] = "UPS: Detenido — estás en combate."
L["msg:blockedBankClosed"] = "UPS: Detenido — el banco se ha cerrado."
L["msg:blockedCursor"] = "UPS: Detenido — llevas algo en el cursor."
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
L["curation:unscanned"] = "Nunca se analizaron sus recetas: %s. Hasta entonces, toda receta de sus profesiones se considera necesaria y se depositará."
L["curation:heldBy"] = "En poder de"
L["curation:overrideTooltip"] = "Tú elegiste este destino. Restablece el valor predeterminado para volver a seguir las reglas."

-- Destinations
L["dest:warband"] = "Banco de tropa de guerra"
L["dest:private"] = "Tu banco"
L["dest:privateOwned"] = "Tu banco (%s)"
L["dest:ignore"] = "Dejar en paz"

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

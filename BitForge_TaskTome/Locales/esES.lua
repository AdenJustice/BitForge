if GetLocale() ~= "esES" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

L["status:widgetTitle"] = "Tomo de tareas"

L["settings:configTitle"] = "Tomo de tareas — Configuración"
L["btn:addRootTask"] = "Añadir tarea raíz"
L["btn:addChildTask"] = "Añadir tarea secundaria"
L["btn:deleteTask"] = "Eliminar tarea"
L["btn:save"] = "Guardar"
L["settings:taskName"] = "Nombre"
L["settings:resetCycle"] = "Reinicio"
L["settings:warbandAssigned"] = "Asignada a todos los personajes"
L["settings:completionScope"] = "Ámbito de finalización"
L["settings:optState"] = "Mi asignación"

L["menu:resetNone"] = "Ninguno"
L["menu:resetDaily"] = "Diario"
L["menu:resetWeekly"] = "Semanal"
L["menu:scopeChar"] = "Personaje"
L["menu:scopeWarband"] = "Compartida — una finalización para toda la cuenta"
L["menu:optFollow"] = "Seguir valor predeterminado"
L["menu:optIn"] = "Mostrar siempre"
L["menu:optOut"] = "Ocultar siempre"

L["msg:deleteConfirm"] = "¿Eliminar '%s' y todas sus %d tareas secundarias?"
L["msg:deleteSingle"] = "¿Eliminar '%s'?"
L["btn:confirmDelete"] = "Eliminar"
L["btn:cancel"] = "Cancelar"
L["msg:nameRequired"] = "El nombre de la tarea no puede estar vacío."

L["settings:taskTomePanel"] = "Tomo de tareas"
L["settings:config"] = "Configuración"
L["settings:openConfig"] = "Abrir"

L["group:accountWide"] = "De toda la cuenta"
L["tooltip:scopeMe"] = "Mostrando este personaje. Haz clic para mostrar todos los personajes."
L["tooltip:scopeAll"] = "Mostrando todos los personajes. Haz clic para mostrar solo este personaje."
L["tooltip:orientByChar"] = "Agrupado por personaje. Haz clic para agrupar por tarea."
L["tooltip:orientByTask"] = "Agrupado por tarea. Haz clic para agrupar por personaje."
L["tooltip:openConfig"] = "Abre la ventana de configuración del Tomo de tareas."
L["tooltip:widgetLocked"] = "La ventana está bloqueada. Haz clic para desbloquearla y poder moverla y redimensionarla."
L["tooltip:widgetUnlocked"] = "La ventana está desbloqueada. Haz clic para bloquear su posición y tamaño."

L["settings:editingFor"] = "Editando para"
L["settings:optStateFor"] = "Asignación de %s"

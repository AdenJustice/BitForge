if GetLocale() ~= "esMX" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "Tomo de tareas"
L["btn:lockWidget"] = "Bloquear"
L["btn:unlockWidget"] = "Desbloquear"

-- Config Frame
L["settings:configTitle"] = "Tomo de tareas — Configuración"
L["btn:addRootTask"] = "Agregar tarea raíz"
L["btn:addChildTask"] = "Agregar subtarea"
L["btn:deleteTask"] = "Eliminar tarea"
L["btn:save"] = "Guardar"
L["settings:taskName"] = "Nombre"
L["settings:resetCycle"] = "Reinicio"
L["settings:warbandAssigned"] = "Asignada a todos los personajes"
L["settings:completionScope"] = "Alcance de finalización"
L["settings:optState"] = "Mi asignación"

-- Dropdowns
L["menu:resetNone"] = "Ninguno"
L["menu:resetDaily"] = "Diario"
L["menu:resetWeekly"] = "Semanal"
L["menu:scopeChar"] = "Personaje"
L["menu:scopeWarband"] = "Compartida — una finalización para toda la cuenta"
L["menu:optFollow"] = "Seguir predeterminado"
L["menu:optIn"] = "Mostrar siempre"
L["menu:optOut"] = "Ocultar siempre"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "¿Eliminar '%s' y las %d subtarea(s)?"
L["msg:deleteSingle"] = "¿Eliminar '%s'?"
L["btn:confirmDelete"] = "Eliminar"
L["btn:cancel"] = "Cancelar"
L["msg:nameRequired"] = "El nombre de la tarea no puede estar vacío."

-- Settings panel
L["settings:taskTomePanel"] = "Tomo de tareas"
L["settings:config"] = "Configuración"
L["settings:openConfig"] = "Abrir"

-- Widget modes
L["group:accountWide"] = "A nivel de cuenta"
L["tooltip:scopeMe"] = "Mostrando solo este personaje. Haz clic para mostrar todos los personajes."
L["tooltip:scopeAll"] = "Mostrando todos los personajes. Haz clic para mostrar solo este personaje."
L["tooltip:orientByChar"] = "Agrupado por personaje. Haz clic para agrupar por tarea."
L["tooltip:orientByTask"] = "Agrupado por tarea. Haz clic para agrupar por personaje."

-- Config
L["settings:editingFor"] = "Editando para"
L["settings:optStateFor"] = "Asignación de %s"

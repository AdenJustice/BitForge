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
L["settings:warbandAssigned"] = "Tarea del Grupo de Guerra"
L["settings:completionScope"] = "Alcance de finalización"
L["settings:optState"] = "Mi estado de participación"

-- Dropdowns
L["menu:resetNone"] = "Ninguno"
L["menu:resetDaily"] = "Diario"
L["menu:resetWeekly"] = "Semanal"
L["menu:scopeChar"] = "Personaje"
L["menu:scopeWarband"] = "Grupo de Guerra"
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

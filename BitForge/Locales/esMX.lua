if GetLocale() ~= "esMX" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "Clic izquierdo para opciones"
L["minimap:hintDrag"] = "Arrastra para mover"
L["minimap:compartmentTooltip"] = "Abrir el menú de BitForge"

L["msg:schemaResetBody"] = "Los datos guardados de %s son de una versión anterior y no se pueden conservar. Se borrarán y se reconstruirán. Esto ocurre una sola vez."
L["btn:schemaResetAccept"] = "Borrar y continuar"

L["cmd:usage"] = "/bitforge <módulo> [argumentos], /bfdump <módulo> [argumentos] -- un nombre de módulo puede acortarse a cualquier prefijo sin ambigüedad"
L["cmd:unknownModule"] = "no hay ningún módulo llamado %s -- usa /bitforge para ver la lista"
L["cmd:ambiguousModule"] = "%s nombra más de un módulo: %s"
L["cmd:noSuchCommand"] = "%s no responde al comando %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- muestra qué cambió en esta actualización"

L["report:windowTitle"] = "Reportar un objeto"
L["report:windowTitleDiagnostic"] = "Reporte de diagnóstico"
L["report:howTo"] = "Selecciona todo y presiona Ctrl+C. Pégalo en una incidencia nueva en:"
L["report:selectAll"] = "Seleccionar todo"
L["report:encoded"] = "Este reporte era demasiado largo para leerlo, así que se comprimió. Pégalo tal cual -- las herramientas del desarrollador lo descomprimirán."

L["whatsNew:windowTitle"] = "Novedades de BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Cerrar"

if GetLocale() ~= "esES" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Clic izquierdo para opciones"
L["minimap:hintDrag"] = "Arrastra para mover"
L["minimap:compartmentTooltip"] = "Abrir el menú de BitForge"

-- Schema upgrade
L["msg:schemaResetBody"] = "Los datos guardados de %s son de una versión anterior y no se pueden conservar. Se borrarán y se reconstruirán. Esto ocurre una sola vez."
L["btn:schemaResetAccept"] = "Borrar y continuar"

-- Slash commands
L["cmd:usage"] = "/bitforge <módulo> [argumentos], /bfdump <módulo> [argumentos] -- un nombre de módulo puede acortarse a cualquier prefijo inequívoco"
L["cmd:unknownModule"] = "ningún módulo se llama %s -- usa /bitforge para ver la lista"
L["cmd:ambiguousModule"] = "%s nombra más de un módulo: %s"
L["cmd:noSuchCommand"] = "%s no responde al comando %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- muestra qué cambió en esta actualización"

-- Report window
L["report:windowTitle"] = "Reportar un objeto"
L["report:howTo"] = "Selecciona todo y pulsa Ctrl+C. Pégalo en una incidencia nueva en:"
L["report:selectAll"] = "Seleccionar todo"

-- The release-notes popup
L["whatsNew:windowTitle"] = "Novedades de BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Cerrar"

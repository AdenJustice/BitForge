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

L["upgrade:windowTitle"] = "BitForge ahora son seis descargas"
L["upgrade:lead"] = "De ahora en adelante, BitForge y sus módulos son descargas separadas: un proyecto cada uno, que se actualiza por su cuenta. Actualizar BitForge no eliminó nada, así que todo lo que ya tenías sigue instalado y sigue funcionando."
L["upgrade:separate"] = "Estos ya no forman parte de la descarga de BitForge, y nada volverá a actualizarlos hasta que instales cada uno como su propio proyecto:"
L["upgrade:renamed"] = "BitForge Dispatch cambió de nombre a BitForge AzerothPrime, y es un proyecto propio con ese nombre. Instálalo y todo lo que Dispatch tenía guardado -- reglas, listas por objeto, destinos de depósito, listas negras, el tamaño y la posición del botón -- se va con él. Si el Dispatch anterior sigue instalado, AzerothPrime lo desactiva primero y tus ajustes llegan en tu siguiente inicio de sesión, así que ver Dispatch en gris en la lista de addons es lo esperado y no una falla; en ese momento ya puedes borrar la carpeta. Una cosa no se traslada: la asignación de teclas del botón de objetos abribles, que el juego guarda con el nombre del botón. Vuelve a asignarla en Asignación de teclas."
L["upgrade:close"] = "Entendido"

L["msg:outOfStep"] = "Actualiza %s desde CurseForge: va en %s mientras que BitForge va en %s. Ahora cada uno es su propia descarga, así que un gestor de addons puede actualizar uno y dejar el otro sin tocar."

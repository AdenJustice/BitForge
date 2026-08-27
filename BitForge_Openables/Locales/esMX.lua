if GetLocale() ~= "esMX" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Openables"
L["settings:enabled"] = "Activar Openables"
L["settings:enabledTooltip"] = "Muestra un botón para el siguiente objeto abrible o usable de tus bolsas"
L["settings:locked"] = "Bloquear botón"
L["settings:lockedTooltip"] = "Impide que el botón se pueda arrastrar"
L["settings:buttonSize"] = "Tamaño del botón"
L["settings:buttonSizeTooltip"] = "Ancho y alto del botón, en píxeles"
L["settings:showCount"] = "Mostrar cantidad"
L["settings:showCountTooltip"] = "Muestra cuántas unidades del objeto llevas"
L["settings:showCooldown"] = "Mostrar reutilización"
L["settings:showCooldownTooltip"] = "Muestra el tiempo de reutilización en el botón"
L["settings:resetPosition"] = "Restablecer posición"
L["settings:manageBlacklist"] = "Administrar lista de exclusión"

L["tooltip:use"] = "Clic izquierdo para abrir o usar."
L["tooltip:skip"] = "Clic derecho para omitir durante esta sesión."
L["tooltip:blacklist"] = "Ctrl + clic derecho para excluir permanentemente."
L["tooltip:report"] = "Mayús + Alt + clic derecho para reportar este veredicto."
L["tooltip:drag"] = "Alt + arrastra para mover."

L["report:blurb"] = "Este reporte incluye el objeto, cómo lo clasificó BitForge, el texto de su tooltip y qué profesiones conoce este personaje. Nada aquí menciona tu personaje, reino, hermandad o facción."

L["report:blurbField"] = "Este reporte incluye cada candidato que el último análisis clasificó para abrir a continuación, en el orden clasificado: el nombre, el ID del objeto, la bolsa y la ranura, la cantidad apilada, la prioridad y el motivo de su posición, y si está bloqueado, en reutilización o aplazado. Nada aquí menciona tu personaje, reino, hermandad o facción, y no se incluye el texto del tooltip de ningún objeto."

L["blacklist:windowTitle"] = "Objetos excluidos"
L["blacklist:empty"] = "No hay objetos excluidos."
L["blacklist:remove"] = "Quitar"
L["blacklist:clearAll"] = "Borrar todo"
L["blacklist:unknownItem"] = "Objeto %d"

L["binding:header"] = "BitForge Openables"
L["binding:use"] = "Usar objeto abrible"

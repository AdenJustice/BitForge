---@class BitForge.Openables
local ns = select(2, ...)
if GetLocale() ~= "esES" then return end
local L = ns.locale

-- Settings panel
L["panel:title"] = "Aperturas"
L["settings:enabled"] = "Activar Aperturas"
L["settings:enabledTooltip"] = "Muestra un botón para el siguiente objeto abrible o usable de tus bolsas"
L["settings:locked"] = "Bloquear botón"
L["settings:lockedTooltip"] = "Impide que el botón se pueda arrastrar"
L["settings:buttonSize"] = "Tamaño del botón"
L["settings:buttonSizeTooltip"] = "Anchura y altura del botón, en píxeles"
L["settings:showCount"] = "Mostrar cantidad"
L["settings:showCountTooltip"] = "Muestra cuántas unidades del objeto llevas"
L["settings:showCooldown"] = "Mostrar reutilización"
L["settings:showCooldownTooltip"] = "Muestra el tiempo de reutilización en el botón"
L["settings:resetPosition"] = "Restablecer posición"
L["settings:manageBlacklist"] = "Gestionar lista de exclusión"

-- Button tooltip
L["tooltip:use"] = "Clic izquierdo para abrir o usar."
L["tooltip:skip"] = "Clic derecho para omitir durante esta sesión."
L["tooltip:blacklist"] = "Ctrl + clic derecho para excluir permanentemente."
L["tooltip:drag"] = "Alt + arrastra para mover."

-- Blacklist
L["blacklist:windowTitle"] = "Objetos excluidos"
L["blacklist:empty"] = "No hay objetos excluidos."
L["blacklist:remove"] = "Quitar"
L["blacklist:clearAll"] = "Borrar todo"
L["blacklist:unknownItem"] = "Objeto %d"

-- Key bindings
L["binding:header"] = "BitForge Aperturas"
L["binding:use"] = "Usar objeto abrible"

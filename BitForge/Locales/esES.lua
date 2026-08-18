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

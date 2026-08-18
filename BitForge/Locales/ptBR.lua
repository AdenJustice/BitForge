if GetLocale() ~= "ptBR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Clique esquerdo para opções"
L["minimap:hintDrag"] = "Arraste para mover"
L["minimap:compartmentTooltip"] = "Abrir o menu do BitForge"

-- Schema upgrade
L["msg:schemaResetBody"] = "Os dados salvos de %s são de uma versão anterior e não podem ser mantidos. Eles serão apagados e reconstruídos. Isso acontece apenas uma vez."
L["btn:schemaResetAccept"] = "Apagar e continuar"

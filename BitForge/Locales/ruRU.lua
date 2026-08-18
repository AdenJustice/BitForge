if GetLocale() ~= "ruRU" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Левый клик — параметры"
L["minimap:hintDrag"] = "Перетащите, чтобы переместить"
L["minimap:compartmentTooltip"] = "Открыть меню BitForge"

-- Schema upgrade
L["msg:schemaResetBody"] = "Сохранённые данные %s созданы в более старой версии и не могут быть перенесены. Они будут удалены и созданы заново. Это произойдёт один раз."
L["btn:schemaResetAccept"] = "Удалить и продолжить"

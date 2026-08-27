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

-- Slash commands
L["cmd:usage"] = "/bitforge <модуль> [аргументы], /bfdump <модуль> [аргументы] -- имя модуля можно сократить до любого однозначного префикса"
L["cmd:unknownModule"] = "модуль с именем %s не найден -- список выводит /bitforge"
L["cmd:ambiguousModule"] = "%s соответствует нескольким модулям: %s"
L["cmd:noSuchCommand"] = "%s не отвечает на команду %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- показывает, что изменилось в этом обновлении"

-- Report window
L["report:windowTitle"] = "Сообщить о предмете"
L["report:howTo"] = "Выберите всё, затем нажмите Ctrl+C. Вставьте это в новый тикет на:"
L["report:selectAll"] = "Выбрать всё"

-- The release-notes popup
L["whatsNew:windowTitle"] = "Что нового в BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Закрыть"

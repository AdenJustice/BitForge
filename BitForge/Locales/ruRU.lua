if GetLocale() ~= "ruRU" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "Левый клик — настройки"
L["minimap:hintDrag"] = "Перетащите, чтобы переместить"
L["minimap:compartmentTooltip"] = "Открыть меню BitForge"

L["msg:schemaResetBody"] = "Сохранённые данные %s созданы в более старой версии и не могут быть перенесены. Они будут удалены и созданы заново. Это произойдёт один раз."
L["btn:schemaResetAccept"] = "Удалить и продолжить"

L["cmd:usage"] = "/bitforge <модуль> [аргументы], /bfdump <модуль> [аргументы] -- имя модуля можно сократить до любого однозначного префикса"
L["cmd:unknownModule"] = "модуль с именем %s не найден -- список выводит /bitforge"
L["cmd:ambiguousModule"] = "%s соответствует нескольким модулям: %s"
L["cmd:noSuchCommand"] = "%s не отвечает на команду %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- показывает, что изменилось в этом обновлении"

L["report:windowTitle"] = "Сообщить о предмете"
L["report:windowTitleDiagnostic"] = "Диагностический отчёт"
L["report:howTo"] = "Выберите всё, затем нажмите Ctrl+C. Вставьте это в новый тикет на:"
L["report:selectAll"] = "Выбрать всё"
L["report:encoded"] = "Этот отчёт был слишком длинным для чтения, поэтому он был сжат. Вставьте его как есть -- инструменты разработчика распакуют его."

L["whatsNew:windowTitle"] = "Что нового в BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Закрыть"

if GetLocale() ~= "ruRU" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Openables"
L["settings:enabled"] = "Включить «Openables»"
L["settings:enabledTooltip"] = "Показывать кнопку для следующего открываемого или используемого предмета в сумках"
L["settings:locked"] = "Закрепить кнопку"
L["settings:lockedTooltip"] = "Запретить перетаскивание кнопки"
L["settings:buttonSize"] = "Размер кнопки"
L["settings:buttonSizeTooltip"] = "Ширина и высота кнопки в пикселях"
L["settings:showCount"] = "Показывать количество"
L["settings:showCountTooltip"] = "Показывать, сколько предметов у вас с собой"
L["settings:showCooldown"] = "Показывать восстановление"
L["settings:showCooldownTooltip"] = "Показывать время восстановления на кнопке"
L["settings:resetPosition"] = "Сбросить положение"
L["settings:manageBlacklist"] = "Управление списком исключений"

L["tooltip:use"] = "Левый щелчок — открыть или использовать."
L["tooltip:skip"] = "Правый щелчок — пропустить до конца сеанса."
L["tooltip:blacklist"] = "Ctrl + правый щелчок — исключить навсегда."
L["tooltip:report"] = "Shift + Alt + правый щелчок — сообщить об этом решении."
L["tooltip:drag"] = "Alt + перетащите, чтобы переместить."

L["report:blurb"] = "Этот отчёт содержит предмет, то, как BitForge его классифицировал, текст его подсказки и какие профессии знает этот персонаж. Здесь не упоминаются ваш персонаж, сервер, гильдия или фракция."

L["report:blurbField"] = "Этот отчёт содержит каждого кандидата, которого последнее сканирование ранжировало для следующего открытия, в порядке ранжирования: имя, ID предмета, сумку и слот, количество в стопке, приоритет и причину такого места в списке, а также заблокирован ли он, находится ли на восстановлении или отложен. Здесь не упоминаются ваш персонаж, сервер, гильдия или фракция, и текст подсказки ни одного предмета не включён."

L["blacklist:windowTitle"] = "Исключённые предметы"
L["blacklist:empty"] = "Нет исключённых предметов."
L["blacklist:remove"] = "Убрать"
L["blacklist:clearAll"] = "Очистить всё"
L["blacklist:unknownItem"] = "Предмет %d"

L["binding:header"] = "BitForge Openables"
L["binding:use"] = "Использовать открываемый предмет"

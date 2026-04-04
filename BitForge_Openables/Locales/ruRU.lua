---@class BitForge.Openables
local ns = select(2, ...)
if GetLocale() ~= "ruRU" then return end
local L = ns.locale

-- Settings panel
L["panel:title"] = "Открываемое"
L["settings:enabled"] = "Включить «Открываемое»"
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

-- Button tooltip
L["tooltip:use"] = "Левый щелчок — открыть или использовать."
L["tooltip:skip"] = "Правый щелчок — пропустить до конца сеанса."
L["tooltip:blacklist"] = "Ctrl + правый щелчок — исключить навсегда."
L["tooltip:drag"] = "Alt + перетащите, чтобы переместить."

-- Blacklist
L["blacklist:windowTitle"] = "Исключённые предметы"
L["blacklist:empty"] = "Нет исключённых предметов."
L["blacklist:remove"] = "Убрать"
L["blacklist:clearAll"] = "Очистить всё"
L["blacklist:unknownItem"] = "Предмет %d"

-- Key bindings
L["binding:header"] = "BitForge Открываемое"
L["binding:use"] = "Использовать открываемый предмет"

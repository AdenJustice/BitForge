if GetLocale() ~= "ruRU" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Использовать настройки персонажа"
L["settings:useCharSettingsTooltip"] = "Переопределить общие настройки аккаунта значениями, специфичными для этого персонажа"

L["settings:desiredBalance"] = "Желаемый баланс"
L["settings:desiredBalanceTooltip"] = "Целевой баланс золота для поддержания в сумках"

L["settings:marginalRatio"] = "Предельное соотношение"
L["settings:marginalRatioTooltip"] = "Пропустить перебалансировку, если разница в пределах желаемого × соотношение"

L["settings:collectorCharacter"] = "Персонаж-сборщик"
L["settings:collectorCharacterTooltip"] = "Персонаж, собирающий излишки золота из банка отряда"

L["settings:none"] = "Нет"
L["settings:always"] = "Всегда"

L["msg:deposit"] = "Внесено %s в банк отряда"
L["msg:withdraw"] = "Снято %s из банка отряда"
L["msg:collect"] = "Получено %s из банка отряда"
L["msg:noFunds"] = "В банке отряда нет средств для снятия"

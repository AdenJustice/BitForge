if GetLocale() ~= "ruRU" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "Автобаланс"

L["settings:useCharSettings"] = "Настройки персонажа"
L["settings:useCharSettingsTooltip"] = "Переопределить общие настройки аккаунта значениями, специфичными для этого персонажа"

L["settings:desiredBalance"] = "Желаемый баланс"
L["settings:desiredBalanceTooltip"] = "Целевой баланс золота для поддержания в сумках"

L["settings:marginalRatio"] = "Предельное соотношение"
L["settings:marginalRatioTooltip"] = "Пропустить перебалансировку, если разница в пределах желаемого × соотношение"

L["settings:collectorCharacter"] = "Персонаж-сборщик"
L["settings:collectorCharacterTooltip"] = "Персонаж, собирающий излишки золота из Банка Военного союза"

L["settings:none"] = "Нет"
L["settings:always"] = "Всегда"

L["msg:deposit"] = "Внесено %s в Банк Военного союза"
L["msg:withdraw"] = "Снято %s из Банка Военного союза"
L["msg:collect"] = "Получено %s из Банка Военного союза"
L["msg:noFunds"] = "В Банке Военного союза нет средств для снятия"

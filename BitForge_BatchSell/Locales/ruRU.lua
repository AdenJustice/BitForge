if GetLocale() ~= "ruRU" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Массовая продажа"
L["panel:sellManifest"] = "Список продажи"
L["panel:blacklist"] = "Чёрный список"
L["panel:whitelist"] = "Белый список"

-- Buttons
L["btn:sellAll"] = "Продать всё"
L["btn:refresh"] = "Обновить"

-- Context menu
L["menu:addToBlacklist"] = "Добавить в чёрный список"
L["menu:addToWhitelist"] = "Добавить в белый список"
L["menu:addToBlacklistChar"] = "Добавить в чёрный список (Персонаж)"
L["menu:addToWhitelistChar"] = "Добавить в белый список (Персонаж)"
L["menu:clearCharOverride"] = "Убрать переопределение персонажа"
L["menu:resetListEntry"] = "Удалить из списка"
L["menu:temporaryExclude"] = "Временно исключить"

-- Status
L["status:noItemsToSell"] = "Нет предметов для продажи"
L["status:itemsTotal"] = "%d предм.  |  Итого: %s"

-- Merchant row
L["tooltip:charOverride"] =
"Настройка этого персонажа важнее списка Военного союза — этот предмет будет продан."

-- Settings
L["settings:sellJunk"] = "Продавать хлам"
L["settings:sellJunkTooltip"] = "Автоматически продавать все предметы низкого качества (серые) при посещении торговца"
L["settings:keepEquippable"] = "Сохранять надеваемые"
L["settings:keepEquippableTooltip"] = "Сохранять все предметы, доступные вашему классу"
L["settings:keepBindOnAccount"] = "Сохранять привязанные к аккаунту"
L["settings:keepBindOnAccountTooltip"] = "Сохранять предметы, привязанные к аккаунту (фамильные реликвии)"
L["settings:keepBindOnAccountPastExpac"] = "  Включить прошлые дополнения"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Также сохранять привязанные к аккаунту предметы из прошлых дополнений"
L["settings:keepDisenchantables"] = "Сохранять расплавляемые"
L["settings:keepDisenchantablesTooltip"] = "Чародеи: сохранять BOP/BOE/BOA экипировку. Остальные: сохранять BOE/BOA для АГ или альтов"
L["settings:keepDisenchantablesPastExpac"] = "  Включить прошлые дополнения"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Также сохранять расплавляемую экипировку из прошлых дополнений"
L["settings:limitBatch"] = "Ограничить пакет до 12"
L["settings:limitBatchTooltip"] = "Продавать не более 12 предметов за клик во избежание ограничений сервера"
L["settings:qualityThreshold"] = "Порог качества"
L["settings:qualityThresholdTooltip"] = "Продавать предметы данного качества и ниже"
L["settings:ilvlThreshold"] = "Запас уровня предмета"
L["settings:ilvlThresholdTooltip"] =
"Сохранять надеваемые предметы в пределах данного числа уровней от надетой экипировки (отрицательное = сохранять более качественные предметы)"
L["settings:sellPastExpansion"] = "Продавать предметы из прошлых дополнений"
L["settings:sellPastExpansionTooltip"] = "Продавать предметы из дополнений старше выбранного порога"
L["settings:expansionThreshold"] = "Порог дополнения"
L["settings:expansionThresholdTooltip"] = "Продавать предметы из дополнений, вышедших раньше выбранного"

-- Quality labels
L["quality:poor"] = "Низкое"
L["quality:common"] = "Обычное"
L["quality:uncommon"] = "Необычное"
L["quality:rare"] = "Редкое"
L["quality:epic"] = "Эпическое"

-- Expansion labels
L["expansion:all"] = "Все дополнения"
L["expansion:classic"] = "Classic"
L["expansion:burningCrusade"] = "Пылающий крестовый поход"
L["expansion:wrathOfTheLichKing"] = "Гнев Короля-лича"
L["expansion:cataclysm"] = "Катаклизм"
L["expansion:mistsOfPandaria"] = "Туман Пандарии"
L["expansion:warlordsOfDraenor"] = "Варлорды Дренора"
L["expansion:legion"] = "Легион"
L["expansion:battleForAzeroth"] = "Битва за Азерот"
L["expansion:shadowlands"] = "Темные земли"
L["expansion:dragonflight"] = "Возрождение Драконов"
L["expansion:theWarWithin"] = "Война изнутри"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Сбросить чёрный список Военного союза"
L["listReset:warbandWhitelist"] = "Сбросить белый список Военного союза"
L["listReset:charBlacklist"] = "Сбросить чёрный список персонажа"
L["listReset:charWhitelist"] = "Сбросить белый список персонажа"
L["listReset:confirm"] = "Вы уверены, что хотите очистить этот список? Отменить действие невозможно."

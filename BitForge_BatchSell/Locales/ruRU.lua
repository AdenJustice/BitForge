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

-- Section titles
L["section:general"] = "Общее"
L["section:equipment"] = "Экипировка"
L["section:materials"] = "Материалы для крафта"
L["section:other"] = "Расходники и другое"
L["section:lists"] = "Списки"

-- Settings
L["settings:sellJunk"] = "Продавать хлам"
L["settings:sellJunkTooltip"] = "Автоматически продавать все предметы низкого качества (серые) при посещении торговца"
L["settings:limitBatch"] = "Ограничить пакет до 12"
L["settings:limitBatchTooltip"] = "Продавать не более 12 предметов за клик во избежание ограничений сервера"
L["settings:sellEquipment"] = "Продавать экипировку"
L["settings:sellEquipmentTooltip"] =
"Разрешить продажу брони и оружия. Если выключено, экипировка никогда не продаётся"
L["settings:ilvlMargin"] = "Запас уровня предмета"
L["settings:ilvlMarginTooltip"] =
"Сколько уровней предмета стоит одна ступень редкости. При 10 вещь на ступень ниже надетой должна превзойти её на 10, чтобы сохраниться, а на ступень выше переживёт отставание в 10. При равной редкости вещь должна просто превзойти надетую. При 0 редкость перестаёт учитываться и решает только уровень предмета"
L["settings:emphasizeQuality"] = "  Подчёркивать редкость"
L["settings:emphasizeQualityTooltip"] =
"Считает ступень редкости за двойной запас и позволяет вещи вашей редкости отставать от надетой на этот запас. Редкость выше надетой становится дешевле сохранить, а ниже — дороже оправдать"
L["settings:keepBindOnAccount"] = "Сохранять привязанные к аккаунту"
L["settings:keepBindOnAccountTooltip"] = "Сохранять предметы, привязанные к аккаунту (фамильные реликвии)"
L["settings:keepBindOnAccountPastExpac"] = "  Включить прошлые дополнения"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Также сохранять привязанные к аккаунту предметы из прошлых дополнений"
L["settings:keepDisenchantables"] = "Сохранять распыляемые"
L["settings:keepDisenchantablesTooltip"] = "Чародеи: сохранять BOP/BOE/BOA экипировку. Остальные: сохранять BOE/BOA для АГ или альтов"
L["settings:keepDisenchantablesPastExpac"] = "  Включить прошлые дополнения"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Также сохранять распыляемую экипировку из прошлых дополнений"
L["settings:keepUsedReagents"] = "Сохранять реагенты ваших профессий"
L["settings:keepUsedReagentsTooltip"] = "Сохранять реагенты, которые может использовать любая профессия этой учётной записи"
L["settings:materialsMode"] = "Материалы для крафта"
L["settings:materialsModeTooltip"] =
"Что делать с реагентами, торговыми товарами, самоцветами, чарами и рецептами"
L["settings:materialsExpansion"] = "  Сохранять с дополнения"
L["settings:materialsExpansionTooltip"] =
"Сохранять материалы начиная с этого дополнения и продавать всё более старое. Используется, только если для материалов для крафта выбрано сохранение с определённого дополнения"
L["settings:otherMode"] = "Расходники и другое"
L["settings:otherModeTooltip"] =
"Что делать с расходниками, контейнерами, боевыми питомцами, снаряжением для профессий и предметами интерьера"

-- Sell modes
L["mode:keepAll"] = "Сохранять всё"
L["mode:keepCurrent"] = "Сохранять текущее дополнение"
L["mode:keepFrom"] = "Сохранять с дополнения"
L["mode:sellAll"] = "Продавать всё"

-- List tabs
L["btn:removeEntry"] = "Удалить"
L["list:warband"] = "Военный союз"
L["list:character"] = "Персонаж"
L["status:listEmpty"] = "Этот список пуст"
L["status:listCount"] = "%d записей"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Массовая продажа: будет продано"
L["verdict:keep"] = "Массовая продажа: будет сохранено"
L["reason:TEMP_EXCLUDED"] = "Исключено для этого визита к торговцу"
L["reason:BLACKLISTED"] = "В вашем чёрном списке"
L["reason:LOCKED"] = "Предмет заблокирован"
L["reason:EQUIPMENT_SET"] = "Часть комплекта экипировки"
L["reason:NO_SELL_PRICE"] = "Ни один торговец его не купит"
L["reason:REFUNDABLE"] = "Ещё в пределах срока возврата"
L["reason:WHITELISTED"] = "В вашем белом списке"
L["reason:TEMP_INCLUDED"] = "Добавлено для этого визита к торговцу"
L["reason:JUNK"] = "«Продавать хлам» выключено, хлам не трогается"
L["reason:CATEGORY"] = "Этот тип предметов настроен на сохранение"
L["reason:CURRENT_EXPANSION"] = "Из дополнения, которое вы сохраняете"
L["reason:BIND_ON_ACCOUNT"] = "Предметы, привязанные к аккаунту, сохраняются"
L["reason:DISENCHANTABLE"] = "Стоит сохранить, чтобы распылить или продать"
L["reason:REAGENT_WANTED"] = "Профессия этой учётной записи использует это"
L["reason:NOT_EQUIPPABLE"] = "Нельзя экипировать или не рекомендуется для вашего класса"
L["reason:EQUIPPABLE"] = "Достаточно хорош по сравнению с надетой экипировкой"
L["reason:OUTCLASSED"] = "Уступает надетой экипировке"
L["reason:SELL_MODE"] = "Этот тип предметов настроен на продажу"
L["reason:DEFAULT"] = "Ни одно правило не подошло, поэтому предмет сохраняется"

-- Expansion labels
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
L["expansion:midnight"] = "Полночь"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Сбросить чёрный список Военного союза"
L["listReset:warbandWhitelist"] = "Сбросить белый список Военного союза"
L["listReset:charBlacklist"] = "Сбросить чёрный список персонажа"
L["listReset:charWhitelist"] = "Сбросить белый список персонажа"
L["listReset:confirm"] = "Вы уверены, что хотите очистить этот список? Отменить действие невозможно."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Невозможно продать %s прямо сейчас: %s"
L["msg:dropUnexcluded"] = "Предмет %s больше не исключён и будет продан в этот визит"

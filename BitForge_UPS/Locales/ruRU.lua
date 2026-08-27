if GetLocale() ~= "ruRU" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Undermine Parcel Service"
L["settings:enabled"] = "Включить UPS"
L["settings:enabledTooltip"] = "Складывать реагенты профессий в банк отряда при посещении банка"
L["settings:previewMoves"] = "Предпросмотр перед отправкой"
L["settings:previewMovesTooltip"] = "Показывать окно подтверждения со списком всех перемещений до того, как что-либо будет отправлено"
L["settings:onlyWantedReagents"] = "Складывать только нужные реагенты"
L["settings:onlyWantedReagentsTooltip"] = "Складывать только реагенты, с которыми может работать профессия этой учётной записи. Выключено — складываются все, для аукциона"

L["btn:deposit"] = "Отправить"
L["btn:depositing"] = "Отправка… %d"

L["preview:title"] = "Подтвердите отправку"
L["preview:summary"] = "предметов: %d, перемещений: %d"
L["preview:toWarband"] = "→ Банк отряда"
L["preview:dontAskAgain"] = "Больше не спрашивать"
L["btn:confirm"] = "Подтвердить"
L["btn:cancel"] = "Отмена"

L["msg:nothingToDo"] = "UPS: Нечего перемещать."
L["msg:done"] = "UPS: Готово. Перемещено предметов: %d."
L["msg:noVacancy"] = "UPS: Банк отряда заполнен."
L["msg:blockedCombat"] = "UPS: Остановлено — вы в бою."
L["msg:blockedBankClosed"] = "UPS: Остановлено — банк закрылся."
L["msg:blockedCursor"] = "UPS: Остановлено — вы держите что-то на курсоре."
L["msg:blockedLocked"] = "UPS: Остановлено — предмет заблокирован."
L["msg:moveFailed"] = "UPS: Остановлено — перемещение не завершилось."
L["msg:openProfession"] = "UPS: Откройте окно «%s» один раз, чтобы UPS запомнил известные вам рецепты."

-- Curation window
L["curation:title"] = "UPS — Разбор предметов"
L["curation:open"] = "Разобрать предметы"
L["curation:search"] = "Поиск"
L["curation:filterDestination"] = "Любое назначение"
L["curation:filterClass"] = "Любой тип предмета"
L["curation:source"] = "Источник: %s"
L["curation:sourceBuiltIn"] = "Этот персонаж"
L["curation:count"] = "Предметов: %d"
L["curation:unscanned"] = "Рецепты не проверялись: %s. До проверки любой рецепт их профессий считается нужным и будет складываться в банк."
L["curation:heldBy"] = "Хранится у"
L["curation:overrideTooltip"] = "Это назначение выбрали вы. Сбросьте его, чтобы снова следовать правилам."

-- Destinations
L["dest:warband"] = "Банк отряда"
L["dest:private"] = "Свой банк"
L["dest:privateOwned"] = "Свой банк (%s)"
L["dest:ignore"] = "Не трогать"

-- Private destination
L["preview:toPrivate"] = "→ Свой банк"
L["preview:reclaim"] = "Банк отряда → Свой банк"
L["msg:noVacancyPrivate"] = "UPS: Ваш банк заполнен."
L["curation:privateTooltip"] = "Хранится в личном банке персонажа, а не в общем хранилище. Если владелец не выбран, предмет забирает первый персонаж, посетивший банк."

-- Target quantity
L["curation:targetSuffix"] = "держать %d"
L["target:title"] = "Целевое количество"
L["target:prompt"] = "Сколько %s должен держать каждый владелец?"

-- Row menu
L["menu:resetToDefault"] = "Сбросить по умолчанию"
L["menu:owners"] = "Владельцы"
L["menu:target"] = "Целевое количество"
L["menu:targetNone"] = "Без ограничения"
L["menu:targetOther"] = "Другое…"

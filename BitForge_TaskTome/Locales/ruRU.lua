if GetLocale() ~= "ruRU" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

L["status:widgetTitle"] = "Task Tome"

L["settings:configTitle"] = "Task Tome — Настройки"
L["btn:addRootTask"] = "Добавить основную задачу"
L["btn:addChildTask"] = "Добавить подзадачу"
L["btn:deleteTask"] = "Удалить задачу"
L["btn:save"] = "Сохранить"
L["settings:taskName"] = "Название"
L["settings:resetCycle"] = "Сброс"
L["settings:warbandAssigned"] = "Назначено всем персонажам"
L["settings:completionScope"] = "Область выполнения"
L["settings:optState"] = "Моё назначение"

L["menu:resetNone"] = "Нет"
L["menu:resetDaily"] = "Ежедневно"
L["menu:resetWeekly"] = "Еженедельно"
L["menu:scopeChar"] = "Персонаж"
L["menu:scopeWarband"] = "Общее — одно выполнение засчитывается для всего аккаунта"
L["menu:optFollow"] = "Следовать умолчанию"
L["menu:optIn"] = "Всегда показывать"
L["menu:optOut"] = "Всегда скрывать"

L["msg:deleteConfirm"] = "Удалить «%s» и все вложенные задачи (%d)?"
L["msg:deleteSingle"] = "Удалить «%s»?"
L["btn:confirmDelete"] = "Удалить"
L["btn:cancel"] = "Отмена"
L["msg:nameRequired"] = "Название задачи не может быть пустым."

L["settings:taskTomePanel"] = "Task Tome"
L["settings:config"] = "Настройки"
L["settings:openConfig"] = "Открыть"

L["group:accountWide"] = "Для всего аккаунта"
L["tooltip:scopeMe"] = "Показан этот персонаж. Нажмите, чтобы показать всех персонажей."
L["tooltip:scopeAll"] = "Показаны все персонажи. Нажмите, чтобы показать только этого персонажа."
L["tooltip:orientByChar"] = "Группировка по персонажам. Нажмите, чтобы группировать по задачам."
L["tooltip:orientByTask"] = "Группировка по задачам. Нажмите, чтобы группировать по персонажам."
L["tooltip:openConfig"] = "Открывает окно настроек Книги задач."
L["tooltip:widgetLocked"] = "Окно закреплено. Нажмите, чтобы открепить его для перемещения и изменения размера."
L["tooltip:widgetUnlocked"] = "Окно откреплено. Нажмите, чтобы закрепить его положение и размер."

L["settings:editingFor"] = "Редактирование для"
L["settings:optStateFor"] = "Назначение для %s"

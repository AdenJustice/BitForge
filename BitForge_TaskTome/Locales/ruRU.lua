if GetLocale() ~= "ruRU" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "Книга заданий"
L["btn:lockWidget"] = "Закрепить"
L["btn:unlockWidget"] = "Открепить"

-- Config Frame
L["settings:configTitle"] = "Книга заданий — Настройки"
L["btn:addRootTask"] = "Добавить главное задание"
L["btn:addChildTask"] = "Добавить подзадание"
L["btn:deleteTask"] = "Удалить задание"
L["btn:save"] = "Сохранить"
L["settings:taskName"] = "Название"
L["settings:resetCycle"] = "Сброс"
L["settings:warbandAssigned"] = "Назначено всем персонажам"
L["settings:completionScope"] = "Область выполнения"
L["settings:optState"] = "Моё назначение"

-- Dropdowns
L["menu:resetNone"] = "Нет"
L["menu:resetDaily"] = "Ежедневно"
L["menu:resetWeekly"] = "Еженедельно"
L["menu:scopeChar"] = "Персонаж"
L["menu:scopeWarband"] = "Общее — одно выполнение засчитывается для всего аккаунта"
L["menu:optFollow"] = "По умолчанию"
L["menu:optIn"] = "Всегда показывать"
L["menu:optOut"] = "Всегда скрывать"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "Удалить «%s» и все %d подзадание/подзадания?"
L["msg:deleteSingle"] = "Удалить «%s»?"
L["btn:confirmDelete"] = "Удалить"
L["btn:cancel"] = "Отмена"
L["msg:nameRequired"] = "Название задания не может быть пустым."

-- Settings panel
L["settings:taskTomePanel"] = "Книга заданий"
L["settings:config"] = "Настройки"
L["settings:openConfig"] = "Открыть"

-- Widget modes
L["group:accountWide"] = "Для всего аккаунта"
L["tooltip:scopeMe"] = "Показан этот персонаж. Нажмите, чтобы показать всех персонажей."
L["tooltip:scopeAll"] = "Показаны все персонажи. Нажмите, чтобы показать только этого персонажа."
L["tooltip:orientByChar"] = "Группировка по персонажам. Нажмите, чтобы группировать по заданиям."
L["tooltip:orientByTask"] = "Группировка по заданиям. Нажмите, чтобы группировать по персонажам."

-- Config
L["settings:editingFor"] = "Редактирование для"
L["settings:optStateFor"] = "Назначение для %s"

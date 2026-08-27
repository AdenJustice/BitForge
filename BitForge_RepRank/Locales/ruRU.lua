if GetLocale() ~= "ruRU" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "RepRank"
L["window:title"] = "RepRank"
L["section:warband"] = "Отряд"
L["section:characters"] = "Персонажи"
L["section:ungrouped"] = "Прочее"
L["column:faction"] = "Фракция"
L["column:leader"] = "Лучший"
L["column:standing"] = "Уровень"
L["column:progress"] = "Прогресс"
L["filter:showUntouched"] = "Показывать фракции без прогресса"
L["filter:search"] = "Поиск"
L["tooltip:pendingTitle"] = "Награда парагона ожидает"
L["minimap:label"] = "RepRank"
L["standing:unknown"] = "Неизвестно"
L["standing:renown"] = "Известность %d"
L["alert:pendingSelf"] = "Награда парагона готова: %s"
L["alert:pendingAlt"] = "Награда парагона готова у %s: %s"
L["toast:pendingOne"] = "1 награда парагона ожидает"
L["toast:pendingMany"] = "%d наград парагона ожидает"
L["settings:chatAlerts"] = "Оповещения в чате"
L["settings:chatAlertsTooltip"] = "Выводит строку в чат, когда у персонажа есть ожидающая награда парагона."
L["settings:toastAlerts"] = "Всплывающие оповещения"
L["settings:toastAlertsTooltip"] = "Показывает всплывающее оповещение, когда у персонажа есть ожидающая награда парагона."

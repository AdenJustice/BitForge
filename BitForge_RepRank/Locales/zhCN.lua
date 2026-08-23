if GetLocale() ~= "zhCN" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "声望排行"
L["window:title"] = "声望排行"
L["section:warband"] = "战团"
L["section:characters"] = "角色"
L["column:faction"] = "阵营"
L["column:leader"] = "最佳"
L["column:standing"] = "等级"
L["column:progress"] = "进度"
L["filter:showUntouched"] = "显示无进度的阵营"
L["filter:search"] = "搜索"
L["tooltip:pendingTitle"] = "巅峰奖励等待中"
L["minimap:label"] = "声望排行"
L["standing:unknown"] = "未知"
L["standing:renown"] = "威望 %d"
L["alert:pendingSelf"] = "巅峰奖励就绪：%s"
L["alert:pendingAlt"] = "%s的巅峰奖励就绪：%s"
L["toast:pendingOne"] = "1 个巅峰奖励等待中"
L["toast:pendingMany"] = "%d 个巅峰奖励等待中"
L["settings:chatAlerts"] = "聊天提醒"
L["settings:chatAlertsTooltip"] = "当角色有巅峰奖励等待领取时，在聊天窗口中显示一行提示。"
L["settings:toastAlerts"] = "弹出提醒"
L["settings:toastAlertsTooltip"] = "当角色有巅峰奖励等待领取时，显示弹出提醒。"

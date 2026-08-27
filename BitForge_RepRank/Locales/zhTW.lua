if GetLocale() ~= "zhTW" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "聲望排行"
L["window:title"] = "聲望排行"
L["section:warband"] = "戰團"
L["section:characters"] = "角色"
L["section:ungrouped"] = "其他"
L["column:faction"] = "陣營"
L["column:leader"] = "最佳"
L["column:standing"] = "等級"
L["column:progress"] = "進度"
L["filter:showUntouched"] = "顯示無進度的陣營"
L["filter:search"] = "搜尋"
L["tooltip:pendingTitle"] = "巔峰獎勵等待中"
L["minimap:label"] = "聲望排行"
L["standing:unknown"] = "未知"
L["standing:renown"] = "威望 %d"
L["alert:pendingSelf"] = "巔峰獎勵就緒：%s"
L["alert:pendingAlt"] = "%s的巔峰獎勵就緒：%s"
L["toast:pendingOne"] = "1 個巔峰獎勵等待中"
L["toast:pendingMany"] = "%d 個巔峰獎勵等待中"
L["settings:chatAlerts"] = "聊天提醒"
L["settings:chatAlertsTooltip"] = "當角色有巔峰獎勵等待領取時，在聊天視窗中顯示一行提示。"
L["settings:toastAlerts"] = "彈出提醒"
L["settings:toastAlertsTooltip"] = "當角色有巔峰獎勵等待領取時，顯示彈出提醒。"

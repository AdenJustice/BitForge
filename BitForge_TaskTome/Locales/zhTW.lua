if GetLocale() ~= "zhTW" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "任務冊"
L["btn:lockWidget"] = "鎖定"
L["btn:unlockWidget"] = "解鎖"

-- Config Frame
L["settings:configTitle"] = "任務冊 — 設定"
L["btn:addRootTask"] = "新增根任務"
L["btn:addChildTask"] = "新增子任務"
L["btn:deleteTask"] = "刪除任務"
L["btn:save"] = "儲存"
L["settings:taskName"] = "名稱"
L["settings:resetCycle"] = "重置"
L["settings:warbandAssigned"] = "戰團任務"
L["settings:completionScope"] = "完成範圍"
L["settings:optState"] = "我的參與狀態"

-- Dropdowns
L["menu:resetNone"] = "無"
L["menu:resetDaily"] = "每日"
L["menu:resetWeekly"] = "每週"
L["menu:scopeChar"] = "角色"
L["menu:scopeWarband"] = "戰團"
L["menu:optFollow"] = "跟隨預設"
L["menu:optIn"] = "始終顯示"
L["menu:optOut"] = "始終隱藏"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "刪除「%s」及其 %d 個子任務？"
L["msg:deleteSingle"] = "刪除「%s」？"
L["btn:confirmDelete"] = "刪除"
L["btn:cancel"] = "取消"
L["msg:nameRequired"] = "任務名稱不能為空。"

-- Settings panel
L["settings:taskTomePanel"] = "任務冊"
L["settings:config"] = "設定"
L["settings:openConfig"] = "開啟"

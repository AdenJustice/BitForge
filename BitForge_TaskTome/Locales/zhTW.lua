if GetLocale() ~= "zhTW" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "任務冊"

-- Config Frame
L["settings:configTitle"] = "任務冊 — 設定"
L["btn:addRootTask"] = "新增根任務"
L["btn:addChildTask"] = "新增子任務"
L["btn:deleteTask"] = "刪除任務"
L["btn:save"] = "儲存"
L["settings:taskName"] = "名稱"
L["settings:resetCycle"] = "重置"
L["settings:warbandAssigned"] = "分配給所有角色"
L["settings:completionScope"] = "完成範圍"
L["settings:optState"] = "我的分配"

-- Dropdowns
L["menu:resetNone"] = "無"
L["menu:resetDaily"] = "每日"
L["menu:resetWeekly"] = "每週"
L["menu:scopeChar"] = "角色"
L["menu:scopeWarband"] = "共享 — 全帳號計為一次完成"
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

-- Widget modes
L["group:accountWide"] = "帳號共享"
L["tooltip:scopeMe"] = "正在顯示此角色。點擊以顯示所有角色。"
L["tooltip:scopeAll"] = "正在顯示所有角色。點擊以僅顯示此角色。"
L["tooltip:orientByChar"] = "依角色分組。點擊以依任務分組。"
L["tooltip:orientByTask"] = "依任務分組。點擊以依角色分組。"
L["tooltip:openConfig"] = "開啟任務冊設定視窗。"
L["tooltip:widgetLocked"] = "視窗已鎖定。點擊以解鎖，即可移動並調整大小。"
L["tooltip:widgetUnlocked"] = "視窗已解鎖。點擊以鎖定其位置與大小。"

-- Config
L["settings:editingFor"] = "正在編輯"
L["settings:optStateFor"] = "%s 的分配"

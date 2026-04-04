if GetLocale() ~= "zhCN" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "任务册"
L["btn:lockWidget"] = "锁定"
L["btn:unlockWidget"] = "解锁"

-- Config Frame
L["settings:configTitle"] = "任务册 — 配置"
L["btn:addRootTask"] = "添加主任务"
L["btn:addChildTask"] = "添加子任务"
L["btn:deleteTask"] = "删除任务"
L["btn:save"] = "保存"
L["settings:taskName"] = "名称"
L["settings:resetCycle"] = "重置"
L["settings:warbandAssigned"] = "战团任务"
L["settings:completionScope"] = "完成范围"
L["settings:optState"] = "我的参与状态"

-- Dropdowns
L["menu:resetNone"] = "无"
L["menu:resetDaily"] = "每日"
L["menu:resetWeekly"] = "每周"
L["menu:scopeChar"] = "角色"
L["menu:scopeWarband"] = "战团"
L["menu:optFollow"] = "跟随默认"
L["menu:optIn"] = "始终显示"
L["menu:optOut"] = "始终隐藏"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "删除「%s」及其 %d 个子任务？"
L["msg:deleteSingle"] = "删除「%s」？"
L["btn:confirmDelete"] = "删除"
L["btn:cancel"] = "取消"
L["msg:nameRequired"] = "任务名称不能为空。"

-- Settings panel
L["settings:taskTomePanel"] = "任务册"
L["settings:config"] = "配置"
L["settings:openConfig"] = "打开"

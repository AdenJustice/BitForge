if GetLocale() ~= "zhCN" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

L["status:widgetTitle"] = "任务册"

L["settings:configTitle"] = "任务册 — 配置"
L["btn:addRootTask"] = "添加主任务"
L["btn:addChildTask"] = "添加子任务"
L["btn:deleteTask"] = "删除任务"
L["btn:save"] = "保存"
L["settings:taskName"] = "名称"
L["settings:resetCycle"] = "重置"
L["settings:warbandAssigned"] = "分配给所有角色"
L["settings:completionScope"] = "完成范围"
L["settings:optState"] = "我的分配"

L["menu:resetNone"] = "无"
L["menu:resetDaily"] = "每日"
L["menu:resetWeekly"] = "每周"
L["menu:scopeChar"] = "角色"
L["menu:scopeWarband"] = "共享 — 全账号计为一次完成"
L["menu:optFollow"] = "跟随默认"
L["menu:optIn"] = "始终显示"
L["menu:optOut"] = "始终隐藏"

L["msg:deleteConfirm"] = "删除「%s」及其 %d 个子任务？"
L["msg:deleteSingle"] = "删除「%s」？"
L["btn:confirmDelete"] = "删除"
L["btn:cancel"] = "取消"
L["msg:nameRequired"] = "任务名称不能为空。"

L["settings:taskTomePanel"] = "任务册"
L["settings:config"] = "配置"
L["settings:openConfig"] = "打开"

L["group:accountWide"] = "账号共享"
L["tooltip:scopeMe"] = "正在显示此角色。点击以显示所有角色。"
L["tooltip:scopeAll"] = "正在显示所有角色。点击以仅显示此角色。"
L["tooltip:orientByChar"] = "按角色分组。点击以按任务分组。"
L["tooltip:orientByTask"] = "按任务分组。点击以按角色分组。"
L["tooltip:openConfig"] = "打开任务册配置窗口。"
L["tooltip:widgetLocked"] = "窗口已锁定。点击以解锁，即可移动和调整大小。"
L["tooltip:widgetUnlocked"] = "窗口已解锁。点击以锁定其位置和大小。"

L["settings:editingFor"] = "正在编辑"
L["settings:optStateFor"] = "%s 的分配"

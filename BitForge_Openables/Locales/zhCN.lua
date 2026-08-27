if GetLocale() ~= "zhCN" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Openables"
L["settings:enabled"] = "启用 Openables"
L["settings:enabledTooltip"] = "显示一个按钮，指向背包中下一件可开启或可使用的物品"
L["settings:locked"] = "锁定按钮"
L["settings:lockedTooltip"] = "禁止拖动按钮"
L["settings:buttonSize"] = "按钮大小"
L["settings:buttonSizeTooltip"] = "按钮的宽度和高度，以像素为单位"
L["settings:showCount"] = "显示数量"
L["settings:showCountTooltip"] = "显示你携带的该物品数量"
L["settings:showCooldown"] = "显示冷却"
L["settings:showCooldownTooltip"] = "在按钮上显示冷却时间"
L["settings:resetPosition"] = "重置位置"
L["settings:manageBlacklist"] = "管理排除列表"

L["tooltip:use"] = "左键点击以开启或使用。"
L["tooltip:skip"] = "右键点击以在本次登录期间跳过。"
L["tooltip:blacklist"] = "Ctrl + 右键点击以永久排除。"
L["tooltip:report"] = "Shift + Alt + 右键点击以反馈此判定。"
L["tooltip:drag"] = "Alt + 拖动以移动。"

L["report:blurb"] = "这份报告包含物品、BitForge 对它的分类方式、它的提示文字，以及本角色已知的专业。这里不会写出你角色的名字、所在服务器、公会或阵营。"

L["report:blurbField"] = "这份报告包含上次扫描排出的每一个候选物品，按排名顺序列出：各自的名称、物品 ID、背包与格子、堆叠数量、优先级以及排到该位置的原因，以及它是否被锁定、正在冷却或被推迟。这里不会写出你角色的名字、所在服务器、公会或阵营，也不包含任何物品的提示文字。"

L["blacklist:windowTitle"] = "已排除的物品"
L["blacklist:empty"] = "没有已排除的物品。"
L["blacklist:remove"] = "移除"
L["blacklist:clearAll"] = "全部清除"
L["blacklist:unknownItem"] = "物品 %d"

L["binding:header"] = "BitForge Openables"
L["binding:use"] = "使用可开启物品"

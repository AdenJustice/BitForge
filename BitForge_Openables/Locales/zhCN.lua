---@class BitForge.Openables
local ns = select(2, ...)
if GetLocale() ~= "zhCN" then return end
local L = ns.locale

-- Settings panel
L["panel:title"] = "可开启物品"
L["settings:enabled"] = "启用可开启物品"
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

-- Button tooltip
L["tooltip:use"] = "左键点击以开启或使用。"
L["tooltip:skip"] = "右键点击以在本次登录期间跳过。"
L["tooltip:blacklist"] = "Ctrl + 右键点击以永久排除。"
L["tooltip:drag"] = "Alt + 拖动以移动。"

-- Blacklist
L["blacklist:windowTitle"] = "已排除的物品"
L["blacklist:empty"] = "没有已排除的物品。"
L["blacklist:remove"] = "移除"
L["blacklist:clearAll"] = "全部清除"
L["blacklist:unknownItem"] = "物品 %d"

-- Key bindings
L["binding:header"] = "BitForge 可开启物品"
L["binding:use"] = "使用可开启物品"

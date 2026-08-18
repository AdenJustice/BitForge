if GetLocale() ~= "zhCN" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "左键点击打开选项"
L["minimap:hintDrag"] = "拖动以移动"
L["minimap:compartmentTooltip"] = "打开 BitForge 菜单"

-- Schema upgrade
L["msg:schemaResetBody"] = "%s 的存档数据来自旧版本，无法继续沿用。这些数据将被清除并重新建立。此操作只会发生一次。"
L["btn:schemaResetAccept"] = "清除并继续"

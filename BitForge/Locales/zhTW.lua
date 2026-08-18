if GetLocale() ~= "zhTW" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "左鍵點擊開啟選項"
L["minimap:hintDrag"] = "拖曳以移動"
L["minimap:compartmentTooltip"] = "開啟 BitForge 選單"

-- Schema upgrade
L["msg:schemaResetBody"] = "%s 的存檔資料來自舊版本，無法繼續沿用。這些資料將被清除並重新建立。此操作只會發生一次。"
L["btn:schemaResetAccept"] = "清除並繼續"

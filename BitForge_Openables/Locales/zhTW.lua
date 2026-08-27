if GetLocale() ~= "zhTW" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "可開啟物品"
L["settings:enabled"] = "啟用可開啟物品"
L["settings:enabledTooltip"] = "顯示一個按鈕，指向背包中下一件可開啟或可使用的物品"
L["settings:locked"] = "鎖定按鈕"
L["settings:lockedTooltip"] = "禁止拖曳按鈕"
L["settings:buttonSize"] = "按鈕大小"
L["settings:buttonSizeTooltip"] = "按鈕的寬度與高度，以像素為單位"
L["settings:showCount"] = "顯示數量"
L["settings:showCountTooltip"] = "顯示你攜帶的該物品數量"
L["settings:showCooldown"] = "顯示冷卻"
L["settings:showCooldownTooltip"] = "在按鈕上顯示冷卻時間"
L["settings:resetPosition"] = "重設位置"
L["settings:manageBlacklist"] = "管理排除清單"

L["tooltip:use"] = "左鍵點擊以開啟或使用。"
L["tooltip:skip"] = "右鍵點擊以在本次登入期間略過。"
L["tooltip:blacklist"] = "Ctrl + 右鍵點擊以永久排除。"
L["tooltip:report"] = "Shift + Alt + 右鍵點擊以回報此判定。"
L["tooltip:drag"] = "Alt + 拖曳以移動。"

L["report:blurb"] = "這份報告包含物品、BitForge 對它的分類方式、它的提示文字，以及本角色已知的專業。這裡不會寫出你角色的名字、所在伺服器、公會或陣營。"

L["blacklist:windowTitle"] = "已排除的物品"
L["blacklist:empty"] = "沒有已排除的物品。"
L["blacklist:remove"] = "移除"
L["blacklist:clearAll"] = "全部清除"
L["blacklist:unknownItem"] = "物品 %d"

L["binding:header"] = "BitForge 可開啟物品"
L["binding:use"] = "使用可開啟物品"

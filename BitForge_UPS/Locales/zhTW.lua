if GetLocale() ~= "zhTW" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "艾澤拉斯包裹服務"
L["settings:enabled"] = "啟用 UPS"
L["settings:enabledTooltip"] = "造訪銀行時將專業材料存入戰隊銀行"
L["settings:previewMoves"] = "存入前預覽"
L["settings:previewMovesTooltip"] = "在存入任何物品之前，顯示列出所有移動操作的確認視窗"
L["settings:onlyWantedReagents"] = "僅存入可使用的材料"
L["settings:onlyWantedReagentsTooltip"] = "僅存入此帳號任一專業能用於製作的材料。關閉則存入全部材料，供拍賣場使用"

L["btn:deposit"] = "存入"
L["btn:depositing"] = "正在存入… %d"

L["preview:title"] = "確認存入"
L["preview:summary"] = "%d 件物品，共 %d 次移動"
L["preview:toWarband"] = "→ 戰隊銀行"
L["preview:dontAskAgain"] = "不再詢問"
L["btn:confirm"] = "確認"
L["btn:cancel"] = "取消"

L["msg:nothingToDo"] = "UPS：沒有需要移動的物品。"
L["msg:done"] = "UPS：完成。已移動 %d 件物品。"
L["msg:noVacancy"] = "UPS：戰隊銀行已滿。"
L["msg:blockedCombat"] = "UPS：已停止 — 你正在戰鬥中。"
L["msg:blockedBankClosed"] = "UPS：已停止 — 銀行已關閉。"
L["msg:blockedCursor"] = "UPS：已停止 — 游標上有物品。"
L["msg:blockedLocked"] = "UPS：已停止 — 物品已鎖定。"
L["msg:moveFailed"] = "UPS：已停止 — 移動未能完成。"
L["msg:openProfession"] = "UPS：請開啟一次%s視窗，讓 UPS 記錄你已學會的配方。"

-- Curation window
L["curation:title"] = "UPS — 物品整理"
L["curation:open"] = "整理物品"
L["curation:search"] = "搜尋"
L["curation:filterDestination"] = "任何去向"
L["curation:filterClass"] = "任何物品類型"
L["curation:source"] = "資料來源：%s"
L["curation:sourceBuiltIn"] = "目前角色"
L["curation:count"] = "共 %d 件物品"
L["curation:unscanned"] = "從未掃描過配方：%s。在掃描之前，其專業的所有配方都會被視為需要並存入銀行。"
L["curation:heldBy"] = "持有角色"
L["curation:overrideTooltip"] = "該去向由你指定。恢復預設後將重新依規則判斷。"

-- Destinations
L["dest:warband"] = "戰隊銀行"
L["dest:private"] = "個人銀行"
L["dest:privateOwned"] = "個人銀行（%s）"
L["dest:ignore"] = "保持不動"

-- Private destination
L["preview:toPrivate"] = "→ 個人銀行"
L["preview:reclaim"] = "戰隊銀行 → 個人銀行"
L["msg:noVacancyPrivate"] = "UPS：你的銀行已滿。"
L["curation:privateTooltip"] = "存放在角色自己的銀行，而非共用倉庫。未指定歸屬角色時，最先造訪銀行的角色會取走它。"

-- Target quantity
L["curation:targetSuffix"] = "保留 %d"
L["target:title"] = "目標數量"
L["target:prompt"] = "每位歸屬角色應保留多少個%s？"

-- Row menu
L["menu:resetToDefault"] = "恢復預設"
L["menu:owners"] = "歸屬角色"
L["menu:target"] = "目標數量"
L["menu:targetNone"] = "不限制"
L["menu:targetOther"] = "其他…"

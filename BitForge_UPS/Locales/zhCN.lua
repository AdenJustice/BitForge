if GetLocale() ~= "zhCN" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "艾泽拉斯包裹服务"
L["settings:enabled"] = "启用 UPS"
L["settings:enabledTooltip"] = "访问银行时将专业材料存入战团银行"
L["settings:previewMoves"] = "存入前预览"
L["settings:previewMovesTooltip"] = "在存入任何物品之前，显示列出全部移动操作的确认窗口"
L["settings:onlyWantedReagents"] = "仅存入可使用的材料"
L["settings:onlyWantedReagentsTooltip"] = "仅存入此账号任一专业能用于制作的材料。关闭则存入全部材料，供拍卖行使用"

L["btn:deposit"] = "存入"
L["btn:depositing"] = "正在存入… %d"

L["preview:title"] = "确认存入"
L["preview:summary"] = "%d 件物品，共 %d 次移动"
L["preview:toWarband"] = "→ 战团银行"
L["preview:dontAskAgain"] = "不再询问"
L["btn:confirm"] = "确认"
L["btn:cancel"] = "取消"

L["msg:nothingToDo"] = "UPS：没有需要移动的物品。"
L["msg:done"] = "UPS：完成。已移动 %d 件物品。"
L["msg:noVacancy"] = "UPS：战团银行已满。"
L["msg:blockedCombat"] = "UPS：已停止 — 你正在战斗中。"
L["msg:blockedBankClosed"] = "UPS：已停止 — 银行已关闭。"
L["msg:blockedCursor"] = "UPS：已停止 — 光标上有物品。"
L["msg:blockedLocked"] = "UPS：已停止 — 物品已锁定。"
L["msg:moveFailed"] = "UPS：已停止 — 移动未能完成。"
L["msg:openProfession"] = "UPS：请打开一次%s窗口，以便 UPS 记录你已学会的配方。"

-- Curation window
L["curation:title"] = "UPS — 物品整理"
L["curation:open"] = "整理物品"
L["curation:search"] = "搜索"
L["curation:filterDestination"] = "任意去向"
L["curation:filterClass"] = "任意物品类型"
L["curation:source"] = "数据来源：%s"
L["curation:sourceBuiltIn"] = "当前角色"
L["curation:count"] = "共 %d 件物品"
L["curation:unscanned"] = "从未扫描过配方：%s。在扫描之前，其专业的所有配方都会被视为需要并存入银行。"
L["curation:heldBy"] = "持有角色"
L["curation:overrideTooltip"] = "该去向由你指定。恢复默认后将重新按规则判断。"

-- Destinations
L["dest:warband"] = "战团银行"
L["dest:private"] = "个人银行"
L["dest:privateOwned"] = "个人银行（%s）"
L["dest:ignore"] = "保持不动"

-- Private destination
L["preview:toPrivate"] = "→ 个人银行"
L["preview:reclaim"] = "战团银行 → 个人银行"
L["msg:noVacancyPrivate"] = "UPS：你的银行已满。"
L["curation:privateTooltip"] = "存放在角色自己的银行中，而非共享仓库。未指定归属角色时，最先访问银行的角色将取走它。"

-- Target quantity
L["curation:targetSuffix"] = "保留 %d"
L["target:title"] = "目标数量"
L["target:prompt"] = "每位归属角色应保留多少个%s？"

-- Row menu
L["menu:resetToDefault"] = "恢复默认"
L["menu:owners"] = "归属角色"
L["menu:target"] = "目标数量"
L["menu:targetNone"] = "不限制"
L["menu:targetOther"] = "其他…"

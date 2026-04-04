if GetLocale() ~= "zhTW" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "自動平衡"

L["settings:useCharSettings"] = "使用角色設定"
L["settings:useCharSettingsTooltip"] = "以此角色的專屬設定覆蓋帳號通用設定"

L["settings:desiredBalance"] = "目標餘額"
L["settings:desiredBalanceTooltip"] = "欲維持在背包中的目標金幣數量"

L["settings:marginalRatio"] = "容差比例"
L["settings:marginalRatioTooltip"] = "若差額在目標 × 比例範圍內，跳過重新平衡"

L["settings:collectorCharacter"] = "收款角色"
L["settings:collectorCharacterTooltip"] = "從戰團銀行提取多餘金幣的角色"

L["settings:none"] = "無"
L["settings:always"] = "始終"

L["msg:deposit"] = "已存入 %s 至戰團銀行"
L["msg:withdraw"] = "已從戰團銀行提取 %s"
L["msg:collect"] = "已從戰團銀行收取 %s"
L["msg:noFunds"] = "戰團銀行無可提取的金幣"

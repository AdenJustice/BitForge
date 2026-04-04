if GetLocale() ~= "zhCN" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "自动均衡"

L["settings:useCharSettings"] = "使用角色设置"
L["settings:useCharSettingsTooltip"] = "使用此角色专属设置覆盖账号全局设置"

L["settings:desiredBalance"] = "目标余额"
L["settings:desiredBalanceTooltip"] = "维持背包中的目标金币余额"

L["settings:marginalRatio"] = "容差比例"
L["settings:marginalRatioTooltip"] = "若差额在目标×比例范围内，则跳过再平衡"

L["settings:collectorCharacter"] = "收集角色"
L["settings:collectorCharacterTooltip"] = "从战团银行收集多余金币的角色"

L["settings:none"] = "无"
L["settings:always"] = "始终"

L["msg:deposit"] = "已向战团银行存入 %s"
L["msg:withdraw"] = "已从战团银行取出 %s"
L["msg:collect"] = "已从战团银行收取 %s"
L["msg:noFunds"] = "战团银行没有可取的金币"

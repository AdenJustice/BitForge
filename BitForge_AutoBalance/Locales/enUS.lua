---@class BitForge.AutoBalance
local ns = select(2, ...)
---@class BitForge.AutoBalance.Locale
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Use Character Settings"
L["settings:useCharSettingsTooltip"] = "Override account-wide settings with values specific to this character"

L["settings:desiredBalance"] = "Desired Balance"
L["settings:desiredBalanceTooltip"] = "Target gold balance to maintain in your bags"

L["settings:marginalRatio"] = "Marginal Ratio"
L["settings:marginalRatioTooltip"] = "Skip rebalancing if difference is within desired × ratio"

L["settings:collectorCharacter"] = "Collector Character"
L["settings:collectorCharacterTooltip"] = "Character that collects excess gold from the Warband Bank"

L["settings:none"] = "None"
L["settings:always"] = "Always"

L["msg:deposit"] = "Deposited %s to Warband Bank"
L["msg:withdraw"] = "Withdrew %s from Warband Bank"
L["msg:collect"] = "Collected %s from Warband Bank"
L["msg:noFunds"] = "Warband Bank has no funds to withdraw"

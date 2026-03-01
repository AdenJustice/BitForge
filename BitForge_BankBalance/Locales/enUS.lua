---@type ns_BB
local ns = select(2, ...)
---@class BB_Locale
local L = ns.locale

L["message:deposit"] = "Deposited: %s"
L["message:withdraw"] = "Withdrew: %s"
L["message:withdrawError"] = "Cannot withdraw from warband bank."
L["message:depositError"] = "Cannot deposit to warband bank."
L["message:noBalance"] = "No funds available to withdraw."

L["setting:title"] = "BitForge: BankBalance Settings"
L["setting:category"] = "BankBalance"
L["setting:useGlobal"] = "Use Warband Settings"
L["setting:useGlobal_tooltip"] = "Check to use the warband settings. Uncheck to use character settings."
L["setting:enableMargin"] = "Enable Margin Ratio"
L["setting:enableMargin_tooltip"] = "Check to use range of values. Uncheck to use point value."
L["setting:marginRatio"] = "Margin Ratio"
L["setting:marginRatio_tooltip"] = "This creates a 'safety zone' around your target balance to ignore small changes. If you set it to '10%', nothing happens as long as your balance stays between 90% and 110% of your goal."
L["setting:balance"] = "Desired Balance"
L["setting:balance_tooltip"] = "Select the desired balance."

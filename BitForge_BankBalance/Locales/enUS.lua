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
L["setting:useGlobal"] = "Use Warband (Global) Settings"
L["setting:useGlobal_tooltip"] = "Check to use the warband settings. Uncheck to use personal settings."

L["ui:threshold_label"] = "Target Threshold (Gold)"
L["ui:use_margin_label"] = "Use Margin Balancing"
L["ui:margin_ratio_label"] = "Margin Ratio"

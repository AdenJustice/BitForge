---@class ns_core
local ns = select(2, ...)
---@class BF_Locale
local L = ns.locale

-- Minimap Button
L["minimapButton:tooltip_settings"] = "Open Settings"

-- Migration Dialog
L["migration:step1_title"] = "Data Migration - Step 1"
L["migration:step1_desc"] = "The following characters have invalid data. Select a character to migrate their data to your current character."
L["migration:step2_title"] = "Data Migration - Step 2"
L["migration:step2_desc"] = "The following characters have invalid data. Select the characters whose data you would like to permanently delete."
L["migration:button_migrate"] = "Migrate"
L["migration:button_skip"] = "Skip"
L["migration:button_purge"] = "Purge"
L["migration:button_keep_all"] = "Keep All"

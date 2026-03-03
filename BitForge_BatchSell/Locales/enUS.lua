---@type ns.BatchSell
local ns = select(2, ...)
---@class BitForge.Locales.BatchSell
local L = ns.locale

--- [ UI TEXT ]======================================================================

L["title:main"] = "BitForge Batch Sell"

L["tab:manifest"] = "Manifest"
L["tab:blacklist"] = "Blacklist"
L["tab:whitelist"] = "Whitelist"
L["tab:settings"] = "Settings"

L["button:sell_all"] = "Sell All"

--- [ CONTEXT MENU ]======================================================================

L["context:remove_from_manifest"] = "Remove from Manifest"
L["context:add_to_warband_blacklist"] = "Add to Warband Blacklist"
L["context:add_to_char_blacklist"] = "Add to Character Blacklist"
L["context:add_to_warband_whitelist"] = "Add to Warband Whitelist"
L["context:add_to_char_whitelist"] = "Add to Character Whitelist"
L["context:move_to_warband_blacklist"] = "Move to Warband Blacklist"
L["context:move_to_char_blacklist"] = "Move to Character Blacklist"
L["context:move_to_warband_whitelist"] = "Move to Warband Whitelist"
L["context:move_to_char_whitelist"] = "Move to Character Whitelist"
L["context:remove_from_blacklist"] = "Remove from Blacklist"
L["context:remove_from_whitelist"] = "Remove from Whitelist"
L["context:reset"] = "Reset (Remove from All Lists)"

--- [ INFO TEXT ]======================================================================

L["info:items_value"] = "%d items | Total: %s"
L["info:no_items"] = "No items to sell"

--- [ SETTINGS ]======================================================================

L["setting:sell_junk"] = "Automatically sell poor quality (junk) items"
L["setting:include_disenchantables"] = "Allow selling disenchantable items (Enchanting)"
L["setting:ilvl_threshold"] = "Item level threshold for selling"
L["setting:ilvl_threshold_help"] = "If < 1: ratio (0.1 = 10% below equipped)\nIf >= 1: absolute level difference"
L["setting:limit_to_12"] = "Limit batch sell to 12 items (preserves buyback slots)"

--- [ DIALOGS ]======================================================================

L["popup:confirm_sell"] = "Sell %d items for %s?"

--- [ MESSAGES ]======================================================================

L["msg:sell_complete"] = "Batch sell completed successfully!"

--- [ ERRORS ]======================================================================

L["error:scan_in_progress"] = "Scan already in progress"

--- [ EVALUATION REASONS ]======================================================================

L["evaluation:locked"] = "Item is locked"
L["evaluation:in_equipment_set"] = "Item is part of a saved gear set"
L["evaluation:no_item_info"] = "Unable to fetch item details from the server"
L["evaluation:no_sell_price"] = "Item cannot be sold to vendors"
L["evaluation:refundable"] = "Item is still refundable"
L["evaluation:whitelisted"] = "Item is whitelisted"
L["evaluation:blacklisted"] = "Item is blacklisted"
L["evaluation:junk_filter"] = "'Sell junk' is enabled"
L["evaluation:disenchantable"] = "Disenchantable by Enchanting"
L["evaluation:not_equipment"] = "Item is not armor or a weapon"
L["evaluation:wrong_armor_type"] = "Armor type doesn't match character's primary armor type"
L["evaluation:current_expansion_unbound"] = "Unbound item from the current expansion"
L["evaluation:no_slot_mapping"] = "No equipment slot available for this item"
L["evaluation:lower_ilvl"] = "Item level is lower than your equipped item"
L["evaluation:not_trash"] = "Item does not qualify as junk"

---@class BitForge.Core
local ns = select(2, ...)
---@class BitForge.Core.Locale
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Left-click for options"
L["minimap:hintDrag"] = "Drag to move"
L["minimap:compartmentTooltip"] = "Open the BitForge menu"

-- Schema upgrade. The body takes the module's title; core resolves that from
-- the addon's .toc rather than asking each module for a localized name.
L["msg:schemaResetBody"] = "The saved data for %s is from an older version and cannot be carried forward. It will be cleared and rebuilt. This happens once."
L["btn:schemaResetAccept"] = "Clear and continue"

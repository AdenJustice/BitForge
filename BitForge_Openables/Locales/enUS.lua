---@class BitForge.Openables
local ns = select(2, ...)
---@class BitForge.Openables.Locale
local L = ns.locale

L["panel:title"] = "Openables"
L["settings:enabled"] = "Enable Openables"
L["settings:enabledTooltip"] = "Show a button for the next openable or usable item in your bags"
L["settings:locked"] = "Lock button"
L["settings:lockedTooltip"] = "Prevent the button from being dragged"
L["settings:buttonSize"] = "Button size"
L["settings:buttonSizeTooltip"] = "Width and height of the button, in pixels"
L["settings:showCount"] = "Show stack count"
L["settings:showCountTooltip"] = "Display how many of the item you carry"
L["settings:showCooldown"] = "Show cooldown"
L["settings:showCooldownTooltip"] = "Display the cooldown sweep on the button"
L["settings:resetPosition"] = "Reset position"
L["settings:manageBlacklist"] = "Manage blacklist"

L["tooltip:use"] = "Left-click to open or use."
L["tooltip:skip"] = "Right-click to skip for this session."
L["tooltip:blacklist"] = "Ctrl + right-click to blacklist permanently."
L["tooltip:report"] = "Shift + Alt + right-click to report this verdict."
L["tooltip:drag"] = "Alt + drag to move."

-- The report window's footnote. What Openables discloses is not what BatchSell
-- discloses -- no item link, so no level and no specialization -- so each
-- module states its own.
L["report:blurb"] = "This report carries the item, how BitForge classified it, the text of its tooltip, and which professions this character knows. Nothing here names your character, realm, guild or faction."

L["blacklist:windowTitle"] = "Blacklisted Items"
L["blacklist:empty"] = "No items are blacklisted."
L["blacklist:remove"] = "Remove"
L["blacklist:clearAll"] = "Clear all"
L["blacklist:unknownItem"] = "Item %d"

L["binding:header"] = "BitForge Openables"
L["binding:use"] = "Use openable item"

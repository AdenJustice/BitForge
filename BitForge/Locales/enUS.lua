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

-- Slash commands. Core owns /bitforge and /bfdump for the whole suite; a module
-- name shortens to any prefix that reaches only one of them.
L["cmd:usage"] = "/bitforge <module> [arguments], /bfdump <module> [arguments] -- a module name may be shortened to any unambiguous prefix"
L["cmd:unknownModule"] = "no module named %s -- run /bitforge for the list"
L["cmd:ambiguousModule"] = "%s names more than one module: %s"
L["cmd:noSuchCommand"] = "%s answers no %s command"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- show what changed in this update"

-- The report window. A player who disagrees with a verdict reaches this from
-- the item itself; the payload and the sentence about what it discloses both
-- come from the module that opened it.
L["report:windowTitle"] = "Report an Item"
L["report:howTo"] = "Select All, then Ctrl+C. Paste it into a new issue at:"
L["report:selectAll"] = "Select All"

-- The release-notes popup. The window's chrome is localized; the notes inside
-- it are English, because they are generated from CHANGELOG.md and translating
-- several hundred words of release prose per release is not sustainable.
L["whatsNew:windowTitle"] = "What's New in BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Close"

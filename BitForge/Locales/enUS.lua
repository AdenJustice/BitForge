---@class BitForge.Core
local ns = select(2, ...)
---@class BitForge.Core.Locale
local L = ns.locale

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

-- The report window serves two entry points: a player who disagrees with a
-- verdict reaches it from the item itself, and /bfdump reaches it from a
-- diagnostic dump. Neither is "an item" the other is, so the payload, the
-- footnote and the title all come from the caller -- report:windowTitle is
-- the item-report default, and report:windowTitleDiagnostic is what every
-- /bfdump path asks for instead.
L["report:windowTitle"] = "Report an Item"
L["report:windowTitleDiagnostic"] = "Diagnostic Report"
L["report:howTo"] = "Select All, then Ctrl+C. Paste it into a new issue at:"
L["report:selectAll"] = "Select All"
L["report:encoded"] = "This report was too long to read, so it has been compressed. Paste it as it is -- the developer's tools will unpack it."

-- The release-notes popup. The window's chrome is localized; the notes inside
-- it are English, because they are generated from CHANGELOG.md and translating
-- several hundred words of release prose per release is not sustainable.
L["whatsNew:windowTitle"] = "What's New in BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Close"

-- The one-time notice raised for a profile that still has folders the BitForge
-- download used to carry. It says everything at once because it is shown once
-- and never again. The project names inside it are folder names, derived in
-- view.upgradeNotice and never translated.
L["upgrade:windowTitle"] = "BitForge is six downloads now"
L["upgrade:lead"] = "BitForge and its modules are separate downloads from now on -- one project each, updated on its own. Updating BitForge removed nothing, so everything you already had is still installed and still working."
L["upgrade:separate"] = "These are no longer part of the BitForge download, and nothing will update them again until you install each one as its own project:"
L["upgrade:renamed"] = "BitForge Dispatch has been renamed BitForge AzerothPrime, and is its own project under that name. Install it and everything Dispatch had saved -- rules, per-item lists, curation destinations, blacklists, the button's size and position -- comes with it. If the old Dispatch is still installed, AzerothPrime switches it off first and your settings arrive at your next login, so finding Dispatch greyed out in the addon list is expected rather than a fault; the folder is safe to delete then. One thing does not come across: the keybinding for the openables button, which the game stores under the button's name. Set it again in the Key Bindings panel."
L["upgrade:close"] = "Got it"

-- Said in chat, once per pair of versions, when a module and core were not
-- released beside each other. The project name is derived from the folder name
-- in control.lua and never translated; the two versions are .toc strings.
L["msg:outOfStep"] = "Update %s from CurseForge: it is on %s while BitForge is on %s. Each is its own download now, so an addon manager can update one and not the other."

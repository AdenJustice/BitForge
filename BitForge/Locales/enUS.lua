---@class ns.Core
local ns                                 = select(2, ...)
---@class BitForge.Locales.Core
local L                                  = ns.locale

-- Minimap Button
L["minimapButton:tooltip_settings"]      = "Click to Open Settings of BitForge."

-- Migration Dialog
L["migration:title"]                     = "Data Migration"
L["migration:desc"]                      = "The following characters share your class and may be the same character. Select one to migrate their settings to your current character, or skip to create a fresh entry."
L["migration:button_migrate"]            = "Migrate"
L["migration:button_skip"]               = "Skip"
L["migration:button_purge"]              = "Purge"
L["migration:button_keep_all"]           = "Keep All"

-- Purge Dialog
L["purge:title"]                         = "Purge Invalid Characters"
L["purge:desc"]                          = "The following characters haven't been seen recently. Select the ones whose addon data you'd like to permanently remove. This only affects BitForge's database — your characters are not deleted."
L["purge:label"]                         = "%s (|cffffff00last seen %d days ago|r)"

-- Settings
L["settings:plugins_header"]             = "List of Installed Plugins"
L["settings:plugins_tooltip"]            = "Check to activate the plugin for this character."
L["settings:characters_header"]          = "Character Management"
L["settings:lastSeenThreshold"]          = "Mark Characters as Invalid After"
L["settings:lastSeenThreshold_tooltip"]  = "Characters not seen within this many days will be flagged as invalid on login. Set to Never to disable."
L["settings:lastSeenThreshold_never"]    = "Never"
L["settings:lastSeenThreshold_days"]     = "%d Days"
L["settings:purgeInvalidButton"]         = "Purge Invalid Characters Now"
L["settings:purgeInvalidButton_tooltip"] = "Immediately remove addon data for characters that haven't been seen within the threshold period."

-- Notifications
L["notification:invalidCharacters"]      = "BitForge: %d character(s) not seen in over %d day(s). Open Settings to remove their addon data."
L["notification:nothingToPurge"]         = "BitForge: No invalid characters to purge."
L["notification:purgeComplete"]          = "BitForge: Addon data removed for %d character(s)."

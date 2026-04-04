---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "Undermine Parcel Service"
L["settings:enabled"] = "Enable UPS"
L["settings:enabledTooltip"] = "Deposit crafting reagents to the Warband Bank when you visit a bank"
L["settings:previewMoves"] = "Preview before depositing"
L["settings:previewMovesTooltip"] = "Show a confirmation window listing every move before anything is deposited"

-- Bank button
L["btn:deposit"] = "Deposit"
L["btn:depositing"] = "Depositing… %d"

-- Preview dialog
L["preview:title"] = "Confirm Deposit"
L["preview:summary"] = "%d item(s) in %d move(s)"
L["preview:toWarband"] = "→ Warband Bank"
L["preview:dontAskAgain"] = "Don't ask again"
L["btn:confirm"] = "Confirm"
L["btn:cancel"] = "Cancel"

-- Messages
L["msg:nothingToDo"] = "UPS: Nothing to move."
L["msg:done"] = "UPS: Done. Moved %d item(s)."
L["msg:noVacancy"] = "UPS: The Warband Bank is full."
L["msg:blockedCombat"] = "UPS: Stopped — you are in combat."
L["msg:blockedBankClosed"] = "UPS: Stopped — the bank closed."
L["msg:blockedCursor"] = "UPS: Stopped — something is on your cursor."
L["msg:blockedLocked"] = "UPS: Stopped — an item is locked."
L["msg:moveFailed"] = "UPS: Stopped — a move did not complete."
L["msg:openProfession"] = "UPS: Open your %s window once so UPS can record which recipes you know."

-- Curation window
L["curation:title"] = "UPS — Item Curation"
L["curation:open"] = "Curate Items"
L["curation:search"] = "Search"
L["curation:filterDestination"] = "Any destination"
L["curation:filterClass"] = "Any item type"
L["curation:source"] = "Source: %s"
L["curation:sourceBuiltIn"] = "This character"
L["curation:count"] = "%d item(s)"
L["curation:unscanned"] = "Never scanned for recipes: %s. Until they are, every recipe for their professions looks wanted and will be deposited."
L["curation:heldBy"] = "Held by"
L["curation:overrideTooltip"] = "You chose this destination. Reset to default to follow the rules again."

-- Destinations
L["dest:warband"] = "Warband Bank"
L["dest:private"] = "Your Bank"
L["dest:privateOwned"] = "Your Bank (%s)"
L["dest:ignore"] = "Leave alone"

-- Private destination
L["preview:toPrivate"] = "→ Your Bank"
L["preview:reclaim"] = "Warband Bank → Your Bank"
L["msg:noVacancyPrivate"] = "UPS: Your bank is full."
L["curation:privateTooltip"] = "Kept in a character's own bank rather than shared storage. With no owner chosen, the first character to visit a bank claims it."

-- Target quantity
L["curation:targetSuffix"] = "keep %d"
L["target:title"] = "Target Quantity"
L["target:prompt"] = "How many %s should each owner keep?"

-- Row menu
L["menu:resetToDefault"] = "Reset to default"
L["menu:owners"] = "Owners"
L["menu:target"] = "Target quantity"
L["menu:targetNone"] = "No limit"
L["menu:targetOther"] = "Other…"

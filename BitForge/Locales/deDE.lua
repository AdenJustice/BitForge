if GetLocale() ~= "deDE" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Linksklick für Optionen"
L["minimap:hintDrag"] = "Zum Verschieben ziehen"
L["minimap:compartmentTooltip"] = "BitForge-Menü öffnen"

-- Schema upgrade
L["msg:schemaResetBody"] = "Die gespeicherten Daten für %s stammen aus einer älteren Version und können nicht übernommen werden. Sie werden gelöscht und neu aufgebaut. Dies geschieht einmalig."
L["btn:schemaResetAccept"] = "Löschen und fortfahren"

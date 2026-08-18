if GetLocale() ~= "itIT" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Clic sinistro per le opzioni"
L["minimap:hintDrag"] = "Trascina per spostare"
L["minimap:compartmentTooltip"] = "Apri il menu di BitForge"

-- Schema upgrade
L["msg:schemaResetBody"] = "I dati salvati di %s provengono da una versione precedente e non possono essere mantenuti. Verranno cancellati e ricostruiti. Questo accade una sola volta."
L["btn:schemaResetAccept"] = "Cancella e continua"

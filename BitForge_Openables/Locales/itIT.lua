---@class BitForge.Openables
local ns = select(2, ...)
if GetLocale() ~= "itIT" then return end
local L = ns.locale

-- Settings panel
L["panel:title"] = "Apribili"
L["settings:enabled"] = "Attiva Apribili"
L["settings:enabledTooltip"] = "Mostra un pulsante per il prossimo oggetto apribile o utilizzabile nelle borse"
L["settings:locked"] = "Blocca pulsante"
L["settings:lockedTooltip"] = "Impedisce lo spostamento del pulsante"
L["settings:buttonSize"] = "Dimensione del pulsante"
L["settings:buttonSizeTooltip"] = "Larghezza e altezza del pulsante, in pixel"
L["settings:showCount"] = "Mostra quantità"
L["settings:showCountTooltip"] = "Mostra quanti esemplari dell'oggetto possiedi"
L["settings:showCooldown"] = "Mostra recupero"
L["settings:showCooldownTooltip"] = "Mostra il tempo di recupero sul pulsante"
L["settings:resetPosition"] = "Reimposta posizione"
L["settings:manageBlacklist"] = "Gestisci lista di esclusione"

-- Button tooltip
L["tooltip:use"] = "Clic sinistro per aprire o usare."
L["tooltip:skip"] = "Clic destro per saltare in questa sessione."
L["tooltip:blacklist"] = "Ctrl + clic destro per escludere definitivamente."
L["tooltip:drag"] = "Alt + trascina per spostare."

-- Blacklist
L["blacklist:windowTitle"] = "Oggetti esclusi"
L["blacklist:empty"] = "Nessun oggetto è escluso."
L["blacklist:remove"] = "Rimuovi"
L["blacklist:clearAll"] = "Cancella tutto"
L["blacklist:unknownItem"] = "Oggetto %d"

-- Key bindings
L["binding:header"] = "BitForge Apribili"
L["binding:use"] = "Usa oggetto apribile"

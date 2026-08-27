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

-- Slash commands
L["cmd:usage"] = "/bitforge <modulo> [argomenti], /bfdump <modulo> [argomenti] -- un nome di modulo può essere abbreviato a qualsiasi prefisso non ambiguo"
L["cmd:unknownModule"] = "nessun modulo di nome %s -- usa /bitforge per l'elenco"
L["cmd:ambiguousModule"] = "%s indica più di un modulo: %s"
L["cmd:noSuchCommand"] = "%s non risponde al comando %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- mostra le novità di questo aggiornamento"

-- Report window
L["report:windowTitle"] = "Segnala un oggetto"
L["report:howTo"] = "Seleziona tutto, poi premi Ctrl+C. Incollalo in una nuova segnalazione su:"
L["report:selectAll"] = "Seleziona tutto"

-- The release-notes popup
L["whatsNew:windowTitle"] = "Novità di BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Chiudi"

if GetLocale() ~= "itIT" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Servizio Pacchi di Sottominiera"
L["settings:enabled"] = "Attiva UPS"
L["settings:enabledTooltip"] = "Deposita i materiali d'artigianato nella Banca della Compagnia quando visiti una banca"
L["settings:previewMoves"] = "Anteprima prima del deposito"
L["settings:previewMovesTooltip"] = "Mostra una finestra di conferma con tutti gli spostamenti prima di depositare qualsiasi cosa"

L["btn:deposit"] = "Deposita"
L["btn:depositing"] = "Deposito in corso… %d"

L["preview:title"] = "Conferma deposito"
L["preview:summary"] = "%d oggetto/i in %d spostamento/i"
L["preview:toWarband"] = "→ Banca della Compagnia"
L["preview:dontAskAgain"] = "Non chiedere più"
L["btn:confirm"] = "Conferma"
L["btn:cancel"] = "Annulla"

L["msg:nothingToDo"] = "UPS: Niente da spostare."
L["msg:done"] = "UPS: Fatto. %d oggetto/i spostato/i."
L["msg:noVacancy"] = "UPS: La Banca della Compagnia è piena."
L["msg:blockedCombat"] = "UPS: Interrotto — sei in combattimento."
L["msg:blockedBankClosed"] = "UPS: Interrotto — la banca si è chiusa."
L["msg:blockedCursor"] = "UPS: Interrotto — hai qualcosa sul cursore."
L["msg:blockedLocked"] = "UPS: Interrotto — un oggetto è bloccato."
L["msg:moveFailed"] = "UPS: Interrotto — uno spostamento non è riuscito."
L["msg:openProfession"] = "UPS: Apri una volta la finestra %s così UPS può registrare quali ricette conosci."

-- Curation window
L["curation:title"] = "UPS — Catalogazione oggetti"
L["curation:open"] = "Cataloga oggetti"
L["curation:search"] = "Cerca"
L["curation:filterDestination"] = "Qualsiasi destinazione"
L["curation:filterClass"] = "Qualsiasi tipo di oggetto"
L["curation:source"] = "Fonte: %s"
L["curation:sourceBuiltIn"] = "Questo personaggio"
L["curation:count"] = "%d oggetto/i"
L["curation:unscanned"] = "Mai analizzati per le ricette: %s. Fino ad allora ogni ricetta delle loro professioni risulta utile e verrà depositata."
L["curation:heldBy"] = "Posseduto da"
L["curation:overrideTooltip"] = "Hai scelto tu questa destinazione. Ripristina il valore predefinito per tornare a seguire le regole."

-- Destinations
L["dest:warband"] = "Banca della Compagnia"
L["dest:private"] = "La tua banca"
L["dest:privateOwned"] = "La tua banca (%s)"
L["dest:ignore"] = "Lascia stare"

-- Private destination
L["preview:toPrivate"] = "→ La tua banca"
L["preview:reclaim"] = "Banca della Compagnia → La tua banca"
L["msg:noVacancyPrivate"] = "UPS: La tua banca è piena."
L["curation:privateTooltip"] = "Conservato nella banca personale di un personaggio anziché nel deposito condiviso. Senza un proprietario scelto, lo reclama il primo personaggio che visita una banca."

-- Target quantity
L["curation:targetSuffix"] = "tieni %d"
L["target:title"] = "Quantità obiettivo"
L["target:prompt"] = "Quanti %s deve tenere ogni proprietario?"

-- Row menu
L["menu:resetToDefault"] = "Ripristina predefinito"
L["menu:owners"] = "Proprietari"
L["menu:target"] = "Quantità obiettivo"
L["menu:targetNone"] = "Nessun limite"
L["menu:targetOther"] = "Altro…"

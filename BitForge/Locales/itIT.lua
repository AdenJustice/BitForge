if GetLocale() ~= "itIT" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "Clic sinistro per le opzioni"
L["minimap:hintDrag"] = "Trascina per spostare"
L["minimap:compartmentTooltip"] = "Apri il menu di BitForge"

L["msg:schemaResetBody"] = "I dati salvati di %s provengono da una versione precedente e non possono essere mantenuti. Verranno cancellati e ricostruiti. Questo accade una sola volta."
L["btn:schemaResetAccept"] = "Cancella e continua"

L["cmd:usage"] = "/bitforge <modulo> [argomenti], /bfdump <modulo> [argomenti] -- un nome di modulo può essere abbreviato a qualsiasi prefisso non ambiguo"
L["cmd:unknownModule"] = "nessun modulo di nome %s -- usa /bitforge per l'elenco"
L["cmd:ambiguousModule"] = "%s indica più di un modulo: %s"
L["cmd:noSuchCommand"] = "%s non risponde al comando %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- mostra le novità di questo aggiornamento"

L["report:windowTitle"] = "Segnala un oggetto"
L["report:windowTitleDiagnostic"] = "Rapporto diagnostico"
L["report:howTo"] = "Seleziona tutto, poi premi Ctrl+C. Incollalo in una nuova segnalazione su:"
L["report:selectAll"] = "Seleziona tutto"
L["report:encoded"] = "Questo rapporto era troppo lungo da leggere, quindi è stato compresso. Incollalo così com'è -- gli strumenti dello sviluppatore lo decomprimeranno."

L["whatsNew:windowTitle"] = "Novità di BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Chiudi"

L["upgrade:windowTitle"] = "BitForge ora è sei download"
L["upgrade:lead"] = "Da adesso BitForge e i suoi moduli sono download separati: un progetto ciascuno, aggiornato per conto proprio. L'aggiornamento di BitForge non ha rimosso nulla, quindi tutto quello che avevi già è ancora installato e funziona ancora."
L["upgrade:separate"] = "Questi non fanno più parte del download di BitForge, e nulla li aggiornerà più finché non installi ciascuno come progetto a sé:"
L["upgrade:renamed"] = "BitForge Dispatch è stato rinominato BitForge AzerothPrime, ed è un progetto a sé con quel nome. Installalo e tutto ciò che Dispatch aveva salvato -- regole, liste per oggetto, destinazioni di deposito, liste nere, dimensione e posizione del pulsante -- viene con lui. Se il vecchio Dispatch è ancora installato, AzerothPrime lo disattiva per primo e le tue impostazioni arrivano al tuo prossimo accesso: vedere Dispatch in grigio nell'elenco degli addon è quindi previsto e non un guasto, e a quel punto la cartella si può eliminare. Una cosa non si sposta: l'assegnazione tasti del pulsante degli oggetti apribili, che il gioco salva sotto il nome del pulsante. Riassegnala in Assegnazione Tasti."
L["upgrade:close"] = "Ho capito"

L["msg:outOfStep"] = "Aggiorna %s da CurseForge: è alla %s mentre BitForge è alla %s. Ora ciascuno è un download a sé, quindi un gestore di addon può aggiornarne uno e non l'altro."

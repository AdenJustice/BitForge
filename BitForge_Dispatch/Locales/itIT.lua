if GetLocale() ~= "itIT" then return end
---@class BitForge.Dispatch
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "Dispatch"
L["settings:openEnabled"] = "Attiva il pulsante degli oggetti apribili"
L["settings:openEnabledTooltip"] = "Mostra un pulsante per il prossimo oggetto apribile o utilizzabile nelle borse"
L["settings:sellEnabled"] = "Attiva la vendita ai venditori"
L["settings:sellEnabledTooltip"] = "Vende gli oggetti selezionati da una regola quando apri la finestra di un venditore. Non viene venduto nulla finché non imposti una regola"
L["settings:bankEnabled"] = "Attiva il deposito nella Banca della Brigata"
L["settings:bankEnabledTooltip"] = "Deposita componenti, ricette utili ai tuoi altri personaggi e gli oggetti che cataloghi quando visiti una banca"

-- Leftover-install guard
L["msg:replacedInstalled"] = "Dispatch: Ancora installato — %s."
L["msg:replacedInstalledFix"] = "Elimina la vecchia installazione e accedi di nuovo per lasciare che Dispatch subentri."

-- Openables button
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

L["tooltip:use"] = "Clic sinistro per aprire o usare."
L["tooltip:skip"] = "Clic destro per saltare in questa sessione."
L["tooltip:blacklist"] = "Ctrl + clic destro per escludere definitivamente."
L["tooltip:report"] = "Maiusc + Alt + clic destro per segnalare questo verdetto."
L["tooltip:drag"] = "Alt + trascina per spostare."

L["report:blurbOpen"] = "Questo rapporto include l'oggetto, la sua borsa e il suo slot e se è bloccato, come BitForge lo ha classificato, il testo del suo tooltip e quali mestieri conosce questo personaggio. Niente qui menziona il tuo personaggio, regno, gilda o fazione."

L["report:blurbField"] = "Questo rapporto include ogni candidato che l'ultima scansione ha classificato per la prossima apertura, nell'ordine di classifica: nome, ID oggetto, borsa e slot, quantità in pila, priorità e il motivo della sua posizione, se è una cassa chiusa a chiave, se il suo slot è attualmente bloccato, e se è in recupero o rimandato. Niente qui menziona il tuo personaggio, regno, gilda o fazione, e non è incluso il testo del tooltip di alcun oggetto."

L["report:blurbAllowList"] = "Questo rapporto include ogni oggetto delle due liste di apertura che l'addon tiene a mano -- la lista di apertura consentita e quella di apertura negata, una sezione per ciascuna, o una sola quando ne indichi una. Ogni riga dà l'ID oggetto e il nome, il verdetto a cui arrivano le regole di apertura quando quella lista viene ignorata, il gradino che lo ha raggiunto, la priorità che quel gradino ha assegnato e, solo per la lista consentita, quella a cui essa lo fissa, e il gruppo in cui ricade la voce. Quando una riga dice invece che i dati dell'oggetto o il suo tooltip non sono mai arrivati, questo descrive la cache di questo client nel momento in cui hai lanciato il comando e non l'oggetto in sé; alla prima esecuzione vale per gran parte della lista consentita. Legge le liste fornite e il tooltip di ogni oggetto tramite il suo ID, quindi non descrive nulla delle tue borse -- tranne che un oggetto delle liste che hai escluso o saltato in questa sessione viene indicato come tale, così come un verdetto che è dipeso dallo stato di questo personaggio, ad esempio se puoi usare l'oggetto o aprire una cassa chiusa a chiave. Niente qui nomina il tuo personaggio, il tuo regno, la tua gilda o la tua fazione."

L["blacklist:windowTitle"] = "Oggetti esclusi"
L["blacklist:empty"] = "Nessun oggetto è escluso."
L["blacklist:remove"] = "Rimuovi"
L["blacklist:clearAll"] = "Cancella tutto"
L["blacklist:unknownItem"] = "Oggetto %d"

L["binding:header"] = "BitForge Dispatch"
L["binding:use"] = "Usa oggetto apribile"

L["settings:previewMoves"] = "Anteprima prima del deposito"
L["settings:previewMovesTooltip"] = "Mostra una finestra di conferma con tutti gli spostamenti prima di depositare qualsiasi cosa"
L["settings:onlyWantedReagents"] = "Deposita solo componenti utilizzabili"
L["settings:onlyWantedReagentsTooltip"] = "Deposita solo componenti che un mestiere di questo account può lavorare. Disattivato deposita tutto, per la casa d'aste"

L["btn:deposit"] = "Deposita"
L["btn:depositing"] = "Deposito in corso… %d"

L["preview:title"] = "Conferma deposito"
L["preview:summary"] = "%d oggetto/i in %d spostamento/i"
L["preview:toWarband"] = "→ Banca della Brigata"
L["preview:dontAskAgain"] = "Non chiedere più"
L["btn:confirm"] = "Conferma"
L["btn:cancel"] = "Annulla"

L["msg:nothingToDo"] = "Dispatch: Niente da spostare."
L["msg:done"] = "Dispatch: Fatto. %d oggetto/i spostato/i."
L["msg:noVacancy"] = "Dispatch: La Banca della Brigata è piena."
L["msg:blockedCombat"] = "Dispatch: Interrotto — sei in combattimento."
L["msg:blockedBankClosed"] = "Dispatch: Interrotto — la banca si è chiusa."
L["msg:blockedCursor"] = "Dispatch: Interrotto — hai qualcosa sul cursore."
L["msg:blockedLocked"] = "Dispatch: Interrotto — un oggetto è bloccato."
L["msg:moveFailed"] = "Dispatch: Interrotto — uno spostamento non è riuscito."
L["msg:openProfession"] = "Dispatch: Apri una volta la finestra %s così Dispatch può registrare quali ricette conosci."

-- Curation window
L["curation:title"] = "Catalogazione oggetti"
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
L["dest:warband"] = "Banca della Brigata"
L["dest:private"] = "La tua banca"
L["dest:privateOwned"] = "La tua banca (%s)"
L["dest:ignore"] = "Lascia stare"

-- Private destination
L["preview:toPrivate"] = "→ La tua banca"
L["preview:reclaim"] = "Banca della Brigata → La tua banca"
L["msg:noVacancyPrivate"] = "Dispatch: La tua banca è piena."
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

L["panel:batchSell"] = "Vendita in blocco"
L["panel:sellManifest"] = "Manifesto vendita"
L["panel:blacklist"] = "Lista nera"
L["panel:whitelist"] = "Lista bianca"

L["ui:ruleWindowTitle"] = "Regole di vendita in blocco"
L["ui:ruleWindowNothingToConfigure"] = "Qui non c'è nulla da configurare."
L["ui:ruleWindowDisclaimer"] =
"In combattimento e nelle istanze, il gioco a volte non rivela i dettagli di un oggetto. Dispatch tiene questi oggetti invece di indovinare, quindi alcuni potrebbero mancare dalla lista -- questo è previsto. Un verdetto che sembra sbagliato per qualsiasi altro motivo vale la pena segnalarlo."
L["ui:selectedCount"] = "Selezione: %d"
L["ui:reagentsNoProfession"] =
"Nessun personaggio di questo account ha ancora un mestiere, quindi questa regola non conserva nulla. Entra con uno che ne abbia uno e questi controlli tornano disponibili."

L["btn:sellAll"] = "Vendi tutto"
L["btn:refresh"] = "Aggiorna"
L["btn:rules"] = "Regole"

L["menu:temporaryExclude"] = "Escludi temporaneamente"
L["menu:blacklisted"] = "Lista nera"
L["menu:whitelisted"] = "Lista bianca"
L["menu:noStatus"] = "Nessuna"
L["menu:reportVerdict"] = "Segnala questo verdetto"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "Contrassegna i componenti di questa ricetta"

L["status:noItemsToSell"] = "Nessun oggetto da vendere"
L["status:itemsTotal"] = "%d oggetti  |  Totale: %s"

L["ui:manifestHint"] = "Ti aspettavi qualcosa che non è nell'elenco? Passa il mouse su di esso nelle borse per scoprire perché."

-- Merchant row
L["tooltip:charOverride"] =
"L'impostazione di questo personaggio ha la precedenza sulla lista della Brigata: questo oggetto verrà venduto."

L["section:general"] = "Generale"
L["section:lists"] = "Liste"
L["section:everyItem"] = "Ogni oggetto"
L["section:byItemType"] = "Per tipo di oggetto"

L["settings:openRuleWindow"] = "Visualizza regole"
L["settings:openRuleWindowTooltip"] =
"Spiega cosa cerca ogni regola e perché un oggetto è stato tenuto o venduto"
L["settings:sellJunk"] = "Vendi spazzatura"
L["settings:sellJunkTooltip"] = "Vendi automaticamente tutti gli oggetti di qualità scadente (grigi) quando visiti un venditore"
L["settings:limitBatch"] = "Limita blocco a 12"
L["settings:limitBatchTooltip"] = "Vendi al massimo 12 oggetti per clic per evitare la limitazione del server"
L["settings:keepUsedReagents"] = "Conserva i componenti dei tuoi mestieri"
L["settings:keepUsedReagentsTooltip"] =
"Conserva i componenti d'artigianato che un mestiere di questo account può usare. Una copia legata all'anima non raggiungerà mai un altro personaggio, quindi la conservano solo i mestieri di questo personaggio"
L["settings:reagentsExpansions"] = "Quali componenti conservare"
L["settings:reagentsExpansionsTooltip"] =
"Da quali espansioni la regola qui sopra conserva i componenti. Parte impostata solo su questa espansione, quindi i componenti più vecchi finiscono in vendita, tranne quelli che servono ancora a una ricetta che hai contrassegnato: quelli vengono conservati qualunque cosa selezioni qui"
L["settings:margin"] = "Margine livello oggetto"
L["settings:marginTooltip"] =
"Di quanto un pezzo della tua stessa qualità può restare sotto lo slot prima di essere venduto. Con 0 basta eguagliare lo slot"
L["settings:qualityMargin"] = "Margine qualità"
L["settings:qualityMarginTooltip"] =
"Quanto vale un grado di qualità in livelli oggetto. Con 10, un pezzo un grado sotto quello che indossi ha bisogno di 10 livelli oggetto in più per essere tenuto, e uno un grado sopra sopravvive 10 sotto. Con 0 la qualità smette di contare e decide solo il livello dell'oggetto. Con Sempre, qualsiasi qualità superiore viene tenuta a prescindere dal livello oggetto, e nessun livello oggetto salva una inferiore"
L["settings:qualityMarginAlways"] = "Sempre"
L["settings:keepForDisenchant"] = "Mantieni l'equipaggiamento in base all'espansione dei materiali"
L["settings:keepForDisenchantTooltip"] =
"Mantieni l'equipaggiamento che un incantatore potrebbe disincantare, in base all'espansione dei materiali che produrrebbe anziché all'età dell'equipaggiamento stesso -- l'equipaggiamento di un'espansione conclusa produce i materiali di quell'espansione. Il tuo incantatore personale mantiene sempre ciò che solo lui può raggiungere, con qualsiasi impostazione, ma questa decide comunque se ciò si estende anche ai materiali più vecchi"
L["settings:spareBindOnAccount"] = "Risparmia equipaggiamento legato all'account"
L["settings:spareBindOnAccountTooltip"] =
"Da quali espansioni mantenere l'equipaggiamento legato all'account finché può ancora passare a un altro personaggio"
L["settings:spareBindOnEquip"] = "Risparmia equipaggiamento che si lega quando indossato"
L["settings:spareBindOnEquipTooltip"] =
"Da quali espansioni mantenere l'equipaggiamento che si lega quando indossato finché può ancora raggiungere un altro personaggio o la casa d'aste"
L["settings:keepUncollectedCosmetic"] = "Mantieni gli aspetti non raccolti"
L["settings:keepUncollectedCosmeticTooltip"] =
"Mantiene qualsiasi oggetto il cui aspetto non hai ancora raccolto. Vendere un pezzo comune lo raccoglie comunque, ma un oggetto cosmetico concede il suo aspetto solo all'uso: venderlo significa perderlo per sempre"
L["settings:sellRelics"] = "Vendi le reliquie di Classic"
L["settings:sellRelicsTooltip"] =
"Vende idoli, libri sacri, totem e sigilli, lo slot reliquia che Cataclysm ha rimosso. Non le reliquie degli artefatti di Legion, che sono gemme e ne condividono solo il numero di sottoclasse"
L["settings:gemsExpansions"] = "Quali gemme conservare"
L["settings:gemsExpansionsTooltip"] =
"Da quali espansioni conservare le gemme. Ciò che non è selezionato passa alle due domande qui sotto"
L["settings:gemsRecipesNow"] = "Mantieni le gemme attuali che una ricetta usa"
L["settings:gemsRecipesNowTooltip"] =
"Mantiene una gemma dell'espansione corrente che una ricetta di professione usa come componente, di chiunque sia quella professione. La domanda va al catalogo delle ricette, e una gemma che non vi compare vale come una che nessuna ricetta vuole"
L["settings:gemsRecipesOld"] = "Mantieni le gemme vecchie che una ricetta usa"
L["settings:gemsRecipesOldTooltip"] =
"La stessa domanda per le gemme delle espansioni passate. Ciò che usano le tue professioni è già mantenuto altrove, quindi questa colonna vale per le ricette di tutti gli altri"
L["settings:keepArtifactRelics"] = "Mantieni le reliquie degli artefatti"
L["settings:keepArtifactRelicsTooltip"] =
"Mantiene le reliquie che si incastonavano nelle armi artefatto di Legion. Da Legion in poi nulla le usa più, quindi conviene disattivarlo a meno che tu non le collezioni"
L["settings:enhancementsExpansions"] = "Quali potenziamenti conservare"
L["settings:enhancementsExpansionsTooltip"] =
"Da quali espansioni conservare i potenziamenti per oggetti. Una nuova espansione limita l'equipaggiamento a cui un potenziamento si applica, quindi seleziona l'espansione il cui equipaggiamento indossi davvero"
L["settings:keepLearnable"] = "Mantieni le ricette che puoi imparare"
L["settings:keepLearnableTooltip"] =
"Mantiene una ricetta che questo personaggio non ha imparato"
L["settings:keepTradeableRecipes"] = "Mantieni le ricette commerciabili"
L["settings:keepTradeableRecipesTooltip"] =
"Mantiene una ricetta ancora non legata, così da poter raggiungere un personaggio secondario o la casa d'aste anche quando questo personaggio l'ha già imparata"
L["settings:sellCollectedMounts"] = "Vendi le cavalcature già ottenute"
L["settings:sellCollectedMountsTooltip"] =
"Vende una cavalcatura che possiedi già, purché quella copia sia legata all'anima. Una copia non legata viene mantenuta qualunque cosa dica questa opzione, perché può ancora raggiungere qualcuno"
L["settings:sellCollectedToys"] = "Vendi i giocattoli già ottenuti"
L["settings:sellCollectedToysTooltip"] =
"Vende un giocattolo che possiedi già, purché la copia nelle tue borse sia legata. Una copia non legata viene mantenuta qualunque cosa dica la tua collezione, perché può ancora raggiungere qualcuno"
L["settings:sellCollectedPets"] = "Vendi le mascotte già ottenute"
L["settings:sellCollectedPetsTooltip"] =
"Vende una mascotte da combattimento che hai già. Una che non hai mai ottenuto non viene mai venduta da questa regola, in nessuna delle due posizioni"
L["settings:sellHoliday"] = "Vendi gli oggetti festivi"
L["settings:sellHolidayTooltip"] =
"Vende i gettoni, i costumi e le curiosità che gli eventi mondiali lasciano nelle tue borse"
L["settings:sellMountEquipment"] = "Vendi l'equipaggiamento da cavalcatura"
L["settings:sellMountEquipmentTooltip"] =
"Vende l'equipaggiamento da cavalcatura. Si applica un solo pezzo per volta a tutto l'account, quindi i pezzi di scorta nelle tue borse non fanno nulla"
L["settings:sellCollectedDecor"] = "Vendi gli decorazioni già ottenuti"
L["settings:sellCollectedDecorTooltip"] =
"Vende gli decorazioni per la casa che il tuo catalogo possiede già. Un pezzo che non ha mai visto viene mantenuto, e così anche uno per cui il catalogo non si è potuto leggere"
L["settings:keepTradeableDyes"] = "Mantieni le tinture commerciabili"
L["settings:keepTradeableDyesTooltip"] =
"Una tintura si consuma quando viene applicata e non si impara mai, quindi non c'è nessuna collezione a cui chiedere. Si chiede invece se questa copia può ancora raggiungere qualcuno: non legata viene mantenuta, legata venduta"
L["settings:spareProfessions"] = "Risparmia per questi mestieri"
L["settings:spareProfessionsTooltip"] =
"Conserva un materiale da mestiere se un mestiere selezionato qui potrebbe usarlo come componente -- per un altro personaggio che non lo ha ancora imparato, o per la casa d'aste. I mestieri di questo account sono già coperti da Conserva i componenti dei tuoi mestieri"

L["spare:none"] = "Nessuno"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "Tutte le espansioni"
L["expansion:current"] = "Espansione attuale"

L["profession:FirstAid"] = "Primo Soccorso"
L["profession:Blacksmithing"] = "Forgiatura"
L["profession:Leatherworking"] = "Conciatura"
L["profession:Alchemy"] = "Alchimia"
L["profession:Herbalism"] = "Erbalismo"
L["profession:Cooking"] = "Cucina"
L["profession:Mining"] = "Estrazione"
L["profession:Tailoring"] = "Sartoria"
L["profession:Engineering"] = "Ingegneria"
L["profession:Enchanting"] = "Incantamento"
L["profession:Fishing"] = "Pesca"
L["profession:Skinning"] = "Scuoiatura"
L["profession:Jewelcrafting"] = "Oreficeria"
L["profession:Inscription"] = "Runografia"
L["profession:Archaeology"] = "Archeologia"

L["sub:0"] = "Generico"
L["sub:1"] = "Pozione"
L["sub:2"] = "Elisir"
L["sub:3"] = "Fiale e ampolle"
L["sub:5"] = "Cibo e bevande"
L["sub:7"] = "Benda"
L["sub:8"] = "Altro"
L["sub:9"] = "Runa di Vantus"

L["option:expansions"] = "Quali espansioni conservare"
L["option:recipesNow"] = "Tieni anche quelli di questa espansione se una ricetta li vuole"
L["option:recipesOld"] = "Tieni anche quelli più vecchi se una ricetta li vuole"

-- List tabs
L["btn:removeEntry"] = "Rimuovi"
L["list:warband"] = "Brigata"
L["list:character"] = "Personaggio"
L["status:listEmpty"] = "Questa lista è vuota"
L["status:listCount"] = "%d voci"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Vendita in blocco: verrà venduto"
L["verdict:keep"] = "Vendita in blocco: verrà mantenuto"
L["claimed:OPEN"] = "Il pulsante di apertura lo ha reclamato"
L["claimed:DEPOSIT_WARBAND"] = "Andrà invece nella Banca della Brigata"
L["claimed:DEPOSIT_PRIVATE"] = "Andrà invece nella banca personale di un personaggio"
L["reason:TEMP_EXCLUDED"] = "Escluso per questa visita al venditore"
L["reason:BLACKLISTED"] = "Nella tua lista nera"
L["reason:LOCKED"] = "L'oggetto è bloccato"
L["reason:EQUIPMENT_SET"] = "Fa parte di un set di equipaggiamento"
L["reason:NO_SELL_PRICE"] = "Nessun venditore lo acquisterà"
L["reason:REFUNDABLE"] = "Ancora entro il periodo di rimborso"
L["reason:WHITELISTED"] = "Nella tua lista bianca"
L["reason:TEMP_INCLUDED"] = "Aggiunto per questa visita al venditore"
L["reason:JUNK"] = "«Vendi spazzatura» è disattivato, la spazzatura non viene toccata"
L["reason:JUNK_SOLD"] = "«Vendi spazzatura» è attivato, la spazzatura viene venduta"
L["reason:ABOVE_EPIC"] = "Migliore di epico, quindi non viene mai venduto"
L["reason:BIND_ON_ACCOUNT"] = "L'equipaggiamento legato all'account viene mantenuto"
L["reason:DISENCHANTABLE"] = "Vale la pena mantenerlo per disincantarlo o rivenderlo"
L["reason:BAG_KEPT"] = "Le borse non vengono mai vendute"
L["reason:PROFESSION_GEAR_KEPT"] = "L'equipaggiamento da mestiere non viene mai venduto"
L["reason:ENHANCEMENT_EXPANSION"] = "I miglioramenti oggetto di questa espansione vengono mantenuti"
L["reason:CONSUMABLE_EXPANSION"] = "I consumabili di questa espansione vengono mantenuti"
L["reason:CONSUMABLE_REAGENT"] = "Una ricetta da qualche parte lo usa come componente"
L["reason:GEM_EXPANSION"] = "Le gemme di questa espansione vengono mantenute"
L["reason:GEM_REAGENT"] = "Una ricetta da qualche parte lo usa come componente"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "Le reliquie di artefatto vengono mantenute"
L["reason:TRADE_GOOD_SPARED"] = "Un mestiere che hai scelto di risparmiare lo vuole"
L["reason:NOT_WANTED"] = "Nessuna casella conserva l'oggetto, quindi viene venduto"
L["reason:REAGENT_WANTED"] = "Un mestiere che può usarlo lo vuole come componente"
L["reason:NOT_EQUIPPABLE"] = "Non equipaggiabile o non consigliato per la tua classe"
L["reason:EQUIPPABLE"] = "Abbastanza buono rispetto al tuo equipaggiamento indossato"
L["reason:OUTCLASSED"] = "Superato dal tuo equipaggiamento indossato"
L["reason:OUTDATED_EXPAC"] = "Supera il tuo equipaggiamento attuale, dell'espansione precedente"
L["reason:BIND_ON_EQUIP"] = "L'equipaggiamento che si lega quando indossato viene mantenuto"
L["reason:ARMOR_RELIC"] = "Nessuno può più equipaggiare una reliquia, quindi viene venduta"
L["reason:RECIPE_LEARNABLE"] = "Non ancora imparata, quindi viene mantenuta"
L["reason:HOLIDAY_ITEM"] = "Gli oggetti festivi vengono venduti"
L["reason:MOUNT_EQUIPMENT"] = "L'equipaggiamento da cavalcatura viene venduto"
L["reason:ALREADY_COLLECTED"] = "L'oggetto è già stato collezionato, quindi viene venduto"
L["reason:NOT_COLLECTED"] = "L'oggetto non è ancora stato collezionato, quindi viene mantenuto"
L["reason:STILL_TRADEABLE"] = "L'oggetto è ancora scambiabile, quindi viene mantenuto"
L["reason:ALREADY_LEARNED"] = "L'oggetto è già stato imparato, quindi viene venduto"
L["reason:DEFAULT"] = "Nessuna regola lo ha reclamato, quindi viene mantenuto"

L["listReset:warbandBlacklist"] = "Reimposta lista nera della Brigata"
L["listReset:warbandWhitelist"] = "Reimposta lista bianca della Brigata"
L["listReset:charBlacklist"] = "Reimposta lista nera del personaggio"
L["listReset:charWhitelist"] = "Reimposta lista bianca del personaggio"
L["listReset:confirm"] = "Sei sicuro di voler svuotare questa lista? L'operazione non può essere annullata."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Impossibile vendere %s in questo momento: %s"
L["msg:dropUnexcluded"] = "%s non è più escluso e verrà venduto in questa visita"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "Bloccato temporaneamente"
L["rule:tempSub"] = "Solo per questa visita al venditore"
L["rule:tempBlurb"] =
"Oggetti che hai rimosso dalla lista di vendita prima di premere Vendi. Restano nelle tue borse per questa visita e vengono valutati di nuovo normalmente dal prossimo venditore."
L["rule:black"] = "Non vendere mai"
L["rule:blackSub"] = "La tua lista Non vendere mai"
L["rule:blackBlurb"] =
"Tutto ciò che è nella tua lista Non vendere mai resta nelle tue borse. Un'impostazione su questo personaggio prevale sulla lista della Brigata, in qualunque direzione i due siano in disaccordo."
L["rule:gates"] = "Non vendibile"
L["rule:gatesSub"] = "Il venditore non li accetta"
L["rule:gatesBlurb"] =
"Oggetti bloccati, tutto ciò che fa parte di un set di equipaggiamento, oggetti senza prezzo di vendita e acquisti ancora entro il periodo di rimborso. La tua lista Vendi sempre non prevale su questi, perché il venditore rifiuterebbe comunque la vendita."
L["rule:white"] = "Vendi sempre"
L["rule:whiteSub"] = "La tua lista Vendi sempre"
L["rule:whiteBlurb"] =
"Tutto ciò che è nella tua lista Vendi sempre viene venduto, anche quando una regola successiva lo avrebbe tenuto. È così che vendi quell'unico componente d'artigianato che non vuoi."
L["rule:tempIn"] = "Incluso per questa visita"
L["rule:tempInSub"] = "Solo per questa visita al venditore"
L["rule:tempInBlurb"] =
"Oggetti che hai trascinato nella lista di vendita da questo venditore. Vengono venduti in questa visita e valutati di nuovo normalmente nella prossima."
L["rule:junk"] = "Qualità scadente"
L["rule:junkSub"] = "Disattivato per impostazione predefinita"
L["rule:junkBlurb"] =
"Oggetti grigi, qualunque sia il loro tipo. Disattivato per impostazione predefinita, perché di solito se ne occupa un altro addon. Se nessun altro lo fa, attivalo e Dispatch li eliminerà per te."
L["rule:epic"] = "Leggendario e superiore"
L["rule:epicSub"] = "Leggendario, Manufatto, Cimelio"
L["rule:epicBlurb"] =
"Non viene mai venduto. Il venditore mostra un prezzo per questi oggetti e poi rifiuta la vendita, quindi Dispatch non li mette in lista."
L["rule:reagent"] = "Componenti da mestiere"
L["rule:reagentSub"] = "Usa la tua lista di mestieri"
L["rule:reagentBlurb"] =
"Conserva qualsiasi componente che un mestiere di questo account possa usare, qualunque sia il tipo di oggetto. I componenti compaiono sia come pozioni, sia come gemme che come materiali da mestiere, quindi questo viene controllato prima del tipo dell'oggetto. Finché non decidi diversamente vengono conservati solo quelli di questa espansione; uno più vecchio viene conservato lo stesso se serve ancora a una ricetta che hai contrassegnato, qualunque espansione sia selezionata. L'elenco viene letto dalle ricette del gioco stesso, quindi contiene già i componenti opzionali che una ricetta accetta e ogni livello di qualità -- non devi aprire né scansionare nulla."
L["rule:cosmetic"] = "Aspetti non collezionati"
L["rule:cosmeticSub"] = "Oggetti estetici che non hai ancora collezionato"
L["rule:cosmeticBlurb"] =
"Un oggetto estetico che non hai collezionato viene tenuto. Venderlo non ne colleziona l'aspetto -- semplicemente sparisce --, quindi questo è l'unico punto della finestra in cui un errore non può essere annullato. Un oggetto estetico che hai già collezionato non viene venduto solo per esserlo; non porta più nulla da proteggere, e viene comunque valutato come l'arma o l'armatura che è."
L["rule:consumables"] = "Consumabili"
L["rule:consumablesSub"] = "Pozioni, cibo, pergamene, curiosità"
L["rule:consumablesBlurb"] =
"Scegli cosa tenere per ogni tipo di consumabile. Tutto ciò che nessuna casella tiene viene venduto."
L["rule:bags"] = "Borse"
L["rule:bagsSub"] = "Contenitori di ogni tipo"
L["rule:bagsBlurb"] =
"Non vengono mai vendute. Quali borse porti è una tua scelta, quindi Dispatch non le valuta."
L["rule:gear"] = "Armi e armatura"
L["rule:gearSub"] = "Valutate rispetto a ciò che indossi"
L["rule:gearBlurb"] =
"Un unico gruppo di impostazioni valuta entrambe. Ogni arma e ogni pezzo di armatura viene sottoposto alle domande sottostanti in ordine, e la prima che risponde Tieni decide."
L["rule:gems"] = "Gemme"
L["rule:gemsSub"] = "Incastonature e reliquie di artefatto"
L["rule:gemsBlurb"] =
"Un unico gruppo di scelte per ogni gemma. Le reliquie di artefatto hanno un'opzione propria qui sotto, perché nient'altro nel tipo di una gemma cambia se vale la pena tenerla."
L["rule:tradeGoods"] = "Materiali da mestiere"
L["rule:tradeGoodsSub"] = "Materiali d'artigianato per mestiere"
L["rule:tradeGoodsBlurb"] =
"Scegli i componenti di chi risparmiare. Tutto ciò che non risparmi viene venduto -- anche se un componente che i tuoi mestieri usano davvero è già tenuto dalla regola Componenti da mestiere qui sopra."
L["rule:enhancements"] = "Miglioramenti dell'oggetto"
L["rule:enhancementsSub"] = "Incantesimi, oli, pietre"
L["rule:enhancementsBlurb"] =
"Una nuova espansione limita l'equipaggiamento a cui questi possono essere applicati, quindi quelli più vecchi smettono di valere qualcosa. Seleziona ogni espansione il cui equipaggiamento indossi davvero, compresa questa -- non viene più tenuto nulla in automatico."
L["rule:recipes"] = "Ricette"
L["rule:recipesSub"] = "Modelli, progetti, formule"
L["rule:recipesBlurb"] =
"Ogni ricetta porta con sé il mestiere a cui appartiene, quindi viene valutata non appena compare dal mercante. Una ricetta che non appartiene a nessun mestiere in particolare -- un modello o un manuale generico -- viene lasciata stare, perché non c'è nulla con cui valutarla."
L["rule:misc"] = "Varie"
L["rule:miscSub"] = "Mascotte, cavalcature, giocattoli, oggetti festivi"
L["rule:miscBlurb"] =
"I componenti di incantesimo sono lasciati stare. Tra le cianfrusaglie non categorizzate, viene giudicato solo un giocattolo: viene venduto non appena è già nella tua collezione e la copia nelle tue borse è legata. Gli oggetti grigi sono gestiti dalla regola Qualità scadente qui sopra, non qui."
L["rule:profession"] = "Equipaggiamento da mestiere"
L["rule:professionSub"] = "Strumenti e accessori"
L["rule:professionBlurb"] =
"Non viene mai venduto. Quelli scambiabili valgono denaro, e quelli legati li hai creati per te stesso o li stai usando proprio ora, quindi non c'è alcun caso in cui venderli sia corretto."
L["rule:housing"] = "Alloggio"
L["rule:housingSub"] = "Decorazioni e tinture"
L["rule:housingBlurb"] =
"Una volta collezionata una decorazione, l'oggetto in sé non ha più alcun uso, quindi può andare dal venditore. Una tintura non è affatto quel genere di cosa: è un consumabile monouso, esaurito quando viene applicato, quindi non c'è nulla da collezionare né nulla che sia stato imparato. Inoltre non è mai legata, quindi l'unica domanda che vale la pena porsi è se può ancora raggiungere qualcuno che la desidera."
L["rule:none"] = "Tutto il resto"
L["rule:noneSub"] = "Oggetti missione, chiavi, glifi, gettoni"
L["rule:noneBlurb"] =
"Tipi di oggetto che Dispatch non valuta affatto: oggetti missione, chiavi, mascotte in gabbia, glifi, gettoni WoW, componenti di incantesimo, frecce e le altre categorie dismesse. Restano nelle tue borse indipendentemente da come sono impostate le regole sopra."

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "Questo rapporto include il link dell'oggetto e le sue altre statistiche, il verdetto a cui è arrivato BitForge e la regola che lo ha deciso, se tu stesso hai messo questo oggetto nella tua lista nera o bianca, qualunque cosa tu abbia equipaggiato nello slot che occuperebbe, e le impostazioni che hanno giudicato la coppia. Un link oggetto indica il livello e la specializzazione del tuo personaggio -- questo fa parte del formato del link stesso, e rimuoverlo farebbe perdere il dettaglio che rende il rapporto riproducibile. Niente qui nomina il tuo personaggio, il tuo regno, la tua gilda o la tua fazione, e niente descrive un altro slot."

-- The disenchant scan's own footnote: it discloses several bag items and
-- their tooltips, not the single item/link pair report:blurbSell describes.
L["report:blurbDisenchant"] = "Questo rapporto include lo stato attuale di puntamento incantesimo del client e se questo personaggio può disincantare. Include anche fino a otto armi o pezzi di armatura dalle tue borse che potrebbero valere la pena disincantare, ciascuno con la propria borsa, slot, ID oggetto, nome, qualità, tipo di oggetto e la previsione di BitForge su se possa essere disincantato, oltre al testo completo del suo tooltip. Per qualsiasi altro oggetto nelle tue borse di cui non è stato possibile leggere la qualità, include anche la sua borsa, slot, ID oggetto e nome. Niente qui nomina il tuo personaggio, il tuo regno, la tua gilda o la tua fazione."
L["report:blurbDispatch"] = "Questo rapporto include il link e la qualità dell'oggetto, da quale borsa e slot ha risposto quando lo porti con te, il verdetto a cui è arrivato ogni percorso di regole per esso -- il suo dettaglio aggiuntivo, e se proviene da una deroga salvata -- e la rivendicazione, la forza e il motivo propri di ciascun percorso, incluso ogni percorso che non fosse riuscito a rispondere affatto. Quando l'oggetto è di qualità scadente, questo rapporto indica anche se la funzione «Vendi spazzatura» di Blizzard lo venderebbe comunque, in base alle tue impostazioni di vendita e della regola sulla spazzatura. Quando l'oggetto è un componente d'artigianato, questo rapporto include anche i mestieri per cui lo elenca il catalogo distribuito con il componente aggiuntivo, i mestieri registrati per questo account -- o solo quelli di questo personaggio, quando la copia è legata all'anima -- l'espansione a cui l'oggetto appartiene e se hai selezionato quell'espansione, se una ricetta che hai contrassegnato ne ha bisogno, e con quale di queste cose ha risposto la regola sui componenti stessa -- il suo verdetto, che non è sempre ciò che ha deciso l'oggetto. Elenca sempre le ricette che hai contrassegnato, per ID e, dove il gioco riesce ancora a darne il nome, per nome: dice quindi cosa produci e non solo cosa stai portando con te. Quando la diagnostica è attiva, questo rapporto include anche la mappa su cui ti trovavi e la mappa che la contiene e, per un oggetto limitato a un luogo, i luoghi che quella limitazione indica e quale di essi corrispondeva a dove ti trovavi. Un link oggetto indica il livello e la specializzazione del tuo personaggio -- questo fa parte del formato del link stesso, e rimuoverlo farebbe perdere il dettaglio che rende il rapporto riproducibile. Niente qui nomina il tuo personaggio, il tuo regno, la tua gilda o la tua fazione."

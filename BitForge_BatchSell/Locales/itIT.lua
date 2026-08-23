if GetLocale() ~= "itIT" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Vendita in blocco"
L["panel:sellManifest"] = "Manifesto vendita"
L["panel:blacklist"] = "Lista nera"
L["panel:whitelist"] = "Lista bianca"

-- Buttons
L["btn:sellAll"] = "Vendi tutto"
L["btn:refresh"] = "Aggiorna"

-- Context menu
L["menu:addToBlacklist"] = "Aggiungi alla lista nera"
L["menu:addToWhitelist"] = "Aggiungi alla lista bianca"
L["menu:addToBlacklistChar"] = "Aggiungi alla lista nera (Personaggio)"
L["menu:addToWhitelistChar"] = "Aggiungi alla lista bianca (Personaggio)"
L["menu:clearCharOverride"] = "Rimuovi la priorità del personaggio"
L["menu:resetListEntry"] = "Rimuovi dalla lista"
L["menu:temporaryExclude"] = "Escludi temporaneamente"

-- Status
L["status:noItemsToSell"] = "Nessun oggetto da vendere"
L["status:itemsTotal"] = "%d oggetti  |  Totale: %s"

-- Merchant row
L["tooltip:charOverride"] =
"L'impostazione di questo personaggio ha la precedenza sulla lista del gruppo di guerra: questo oggetto verrà venduto."

-- Section titles
L["section:general"] = "Generale"
L["section:equipment"] = "Equipaggiamento"
L["section:materials"] = "Materiali da crafting"
L["section:other"] = "Consumabili e altro"
L["section:lists"] = "Liste"

-- Settings
L["settings:sellJunk"] = "Vendi spazzatura"
L["settings:sellJunkTooltip"] = "Vendi automaticamente tutti gli oggetti di scarsa qualità (grigi) quando visiti un venditore"
L["settings:limitBatch"] = "Limita blocco a 12"
L["settings:limitBatchTooltip"] = "Vendi al massimo 12 oggetti per clic per evitare il throttling del server"
L["settings:sellEquipment"] = "Vendi equipaggiamento"
L["settings:sellEquipmentTooltip"] =
"Consenti la vendita di armature e armi. Se disattivato, l'equipaggiamento non viene mai venduto"
L["settings:ilvlMargin"] = "Margine livello oggetto"
L["settings:ilvlMarginTooltip"] =
"Quanto vale un grado di qualità in livelli oggetto. Con 10, un pezzo un grado sotto quello che indossi deve superarlo di 10 per essere tenuto, e uno un grado sopra sopravvive 10 sotto. Alla tua stessa qualità un pezzo deve semplicemente battere lo slot. Con 0 la qualità smette di contare e decide solo il livello dell'oggetto"
L["settings:emphasizeQuality"] = "  Enfatizza la qualità"
L["settings:emphasizeQualityTooltip"] =
"Conta un grado di qualità per il doppio del margine e consente a un pezzo di pari qualità di restare quel margine sotto lo slot. La qualità superiore a quella che indossi diventa più economica da tenere, e quella inferiore più cara da giustificare"
L["settings:keepBindOnAccount"] = "Mantieni legati all'account"
L["settings:keepBindOnAccountTooltip"] = "Mantieni gli oggetti legati all'account (eredità)"
L["settings:keepBindOnAccountPastExpac"] = "  Includi espansioni passate"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Mantieni anche gli oggetti legati all'account delle espansioni passate"
L["settings:keepDisenchantables"] = "Mantieni disincantabili"
L["settings:keepDisenchantablesTooltip"] = "Incantatori: mantieni oggetti BOP/BOE/BOA. Altri: mantieni oggetti BOE/BOA per AH o alter"
L["settings:keepDisenchantablesPastExpac"] = "  Includi espansioni passate"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Mantieni anche gli oggetti disincantabili delle espansioni passate"
L["settings:keepUsedReagents"] = "Conserva i componenti dei tuoi mestieri"
L["settings:keepUsedReagentsTooltip"] = "Conserva i componenti d'artigianato che un mestiere di questo account può usare"
L["settings:materialsMode"] = "Materiali da crafting"
L["settings:materialsModeTooltip"] =
"Cosa fare con reagenti, materiali da commercio, gemme, incantamenti e ricette"
L["settings:materialsExpansion"] = "  Mantieni dall'espansione"
L["settings:materialsExpansionTooltip"] =
"Mantieni i materiali da questa espansione in poi e vendi tutto ciò che è più vecchio. Usato solo quando Materiali da crafting è impostato per mantenere da un'espansione scelta"
L["settings:otherMode"] = "Consumabili e altro"
L["settings:otherModeTooltip"] =
"Cosa fare con consumabili, contenitori, mascotte da combattimento, equipaggiamento di professione e decorazioni dell'alloggio"

-- Sell modes
L["mode:keepAll"] = "Mantieni tutto"
L["mode:keepCurrent"] = "Mantieni espansione attuale"
L["mode:keepFrom"] = "Mantieni dall'espansione"
L["mode:sellAll"] = "Vendi tutto"

-- List tabs
L["btn:removeEntry"] = "Rimuovi"
L["list:warband"] = "Gruppo di guerra"
L["list:character"] = "Personaggio"
L["status:listEmpty"] = "Questa lista è vuota"
L["status:listCount"] = "%d voci"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Vendita in blocco: verrà venduto"
L["verdict:keep"] = "Vendita in blocco: verrà mantenuto"
L["reason:TEMP_EXCLUDED"] = "Escluso per questa visita al venditore"
L["reason:BLACKLISTED"] = "Nella tua lista nera"
L["reason:LOCKED"] = "L'oggetto è bloccato"
L["reason:EQUIPMENT_SET"] = "Fa parte di un set di equipaggiamento"
L["reason:NO_SELL_PRICE"] = "Nessun venditore lo acquisterà"
L["reason:REFUNDABLE"] = "Ancora entro il periodo di rimborso"
L["reason:WHITELISTED"] = "Nella tua lista bianca"
L["reason:TEMP_INCLUDED"] = "Aggiunto per questa visita al venditore"
L["reason:JUNK"] = "«Vendi spazzatura» è disattivato, la spazzatura non viene toccata"
L["reason:CATEGORY"] = "Questo tipo di oggetto è impostato per essere mantenuto"
L["reason:CURRENT_EXPANSION"] = "Proviene da un'espansione che stai mantenendo"
L["reason:BIND_ON_ACCOUNT"] = "L'equipaggiamento legato all'account viene mantenuto"
L["reason:DISENCHANTABLE"] = "Vale la pena mantenerlo per disincantarlo o rivenderlo"
L["reason:REAGENT_WANTED"] = "Un mestiere di questo account usa questo"
L["reason:NOT_EQUIPPABLE"] = "Non equipaggiabile o non consigliato per la tua classe"
L["reason:EQUIPPABLE"] = "Abbastanza buono rispetto al tuo equipaggiamento indossato"
L["reason:OUTCLASSED"] = "Superato dal tuo equipaggiamento indossato"
L["reason:SELL_MODE"] = "Questo tipo di oggetto è impostato per essere venduto"
L["reason:DEFAULT"] = "Nessuna regola lo ha reclamato, quindi viene mantenuto"

-- Expansion labels
L["expansion:classic"] = "Classic"
L["expansion:burningCrusade"] = "L'Alba Bruciante"
L["expansion:wrathOfTheLichKing"] = "L'Ira del Re dei Lich"
L["expansion:cataclysm"] = "Catastrofe"
L["expansion:mistsOfPandaria"] = "Nebbie di Pandaria"
L["expansion:warlordsOfDraenor"] = "Signori di guerra di Draenor"
L["expansion:legion"] = "Legione"
L["expansion:battleForAzeroth"] = "La battaglia per Azeroth"
L["expansion:shadowlands"] = "Shadowlands"
L["expansion:dragonflight"] = "Dragonflight"
L["expansion:theWarWithin"] = "La guerra interiore"
L["expansion:midnight"] = "Mezzanotte"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Reimposta lista nera del gruppo di guerra"
L["listReset:warbandWhitelist"] = "Reimposta lista bianca del gruppo di guerra"
L["listReset:charBlacklist"] = "Reimposta lista nera del personaggio"
L["listReset:charWhitelist"] = "Reimposta lista bianca del personaggio"
L["listReset:confirm"] = "Sei sicuro di voler svuotare questa lista? L'operazione non può essere annullata."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Impossibile vendere %s in questo momento: %s"
L["msg:dropUnexcluded"] = "%s non è più escluso e verrà venduto in questa visita"

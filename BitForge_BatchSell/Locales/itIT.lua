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

-- Settings
L["settings:sellJunk"] = "Vendi spazzatura"
L["settings:sellJunkTooltip"] = "Vendi automaticamente tutti gli oggetti di scarsa qualità (grigi) quando visiti un venditore"
L["settings:keepEquippable"] = "Mantieni indossabili"
L["settings:keepEquippableTooltip"] = "Mantieni tutti gli oggetti indossabili dalla tua classe"
L["settings:keepBindOnAccount"] = "Mantieni legati all'account"
L["settings:keepBindOnAccountTooltip"] = "Mantieni gli oggetti legati all'account (eredità)"
L["settings:keepBindOnAccountPastExpac"] = "  Includi espansioni passate"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Mantieni anche gli oggetti legati all'account delle espansioni passate"
L["settings:keepDisenchantables"] = "Mantieni disincantabili"
L["settings:keepDisenchantablesTooltip"] = "Incantatori: mantieni oggetti BOP/BOE/BOA. Altri: mantieni oggetti BOE/BOA per AH o alter"
L["settings:keepDisenchantablesPastExpac"] = "  Includi espansioni passate"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Mantieni anche gli oggetti disincantabili delle espansioni passate"
L["settings:limitBatch"] = "Limita blocco a 12"
L["settings:limitBatchTooltip"] = "Vendi al massimo 12 oggetti per clic per evitare il throttling del server"
L["settings:qualityThreshold"] = "Soglia qualità"
L["settings:qualityThresholdTooltip"] = "Vendi oggetti pari o inferiori a questa qualità"
L["settings:ilvlThreshold"] = "Margine livello oggetto"
L["settings:ilvlThresholdTooltip"] =
"Mantieni gli oggetti indossabili entro questo numero di livelli oggetto dal tuo equipaggiamento (negativo = mantieni oggetti migliori)"
L["settings:sellPastExpansion"] = "Vendi oggetti espansioni passate"
L["settings:sellPastExpansionTooltip"] = "Vendi oggetti di espansioni più vecchie della soglia selezionata"
L["settings:expansionThreshold"] = "Soglia espansione"
L["settings:expansionThresholdTooltip"] = "Vendi oggetti di espansioni più vecchie di quella selezionata"

-- Quality labels
L["quality:poor"] = "Scarso"
L["quality:common"] = "Comune"
L["quality:uncommon"] = "Non comune"
L["quality:rare"] = "Raro"
L["quality:epic"] = "Epico"

-- Expansion labels
L["expansion:all"] = "Tutte le espansioni"
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

-- List reset buttons
L["listReset:warbandBlacklist"] = "Reimposta lista nera del gruppo di guerra"
L["listReset:warbandWhitelist"] = "Reimposta lista bianca del gruppo di guerra"
L["listReset:charBlacklist"] = "Reimposta lista nera del personaggio"
L["listReset:charWhitelist"] = "Reimposta lista bianca del personaggio"
L["listReset:confirm"] = "Sei sicuro di voler svuotare questa lista? L'operazione non può essere annullata."

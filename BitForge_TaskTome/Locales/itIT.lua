if GetLocale() ~= "itIT" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "Tomo dei compiti"

-- Config Frame
L["settings:configTitle"] = "Tomo dei compiti — Configurazione"
L["btn:addRootTask"] = "Aggiungi compito radice"
L["btn:addChildTask"] = "Aggiungi compito figlio"
L["btn:deleteTask"] = "Elimina compito"
L["btn:save"] = "Salva"
L["settings:taskName"] = "Nome"
L["settings:resetCycle"] = "Reimpostazione"
L["settings:warbandAssigned"] = "Assegnato a tutti i personaggi"
L["settings:completionScope"] = "Ambito di completamento"
L["settings:optState"] = "La mia assegnazione"

-- Dropdowns
L["menu:resetNone"] = "Nessuno"
L["menu:resetDaily"] = "Giornaliero"
L["menu:resetWeekly"] = "Settimanale"
L["menu:scopeChar"] = "Personaggio"
L["menu:scopeWarband"] = "Condiviso — un completamento per l'intero account"
L["menu:optFollow"] = "Segui impostazione predefinita"
L["menu:optIn"] = "Mostra sempre"
L["menu:optOut"] = "Nascondi sempre"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "Eliminare '%s' e tutti i %d compiti figlio?"
L["msg:deleteSingle"] = "Eliminare '%s'?"
L["btn:confirmDelete"] = "Elimina"
L["btn:cancel"] = "Annulla"
L["msg:nameRequired"] = "Il nome del compito non può essere vuoto."

-- Settings panel
L["settings:taskTomePanel"] = "Tomo dei compiti"
L["settings:config"] = "Configurazione"
L["settings:openConfig"] = "Apri"

-- Widget modes
L["group:accountWide"] = "Per tutto l'account"
L["tooltip:scopeMe"] = "Mostra questo personaggio. Clicca per mostrare tutti i personaggi."
L["tooltip:scopeAll"] = "Mostra tutti i personaggi. Clicca per mostrare solo questo personaggio."
L["tooltip:orientByChar"] = "Raggruppato per personaggio. Clicca per raggruppare per compito."
L["tooltip:orientByTask"] = "Raggruppato per compito. Clicca per raggruppare per personaggio."
L["tooltip:openConfig"] = "Apre la finestra di configurazione del Tomo dei compiti."
L["tooltip:widgetLocked"] = "La finestra è bloccata. Clicca per sbloccarla e poterla spostare e ridimensionare."
L["tooltip:widgetUnlocked"] = "La finestra è sbloccata. Clicca per bloccarne posizione e dimensioni."

-- Config
L["settings:editingFor"] = "Modifica per"
L["settings:optStateFor"] = "Assegnazione di %s"

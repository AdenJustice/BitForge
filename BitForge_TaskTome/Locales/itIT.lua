if GetLocale() ~= "itIT" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "Tomo dei compiti"
L["btn:lockWidget"] = "Blocca"
L["btn:unlockWidget"] = "Sblocca"

-- Config Frame
L["settings:configTitle"] = "Tomo dei compiti — Configurazione"
L["btn:addRootTask"] = "Aggiungi compito radice"
L["btn:addChildTask"] = "Aggiungi compito figlio"
L["btn:deleteTask"] = "Elimina compito"
L["btn:save"] = "Salva"
L["settings:taskName"] = "Nome"
L["settings:resetCycle"] = "Reimpostazione"
L["settings:warbandAssigned"] = "Compito del gruppo di guerra"
L["settings:completionScope"] = "Ambito di completamento"
L["settings:optState"] = "Il mio stato di partecipazione"

-- Dropdowns
L["menu:resetNone"] = "Nessuno"
L["menu:resetDaily"] = "Giornaliero"
L["menu:resetWeekly"] = "Settimanale"
L["menu:scopeChar"] = "Personaggio"
L["menu:scopeWarband"] = "Gruppo di guerra"
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

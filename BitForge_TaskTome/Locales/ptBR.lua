if GetLocale() ~= "ptBR" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "Livro de Tarefas"
L["btn:lockWidget"] = "Travar"
L["btn:unlockWidget"] = "Destravar"

-- Config Frame
L["settings:configTitle"] = "Livro de Tarefas — Configuração"
L["btn:addRootTask"] = "Adicionar Tarefa Principal"
L["btn:addChildTask"] = "Adicionar Subtarefa"
L["btn:deleteTask"] = "Excluir Tarefa"
L["btn:save"] = "Salvar"
L["settings:taskName"] = "Nome"
L["settings:resetCycle"] = "Reiniciar"
L["settings:warbandAssigned"] = "Tarefa da Tropa de Guerra"
L["settings:completionScope"] = "Escopo de Conclusão"
L["settings:optState"] = "Meu Estado de Opt"

-- Dropdowns
L["menu:resetNone"] = "Nenhum"
L["menu:resetDaily"] = "Diário"
L["menu:resetWeekly"] = "Semanal"
L["menu:scopeChar"] = "Personagem"
L["menu:scopeWarband"] = "Tropa de Guerra"
L["menu:optFollow"] = "Seguir Padrão"
L["menu:optIn"] = "Sempre Mostrar"
L["menu:optOut"] = "Sempre Ocultar"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "Excluir '%s' e todas as %d subtarefa(s)?"
L["msg:deleteSingle"] = "Excluir '%s'?"
L["btn:confirmDelete"] = "Excluir"
L["btn:cancel"] = "Cancelar"
L["msg:nameRequired"] = "O nome da tarefa não pode estar vazio."

-- Settings panel
L["settings:taskTomePanel"] = "Livro de Tarefas"
L["settings:config"] = "Configuração"
L["settings:openConfig"] = "Abrir"

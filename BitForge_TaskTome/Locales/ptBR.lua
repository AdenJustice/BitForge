if GetLocale() ~= "ptBR" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

L["status:widgetTitle"] = "Livro de Tarefas"

L["settings:configTitle"] = "Livro de Tarefas — Configuração"
L["btn:addRootTask"] = "Adicionar Tarefa Principal"
L["btn:addChildTask"] = "Adicionar Subtarefa"
L["btn:deleteTask"] = "Excluir Tarefa"
L["btn:save"] = "Salvar"
L["settings:taskName"] = "Nome"
L["settings:resetCycle"] = "Reiniciar"
L["settings:warbandAssigned"] = "Atribuída a Todos os Personagens"
L["settings:completionScope"] = "Escopo de Conclusão"
L["settings:optState"] = "Minha Atribuição"

L["menu:resetNone"] = "Nenhum"
L["menu:resetDaily"] = "Diário"
L["menu:resetWeekly"] = "Semanal"
L["menu:scopeChar"] = "Personagem"
L["menu:scopeWarband"] = "Compartilhada — uma conclusão para toda a conta"
L["menu:optFollow"] = "Seguir Padrão"
L["menu:optIn"] = "Sempre Mostrar"
L["menu:optOut"] = "Sempre Ocultar"

L["msg:deleteConfirm"] = "Excluir '%s' e todas as %d subtarefa(s)?"
L["msg:deleteSingle"] = "Excluir '%s'?"
L["btn:confirmDelete"] = "Excluir"
L["btn:cancel"] = "Cancelar"
L["msg:nameRequired"] = "O nome da tarefa não pode estar vazio."

L["settings:taskTomePanel"] = "Livro de Tarefas"
L["settings:config"] = "Configuração"
L["settings:openConfig"] = "Abrir"

L["group:accountWide"] = "Toda a Conta"
L["tooltip:scopeMe"] = "Mostrando este personagem. Clique para mostrar todos os personagens."
L["tooltip:scopeAll"] = "Mostrando todos os personagens. Clique para mostrar apenas este personagem."
L["tooltip:orientByChar"] = "Agrupado por personagem. Clique para agrupar por tarefa."
L["tooltip:orientByTask"] = "Agrupado por tarefa. Clique para agrupar por personagem."
L["tooltip:openConfig"] = "Abre a janela de configuração do Livro de Tarefas."
L["tooltip:widgetLocked"] = "A janela está travada. Clique para destravá-la e poder movê-la e redimensioná-la."
L["tooltip:widgetUnlocked"] = "A janela está destravada. Clique para travar sua posição e tamanho."

L["settings:editingFor"] = "Editando Para"
L["settings:optStateFor"] = "Atribuição de %s"

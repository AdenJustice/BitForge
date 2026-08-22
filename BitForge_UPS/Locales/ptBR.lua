if GetLocale() ~= "ptBR" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Serviço de Encomendas de Kaz'Mina"
L["settings:enabled"] = "Ativar UPS"
L["settings:enabledTooltip"] = "Depositar reagentes de profissão no Banco do Bando de Guerra ao visitar um banco"
L["settings:previewMoves"] = "Pré-visualizar antes de depositar"
L["settings:previewMovesTooltip"] = "Mostrar uma janela de confirmação listando cada movimentação antes de depositar qualquer coisa"
L["settings:onlyWantedReagents"] = "Depositar apenas reagentes utilizáveis"
L["settings:onlyWantedReagentsTooltip"] = "Depositar apenas reagentes com que uma profissão desta conta possa trabalhar. Desligado deposita todos, para a casa de leilões"

L["btn:deposit"] = "Depositar"
L["btn:depositing"] = "Depositando… %d"

L["preview:title"] = "Confirmar depósito"
L["preview:summary"] = "%d item(ns) em %d movimentação(ões)"
L["preview:toWarband"] = "→ Banco do Bando de Guerra"
L["preview:dontAskAgain"] = "Não perguntar novamente"
L["btn:confirm"] = "Confirmar"
L["btn:cancel"] = "Cancelar"

L["msg:nothingToDo"] = "UPS: Nada para mover."
L["msg:done"] = "UPS: Concluído. %d item(ns) movido(s)."
L["msg:noVacancy"] = "UPS: O Banco do Bando de Guerra está cheio."
L["msg:blockedCombat"] = "UPS: Interrompido — você está em combate."
L["msg:blockedBankClosed"] = "UPS: Interrompido — o banco foi fechado."
L["msg:blockedCursor"] = "UPS: Interrompido — você está segurando algo no cursor."
L["msg:blockedLocked"] = "UPS: Interrompido — um item está bloqueado."
L["msg:moveFailed"] = "UPS: Interrompido — uma movimentação não foi concluída."
L["msg:openProfession"] = "UPS: Abra uma vez a janela de %s para que o UPS registre quais receitas você conhece."

-- Curation window
L["curation:title"] = "UPS — Curadoria de itens"
L["curation:open"] = "Organizar itens"
L["curation:search"] = "Buscar"
L["curation:filterDestination"] = "Qualquer destino"
L["curation:filterClass"] = "Qualquer tipo de item"
L["curation:source"] = "Origem: %s"
L["curation:sourceBuiltIn"] = "Este personagem"
L["curation:count"] = "%d item(ns)"
L["curation:unscanned"] = "Nunca verificados quanto a receitas: %s. Até lá, toda receita das profissões deles parece necessária e será depositada."
L["curation:heldBy"] = "Em posse de"
L["curation:overrideTooltip"] = "Você escolheu este destino. Restaure o padrão para voltar a seguir as regras."

-- Destinations
L["dest:warband"] = "Banco do Bando de Guerra"
L["dest:private"] = "Seu banco"
L["dest:privateOwned"] = "Seu banco (%s)"
L["dest:ignore"] = "Deixar como está"

-- Private destination
L["preview:toPrivate"] = "→ Seu banco"
L["preview:reclaim"] = "Banco do Bando de Guerra → Seu banco"
L["msg:noVacancyPrivate"] = "UPS: Seu banco está cheio."
L["curation:privateTooltip"] = "Guardado no banco do próprio personagem em vez do armazenamento compartilhado. Sem um dono escolhido, o primeiro personagem a visitar um banco fica com o item."

-- Target quantity
L["curation:targetSuffix"] = "manter %d"
L["target:title"] = "Quantidade alvo"
L["target:prompt"] = "Quantos %s cada dono deve manter?"

-- Row menu
L["menu:resetToDefault"] = "Restaurar padrão"
L["menu:owners"] = "Donos"
L["menu:target"] = "Quantidade alvo"
L["menu:targetNone"] = "Sem limite"
L["menu:targetOther"] = "Outra…"

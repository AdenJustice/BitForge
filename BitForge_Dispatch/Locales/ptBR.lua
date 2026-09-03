if GetLocale() ~= "ptBR" then return end
---@class BitForge.Dispatch
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "Dispatch"
L["settings:openEnabled"] = "Ativar o botão de itens abríveis"
L["settings:openEnabledTooltip"] = "Mostra um botão para o próximo item abrível ou usável nas suas bolsas"
L["settings:sellEnabled"] = "Ativar a venda a vendedores"
L["settings:sellEnabledTooltip"] = "Vende os itens que uma regra seleciona ao abrir um vendedor. Nada é vendido até você definir uma regra"
L["settings:bankEnabled"] = "Ativar o depósito no Banco do Bando de Guerra"
L["settings:bankEnabledTooltip"] = "Deposita reagentes, receitas que seus outros personagens precisam e os itens que você organizar ao visitar um banco"

-- Leftover-install guard
L["msg:replacedInstalled"] = "Dispatch: Ainda instalado — %s."
L["msg:replacedInstalledFix"] = "Exclua a instalação antiga e entre novamente para deixar o Dispatch assumir."

-- Openables button
L["settings:locked"] = "Travar botão"
L["settings:lockedTooltip"] = "Impede que o botão seja arrastado"
L["settings:buttonSize"] = "Tamanho do botão"
L["settings:buttonSizeTooltip"] = "Largura e altura do botão, em pixels"
L["settings:showCount"] = "Mostrar quantidade"
L["settings:showCountTooltip"] = "Mostra quantas unidades do item você carrega"
L["settings:showCooldown"] = "Mostrar recarga"
L["settings:showCooldownTooltip"] = "Mostra o tempo de recarga no botão"
L["settings:resetPosition"] = "Redefinir posição"
L["settings:manageBlacklist"] = "Gerenciar lista de bloqueio"

L["tooltip:use"] = "Clique esquerdo para abrir ou usar."
L["tooltip:skip"] = "Clique direito para pular nesta sessão."
L["tooltip:blacklist"] = "Ctrl + clique direito para bloquear permanentemente."
L["tooltip:report"] = "Shift + Alt + clique direito para reportar este veredito."
L["tooltip:drag"] = "Alt + arraste para mover."

L["report:blurbOpen"] = "Este relatório contém o item, sua bolsa e slot e se está travado, como o BitForge o classificou, o texto de seu tooltip e quais profissões este personagem conhece. Nada aqui menciona seu personagem, reino, guilda ou facção."

L["report:blurbField"] = "Este relatório contém cada candidato que a última varredura classificou para abrir em seguida, na ordem da classificação: o nome, o ID do item, a bolsa e o slot, a quantidade empilhada, a prioridade e o motivo de sua posição, se é um baú trancado que precisa de uma chave, se seu slot está travado no momento, e se está em recarga ou adiado. Nada aqui menciona seu personagem, reino, guilda ou facção, e o texto do tooltip de nenhum item é incluído."

L["report:blurbAllowList"] = "Este relatório contém cada item das duas listas de abertura que o addon mantém à mão -- a lista de liberação e a lista de recusa, uma seção para cada uma, ou uma só quando você nomeia uma lista. Cada linha traz o ID do item e o nome, o veredito a que as regras de abertura chegam quando essa lista é ignorada, o degrau que chegou a ele, a prioridade que esse degrau concedeu e, só na lista de liberação, a prioridade que ela fixa para o item, e o grupo em que a entrada cai. Quando uma linha diz em vez disso que os dados do item ou o tooltip dele nunca chegaram, isso descreve o cache deste cliente no momento em que você executou o comando, e não algo sobre o item; na primeira execução vale para quase toda a lista de liberação. Ele lê as listas distribuídas e o tooltip de cada item pelo ID, portanto não descreve nada das suas bolsas -- exceto que um item das listas que você bloqueou ou pulou nesta sessão é indicado como tal, assim como um veredito que dependeu do estado deste personagem, como se você pode usar o item ou abrir um baú trancado. Nada aqui nomeia seu personagem, seu reino, sua guilda ou sua facção."

L["blacklist:windowTitle"] = "Itens bloqueados"
L["blacklist:empty"] = "Nenhum item está bloqueado."
L["blacklist:remove"] = "Remover"
L["blacklist:clearAll"] = "Limpar tudo"
L["blacklist:unknownItem"] = "Item nº %d"

L["binding:header"] = "BitForge Dispatch"
L["binding:use"] = "Usar item abrível"

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

L["msg:nothingToDo"] = "Dispatch: Nada para mover."
L["msg:done"] = "Dispatch: Concluído. %d item(ns) movido(s)."
L["msg:noVacancy"] = "Dispatch: O Banco do Bando de Guerra está cheio."
L["msg:blockedCombat"] = "Dispatch: Interrompido — você está em combate."
L["msg:blockedBankClosed"] = "Dispatch: Interrompido — o banco foi fechado."
L["msg:blockedCursor"] = "Dispatch: Interrompido — você está segurando algo no cursor."
L["msg:blockedLocked"] = "Dispatch: Interrompido — um item está bloqueado."
L["msg:moveFailed"] = "Dispatch: Interrompido — uma movimentação não foi concluída."
L["msg:openProfession"] = "Dispatch: Abra uma vez a janela de %s para que o Dispatch registre quais receitas você conhece."

-- Curation window
L["curation:title"] = "Curadoria de itens"
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
L["msg:noVacancyPrivate"] = "Dispatch: Seu banco está cheio."
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

L["panel:batchSell"] = "Venda em lote"
L["panel:sellManifest"] = "Manifesto de venda"
L["panel:blacklist"] = "Lista negra"
L["panel:whitelist"] = "Lista branca"

L["ui:ruleWindowTitle"] = "Regras de venda em lote"
L["ui:ruleWindowNothingToConfigure"] = "Não há nada para configurar aqui."
L["ui:ruleWindowDisclaimer"] =
"Em combate e dentro de instâncias, o jogo às vezes não revela os detalhes de um item. O Dispatch mantém esses itens em vez de adivinhar, então alguns podem estar faltando na lista -- isso é esperado. Um veredito que pareça errado por qualquer outro motivo vale a pena reportar."
L["ui:selectedCount"] = "Seleção: %d"
L["ui:reagentsNoProfession"] =
"Nenhum personagem desta conta tem uma profissão ainda, então esta regra não mantém nada. Entre com um que tenha e estes controles voltam."

L["btn:sellAll"] = "Vender tudo"
L["btn:refresh"] = "Atualizar"
L["btn:rules"] = "Regras"

L["menu:temporaryExclude"] = "Excluir temporariamente"
L["menu:blacklisted"] = "Lista negra"
L["menu:whitelisted"] = "Lista branca"
L["menu:noStatus"] = "Nenhuma"
L["menu:reportVerdict"] = "Reportar este veredito"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "Marcar os reagentes desta receita"

L["status:noItemsToSell"] = "Nenhum item para vender"
L["status:itemsTotal"] = "%d itens  |  Total: %s"

L["ui:manifestHint"] = "Esperava algo que não está na lista? Passe o mouse sobre ele nas suas mochilas para ver o motivo."

-- Merchant row
L["tooltip:charOverride"] =
"A configuração deste personagem substitui a lista do Bando de Guerra — este item será vendido."

L["section:general"] = "Geral"
L["section:lists"] = "Listas"
L["section:everyItem"] = "Todos os itens"
L["section:byItemType"] = "Por tipo de item"

L["settings:openRuleWindow"] = "Ver regras"
L["settings:openRuleWindowTooltip"] =
"Explica o que cada regra procura e por que um item foi mantido ou vendido"
L["settings:sellJunk"] = "Vender lixo"
L["settings:sellJunkTooltip"] = "Vende automaticamente todos os itens de qualidade ruim (cinza) ao visitar um vendedor"
L["settings:limitBatch"] = "Limitar lote a 12"
L["settings:limitBatchTooltip"] = "Vende no máximo 12 itens por clique para evitar limitação do servidor"
L["settings:keepUsedReagents"] = "Manter reagentes das suas profissões"
L["settings:keepUsedReagentsTooltip"] =
"Manter reagentes de criação que uma profissão desta conta possa usar. Uma cópia vinculada à alma nunca chega a outro personagem, então só as profissões deste personagem a mantêm"
L["settings:reagentsExpansions"] = "Quais reagentes manter"
L["settings:reagentsExpansionsTooltip"] =
"De quais expansões a regra acima mantém reagentes. Vem definido só para esta expansão, então reagentes mais antigos vão para a venda -- menos os que uma receita marcada por você ainda precisa, que são mantidos seja lá o que estiver selecionado aqui"
L["settings:margin"] = "Margem de nível do item"
L["settings:marginTooltip"] =
"Quanto uma peça da sua própria qualidade pode ficar abaixo do espaço antes de ser vendida. Com 0 basta igualar o espaço"
L["settings:qualityMargin"] = "Margem de qualidade"
L["settings:qualityMarginTooltip"] =
"Quanto vale um grau de qualidade em níveis de item. Com 10, uma peça um grau abaixo da que você usa precisa de 10 níveis de item a mais para ser mantida, e uma um grau acima sobrevive 10 abaixo. Com 0 a qualidade deixa de contar e só o nível do item decide. Com Sempre, qualquer qualidade superior é mantida seja qual for o nível do item, e nenhum nível de item salva uma inferior"
L["settings:qualityMarginAlways"] = "Sempre"
L["settings:keepForDisenchant"] = "Manter equipamento pela expansão dos materiais"
L["settings:keepForDisenchantTooltip"] =
"Mantenha equipamentos que um encantador poderia desencantar, pela expansão dos materiais que produziriam em vez da idade do próprio equipamento -- equipamentos de uma expansão encerrada produzem os materiais dessa expansão. Seu próprio encantador sempre mantém o que só ele pode alcançar, seja qual for este ajuste, mas isso ainda decide se isso também vale para materiais mais antigos"
L["settings:spareBindOnAccount"] = "Poupar equipamento vinculado à conta"
L["settings:spareBindOnAccountTooltip"] =
"De quais expansões manter o equipamento vinculado à conta enquanto ainda pode ser passado a outro personagem"
L["settings:spareBindOnEquip"] = "Poupar equipamento vinculado ao equipar"
L["settings:spareBindOnEquipTooltip"] =
"De quais expansões manter o equipamento vinculado ao equipar enquanto ainda pode chegar a outro personagem ou à casa de leilões"
L["settings:keepUncollectedCosmetic"] = "Manter aparências não coletadas"
L["settings:keepUncollectedCosmeticTooltip"] =
"Mantém qualquer item cuja aparência você ainda não coletou. Vender uma peça comum a coleta mesmo assim, mas um item cosmético só concede o visual ao ser usado: vendê-lo perde a aparência de vez"
L["settings:sellRelics"] = "Vender relíquias de Classic"
L["settings:sellRelicsTooltip"] =
"Vende ídolos, tomos, totens e sigilos, o espaço de relíquia que Cataclysm removeu. Não são as relíquias de artefato de Legion, que são gemas e só compartilham o número da subclasse"
L["settings:gemsExpansions"] = "Quais gemas manter"
L["settings:gemsExpansionsTooltip"] =
"De quais expansões manter gemas. O que não estiver marcado segue para as duas perguntas abaixo"
L["settings:gemsRecipesNow"] = "Manter gemas atuais que alguma receita use"
L["settings:gemsRecipesNowTooltip"] =
"Mantém uma gema da expansão atual que alguma receita de profissão use como reagente, seja de quem for essa profissão. A pergunta vai ao catálogo de receitas, e uma gema que não consta nele conta como uma que nenhuma receita quer"
L["settings:gemsRecipesOld"] = "Manter gemas antigas que alguma receita use"
L["settings:gemsRecipesOldTooltip"] =
"A mesma pergunta para gemas de expansões passadas. O que as suas próprias profissões usam já é mantido em outro ponto, então esta coluna serve às receitas de todo mundo"
L["settings:keepArtifactRelics"] = "Manter relíquias de artefato"
L["settings:keepArtifactRelicsTooltip"] =
"Mantém as relíquias que eram encaixadas nas armas de artefato de Legion. Nada as usa desde Legion, então vale desligar a menos que você as colecione"
L["settings:enhancementsExpansions"] = "Quais aprimoramentos manter"
L["settings:enhancementsExpansionsTooltip"] =
"De quais expansões manter os aprimoramentos de item. Uma nova expansão limita o equipamento a que um aprimoramento serve, então marque a expansão cujo equipamento você realmente usa"
L["settings:keepLearnable"] = "Manter receitas que você pode aprender"
L["settings:keepLearnableTooltip"] =
"Mantém uma receita que este personagem ainda não aprendeu"
L["settings:keepTradeableRecipes"] = "Manter receitas negociáveis"
L["settings:keepTradeableRecipesTooltip"] =
"Mantém uma receita ainda não vinculada, para que ela chegue a um outro personagem ou ao leilão mesmo quando este personagem já a aprendeu"
L["settings:sellCollectedMounts"] = "Vender montarias coletadas"
L["settings:sellCollectedMountsTooltip"] =
"Vende uma montaria que você já possui, desde que a cópia esteja vinculada à alma. Uma cópia não vinculada é mantida diga o que disser esta opção, porque ainda pode chegar a alguém"
L["settings:sellCollectedToys"] = "Vender brinquedos coletados"
L["settings:sellCollectedToysTooltip"] =
"Vende um brinquedo que você já possui, desde que a cópia nas suas mochilas esteja vinculada. Uma cópia não vinculada é mantida diga o que disser sua coleção, porque ainda pode chegar a alguém"
L["settings:sellCollectedPets"] = "Vender mascotes coletados"
L["settings:sellCollectedPetsTooltip"] =
"Vende um mascote de batalha que você já tem. Um que você nunca coletou nunca é vendido por esta regra, em nenhuma das posições"
L["settings:sellHoliday"] = "Vender itens de festividade"
L["settings:sellHolidayTooltip"] =
"Vende as fichas, fantasias e bugigangas que os eventos do mundo deixam nas suas mochilas"
L["settings:sellMountEquipment"] = "Vender equipamento de montaria"
L["settings:sellMountEquipmentTooltip"] =
"Vende equipamento de montaria. Só uma peça vale para a conta inteira por vez, então as sobras nas suas mochilas não fazem nada"
L["settings:sellCollectedDecor"] = "Vender decoração coletada"
L["settings:sellCollectedDecorTooltip"] =
"Vende a decoração de moradia que o seu catálogo já tem. Uma peça que ele nunca viu é mantida, e também uma para a qual o catálogo não pôde ser lido"
L["settings:keepTradeableDyes"] = "Manter tinturas negociáveis"
L["settings:keepTradeableDyesTooltip"] =
"Uma tintura é gasta ao ser aplicada e nunca é aprendida, então não há coleção a consultar. O que se pergunta é se esta cópia ainda pode chegar a alguém: não vinculada é mantida, vinculada é vendida"
L["settings:spareProfessions"] = "Poupar para estas profissões"
L["settings:spareProfessionsTooltip"] =
"Mantém uma mercadoria se alguma profissão marcada aqui pudesse usá-la como reagente -- para um outro personagem que ainda não a tenha aprendido, ou para a casa de leilões. As profissões desta conta já são cobertas por Manter reagentes das suas profissões"

L["spare:none"] = "Nenhum"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "Todas as expansões"
L["expansion:current"] = "Expansão atual"

L["profession:FirstAid"] = "Primeiros Socorros"
L["profession:Blacksmithing"] = "Ferraria"
L["profession:Leatherworking"] = "Couraria"
L["profession:Alchemy"] = "Alquimia"
L["profession:Herbalism"] = "Herborismo"
L["profession:Cooking"] = "Culinária"
L["profession:Mining"] = "Mineração"
L["profession:Tailoring"] = "Alfaiataria"
L["profession:Engineering"] = "Engenharia"
L["profession:Enchanting"] = "Encantamento"
L["profession:Fishing"] = "Pesca"
L["profession:Skinning"] = "Esfolamento"
L["profession:Jewelcrafting"] = "Joalheria"
L["profession:Inscription"] = "Escrivania"
L["profession:Archaeology"] = "Arqueologia"

L["sub:0"] = "Genérico"
L["sub:1"] = "Poção"
L["sub:2"] = "Elixir"
L["sub:3"] = "Frascos e ampolas"
L["sub:5"] = "Comida e bebida"
L["sub:7"] = "Bandagem"
L["sub:8"] = "Outro"
L["sub:9"] = "Runa de Vantus"

L["option:expansions"] = "Quais expansões manter"
L["option:recipesNow"] = "Manter também os desta expansão se alguma receita os quiser"
L["option:recipesOld"] = "Manter também os mais antigos se alguma receita os quiser"

-- List tabs
L["btn:removeEntry"] = "Remover"
L["list:warband"] = "Bando de Guerra"
L["list:character"] = "Personagem"
L["status:listEmpty"] = "Esta lista está vazia"
L["status:listCount"] = "%d entradas"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Venda em lote: será vendido"
L["verdict:keep"] = "Venda em lote: será mantido"
L["claimed:OPEN"] = "O botão de abertura reivindicou este item"
L["claimed:DEPOSIT_WARBAND"] = "Irá para o Banco do Bando de Guerra em vez disso"
L["claimed:DEPOSIT_PRIVATE"] = "Irá para o banco próprio de um personagem em vez disso"
L["reason:TEMP_EXCLUDED"] = "Excluído para esta visita ao vendedor"
L["reason:BLACKLISTED"] = "Na sua lista negra"
L["reason:LOCKED"] = "O item está bloqueado"
L["reason:EQUIPMENT_SET"] = "Parte de um conjunto de equipamento"
L["reason:NO_SELL_PRICE"] = "Nenhum vendedor vai comprá-lo"
L["reason:REFUNDABLE"] = "Ainda dentro do prazo de reembolso"
L["reason:WHITELISTED"] = "Na sua lista branca"
L["reason:TEMP_INCLUDED"] = "Adicionado para esta visita ao vendedor"
L["reason:JUNK"] = "“Vender lixo” está desativado, o lixo não é tocado"
L["reason:JUNK_SOLD"] = "“Vender lixo” está ativado, o lixo é vendido"
L["reason:ABOVE_EPIC"] = "Melhor que épico, portanto nunca é vendido"
L["reason:BIND_ON_ACCOUNT"] = "Equipamentos vinculados à conta são mantidos"
L["reason:DISENCHANTABLE"] = "Vale a pena manter para desencantar ou revender"
L["reason:BAG_KEPT"] = "Mochilas nunca são vendidas"
L["reason:PROFESSION_GEAR_KEPT"] = "Equipamento de profissão nunca é vendido"
L["reason:ENHANCEMENT_EXPANSION"] = "Melhorias de item desta expansão são mantidas"
L["reason:CONSUMABLE_EXPANSION"] = "Os consumíveis desta expansão são mantidos"
L["reason:CONSUMABLE_REAGENT"] = "Alguma receita usa isto como reagente"
L["reason:GEM_EXPANSION"] = "As gemas desta expansão são mantidas"
L["reason:GEM_REAGENT"] = "Alguma receita usa isto como reagente"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "Relíquias de artefato são mantidas"
L["reason:TRADE_GOOD_SPARED"] = "Uma profissão que você escolheu poupar quer isto"
L["reason:NOT_WANTED"] = "Nenhuma opção mantém o item, então é vendido"
L["reason:REAGENT_WANTED"] = "Uma profissão que pode usá-lo quer isto como reagente"
L["reason:NOT_EQUIPPABLE"] = "Não equipável ou não recomendado para sua classe"
L["reason:EQUIPPABLE"] = "Bom o suficiente em comparação ao que você tem equipado"
L["reason:OUTCLASSED"] = "Superado pelo que você tem equipado"
L["reason:OUTDATED_EXPAC"] = "Supera o que você tem equipado, que é da expansão anterior"
L["reason:BIND_ON_EQUIP"] = "Equipamentos vinculados ao equipar são mantidos"
L["reason:ARMOR_RELIC"] = "Ninguém mais pode equipar uma relíquia, então é vendida"
L["reason:RECIPE_LEARNABLE"] = "Ainda não aprendida, então é mantida"
L["reason:HOLIDAY_ITEM"] = "Itens de festividade são vendidos"
L["reason:MOUNT_EQUIPMENT"] = "Equipamento de montaria é vendido"
L["reason:ALREADY_COLLECTED"] = "O item já foi colecionado, então é vendido"
L["reason:NOT_COLLECTED"] = "O item ainda não foi colecionado, então é mantido"
L["reason:STILL_TRADEABLE"] = "O item ainda é comerciável, então é mantido"
L["reason:ALREADY_LEARNED"] = "O item já foi aprendido, então é vendido"
L["reason:DEFAULT"] = "Nenhuma regra o reivindicou, então é mantido"

L["listReset:warbandBlacklist"] = "Redefinir lista negra do Bando de Guerra"
L["listReset:warbandWhitelist"] = "Redefinir lista branca do Bando de Guerra"
L["listReset:charBlacklist"] = "Redefinir lista negra do personagem"
L["listReset:charWhitelist"] = "Redefinir lista branca do personagem"
L["listReset:confirm"] = "Tem certeza que deseja limpar esta lista? Isso não pode ser desfeito."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Não é possível vender %s agora: %s"
L["msg:dropUnexcluded"] = "%s não está mais excluído e será vendido nesta visita"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "Bloqueado temporariamente"
L["rule:tempSub"] = "Somente para esta visita ao vendedor"
L["rule:tempBlurb"] =
"Itens que você retirou da lista de venda antes de clicar em Vender. Eles ficam nas suas mochilas durante esta visita e voltam a ser avaliados normalmente no próximo vendedor."
L["rule:black"] = "Nunca vender"
L["rule:blackSub"] = "Sua lista de nunca vender"
L["rule:blackBlurb"] =
"Tudo o que estiver na sua lista de nunca vender fica nas suas mochilas. Uma configuração deste personagem prevalece sobre a lista do Bando de Guerra, qualquer que seja o sentido da divergência entre as duas."
L["rule:gates"] = "Não pode ser vendido"
L["rule:gatesSub"] = "O vendedor não aceita estes"
L["rule:gatesBlurb"] =
"Itens bloqueados, qualquer coisa que faça parte de um conjunto de equipamento, itens sem preço de venda e compras ainda dentro do prazo de reembolso. Sua lista de sempre vender não se sobrepõe a estes, porque o vendedor recusaria a venda de qualquer forma."
L["rule:white"] = "Sempre vender"
L["rule:whiteSub"] = "Sua lista de sempre vender"
L["rule:whiteBlurb"] =
"Tudo o que estiver na sua lista de sempre vender é vendido, mesmo quando uma regra posterior o teria mantido. É assim que você vende aquele reagente de criação específico que não quer."
L["rule:tempIn"] = "Incluído nesta visita"
L["rule:tempInSub"] = "Somente para esta visita ao vendedor"
L["rule:tempInBlurb"] =
"Itens que você arrastou para a lista de venda neste vendedor. Eles são vendidos nesta visita e voltam a ser avaliados normalmente na próxima."
L["rule:junk"] = "Qualidade ruim"
L["rule:junkSub"] = "Desativado por padrão"
L["rule:junkBlurb"] =
"Itens cinzas, seja qual for o tipo. Desativado por padrão, porque geralmente outro addon já cuida disso. Se nenhum outro cuidar, ative esta opção e o Dispatch vai limpá-los para você."
L["rule:epic"] = "Lendário e acima"
L["rule:epicSub"] = "Lendário, Artefato, Herança"
L["rule:epicBlurb"] =
"Nunca é vendido. O vendedor mostra um preço para estes itens e depois recusa a venda, então o Dispatch não os coloca na lista."
L["rule:reagent"] = "Reagentes de criação"
L["rule:reagentSub"] = "Usa sua lista de profissões"
L["rule:reagentBlurb"] =
"Mantém qualquer reagente que uma profissão desta conta possa usar, seja qual for o tipo de item. Reagentes aparecem tanto em poções quanto em gemas e mercadorias, então isto é verificado antes do tipo do item. Enquanto você não disser o contrário, só os desta expansão são mantidos; um mais antigo também é mantido quando uma receita marcada por você ainda precisa dele, seja qual for a expansão selecionada. A lista é lida das próprias receitas do jogo, então já traz os reagentes opcionais que uma receita aceita e todos os níveis de qualidade -- você não precisa abrir nem varrer nada."
L["rule:cosmetic"] = "Aparências não colecionadas"
L["rule:cosmeticSub"] = "Itens cosméticos que você ainda não colecionou"
L["rule:cosmeticBlurb"] =
"Um item cosmético que você não colecionou é mantido. Vendê-lo não coleciona a aparência -- ela simplesmente desaparece --, então este é o único lugar na janela onde um erro não pode ser desfeito. Um item cosmético que você já colecionou não é vendido só por ser um; ele simplesmente não carrega mais nada a proteger, e passa a ser avaliado como a arma ou armadura que é."
L["rule:consumables"] = "Consumíveis"
L["rule:consumablesSub"] = "Poções, comida, pergaminhos, curiosidades"
L["rule:consumablesBlurb"] =
"Escolha o que manter para cada tipo de consumível. Tudo o que nenhuma opção mantiver é vendido."
L["rule:bags"] = "Mochilas"
L["rule:bagsSub"] = "Contêineres de todo tipo"
L["rule:bagsBlurb"] =
"Nunca são vendidas. Quais mochilas você carrega é decisão sua, então o Dispatch não as avalia."
L["rule:gear"] = "Armas e armadura"
L["rule:gearSub"] = "Avaliados contra o que você tem equipado"
L["rule:gearBlurb"] =
"Um único conjunto de configurações avalia os dois. Cada arma e cada peça de armadura passa pelas perguntas abaixo em ordem, e a primeira que responder Manter decide."
L["rule:gems"] = "Gemas"
L["rule:gemsSub"] = "Encaixes e relíquias de artefato"
L["rule:gemsBlurb"] =
"Um único conjunto de opções para cada gema. Relíquias de artefato têm sua própria opção abaixo, porque mais nada sobre o tipo de uma gema muda se vale a pena mantê-la."
L["rule:tradeGoods"] = "Mercadorias"
L["rule:tradeGoodsSub"] = "Materiais de criação por profissão"
L["rule:tradeGoodsBlurb"] =
"Escolha de quem manter os reagentes. Tudo o que você não poupar é vendido -- ainda que um reagente que suas próprias profissões realmente usem já seja mantido pela regra Reagentes de criação acima."
L["rule:enhancements"] = "Melhorias de item"
L["rule:enhancementsSub"] = "Encantamentos, óleos, pedras"
L["rule:enhancementsBlurb"] =
"Uma nova expansão limita o equipamento ao qual estes podem ser aplicados, então os mais antigos deixam de valer alguma coisa. Marque cada expansão cujo equipamento você realmente usa, incluindo esta -- nada é mais mantido automaticamente."
L["rule:recipes"] = "Receitas"
L["rule:recipesSub"] = "Padrões, plantas, fórmulas"
L["rule:recipesBlurb"] =
"Cada receita carrega consigo a profissão à qual pertence, então é avaliada assim que aparece diante do vendedor. Uma receita que não pertence a nenhuma profissão específica -- um padrão ou um manual genérico -- é deixada de lado, pois não há nada com que avaliá-la."
L["rule:misc"] = "Diversos"
L["rule:miscSub"] = "Mascotes, montarias, brinquedos, itens de festividade"
L["rule:miscBlurb"] =
"Reagentes de feitiço são deixados de lado. Entre os itens não categorizados, só um brinquedo é julgado: ele é vendido assim que já estiver na sua coleção e a cópia nas suas mochilas estiver vinculada. Itens cinzas são tratados pela regra Qualidade ruim acima, não aqui."
L["rule:profession"] = "Equipamento de profissão"
L["rule:professionSub"] = "Ferramentas e acessórios"
L["rule:professionBlurb"] =
"Nunca é vendido. Os negociáveis valem dinheiro, e os vinculados você criou para si mesmo ou está usando agora, então não há caso em que vendê-los seja certo."
L["rule:housing"] = "Residência"
L["rule:housingSub"] = "Decoração e tinturas"
L["rule:housingBlurb"] =
"Depois que uma decoração é colecionada, o item em si não tem mais utilidade, então pode ir para o vendedor. Uma tintura não é esse tipo de coisa: é um consumível de uso único, gasto quando aplicado, então não há nada para colecionar nem nada que pudesse ter sido aprendido. Ela também nunca é vinculada, então a única pergunta que vale a pena fazer é se ainda pode chegar a alguém que a queira."
L["rule:none"] = "Tudo o mais"
L["rule:noneSub"] = "Itens de missão, chaves, glifos, símbolos"
L["rule:noneBlurb"] =
"Tipos de item que o Dispatch não avalia de forma alguma: itens de missão, chaves, mascotes engaiolados, glifos, Símbolos da WoW, reagentes de feitiço, flechas e as outras categorias aposentadas. Eles ficam nas suas mochilas não importa como as regras acima estejam configuradas."

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "Este relato inclui o link do item e seus outros dados, o veredito a que o BitForge chegou e a regra que o decidiu, se você mesmo colocou este item na sua lista negra ou branca, o que você tem equipado no espaço que ele ocuparia, e as configurações que avaliaram o par. Um link de item indica o nível e a especialização do seu personagem -- isso faz parte do próprio formato do link, e removê-lo perderia o detalhe que torna o relato reproduzível. Nada aqui nomeia seu personagem, seu reino, sua guilda ou sua facção, e nada descreve nenhum outro espaço."

-- The disenchant scan's own footnote: it discloses several bag items and
-- their tooltips, not the single item/link pair report:blurbSell describes.
L["report:blurbDisenchant"] = "Este relato inclui o estado atual de mira de feitiço do cliente e se este personagem sabe desencantar. Também inclui até oito armas ou peças de armadura das suas mochilas que poderiam valer a pena desencantar, cada uma com sua mochila, espaço, ID do item, nome, qualidade, tipo de item e a própria previsão do BitForge sobre se ele pode ser desencantado, além do texto completo do seu tooltip. Para qualquer outro item nas suas mochilas cuja qualidade não pôde ser lida, também inclui a mochila, o espaço, o ID do item e o nome desse item. Nada aqui nomeia seu personagem, seu reino, sua guilda ou sua facção."
L["report:blurbDispatch"] = "Este relato inclui o link e a qualidade do item, de qual mochila e espaço ele respondeu quando você o carrega, o veredito a que cada caminho de regras chegou para ele -- seu próprio detalhe extra, e se ele veio de uma substituição salva -- e a reivindicação, a força e o motivo próprios de cada caminho, incluindo qualquer caminho que não tenha conseguido responder de forma alguma. Quando o item é de qualidade ruim, este relato também informa se a função “Vender lixo” da Blizzard o venderia mesmo assim, de acordo com suas próprias configurações de venda e da regra de lixo. Quando o item é um reagente de criação, este relato também traz as profissões para as quais o catálogo distribuído com o complemento o lista, as profissões registradas para esta conta -- ou apenas as deste personagem, quando a cópia está vinculada à alma -- a expansão à qual o item pertence e se você tem essa expansão selecionada, se uma receita marcada por você precisa dele, e com qual dessas coisas a própria regra de reagentes respondeu -- o veredito da própria regra, que nem sempre é o que decidiu o item. Ele sempre lista as receitas que você marcou, por ID e, onde o jogo ainda consegue nomear alguma, por nome, então ele diz o que você cria e não apenas o que está carregando. Quando o diagnóstico está ativado, este relato também traz o mapa em que você estava e o mapa que o contém e, para um item restrito a um lugar, os lugares que essa restrição nomeia e qual deles correspondia a onde você estava. Um link de item indica o nível e a especialização do seu personagem -- isso faz parte do próprio formato do link, e removê-lo perderia o detalhe que torna o relato reproduzível. Nada aqui nomeia seu personagem, seu reino, sua guilda ou sua facção."

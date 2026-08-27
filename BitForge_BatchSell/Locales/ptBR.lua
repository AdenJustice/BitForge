if GetLocale() ~= "ptBR" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

L["panel:batchSell"] = "Venda em lote"
L["panel:sellManifest"] = "Manifesto de venda"
L["panel:blacklist"] = "Lista negra"
L["panel:whitelist"] = "Lista branca"

L["ui:ruleWindowTitle"] = "Regras de venda em lote"
L["ui:ruleWindowNothingToConfigure"] = "Não há nada para configurar aqui."
L["ui:ruleWindowDisclaimer"] =
"Em combate e dentro de instâncias, o jogo às vezes não revela os detalhes de um item. O BatchSell mantém esses itens em vez de adivinhar, então alguns podem estar faltando na lista -- isso é esperado. Um veredito que pareça errado por qualquer outro motivo vale a pena reportar."
L["ui:selectedCount"] = "Seleção: %d"

L["btn:sellAll"] = "Vender tudo"
L["btn:refresh"] = "Atualizar"
L["btn:rules"] = "Regras"

L["menu:temporaryExclude"] = "Excluir temporariamente"
L["menu:blacklisted"] = "Lista negra"
L["menu:whitelisted"] = "Lista branca"
L["menu:noStatus"] = "Nenhuma"
L["menu:reportVerdict"] = "Reportar este veredito"

L["status:noItemsToSell"] = "Nenhum item para vender"
L["status:itemsTotal"] = "%d itens  |  Total: %s"

L["ui:manifestHint"] = "Esperava algo que não está na lista? Passe o mouse sobre ele nas suas mochilas para ver o motivo."

-- Merchant row
L["tooltip:charOverride"] =
"A configuração deste personagem substitui a lista da Tropa de Guerra — este item será vendido."

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
L["settings:compareQuality"] = "Comparar qualidade"
L["settings:compareQualityTooltip"] =
"Vende equipamentos cuja qualidade seja inferior à do que você usa, independentemente do nível do item"
L["settings:compareItemLevel"] = "Comparar nível do item"
L["settings:compareItemLevelTooltip"] =
"Compara o equipamento com o que você usa pelo nível do item, usando a margem abaixo. Com isto desativado, o nível do item não influencia a decisão"
L["settings:ilvlMargin"] = "Margem de nível do item"
L["settings:ilvlMarginTooltip"] =
"Quanto vale um grau de qualidade em níveis de item. Com 10, uma peça um grau abaixo da que você usa precisa superá-la por 10 para ser mantida, e uma um grau acima sobrevive 10 abaixo. Na sua própria qualidade, a peça precisa simplesmente superar o espaço. Com 0 a qualidade deixa de contar e só o nível do item decide"
L["settings:emphasizeQuality"] = "Enfatizar qualidade"
L["settings:emphasizeQualityTooltip"] =
"Conta um grau de qualidade pelo dobro da margem e permite que uma peça da sua própria qualidade fique essa margem abaixo do espaço. A qualidade acima da que você usa fica mais barata de manter, e a abaixo mais cara de desculpar"
L["settings:keepForDisenchant"] = "Manter equipamento desencantável"
L["settings:keepForDisenchantTooltip"] =
"Mantém equipamentos que poderiam ser desencantados, para o leilão ou um alternativo com a profissão. Encantadores sempre mantêm seu próprio equipamento vinculado desencantável, independentemente deste ajuste"
L["settings:spareBindOnAccount"] = "Poupar equipamento vinculado à conta"
L["settings:spareBindOnAccountTooltip"] =
"Qual equipamento não vinculado, vinculado à conta, manter para que uma cópia chegue a outro personagem: o desta expansão, tudo, ou nenhum"
L["settings:spareBindOnEquip"] = "Poupar equipamento vinculado ao equipar"
L["settings:spareBindOnEquipTooltip"] =
"Qual equipamento não vinculado, vinculado ao equipar, manter para outro personagem ou o leilão: o desta expansão, tudo, ou nenhum"
L["settings:reagentsCurrentOnly"] = "Apenas reagentes desta expansão"
L["settings:reagentsCurrentOnlyTooltip"] =
"Restringe a regra acima aos reagentes da expansão atual. Uma receita que pede uma erva de Classic continua pedindo do mesmo jeito hoje, então isto fica desligado a menos que você prefira não acumular reagentes antigos"
L["settings:keepUncollectedCosmetic"] = "Manter aparências não coletadas"
L["settings:keepUncollectedCosmeticTooltip"] =
"Mantém qualquer item cuja aparência você ainda não coletou. Vender uma peça comum a coleta mesmo assim, mas um item cosmético só concede o visual ao ser usado: vendê-lo perde a aparência de vez"
L["settings:sellRelics"] = "Vender relíquias de Classic"
L["settings:sellRelicsTooltip"] =
"Vende ídolos, tomos, totens e sigilos, o espaço de relíquia que Cataclysm removeu. Não são as relíquias de artefato de Legion, que são gemas e só compartilham o número da subclasse"
L["settings:gemsCurrent"] = "Manter gemas desta expansão"
L["settings:gemsCurrentTooltip"] =
"Mantém as gemas da expansão atual. As mais antigas seguem para as duas perguntas abaixo"
L["settings:gemsRecipesNow"] = "Manter gemas atuais que alguma receita use"
L["settings:gemsRecipesNowTooltip"] =
"Mantém uma gema da expansão atual que alguma receita de profissão use como reagente, seja de quem for essa profissão. A pergunta vai ao catálogo de receitas, e uma gema que ele nunca viu é mantida em vez de adivinhada"
L["settings:gemsRecipesOld"] = "Manter gemas antigas que alguma receita use"
L["settings:gemsRecipesOldTooltip"] =
"A mesma pergunta para gemas de expansões passadas. O que as suas próprias profissões usam já é mantido em outro ponto, então esta coluna serve às receitas de todo mundo"
L["settings:keepArtifactRelics"] = "Manter relíquias de artefato"
L["settings:keepArtifactRelicsTooltip"] =
"Mantém as relíquias que eram encaixadas nas armas de artefato de Legion. Nada as usa desde Legion, então vale desligar a menos que você as colecione"
L["settings:enhancementsKeepLast"] = "Manter aprimoramentos da expansão passada"
L["settings:enhancementsKeepLastTooltip"] =
"Mantém os aprimoramentos de item da expansão imediatamente anterior, para um personagem que ainda usa o equipamento que eles servem. Só essa é oferecida: ninguém está subindo de nível pela anterior a ela"
L["settings:keepLearnable"] = "Manter receitas que você pode aprender"
L["settings:keepLearnableTooltip"] =
"Mantém uma receita que este personagem ainda não aprendeu"
L["settings:keepTradeableRecipes"] = "Manter receitas negociáveis"
L["settings:keepTradeableRecipesTooltip"] =
"Mantém uma receita ainda não vinculada, para que ela chegue a um alt ou ao leilão mesmo quando este personagem já a aprendeu"
L["settings:sellCollectedMounts"] = "Vender montarias coletadas"
L["settings:sellCollectedMountsTooltip"] =
"Vende uma montaria que você já possui, desde que a cópia esteja vinculada à alma. Uma cópia não vinculada é mantida diga o que disser esta opção, porque ainda pode chegar a alguém"
L["settings:sellCollectedPets"] = "Vender mascotes coletados"
L["settings:sellCollectedPetsTooltip"] =
"Vende um mascote de batalha que você já tem. Um que você nunca coletou nunca é vendido por esta regra, em nenhuma das posições"
L["settings:sellHoliday"] = "Vender itens de festividade"
L["settings:sellHolidayTooltip"] =
"Vende as fichas, fantasias e bugigangas que os eventos do mundo deixam nas suas bolsas"
L["settings:sellMountEquipment"] = "Vender equipamento de montaria"
L["settings:sellMountEquipmentTooltip"] =
"Vende equipamento de montaria. Só uma peça vale para a conta inteira por vez, então as sobras nas suas bolsas não fazem nada"
L["settings:sellCollectedDecor"] = "Vender decoração coletada"
L["settings:sellCollectedDecorTooltip"] =
"Vende a decoração de moradia que o seu catálogo já tem. Uma peça que ele nunca viu é mantida, e também uma para a qual o catálogo não pôde ser lido"
L["settings:keepTradeableDyes"] = "Manter tintas negociáveis"
L["settings:keepTradeableDyesTooltip"] =
"Uma tinta é gasta ao ser aplicada e nunca é aprendida, então não há coleção a consultar. O que se pergunta é se esta cópia ainda pode chegar a alguém: não vinculada é mantida, vinculada é vendida"
L["settings:spareProfessions"] = "Poupar para estas profissões"
L["settings:spareProfessionsTooltip"] =
"Mantém uma mercadoria se alguma profissão marcada aqui pudesse usá-la como reagente -- para um alt que ainda não a tenha aprendido, ou para a casa de leilões. As profissões desta conta já são cobertas por Manter reagentes das suas profissões"

L["spare:current"] = "Expansão Atual"
L["spare:all"] = "Tudo"
L["spare:none"] = "Nenhum"

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

L["option:current"] = "Manter tudo desta expansão"
L["option:lastExpansion"] = "E da anterior, enquanto você sobe de nível nela"
L["option:recipesNow"] = "Manter os desta expansão, a menos que nenhuma receita os queira"
L["option:recipesOld"] = "Manter os mais antigos, a menos que nenhuma receita os queira"

-- List tabs
L["btn:removeEntry"] = "Remover"
L["list:warband"] = "Tropa de Guerra"
L["list:character"] = "Personagem"
L["status:listEmpty"] = "Esta lista está vazia"
L["status:listCount"] = "%d entradas"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "Venda em lote: será vendido"
L["verdict:keep"] = "Venda em lote: será mantido"
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
L["reason:BAG_KEPT"] = "Bolsas nunca são vendidas"
L["reason:PROFESSION_GEAR_KEPT"] = "Equipamento profissional nunca é vendido"
L["reason:ENHANCEMENT_CURRENT"] = "Encantamentos desta expansão são mantidos"
L["reason:ENHANCEMENT_LAST_EXPANSION"] = "Encantamentos da expansão anterior são mantidos"
L["reason:ENHANCEMENT_OUTDATED"] = "Encantamentos de expansões anteriores são vendidos"
L["reason:CONSUMABLE_CURRENT"] = "Os consumíveis desta expansão são mantidos"
L["reason:CONSUMABLE_LAST_EXPANSION"] = "Os consumíveis da expansão anterior são mantidos"
L["reason:CONSUMABLE_REAGENT"] = "Alguma receita usa isto como reagente"
L["reason:GEM_CURRENT"] = "As gemas desta expansão são mantidas"
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
L["reason:HOLIDAY_ITEM"] = "Itens de feriado são vendidos"
L["reason:MOUNT_EQUIPMENT"] = "Equipamento de montaria é vendido"
L["reason:ALREADY_COLLECTED"] = "O item já foi colecionado, então é vendido"
L["reason:NOT_COLLECTED"] = "O item ainda não foi colecionado, então é mantido"
L["reason:STILL_TRADEABLE"] = "O item ainda é comerciável, então é mantido"
L["reason:ALREADY_LEARNED"] = "O item já foi aprendido, então é vendido"
L["reason:DEFAULT"] = "Nenhuma regra o reivindicou, então é mantido"

L["listReset:warbandBlacklist"] = "Redefinir lista negra da Tropa de Guerra"
L["listReset:warbandWhitelist"] = "Redefinir lista branca da Tropa de Guerra"
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
"Tudo o que estiver na sua lista de nunca vender fica nas suas mochilas. Uma configuração deste personagem prevalece sobre a lista da Tropa de Guerra, qualquer que seja o sentido da divergência entre as duas."
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
"Itens cinzas, seja qual for o tipo. Desativado por padrão, porque geralmente outro addon já cuida disso. Se nenhum outro cuidar, ative esta opção e o BatchSell vai limpá-los para você."
L["rule:epic"] = "Lendário e acima"
L["rule:epicSub"] = "Lendário, Artefato, Herança"
L["rule:epicBlurb"] =
"Nunca é vendido. O vendedor mostra um preço para estes itens e depois recusa a venda, então o BatchSell não os coloca na lista."
L["rule:reagent"] = "Reagentes de criação"
L["rule:reagentSub"] = "Usa sua lista de profissões"
L["rule:reagentBlurb"] =
"Mantém qualquer reagente que uma profissão desta conta possa usar, seja qual for o tipo de item. Reagentes aparecem tanto em poções quanto em gemas e materiais de comércio, então isto é verificado antes do tipo do item. A lista é lida das próprias receitas do jogo, então já traz os reagentes opcionais que uma receita aceita e todos os níveis de qualidade -- você não precisa abrir nem varrer nada."
L["rule:cosmetic"] = "Aparências não colecionadas"
L["rule:cosmeticSub"] = "Itens cosméticos que você ainda não colecionou"
L["rule:cosmeticBlurb"] =
"Um item cosmético que você não colecionou é mantido. Vendê-lo não coleciona a aparência -- ela simplesmente desaparece --, então este é o único lugar na janela onde um erro não pode ser desfeito. Um item cosmético que você já colecionou não é vendido só por ser um; ele simplesmente não carrega mais nada a proteger, e passa a ser avaliado como a arma ou armadura que é."
L["rule:consumables"] = "Consumíveis"
L["rule:consumablesSub"] = "Poções, comida, pergaminhos, curiosidades"
L["rule:consumablesBlurb"] =
"Escolha o que manter para cada tipo de consumível. Tudo o que nenhuma opção mantiver é vendido. Poções, elixires, frascos e comida recebem mais uma opção -- a da expansão anterior também -- que só se aplica enquanto você estiver mantendo a desta expansão."
L["rule:bags"] = "Mochilas"
L["rule:bagsSub"] = "Contêineres de todo tipo"
L["rule:bagsBlurb"] =
"Nunca são vendidas. Quais mochilas você carrega é decisão sua, então o BatchSell não as avalia."
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
"Uma nova expansão limita o equipamento ao qual estes podem ser aplicados, então os mais antigos deixam de valer alguma coisa. Os desta expansão são mantidos, e os da expansão anterior também, se você quiser."
L["rule:recipes"] = "Receitas"
L["rule:recipesSub"] = "Padrões, plantas, fórmulas"
L["rule:recipesBlurb"] =
"Cada receita carrega consigo a profissão à qual pertence, então é avaliada assim que aparece diante do vendedor. Uma receita que não pertence a nenhuma profissão específica -- um padrão ou um manual genérico -- é deixada de lado, pois não há nada com que avaliá-la."
L["rule:misc"] = "Diversos"
L["rule:miscSub"] = "Mascotes, montarias, itens de feriado"
L["rule:miscBlurb"] =
"Reagentes de feitiço e itens não categorizados são deixados de lado. Itens cinzas são tratados pela regra Qualidade ruim acima, não aqui."
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
"Tipos de item que o BatchSell não avalia de forma alguma: itens de missão, chaves, mascotes engaiolados, glifos, Símbolos da WoW, reagentes de feitiço, flechas e as outras categorias aposentadas. Eles ficam nas suas mochilas não importa como as regras acima estejam configuradas."

-- The report window's footnote. What BatchSell discloses is not what Openables
-- discloses, so each module states its own.
L["report:blurb"] = "Este relato inclui o link do item, o que você tem equipado no espaço que ele ocuparia, e as configurações que avaliaram o par. Um link de item indica o nível e a especialização do seu personagem -- isso faz parte do próprio formato do link, e removê-lo perderia o detalhe que torna o relato reproduzível. Nada aqui nomeia seu personagem, seu reino, sua guilda ou sua facção, e nada descreve nenhum outro espaço."

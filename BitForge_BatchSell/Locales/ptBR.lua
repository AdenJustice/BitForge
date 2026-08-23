if GetLocale() ~= "ptBR" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "Venda em lote"
L["panel:sellManifest"] = "Manifesto de venda"
L["panel:blacklist"] = "Lista negra"
L["panel:whitelist"] = "Lista branca"

-- Buttons
L["btn:sellAll"] = "Vender tudo"
L["btn:refresh"] = "Atualizar"

-- Context menu
L["menu:addToBlacklist"] = "Adicionar à lista negra"
L["menu:addToWhitelist"] = "Adicionar à lista branca"
L["menu:addToBlacklistChar"] = "Adicionar à lista negra (personagem)"
L["menu:addToWhitelistChar"] = "Adicionar à lista branca (personagem)"
L["menu:clearCharOverride"] = "Remover substituição do personagem"
L["menu:resetListEntry"] = "Remover da lista"
L["menu:temporaryExclude"] = "Excluir temporariamente"

-- Status
L["status:noItemsToSell"] = "Nenhum item para vender"
L["status:itemsTotal"] = "%d itens  |  Total: %s"

-- Merchant row
L["tooltip:charOverride"] =
"A configuração deste personagem substitui a lista da Tropa de Guerra — este item será vendido."

-- Section titles
L["section:general"] = "Geral"
L["section:equipment"] = "Equipamento"
L["section:materials"] = "Materiais de Fabricação"
L["section:other"] = "Consumíveis e Outros"
L["section:lists"] = "Listas"

-- Settings
L["settings:sellJunk"] = "Vender lixo"
L["settings:sellJunkTooltip"] = "Vende automaticamente todos os itens de qualidade ruim (cinza) ao visitar um vendedor"
L["settings:limitBatch"] = "Limitar lote a 12"
L["settings:limitBatchTooltip"] = "Vende no máximo 12 itens por clique para evitar limitação do servidor"
L["settings:sellEquipment"] = "Vender equipamento"
L["settings:sellEquipmentTooltip"] =
"Permite a venda de armaduras e armas. Com isto desativado, nenhum equipamento é vendido"
L["settings:ilvlMargin"] = "Margem de nível do item"
L["settings:ilvlMarginTooltip"] =
"Quanto vale um grau de qualidade em níveis de item. Com 10, uma peça um grau abaixo da que você usa precisa superá-la por 10 para ser mantida, e uma um grau acima sobrevive 10 abaixo. Na sua própria qualidade, a peça precisa simplesmente superar o espaço. Com 0 a qualidade deixa de contar e só o nível do item decide"
L["settings:emphasizeQuality"] = "  Enfatizar qualidade"
L["settings:emphasizeQualityTooltip"] =
"Conta um grau de qualidade pelo dobro da margem e permite que uma peça da sua própria qualidade fique essa margem abaixo do espaço. A qualidade acima da que você usa fica mais barata de manter, e a abaixo mais cara de desculpar"
L["settings:keepBindOnAccount"] = "Manter vinculados à conta"
L["settings:keepBindOnAccountTooltip"] = "Mantém equipamentos vinculados à conta (herança)"
L["settings:keepBindOnAccountPastExpac"] = "  Incluir expansões anteriores"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Também mantém equipamentos vinculados à conta de expansões anteriores"
L["settings:keepDisenchantables"] = "Manter desencantáveis"
L["settings:keepDisenchantablesTooltip"] = "Encantadores: mantém equipamentos LdP/LdC/VàC. Outros: mantém equipamentos LdC/VàC para leilão ou alternativos"
L["settings:keepDisenchantablesPastExpac"] = "  Incluir expansões anteriores"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Também mantém equipamentos desencantáveis de expansões anteriores"
L["settings:keepUsedReagents"] = "Manter reagentes das suas profissões"
L["settings:keepUsedReagentsTooltip"] = "Manter reagentes de criação que qualquer profissão desta conta possa usar"
L["settings:materialsMode"] = "Materiais de Fabricação"
L["settings:materialsModeTooltip"] =
"O que fazer com reagentes, materiais comerciais, gemas, encantamentos e receitas"
L["settings:materialsExpansion"] = "  Manter a partir da expansão"
L["settings:materialsExpansionTooltip"] =
"Mantém materiais a partir desta expansão e vende tudo que for mais antigo. Usado apenas quando Materiais de Fabricação está configurado para manter a partir de uma expansão escolhida"
L["settings:otherMode"] = "Consumíveis e Outros"
L["settings:otherModeTooltip"] =
"O que fazer com consumíveis, recipientes, mascotes de batalha, equipamento de profissão e decoração de moradia"

-- Sell modes
L["mode:keepAll"] = "Manter tudo"
L["mode:keepCurrent"] = "Manter expansão atual"
L["mode:keepFrom"] = "Manter a partir da expansão"
L["mode:sellAll"] = "Vender tudo"

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
L["reason:CATEGORY"] = "Este tipo de item está configurado para ser mantido"
L["reason:CURRENT_EXPANSION"] = "De uma expansão que você está mantendo"
L["reason:BIND_ON_ACCOUNT"] = "Equipamentos vinculados à conta são mantidos"
L["reason:DISENCHANTABLE"] = "Vale a pena manter para desencantar ou revender"
L["reason:REAGENT_WANTED"] = "Uma profissão desta conta usa isto"
L["reason:NOT_EQUIPPABLE"] = "Não equipável ou não recomendado para sua classe"
L["reason:EQUIPPABLE"] = "Bom o suficiente em comparação ao que você tem equipado"
L["reason:OUTCLASSED"] = "Superado pelo que você tem equipado"
L["reason:SELL_MODE"] = "Este tipo de item está configurado para ser vendido"
L["reason:DEFAULT"] = "Nenhuma regra o reivindicou, então é mantido"

-- Expansion labels
L["expansion:classic"] = "Classic"
L["expansion:burningCrusade"] = "A Cruzada Ardente"
L["expansion:wrathOfTheLichKing"] = "A Ira do Lich Rei"
L["expansion:cataclysm"] = "Cataclismo"
L["expansion:mistsOfPandaria"] = "Névoas de Pandária"
L["expansion:warlordsOfDraenor"] = "Senhores de Guerra de Draenor"
L["expansion:legion"] = "Legião"
L["expansion:battleForAzeroth"] = "A Batalha por Azeroth"
L["expansion:shadowlands"] = "Shadowlands"
L["expansion:dragonflight"] = "Dragonflight"
L["expansion:theWarWithin"] = "A Guerra Interior"
L["expansion:midnight"] = "Meia-Noite"

-- List reset buttons
L["listReset:warbandBlacklist"] = "Redefinir lista negra da Tropa de Guerra"
L["listReset:warbandWhitelist"] = "Redefinir lista branca da Tropa de Guerra"
L["listReset:charBlacklist"] = "Redefinir lista negra do personagem"
L["listReset:charWhitelist"] = "Redefinir lista branca do personagem"
L["listReset:confirm"] = "Tem certeza que deseja limpar esta lista? Isso não pode ser desfeito."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "Não é possível vender %s agora: %s"
L["msg:dropUnexcluded"] = "%s não está mais excluído e será vendido nesta visita"

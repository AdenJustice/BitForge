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

-- Settings
L["settings:sellJunk"] = "Vender lixo"
L["settings:sellJunkTooltip"] = "Vende automaticamente todos os itens de qualidade ruim (cinza) ao visitar um vendedor"
L["settings:keepEquippable"] = "Manter equipáveis"
L["settings:keepEquippableTooltip"] = "Mantém todos os itens equipáveis pela sua classe"
L["settings:keepBindOnAccount"] = "Manter vinculados à conta"
L["settings:keepBindOnAccountTooltip"] = "Mantém equipamentos vinculados à conta (herança)"
L["settings:keepBindOnAccountPastExpac"] = "  Incluir expansões anteriores"
L["settings:keepBindOnAccountPastExpacTooltip"] = "Também mantém equipamentos vinculados à conta de expansões anteriores"
L["settings:keepDisenchantables"] = "Manter desencantáveis"
L["settings:keepDisenchantablesTooltip"] = "Encantadores: mantém equipamentos LdP/LdC/VàC. Outros: mantém equipamentos LdC/VàC para leilão ou alternativos"
L["settings:keepDisenchantablesPastExpac"] = "  Incluir expansões anteriores"
L["settings:keepDisenchantablesPastExpacTooltip"] = "Também mantém equipamentos desencantáveis de expansões anteriores"
L["settings:limitBatch"] = "Limitar lote a 12"
L["settings:limitBatchTooltip"] = "Vende no máximo 12 itens por clique para evitar limitação do servidor"
L["settings:qualityThreshold"] = "Limiar de qualidade"
L["settings:qualityThresholdTooltip"] = "Vende itens com essa qualidade ou inferior"
L["settings:ilvlThreshold"] = "Margem de nível do item"
L["settings:ilvlThresholdTooltip"] =
"Mantém itens equipáveis dentro desta quantidade de níveis do seu equipamento equipado (negativo = manter itens melhores)"
L["settings:sellPastExpansion"] = "Vender itens de expansões anteriores"
L["settings:sellPastExpansionTooltip"] = "Vende itens de expansões mais antigas que o limiar selecionado"
L["settings:expansionThreshold"] = "Limiar de expansão"
L["settings:expansionThresholdTooltip"] = "Vende itens de expansões mais antigas que a selecionada"

-- Quality labels
L["quality:poor"] = "Ruim"
L["quality:common"] = "Comum"
L["quality:uncommon"] = "Incomum"
L["quality:rare"] = "Raro"
L["quality:epic"] = "Épico"

-- Expansion labels
L["expansion:all"] = "Todas as expansões"
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

-- List reset buttons
L["listReset:warbandBlacklist"] = "Redefinir lista negra da Tropa de Guerra"
L["listReset:warbandWhitelist"] = "Redefinir lista branca da Tropa de Guerra"
L["listReset:charBlacklist"] = "Redefinir lista negra do personagem"
L["listReset:charWhitelist"] = "Redefinir lista branca do personagem"
L["listReset:confirm"] = "Tem certeza que deseja limpar esta lista? Isso não pode ser desfeito."

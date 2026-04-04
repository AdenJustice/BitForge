if GetLocale() ~= "ptBR" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Usar configurações do personagem"
L["settings:useCharSettingsTooltip"] = "Substituir configurações de conta pelas configurações específicas deste personagem"

L["settings:desiredBalance"] = "Saldo desejado"
L["settings:desiredBalanceTooltip"] = "Quantidade de ouro alvo a manter em seus bolsos"

L["settings:marginalRatio"] = "Proporção marginal"
L["settings:marginalRatioTooltip"] = "Ignorar reequilíbrio se a diferença estiver dentro do desejado × proporção"

L["settings:collectorCharacter"] = "Personagem coletor"
L["settings:collectorCharacterTooltip"] = "Personagem que coleta o ouro excedente do Banco da Tropa de Guerra"

L["settings:none"] = "Nenhum"
L["settings:always"] = "Sempre"

L["msg:deposit"] = "Depositou %s no Banco da Tropa de Guerra"
L["msg:withdraw"] = "Retirou %s do Banco da Tropa de Guerra"
L["msg:collect"] = "Coletou %s do Banco da Tropa de Guerra"
L["msg:noFunds"] = "O Banco da Tropa de Guerra não possui fundos para sacar"

if GetLocale() ~= "ptBR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Clique esquerdo para opções"
L["minimap:hintDrag"] = "Arraste para mover"
L["minimap:compartmentTooltip"] = "Abrir o menu do BitForge"

-- Schema upgrade
L["msg:schemaResetBody"] = "Os dados salvos de %s são de uma versão anterior e não podem ser mantidos. Eles serão apagados e reconstruídos. Isso acontece apenas uma vez."
L["btn:schemaResetAccept"] = "Apagar e continuar"

-- Slash commands
L["cmd:usage"] = "/bitforge <módulo> [argumentos], /bfdump <módulo> [argumentos] -- um nome de módulo pode ser abreviado para qualquer prefixo sem ambiguidade"
L["cmd:unknownModule"] = "nenhum módulo chamado %s -- use /bitforge para ver a lista"
L["cmd:ambiguousModule"] = "%s indica mais de um módulo: %s"
L["cmd:noSuchCommand"] = "%s não responde ao comando %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- mostra o que mudou nesta atualização"

-- Report window
L["report:windowTitle"] = "Reportar um item"
L["report:howTo"] = "Selecione tudo e pressione Ctrl+C. Cole em um novo ticket em:"
L["report:selectAll"] = "Selecionar tudo"

-- The release-notes popup
L["whatsNew:windowTitle"] = "Novidades do BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Fechar"

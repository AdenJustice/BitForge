if GetLocale() ~= "ptBR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "Clique esquerdo para opções"
L["minimap:hintDrag"] = "Arraste para mover"
L["minimap:compartmentTooltip"] = "Abrir o menu do BitForge"

L["msg:schemaResetBody"] = "Os dados salvos de %s são de uma versão anterior e não podem ser mantidos. Eles serão apagados e reconstruídos. Isso acontece apenas uma vez."
L["btn:schemaResetAccept"] = "Apagar e continuar"

L["cmd:usage"] = "/bitforge <módulo> [argumentos], /bfdump <módulo> [argumentos] -- um nome de módulo pode ser abreviado para qualquer prefixo sem ambiguidade"
L["cmd:unknownModule"] = "nenhum módulo chamado %s -- use /bitforge para ver a lista"
L["cmd:ambiguousModule"] = "%s indica mais de um módulo: %s"
L["cmd:noSuchCommand"] = "%s não responde ao comando %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- mostra o que mudou nesta atualização"

L["report:windowTitle"] = "Reportar um item"
L["report:windowTitleDiagnostic"] = "Relatório de diagnóstico"
L["report:howTo"] = "Selecione tudo e pressione Ctrl+C. Cole em um novo ticket em:"
L["report:selectAll"] = "Selecionar tudo"
L["report:encoded"] = "Este relatório era muito longo para ler, por isso foi compactado. Cole-o como está -- as ferramentas do desenvolvedor vão descompactá-lo."

L["whatsNew:windowTitle"] = "Novidades do BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Fechar"

L["upgrade:windowTitle"] = "O BitForge agora são seis downloads"
L["upgrade:lead"] = "De agora em diante, o BitForge e seus módulos são downloads separados: um projeto cada, atualizado por conta própria. Atualizar o BitForge não removeu nada, então tudo o que você já tinha continua instalado e continua funcionando."
L["upgrade:separate"] = "Estes não fazem mais parte do download do BitForge, e nada vai atualizá-los de novo até você instalar cada um como seu próprio projeto:"
L["upgrade:renamed"] = "O BitForge Dispatch foi renomeado para BitForge AzerothPrime, e é um projeto próprio com esse nome. Instale-o e tudo o que o Dispatch tinha salvo -- regras, listas por item, destinos de depósito, listas de bloqueio, o tamanho e a posição do botão -- vem junto. Se o Dispatch antigo ainda estiver instalado, o AzerothPrime o desativa primeiro e suas configurações chegam no seu próximo login, então ver o Dispatch acinzentado na lista de addons é o esperado e não uma falha; a pasta pode ser apagada nesse momento. Uma coisa não vem junto: o atalho de teclado do botão de itens abríveis, que o jogo guarda sob o nome do botão. Defina-o novamente em Atalhos."
L["upgrade:close"] = "Entendi"

L["msg:outOfStep"] = "Atualize o %s pelo CurseForge: ele está na %s enquanto o BitForge está na %s. Agora cada um é um download próprio, então um gerenciador de addons pode atualizar um e não o outro."

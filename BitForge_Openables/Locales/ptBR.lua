if GetLocale() ~= "ptBR" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Openables"
L["settings:enabled"] = "Ativar Openables"
L["settings:enabledTooltip"] = "Mostra um botão para o próximo item abrível ou usável nas suas bolsas"
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

L["report:blurb"] = "Este relatório contém o item, como o BitForge o classificou, o texto de seu tooltip e quais profissões este personagem conhece. Nada aqui menciona seu personagem, reino, guilda ou facção."

L["report:blurbField"] = "Este relatório contém cada candidato que a última varredura classificou para abrir em seguida, na ordem da classificação: o nome, o ID do item, a bolsa e o slot, a quantidade empilhada, a prioridade e o motivo de sua posição, e se está travado, em recarga ou adiado. Nada aqui menciona seu personagem, reino, guilda ou facção, e o texto do tooltip de nenhum item é incluído."

L["blacklist:windowTitle"] = "Itens bloqueados"
L["blacklist:empty"] = "Nenhum item está bloqueado."
L["blacklist:remove"] = "Remover"
L["blacklist:clearAll"] = "Limpar tudo"
L["blacklist:unknownItem"] = "Item nº %d"

L["binding:header"] = "BitForge Openables"
L["binding:use"] = "Usar item abrível"

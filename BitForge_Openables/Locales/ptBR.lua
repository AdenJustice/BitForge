---@class BitForge.Openables
local ns = select(2, ...)
if GetLocale() ~= "ptBR" then return end
local L = ns.locale

-- Settings panel
L["panel:title"] = "Abríveis"
L["settings:enabled"] = "Ativar Abríveis"
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
L["settings:manageBlacklist"] = "Gerenciar lista de exclusão"

-- Button tooltip
L["tooltip:use"] = "Clique esquerdo para abrir ou usar."
L["tooltip:skip"] = "Clique direito para pular nesta sessão."
L["tooltip:blacklist"] = "Ctrl + clique direito para excluir permanentemente."
L["tooltip:drag"] = "Alt + arraste para mover."

-- Blacklist
L["blacklist:windowTitle"] = "Itens excluídos"
L["blacklist:empty"] = "Nenhum item está excluído."
L["blacklist:remove"] = "Remover"
L["blacklist:clearAll"] = "Limpar tudo"
L["blacklist:unknownItem"] = "Item nº %d"

-- Key bindings
L["binding:header"] = "BitForge Abríveis"
L["binding:use"] = "Usar item abrível"

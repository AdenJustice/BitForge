if GetLocale() ~= "esES" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Usar configuración del personaje"
L["settings:useCharSettingsTooltip"] = "Sobrescribir la configuración de toda la cuenta con valores específicos de este personaje"

L["settings:desiredBalance"] = "Saldo deseado"
L["settings:desiredBalanceTooltip"] = "Saldo de oro objetivo a mantener en tu mochila"

L["settings:marginalRatio"] = "Ratio marginal"
L["settings:marginalRatioTooltip"] = "Omitir reequilibrio si la diferencia está dentro del saldo deseado × ratio"

L["settings:collectorCharacter"] = "Personaje recolector"
L["settings:collectorCharacterTooltip"] = "Personaje que recolecta el oro sobrante del Banco del Grupo de Guerra"

L["settings:none"] = "Ninguno"
L["settings:always"] = "Siempre"

L["msg:deposit"] = "Depositado %s en el Banco del Grupo de Guerra"
L["msg:withdraw"] = "Retirado %s del Banco del Grupo de Guerra"
L["msg:collect"] = "Recolectado %s del Banco del Grupo de Guerra"
L["msg:noFunds"] = "El Banco del Grupo de Guerra no tiene fondos para retirar"

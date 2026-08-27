if GetLocale() ~= "esES" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Usar configuración del personaje"
L["settings:useCharSettingsTooltip"] = "Sobrescribir la configuración de toda la cuenta con valores específicos de este personaje"

L["settings:desiredBalance"] = "Saldo deseado"
L["settings:desiredBalanceTooltip"] = "Saldo de oro objetivo a mantener en tus bolsas"

L["settings:marginalRatio"] = "Ratio marginal"
L["settings:marginalRatioTooltip"] = "Omitir reequilibrio si la diferencia está dentro del saldo deseado × ratio"

L["settings:collectorCharacter"] = "Personaje recolector"
L["settings:collectorCharacterTooltip"] = "Personaje que recolecta el oro sobrante del banco de la banda guerrera"

L["settings:none"] = "Ninguno"
L["settings:always"] = "Siempre"

L["msg:deposit"] = "Depositado %s en el banco de la banda guerrera"
L["msg:withdraw"] = "Retirado %s del banco de la banda guerrera"
L["msg:collect"] = "Recolectado %s del banco de la banda guerrera"
L["msg:noFunds"] = "El banco de la banda guerrera no tiene fondos para retirar"

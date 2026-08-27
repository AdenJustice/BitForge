if GetLocale() ~= "esMX" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Usar configuración de personaje"
L["settings:useCharSettingsTooltip"] = "Reemplaza la configuración de la cuenta con valores específicos de este personaje"

L["settings:desiredBalance"] = "Saldo deseado"
L["settings:desiredBalanceTooltip"] = "Cantidad de oro objetivo a mantener en tus bolsas"

L["settings:marginalRatio"] = "Proporción marginal"
L["settings:marginalRatioTooltip"] = "Omite el rebalanceo si la diferencia está dentro del saldo deseado × proporción"

L["settings:collectorCharacter"] = "Personaje recolector"
L["settings:collectorCharacterTooltip"] = "Personaje que recolecta el oro en exceso del banco de tropa"

L["settings:none"] = "Ninguno"
L["settings:always"] = "Siempre"

L["msg:deposit"] = "Depositado %s en el banco de tropa"
L["msg:withdraw"] = "Retirado %s del banco de tropa"
L["msg:collect"] = "Recolectado %s del banco de tropa"
L["msg:noFunds"] = "El banco de tropa no tiene fondos para retirar"

if GetLocale() ~= "deDE" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "AutoBalance"

L["settings:useCharSettings"] = "Charaktereinstellungen verwenden"
L["settings:useCharSettingsTooltip"] = "Kontoweite Einstellungen mit charakterspezifischen Werten überschreiben"

L["settings:desiredBalance"] = "Gewünschter Kontostand"
L["settings:desiredBalanceTooltip"] = "Zielgoldmenge, die in Euren Taschen gehalten werden soll"

L["settings:marginalRatio"] = "Marginalverhältnis"
L["settings:marginalRatioTooltip"] = "Neuausgleich überspringen, wenn die Differenz innerhalb von Gewünscht × Verhältnis liegt"

L["settings:collectorCharacter"] = "Sammelcharakter"
L["settings:collectorCharacterTooltip"] = "Charakter, der überschüssiges Gold von der Kriegsmeutenbank einsammelt"

L["settings:none"] = "Keine"
L["settings:always"] = "Immer"

L["msg:deposit"] = "%s auf die Kriegsmeutenbank eingezahlt"
L["msg:withdraw"] = "%s von der Kriegsmeutenbank abgehoben"
L["msg:collect"] = "%s von der Kriegsmeutenbank eingesammelt"
L["msg:noFunds"] = "Die Kriegsmeutenbank hat keine Mittel zum Abheben"

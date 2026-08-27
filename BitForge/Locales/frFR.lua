if GetLocale() ~= "frFR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "Clic gauche pour les options"
L["minimap:hintDrag"] = "Faites glisser pour déplacer"
L["minimap:compartmentTooltip"] = "Ouvrir le menu BitForge"

-- Schema upgrade
L["msg:schemaResetBody"] = "Les données enregistrées de %s proviennent d'une version antérieure et ne peuvent pas être conservées. Elles vont être effacées et reconstruites. Cela n'arrive qu'une fois."
L["btn:schemaResetAccept"] = "Effacer et continuer"

-- Slash commands
L["cmd:usage"] = "/bitforge <module> [arguments], /bfdump <module> [arguments] -- un nom de module peut être abrégé en n'importe quel préfixe sans ambiguïté"
L["cmd:unknownModule"] = "aucun module nommé %s -- utilisez /bitforge pour la liste"
L["cmd:ambiguousModule"] = "%s désigne plusieurs modules : %s"
L["cmd:noSuchCommand"] = "%s ne répond à aucune commande %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- affiche ce qui a changé dans cette mise à jour"

-- Report window
L["report:windowTitle"] = "Signaler un objet"
L["report:windowTitleDiagnostic"] = "Rapport de diagnostic"
L["report:howTo"] = "Tout sélectionner, puis appuyez sur Ctrl+C. Collez-le dans un nouveau ticket à :"
L["report:selectAll"] = "Tout sélectionner"
L["report:encoded"] = "Ce rapport était trop long pour être lu, il a donc été compressé. Collez-le tel quel -- les outils du développeur le décompresseront."

-- The release-notes popup
L["whatsNew:windowTitle"] = "Nouveautés de BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Fermer"

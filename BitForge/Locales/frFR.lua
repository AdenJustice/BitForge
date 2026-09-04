if GetLocale() ~= "frFR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "Clic gauche pour les options"
L["minimap:hintDrag"] = "Faites glisser pour déplacer"
L["minimap:compartmentTooltip"] = "Ouvrir le menu BitForge"

L["msg:schemaResetBody"] = "Les données enregistrées de %s proviennent d'une version antérieure et ne peuvent pas être conservées. Elles vont être effacées et reconstruites. Cela n'arrive qu'une fois."
L["btn:schemaResetAccept"] = "Effacer et continuer"

L["cmd:usage"] = "/bitforge <module> [arguments], /bfdump <module> [arguments] -- un nom de module peut être abrégé en n'importe quel préfixe sans ambiguïté"
L["cmd:unknownModule"] = "aucun module nommé %s -- utilisez /bitforge pour la liste"
L["cmd:ambiguousModule"] = "%s désigne plusieurs modules : %s"
L["cmd:noSuchCommand"] = "%s ne répond à aucune commande %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- affiche ce qui a changé dans cette mise à jour"

L["report:windowTitle"] = "Signaler un objet"
L["report:windowTitleDiagnostic"] = "Rapport de diagnostic"
L["report:howTo"] = "Tout sélectionner, puis appuyez sur Ctrl+C. Collez-le dans un nouveau ticket à :"
L["report:selectAll"] = "Tout sélectionner"
L["report:encoded"] = "Ce rapport était trop long pour être lu, il a donc été compressé. Collez-le tel quel -- les outils du développeur le décompresseront."

L["whatsNew:windowTitle"] = "Nouveautés de BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Fermer"

L["upgrade:windowTitle"] = "BitForge, c'est six téléchargements désormais"
L["upgrade:lead"] = "BitForge et ses modules sont désormais des téléchargements distincts : un projet chacun, mis à jour de son côté. La mise à jour de BitForge n'a rien supprimé, tout ce que vous aviez déjà est donc toujours installé et fonctionne toujours."
L["upgrade:separate"] = "Ceux-ci ne font plus partie du téléchargement de BitForge, et plus rien ne les mettra à jour tant que vous n'aurez pas installé chacun comme son propre projet :"
L["upgrade:renamed"] = "BitForge Dispatch s'appelle désormais BitForge AzerothPrime, et constitue un projet à part sous ce nom. Installez-le et tout ce que Dispatch avait enregistré -- règles, listes par objet, destinations de rangement, listes noires, la taille et la position du bouton -- vient avec lui. Si l'ancien Dispatch est encore installé, AzerothPrime le désactive d'abord et vos réglages arrivent à votre prochaine connexion : voir Dispatch grisé dans la liste des addons est donc attendu et non un défaut, et le dossier peut alors être supprimé. Une chose ne suit pas : le raccourci clavier du bouton d'ouverture, que le jeu enregistre sous le nom du bouton. Redéfinissez-le dans les Raccourcis clavier."
L["upgrade:close"] = "Compris"

L["msg:outOfStep"] = "Mettez %s à jour depuis CurseForge : il est en %s alors que BitForge est en %s. Chacun est désormais son propre téléchargement, un gestionnaire d'addons peut donc mettre l'un à jour et pas l'autre."

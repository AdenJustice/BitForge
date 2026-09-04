if GetLocale() ~= "deDE" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "Linksklick für Optionen"
L["minimap:hintDrag"] = "Zum Verschieben ziehen"
L["minimap:compartmentTooltip"] = "BitForge-Menü öffnen"

L["msg:schemaResetBody"] = "Die gespeicherten Daten für %s stammen aus einer älteren Version und können nicht übernommen werden. Sie werden gelöscht und neu aufgebaut. Dies geschieht einmalig."
L["btn:schemaResetAccept"] = "Löschen und fortfahren"

L["cmd:usage"] = "/bitforge <Modul> [Argumente], /bfdump <Modul> [Argumente] -- ein Modulname darf auf jedes eindeutige Präfix gekürzt werden"
L["cmd:unknownModule"] = "kein Modul namens %s -- /bitforge zeigt die Liste"
L["cmd:ambiguousModule"] = "%s benennt mehr als ein Modul: %s"
L["cmd:noSuchCommand"] = "%s kennt keinen Befehl %s"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- zeigt, was sich in diesem Update geändert hat"

L["report:windowTitle"] = "Einen Gegenstand melden"
L["report:windowTitleDiagnostic"] = "Diagnosebericht"
L["report:howTo"] = "Alles auswählen, dann Strg+C. Fügt es als neues Issue ein unter:"
L["report:selectAll"] = "Alles auswählen"
L["report:encoded"] = "Dieser Bericht war zu lang zum Lesen und wurde deshalb komprimiert. Fügt ihn unverändert ein -- die Tools der Entwickler werden ihn wieder entpacken."

L["whatsNew:windowTitle"] = "Neuerungen in BitForge"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "Schließen"

L["upgrade:windowTitle"] = "BitForge sind jetzt sechs Downloads"
L["upgrade:lead"] = "BitForge und seine Module sind ab sofort getrennte Downloads -- je ein eigenes Projekt, das für sich aktualisiert wird. Beim Aktualisieren von BitForge wurde nichts entfernt, alles bereits Installierte ist also weiterhin vorhanden und funktioniert."
L["upgrade:separate"] = "Diese gehören nicht mehr zum BitForge-Download, und nichts wird sie wieder aktualisieren, bis Ihr jedes davon als eigenes Projekt installiert:"
L["upgrade:renamed"] = "BitForge Dispatch heißt jetzt BitForge AzerothPrime und ist unter diesem Namen ein eigenes Projekt. Installiert es, und alles, was Dispatch gespeichert hatte -- Regeln, Listen je Gegenstand, Verstauziele, Sperrlisten, Größe und Position der Schaltfläche --, kommt mit. Ist das alte Dispatch noch installiert, schaltet AzerothPrime es zuerst ab und Eure Einstellungen treffen bei Eurer nächsten Anmeldung ein; ein ausgegrautes Dispatch in der Addon-Liste ist also zu erwarten und kein Fehler, und der Ordner kann dann gelöscht werden. Eines kommt nicht mit: die Tastenbelegung für die Öffnen-Schaltfläche, die das Spiel unter dem Namen der Schaltfläche speichert. Legt sie in der Tastenbelegung erneut fest."
L["upgrade:close"] = "Verstanden"

L["msg:outOfStep"] = "Aktualisiert %s über CurseForge: es ist auf %s, BitForge dagegen auf %s. Jedes ist jetzt ein eigener Download, ein Addon-Manager kann also das eine aktualisieren und das andere nicht."

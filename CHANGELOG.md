# Changelog

## [v12.1.0.11] — 2026-09-03

### Added

- **Flag a recipe, and Dispatch keeps what it is made of.** Right-click a recipe in your profession window and there is a Flag entry on the menu: from then on, every reagent that recipe consumes is kept even when the reagent rule would otherwise let it go. It reads the recipe's own ingredient list from the game, so nothing has to be listed by hand and a flag keeps working when the recipe's requirements change. Basic ingredients only -- an optional or finishing reagent is not covered, because those are a choice you make at the crafting window rather than something the recipe needs.

- **The expansion lists have a Vanilla row.** Items the game files under the original game had no row to tick, so no expansion list could name them. They can be named now, everywhere an expansion list appears. One quirk worth knowing, and it is the game's rather than ours: a few items sold across late Vanilla and early Burning Crusade report the *current* expansion instead of either of them, so those follow the Current expansion row rather than Vanilla.

- **The openables button offers you a cosmetic whose appearance you have not collected.** These grant the appearance when you use them rather than when you vendor them, so one sitting unused in your bags is an appearance you do not have — and the button never showed them. It could not: an item says it adds an appearance on a line the game gives no type to, indistinguishable from any other sentence in a tooltip, and the two items that do have a type are ensembles and illusions. It now asks the collection directly instead, and a single uncollected appearance ranks with recipes and toys as something to learn. Once it is collected the item drops off the button again.

### Changed

- **`/bfdump` is a developer's command now, and a released build answers none of it.** `/bfdump openables` and `/bfdump batchsell` opened a machine-readable record of what BitForge had concluded about an item; Dispatch inherits neither of them, and `/bfdump eui` goes the same way. None of them is listed by `/bitforge` any more, and typing one is refused. If you ever pasted one of those records into an issue, that is a real loss and worth saying plainly rather than leaving you to find it. What is **not** lost is the record itself: Shift+Alt+right-click on the openables button, and **Report This Verdict** on an item at a vendor, open the same window they always did with the same report in it -- already selected, nothing written to your saved variables, no reload, and still saying what it discloses before you send it.

- **Reagents are now kept by expansion first, and by the recipes you flagged second.** The rule used to be one question -- does one of your professions craft with this -- and it kept the answer whatever expansion the reagent came from. It is two questions now: keep it if its expansion is ticked, otherwise keep it if a recipe you flagged wants it, otherwise sell it. The list starts on **Current expansion**, and your existing profile moves to that default rather than being migrated to something wider. **So expect older reagents to be offered for sale even if you change nothing** -- everything from a finished expansion that no flagged recipe consumes. If you were relying on the old behaviour, tick All expansions in the reagent rule, or flag the recipes you are actually saving them for.

- **Every rule that names expansions now agrees about the original game.** The two questions behind the expansion lists both treated an item from the original game as though the game had not answered, which meant a Vanilla piece slipped past the rules that were supposed to weigh it. This was not confined to reagents: it reaches the Bind on Equip and Bind on Account gear rescues and the keep-it-to-disenchant question too. Those rules now decide about a Vanilla item rather than stepping around it, so a Vanilla piece may be sold where it previously survived, and kept where you have ticked Vanilla.

- **An item in your bags now gets one answer instead of three.** The openables button, the vendor sweep and the Warband deposit each decided on their own, so the same item could sit on the button and in the sell list at once, and whichever you clicked first won. They agree now, and opening comes first -- it is the only one of the three that turns an item into other items, so a box you sold is gone while a box you opened is sorted out on the next pass. Four things follow: a cache or container is opened rather than sold; a recipe another of your characters still needs is kept; a recipe you have not learned but do not want stops being offered on the button and in the sell list at the same time; and with **Only wanted reagents** off, a reagent bound for the bank is no longer offered to the vendor as well. Grey items with a "Use:" line are the deliberate exception and still sell -- "the game says this does something" is not a reason to keep vendor trash.

- **Your own decisions about an item are stored in one place instead of three.** Hiding something from the openables button, putting it on a sell list, and choosing which bank it belongs in were three separate records, kept by what used to be three separate addons. They are one record now, and **everything you had set is carried across the first time you log in** — nothing is reset and there is nothing to re-enter. You should not be able to tell the difference from playing; that is the intent. One consequence worth knowing: once this version has upgraded your saved data, an older version of Dispatch can no longer read it, so this is not a change to roll back from by reinstalling an earlier build.

- **Openables, Batch Sell and UPS are now one addon: Dispatch.** Three folders become one, and the three features become three switches inside it — the openables button, selling at a vendor, and depositing to the Warband Bank — each turned on and off on its own in the settings panel. **Everything you had configured in all three is carried over the first time you log in**: rules, per-item lists, curation destinations, blacklists, the button's size and position. Nothing is reset and there is nothing to re-enter. **One thing does not survive the move: the keybinding for the openables button.** The button's name changed with the addon's, and the game stores keybindings by name, so yours is cleared — set it again in the standard Key Bindings panel. If you install by hand rather than through an addon manager, delete the three old folders: Dispatch refuses to start while any of them is still installed, and tells you which.
- **Every selling rule that asked about an expansion now lets you name the expansions.** The three-way "this expansion / all of them / none" on the gear rescues, and the "keep this expansion's" checkboxes on consumables, gems, reagents and enhancements, are one control now: a list you tick. Keep Dragonflight's flasks and nothing older, or spare Bind on Equip gear from the two expansions you are still levelling alts through. Each list opens with "All expansions" and "Current expansion", which follow the game as it moves, while a named expansion stays the one you picked. Two limits go with the old shape: consumables offered only the expansion immediately behind, and only while "this expansion" was ticked, and enhancements always kept the current expansion whether you wanted them or not. **Your existing settings all carry across** — nothing is reset.
- **Selling trusts the crafting-reagent list instead of hedging against it.** The list is captured from the game's own recipes, and anything missing from it used to count as "unknown" rather than as an answer — so an item it had never heard of was held back rather than judged, whatever you had set. That was meant to protect reagents, and mostly it protected junk: the list does know the real reagents, so those were already being handled correctly, while last expansion's food, gems and trade goods it had never seen sat in your bags forever with no setting that could shift them. Absence now means what it reads as — nothing crafts with this — and those items go through your rules like anything else. **Expect more to be offered for sale**, in the consumables, gems and trade goods rules especially. Your Never Sell list still overrules everything, and the reagent list is retaken from the client and reshipped after a game patch.
- **Eight retired items no longer appear on the openables button.** A Draenor cache, two Legion tomes and a set of War Within delve rewards are all grey, which is how the game marks this kind of item as finished with, and the button's curated list no longer overrides that — so the next one Blizzard retires drops off on its own rather than waiting for someone to notice.

### Fixed

- **A greyed-out dropdown now looks greyed out.** Every BitForge dropdown that switches itself off when another setting has already decided the question was painting only half of itself as disabled -- the arrow and the frame dimmed, the text stayed bright -- so a control that was doing nothing still read as live. It has been shipping that way in TaskTome and EUI as well as here, and all three are fixed together.

- **The report windows now say exactly what they carry.** The footnote under the openables report named the item, how BitForge classified it, its tooltip and this character's professions -- but not the bag and slot it was sitting in or whether it was locked, both of which the report also prints. The sell verdict's footnote was short of fields in the same way. So a report pasted into a public issue carried a little more than its own footnote promised. Both now list everything they disclose, and what you are told you are sending is what you send.

- **The selling rules stop short of an item the game will not describe.** An item's quality can be missing for a moment while the game is still answering, or withheld by the game outright — and only the first of those was being recognised. The selling rules and the disenchant probe now recognise both, and treat such an item as unanswered rather than weighing it against your settings on a quality nobody ever gave them.

- **The openables button no longer acts on an item before the game has finished describing it.** An item's tooltip and its item data load separately, and for a moment after a bag changes the tooltip can be empty. The button read that silence as an answer -- it took "no line said this item cannot be used" from a tooltip it had not been shown -- so in that moment it could offer an item the game itself refuses, and a toy or a recipe could be ranked below whatever else you were carrying instead of at the top. It now waits, and the item appears as soon as the tooltip arrives. If you are used to something showing up the instant it drops, it may now take a fraction of a second longer.

- **Moving the openables button no longer skips the item on it.** Alt and left-drag is how you reposition the button, and the same press was also counted as using the item -- so the item you were carefully not touching went to the back of the queue and the button moved on to the next one. It never actually opened anything: the game only performs a button's action on an unmodified click, so holding Alt meant nothing happened at all except the wrong bookkeeping. Holding Shift or Ctrl on a left click had the same effect and nobody had noticed. All three now leave the item where it is.

- **The openables button no longer offers you socket gems.** A gem's stats are built as an enchantment, and that is indistinguishable to an addon from an ordinary "Use:" effect — so every gem sitting in your bags took its turn on the button as though it were something to open. A gem goes into a socket rather than opening anything, and they are now left out.

## [v12.1.0.10] — 2026-08-30

### Fixed

- **The CurseForge download works again.** v12.1.0.8 and v12.1.0.9 were built and uploaded, and CurseForge refused both of them while processing the file — so the newest version there is still v12.1.0.7, and everything those two releases carried has been sitting somewhere CurseForge could not hand it to you. The package was shipping a documentation folder belonging to a bundled library, which CurseForge will not accept in an addon. The Wago and GitHub downloads were unaffected and have had both releases all along.

## [v12.1.0.9] — 2026-08-30

### Changed

- **BitForge has a mark of its own.** The minimap button was wearing the game's engineering icon, and the addon list and the addon compartment entry showed nothing at all — the icon the addon claimed to carry had never been drawn. All three now show the suite's own.

## [v12.1.0.8] — 2026-08-27

### Changed

- **`/bfdump batchsell` opens a window you can copy out of.** It used to write its record into the saved variables, so getting it to us meant setting a debug flag by hand, running the command, reloading, opening `SavedVariables/BitForge.lua` in a text editor and pasting a Lua table — which is why almost nobody ever did. It now renders the record straight into the same window the report button uses: select, copy, paste. Nothing is written to disk, so the diagnostics flag no longer has to be on for the command to answer, and each report still states what it discloses before you send it. The other modules follow.
- **Every `/bfdump` now opens that window** — Openables and the EllesmereUI helper as well as BatchSell, and each with its own footnote saying what that particular report discloses. A diagnostic dump opens under its own title rather than borrowing the item report's, since a bag's ranked list or a frame's position is not an item. `/bfdump dev recipes` is the one exception and keeps writing to the saved variables: a whole profession is a quarter of a megabyte, and it exists to be carried out of the game as a file rather than read.
- **A diagnostic too long to read is compressed instead.** The bag-walking dumps run to hundreds of lines of tooltip text nobody was ever going to read — just select and paste. Above a few thousand characters the window now shows a single compressed line instead, and the footnote says so: paste it exactly as it is and the developer's tools unpack it. Reports short enough to read are untouched and stay readable, which is the whole point of the window.
- **The report window stays where you put it.** Drag it somewhere that suits your screen and it opens there next time, for every character on the account. It only remembers the report window — the What's New popup still opens where it always did.
- **BatchSell sells a toy once you have collected it.** Mounts, battle pets and housing decor were already judged on whether your collection has them; toys were the one kind left out, so a toy already in your toy box sat in your bags forever. It is sold only once the copy in your bags is bound — an unbound one is kept whatever your collection says, because it can still reach someone who wants it. On by default, and switchable in the Rules window beside the other three.
- **BatchSell's gear comparison now has two dials instead of one.** "Item Level Margin" was named for item levels but priced a quality tier, and "Emphasize Quality" doubled it *and* granted a tolerance of the same size — one slider doing two jobs, and a checkbox you could not have one without the other of. They are replaced by a margin, which is how far under the slot a piece of your own quality may sit, and a quality margin, which is what one quality tier is worth in item levels. Either can be set to 0 on its own: no tolerance, or quality stops counting and item level alone decides. **Your existing settings for these two are reset to the new defaults**, which reproduce the comparison BitForge shipped with — so if you never touched them, nothing changes. If you had raised the old margin, gear a quality tier above what you wear will now be sold more readily than before until you set the quality margin back where you want it.
- **And the two checkboxes above them are gone.** "Compare Item Level" and "Compare Quality" have left the Rules window, so the two dials are now the whole of the comparison. The first only said whether the two sliders beside it applied at all, and its own description was wrong about what turning it off did; the second sold any piece of lower quality than what you have equipped, whatever its item level. **If you had either set away from its default, gear will be judged differently for you from now on** — the item level comparison can no longer be switched off, and instead of an outright quality veto a lower quality piece now has to make the difference up in item levels, at the price the quality margin sets. If you left both alone, nothing changes.
- **BatchSell's quality margin gained an "Always" setting.** Past the top of the slider there is now one more position, and it is not a number of item levels: set there, gear of a higher quality than what you have equipped is kept whatever its item level, and no amount of item level saves a piece of lower quality. It is the outright quality preference the retired "Compare Quality" tick used to give, now on the same dial as everything else it competes with. The slider also runs to 30 rather than 20, matching the item level margin beside it.
- **Gear that matches what you are wearing is kept rather than sold.** Every item level comparison in the rule was "strictly better"; it is now "at least as good". At the default margin of 0, a piece level with the slot is kept instead of vendored, and a piece a tier below only has to make the quality margin up exactly rather than exceed it. Quality itself is unchanged — this is about item levels alone.
- **A piece from a finished expansion is now weighed by the same two dials as anything else.** BitForge v12.1.0.7 said the opposite — that such a piece "sets its bar on item level alone, no margin, no quality discount" — and **that is withdrawn.** There is one comparison in the rule again, and what a finished-expansion piece still changes is the reason you are told: the tooltip says you outlived that bar rather than merely beat it. **If you are levelling in last expansion's gear, expect this to matter**: at the shipped defaults, this expansion's rare has to beat a finished-expansion epic by the quality margin rather than by a single item level. Setting the quality margin to 0 restores the v12.1.0.7 behaviour, for every comparison rather than only that one.
- **German now addresses you the way the game does.** The client is consistently formal — *Eure Taschen sind voll* — and BitForge was mixing that with the familiar *du*, sometimes inside a single window: BatchSell's settings block was formal while the rule window beside it was not.
- **Each module keeps its name in every language.** Openables, RepRank, Task Tome, AutoBalance and Undermine Parcel Service were being translated as though they were descriptions, which is how UPS ended up named after Undercity in French, Azeroth in Chinese and Kaz'Mina in Portuguese — three places, none of them Undermine.
- **BatchSell stops calling one thing two names inside a single language.** Mexican Spanish used two different verbs down one column of checkboxes; Russian split quality between two words and crafting between two more; Chinese had two words for collecting and two for artifact relics; Portuguese, Italian and Traditional Chinese each named dyes, decor or holiday items differently in the settings than in the rules that describe them.
- **BatchSell speaks the game's own vocabulary in every language.** A Russian setting told you to turn it on under exactly the condition it should be left off. Korean named the sell-list tab and the always-sell tab identically, called Skinning by a word the game does not use, and described item enhancements as arcane power. Six languages narrowed "enhancements" to enchants alone, contradicting the line directly above them. Chinese called heirlooms "retro", used patch where it meant expansion, and used the verb for reporting a player to Blizzard. Spanish called crafting reagents chemical reagents, in three different ways within one file. Around ninety strings in all.
- **The report window and the minimap hint say the right thing in Chinese, German and Russian.** The Chinese title used the verb for reporting someone to the authorities, the German instructions named a key German keyboards do not have (Ctrl, not Strg), and the Russian minimap hint pointed at the wrong word for settings. French now names its own button correctly in the line above it.
- **AutoBalance:** the gold target says "your bags" in the words each client uses for bags, and the Russian checkbox reads as a setting to turn on rather than a section heading.
- **Openables in Portuguese no longer reads as though it destroys things.** Blacklisting was worded with the verb the game uses for *delete*, so "Ctrl + right-click to permanently exclude" invited exactly the wrong reading. Spanish, French and Chinese also get the module's own name and its report wording corrected.
- **TaskTome in Russian calls a task a task.** It used the word the Russian client reserves for quests, which made every tracked item look like one.
- **BatchSell:** the two Bind on Account / Bind on Equip sparing settings explain themselves. They described "unbound Bind on Account gear", which reads in English only because *Bind on Account* is a name — every other language rendered it as "unbound bound gear". They now say what the state is: gear kept while it can still be passed on.
- **The Warband is called what the game calls it**, in every language and every module. Ten of the eleven locales had invented their own word for it, and several used a different invention in each module — Korean alone had three (워밴드, 전투부대, 전쟁부대) for the one thing the game calls 전투부대. The names now match what you read on the bank itself.
- **BatchSell:** the German and Italian Rules window no longer names one thing two ways — the line listing recipe types and the explanation under it used different words for "pattern", on two lines that sit next to each other.
- **BatchSell:** in the Rules window, "Keep this expansion's unless no recipe wants it" now greys out while "Keep everything from this expansion" is ticked above it — for consumables and for gems alike. It could be ticked before and changed nothing, because the broader rule had already kept the item.

### Fixed

- **Keeping gear for an enchanter now asks what it would turn into.** "Keep Disenchantable Gear" was on-or-off, so a Classic-era green was kept forever by a rule whose whole argument is that somebody wants the materials — and nobody wants those. It becomes a choice of **current materials, any materials, or don't keep**, worded about the materials because that is what a disenchant actually gives you: gear from a finished expansion yields that expansion's materials, however current its item level looks. **Your existing setting is carried across unchanged** — if it was on you keep everything, exactly as before, until you narrow it yourself. A new character starts on current materials. Your own enchanter still keeps what only they can reach at any setting; what this decides is whether that reaches older materials too.
- **Warband gear you have already equipped is no longer treated as though an alt could still take it.** A Warbound piece moves freely between your characters until you equip it, and equipping binds it for good — but BatchSell was still reading it as account-bound afterwards, so a worn piece was kept for an alt's enchanter, and a bound Warbound reagent was weighed against every profession on the account rather than the one holding it. Once something is bound, it is bound.
- **BatchSell no longer sells a bound piece when the game has not said whether it is Warbound.** The three rules that keep gear for somebody else each worked out separately whether a copy could still leave you, and one of them read an unanswered question as a no — so a soulbound item the game had not finished describing could be vendored as outclassed. There is one answer to that question now, and where it cannot be answered nothing is sold on it.
- **Openables:** the button stops flickering past an item when what you clicked has a cast time. Clicking it moved the button on, and then moved it on again when the cast finished — so the item it showed in between was never really offered. It now holds still until the use resolves and moves on once.
- **Openables:** an item you cannot use yet is not offered. Something waiting on a part you have not looted, a level you have not reached or a currency you have not saved was being put on the button on nothing more than the fact that it does *something* — an egg that combines with a second half you do not have, for instance. It appears the moment it becomes usable. Items recognised for what they are rather than for having a use — toys, recipes, appearances, anything that opens — are unaffected.
- **Openables:** a toy you have not collected yet is offered as something to learn. One whose tooltip describes what it does rather than announcing itself as a toy — a teleport key, say — was being read as junk and hidden. Once it is in your toy box it goes back to being hidden, since the copy in your bags has nothing left to give.
- **Openables:** profession knowledge items appear again. They had stopped, because the client reports every profession in the game at rank zero when asked by skill line — including the ones your character actually has — so nothing could be recognised as yours. The rank now comes from the API that states it.
- **Openables:** thirteen more items that were never openable stop appearing on the button — a guild banner, a cooking bell, a conduit, a music roll, a blink vial and the rest of one player's report. They are listed by name rather than caught by a rule, because any rule wide enough to catch them would also hide the conduits and reputation tokens they sit beside.
- **Openables:** gadgets stay off the button — repair bots, target dummies, time displacers, remote auction house access and the rest of the category the game files them under. The handful of real containers that share it are unaffected.
- **Openables:** baits, lures and other profession tools stay off the button whether or not your character has learned the profession. One gated on a profession you do not have was offered as something to open — the case where it is least useful, since you cannot use it at all.
- **Openables:** a character who has learned no professions is no longer offered every oddment in their bags as something to study.
- **Openables:** the button keeps moving on however long you go. Clicking through your items advanced once through the whole set and then stuck on the first one, and only logging out or reloading started it moving again.

## [v12.1.0.7] — 2026-08-27

### Added

- **Tell us when BitForge gets an item wrong.** BatchSell's sell list and Openables' button now offer to report the item you are looking at: a window opens with everything BitForge judged it by, already selected, and the address to paste it into. It needs nothing turned on first. The window shows you the whole report rather than hiding it behind a button, and says plainly what it discloses — for BatchSell that is the item's link, which states your character's level and specialization, and whatever you have equipped in the slot it would fill; for Openables it is the item, how it was classified, and which professions the character knows. Neither names your character, realm, guild or faction. Reach it from the menu on a row in the sell list, or with Shift + Alt + right-click on Openables' button.
- **BitForge tells you what changed after it updates.** The first time you log in on a new version, a window lists everything new since the version you last saw, and does not come back until the next update. `/bitforge core whatsnew` opens it again.
- **RepRank:** factions are grouped by expansion, under the same headings the game's own reputation pane uses, indented beneath the Warband and Characters sections. Sorting by rank now orders factions within their expansion rather than across the whole list. A faction recorded before this update sits under "Other" until the character holding it next logs in.
- **Openables:** an item that starts a quest is now marked with a bold gold exclamation mark in the button's top-left corner, so you can tell a quest you can pick up from an ordinary item at a glance.
- **EUI**, a new module: precise, numeric control over EllesmereUI's frame positions.
  Installing it changes nothing — it records where your frames already are and moves none
  of them until you edit something. It also offers attachments EllesmereUI cannot express,
  resolving those itself. EllesmereUI is required.
- **The suite's slash commands are now owned by BitForge itself.** `/bitforge <module>` opens or acts on a module, in place of the separate command each module used to install for itself. `/bitforge` on its own prints the modules you have installed, so the list cannot go stale the way a written-down one does. A module name shortens to any unambiguous prefix, making `/bitforge b` and `/bitforge batchsell` the same command, and asking a module for something it does not offer says so instead of doing nothing.
- **A close button that matches the window it sits on.** Openables, RepRank, UPS and both of TaskTome's windows now draw their X in BitForge's own colours instead of wearing Blizzard's red one, and it lights up under the pointer. EUI's editor deliberately keeps EllesmereUI's, since that window is a guest in EllesmereUI's layout and should look like the rest of it.
- **BatchSell can show you why.** A new Rules window lists every criterion it judges an item by, in the order it checks them, with a plain-English explanation of each — from the Rules button at the vendor, or from BatchSell's settings. Every criterion that has anything to set is now set from the window itself, each control explaining what it does when you point at it: whether poor quality items sell, how gear is compared with what you are wearing, and the rules for crafting reagents, uncollected appearances, gems, enhancements, recipes, mounts and pets, and housing. Which of your professions spares a trade good is set here too, from a list you tick. Consumables get a row each, with their options behind it. A setting that only matters while another is on greys out until it is, and changing anything at a vendor updates the sell list straight away. The pane scrolls when a criterion has more to say than fits. The manifest also tells you what to do when something you expected to sell is not listed: hover it in your bags and the tooltip names the rule that kept it.

### Changed

- **BatchSell:** the menu on an item in the sell list now shows what that item is already set to. It has a Character section and a Warband section, each offering Blacklisted, Whitelisted and None, so a warband entry being overridden on this character is finally visible — the old menu offered four ways to set a status and no way to see which was set. Clearing one scope leaves the other standing: *Clear Character Override* is now Character → None, and *Remove From List* is None in both.
- **BatchSell judges recipes straight away now.** A recipe used to be left alone until you had opened that profession's window at least once; it is judged from the item itself from now on, so "keep what I can still learn" and "keep what is still tradeable" apply on your first visit to a vendor. A recipe that belongs to no one profession — a generic pattern or manual — is still left alone, since there is nothing to judge it against.
- **The crafting-reagent catalogue is now read from the game itself rather than from a website.** It covers 2,833 reagents across the ten professions that have recipes, up from 2,200, and for the first time it carries the optional reagents a recipe accepts and every quality tier of a reagent instead of only the first. Fewer materials will be offered for sale because BitForge had never heard of them. It also asks nothing of you: opening each of your profession windows used to be how the list filled itself in, and there is no longer anything to fill in — what ships is the whole of it, and reagents a later patch adds wait for the next update rather than for you.
- **BatchSell** now decides by the kind of item. Every kind has its own rule — consumables, gems, trade goods, recipes, companion pets and mounts, housing decor, gear — instead of everything being sorted into equipment, materials or other and the last two sharing one keep-or-sell setting. A kind with no rule of its own is never examined, so quest items, keys, glyphs and anything else BatchSell does not understand stay in your bags no matter how the rest is set. Crafting materials and consumables are affected most: they used to answer to a single expansion-age setting, and now each kind answers for itself.
- **BatchSell** never sells on something it could not read. If the game has not finished loading an item's details, or has not told BatchSell what you have equipped, or what your character's class is, the item is kept rather than judged on a blank. This mattered most right after logging in or reloading at a vendor. The same goes for the reagent list: a trade good, consumable or gem that BatchSell's list has no entry for is kept rather than sold, since not knowing whether a profession wants it is not the same as knowing none does. Expect fewer trade goods to sell than before, especially just after a patch adds new ones.
- **BatchSell** settings are now shared across your warband instead of being set per character, and **your existing settings are reset once** when you first log in after this update. They could not be carried over: there was no way to tell which character's settings should become everyone's. The batch limit stays on, so a first sell after the update is still capped.
- **BatchSell:** two defaults changed. Selling poor quality items is now off, since another addon usually handles it — turn it back on if nothing else does. Keeping gear worth disenchanting is now on.
- **BatchSell spares unbound Bind on Equip gear by default.** A new **Spare Bind on Equip Gear** dropdown sits beside the Bind on Account one and ships on Current Expansion, so a current-expansion piece you have never worn is kept for an alt or the auction house even when it loses the comparison. **Expect some gear you used to see vendored to stay in your bags.** Set it to All to keep older Bind on Equip gear too, or None to have it judged like anything else.
- **BatchSell:** every per-kind rule is now yours to set, in the Rules window. Consumables are the finest-grained of them: potions, elixirs, flasks and phials, food and drink, bandages, vantus runes and the rest each get their own answer, and the four that can be levelled through offer to keep last expansion's as well. The defaults are unchanged, so nothing starts selling that was not selling before.
- **BatchSell's settings panel no longer holds any rule.** Sell Junk, Keep Reagents Your Professions Use and the seven gear settings have moved into the Rules window, where the other forty-five already were. What is left in the Blizzard settings panel is the batch limit, the four list resets, and the button that opens the window. If you knew where those nine were, they are one button away now — and there is no longer a second place a rule can be set from.
- **BatchSell** ships those new rules on defaults you can change: a housing dye you could still trade or sell is kept and one bound to you is sold; housing decor and battle pets are kept; and a mount is kept unless it is bound to you and you have already collected it.
- **BatchSell** explains a sold relic properly. The verdict read "Relics are sold", which said nothing about *why* and used the same word as the artifact relics it keeps. It now says nothing can equip a relic any more — idols, librams, totems and sigils belong to a slot the game removed. All eleven languages; nothing behaves differently.

### Removed

- `/bfodump`, `/bfsdump` and `/bfsde` are gone.
- **BatchSell:** the **Sell Equipment** checkbox is gone, and so are the **Crafting Materials** and **Consumables & Other** sections along with their keep-or-sell dropdowns — every kind of item now answers for itself instead. If you used Sell Equipment to keep all your gear, turn off both **Compare Quality** and **Compare Item Level**: nothing your class can equip is vendored then. Gear your class cannot use is still judged, and what keeps it is the Spare Bind on Account, Spare Bind on Equip and Keep Disenchantable Gear settings underneath.

### Fixed

- **BatchSell** no longer sells a cosmetic whose appearance you have not collected. Selling one does *not* collect it — the appearance is simply gone — and the check that was meant to prevent this only ever looked at armor filed under the Cosmetic subclass. Cosmetic weapons are filed as ordinary weapons, so a cosmetic bow or polearm was judged on its item level like any other and vendored. The question is now asked of every item whatever its class, and an item whose appearance state cannot be read is kept rather than risked.
- **BatchSell** compares bows, guns, crossbows and wands against the weapon you are actually holding. They were being weighed against the ranged slot, which the game removed years ago and which is empty on every character — so they never lost the comparison and were never sold, however far behind they had fallen. **Expect outgrown ranged weapons to start selling.**
- **BatchSell** no longer keeps a soulbound crafting reagent because an *alt* has the profession that wants it. A bound copy can never reach that alt, so the account-wide answer was the wrong one to ask; it now asks about the character actually holding it. **Expect some bound reagents to start selling** — they were being kept for a character who could never receive them.
- **Openables** moves to the next item even when using one fails. The button only advanced when the item was actually consumed, so a use the game refused — out of range, wrong zone, on cooldown — left you clicking the same item. It now moves on regardless, and the item is not dropped: it goes to the back and comes round again.
- **Openables** no longer offers profession tools you use out in the world, like the Elusive Creature Lure or a skinning bait on a twelve hour cooldown. They arrive looking exactly like something to open — a plain "Use:" line and nothing else — and the only thing separating them is a profession requirement you meet. They used to sit above every genuine learnable in the button's order; now they are not offered at all.
- **BatchSell** no longer keeps gear nobody can ever disenchant. With Keep Disenchantable Gear on, a piece was spared whenever the game would accept it for a disenchant — but a piece you have worn is bound to you, and if you are not an enchanter there is no one it can reach. Those pieces stayed in your bags for good, and on a levelling character that is most of what you outgrow. BatchSell now asks who could actually receive the item: you, if you have the profession; an alt, if it is Warbound; or a buyer, if you have not bound it yet. **Expect levelling gear you outgrew to start selling again** — it was never doing anything for you.
- **BatchSell** now recognises Warbound gear. It was reading the wrong bind type — the one the game uses for quest items — so gear bound to your warband was never seen as account-bound and could be sold whatever you had set. What spares it is the **Spare Bind on Account Gear** dropdown, which offers All, Current Expansion and None and ships on Current Expansion: at that setting this expansion's Warbound gear is kept and a past expansion's is not, and All keeps every piece. Enchanters lost the same gear from **Keep Disenchantable Gear** for the same reason.
- **BatchSell** no longer sells gear that beats what you are wearing, when what you are wearing is last expansion's. Quality counted for a fixed number of item levels whatever its age, so a levelling character in last expansion's epic had this expansion's upgrades vendored for being a tier below it. A piece from a finished expansion now sets its bar on item level alone — no margin, no quality discount. Gear scaled by Timewalking is exempt, since its item level is already current.
- **BatchSell** never sells anything above epic quality. Legendary, artifact and heirloom items were judged like any other gear, so an outgrown legendary was vendored for being behind on item level — and the game reports a sale price for these and then refuses the sale, so one that reached the list quietly used up a slot in the batch and sold nothing. The game will not complete the sale whatever BatchSell does, so there is no setting and no list that makes one happen.
- **BatchSell** no longer sells cloaks, shirts or tabards as gear your class cannot equip. Every class wears all three, but the game files them under cloth, so on anything but a cloth wearer they were being judged as off-class gear and vendored.
- **BatchSell** no longer treats one-handed weapons as gear a hunter wants. No hunter specialization uses one — Beast Mastery and Marksmanship are ranged, Survival is two-handed — so a one-hander picked up while levelling is no longer weighed against what you have equipped. It is not vendored on the spot either: it still faces the bind and disenchant questions, and is kept if it is Warbound, Bind on Equip or worth disenchanting.
- **Openables:** the button updates as soon as you pick something up. It could previously sit on the wrong item, or show nothing at all, until an unrelated bag change happened to refresh it — the item's tooltip had not finished loading when the button first looked at it, and nothing told it when it had.
- **Openables** no longer offers profession knowledge items you cannot study yet. A requirement like "Requires Dragon Isles Mining (25)" was treated as met by knowing the profession at all, so an item that needs rank 25 showed up at rank 1.
- **Openables** stops hiding profession knowledge items you *can* study. The button sizes an item up along one of two paths, and only one of them was reading the item's profession requirement — so on the other path a knowledge item you were entitled to use looked like an ordinary firecracker and was dropped from the button entirely, while a profession-gated lure lost the requirement that would have turned it away and was offered in its place. Both paths now read the same evidence.
- **Openables** now counts housing decor, dyes and room customizations as learnables, so they are offered ahead of items you merely use rather than last.
- **Openables** holds back Focused Life Essence until you carry the five it needs to combine, and no longer offers Superior Loyal Spirit, which does nothing away from its Queen's Conservatory node.
- **RepRank:** the **Show factions with no progress** toggle now shows its state after you click it. It changed the list correctly but kept the appearance it was built with, so it read as unchanged.
- **Openables:** blacklisted items show their names again. A row in the blacklist window read `Unknown item (194829)` and stayed that way for the rest of the session — the window asked the game for the name, but nothing was listening for the answer when it came back. Rows only ever looked right for items still sitting in your bags, which is rarely what is on a blacklist.

## [v12.1.0.6] — 2026-08-23

### Added

- **RepRank:** every faction now carries a progress bar showing how far the leading character is through their current step, so you can see who is close to the next rank rather than only which rank they have reached. The bar is coloured by what kind of progress it is — the game's own standing colours for ordinary reputations, green for friendships, the accent colour for renown, and purple for paragon — and hovering it gives you the exact figures. A faction in paragon shows its paragon progress rather than a permanently full bar. A faction with nothing left to earn shows a full bar and no figures, and one the game has not sent numbers for shows an empty bar rather than a made-up total. The window is wider to make room for the column.

### Changed

- **RepRank:** character names are shown in class colours — in the window's Best column, in the tooltip listing who has a paragon reward waiting, and in the paragon alerts printed to chat. A character is coloured from the next time you log in on it; until then it looks exactly as it does today.

## [v12.1.0.5] — 2026-08-23

### Added

- **RepRank**, a new module: it records each character's reputations as you play them and
  shows who is furthest along with every faction, warband-wide reputations listed apart
  from the ones that differ per character. It also tells you when any character has a
  paragon reward waiting — in chat and as a pop-up when one becomes claimable, and again
  at each login while it is still unclaimed.
- BitForge windows are painted in **EllesmereUI**'s theme when you have it installed, following your accent colour and style settings. Nothing to configure; EllesmereUI's own per-addon skinning toggle controls it. The BatchSell merchant window is the first to use it.

### Changed

- **BatchSell** now asks three questions about a piece of gear, in order: is it good for me, is it good for one of my alts, is it worth disenchanting? Only gear that fails all three is sold. Previously the comparison against your equipped item had the last word, so a piece it rejected was vendored before the heirloom and disenchanting rules were consulted at all. Off-class gear goes through the same three questions now — a weapon your class cannot use but that binds to the account is kept for the character who can.
- **BatchSell:** the three "apply margin to higher / equal / lower quality" checkboxes are replaced by one margin that covers every case. It is now what a quality tier is worth in item levels: at the default of 10, gear a tier below what you have equipped has to beat it by 10 to be kept, and a tier above survives 10 under it. At your own quality a piece has to beat the slot outright. Set it to 0 to ignore quality altogether. The slider runs 0 to 30 in steps of 2 and reads as a plain count of item levels rather than the negative number it used to be. The old checkboxes could contradict each other, so an uncommon could outlive the rare sitting next to it at the same item level; gear is judged consistently now, and more item level or more quality can only ever help a piece survive. The trade-off is that a large quality drop is no longer excused by a small item level gain — a 139 uncommon no longer survives an equipped 134 epic, because two tiers down has to beat it by 20 at the default margin. It is still offered to the heirloom and disenchanting rules before anything sells it. **Your existing margin is reset to the new default.**
- **BatchSell** has a new "Emphasize Quality" option, off by default. It counts a quality tier for twice the margin and lets a piece of your own quality sit that margin below the slot — so quality above what you wear gets cheaper to keep, and quality below it dearer to excuse.
- **BatchSell** no longer sells gear for a slot you have nothing equipped in. There is nothing for it to be worse than, so it is kept — levelling gear for an empty slot is not junk.
- **BatchSell:** with "Sell Equipment" turned off, gear tooltips now say what the piece is actually worth — "good enough against what you have equipped", "kept for the character who can use it", "worth disenchanting" — instead of the same "this kind of item is set to be kept" on everything. Gear that would have been vendored still names the setting as what saved it. Nothing is sold that was not sold before.
- **Openables** now surfaces profession knowledge items — the ones that read "Study to increase your <Profession> Knowledge" — for the professions your character actually has. They are ordinary Miscellaneous items with a plain Use: line, indistinguishable by class from the junk the button deliberately ignores, so they were being skipped. What tells them apart is that they are gated on a trade skill, which nothing you would want ignored ever is.
- **Openables** shows what you can learn from first — recipes, toys, appearances, profession knowledge — then tokens, then caches and lockboxes, then quest items, and last of all anything that is merely usable. The order used to run the other way. A recipe is permanent and easy to forget you are carrying, while a cache keeps until you open it and a quest item is already held on the button by its own gate. An item whose tooltip only says it does something — with nothing to learn from it — now sits below all of them; it used to share the top place with recipes, and could take the button from a cache, a token or a quest item.
- **BatchSell** learns which items can really be disenchanted, instead of trusting only its built-in list. Whenever you put Disenchant on the cursor, the game marks every item in your bags as disenchantable or not; BatchSell reads those marks and remembers them warband-wide. An item the built-in list had wrong stops being judged on it, in either direction — gear that turns out not to be disenchantable is no longer kept for that reason, and gear that turns out to be is no longer sold for the lack of it. Nothing to switch on, no extra clicks, and it only ever reads what the game has already said. Non-enchanters are unaffected.
- **BatchSell:** the sell window now matches the merchant window's width, and its three tabs sit below it rather than above.
- **BatchSell:** "Your class cannot equip this" now reads "Not equippable or not recommended for your class" — the rule also covers armor your class can technically wear but is not meant to.
- **TaskTome:** the buttons along the top of the tracker window explain themselves. Hovering the gear or the padlock now describes what a click will do, and both light up under the pointer like the two beside them — the gear is how you open the configuration window from the tracker, and there was nothing to suggest it. Opening it from the Settings panel still works.
- **TaskTome:** character names in the tracker are shown in class colours, so a roster of alts is readable at a glance. A character is coloured from the next time you log in on it; until then it looks exactly as it does today.

### Fixed

- **Openables:** Aqir Relic Fragment is held back until you are carrying six of them. Its tooltip offers a use at any stack size, but the effect combines six, so a click below that did nothing.
- **Openables:** the click instructions on the button's tooltip no longer go missing on the first hover after a login or reload. The tooltip rebuilds itself once the item's data finishes loading, and the instructions were being dropped in that rebuild — which is why moving the mouse away and back brought them back.
- **BatchSell:** gear your class cannot wear is no longer described as outclassed by what you have equipped. A hunter's tooltip on a one-handed mace said the mace was worse than the weapon in hand, when the real reason was simply that a hunter cannot hold one. It still sells; the tooltip now says why.
- **BatchSell:** turning "Sell Junk" off now leaves poor quality items alone completely. It only ever stopped BatchSell from using the vendor's own Sell All Junk button — the greys were still judged by the usual rules and sold anyway, which defeated the point of handing them to another addon.
- **BatchSell:** the sell list is no longer empty when you reopen a vendor. Closing and immediately reopening showed nothing until you pressed Refresh, on every visit after the first had cleared your junk.
- **TaskTome:** the tracker window can be moved. Unlocking it with the padlock did nothing at all — the window never took mouse input, so the drag it was listening for could never begin. Locking it still pins it in place.
- **TaskTome:** the tracker window has a close button. Until now the only way to put it away was the minimap icon.

## [v12.1.0.4] — 2026-08-22

### Added

- **BatchSell** now keeps crafting reagents that a profession on one of your characters actually uses, instead of judging them on expansion age alone. On by default — turn off "Keep Reagents Your Professions Use" for the old behaviour.
- **UPS** now deposits only the reagents your professions can craft with. Turn off "Only deposit reagents you can use" to send everything to the Warband Bank for the auction house, as before.

### Changed

- Your characters' professions are remembered by BitForge itself now rather than by UPS, so BatchSell can use them too. Nothing to do — whatever UPS already recorded is carried over.

### Fixed

- **BatchSell:** the list of items that cannot be disenchanted was badly incomplete — about 2,000 entries where the real figure is over 15,000. Shirts, tabards, rings, trinkets, cloaks and every cosmetic item were missing entirely, so BatchSell treated them as disenchantable and offered them for sale on that basis. All of them are now recognised.

## [v12.1.0.3] — 2026-08-21

### Added

- **BatchSell** — your blacklist and whitelist are now readable from the merchant window.
  The sell list gained tabs, so you can see everything on each list, remove entries one at
  a time, and watch the sell list re-decide immediately. Previously the lists were
  write-only: you could add an item but the only way back was resetting a whole list.
- **BatchSell** — drag an item from your bags onto the sell list to sell it on this visit
  only. It is forgotten when you close the merchant, and it never overrides your
  blacklist, an equipment set, a locked item, or something no vendor will buy — if you drag
  one of those, it tells you why in chat. Dragging in something you had temporarily
  excluded simply changes your mind back.
- **BatchSell** — item tooltips at a vendor now tell you whether the item will be sold or
  kept, and which rule decided it.

### Changed

- **BatchSell** — a substantial rework of what gets sold. Nothing is vendored now unless a
  rule specifically selects it, where previously anything no rule protected was fair game.
  Gear is judged against what you are actually wearing in that slot rather than against
  typed-in numbers: the item level margin and the quality thresholds are gone, replaced by
  a margin you can apply separately to gear of higher, equal, or lower quality than your
  own. Crafting materials and consumables each gained their own setting — keep everything,
  keep the current expansion, keep from an expansion you choose, or sell it all.
  **Please review your settings before your next vendor trip.** The old "Keep Equippable"
  option, the quality threshold, and the past-expansion toggles no longer exist, and your
  saved values for them are cleared automatically.
- **BatchSell** — the settings panel is grouped into collapsible sections — General,
  Equipment, Crafting Materials, Consumables & Other, and Lists — instead of one long list.

### Fixed

- **BitForge** — the minimap button reacts to being pressed again. Holding it down was
  meant to zoom the icon in slightly as an acknowledgement, but the effect never appeared
  and raised an error every time instead.

## [v12.1.0.2] — 2026-08-18

### Added

- **TaskTome** — the widget can show every character on your account, not just the one you
  are playing. One header button switches between "this character" and "all characters",
  and a second flips the layout: group by character to see who still owes what, or group
  by task to see who has already done it. Every collapsible header carries a done/total
  count. The all-characters view is read-only — you still tick chores off on the character
  that owes them.
- **TaskTome** — the config panel gained a character selector, so you can opt an alt in or
  out of a chore without logging that character in.
- **TaskTome** — the widget can be resized by dragging its bottom-right corner, and
  remembers the size.
- **BitForge** — the minimap button can be dragged anywhere around the minimap ring, and
  it remembers where you left it for every character on the account.
- **BitForge** — BitForge now has an entry in the minimap's addon compartment, so the menu
  can be opened from there as well as from the button itself.

### Changed

- **TaskTome** — **your existing Task Tome data is cleared once, the first time you log in
  after this update.** Tasks, completions and per-character assignments all reset, and a
  message explains what is about to happen before anything is deleted. Where this
  information is stored had to change so that one character can see and correct another's,
  and carrying the old data across would have produced a list that looked right without
  being trustworthy.
- **TaskTome** — two confusingly similar config labels renamed. "Warband Task" is now
  "Assigned to all characters", and the "Warband" completion scope is now "Shared — one
  completion for the account". They control genuinely different things: who is expected to
  do a chore, and whether one character doing it counts for everybody.
- **Openables** — **your Openables settings reset once, the first time you log in after
  this update.** The button position, its size, the blacklist and the count and cooldown
  toggles all return to their defaults. Openables was saving under a different name from
  every other module, and correcting that leaves the old entry behind. Nothing else is
  affected, and it happens only this once.
- **BitForge** — the minimap button now sits out on the minimap ring and follows the
  minimap's size, instead of a fixed distance from the centre. It keeps the angle it was
  already at, so it stays in the same direction but moves outward — from inside the map
  onto its edge.
- **BitForge** — the shared BitForge text, such as the minimap button's tooltip, is now
  translated into every supported language rather than only English.

### Fixed

- **TaskTome** — daily and weekly chores now reset for every character, not only the one
  you happened to be playing when the reset came round. An alt logged out across a reset
  used to keep yesterday's ticks indefinitely; it is now corrected the next time any of
  your characters logs in.

## [v12.1.0.1] — 2026-08-17

### Added

- **Openables** — new optional module. A single secure button surfacing the next openable
  or usable item in your bags, with session skip, account-wide blacklist, cooldown and
  stack count display, and Rogue/Mechagnome lockbox picking. Ported from the abandoned
  New Openables addon; item detection now uses typed tooltip line data rather than text
  and colour scraping.
- **UPS** — rebuilt as a Warband Bank deposit assistant. Deposits reagents, recipes an alt
  still needs, and anything you curate by hand. A confirmation window lists every move
  before anything is sent, and a curation window lets you set a destination per item —
  including keeping it in your own bank. Alt inventories are read from your own characters
  and from Syndicator, DataStore, BagSync or BagBrother when installed.

### Changed

- **Openables** — far fewer items that cannot actually be opened now reach the button.
  Buff food, potions, keys, enchanting scrolls, holiday trinkets, on-use trinkets and
  quest leftovers are filtered out, while caches, tokens, recipes and toys still appear.
  Items that only work once several have stacked up stay hidden until you carry enough,
  counted across all your bags. Quest starters are recognised whatever kind of item they
  are, and disappear once the quest is taken or completed.
- **Openables** — the button now requires **Alt + drag** to move, so a stray click no
  longer drags it out from under the cursor.
- **BatchSell** — the per-item blacklist and whitelist are now mutually exclusive; adding
  an item to one removes it from the other.

### Fixed

- **All modules** — a moved frame no longer returns to its default position after you log
  out and back in. Any setting stored as a group of related values could lose part of
  itself on logout; this affected the Openables button's position most visibly.
- **Openables** — the tooltip now updates as soon as the button changes item. Previously
  it kept describing the previous item until you moved the mouse away and back.
- **Openables** — fixed a white square flashing on the button between items.
- **Openables** — the Garrison and Dalaran hearthstones are offered again so their toys can
  be learned, and the plain Hearthstone stays hidden.
- **TaskTome** — reset times now come from the client, so daily and weekly tasks clear when
  the game says they do rather than on a stored estimate.
- **AutoBalance** — no longer risks depositing or withdrawing twice when you approach a
  bank repeatedly in quick succession.
- **Packaging** — `.pkgmeta` was missing a `move-folders` entry for `BitForge_UPS`.

## [v12.0.5.19] — 2026-08-13

### Removed

- **ActionBars, Basics, Chat, ClassBars, DamageMeters, Session, Skins, Toasts, Trackers, UnitFrame** — modules removed from the suite.
- **BitForge** — dropped the embedded oUF library and the `BitForge_ClassPanel` anchor frame (`APIs/ClassPanelAnchor.lua`); both existed solely to support the removed ClassBars/UnitFrame modules.

## [v12.0.5.18] — 2026-05-10

### Added

- **Toasts** — new optional module. Provides a unified toast system for loot, collection, transmog, achievement, and cross-module system messages with queueing, stacking, animation, quality-aware styling, and Blizzard-toast replacement controls.

### Changed

- **Basics** — custom loot toasts, boss banner suppression, and Azerite power toast suppression moved to the new **Toasts** module. Install BitForge_Toasts to use these features.

## [v12.0.5.17] — 2026-05-08

### Changed

- **DamageMeters** — now powered by the Blizzard native combat log parser; display is more stable and compatible with WoW 12.0.5 protected API restrictions.

### Fixed

- **ClassBars** — macro assist slot highlights now appear correctly; fixed a stacking order issue with the class bar panel.
- **Skins, Chat, Trackers** — visual consistency pass; skin seams and edge cases are more reliably hidden across these frames.

## [v12.0.5.16] — 2026-05-08

### Fixed

- **Chat and Trackers** — cleaned up remaining Blizzard skin seams, hid default scrollbars and textures more reliably, and tightened backdrop spacing so these windows look consistent with the BitForge style.
- **ClassBars** — fixed ClassPanel anchoring and sizing so the class bar area positions more reliably and no longer hits layout issues.
- **DamageMeters and Session** — improved WoW 12.0.5 compatibility so protected Blizzard combat and stat values no longer cause blank or unstable displays.

## [v12.0.5.15] — 2026-05-07

### Added

- **ClassBars** — new optional module. Adds a class resource bar (combo points, Holy Power, Soul Shards, and all other class-specific resources), a secondary resource bar, cooldown tracking for essential and utility spells, and a tracked-buff display. Install BitForge_ClassBars to get these features.

### Changed

- **UnitFrame** — the ClassPanel (cooldown tracker) has moved to the new **ClassBars** module. Install BitForge_ClassBars to restore that functionality.

### Fixed

- **Chat** — fixed an issue where the chat scroll position behaved incorrectly.

## [v12.0.5.14] — 2026-05-06

### Fixed

- **All modules** — fixed a startup crash that could occur on a fresh install due to an uninitialized locale table.
- **Skins** — resolved tooltip backdrop errors that appeared in the WoW error log on login.

## [v12.0.5.13] — 2026-05-06

### Added

- **Chat** — new dedicated chat module. Reskins chat frames and tabs, adds a slim sidebar showing your online friend count, detects URLs in chat and shows a click-to-copy popup, fades chat out after a configurable period of inactivity, and styles the input box with focus effects and a toggleable position. Includes a thin custom scrollbar. Install BitForge_Chat to get these features.

### Changed

- **Basics** — chat skinning and auto channel-setup have moved to the new **Chat** module. Install BitForge_Chat to restore that functionality.

### Fixed

- **Session** — the rested XP bar is now fully visible at all fill levels.
- **Basics — Tooltips** — resolved compatibility warnings for WoW 12.0+ tooltip API.

## [v12.0.5.11] — 2026-05-05

### Added

- **Basics — Tooltip IDs** — Tooltips can now optionally display the underlying game IDs for items, spells, NPCs/units, and icons. Each category is independently toggled in Settings → Basics → Tooltips. Helpful for addon developers and players cross-referencing Wowhead or external tools.

## [v12.0.5.10] — 2026-05-05

### Added

- **Skins** — new optional module that reskins core Blizzard frames to match the BitForge aesthetic: Character Sheet, Inspect Sheet, tooltips, the Game Menu, and confirmation dialogs.
- **Skins — Skyriding HUD** — a custom Skyriding overlay with a speed bar, vigor pip display, and indicators for Second Wind and Whirling Surge. Requires BitForge_Skins.

### Changed

- **Basics** — character frame tweaks, tooltip enhancements, and the Dragonriding HUD have moved to the new **Skins** module. Install BitForge_Skins to restore that functionality.

## [v12.0.5.9] — 2026-05-04

### Added

- **Basics — Character** — Equipped item slots now show a small dot when the item has gem sockets: orange means one or more sockets are empty, green means all sockets are filled.
- **Basics — Character** — A new Gem Socket Helper panel appears next to the Character Frame listing every gear slot with empty sockets, so you can see at a glance what still needs gems.

### Changed

- **Basics** — Several settings toggles (item filter bar, macros, world map teleport, edit mode button, camera zoom) now take effect immediately when you flip the checkbox, without needing a UI reload.

## [v12.0.5.8] — 2026-05-04

### Added

- **Session** — Crit chance in the stat tracker now reflects your current specialization (spell crit for caster specs, melee crit for physical specs).

### Changed

- **Settings** — All module settings panels now use collapsible sections, making it easier to find and navigate to individual features.
- **Basics — Chat** — Changing the chat skin or input-box position now shows a confirmation prompt to reload WoW instead of silently requiring one.

## [v12.0.5.7] — 2026-04-27

### Added

- **ActionBars** — Action buttons now show colored square glow borders: green for equipped items, gold for proc alerts, and cyan for rotation assistant highlights. Each border pulses to draw attention.

### Changed

- **DamageMeters** — The meter window can now be resized when unlocked, in addition to being dragged.

## [v12.0.5.6] — 2026-04-26

### Added

- **Keystone** — new module for Mythic+ players. Adds a live in-run overlay showing force %, death count and time lost, and a countdown timer with two- and three-chest cutoffs. Records split times at each force milestone for run-over-run comparison. Detects crowd-control resses mid-pull and fires a raid warning. Auto-gossips with the dungeon-start NPC. Shows party keystones without opening the Group Finder. Configure everything under Settings → Keystone.

### Changed

- **Basics** — the Mythic+ chest timer is now part of the Keystone module. Enable BitForge_Keystone to get chest-timer functionality.
- All modules now display their names with the BitForge gold/copper colour scheme in the WoW addon list.

### Fixed

- **Keystone** — death count and time lost are now read from Blizzard's Mythic+ API directly, giving accurate totals for the full run on Midnight+.
- **Basics — Bags** — item-level labels on bag slots no longer error after the Midnight container API changes.
- **DamageMeters** — per-character stat history is now stored separately for each character; fixed a startup error and a button-creation error.

## [v12.0.5.5] — 2026-04-25

### Added

- **DamageMeters** — new module that tracks and displays damage and healing output for your group in real time. Shows up to three independently toggleable panes. Panes can be arranged horizontally or vertically, dragged anywhere on screen, and reset or configured individually from the per-pane gear menu. Open Settings → DamageMeters to customize orientation and pane layout.

### Fixed

- **Basics — Known Items**: fixed a nil error when scanning a guild bank tab and corrected the variable used for pet species detection.

## [v12.0.5.4] — 2026-04-23

### Added

- **Basics — Known Items**: Items in the Auction House are now highlighted if your character already knows them (transmogs, recipes, mounts, pets, and other collectibles). Makes it easy to spot new appearances and skip duplicates while browsing.

## [v12.0.5.3] — 2026-04-23

### Added

- All eight modules now ship with full translations for German, Spanish (Spain), Spanish (Latin America), French, Italian, Brazilian Portuguese, Russian, Simplified Chinese, and Traditional Chinese. Previously only English and Korean were available.

## [v12.0.5.2] — 2026-04-23

### Added

- **Basics — Crosshair**: On-screen crosshair overlay follows the cursor; four styles (full cross, broken with a gap around the cursor, T-shape, diagonal); optional outline and center dot; optional red recolor when your target is within melee range.
- **Basics — Mouse Ring**: A ring drawn around the cursor shows your GCD and cast-bar progress as a swipe animation. Configurable size, separate in-combat and out-of-combat opacity, and a "GCD only" mode that hides the ring when no global cooldown is active.
- **Basics — Custom Loot Toasts**: Slim custom toasts replace the default loot notification. Filter by item level per rarity (uncommon, rare, epic, legendary), automatically include mounts and pets, maintain an item-ID whitelist, and optionally play a custom sound on each drop.
- **Basics — Boss Banner**: Option to suppress the boss-kill banner after defeating a boss.
- **Basics — Azerite Power Toast**: Option to suppress the Azerite power level-up toast.
- **Basics — Instant Catalyst**: Option to skip the confirmation step when upgrading gear at the Catalyst — the upgrade applies immediately on click.
- **Basics — Override Key for Quest Automation**: Designate a modifier key (Ctrl/Alt/Shift) that, when held, pauses auto-accept and auto-turn-in so you can read quests normally.

### Changed

- **Session**: Removed the title bar from the session overlay frame for a cleaner look.

## [v12.0.5.1] — 2026-04-22

### Changed

- Updated for WoW patch 12.0.5.
- **Basics — Chat**: Auto chat-window setup now tracks completion per character, so switching to an alt no longer re-runs the setup if it already ran on that character.

# BitForge

A modular World of Warcraft addon suite for WoW 12.0+ (Midnight). Each module is independent — enable only what you need. The **BitForge** core addon is required by all modules.

> **AI disclosure:** BitForge is developed with heavy AI assistance. Much of the code,
> localization, and documentation in this repository was written with Claude. Bug reports
> and corrections are very welcome.

---

## Compatibility

| Field           | Value                                                    |
| --------------- | -------------------------------------------------------- |
| WoW version     | 12+ (Midnight)                                        |
| Retail only     | Yes                                                      |
| Saved variables | `BitForgeDB` (core only — no per-module saved variables) |
| Optional        | [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI) — BitForge windows adopt its theme when it is installed, and the EUI module requires it |

---

## Modules

### BitForge _(core — required)_

Shared infrastructure: event bus, account/character database, settings panel integration, minimap button, and the BitForge UI widget library.

It also owns the two windows a player meets that belong to no one module. The first is the report window: when BatchSell or Openables judges an item and you disagree, the item's own menu opens a window holding everything it was judged by, already selected, with the address to paste it into and a plain statement of what the report discloses. The second appears once after an update, listing what changed since the version you last played; `/bitforge core whatsnew` opens it again.

The suite's two slash commands live here: `/bitforge <module>` opens or acts on a module, and `/bfdump <module>` opens a window holding the diagnostic record for that module, selected and ready to copy — nothing is written to your saved variables and no reload is involved, and each one says what it discloses before you send it. A record too long to be worth reading is compressed to a single line you paste exactly as it is. Not every module answers both, and some answer neither — `/bitforge` on its own lists what you have installed and which of the two each one takes, core included. A module name shortens to any unambiguous prefix, so `/bfdump b` and `/bfdump batchsell` are the same command.

It also ships a catalogue of which professions use an item as a crafting reagent, which other modules build on. It is read from the game client's own recipe lists, so it carries every reagent a recipe consumes — optional reagents and the higher quality tiers of a reagent included, both of which the old catalogue missed — for all ten professions that have recipes, whether or not any of your characters have them. Herbalism, Skinning, Fishing and Archaeology have no entries at all, because nothing is crafted from them; Mining does, since smelting and prospecting are recipes of its own. It does not update itself and asks nothing of you: recipes added by a later patch are missing until the addon ships a rebuilt catalogue. Anything missing counts as unknown rather than unwanted, so nothing is ever acted on because of a gap.

### BitForge AutoBalance

Automatically deposits and withdraws gold between your bags and the Warband Bank when you visit it, keeping each character at a configurable target balance. Supports a designated collector character that pulls all gold from the warband bank.

### BitForge BatchSell

Automates selling items at vendors. Nothing is sold unless a rule selects it. Every kind of item has its own rule — consumables, gems, trade goods, recipes, pets and mounts, toys, housing decor — and a kind with no rule is never examined at all, so anything BatchSell does not understand stays in your bags. Gear is the longest of them: is it a kind your class uses, does it beat what you are wearing, could an alt still use it, is it worth disenchanting, and only a piece that answers no to all of them is sold. The comparison runs on two dials — a flat item-level tolerance at your own quality, and what one quality tier is worth — so a lower quality piece has to make the difference up in item level and a higher quality one earns a discount worth that many levels rather than a free pass — or, at the quality margin's topmost setting, is kept outright whatever its item level while nothing of lower quality ever is — and a piece from a finished expansion is weighed by exactly the same two dials, with what you are told changing rather than what is decided — the tooltip says you outlived that bar rather than merely beat it. Reagents your professions actually use are kept whatever kind of item they are, and a bound one is weighed against the professions of the character holding it rather than the whole warband's, since nobody else can ever have it; nothing above epic quality is ever sold; and no rule ever sells on a fact the game had not finished answering — an item whose details have not loaded is kept. Bind type and disenchantability are respected throughout: gear you have never worn is spared by default so a copy can still reach an alt or the auction house — this expansion's Bind on Equip and Bind on Account pieces alike, each widenable to every expansion or turned off on its own. Disenchantability corrects itself: each time you raise Disenchant, BatchSell reads the game's own verdict on what is in your bags and remembers it, so its built-in list of exceptions stops being the last word. Settings are shared across your warband. Per-item overrides from the item's own menu, set for this character or for the whole warband and showing which is already set for each; both lists are readable and editable from the merchant window, and the same menu reports an item whose verdict you disagree with. Drag an item in from your bags to sell it on that visit only. Item tooltips say what will happen and why, and a sell manifest shows a live total before confirming. Every rule can be read in plain language, and set, in one window opened from the vendor or from the settings panel — each control saying what it does when you point at it, greying out whenever another setting has already decided the question, and updating the sell list the moment you change it. Nothing about a rule lives anywhere else.

### BitForge EUI

Numeric control over EllesmereUI's frame positions. EllesmereUI moves a frame by
dragging it; this types the numbers in — a position, a size, and an attachment to
another frame, all in one window with the whole layout listed beside it.
Installing it changes nothing: it records where your frames already are and moves
none of them until you edit something.

It also offers attachments EllesmereUI cannot express. EllesmereUI attaches a
frame to one side of another, centred on that side; here any corner or edge can
be pinned to any other, and the pairings EllesmereUI has no way to store are
resolved by the module itself. Anything EllesmereUI *can* express is handed back
to it, so its own dragging, cascading and locking keep working on those.

**EllesmereUI is required for this module, not optional.** It is a hard
dependency: with EllesmereUI missing or disabled, WoW disables this module
outright and shows it greyed out in the addon list. No other BitForge module is
affected.

### BitForge Openables

A single button showing the next openable or usable item in your bags, in that order of
urgency: recipes, profession knowledge, housing decor and other learnables first, then
tokens, then caches and lockboxes, then quest items, and last of all anything that is
merely usable. An item that starts a quest is marked with a bold gold exclamation
mark in the button's top-left corner. Left-click uses the item and moves to the next one
whether or not the use succeeded — a failed use no longer leaves you stuck on the same
item, and nothing is dropped from the queue, so it comes back round. Right-click skips it
for the session, Ctrl+right-click blacklists it permanently, and Shift+Alt+right-click
reports it if you think BitForge has judged it wrongly. Rogues and Mechagnomes get lockbox picking; other characters
only see a lockbox once it is already open. Bindable through the standard Key Bindings
panel.

Derived from [New Openables](https://www.curseforge.com/wow/addons/new-openables) by
PeknaMrcha, continued by srhinos and cont1nuity. MIT licensed.

### BitForge RepRank

Records every character's reputations as you play them, and shows which character is
furthest along with each faction — so the alt closest to that Exalted-only recipe is one
window away instead of one login each. Factions are grouped by expansion, under the same
headings the game's own reputation pane uses. Opened from the BitForge minimap button.

Each faction carries a progress bar for how far that character is through their current
step — a standing, a friendship rank, a renown level, or a paragon bracket — coloured by
which of those it is, with the exact figures on hover. Character names are shown in class
colours, from the next time you log in on each character.

Warband-wide reputations are listed separately, with the single standing every character
shares: there is nothing to rank when they all report the same number. What they do carry
is paragon, which is per character even on an account-wide reputation, so the list marks
which of your characters has a reward chest waiting.

Paragon rewards are announced in chat and as a pop-up when one becomes claimable, and
again at each login for anything still waiting. A character's state is whatever it was
when you last played them, so a chest you claimed on an alt keeps being listed until that
alt logs in again.

### BitForge TaskTome

A Warband chore tracker for daily, weekly, and one-time tasks, with nested sub-tasks and
per-character opt-in/out. The in-game widget is draggable and resizable, and shows either
the character you are playing or every character on the account — grouped by character to
see who still owes what, or by task to see who has already done it, with a done/total
count on each heading.

Chores reset on your realm's own schedule, and an alt that was logged out across a reset
is corrected the next time any of your characters logs in. The config panel — opened from
the gear on the widget, or from the Settings panel — supports drag-and-drop reordering, and
can set another character's assignments without you logging in as them.

### BitForge UPS _(Undermine Parcel Service)_

Deposits your bags into the Warband Bank when you visit a bank — crafting reagents,
recipes an alt still needs, and anything you have curated by hand. By default only
reagents one of your professions can actually craft with are sent; turn that off to
deposit everything, for the auction house. A confirmation window
lists every move before anything is sent, and a curation window lets you set a
destination per item, including keeping something in your own bank instead.

Recipes are judged against what your alts already know. Seeing your other characters at all
takes an inventory addon you have probably already got — **Baganator**, **Altoholic**,
**Bagnon** or **BagSync**. What UPS actually reads is the data library behind each of those
(Syndicator, DataStore, BagBrother, and BagSync itself), so anything else built on one of
them works just as well. There is nothing extra to install and nothing to configure; the
curation window names the source it used. Without any of them, UPS sees only the character
you are playing.

---

## Installation

1. Download or clone this repository.
2. Copy the folders you want into your `World of Warcraft/_retail_/Interface/AddOns/` directory.  
   **BitForge** must always be included.
3. Log in and enable the addons from the character select screen.

```
Interface/AddOns/
  BitForge/
  BitForge_AutoBalance/     ← optional
  BitForge_BatchSell/       ← optional
  BitForge_EUI/             ← optional, requires EllesmereUI
  BitForge_Openables/       ← optional
  BitForge_RepRank/         ← optional
  BitForge_TaskTome/        ← optional
  BitForge_UPS/             ← optional
```

---

## Localization

All modules are fully localized in eleven languages: English (enUS), Korean (koKR), German (deDE), Spanish — Spain (esES), Spanish — Latin America (esMX), French (frFR), Italian (itIT), Brazilian Portuguese (ptBR), Russian (ruRU), Simplified Chinese (zhCN), and Traditional Chinese (zhTW).

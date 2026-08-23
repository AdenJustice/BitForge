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
| Optional        | [EllesmereUI](https://github.com/EllesmereGaming/EllesmereUI) — BitForge windows adopt its theme when it is installed |

---

## Modules

### BitForge _(core — required)_

Shared infrastructure: event bus, account/character database, settings panel integration, minimap button, and the BitForge UI widget library.

It also ships a catalogue of which professions use an item as a crafting reagent, which other modules build on. The catalogue covers every profession, including ones none of your characters have, but it is not exhaustive: some reagents — the optional ones especially, and the higher quality tiers — are missing until you actually open a profession window. Opening each of your professions once fills in the rest for that profession for good. Anything still missing counts as unknown rather than unwanted, so nothing is ever acted on because of a gap.

### BitForge AutoBalance

Automatically deposits and withdraws gold between your bags and the Warband Bank when you visit it, keeping each character at a configurable target balance. Supports a designated collector character that pulls all gold from the warband bank.

### BitForge BatchSell

Automates selling items at vendors. Nothing is sold unless a rule selects it. Gear is put to three questions in order — is it good for you, is it good for an alt, is it worth disenchanting — and only a piece that fails all three is sold. The first compares it against what you have equipped in that slot: a single margin, a flat number of item levels, is what one quality tier is worth, so a lower quality piece has to make the difference up in item level and a higher quality one earns a discount rather than a free pass, with an option to weigh quality twice as heavily; crafting materials and consumables each get their own keep-or-sell mode based on expansion age; reagents your professions actually use are kept regardless; bind type and disenchantability are respected throughout, and disenchantability corrects itself: each time you raise Disenchant, BatchSell reads the game's own verdict on what is in your bags and remembers it, so its built-in list of exceptions stops being the last word. Per-item overrides via right-click blacklist / whitelist, both readable and editable from the merchant window. Drag an item in from your bags to sell it on that visit only. Item tooltips say what will happen and why, and a sell manifest shows a live total before confirming.

### BitForge Openables

A single button showing the next openable or usable item in your bags, in that order of
urgency: recipes, profession knowledge and other learnables first, then tokens, then caches
and lockboxes, then quest items, and last of all anything that is merely usable. Left-click
uses the item, right-click skips it for the session, Ctrl+right-click blacklists it
permanently. Rogues and Mechagnomes get lockbox picking; other characters only see a
lockbox once it is already open. Bindable through the standard Key Bindings panel.

Derived from [New Openables](https://www.curseforge.com/wow/addons/new-openables) by
PeknaMrcha, continued by srhinos and cont1nuity. MIT licensed.

### BitForge RepRank

Records every character's reputations as you play them, and shows which character is
furthest along with each faction — so the alt closest to that Exalted-only recipe is one
window away instead of one login each. Opened from the BitForge minimap button.

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
  BitForge_Openables/       ← optional
  BitForge_RepRank/         ← optional
  BitForge_TaskTome/        ← optional
  BitForge_UPS/             ← optional
```

---

## Localization

All modules are fully localized in eleven languages: English (enUS), Korean (koKR), German (deDE), Spanish — Spain (esES), Spanish — Latin America (esMX), French (frFR), Italian (itIT), Brazilian Portuguese (ptBR), Russian (ruRU), Simplified Chinese (zhCN), and Traditional Chinese (zhTW).

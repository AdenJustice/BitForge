# BitForge

A modular World of Warcraft addon suite for WoW 12.0+ (Midnight). Each module is independent — enable only what you need. The **BitForge** core addon is required by all modules.

---

## Compatibility

| Field           | Value                                                    |
| --------------- | -------------------------------------------------------- |
| WoW version     | 12.0.5 (Midnight)                                        |
| Retail only     | Yes                                                      |
| Saved variables | `BitForgeDB` (core only — no per-module saved variables) |

---

## Modules

### BitForge _(core — required)_

Shared infrastructure: event bus, account/character database, settings panel integration, minimap button, and the BitForge UI widget library.

### BitForge AutoBalance

Automatically deposits and withdraws gold between your bags and the Warband Bank when you visit it, keeping each character at a configurable target balance. Supports a designated collector character that pulls all gold from the warband bank.

### BitForge BatchSell

Automates selling items at vendors. Filters by quality threshold, item level, expansion, equippability, bind type, and disenchantability. Per-item overrides via right-click blacklist / whitelist. Shows a sell manifest with a live total before confirming.

### BitForge Openables

A single button showing the next openable or usable item in your bags — caches, tokens,
recipes, and lockboxes. Left-click uses the item, right-click skips it for the session,
Ctrl+right-click blacklists it permanently. Rogues and Mechagnomes get lockbox picking;
other characters only see a lockbox once it is already open. Bindable through the
standard Key Bindings panel.

Derived from [New Openables](https://www.curseforge.com/wow/addons/new-openables) by
PeknaMrcha, continued by srhinos and cont1nuity. MIT licensed.

### BitForge TaskTome

A Warband chore tracker for daily, weekly, and one-time tasks. Supports per-character opt-in/out, nested sub-tasks, a draggable in-game widget, and a drag-and-drop config panel in WoW Settings.

### BitForge UPS _(Undermine Parcel Service)_

Deposits your bags into the Warband Bank when you visit a bank — crafting reagents,
recipes an alt still needs, and anything you have curated by hand. A confirmation window
lists every move before anything is sent, and a curation window lets you set a
destination per item, including keeping something in your own bank instead.

Recipes are judged against what your alts already know, read from your own characters and
from Syndicator, DataStore, BagSync or BagBrother if you have any of them installed.

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
  BitForge_TaskTome/        ← optional
  BitForge_UPS/             ← optional
```

---

## Localization

All modules are fully localized in eleven languages: English (enUS), Korean (koKR), German (deDE), Spanish — Spain (esES), Spanish — Latin America (esMX), French (frFR), Italian (itIT), Brazilian Portuguese (ptBR), Russian (ruRU), Simplified Chinese (zhCN), and Traditional Chinese (zhTW).

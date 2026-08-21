# Changelog

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

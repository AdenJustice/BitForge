# Changelog

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

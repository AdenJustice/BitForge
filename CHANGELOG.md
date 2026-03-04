# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [12.0.1.6] - 2026-03-05

### Added

- **Alt data management** — you can now set how many days of inactivity before an alt is flagged as inactive. BitForge will notify you on login if any alts exceed your limit.
- **"Purge Invalid Characters"** button in settings — remove leftover addon data from alts you no longer play. A dialog shows each alt and how long ago they were last seen, so you can choose exactly what to clean up.
- Korean translations for all new features.

### Changed

- The character migration and purge dialogs are now scrollable, so they work correctly no matter how many alts you have.
- The minimap button has a new look that matches the standard minimap icon style. Its position is also now correctly saved when you drag it.
- The margin safe zone for Bank Balance is now **on by default** — small gold fluctuations near your target will be ignored automatically.
- Minor display and visual fixes.

## [12.0.1.1] - 2026-03-01

### Added

- Initial public release packaging for `BitForge` core and `BitForge_BankBalance` plugin.
- Bank balance automation module with configurable desired balance and margin ratio settings.
- English (`enUS`) and Korean (`koKR`) locale files for `BitForge_BankBalance`.

### Changed

- Korean localization terminology aligned to official in-game wording (`전투부대`).
- Margin ratio tooltip text clarified for safety-zone behavior (90% to 110% example).

### Fixed

- `SetUseGlobal` now preserves explicit `false` values and defaults only when the input is `nil`.
- Removed temporary debug logging from BankBalance settings callback.

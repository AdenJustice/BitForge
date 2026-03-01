# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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

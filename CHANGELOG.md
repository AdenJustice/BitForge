# Changelog

## [v12.0.1.7] — 2026-03-27

### Changed

- ActionBars: split `Core.lua` into per-bar controllers (`MainBar.lua`, `MultiBar.lua`, `StanceBar.lua`, `PetBar.lua`); `SetupBar` is now a lean dispatcher
- ActionBars: renamed all files to drop redundant addon prefix/layer suffix (`ActionBarsController→Core`, `ActionBarsPagingController→Paging`, etc.)
- ActionBars: apply spec compliance — model alias, min cache, alignment; cache `table.wipe` in Core
- AutoBalance: simplify `AllocateModuleDB` to direct `model.Init` reference
- BatchSell, UPS: remove wipe alignment, minor cache fixes
- CLAUDE.md: add File Naming convention; remove redundant Module Contract boilerplate, trim preamble example

## [Unreleased] — 2026-03-25

### Added

- BitForge_AutoBalance: new module for automated gold balance with settings panel (MVC)
- BitForge_UnitFrame: new oUF-based unit frame module (player, target, focus, party, raid, boss, pet, target-of-target)
- CLAUDE.md: developer reference for architecture, MVC rules, and locale key conventions

### Changed

- Rebuilt BitForge core: replaced monolithic `Core/` and `Shared/` with clean MVC layout (`Models/`, `Controllers/`, `Views/`)
- Refactored BitForge_BatchSell to MVC structure; added koKR locale; updated settings titles and item thresholds
- Standardized locale keys to `"context:camelCaseKey"` convention across all modules
- Added `.vscode/settings.json`; removed stale GitHub workflows, `.pkgmeta`, and CI configuration

### Removed

- BitForge_BankBalance: deprecated module removed

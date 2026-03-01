# BitForge

BitForge is a modular World of Warcraft addon suite.

- **Core addon (`BitForge`)** provides shared systems, settings integration, plugin loading, and common APIs.
- **Plugin addons** (such as `BitForge_BankBalance`) add focused features on top of the core.

## Included Addons

### BitForge (Core)

Core engine for the BitForge suite.

Key responsibilities:

- Shared utility layer (DB, GUI, assets, mixins, APIs)
- Plugin discovery and load-on-demand activation
- Addon settings integration (including per-plugin settings)
- Minimap button to open settings

### BitForge_BankBalance (Plugin)

Automatically balances your bag gold against a target amount using the Warband Bank when you interact with an Account Banker.

Features:

- Configurable desired balance (1k, 5k, 10k, 50k, 100k)
- Optional margin ratio “safe zone” to ignore small fluctuations
- Character-specific or Warband-shared settings
- Localized for `enUS` and `koKR`

## Requirements

- Game version: World of Warcraft Retail (Midnight, 12.0+)
- Not supported on Classic clients (including MoP Classic).
- `BitForge_BankBalance` requires `BitForge`

## Installation

1. Download or clone this repository.
2. Copy both folders into your WoW AddOns directory:
   - `BitForge`
   - `BitForge_BankBalance`
3. Final path should look like:
   - `World of Warcraft/_retail_/Interface/AddOns/BitForge`
   - `World of Warcraft/_retail_/Interface/AddOns/BitForge_BankBalance`
4. Launch the game and ensure both addons are enabled at character selection.

## Usage

1. Open **Settings → AddOns → BitForge**.
2. Enable **BitForge - Bank Balance** plugin if needed.
3. Configure desired balance and margin options under the plugin settings.
4. Visit a Warband bank NPC (Account Banker).
5. The addon will automatically deposit/withdraw to bring your bag gold near your configured target.

## Localization

- English: `enUS`
- Korean: `koKR`

## Versioning

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## Author

AdenJustice (KR)

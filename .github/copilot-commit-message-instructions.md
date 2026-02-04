# BitForge Commit Message Protocol

## 1. Tone & Style

- **Detail Level:** Exhaustive. Do not summarize with "updated files." Explain _what_ changed inside the functions.
  - Exception: Files in `Locales/` folder.
- **Visuals:** Use emojis liberally to categorize change types.
- **Voice:** Professional yet expressive.

## 2. Structure Template

Every message must follow this structure:

### [Emoji] [Module Name] - [Action]

- Brief summary of the high-level goal, possibly in a sentence.

#### 🏗️ Architecture (MVC-I)

- List changes to `Init`, `Model`, `View`, or `Controller`.
- **Note:** Mention if logic was moved to satisfy "Layer Law."

#### ⚡ Performance & Caching

- Detail any new globals cached (e.g., `_ipairs`).
- Mention API optimizations or Ace3 event refinements.

#### 🌐 Localization & Assets

- Simply mention which locales are updated.

#### 🧹 Cleansing & Refactor

- Detail removed variables, sorted functions, or deleted dead code.

## 3. Emoji Mapping (Mandatory)

- 🚀 New Feature / Module
- 🐛 Bug Fix
- ⚡ Performance Tuning
- 🧹 Code Cleansing/Refactor
- 🏗️ Structural/MVC Change
- 🌐 Localization (Locales)
- 📝 Documentation / Meta

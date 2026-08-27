---@class BitForge.BatchSell
---@field view BitForge.BatchSell.View

---@class BitForge.BatchSell
local ns = select(2, ...)

-- The sub-key files publish onto this table but must not widen it, so the
-- fields they add are declared here, on the file that owns the key.
---@class BitForge.BatchSell.View
---@field ruleDescriptors BitForge.BatchSell.View.RuleDescriptors
---@field ruleControls    BitForge.BatchSell.View.RuleControls
---@field ruleWindow      BitForge.BatchSell.View.RuleWindow
---@field merchantPanel   BitForge.BatchSell.View.MerchantPanel
---@field settingsPanel   BitForge.BatchSell.View.SettingsPanel
---@field itemTooltip     BitForge.BatchSell.View.ItemTooltip
local view = ns.view

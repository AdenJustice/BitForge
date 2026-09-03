---@class BitForge.Dispatch
---@field view BitForge.Dispatch.View

---@class BitForge.Dispatch
local ns = select(2, ...)

-- The sub-key files publish onto this table but must not widen it, so the
-- fields they add are declared here, on the file that owns the key.
---@class BitForge.Dispatch.View
---@field button BitForge.Dispatch.View.Button
---@field settingsPanel BitForge.Dispatch.View.SettingsPanel
---@field blacklistFrame BitForge.Dispatch.View.BlacklistFrame
---@field bankButton BitForge.Dispatch.View.BankButton
---@field previewDialog BitForge.Dispatch.View.PreviewDialog
---@field targetDialog BitForge.Dispatch.View.TargetDialog
---@field curationWindow BitForge.Dispatch.View.CurationWindow
---@field itemTooltip BitForge.Dispatch.View.ItemTooltip
---@field recipeMenu BitForge.Dispatch.View.RecipeMenu
---@field merchantPanel BitForge.Dispatch.View.MerchantPanel
---@field ruleWindow BitForge.Dispatch.View.RuleWindow
---@field ruleControls BitForge.Dispatch.View.RuleControls
---@field ruleDescriptors BitForge.Dispatch.View.RuleDescriptors
-- Nilable: a release build ships no debug/lines.lua at all.
---@field debugLines BitForge.Dispatch.View.DebugLines|nil
local view = ns.view

---@class BitForge.AzerothPrime
---@field view BitForge.AzerothPrime.View

---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...

-- The sub-key files publish onto this table but must not widen it, so the
-- fields they add are declared here, on the file that owns the key.
---@class BitForge.AzerothPrime.View
---@field button BitForge.AzerothPrime.View.Button
---@field settingsPanel BitForge.AzerothPrime.View.SettingsPanel
---@field blacklistFrame BitForge.AzerothPrime.View.BlacklistFrame
---@field bankButton BitForge.AzerothPrime.View.BankButton
---@field previewDialog BitForge.AzerothPrime.View.PreviewDialog
---@field targetDialog BitForge.AzerothPrime.View.TargetDialog
---@field curationWindow BitForge.AzerothPrime.View.CurationWindow
---@field itemTooltip BitForge.AzerothPrime.View.ItemTooltip
---@field recipeMenu BitForge.AzerothPrime.View.RecipeMenu
---@field merchantPanel BitForge.AzerothPrime.View.MerchantPanel
---@field ruleWindow BitForge.AzerothPrime.View.RuleWindow
---@field ruleControls BitForge.AzerothPrime.View.RuleControls
---@field ruleDescriptors BitForge.AzerothPrime.View.RuleDescriptors
-- Nilable: a release build ships no debug/lines.lua at all.
---@field debugLines BitForge.AzerothPrime.View.DebugLines|nil
---@field skinBridge BitForge.AzerothPrime.View.SkinBridge
local view = ns.view

-- LibBitForgeUI's NewSkinBridge() carries no return-type annotation of its
-- own (BitForge/Libs/LibBitForgeUI/Skin.lua), so the shape is restated here
-- rather than left unknown.
---@class BitForge.AzerothPrime.View.SkinBridge
---@field OnSkin fun(handler: fun(facade: table))
---@field GetSkin fun(): table|nil
---@field Deliver fun(facade: table)

-- Every window in this module shares one bridge, registered once under the
-- module's own folder name -- EllesmereUI's per-addon toggle is keyed by that
-- name, so a second bridge per window would still share one switch. Windows
-- reach it through view.skinBridge rather than building their own.
view.skinBridge = BitForge.UI.NewSkinBridge()

if EllesmereUI and EllesmereUI.RegisterSkin then
    EllesmereUI.RegisterSkin(ADDON_NAME, view.skinBridge.Deliver)
end

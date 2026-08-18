---@class BitForge.TaskTome
---@field view BitForge.TaskTome.View

---@type string, BitForge.TaskTome
local ADDON_NAME, ns = ...

---@type BitForge.TaskTome.Locale
local locale = ns.locale

-- The sub-key files publish onto this table but must not widen it, so the fields
-- they add are declared here, on the file that owns the key. That keeps their
-- own aliases at ---@type -- consumers rather than owners -- without tripping
-- inject-field on the one assignment each of them makes.
---@class BitForge.TaskTome.View
---@field settingsPanel BitForge.TaskTome.View.SettingsPanel
---@field widget        BitForge.TaskTome.View.Widget
---@field configFrame   BitForge.TaskTome.View.ConfigFrame
local view = ns.view

-- =============================================================================
--  Settings Panel
-- =============================================================================

do
    ---@class BitForge.TaskTome.View.SettingsPanel
    local settingsPanel = {}

    local function OnOpenConfig()
        view.configFrame.Show()
    end

    function settingsPanel.Init()
        local cat = BitForge.Settings.NewSubcategory(ADDON_NAME, locale["settings:taskTomePanel"], locale)
        cat:AddInitializer(CreateSettingsButtonInitializer(
            locale["settings:config"],
            locale["settings:openConfig"],
            OnOpenConfig,
            nil, true
        ))
    end

    view.settingsPanel = settingsPanel
end

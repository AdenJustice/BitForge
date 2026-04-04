---@type BitForge.Core
local ns = select(2, ...)
---@class BitForge.Core.View
local view = ns.view

local ipairs = ipairs

local Settings = Settings

---@param modules { name: string, title: string, enabled: boolean }[]
---@param callbacks table<string, { getValue: fun(), setValue: fun(value: boolean) }>
function view:Register(modules, callbacks)
    local category = Settings.RegisterVerticalLayoutCategory("BitForge")
    Settings.RegisterAddOnCategory(category)
    BitForge.settingsCategory = category

    for _, mod in ipairs(modules) do
        local name, title = mod.name, mod.title
        local cb = callbacks[name]

        local setting = Settings.RegisterProxySetting(
            category, name,
            Settings.VarType.Boolean, title,
            mod.enabled,
            cb.getValue,
            cb.setValue
        )
        Settings.CreateCheckbox(category, setting, title)
    end
end

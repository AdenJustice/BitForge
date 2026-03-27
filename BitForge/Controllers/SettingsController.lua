local _, ns              = ...
local bus                = ns.eventBus
local E                  = BitForge.Events
local SettingsController = {}
ns.SettingsController    = SettingsController

local PREFIX     = "BitForge_"
local PREFIX_LEN = #PREFIX

local function ScanModules()
    local modules = {}
    local count   = C_AddOns.GetNumAddOns()
    for i = 1, count do
        local name, title = C_AddOns.GetAddOnInfo(i)
        if name and name:sub(1, PREFIX_LEN) == PREFIX then
            -- GetAddOnEnableState: 0=disabled, 1=enabled(other char), 2=enabled(this char)
            local state = C_AddOns.GetAddOnEnableState(name, ns.playerName)
            modules[#modules + 1] = {
                name    = name,
                title   = title or name,
                enabled = state == 2,
                loaded  = C_AddOns.IsAddOnLoaded(name),
            }
        end
    end
    ns.ModuleList.SetAll(modules)
end

--- Called when a module checkbox is toggled.
---@param addonName string
---@param enable boolean
function SettingsController.OnToggle(addonName, enable)
    if enable then
        C_AddOns.EnableAddOn(addonName)
        if not C_AddOns.IsAddOnLoaded(addonName) then
            C_AddOns.LoadAddOn(addonName)
        end
        bus:TriggerEvent(E.MODULE_ENABLED, addonName)
    else
        C_AddOns.DisableAddOn(addonName)
        bus:TriggerEvent(E.MODULE_DISABLED, addonName)
    end
end

ns:Subscribe(E.CORE_LOADED, function()
    ScanModules()
    local modules = ns.ModuleList.GetAll()

    local callbacks = {}
    for _, mod in ipairs(modules) do
        local name = mod.name
        callbacks[name] = {
            getValue = function()
                -- GetAddOnEnableState: 0=disabled, 1=enabled(other char), 2=enabled(this char)
                return C_AddOns.GetAddOnEnableState(name, ns.playerName) == 2
            end,
            setValue = function(value)
                SettingsController.OnToggle(name, value)
            end,
        }
    end

    ns.Panel:Register(modules, callbacks)
end)

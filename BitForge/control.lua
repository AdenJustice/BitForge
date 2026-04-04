---@class BitForge.Core
local ns = select(2, ...)
local model = ns.model
local view = ns.view
local enum = ns.enum
local E = BitForge.Events

local C_AddOns = C_AddOns
local EventRegistry = EventRegistry
local ipairs = ipairs
local select = select
local sub = string.sub
local unpack = unpack

-- ================================================================================
-- Event Bus
-- ================================================================================

-- eventBus: modules register their listeners here
local bus = CreateFromMixins(CallbackRegistryMixin)
bus:OnLoad()
bus:SetUndefinedEventsAllowed(true)

local stickyEvents = {
    [E.CORE_LOADED] = true,
    [E.PLAYER_READY] = true,
}

local firedStickyEvents = {}

local function TriggerEvent(event, ...)
    if stickyEvents[event] then
        firedStickyEvents[event] = { n = select("#", ...), ... }
    end
    bus:TriggerEvent(event, ...)
end

function BitForge.Subscribe(event, callback, owner)
    bus:RegisterCallback(event, callback, owner)

    local payload = firedStickyEvents[event]
    if payload then
        callback(unpack(payload, 1, payload.n))
    end
end

function BitForge.Unsubscribe(event, owner)
    bus:UnregisterCallback(event, owner)
end

function ns:Subscribe(event, fn)
    BitForge.Subscribe(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    BitForge:RegisterCharacter()
    TriggerEvent(E.PLAYER_READY)
end)

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGOUT", function()
    TriggerEvent(E.PLAYER_LEAVING)
    model.CleanupDatabase()
end)

EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_OPENED", function()
    TriggerEvent(E.BANK_OPENED)
end)

EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_CLOSED", function()
    TriggerEvent(E.BANK_CLOSED)
end)

EventRegistry:RegisterFrameEventAndCallback("SKILL_LINES_CHANGED", function()
    TriggerEvent(E.SKILL_LINES_CHANGED)
end)

-- ================================================================================
-- Settings
-- ================================================================================

local PREFIX = "BitForge_"
local PREFIX_LEN = #PREFIX

-- =========================================================
-- Scan
-- =========================================================

local function ScanModules()
    local modules = {}
    local count = C_AddOns.GetNumAddOns()
    for i = 1, count do
        local name, title = C_AddOns.GetAddOnInfo(i)
        if name and sub(name, 1, PREFIX_LEN) == PREFIX then
            -- GetAddOnEnableState: 0=disabled, 1=enabled(other char), 2=enabled(this char)
            local state = C_AddOns.GetAddOnEnableState(name, enum.PLAYER_NAME)
            modules[#modules + 1] = {
                name = name,
                title = title or name,
                enabled = state == 2,
                loaded = C_AddOns.IsAddOnLoaded(name),
            }
        end
    end
    model.SetModuleList(modules)
end

--- Called when a module checkbox is toggled.
---@param addonName string
---@param enable boolean
local function OnToggle(addonName, enable)
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

-- =========================================================
-- Events
-- =========================================================

local function OnCoreLoaded()
    ScanModules()

    local modules = model.GetModuleList()
    local callbacks = {}
    for _, mod in ipairs(modules) do
        local name = mod.name
        callbacks[name] = {
            getValue = function()
                return C_AddOns.GetAddOnEnableState(name, enum.PLAYER_NAME) == 2
            end,
            setValue = function(value)
                OnToggle(name, value)
            end,
        }
    end

    view:Register(modules, callbacks)
end

-- OnCoreLoaded must run before TriggerEvent(CORE_LOADED) so that
-- BitForge.settingsCategory is set before any module's CORE_LOADED handler
-- fires. TriggerEvent dispatches via pairs() which gives no ordering guarantee,
-- so we cannot rely on subscription order to ensure the core runs first.
EventUtil.ContinueOnAddOnLoaded("BitForge", function()
    model.InitializeDatabase()
    OnCoreLoaded()
    TriggerEvent(E.CORE_LOADED)
end)

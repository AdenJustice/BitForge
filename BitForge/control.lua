---@class BitForge.Core
local ns = select(2, ...)
local model = ns.model
local view = ns.view
local enum = ns.enum
---@class BitForge.Core.Control
local control = ns.control
local E = BitForge.Events

local C_AddOns = C_AddOns
local EventRegistry = EventRegistry
local ipairs = ipairs
local sub = string.sub

-- ================================================================================
-- Minimap button
-- ================================================================================

---@class BitForge.Core.Control.MinimapButton
local minimapButton = {}

local entries = {}

--- Builds the shared module menu. Anchored to whatever opened it -- the minimap
--- button or the addon compartment entry.
---@param anchor Frame
function minimapButton.OpenMenu(anchor)
    MenuUtil.CreateContextMenu(anchor, function(_, rootDescription)
        rootDescription:CreateTitle("BitForge")
        for _, entry in ipairs(entries) do
            rootDescription:CreateButton(entry.label, entry.onToggle)
        end
    end)
end

---@param angle number degrees
function minimapButton.OnPositionChanged(angle)
    model.UpdateDatabase("minimapPos", angle)
end

--- Built at PLAYER_LOGIN rather than on load: the position depends on the
--- minimap's real dimensions and on GetMinimapShape, and any UI addon providing
--- either has finished loading by then.
function minimapButton.Init()
    view.minimapButton.Create(minimapButton.OpenMenu, minimapButton.OnPositionChanged)
    view.minimapButton.SetPosition(
        model.ReadDatabase("minimapPos") or enum.DB_DEFAULTS.global.minimapPos)
end

control.minimapButton = minimapButton

--- Registers a module entry in the BitForge menu.
---@param entry { label: string, icon: string, onToggle: function }  icon is reserved for future menu icon support
function BitForge.RegisterMinimapButton(entry)
    entries[#entries + 1] = entry
end

-- The addon compartment calls these by name out of the TOC, so they have to be
-- globals rather than namespace members. Blizzard dispatches them as
-- _G[func](addonName, ...) after calling forceinsecure()
-- (Blizzard_Minimap/Mainline/AddonCompartment.lua:97-119).

-- Only the enter and leave callbacks are handed the frame; the click callback
-- receives the mouse button's name instead (:99-103). Hovering necessarily
-- precedes clicking, so the anchor is captured here.
local compartmentAnchor

function BitForge_OnAddonCompartmentEnter(_, anchor)
    compartmentAnchor = anchor
    view.minimapButton.ShowTooltip(anchor, "minimap:compartmentTooltip")
end

function BitForge_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

function BitForge_OnAddonCompartmentClick()
    minimapButton.OpenMenu(compartmentAnchor or AddonCompartmentFrame)
end

-- ================================================================================
-- Lifecycle
-- ================================================================================
--
-- The bus and the relay registry live in events.lua. Only the two events core
-- publishes itself are wired here; every other event in BitForge.Events is a
-- relay that registers itself when a module first subscribes to it.

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    BitForge:RegisterCharacter()
    minimapButton.Init()
    control.TriggerEvent(E.PLAYER_READY)
end)

-- No module observes logout, so this stays a private core registration rather
-- than an entry in BitForge.Events.
EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGOUT", function()
    model.CleanupDatabase()
end)

-- ================================================================================
-- Settings
-- ================================================================================

local PREFIX = enum.ADDON_PREFIX
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
    else
        C_AddOns.DisableAddOn(addonName)
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
    control.TriggerEvent(E.CORE_LOADED)
end)

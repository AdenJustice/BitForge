---@class BitForge.Core
local ns = select(2, ...)
---@class BitForge.Core.Control
local control = ns.control

local coreEvents = BitForge.Events

local CallbackRegistryMixin = CallbackRegistryMixin
local CreateFromMixins = CreateFromMixins
local EventRegistry = EventRegistry
local error = error
local pairs = pairs
local tostring = tostring

-- ================================================================================
-- Event Bus
-- ================================================================================
--
-- Modules never register frame events themselves. Every entry in
-- BitForge.Events is either published by core or relayed from the identically
-- named WoW frame event, and every one of them reaches a module through
-- BitForge.Subscribe.

local bus = CreateFromMixins(CallbackRegistryMixin)
bus:OnLoad()
bus:SetUndefinedEventsAllowed(true)

-- Published by core rather than relayed from a frame event.
local corePublished = {
    [coreEvents.CORE_LOADED]  = true,
    [coreEvents.PLAYER_READY] = true,
}

-- Derived from the enum so there is no second list to drift. Subscribing to a
-- value absent here raises, which is what keeps the event surface governed
-- rather than merely centralized.
local knownEvents = {}
for _, value in pairs(coreEvents) do
    knownEvents[value] = true
end

-- Replayed to subscribers that arrive after the event already fired. Kept to
-- the payload-free lifecycle events on purpose: replaying a stale relay payload
-- would describe a world that has already moved on, and retaining one would
-- hold a value past the scope it was delivered in.
local stickyEvents = {
    [coreEvents.CORE_LOADED]  = true,
    [coreEvents.PLAYER_READY] = true,
}

local firedStickyEvents = {}

--- Publishes a core event. Private to core: modules must be able to subscribe
--- to these but not to forge them, so this is on ns.control, not on BitForge.
---@param event string
function control.TriggerEvent(event, ...)
    if stickyEvents[event] then
        firedStickyEvents[event] = true
    end
    bus:TriggerEvent(event, ...)
end

-- ================================================================================
-- Relays
-- ================================================================================
--
-- A relay's bus key is the raw WoW event name, so the name to register is the
-- event itself. Registration is refcounted by distinct owner: core listens to
-- MERCHANT_SHOW only while something is subscribed to it.

local relayHandles = {}
local relayOwners = {}
local relayCounts = {}

local function AcquireRelay(event, owner)
    if corePublished[event] then return end

    local owners = relayOwners[event]
    if not owners then
        owners = {}
        relayOwners[event] = owners
        relayCounts[event] = 0
    end

    -- RegisterCallback drops an owner's previous callback before adding the new
    -- one, so a repeat subscribe is idempotent there. The count has to match, or
    -- a module that re-subscribes would pin the relay forever.
    if owners[owner] then return end

    owners[owner] = true
    relayCounts[event] = relayCounts[event] + 1

    if relayCounts[event] == 1 then
        relayHandles[event] = EventRegistry:RegisterFrameEventAndCallbackWithHandle(
            event,
            -- EventRegistry dispatches with its own owner ID ahead of the
            -- payload. Drop it here so no module ever sees it.
            function(_, ...)
                control.TriggerEvent(event, ...)
            end)
    end
end

local function ReleaseRelay(event, owner)
    if corePublished[event] then return end

    local owners = relayOwners[event]
    if not owners or not owners[owner] then return end

    owners[owner] = nil
    relayCounts[event] = relayCounts[event] - 1

    if relayCounts[event] == 0 then
        relayHandles[event]:Unregister()
        relayHandles[event] = nil
    end
end

-- ================================================================================
-- Public API
-- ================================================================================

--- Subscribes to a BitForge.Events entry. The callback receives exactly the
--- payload WoW sent -- no owner ID, no padding.
---@param event string a value from BitForge.Events
---@param callback function
---@param owner table
function BitForge.Subscribe(event, callback, owner)
    if not knownEvents[event] then
        error("BitForge.Subscribe: unknown event " .. tostring(event), 2)
    end
    if owner == nil then
        -- RegisterCallback would generate an owner ID core never sees, leaving
        -- the subscription impossible to refcount or release.
        error("BitForge.Subscribe: owner is required", 2)
    end

    -- CallbackRegistryMixin dispatches Function callbacks as func(owner, ...).
    -- Strip that leading owner so live dispatch matches the sticky replay below.
    bus:RegisterCallback(event, function(_, ...)
        callback(...)
    end, owner)

    AcquireRelay(event, owner)

    if firedStickyEvents[event] then
        callback()
    end
end

---@param event string a value from BitForge.Events
---@param owner table
function BitForge.Unsubscribe(event, owner)
    bus:UnregisterCallback(event, owner)
    ReleaseRelay(event, owner)
end

function ns:Subscribe(event, fn)
    BitForge.Subscribe(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

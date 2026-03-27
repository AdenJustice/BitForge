local ns = select(2, ...)
local E  = BitForge.Events

function ns:Subscribe(event, fn)
    BitForge.EventBus:RegisterCallback(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.EventBus:UnregisterCallback(event, self)
end

local EventRegistry = EventRegistry

local model = ns.Model
local L = ns.L

-- Allocate the module DB and initialize the Model.
-- oUF Factory runs on PLAYER_LOGIN (same event as PLAYER_READY), so by the time
-- frames are spawned the DB is already initialized.
ns:Subscribe(E.CORE_LOADED, function()
    BitForge:AllocateModuleDB("UnitFrame", ns.DB_DEFAULTS, model.Init)
end)

-- Called by SettingsPanel after a toggle setter fires.
-- Disables the addon if both features are off, then requests a reload.
function ns.OnSettingToggled()
    if not model.GetUnitFramesEnabled() and not model.GetClassPanelEnabled() then
        C_AddOns.DisableAddOn("BitForge_UnitFrame")
        BitForge:Print(L["msg:bothDisabled"])
    end
    StaticPopup_Show("CONFIRM_RELOADUI")
end

-- =========================================================
-- Raid tier visibility
-- =========================================================

local pendingRaidUpdate = false
local activeRaidTier    = nil

local function ApplyRaidVisibility()
    if not IsInRaid() then
        if activeRaidTier ~= nil then
            ns.RaidView.HideAll()
            activeRaidTier = nil
        end
        return
    end

    local count   = GetNumGroupMembers()
    local newTier = count <= 20 and "raid_small"
        or count <= 30 and "raid_medium"
        or "raid_large"

    if newTier == activeRaidTier then return end

    ns.RaidView.SetActiveTier(newTier)
    activeRaidTier = newTier
end

local function UpdateRaidVisibility()
    if InCombatLockdown() then
        pendingRaidUpdate = true
        return
    end
    ApplyRaidVisibility()
    pendingRaidUpdate = false
end

EventRegistry:RegisterFrameEventAndCallback("GROUP_ROSTER_UPDATE",   UpdateRaidVisibility, ns)
EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD", UpdateRaidVisibility, ns)
EventRegistry:RegisterFrameEventAndCallback("PLAYER_REGEN_ENABLED", function()
    if pendingRaidUpdate then UpdateRaidVisibility() end
end, ns)

local ns = select(2, ...)

local ipairs = ipairs
local min    = math.min
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver

local BAR_DEFS = ns.BAR_DEFS
local BINDING_PREFIX = ns.BINDING_PREFIX
local model = ns.Model

local _bindFrame = CreateFrame("Frame", "BitForge_ABBinds")
local _vehicleClear = false

local function UpdateKeybinds()
    if InCombatLockdown() then return end
    ClearOverrideBindings(_bindFrame)

    if not model then return end

    for _, def in ipairs(BAR_DEFS) do
        local cfg     = model.GetBarConfig(def.key)
        local prefix  = BINDING_PREFIX[def.key]
        -- ns.GetBarButtons is defined in ActionBarsController; may return nil
        -- before PLAYER_READY fires (early UPDATE_BINDINGS events are no-ops).
        local buttons = ns.GetBarButtons and ns.GetBarButtons(def.key)
        if cfg and prefix and buttons then
            local count = min(cfg.count or def.count, def.count)
            for i = 1, count do
                local btn = buttons[i]
                if btn and btn:GetName() then
                    local k1, k2 = GetBindingKey(prefix .. i)
                    if k1 then SetOverrideBindingClick(_bindFrame, true, k1, btn:GetName()) end
                    if k2 then SetOverrideBindingClick(_bindFrame, true, k2, btn:GetName()) end
                end
            end
        end
    end
end

ns.UpdateKeybinds = UpdateKeybinds

local function ClearBindsForVehicle()
    if _vehicleClear then return end
    _vehicleClear = true
    if not InCombatLockdown() then ClearOverrideBindings(_bindFrame) end
end

local function RestoreBindsAfterVehicle()
    if not _vehicleClear then return end
    _vehicleClear = false
    if not InCombatLockdown() then UpdateKeybinds() end
    -- Combat case: _bindFrame's PLAYER_REGEN_ENABLED listener restores binds when combat ends.
end

-- Vehicle state via secure driver so it works in combat.
local _vehicleMonitor = CreateFrame("Frame", "BitForge_ABVehicleMonitor", UIParent,
    "SecureHandlerStateTemplate")
_vehicleMonitor:SetAttribute("_onstate-vehicleui", [[
    if newstate == "invehicle" then
        self:CallMethod("OnVehicleEnter")
    else
        self:CallMethod("OnVehicleExit")
    end
]])
_vehicleMonitor.OnVehicleEnter = ClearBindsForVehicle
_vehicleMonitor.OnVehicleExit  = RestoreBindsAfterVehicle
RegisterStateDriver(_vehicleMonitor, "vehicleui", "[vehicleui] invehicle; novehicle")

-- PLAYER_REGEN_ENABLED is registered only here — no other controller uses it.
_bindFrame:RegisterEvent("UPDATE_BINDINGS")
_bindFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
_bindFrame:SetScript("OnEvent", function(_, event)
    if event == "UPDATE_BINDINGS" or event == "PLAYER_REGEN_ENABLED" then
        UpdateKeybinds()
    end
end)

local ns = select(2, ...)
local E  = BitForge.Events

function ns:Subscribe(event, fn)
    BitForge.EventBus:RegisterCallback(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.EventBus:UnregisterCallback(event, self)
end

local _G = _G
local ipairs = ipairs
local wipe = table.wipe
local InCombatLockdown = InCombatLockdown
local hooksecurefunc = hooksecurefunc
local RegisterAttributeDriver = RegisterAttributeDriver

local model      = ns.Model
local BAR_DEFS = ns.BAR_DEFS
local BAR_LOOKUP = ns.BAR_LOOKUP
local BINDING_PREFIX = ns.BINDING_PREFIX

local barFrames      = {} -- [key] = frame
local barButtons     = {} -- [key] = { btn1, btn2, … }
local allButtons     = {} -- [actionSlot] = button

-- Accessor for KeybindController — returns button list for one bar key.
-- Called inside functions only; barButtons is populated before first use.
local function GetBarButtons(key) return barButtons[key] end
ns.GetBarButtons = GetBarButtons

-------------------------------------------------------------------------------
--  HIDDEN PARENT
--  Reparenting Blizzard bars here avoids calling :Hide() on protected frames,
--  which can cause taint chains.
-------------------------------------------------------------------------------
local hiddenParent = CreateFrame("Frame", "BitForge_ABHidden", UIParent)
hiddenParent:SetAllPoints()
hiddenParent:Hide()

-------------------------------------------------------------------------------
--  EARLY DISPOSAL  (at file load — before PLAYER_LOGIN)
--  Multi-bar frames have no EAB/stance/pet dependency so they are safe to
--  reparent immediately. This is SetParent (disposal), not layout.
-------------------------------------------------------------------------------
do
    local earlyDispose = {
        "MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarLeft", "MultiBarRight",
        "MultiBar5", "MultiBar6", "MultiBar7",
    }
    for _, name in ipairs(earlyDispose) do
        local f = _G[name]
        if f then
            f:UnregisterAllEvents()
            if f.HideBase then f:HideBase() else f:Hide() end
            f:SetParent(hiddenParent)
        end
    end
end

-------------------------------------------------------------------------------
--  EVENT LISTS
--  Restored per-button after DisposeLateBlizzBars wipes parent frame events.
-------------------------------------------------------------------------------
local ACTION_EVENTS = {
    "ACTIONBAR_UPDATE_STATE", "ACTIONBAR_UPDATE_USABLE",
    "ACTIONBAR_UPDATE_COOLDOWN", "ACTIONBAR_SLOT_CHANGED",
    "PLAYER_ENTERING_WORLD", "UPDATE_SHAPESHIFT_FORM",
    "SPELL_UPDATE_CHARGES", "UPDATE_INVENTORY_ALERTS",
    "PLAYER_EQUIPMENT_CHANGED", "LOSS_OF_CONTROL_ADDED",
    "LOSS_OF_CONTROL_UPDATE",
}
local STANCE_EVENTS = {
    "UPDATE_SHAPESHIFT_FORMS", "UPDATE_SHAPESHIFT_FORM",
    "ACTIONBAR_PAGE_CHANGED", "PLAYER_ENTERING_WORLD",
    "UPDATE_SHAPESHIFT_COOLDOWN",
}
local PET_EVENTS = {
    "PET_BAR_UPDATE", "PET_BAR_UPDATE_COOLDOWN",
    "PET_BAR_UPDATE_USABLE", "PLAYER_CONTROL_LOST",
    "PLAYER_CONTROL_GAINED", "PLAYER_FARSIGHT_FOCUS_CHANGED",
    "PLAYER_ENTERING_WORLD", "PET_BAR_SHOWGRID",
    "PET_BAR_HIDEGRID",
}

local function ReRegisterEvents(btn, list, unitEvents)
    for _, ev in ipairs(list) do btn:RegisterEvent(ev) end
    if unitEvents == "action" then
        btn:RegisterUnitEvent("UNIT_AURA", "player")
    elseif unitEvents == "pet" then
        btn:RegisterUnitEvent("UNIT_PET", "player")
        btn:RegisterUnitEvent("UNIT_FLAGS", "pet")
    end
end

-------------------------------------------------------------------------------
--  LATE DISPOSAL  (called inside Init at PLAYER_READY)
--  Frames with EAB/stance/pet dependencies must wait until PLAYER_LOGIN.
-------------------------------------------------------------------------------
local NUM_AB_PAGES = NUM_ACTIONBAR_PAGES or 6

local function DisposeLateBlizzBars()
    local late = { "MainMenuBar", "StanceBar", "PetActionBar" }
    for _, name in ipairs(late) do
        local f = _G[name]
        if f then
            f:UnregisterAllEvents()
            -- Leading semicolon prevents ambiguous parse: (expr)(args) after prior statement.
            ; (f.HideBase or f.Hide)(f)
            f:SetParent(hiddenParent)
            if name == "MainMenuBar" and f.actionButtons then
                wipe(f.actionButtons)
            end
        end
    end

    if MainActionBarController then
        MainActionBarController:UnregisterAllEvents()
    end
    if MainMenuBarPageNumber then MainMenuBarPageNumber:Hide() end
    if StatusTrackingBarManager then
        StatusTrackingBarManager:UnregisterAllEvents()
        StatusTrackingBarManager:Hide()
    end

    if ActionBarParent then
        RegisterAttributeDriver(ActionBarParent, "state-visibility",
            "[vehicleui][overridebar] show; hide")
    end
    if OverrideActionBar then
        RegisterAttributeDriver(OverrideActionBar, "state-visibility",
            "[vehicleui][overridebar] show; hide")
    end

    -- Patch ActionBar_PageUp/Down to read from our bar frame instead of
    -- MainMenuBar (which is now hidden and breaks the stock implementation).
    ActionBar_PageUp = function()
        local f = barFrames["MainBar"]
        local cur = f and tonumber(f:GetAttribute("state-page"))
            or (GetActionBarPage and GetActionBarPage() or 1)
        ChangeActionBarPage(cur < NUM_AB_PAGES and cur + 1 or 1)
    end
    ActionBar_PageDown = function()
        local f = barFrames["MainBar"]
        local cur = f and tonumber(f:GetAttribute("state-page"))
            or (GetActionBarPage and GetActionBarPage() or 1)
        ChangeActionBarPage(cur > 1 and cur - 1 or NUM_AB_PAGES)
    end
end

-------------------------------------------------------------------------------
--  BUTTON HELPERS
-------------------------------------------------------------------------------
local function DisableButtonMouseInput(btn)
    if btn.TextOverlayContainer then
        btn.TextOverlayContainer:EnableMouse(false)
        if btn.TextOverlayContainer.SetMouseClickEnabled then
            btn.TextOverlayContainer:SetMouseClickEnabled(false)
            btn.TextOverlayContainer:SetMouseMotionEnabled(false)
        end
    end
end

local function ApplyButtonBinding(btn, key, i)
    local prefix = BINDING_PREFIX[key] or ""
    btn:SetAttributeNoHandler("binding", prefix .. i)
    btn.commandName = prefix .. i
    btn:RegisterForClicks("AnyDown", "AnyUp")
    btn:EnableMouseWheel(true)
end

-- Shared references for per-bar Controller files.
-- ns._allButtons is the same table as the local; writes from either side are visible to both.
ns._allButtons             = allButtons
ns.DisableButtonMouseInput = DisableButtonMouseInput
ns.ApplyButtonBinding      = ApplyButtonBinding
ns.ReRegisterActionEvents  = function(btn) ReRegisterEvents(btn, ACTION_EVENTS, "action") end
ns.ReRegisterStanceEvents  = function(btn) ReRegisterEvents(btn, STANCE_EVENTS) end
ns.ReRegisterPetEvents     = function(btn) ReRegisterEvents(btn, PET_EVENTS, "pet") end

-------------------------------------------------------------------------------
--  BAR SETUP
--  Creates the bar frame and assigns buttons to it.
-------------------------------------------------------------------------------
local function SetupBar(def)
    local key = def.key

    local frame = ns.CreateBarFrame(def)
    barFrames[key] = frame

    local buttons = {}

    if def.isStance then
        buttons = ns.SetupStanceBar(frame, def)
    elseif def.isPetBar then
        buttons = ns.SetupPetBar(frame, def)
    elseif key == "MainBar" then
        buttons = ns.SetupMainBar(frame, def)
    else
        buttons = ns.SetupMultiBar(frame, def)
    end

    -- Wipe blizzBar.actionButtons so UpdateShownButtons can't interfere.
    if not def.isStance and not def.isPetBar then
        local blizzBar = _G[def.blizzFrame]
        if blizzBar and blizzBar.actionButtons then
            wipe(blizzBar.actionButtons)
        end
    end

    barButtons[key] = buttons
end

-------------------------------------------------------------------------------
--  LAYOUT ENGINE
--  ComputeLayout does pure Lua math (no WoW API).
--  LayoutBar reads Model, calls ComputeLayout, then delegates to View.
-------------------------------------------------------------------------------
local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min

local function ComputeLayout(def, cfg)
    local count    = max(1, min(cfg.count or def.count, def.count))
    local numRows  = max(1, cfg.rows or 1)
    local stride   = ceil(count / numRows)
    numRows        = ceil(count / stride)

    -- Stance/pet buttons are proportional to BTN_SIZE, not the same size.
    local btnSize  = (def.isStance or def.isPetBar)
        and floor(ns.BTN_SIZE * 0.8)
        or ns.BTN_SIZE
    local stepSize = btnSize + ns.BTN_PADDING
    local frameW   = stride * btnSize + (stride - 1) * ns.BTN_PADDING
    local frameH   = numRows * btnSize + (numRows - 1) * ns.BTN_PADDING

    return {
        count    = count,
        stride   = stride,
        numRows  = numRows,
        btnSize  = btnSize,
        stepSize = stepSize,
        frameW   = max(frameW, 1),
        frameH   = max(frameH, 1),
    }
end

local function LayoutBar(key)
    if InCombatLockdown() then return end

    local def     = BAR_LOOKUP[key]
    local cfg     = model.GetBarConfig(key)
    local frame   = barFrames[key]
    local buttons = barButtons[key]
    if not def or not cfg or not frame or not buttons then return end

    local params = ComputeLayout(def, cfg)
    ns.View.ApplyLayout(frame, buttons, params, cfg)
end

-------------------------------------------------------------------------------
--  SHOWGRID MANAGEMENT
--  ACTIONBAR_SHOWGRID/HIDEGRID reveal empty slots during spell drag.
-------------------------------------------------------------------------------
local SHOWGRID_GAME = ns.SHOWGRID_GAME
local _gridShown = false

local function SetShowGridLua(btn, show, reason)
    if InCombatLockdown() then return end
    local cur = btn:GetAttribute("showgrid") or 0
    if show then
        if cur % (reason * 2) < reason then cur = cur + reason end
    elseif cur % (reason * 2) >= reason then
        cur = cur - reason
    end
    btn:SetAttribute("showgrid", cur)
end

local function ShowGrid()
    if InCombatLockdown() or _gridShown then return end
    _gridShown = true
    for _, def in ipairs(BAR_DEFS) do
        if not def.isStance and not def.isPetBar then
            local buttons = barButtons[def.key]
            if buttons then
                for _, btn in ipairs(buttons) do
                    if btn then
                        SetShowGridLua(btn, true, SHOWGRID_GAME)
                        if btn:GetAlpha() < 0.01 then btn:SetAlpha(1) end
                        btn:Show()
                    end
                end
            end
        end
    end
end

local function HideGrid()
    if not _gridShown then return end
    _gridShown = false
    if InCombatLockdown() then return end
    for _, def in ipairs(BAR_DEFS) do
        if not def.isStance and not def.isPetBar then
            local buttons = barButtons[def.key]
            if buttons then
                local cfg   = model.GetBarConfig(def.key)
                local count = cfg and (cfg.count or def.count) or def.count
                for i, btn in ipairs(buttons) do
                    if btn then
                        SetShowGridLua(btn, false, SHOWGRID_GAME)
                        if i > count then btn:Hide() end
                    end
                end
            end
        end
    end
end

local gridFrame = CreateFrame("Frame")
gridFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
gridFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
gridFrame:SetScript("OnEvent", function(_, event)
    if event == "ACTIONBAR_SHOWGRID" then ShowGrid() else HideGrid() end
end)

-------------------------------------------------------------------------------
--  SHOWGRID MONITOR
--  Mirrors Blizzard's showgrid flag from ActionButton1 to our abController
--  so our buttons respond to game-driven spell drag events.
-------------------------------------------------------------------------------
local function InitShowGridMonitor()
    if not ActionButton1 then return end
    local ctrl = _G["BitForge_ABController"]
    if not ctrl then return end
    ctrl:WrapScript(ActionButton1, "OnAttributeChanged", [[
        if name ~= "showgrid" then return end
        for r = 2, 4, 2 do
            local on = value % (r * 2) >= r
            control:RunAttribute("SetShowGrid", on, r)
        end
    ]])
end

-------------------------------------------------------------------------------
--  VEHICLE EXIT BUTTON
-------------------------------------------------------------------------------
local function SetupVehicleExitButton()
    local btn = MainMenuBarVehicleLeaveButton
    if not btn then return end

    btn:SetScript("OnShow", nil)
    btn:SetScript("OnHide", nil)
    btn:SetParent(UIParent)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(100)

    local function AnchorVehicleBtn()
        if InCombatLockdown() then return end
        btn:ClearAllPoints()
        local mainBar = barFrames["MainBar"]
        if mainBar then
            btn:SetPoint("BOTTOMLEFT", mainBar, "TOPRIGHT", 4, 0)
        else
            btn:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 130)
        end
    end
    AnchorVehicleBtn()

    local hookGuard = false
    hooksecurefunc(btn, "SetPoint", function(_, _, parent)
        if hookGuard then return end
        local bar1   = barFrames["MainBar"]
        local anchor = bar1 or UIParent
        if parent ~= anchor and parent ~= UIParent then
            hookGuard = true
            AnchorVehicleBtn()
            hookGuard = false
        end
    end)
end

-------------------------------------------------------------------------------
--  INITIALIZATION
-------------------------------------------------------------------------------
local function Init()
    DisposeLateBlizzBars()
    InitShowGridMonitor()

    for _, def in ipairs(BAR_DEFS) do
        SetupBar(def)
        LayoutBar(def.key)
    end

    SetupVehicleExitButton()
    ns.UpdateKeybinds()
end

ns:Subscribe(E.CORE_LOADED, function()
    BitForge:AllocateModuleDB("ActionBars", ns.DB_DEFAULTS, function(db)
        model.Init(db)
    end)
end)

ns:Subscribe(E.PLAYER_READY, Init)

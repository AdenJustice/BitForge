local ns = select(2, ...)

local _G = _G

local CreateFrame = CreateFrame

local model = ns.Model

ns.Helpers = {}
local H = ns.Helpers

-- Applies the saved or default anchor position to a frame.
-- Saved positions are retrieved via Model; defaults come from ns.FRAME_DEFAULTS.
function H.ApplyPosition(frame, unit)
    frame:ClearAllPoints()
    local saved = model.GetPosition(unit)
    if saved then
        frame:SetPoint(saved[1], _G[saved[2]] or UIParent, saved[3], saved[4], saved[5])
        return
    end
    local d = ns.FRAME_DEFAULTS[unit]
    if d then
        frame:SetPoint(d[1], _G[d[2]] or UIParent, d[3], d[4], d[5])
    end
end

-- Makes a frame draggable while Edit Mode is active.
-- Displays a gold border highlight during Edit Mode.
-- Persists the final position through Model (no direct DB write).
--
-- Intentionally avoids EditModeSystemMixin / OnSystemLoad registration.
-- Registering with EditModeManagerFrame.registeredSystemFrames taints
-- frame.system / frame.systemIndex, causing "attempt to compare a secret
-- number value" warnings in secureexecuterange calls during Edit Mode.
function H.SetupMovable(frame, unit)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    local highlight = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    highlight:SetAllPoints(frame)
    highlight:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
    })
    highlight:SetBackdropBorderColor(1, 0.82, 0, 1)
    highlight:Hide()

    EventRegistry:RegisterCallback("EditMode.Enter", function() highlight:Show() end, highlight)
    EventRegistry:RegisterCallback("EditMode.Exit", function() highlight:Hide() end, highlight)

    frame:SetScript("OnMouseDown", function(self, btn)
        if btn == "LeftButton" and EditModeManagerFrame:IsEditModeActive() then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnMouseUp", function(self, btn)
        if not (btn == "LeftButton" and EditModeManagerFrame:IsEditModeActive()) then return end
        self:StopMovingOrSizing()
        local point, rel, relPoint, x, y = self:GetPoint(1)
        if point then
            local relName = rel and (rel:GetName() or "UIParent") or "UIParent"
            model.SavePosition(unit, point, relName, relPoint, x, y)
        end
    end)

    H.ApplyPosition(frame, unit)
end

-- Adds a faint 1px dark border just outside the frame for a floating appearance.
function H.ApplyShadow(self)
    local offset = 1
    local shadow = CreateFrame("Frame", nil, self, "BackdropTemplate")
    shadow:SetFrameLevel(math.max(0, self:GetFrameLevel() - 1))
    shadow:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset)
    shadow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset)
    shadow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    shadow:SetBackdropBorderColor(0, 0, 0, 0.35)
    self.Shadow = shadow
end

-- Applies shared base setup to every unit frame:
--   shadow, click/hover handlers, health bar, RaidTargetIndicator.
-- Callers are responsible for setting health coloring flags
-- (colorClass, colorReaction, colorHealth) after calling this.
function H.ApplyBaseStyle(self)
    H.ApplyShadow(self)

    self:RegisterForClicks("AnyUp")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)

    local health = CreateFrame("StatusBar", nil, self)
    health:SetAllPoints(self)
    health:SetStatusBarTexture(ns.TEXTURE)
    health.colorTapping      = true
    health.colorDisconnected = true

    local healthBg           = health:CreateTexture(nil, "BACKGROUND")
    healthBg:SetAllPoints(health)
    healthBg:SetTexture(ns.TEXTURE)
    healthBg:SetAlpha(0.3)
    health.bg = healthBg

    self.Health = health

    local raidTarget = self:CreateTexture(nil, "OVERLAY")
    raidTarget:SetSize(16, 16)
    raidTarget:SetPoint("TOPRIGHT", self, "TOPRIGHT", 4, 4)
    self.RaidTargetIndicator = raidTarget
end

-- Adds an 8px power bar anchored to the bottom of the frame.
-- Health bar shrinks to fill the remaining space when the bar is visible.
--
-- Visibility is controlled by flags set on the returned Power element:
--   power.alwaysShow   -- always visible
--   power.showIfBoss   -- show when unit classification is boss/worldboss
--   power.showIfHealer -- show when unit's assigned group role is HEALER
--
-- Recomputed once per entity change (UNIT_NAME_UPDATE / PostUpdate GUID check)
-- rather than every tick, since classification does not change mid-combat.
function H.ApplyPowerBar(self)
    local power = CreateFrame("StatusBar", nil, self)
    power:SetHeight(8)
    power:SetPoint("BOTTOMLEFT", self)
    power:SetPoint("BOTTOMRIGHT", self)
    power:SetStatusBarTexture(ns.TEXTURE)
    power.colorPower        = true
    power.colorDisconnected = true
    power:Hide()

    local powerBg = power:CreateTexture(nil, "BACKGROUND")
    powerBg:SetAllPoints(power)
    powerBg:SetTexture(ns.TEXTURE)
    powerBg:SetAlpha(0.3)
    power.bg = powerBg

    local powerVisible = false

    local function SetPowerVisible(element, visible)
        if visible == powerVisible then return end
        powerVisible = visible
        self.Health:ClearAllPoints()
        if visible then
            self:EnableElement("Power")
            element:Show()
            self.Health:SetPoint("TOPLEFT", self)
            self.Health:SetPoint("TOPRIGHT", self)
            self.Health:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 8)
            self.Health:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 8)
        else
            self:DisableElement("Power")
            element:Hide()
            self.Health:SetAllPoints(self)
        end
    end

    local function UpdatePowerVisibility()
        local unit = self.unit
        if not unit then return end
        local show = false
        if power.alwaysShow then
            show = true
        end
        if not show and power.showIfBoss then
            local c = UnitClassification(unit)
            if c == "boss" or c == "worldboss" then show = true end
        end
        if not show and power.showIfHealer then
            if UnitGroupRolesAssigned(unit) == "HEALER" then show = true end
        end
        SetPowerVisible(power, show)
    end

    -- Primary trigger: fires when the unit slot's occupant changes.
    self:RegisterEvent("UNIT_NAME_UPDATE", function(frame, event, unitTarget)
        if unitTarget == frame.unit then
            power._guid = UnitGUID(frame.unit)
            UpdatePowerVisibility()
        end
    end)

    -- Fallback: handles units that already exist when the addon loads,
    -- since UNIT_NAME_UPDATE may not re-fire for them.
    -- Guarded by GUID so it only runs once per entity.
    power.PostUpdate = function(element, unit, cur, min, max, powerType)
        local guid = UnitGUID(unit)
        if guid == element._guid then return end
        element._guid = guid
        UpdatePowerVisibility()
    end

    self.Power = power
end

-- Adds a 1px border driven by threat status and target selection.
-- Threat color takes priority; falls back to white when the unit is the
-- player's current target. Only intended for group frames (party/raid).
function H.ApplyGroupBorder(self)
    local border = CreateFrame("Frame", nil, self, "BackdropTemplate")
    border:SetAllPoints(self)
    border:SetFrameLevel(self:GetFrameLevel() + 2)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 0)

    local threatStatus = nil

    local function Refresh(unit)
        if threatStatus then return end
        if UnitIsUnit(unit, "target") then
            border:SetBackdropBorderColor(1, 1, 1, 0.8)
        else
            border:SetBackdropBorderColor(0, 0, 0, 0)
        end
    end

    -- Zero-size texture satisfies oUF's ThreatIndicator type check.
    -- Actual visual is driven entirely through PostUpdate on the border.
    local threatTex = self:CreateTexture(nil, "OVERLAY")
    threatTex:SetSize(0, 0)
    threatTex.PostUpdate = function(element, unit, status, color)
        threatStatus = (status and status > 0) and status or nil
        if threatStatus and color then
            border:SetBackdropBorderColor(color.r, color.g, color.b, 1)
        else
            Refresh(unit)
        end
    end
    self.ThreatIndicator = threatTex

    self:RegisterEvent("PLAYER_TARGET_CHANGED", function(frame, event)
        Refresh(frame.unit)
    end)
end

-- Adds a phase indicator icon centered on the health bar.
function H.ApplyPhaseIndicator(self)
    local phaseIndicator = self.Health:CreateTexture(nil, "OVERLAY")
    phaseIndicator:SetSize(24, 24)
    phaseIndicator:SetPoint("CENTER", self.Health, "CENTER")
    self.PhaseIndicator = phaseIndicator
end

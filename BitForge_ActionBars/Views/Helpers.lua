local ns = select(2, ...)

local ipairs = ipairs
local floor = math.floor

local C_Timer = C_Timer
local hooksecurefunc = hooksecurefunc

ns.View = {}
local View = ns.View

local ICON_ZOOM = ns.ICON_ZOOM
local BORDER_SIZE = ns.BORDER_SIZE
local BORDER_COLOR = ns.BORDER_COLOR

-------------------------------------------------------------------------------
--  INTERNAL HELPERS
-------------------------------------------------------------------------------

-- Hides Blizzard's rounded-corner mask and NormalTexture glow.
local function HideBorderArt(btn)
    if btn.NormalTexture then
        btn.NormalTexture:Hide()
        btn.NormalTexture:SetAlpha(0)
    end
    if btn.icon and btn.IconMask then
        btn.icon:RemoveMaskTexture(btn.IconMask)
        btn.IconMask:Hide()
        btn.IconMask:SetTexture(nil)
        btn.IconMask:ClearAllPoints()
        btn.IconMask:SetSize(0.001, 0.001)
    end
end

-- Replaces an atlas-based texture with a plain solid-colour quad.
local function ApplySolidTex(tex, r, g, b, a)
    if not tex then return end
    tex:SetAtlas(nil)
    tex:SetColorTexture(r, g, b, a or 1)
    tex:SetTexCoord(0, 1, 0, 1)
    tex:ClearAllPoints()
    tex:SetAllPoints(tex:GetParent())
end

-- Adds four edge textures to form a thin border around the button.
local function CreateBorderTextures(btn)
    local r, g, b, a = BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4] or 1
    local s = BORDER_SIZE

    local function MakeEdge()
        local t = btn:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(r, g, b, a)
        return t
    end

    local top = MakeEdge()
    top:SetPoint("TOPLEFT",  btn, "TOPLEFT",  0, 0)
    top:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    top:SetHeight(s)

    local bot = MakeEdge()
    bot:SetPoint("BOTTOMLEFT",  btn, "BOTTOMLEFT",  0, 0)
    bot:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    bot:SetHeight(s)

    local left = MakeEdge()
    left:SetPoint("TOPLEFT",    btn, "TOPLEFT",    0, -s)
    left:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0,  s)
    left:SetWidth(s)

    local right = MakeEdge()
    right:SetPoint("TOPRIGHT",    btn, "TOPRIGHT",    0, -s)
    right:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0,  s)
    right:SetWidth(s)
end

-------------------------------------------------------------------------------
--  VIEW.MAKEBUTTONSQUARE
--  Idempotent (guarded by btn._bfSquared). Converts any action button to a
--  clean square with solid-colour overlays and optional thin border.
-------------------------------------------------------------------------------
function View.MakeButtonSquare(btn)
    if btn._bfSquared then return end

    HideBorderArt(btn)

    if not btn.GetPopupDirection then
        btn.GetPopupDirection = function(self)
            return self:GetAttribute("flyoutDirection") or "UP"
        end
    end

    if btn.NormalTexture then
        btn.NormalTexture:HookScript("OnShow", function(self)
            C_Timer.After(0, function()
                if not self:IsForbidden() then self:Hide() end
            end)
        end)
    end

    btn:HookScript("OnShow", function()
        C_Timer.After(0, function()
            if not btn:IsForbidden() then HideBorderArt(btn) end
        end)
    end)

    if btn.UpdateButtonArt then
        local hideFn = function()
            if not btn:IsForbidden() then HideBorderArt(btn) end
        end
        hooksecurefunc(btn, "UpdateButtonArt", function()
            C_Timer.After(0, hideFn)
        end)
    end

    ApplySolidTex(btn.HighlightTexture, 1, 1, 1, 0.15)
    ApplySolidTex(btn.PushedTexture,    1, 1, 1, 0.25)
    ApplySolidTex(btn.Flash,            1, 0.82, 0.2, 0.6)
    ApplySolidTex(btn.CheckedTexture,   1, 0.82, 0.2, 0.35)
    ApplySolidTex(btn.NewActionTexture, 1, 1, 1, 0.15)
    if btn.Border then ApplySolidTex(btn.Border, 0, 0, 0, 0) end

    if btn.FlyoutBorderShadow then btn.FlyoutBorderShadow:SetAlpha(0) end

    if btn.cooldown then
        btn.cooldown:ClearAllPoints()
        btn.cooldown:SetAllPoints(btn)
    end

    if btn.AutoCastOverlay then btn.AutoCastOverlay:SetAllPoints(btn) end

    if btn.SlotBackground then btn.SlotBackground:Hide() end
    if btn.SlotArt        then btn.SlotArt:Hide()        end

    if btn.ProfessionQualityOverlayFrame then
        btn.ProfessionQualityOverlayFrame:SetShown(false)
        btn.ProfessionQualityOverlayFrame:HookScript("OnShow", function(self)
            self:SetShown(false)
        end)
    end

    if btn.Border then
        local guard = false
        hooksecurefunc(btn.Border, "SetAtlas", function(self)
            if guard then return end
            guard = true
            self:SetAtlas(nil)
            self:SetColorTexture(0, 0, 0, 0)
            guard = false
        end)
    end

    if ICON_ZOOM > 0 then
        local icon = btn.icon or btn.Icon
        if icon then
            icon:SetTexCoord(ICON_ZOOM, 1 - ICON_ZOOM, ICON_ZOOM, 1 - ICON_ZOOM)
        end
    end

    if BORDER_SIZE > 0 then
        CreateBorderTextures(btn)
    end

    btn._bfSquared = true
end

-------------------------------------------------------------------------------
--  VIEW.APPLYLAYOUT
--  Receives pre-computed layoutParams from ActionBarsController.ComputeLayout.
--  No geometry logic here — pure positioning and styling.
-------------------------------------------------------------------------------
function View.ApplyLayout(frame, buttons, params, cfg)
    local count    = params.count
    local stride   = params.stride
    local btnSize  = params.btnSize
    local stepSize = params.stepSize

    for i, btn in ipairs(buttons) do
        if i > count then
            btn:Hide()
        else
            btn:Show()

            local col = (i - 1) % stride
            local row = floor((i - 1) / stride)

            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", frame, "TOPLEFT",
                col * stepSize,
                -row * stepSize)
            btn:SetSize(btnSize, btnSize)

            View.MakeButtonSquare(btn)
        end
    end

    frame:SetSize(params.frameW, params.frameH)

    local pt = cfg.point or "BOTTOM"
    frame:ClearAllPoints()
    frame:SetPoint(pt, UIParent, pt, cfg.x or 0, cfg.y or 0)

    -- Flyout direction: computed here because this is where the frame is anchored.
    -- At PLAYER_READY, GetCenter() is always non-nil; "UP" is a defensive fallback.
    local cx  = frame:GetCenter()
    local dir = "UP"
    if cx then
        local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        dir = (cx * scale > UIParent:GetWidth() * 0.5) and "LEFT" or "RIGHT"
    end
    for i = 1, count do
        local btn = buttons[i]
        if btn then btn:SetAttribute("flyoutDirection", dir) end
    end
end

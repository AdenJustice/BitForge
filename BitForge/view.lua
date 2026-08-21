---@type BitForge.Core
local ns = select(2, ...)
---@class BitForge.Core.View
local view = ns.view
---@type BitForge.Core.Locale
local locale = ns.locale

local ipairs = ipairs

local cos = math.cos
local sin = math.sin
local rad = math.rad
local deg = math.deg
local sqrt = math.sqrt
local max = math.max
local min = math.min

-- math.atan2 is the client's Lua 5.1 spelling; Lua removed it in 5.3 in favour
-- of two-argument math.atan, and the headless test runner is 5.5. Binding both
-- keeps one implementation correct in the game and in the suite.
local atan2 = math.atan2 or math.atan

local Settings = Settings
local CreateFrame = CreateFrame
local Minimap = Minimap
local GameTooltip = GameTooltip
local GetCursorPosition = GetCursorPosition

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

-- =========================================================
-- Minimap button
-- =========================================================

---@class BitForge.Core.View.MinimapButton
local minimapButton = {}

-- How far past the minimap's edge the button's centre sits.
local EDGE_RADIUS = 5

-- A square corner reaches further from the centre than the circle does, so a
-- button in a square quadrant is projected along the diagonal and pulled back
-- by this much before being clamped.
local CORNER_INSET = 10

-- Minimap outlines that UI addons publish through the community GetMinimapShape
-- global. Each entry says, per quadrant, whether that corner is rounded, indexed
-- { bottom-right, bottom-left, top-right, top-left }.
local MINIMAP_SHAPES = {
    ["ROUND"]                 = { true, true, true, true },
    ["SQUARE"]                = { false, false, false, false },
    ["CORNER-TOPLEFT"]        = { false, false, false, true },
    ["CORNER-TOPRIGHT"]       = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"]     = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"]    = { true, false, false, false },
    ["SIDE-LEFT"]             = { false, true, false, true },
    ["SIDE-RIGHT"]            = { true, false, true, false },
    ["SIDE-TOP"]              = { false, false, true, true },
    ["SIDE-BOTTOM"]           = { true, true, false, false },
    ["TRICORNER-TOPLEFT"]     = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"]    = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"]  = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

--- Where the button sits on the minimap's ring for a given angle. Pure: every
--- dimension arrives as an argument so the shape table can be tested headlessly.
---@param angle number degrees, 0 = due east, counter-clockwise
---@param width number the minimap's width
---@param height number the minimap's height
---@param radius number how far past the edge the button's centre sits
---@param shape string|nil a MINIMAP_SHAPES key; nil or unknown falls back to ROUND
---@return number x, number y offsets from the minimap's centre
function minimapButton.ComputeOffset(angle, width, height, radius, shape)
    local radians = rad(angle)
    local x, y = cos(radians), sin(radians)

    local quadrant = 1
    if x < 0 then quadrant = quadrant + 1 end
    if y > 0 then quadrant = quadrant + 2 end

    local quadrants = MINIMAP_SHAPES[shape] or MINIMAP_SHAPES["ROUND"]
    local halfWidth = (width / 2) + radius
    local halfHeight = (height / 2) + radius

    if quadrants[quadrant] then
        return x * halfWidth, y * halfHeight
    end

    local diagonalWidth = sqrt(2 * halfWidth ^ 2) - CORNER_INSET
    local diagonalHeight = sqrt(2 * halfHeight ^ 2) - CORNER_INSET
    return max(-halfWidth, min(x * diagonalWidth, halfWidth)),
        max(-halfHeight, min(y * diagonalHeight, halfHeight))
end

--- The angle the cursor sits at relative to the minimap's centre. Pure.
---@param cursorX number cursor position in screen pixels
---@param cursorY number cursor position in screen pixels
---@param centerX number the minimap's centre
---@param centerY number the minimap's centre
---@param scale number the minimap's effective scale
---@return number angle degrees in [0, 360)
function minimapButton.AngleFromCursor(cursorX, cursorY, centerX, centerY, scale)
    return deg(atan2(cursorY / scale - centerY, cursorX / scale - centerX)) % 360
end

local BUTTON_SIZE = 32
local ICON_SIZE = 18
local BACKGROUND_SIZE = 24
local BORDER_SIZE = 50

-- How far the icon's visible area pulls in while the button is held, so a
-- draggable control acknowledges the grab.
local PRESS_INSET = 0.05

-- Cropping PRESS_INSET off each edge and refilling the same area magnifies by
-- 1 / (1 - 2 * inset). The mask is held at ICON_SIZE, so growing the icon to
-- this size is that same zoom -- expressed the only way a masked texture
-- allows, since SetTexCoord is rejected once a texture carries a mask.
local PRESS_SIZE = ICON_SIZE / (1 - 2 * PRESS_INSET)

-- TODO: replace with a real BitForge suite icon when one exists. See section 6
-- of the design doc -- BitForge.toc's IconTexture points at a file that has
-- never been added.
local PLACEHOLDER_ICON = "Interface\\Icons\\Trade_Engineering"

local button

--- Builds and shows the shared "BitForge" tooltip, anchored to the given frame,
--- with one AddLine per hint key. The single construction point for both the
--- minimap button itself and the addon-compartment entry, so the control layer
--- never has to touch GameTooltip.
---@param anchor Frame
---@param ... string locale keys, added as tooltip lines in order
function minimapButton.ShowTooltip(anchor, ...)
    GameTooltip:SetOwner(anchor, "ANCHOR_LEFT")
    GameTooltip:SetText("BitForge", 1, 1, 1, 1)
    for index = 1, select("#", ...) do
        GameTooltip:AddLine(locale[(select(index, ...))], 1, 1, 1)
    end
    GameTooltip:Show()
end

--- Builds the button. Deferred rather than run at file-read time: the frame
--- needs the minimap's real dimensions, and view.lua has to stay loadable in the
--- headless harness, which stubs no CreateFrame.
---@param onClick fun(button: Button)
---@param onPositionChanged fun(angle: number)
function minimapButton.Create(onClick, onPositionChanged)
    if button then return end

    button = CreateFrame("Button", "BitForgeMinimapButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFixedFrameStrata(true)
    button:SetFrameLevel(8)
    button:SetFixedFrameLevel(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER")
    icon:SetTexture(PLACEHOLDER_ICON)

    -- Anchored to the button rather than applied with SetMask, so the circle
    -- stays put while the icon resizes underneath it. SetMask binds the mask to
    -- the icon's own rectangle, which would scale the crop along with the press
    -- instead of zooming within it. The wrap modes are what SetMask supplied
    -- implicitly and have to be named when the mask is built by hand.
    local iconMask = button:CreateMaskTexture()
    iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetSize(ICON_SIZE, ICON_SIZE)
    iconMask:SetPoint("CENTER")
    icon:AddMaskTexture(iconMask)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local draggedAngle

    local function ResetPressState()
        icon:SetSize(ICON_SIZE, ICON_SIZE)
    end

    local function OnUpdate()
        local centerX, centerY = Minimap:GetCenter()
        if not centerX then return end

        local cursorX, cursorY = GetCursorPosition()
        draggedAngle = minimapButton.AngleFromCursor(
            cursorX, cursorY, centerX, centerY, Minimap:GetEffectiveScale())
        minimapButton.SetPosition(draggedAngle)
    end

    button:SetScript("OnDragStart", function(self)
        draggedAngle = nil
        self:LockHighlight()
        self:SetScript("OnUpdate", OnUpdate)
        GameTooltip:Hide()
    end)

    -- The angle is written once, when the drag settles. LibDBIcon writes it on
    -- every OnUpdate frame; there is no reason to touch the saved table 60
    -- times a second when only the resting position matters.
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
        -- A drag-ending release is not guaranteed to also deliver OnMouseUp,
        -- so the press inset has to be undone here too, not only there.
        ResetPressState()
        if draggedAngle then
            onPositionChanged(draggedAngle)
        end
    end)

    button:SetScript("OnMouseDown", function()
        icon:SetSize(PRESS_SIZE, PRESS_SIZE)
    end)

    button:SetScript("OnMouseUp", ResetPressState)

    -- The client suppresses OnClick on a frame that handled a drag, so no
    -- click-versus-drag guard is needed here.
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            onClick(self)
        end
    end)

    button:SetScript("OnEnter", function(self)
        minimapButton.ShowTooltip(self, "minimap:hintClick", "minimap:hintDrag")
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Moves the button to an angle on the ring. Safe to call before Create.
---@param angle number degrees
function minimapButton.SetPosition(angle)
    if not button then return end

    -- GetMinimapShape is a convention other UI addons publish, not a Blizzard
    -- API -- it appears nowhere in wow-ui-source -- so it cannot be whitelisted
    -- in .luarc.json and is read off _G instead of referenced as a bare global.
    local shape = _G.GetMinimapShape and _G.GetMinimapShape() or "ROUND"
    local x, y = minimapButton.ComputeOffset(
        angle, Minimap:GetWidth(), Minimap:GetHeight(), EDGE_RADIUS, shape)

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

view.minimapButton = minimapButton

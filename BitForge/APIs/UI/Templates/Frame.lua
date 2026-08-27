local trim = string.trim
local max = math.max

local PixelUtil = PixelUtil

local UI = BitForge.UI
local colors = UI.Colors

local BACKDROP_CONFIG = {
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    tile = true,
    tileSize = 32,
    edgeSize = UI.GetPixel(),
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local BACKDROP_ALPHA = 0.5

---@class BitForge.FrameMixin : BackdropTemplate
local FrameMixin = {}

--- Initialises backdrop and optional title bar.
---@param hasTitle boolean?  When true, a 32-px primary-colour title bar is added.
function FrameMixin:OnLoad(hasTitle)
    self:SetClampedToScreen(true)
    self:SetBackdrop(BACKDROP_CONFIG)
    self:SetBackdropColor(colors.bg.r, colors.bg.g, colors.bg.b, BACKDROP_ALPHA)
    self:SetBackdropBorderColor(colors.edge:GetRGBA())

    if hasTitle then
        local titleBar = self:CreateTexture(nil, "BORDER")
        titleBar:SetTexture("Interface/Buttons/WHITE8X8")
        PixelUtil.SetHeight(titleBar, 32)
        titleBar:SetVertexColor(colors.point:GetRGBA())
        titleBar:SetPoint("TOPLEFT")
        titleBar:SetPoint("TOPRIGHT")
        self.TitleBar = titleBar

        local title = self:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutlineShadow")
        title:SetJustifyH("CENTER")
        title:SetJustifyV("MIDDLE")
        PixelUtil.SetHeight(title, 32)
        title:SetTextColor(1, 1, 1, 1)
        PixelUtil.SetPoint(title, "TOPLEFT", self, "TOPLEFT", 12, 0)
        PixelUtil.SetPoint(title, "TOPRIGHT", self, "TOPRIGHT", -12, 0)
        self.Title = title
    end
end

--- Set the title bar text.  Errors if the frame was created without a title bar.
---@param text string
function FrameMixin:SetTitle(text)
    if not self.Title then
        error("Attempted to set title on a frame without a title bar.", 2)
    end
    self.Title:SetText(text)
end

UI.Mixins.Frame = FrameMixin

--- Create an MD card-style frame.
---@param parent any
---@param title  string?  Optional title bar text.
---@param name   string?  Optional global frame name, for a window UISpecialFrames
---                        must find by name to close on Escape. Every caller before
---                        this one built an anonymous frame and reached for
---                        `_G[name] = frame` on its own -- correct for `_G`, but
---                        `GetName()` answered nil, because a frame's name is set at
---                        creation and nothing since offers a second chance.
---@return BitForge.FrameMixin
function UI.CreateFrame(parent, title, name)
    local isTitle = title and type(title) == "string" and trim(title) ~= ""

    ---@class BitForge.FrameMixin
    local frame = CreateFrame("Frame", name, parent, "BackdropTemplate")
    Mixin(frame, FrameMixin)
    frame:OnLoad(isTitle)
    if isTitle then
        frame:SetTitle(title)
    end
    return frame
end

--- Adds a faint 1px dark shadow just outside the frame for a floating appearance.
--- Sets frame.Shadow to the created shadow frame.
---@param frame any
function UI.ApplyShadow(frame)
    local shadow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    local offSet = UI.GetPixel(2)
    shadow:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
    shadow:SetBackdrop({
        edgeFile = UI.GetMedia("glow"),
        edgeSize = UI.GetPixel(3),
    })
    shadow:SetPoint("TOPLEFT", frame, "TOPLEFT", -offSet, offSet)
    shadow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offSet, -offSet)
    shadow:SetBackdropBorderColor(0, 0, 0, 0.8)
    frame.Shadow = shadow
end

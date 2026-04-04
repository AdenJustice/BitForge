local pairs = pairs
local floor = math.floor
local max = math.max
local select = select
local setmetatable = setmetatable
local type = type

local UIParent = UIParent
local CreateColor = CreateColorFromHexString

BitForge.UI = {}
local UI = BitForge.UI

-- =========================================================
-- Shared colour palette (Flat Design tokens)
-- =========================================================

---@class BitForge.UI.Colors
---@field point colorRGBA
---@field hover colorRGBA
---@field bg colorRGBA
---@field bgDisabled colorRGBA
---@field surface colorRGBA
---@field disabled colorRGBA
---@field text colorRGBA
---@field textHover colorRGBA
---@field textDisabled colorRGBA
---@field edge colorRGBA
---@field edgeHover colorRGBA
UI.Colors = {
    point = CreateColor("FF45B7D1"),
    hover = CreateColor("FF4B5267"),
    bg = CreateColor("FF121212"),
    bgDisabled = CreateColor("7F121212"),
    surface = CreateColor("FF1E1E1F"),
    disabled = CreateColor("FF181819"),
    text = CreateColor("FF888888"),
    textHover = CreateColor("FFFFFFFF"),
    textDisabled = CreateColor("FF4A4A4B"),
    edge = CreateColor("FF000000"),
    edgeHover = CreateColor("FF2A2A2B"),
}

-- =========================================================
-- BitForge.UI — Flat Design widget library
-- =========================================================

local MEDIA = "Interface/AddOns/BitForge/Media"

--- Returns the full path to a media asset embedded in the BitForge addon.
---@param filename string  Relative name without extension, e.g. "checked"
---@return string
function UI.GetMedia(filename)
    return MEDIA .. "/" .. filename
end

--- Returns the size of one physical pixel in UI units, using UIParent's effective scale.
--- Use this wherever a pixel-perfect 1px value is needed (edgeSize, SetHeight, etc.).
---@return number
function UI.GetPixel(px)
    return PixelUtil.GetNearestPixelSize(px or 1, UIParent:GetEffectiveScale(), 1)
end

--- Returns the gradient texture
function UI.CreateSeparatorTexture(parent)
    assert(parent and parent.IsObjectType and parent:IsObjectType("Frame"))
    local width = floor(parent:GetWidth() * .85)

    local line = parent:CreateTexture(nil, "ARTWORK")
    PixelUtil.SetSize(line, width, 1)
    line:SetPoint("CENTER")
    line:SetTexture("Interface/Common/UI-TooltipDivider-Transparent")
    local c = UI.Colors.point
    line:SetVertexColor(c.r, c.g, c.b, 0.5)

    return line
end

-- =========================================================
-- Shared skin helpers
-- =========================================================

UI.Skin = UI.Skin or {}
local skin = UI.Skin

local windowShellByFrame = setmetatable({}, { __mode = "k" })

local function ResolveRGBA(colorOrRed, green, blue, alpha)
    if colorOrRed == nil then
        return nil
    end

    if type(colorOrRed) == "table" then
        if colorOrRed.GetRGBA then
            return colorOrRed:GetRGBA()
        end

        return colorOrRed.r or 1, colorOrRed.g or 1, colorOrRed.b or 1, colorOrRed.a or 1
    end

    if type(colorOrRed) == "number" then
        return colorOrRed, green or 1, blue or 1, alpha or 1
    end

    return nil
end

function skin.GetSolidBackdrop()
    return {
        bgFile = "Interface/Buttons/WHITE8X8",
        edgeFile = "Interface/Buttons/WHITE8X8",
        tile = false,
        edgeSize = UI.GetPixel(),
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    }
end

function skin.ApplyColorTexture(textureObject, colorOrRed, green, blue, alpha)
    if not textureObject then
        return
    end

    local red, greenValue, blueValue, alphaValue = ResolveRGBA(colorOrRed, green, blue, alpha)
    if not red then
        return
    end

    textureObject:SetColorTexture(red, greenValue, blueValue, alphaValue)
end

function skin.ApplyVertexColor(textureObject, colorOrRed, green, blue, alpha)
    if not textureObject then
        return
    end

    local red, greenValue, blueValue, alphaValue = ResolveRGBA(colorOrRed, green, blue, alpha)
    if not red then
        return
    end

    textureObject:SetVertexColor(red, greenValue, blueValue, alphaValue)
end

function skin.HideTexture(textureObject, clearSource)
    if not textureObject then
        return
    end

    textureObject:SetAlpha(0)

    if clearSource then
        if textureObject.SetAtlas then
            textureObject:SetAtlas(nil)
        end

        if textureObject.SetTexture then
            textureObject:SetTexture(nil)
        end
    end
end

function skin.StripFrameTextures(frameObject, options)
    if not frameObject then
        return
    end

    options = options or {}

    if options.hideNineSlice ~= false and frameObject.NineSlice then
        frameObject.NineSlice:SetAlpha(0)
    end

    if options.hideBorder ~= false and frameObject.Border then
        frameObject.Border:SetAlpha(0)
    end

    if options.hideBg ~= false and frameObject.Bg then
        frameObject.Bg:SetAlpha(0)
    end

    if options.hideBG ~= false and frameObject.BG then
        frameObject.BG:SetAlpha(0)
    end

    if options.stripRegions == false or not frameObject.GetRegions then
        return
    end

    local skipOwnedRegions = options.skipOwnedRegions ~= false
    local regionCount = select("#", frameObject:GetRegions())
    for regionIndex = 1, regionCount do
        local regionObject = select(regionIndex, frameObject:GetRegions())
        if regionObject and regionObject.IsObjectType and regionObject:IsObjectType("Texture") then
            if not (skipOwnedRegions and regionObject._bfOwned) then
                regionObject:SetAlpha(0)
            end
        end
    end
end

function skin.CreateBackdropUnderlay(targetFrame, options)
    if not targetFrame then
        return nil
    end

    options = options or {}

    local parentFrame = options.parent or targetFrame
    local backdropFrame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")

    if options.setAllPoints ~= false then
        backdropFrame:SetAllPoints(targetFrame)
    end

    local frameLevelOffset = options.frameLevelOffset or -1
    backdropFrame:SetFrameLevel(max(1, targetFrame:GetFrameLevel() + frameLevelOffset))
    backdropFrame:SetBackdrop(options.backdrop or skin.GetSolidBackdrop())

    local bgRed, bgGreen, bgBlue, bgAlpha = ResolveRGBA(
        options.backgroundColor or options.backgroundRed,
        options.backgroundGreen,
        options.backgroundBlue,
        options.backgroundAlpha)
    if bgRed then
        backdropFrame:SetBackdropColor(bgRed, bgGreen, bgBlue, bgAlpha)
    end

    local borderRed, borderGreen, borderBlue, borderAlpha = ResolveRGBA(
        options.borderColor or options.borderRed,
        options.borderGreen,
        options.borderBlue,
        options.borderAlpha)
    if borderRed then
        backdropFrame:SetBackdropBorderColor(borderRed, borderGreen, borderBlue, borderAlpha)
    end

    if options.enableMouse == true then
        backdropFrame:EnableMouse(true)
    elseif options.enableMouse == false then
        backdropFrame:EnableMouse(false)
    end

    if options.markOwned == true then
        backdropFrame._bfOwned = true
    end

    return backdropFrame
end

function skin.BuildWindowShell(frameObject, options)
    if not frameObject then
        return nil
    end

    options = options or {}
    local includeHeader = options.includeHeader == true
    local includeInnerTop = options.includeInnerTop ~= false
    local headerHeight = options.headerHeight or 30

    local shell = windowShellByFrame[frameObject]
    if not shell then
        shell = {}
        windowShellByFrame[frameObject] = shell
    end

    if not shell.background then
        shell.background = frameObject:CreateTexture(nil, "BACKGROUND", nil, -8)
        shell.background:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.background:SetPoint("BOTTOMRIGHT", frameObject, "BOTTOMRIGHT", -1, 1)
    end

    if includeHeader and not shell.header then
        shell.header = frameObject:CreateTexture(nil, "BACKGROUND", nil, -7)
        shell.header:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.header:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -1, -1)
        shell.header:SetHeight(headerHeight)
    elseif includeHeader and shell.header then
        shell.header:SetHeight(headerHeight)
    end

    if not shell.borderTop then
        shell.borderTop = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderTop:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.borderTop:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -1, -1)
        shell.borderTop:SetHeight(1)
    end

    if not shell.borderBottom then
        shell.borderBottom = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderBottom:SetPoint("BOTTOMLEFT", frameObject, "BOTTOMLEFT", 1, 1)
        shell.borderBottom:SetPoint("BOTTOMRIGHT", frameObject, "BOTTOMRIGHT", -1, 1)
        shell.borderBottom:SetHeight(1)
    end

    if not shell.borderLeft then
        shell.borderLeft = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderLeft:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 1, -1)
        shell.borderLeft:SetPoint("BOTTOMLEFT", frameObject, "BOTTOMLEFT", 1, 1)
        shell.borderLeft:SetWidth(1)
    end

    if not shell.borderRight then
        shell.borderRight = frameObject:CreateTexture(nil, "BORDER", nil, 7)
        shell.borderRight:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -1, -1)
        shell.borderRight:SetPoint("BOTTOMRIGHT", frameObject, "BOTTOMRIGHT", -1, 1)
        shell.borderRight:SetWidth(1)
    end

    if includeInnerTop and not shell.innerTop then
        shell.innerTop = frameObject:CreateTexture(nil, "BORDER", nil, 6)
        shell.innerTop:SetPoint("TOPLEFT", frameObject, "TOPLEFT", 2, -2)
        shell.innerTop:SetPoint("TOPRIGHT", frameObject, "TOPRIGHT", -2, -2)
        shell.innerTop:SetHeight(1)
    end

    return shell
end

function skin.StyleScrollBar(scrollBar, options)
    if not scrollBar then
        return nil
    end

    options = options or {}

    scrollBar:SetAlpha(options.scrollBarAlpha or 0.85)

    local thumbTexture = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
    if thumbTexture then
        if options.thumbColor then
            skin.ApplyVertexColor(thumbTexture, options.thumbColor)
        end

        thumbTexture:SetAlpha(options.thumbAlpha or 0.95)
    end

    return thumbTexture
end

-- =========================================================
-- Font objects
-- =========================================================

---@class BitForgeFontDef
---@field file   string|nil   Font file path (defaults to STANDARD_TEXT_FONT)
---@field size   number|nil   Point size
---@field flags  string|nil   Outline flags: "", "OUTLINE", or "THICKOUTLINE"
---@field shadow boolean|nil  True to render a 1-pixel drop shadow
---@field color  colorRGBA|nil  Text color (defaults to white)

---@class BitForgeFontVariants
---@field Small               Font
---@field Normal              Font
---@field Large               Font
---@field Huge                Font
---@field SmallOutline        Font
---@field NormalOutline       Font
---@field LargeOutline        Font
---@field HugeOutline         Font
---@field SmallShadow         Font
---@field NormalShadow        Font
---@field LargeShadow         Font
---@field HugeShadow          Font
---@field SmallOutlineShadow  Font
---@field NormalOutlineShadow Font
---@field LargeOutlineShadow  Font
---@field HugeOutlineShadow   Font
UI.Mixins = {}
UI.Fonts = {}

local FONT_SIZES = { Small = 10, Normal = 12, Large = 14, Huge = 20 }
-- CJK fonts generally need to be larger to be legible at the same point size
local isCJK = GetLocale() == "zhCN" or GetLocale() == "zhTW" or GetLocale() == "koKR"
if isCJK then
    for key, value in pairs(FONT_SIZES) do
        FONT_SIZES[key] = value + 1
    end
end

local FONT_COMBINATIONS = {
    { suffix = "",              flags = "",        shadow = false },
    { suffix = "Outline",       flags = "OUTLINE", shadow = false },
    { suffix = "Shadow",        flags = "",        shadow = true },
    { suffix = "OutlineShadow", flags = "OUTLINE", shadow = true },
}

local function CreateFontObject(name, size, flags, shadow)
    local font = CreateFont(name)
    font:SetFont(STANDARD_TEXT_FONT, size, flags)
    font:SetTextColor(1, 1, 1)
    if shadow then
        font:SetShadowOffset(1, -1)
        font:SetShadowColor(0, 0, 0, 1)
    end
    return font
end

for sizeName, sizeVal in pairs(FONT_SIZES) do
    for _, combo in ipairs(FONT_COMBINATIONS) do
        local key = combo.suffix == "" and sizeName or (sizeName .. combo.suffix)
        UI.Fonts[key] = CreateFontObject("BitForgeFont" .. key, sizeVal, combo.flags, combo.shadow)
    end
end

--- Override font settings on one or more variants.  Changes re-apply immediately
--- to existing Font objects.  Keys match BitForgeFontVariants field names.
---@param overrides table<string, BitForgeFontDef>
function UI:SetFonts(overrides)
    for key, def in pairs(overrides) do
        local font = self.Fonts[key]
        if font then
            local curFile, curSize, curFlags = font:GetFont()
            font:SetFont(def.file or curFile, def.size or curSize, def.flags or curFlags)
            local c = def.color
            if c then
                font:SetTextColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
            end
            if def.shadow == true then
                font:SetShadowOffset(1, -1)
                font:SetShadowColor(0, 0, 0, 1)
            elseif def.shadow == false then
                font:SetShadowOffset(0, 0)
                font:SetShadowColor(0, 0, 0, 0)
            end
        end
    end
end

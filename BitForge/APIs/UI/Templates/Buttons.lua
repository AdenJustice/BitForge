local min = math.min

local PixelUtil = PixelUtil

local UI = BitForge.UI
local colors = UI.Colors

-- =========================================================
-- Shared constants
-- =========================================================

local BUTTON_H_PADDING = 48 -- 24 px each side
local PP = UI.GetPixel()
local BACKDROP_CONFIG = {
    bgFile = "Interface/Buttons/WHITE8X8",
    tileSize = 32,
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = PP,
    insets = { left = PP, right = PP, top = PP, bottom = PP },
}
local BORDER_BACKDROP = {
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = PP,
    insets = { left = PP, right = PP, top = PP, bottom = PP },
}

-- =========================================================
-- Shared helpers
-- =========================================================

--- Re-anchor icon and label after any resize.
local function updateLayout(self, width, height)
    local hasIcon = self.Icon ~= nil
    local hasLabel = self.Label ~= nil
    local minSize = min(width, height)

    if hasIcon then self.Icon:ClearAllPoints() end
    if hasLabel then self.Label:ClearAllPoints() end

    if hasIcon and hasLabel then
        local iconSize = minSize - 8
        self.Icon:SetSize(iconSize, iconSize)
        PixelUtil.SetPoint(self.Icon, "LEFT", self, "LEFT", 12, 0)

        self.Label:SetJustifyH("LEFT")
        PixelUtil.SetPoint(self.Label, "LEFT", self.Icon, "RIGHT", 8, 0)
        PixelUtil.SetPoint(self.Label, "RIGHT", self, "RIGHT", -12, 0)
        self.Label:SetPoint("TOP", self, "TOP", 0, 0)
        self.Label:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
    elseif hasIcon then
        local iconSize = minSize - 8
        self.Icon:SetSize(iconSize, iconSize)
        self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0)
    elseif hasLabel then
        self.Label:SetJustifyH("CENTER")
        self.Label:SetAllPoints()
    end
end

-- =========================================================
-- ButtonMixin — MD contained button
-- =========================================================

---@class BitForge.ButtonMixin : Button, BackdropTemplate
local ButtonMixin = {}

do
    ---@param state "NORMAL" | "HOVER" | "DISABLED" | "PUSHED"
    local function UpdateState(self, state)
        local bdBorderColor = colors.edge
        local labelColor = colors.text
        local accentVisibility = false

        if state == "DISABLED" then
            bdBorderColor = colors.bgDisabled
            labelColor = colors.textDisabled
        elseif state == "PUSHED" then
            bdBorderColor = colors.point
            labelColor = colors.point
            if self.Accent then
                accentVisibility = true
                self.Accent:SetVertexColor(colors.point:GetRGB())
            end
        elseif state == "HOVER" then
            bdBorderColor = colors.edgeHover
            labelColor = colors.textHover
            if self.Accent then
                accentVisibility = true
                self.Accent:SetVertexColor(colors.point:GetRGB())
            end
        end

        self:SetBackdropBorderColor(bdBorderColor:GetRGBA())
        if self.Label then
            self.Label:SetTextColor(labelColor:GetRGB())
        end
        if self.Icon then
            self.Icon:SetVertexColor(labelColor:GetRGB())
        end
        if self.Accent then
            self.Accent:SetShown(accentVisibility)
        end
    end

    local function OnEnter(self)
        UpdateState(self, "HOVER")
        if self.tooltipText then
            local r, g, b = colors.textHover:GetRGB()
            GameTooltip:SetOwner(self, self.tooltipAnchor or "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, r, g, b, 1, true)
            GameTooltip:Show()
        end
    end

    local function OnLeave(self)
        UpdateState(self, "NORMAL")
        if self.tooltipText then
            GameTooltip:Hide()
        end
    end

    ---@param hasIcon  boolean?  Whether to create an icon sub-texture.
    ---@param hasLabel boolean?  Whether to create a text label.
    function ButtonMixin:OnLoad(hasIcon, hasLabel)
        assert(hasIcon or hasLabel, "At least one of icon or label must be provided")

        self:SetSize(120, 36)

        self:SetNormalTexture("Interface/Buttons/WHITE8X8")
        self:SetHighlightTexture("Interface/Buttons/WHITE8X8", "ADD")
        self:SetPushedTexture("Interface/Buttons/WHITE8X8")
        self:SetDisabledTexture("Interface/Buttons/WHITE8X8")

        self:GetNormalTexture():SetVertexColor(colors.surface:GetRGBA())
        local r, g, b = colors.point:GetRGB()
        self:GetHighlightTexture():SetVertexColor(r, g, b, .1)
        self:GetPushedTexture():SetVertexColor(colors.surface:GetRGBA())
        self:GetDisabledTexture():SetVertexColor(colors.textDisabled:GetRGBA())

        self:SetBackdrop(BORDER_BACKDROP)
        self:SetBackdropBorderColor(colors.edge:GetRGBA())

        if hasLabel then
            local label = self:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutline")
            label:SetJustifyH("CENTER")
            label:SetJustifyV("MIDDLE")
            label:SetAllPoints()
            self:SetFontString(label)
            self.Label = label
        end

        if hasIcon then
            local icon = self:CreateTexture(nil, "OVERLAY")
            icon:SetSize(16, 16)
            icon:SetPoint("CENTER", self, "CENTER", 0, 0)
            self.Icon = icon
        end

        self:HookScript("OnEnable", function(btn) UpdateState(btn, "NORMAL") end)
        self:HookScript("OnDisable", function(btn) UpdateState(btn, "DISABLED") end)
        self:HookScript("OnEnter", OnEnter)
        self:HookScript("OnLeave", OnLeave)
        self:HookScript("OnMouseDown", function(btn) UpdateState(btn, "PUSHED") end)
        self:HookScript("OnMouseUp", function(btn) UpdateState(btn, "NORMAL") end)
        self:HookScript("OnSizeChanged", updateLayout)

        UpdateState(self, "NORMAL")
    end

    ---@param text string
    function ButtonMixin:SetText(text)
        if not self.Label then
            error("Button does not have a label.", 2)
        end
        self.Label:SetText(text)
        self:SetWidth(self.Label:GetUnboundedStringWidth() + BUTTON_H_PADDING)
    end

    ---@param texture string|number
    function ButtonMixin:SetIcon(texture)
        if not self.Icon then
            error("Button does not have an icon.", 2)
        end
        self.Icon:SetTexture(texture)
    end

    ---@param text   string
    ---@param anchor string?
    function ButtonMixin:SetTooltips(text, anchor)
        self.tooltipText = text
        self.tooltipAnchor = anchor
    end
end

UI.Mixins.Button = ButtonMixin

-- =========================================================
-- CheckButtonMixin — toggle button with border-colour feedback
-- =========================================================
-- For checkbutton, `*Texture` is for tick image
-- So, if you want to use custom images for `tick`, customize `*Texture`s
-- 1) button with only (custom) tick image
-- 2) button with label but tick image (border shows checked status)
-- 3) button with label AND tick image

---@class BitForge.CheckButtonMixin : CheckButton, BackdropTemplate
local CheckButtonMixin = {}
do
    ---@param state "NORMAL" | "HOVER" | "CHECKED" | "DISABLED"
    local function UpdateState(self, state)
        local bdColor = colors.surface
        local bdBorderColor = colors.edge
        local labelColor = colors.text
        local accentVisibility = false

        if state == "DISABLED" then
            bdColor = colors.disabled
            bdBorderColor = colors.bgDisabled
            labelColor = colors.textDisabled
        elseif state == "CHECKED" or state == "HOVER" then
            bdColor = colors.edgeHover
            bdBorderColor = colors.edgeHover
            labelColor = colors.textHover
            accentVisibility = true
            if state == "HOVER" and self.Accent then
                self.Accent:SetVertexColor(colors.point:GetRGB())
            elseif state == "CHECKED" then
                labelColor = colors.point
            end
        end

        self:SetBackdropColor(bdColor:GetRGBA())
        self:SetBackdropBorderColor(bdBorderColor:GetRGBA())
        if self.Label then
            self.Label:SetTextColor(labelColor:GetRGB())
        end
        if self.Accent then
            self.Accent:SetShown(accentVisibility)
        end
    end

    local function UpdateTint(self)
        self:GetNormalTexture():SetVertexColor(colors.text:GetRGBA())
        self:GetCheckedTexture():SetVertexColor(colors.point:GetRGBA())
        self:GetDisabledCheckedTexture():SetVertexColor(colors.textDisabled:GetRGBA())
        self:GetHighlightTexture():SetVertexColor(colors.textHover:GetRGBA())
    end

    local function HookSetChecked(self)
        local flag = self:GetChecked() and "CHECKED" or "NORMAL"
        UpdateState(self, flag)
    end

    local function OnEnter(self)
        if not self:GetChecked() then UpdateState(self, "HOVER") end
        if self.tooltipText then
            local r, g, b = colors.textHover:GetRGB()
            GameTooltip:SetOwner(self, self.tooltipAnchor or "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, r, g, b, 1, true)
            GameTooltip:Show()
        end
    end

    local function OnLeave(self)
        if not self:GetChecked() then UpdateState(self, "NORMAL") end
        if self.tooltipText then GameTooltip:Hide() end
    end

    ---@param hasIcon  boolean?  When true, shows a tick icon for checked state.
    ---@param hasLabel boolean?  When true, shows a text label.
    function CheckButtonMixin:OnLoad(hasIcon, hasLabel)
        assert(hasIcon or hasLabel, "At least one of icon or label must be provided")

        PixelUtil.SetHeight(self, 24, 1)

        self:SetBackdrop(BACKDROP_CONFIG)

        if hasIcon then
            self:SetNormalTexture(UI.GetMedia("unchecked"))
            self:SetCheckedTexture(UI.GetMedia("checked"))
            self:SetDisabledCheckedTexture((UI.GetMedia("checked")))
            self:SetHighlightTexture(UI.GetMedia("checked"), "ADD")
            UpdateTint(self)

            local texNormal = self:GetNormalTexture()
            texNormal:ClearAllPoints()
            texNormal:SetSize(20, 20)
            texNormal:SetPoint("LEFT", self, "LEFT", 0, 0)

            local texChecked = self:GetCheckedTexture()
            texChecked:ClearAllPoints()
            texChecked:SetSize(20, 20)
            texChecked:SetPoint("LEFT", self, "LEFT", 0, 0)

            local texDisabledChecked = self:GetDisabledCheckedTexture()
            texDisabledChecked:ClearAllPoints()
            texDisabledChecked:SetSize(20, 20)
            texDisabledChecked:SetPoint("LEFT", self, "LEFT", 0, 0)

            local texHighlight = self:GetHighlightTexture()
            texHighlight:ClearAllPoints()
            texHighlight:SetSize(20, 20)
            texHighlight:SetPoint("LEFT", self, "LEFT", 0, 0)

            self.hasIcon = true
        else
            self:SetHighlightTexture("")
        end

        if hasLabel then
            local label = self:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutline")
            label:SetJustifyV("MIDDLE")
            label:SetTextColor(1, 1, 1, 1)

            if hasIcon then
                label:SetJustifyH("LEFT")
                label:SetPoint("LEFT", self, "LEFT", 26, 0)
            else
                label:SetJustifyH("CENTER")
                label:SetAllPoints()
            end

            self:SetFontString(label)
            self.Label = label
        end

        if hasIcon and not hasLabel then
            self:SetWidth(24)
        end

        self:HookScript("OnEnter", OnEnter)
        self:HookScript("OnLeave", OnLeave)
        self:HookScript("OnSizeChanged", updateLayout)
        hooksecurefunc(self, "SetChecked", HookSetChecked)

        HookSetChecked(self)
    end

    ---@param text string
    function CheckButtonMixin:SetText(text)
        if not self.Label then
            error("CheckButton does not have a label.", 2)
        end
        self.Label:SetText(text)
        local w = self.Label:GetUnboundedStringWidth()
        self:SetWidth(self.hasIcon and (26 + w + 8) or (w + BUTTON_H_PADDING))
    end

    ---@param texNormal  string|number
    ---@param texChecked string|number
    function CheckButtonMixin:SetIcon(texNormal, texChecked)
        if not self.hasIcon then
            error("CheckButton was not initialised with an icon.", 2)
        end

        self:SetNormalTexture(texNormal)
        self:SetCheckedTexture(texChecked)
        self:SetDisabledCheckedTexture(texChecked)
        self:SetHighlightTexture(texChecked, "ADD")

        UpdateTint(self)
    end

    ---@param text   string
    ---@param anchor string?
    function CheckButtonMixin:SetTooltips(text, anchor)
        self.tooltipText = text
        self.tooltipAnchor = anchor
    end

    --- Register a callback fired whenever the checked state changes via SetChecked.
    ---@param func fun(btn: BitForge.CheckButtonMixin)
    function CheckButtonMixin:HookSetChecked(func)
        hooksecurefunc(self, "SetChecked", func)
    end
end

UI.Mixins.CheckButton = CheckButtonMixin

-- =========================================================
-- Factories
-- =========================================================

--- Create an MD contained button.
---@param name   string?
---@param parent any
---@param icon   string|number?  Texture path or FileDataID for the icon.
---@param text   string?
---@return BitForge.ButtonMixin
function UI.CreateButton(name, parent, icon, text)
    assert(icon or (text and text ~= ""), "At least one of icon or text must be provided")

    ---@class BitForge.ButtonMixin
    local btn = CreateFrame("Button", name, parent or UIParent, "BackdropTemplate")
    Mixin(btn, ButtonMixin)
    btn:OnLoad(icon ~= nil, text ~= nil and text ~= "")

    if icon then btn:SetIcon(icon) end
    if text and text ~= "" then btn:SetText(text) end

    return btn
end

--- Create an MD toggle (checkbox-style) button.
---@param name        string?
---@param parent      any
---@param text        string?
---@param hasIcon     boolean?
---@param iconNormal  string|number?
---@param iconChecked string|number?
---@return BitForge.CheckButtonMixin
function UI.CreateCheckButton(name, parent, text, hasIcon, iconNormal, iconChecked)
    ---@class BitForge.CheckButtonMixin
    local cb = CreateFrame("CheckButton", name, parent or UIParent, "BackdropTemplate")
    Mixin(cb, CheckButtonMixin)
    cb:OnLoad(hasIcon, text ~= nil and text ~= "")

    if hasIcon and iconNormal and iconChecked then cb:SetIcon(iconNormal, iconChecked) end
    if text and text ~= "" then cb:SetText(text) end

    return cb
end

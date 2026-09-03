local ipairs = ipairs
local pairs = pairs

local PixelUtil = PixelUtil

local UI = BitForge.UI
---@type BitForge.UI.Colors
local colors = UI.Colors

-- accent = which edge gets the 2-px active line
-- open   = the content-adjacent edge (no border drawn)
-- sides  = the two edges that frame the tab button

local EDGE_CONFIG = {
    bottom = { accent = "BOTTOM", open = "TOP", sides = { "LEFT", "RIGHT" } },
    top = { accent = "TOP", open = "BOTTOM", sides = { "LEFT", "RIGHT" } },
    left = { accent = "TOP", open = "RIGHT", sides = { "LEFT", "BOTTOM" } },
    right = { accent = "TOP", open = "LEFT", sides = { "RIGHT", "BOTTOM" } },
}

local function AnchorIndicator(accent, button, edge)
    accent:ClearAllPoints()
    if edge == "BOTTOM" then
        accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        accent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    elseif edge == "TOP" then
        accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        accent:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    elseif edge == "LEFT" then
        accent:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        accent:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    elseif edge == "RIGHT" then
        accent:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
        accent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    end
end

local function AnchorBorders(btn)
    btn.BorderTop:ClearAllPoints()
    btn.BorderTop:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.BorderTop:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)

    btn.BorderBottom:ClearAllPoints()
    btn.BorderBottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn.BorderBottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)

    btn.BorderLeft:ClearAllPoints()
    btn.BorderLeft:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    btn.BorderLeft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)

    btn.BorderRight:ClearAllPoints()
    btn.BorderRight:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    btn.BorderRight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
end

---@class BitForge.TabButtonMixin : CheckButton
local TabButtonMixin = {}

do
    ---@param state "NORMAL"|"CHECKED"|"HOVER"|"DISABLED"
    local function UpdateState(self, state)
        local cfg = EDGE_CONFIG[self._position] or EDGE_CONFIG.bottom
        local borderMap = {
            TOP = self.BorderTop,
            BOTTOM = self.BorderBottom,
            LEFT = self.BorderLeft,
            RIGHT = self.BorderRight,
        }
        local bgColor = colors.surface
        local accentVisible = false

        for _, tex in pairs(borderMap) do tex:Hide() end

        if state == "CHECKED" then
            bgColor = colors.bg
            accentVisible = true
            for _, edge in ipairs(cfg.sides) do
                local border = borderMap[edge]
                border:Show()
                border:SetVertexColor(colors.point:GetRGBA())
            end
        elseif state == "HOVER" then
            bgColor = colors.bg
            accentVisible = true
        elseif state == "DISABLED" then
            bgColor = colors.bgDisabled
        end

        self.Bg:SetVertexColor(bgColor:GetRGBA())
        self.Accent:SetShown(accentVisible)
    end

    local function HookSetChecked(self)
        local flag = self:GetChecked() and "CHECKED" or "NORMAL"
        UpdateState(self, flag)
    end

    function TabButtonMixin:OnLoad()
        self:SetSize(80, 32)

        local bg = self:CreateTexture(nil, "BACKGROUND")
        bg:SetTexture("Interface/Buttons/WHITE8X8")
        bg:SetAllPoints()
        self.Bg = bg

        local function makeBorder(layer)
            local tex = self:CreateTexture(nil, layer or "ARTWORK")
            tex:SetTexture("Interface/Buttons/WHITE8X8")
            tex:Hide()
            return tex
        end
        self.BorderTop = makeBorder()
        self.BorderBottom = makeBorder()
        self.BorderLeft = makeBorder()
        self.BorderRight = makeBorder()

        PixelUtil.SetHeight(self.BorderTop, 1, 1)
        PixelUtil.SetHeight(self.BorderBottom, 1, 1)
        PixelUtil.SetWidth(self.BorderLeft, 1, 1)
        PixelUtil.SetWidth(self.BorderRight, 1, 1)

        local accent = self:CreateTexture(nil, "OVERLAY")
        accent:SetTexture("Interface/Buttons/WHITE8X8")
        PixelUtil.SetHeight(accent, 2, 1)
        accent:Hide()
        self.Accent = accent

        local label = self:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutline")
        label:SetJustifyH("CENTER")
        label:SetJustifyV("MIDDLE")
        label:SetTextColor(1, 1, 1, 1)
        PixelUtil.SetPoint(label, "TOPLEFT", self, "TOPLEFT", 4, -4)
        PixelUtil.SetPoint(label, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 4)
        self:SetFontString(label)
        self.Label = label

        self._position = "bottom"

        AnchorIndicator(self.Accent, self, "BOTTOM")
        AnchorBorders(self)

        self:SetScript("OnEnter", function(f) UpdateState(f, "HOVER") end)
        self:SetScript("OnLeave", function(f) UpdateState(f, "NORMAL") end)
        hooksecurefunc(self, "SetChecked", HookSetChecked)

        HookSetChecked(self)
    end

    --- Inform the button which side of the content frame it sits on.
    --- EDGE_CONFIG maps that to the accented and open edges -- a left or right
    --- bar accents the top edge, not its own.
    ---@param pos "bottom"|"top"|"left"|"right"
    function TabButtonMixin:SetTabPosition(pos)
        self._position = pos or "bottom"
        local cfg = EDGE_CONFIG[self._position] or EDGE_CONFIG.bottom

        AnchorIndicator(self.Accent, self, cfg.accent)
        HookSetChecked(self)
    end
end

UI.Mixins.TabButton = TabButtonMixin

---@class BitForge.TabBarMixin : Frame
---@field _tabs { id: any, button: BitForge.TabButtonMixin }[]
---@field _tabMap table<any, BitForge.TabButtonMixin>
---@field _selected any
---@field _onChange fun(id: any)|nil
---@field _tabW number
---@field _tabH number
---@field _position "bottom"|"top"|"left"|"right"
local TabBarMixin = {}

function TabBarMixin:OnLoad()
    self._tabs = {}   -- ordered list of { id, button }
    self._tabMap = {} -- id → button
    self._selected = nil
    self._onChange = nil
    self._tabW = 80
    self._tabH = 32
    self._position = "bottom"
end

--- Add a tab to the bar and return its CheckButton frame.
---@param id    any     Unique identifier.
---@param label string  Text shown on the button.
---@return CheckButton
function TabBarMixin:AddTab(id, label)
    local btn = CreateFrame("CheckButton", nil, self)
    Mixin(btn, TabButtonMixin)
    btn:OnLoad()
    btn:SetSize(self._tabW, self._tabH)

    local prevEntry = self._tabs[#self._tabs]
    if prevEntry then
        btn:SetPoint("TOPLEFT", prevEntry.button, "TOPRIGHT", 0, 0)
    else
        btn:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    end

    btn:SetText(label)
    btn:SetTabPosition(self._position)

    local bar = self
    btn:HookScript("OnClick", function() bar:SetSelectedTab(id) end)

    self._tabs[#self._tabs + 1] = { id = id, button = btn }
    self._tabMap[id] = btn

    return btn
end

--- Propagate the position hint to all existing tab buttons.
---@param pos "bottom"|"top"|"left"|"right"
function TabBarMixin:SetPosition(pos)
    self._position = pos or "bottom"
    for _, entry in ipairs(self._tabs) do
        entry.button:SetTabPosition(self._position)
    end
end

--- Select a tab by id and fire the onChange callback.
---@param id any
function TabBarMixin:SetSelectedTab(id)
    self._selected = id
    for _, entry in ipairs(self._tabs) do
        local isSelected = (entry.id == id)
        entry.button:SetChecked(isSelected)
    end
    if self._onChange then
        self._onChange(id)
    end
end

--- Register a callback fired when the selected tab changes.
---@param fn fun(id: any)
function TabBarMixin:SetOnChange(fn)
    self._onChange = fn
end

--- Set default dimensions for future AddTab calls (does not resize existing tabs).
---@param w number
---@param h number
function TabBarMixin:SetTabSize(w, h)
    self._tabW = w or self._tabW
    self._tabH = h or self._tabH
end

UI.Mixins.TabBar = TabBarMixin

---@param parent any
---@return BitForge.TabBarMixin
function UI.CreateTabBar(parent)
    ---@class BitForge.TabBarMixin
    local bar = CreateFrame("Frame", nil, parent)
    Mixin(bar, TabBarMixin)
    bar:OnLoad()
    return bar
end

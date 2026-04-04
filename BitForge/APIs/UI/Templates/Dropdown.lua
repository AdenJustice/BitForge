local ipairs = ipairs
local insert = table.insert
local concat = table.concat

local UI = BitForge.UI
local colors = UI.Colors

local DropdownButtonMixin = DropdownButtonMixin

-- =========================================================
-- Constants
-- =========================================================

local DROPDOWN_HEIGHT = 32
local ARROW_SIZE = 14
local H_PADDING = 10

local BORDER_BACKDROP = {
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = UI.GetPixel(),
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- =========================================================
-- DropdownMixin — MD-style dropdown backed by DropdownButtonMixin
-- =========================================================

---@class BitForge.DropdownMixin : Button, BackdropTemplate, DropdownButtonMixin
local DropdownMixin = CreateFromMixins(DropdownButtonMixin)

function DropdownMixin:OnLoad()
    -- Fields read by DropdownButtonMixin.OnLoad_Intrinsic for menu anchoring.
    self.menuPoint = "TOPLEFT"
    self.menuRelativePoint = "BOTTOMLEFT"
    self.menuPointX = 0
    self.menuPointY = 0

    DropdownButtonMixin.OnLoad_Intrinsic(self)

    self:SetSize(160, DROPDOWN_HEIGHT)
    self:EnableMouseWheel(true) -- OnLoad_Intrinsic disables it; re-enable for rotation

    -- Backdrop / border
    local P = colors
    self:SetBackdrop(BORDER_BACKDROP)
    self:SetBackdropBorderColor(P.edge.r, P.edge.g, P.edge.b, P.edge.a)

    -- Background fill
    local bg = self:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface/Buttons/WHITE8X8")
    bg:SetAllPoints()
    bg:SetVertexColor(P.bg.r, P.bg.g, P.bg.b, P.bg.a)
    self.Bg = bg

    -- Selected-item label
    local label = self:CreateFontString(nil, "OVERLAY", "BitForgeFontNormalOutline")
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetTextColor(P.text.r, P.text.g, P.text.b, P.text.a)
    label:SetPoint("LEFT", self, "LEFT", H_PADDING, 0)
    label:SetPoint("RIGHT", self, "RIGHT", -(ARROW_SIZE + H_PADDING + 6), 0)
    label:SetPoint("TOP", self, "TOP", 0, 0)
    label:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
    self.Label = label

    -- Arrow indicator
    local arrow = self:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow:SetPoint("RIGHT", self, "RIGHT", -H_PADDING, 0)
    arrow:SetTexture(UI.GetMedia("arrow_down"))
    self.Arrow = arrow

    -- DropdownButtonMixin intrinsic scripts must be wired manually in pure-Lua contexts.
    self:HookScript("OnMouseDown", DropdownButtonMixin.OnMouseDown_Intrinsic)
    self:HookScript("OnMouseWheel", DropdownButtonMixin.OnMouseWheel_Intrinsic)

    -- Hover border highlight
    self:HookScript("OnEnter", function(f)
        local c = colors.point
        f:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
    end)
    self:HookScript("OnLeave", function(f)
        if not f:IsMenuOpen() then
            local c = colors.edge
            f:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
        end
    end)
end

--- Called by DropdownButtonMixin when the selection changes.
--- Displays a comma-separated list of selected option texts in the label.
function DropdownMixin:UpdateToMenuSelections(menuDescription, selections)
    local text = self._placeholder or ""
    if selections and #selections > 0 then
        local parts = {}
        for _, desc in ipairs(selections) do
            local t = desc.text
            if t then
                insert(parts, t)
            end
        end
        if #parts > 0 then
            text = concat(parts, ", ")
        end
    end
    self.Label:SetText(text)
end

function DropdownMixin:OnMenuOpened(menu)
    DropdownButtonMixin.OnMenuOpened(self, menu)
    self.Arrow:SetTexture(UI.GetMedia("arrow_up"))
    local c = colors.point
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

function DropdownMixin:OnMenuClosed(menu)
    DropdownButtonMixin.OnMenuClosed(self, menu)
    self.Arrow:SetTexture(UI.GetMedia("arrow_down"))
    local c = self:IsMouseOver() and colors.point or colors.edge
    self:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
end

--- Placeholder text shown when nothing is selected.
---@param text string
function DropdownMixin:SetPlaceholder(text)
    self._placeholder = text
    local _, _, selections = self:CollectSelectionData()
    if not selections or #selections == 0 then
        self.Label:SetText(text)
    end
end

UI.Mixins.Dropdown = DropdownMixin

-- =========================================================
-- Factory
-- =========================================================

--- Create a styled dropdown widget.
---
--- Example usage:
---   local dd = UI.CreateDropdown(parent, "Select an option")
---   dd:SetupMenu(function(dropdown, root)
---     root:CreateRadio("Option A", getter, setter, "A")
---     root:CreateRadio("Option B", getter, setter, "B")
---   end)
---
---@param parent      any
---@param placeholder string?
---@return BitForge.DropdownMixin
function UI.CreateDropdown(parent, placeholder)
    ---@class BitForge.DropdownMixin
    local dropdown = CreateFrame("Button", nil, parent, "BackdropTemplate")
    Mixin(dropdown, DropdownMixin)
    dropdown:OnLoad()
    if placeholder then
        dropdown:SetPlaceholder(placeholder)
    end
    return dropdown
end

local CreateFrame = CreateFrame
local Minimap = Minimap
local GameTooltip = GameTooltip
local cos = math.cos
local sin = math.sin
local rad = math.rad
local ipairs = ipairs

-- =========================================================
-- BitForge.MinimapButton
-- =========================================================

local entries = {}

--- Register a module toggle entry in the minimap context menu.
---@param entry { label: string, icon: string, onToggle: function }  icon is reserved for future menu icon support
function BitForge.RegisterMinimapButton(entry)
    entries[#entries + 1] = entry
end

local btn = CreateFrame("Button", "BitForgeMinimapBtn", Minimap)
btn:SetSize(32, 32)
btn:SetFrameStrata("MEDIUM")
btn:SetFrameLevel(8)

-- TODO: replace with a real BitForge suite icon when available
local icon = btn:CreateTexture(nil, "ARTWORK")
icon:SetSize(18, 18)
icon:SetPoint("CENTER")
icon:SetTexture("Interface\\Icons\\Trade_Engineering")
icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")

local border = btn:CreateTexture(nil, "OVERLAY")
border:SetSize(50, 50)
border:SetPoint("TOPLEFT", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function PositionOnMinimap()
    local r = rad(45)
    local x = cos(r) * 80
    local y = sin(r) * 80
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end
PositionOnMinimap()

btn:RegisterForClicks("AnyUp")
btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        MenuUtil.CreateContextMenu(self, function(owner, rootDescription)
            rootDescription:CreateTitle("BitForge")
            for _, entry in ipairs(entries) do
                rootDescription:CreateButton(entry.label, entry.onToggle)
                -- entry.icon reserved for future menu icon support
            end
        end)
    end
end)
btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("BitForge", 1, 1, 1, 1)
    GameTooltip:AddLine("Left-click for options", 1, 1, 1)
    GameTooltip:Show()
end)
btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

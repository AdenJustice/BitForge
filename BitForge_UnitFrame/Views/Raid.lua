local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_Raid", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorClass    = true
    self.Health.colorReaction = true
    H.ApplyPowerBar(self)
    self.Power.showIfHealer = true
    H.ApplyGroupBorder(self)
    H.ApplyPhaseIndicator(self)
end)

-- Three layout tiers that activate based on current raid size.
--   small:  1-20 members  — 4 columns x 5 rows, 100x35 per frame
--   medium: 21-30 members — 6 columns x 5 rows,  90x30 per frame
--   large:  31-40 members — 8 columns x 5 rows,  80x25 per frame
local tiers = {
    { key = "raid_small",  name = "BitForge_RaidHeader_Small",  maxColumns = 4, unitsPerColumn = 5, unitWidth = 100, unitHeight = 35 },
    { key = "raid_medium", name = "BitForge_RaidHeader_Medium", maxColumns = 6, unitsPerColumn = 5, unitWidth = 90,  unitHeight = 30 },
    { key = "raid_large",  name = "BitForge_RaidHeader_Large",  maxColumns = 8, unitsPerColumn = 5, unitWidth = 80,  unitHeight = 25 },
}

local headers = {}

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_Raid")

    for _, tier in ipairs(tiers) do
        local h = self:SpawnHeader(tier.name, nil,
            "showRaid", true,
            "showParty", false,
            "maxColumns", tier.maxColumns,
            "unitsPerColumn", tier.unitsPerColumn,
            "columnSpacing", 5,
            "point", "TOP",
            "xOffset", 0,
            "yOffset", -5,
            "columnAnchorPoint", "LEFT",
            "unitWidth", tier.unitWidth,
            "unitHeight", tier.unitHeight
        )
        h:Hide()
        H.SetupMovable(h, tier.key)
        headers[tier.key] = h
    end
end)

-- ── View interface for the controller ────────────────────────────────────────

local function SetHeaderActive(header, active)
    if active then
        header:Show()
        for _, child in ipairs({ header:GetChildren() }) do
            if child.Enable then child:Enable() end
        end
    else
        for _, child in ipairs({ header:GetChildren() }) do
            if child.Disable then child:Disable() end
        end
        header:Hide()
    end
end

ns.RaidView = {
    SetActiveTier = function(newKey)
        for _, tier in ipairs(tiers) do
            SetHeaderActive(headers[tier.key], tier.key == newKey)
        end
    end,
    HideAll = function()
        for _, h in pairs(headers) do SetHeaderActive(h, false) end
    end,
}

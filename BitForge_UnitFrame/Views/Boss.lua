local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_Boss", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorReaction = true
    H.ApplyPowerBar(self)
    self.Power.alwaysShow = true
end)

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_Boss")

    for i = 1, 5 do
        local unit = "boss" .. i
        local f = self:Spawn(unit, "BitForge_BossFrame" .. i)
        f:SetSize(200, 40)
        H.SetupMovable(f, unit)
        -- Show only while the boss unit slot is occupied.
        RegisterAttributeDriver(f, "state-visibility", "[@boss" .. i .. ",exists] show; hide")
    end
end)

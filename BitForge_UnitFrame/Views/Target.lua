local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_Target", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorClass    = true
    self.Health.colorReaction = true
    H.ApplyPowerBar(self)
    self.Power.showIfBoss = true
end)

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_Target")
    local f = self:Spawn("target", "BitForge_TargetFrame")
    f:SetSize(200, 40)
    H.SetupMovable(f, "target")
end)

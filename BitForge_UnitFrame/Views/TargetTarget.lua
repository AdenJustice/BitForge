local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_TargetTarget", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorClass    = true
    self.Health.colorReaction = true
    H.ApplyPowerBar(self)
    self.Power.showIfHealer = true
end)

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_TargetTarget")
    local f = self:Spawn("targettarget", "BitForge_TargetTargetFrame")
    f:SetSize(150, 30)
    H.SetupMovable(f, "targettarget")
end)

local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_Focus", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorClass    = true
    self.Health.colorReaction = true
    H.ApplyPowerBar(self)
    self.Power.showIfBoss   = true
    self.Power.showIfHealer = true
end)

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_Focus")
    local f = self:Spawn("focus", "BitForge_FocusFrame")
    f:SetSize(200, 40)
    H.SetupMovable(f, "focus")
end)

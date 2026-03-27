local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_Pet", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorHealth = true
    H.ApplyPowerBar(self)
    self.Power.showIfHealer = true
end)

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_Pet")
    local f = self:Spawn("pet", "BitForge_PetFrame")
    f:SetSize(150, 30)
    H.SetupMovable(f, "pet")
end)

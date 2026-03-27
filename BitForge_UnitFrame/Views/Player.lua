local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_Player", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorClass    = true
    self.Health.colorReaction = true
end)

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_Player")
    local f = self:Spawn("player", "BitForge_PlayerFrame")
    f:SetSize(200, 40)
    H.SetupMovable(f, "player")
end)

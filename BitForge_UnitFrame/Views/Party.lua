local _, ns = ...
local oUF   = _G["oUF"]
local H     = ns.Helpers

oUF:RegisterStyle("BitForge_Party", function(self, unit)
    H.ApplyBaseStyle(self)
    self.Health.colorClass    = true
    self.Health.colorReaction = true
    H.ApplyPowerBar(self)
    self.Power.showIfHealer = true
    H.ApplyGroupBorder(self)
    H.ApplyPhaseIndicator(self)
end)

oUF:Factory(function(self)
    if not ns.Model.GetUnitFramesEnabled() then return end
    self:SetActiveStyle("BitForge_Party")
    local party = self:SpawnHeader("BitForge_PartyHeader", nil,
        "showParty", true,
        "showRaid", false,
        "showSolo", false,
        "point", "TOP",
        "xOffset", 0,
        "yOffset", -5,
        "unitWidth", 200,
        "unitHeight", 40
    )
    H.SetupMovable(party, "party")
    -- Visible only in a party that has not formed into a raid group.
    RegisterAttributeDriver(party, "state-visibility", "party,noraid")
end)

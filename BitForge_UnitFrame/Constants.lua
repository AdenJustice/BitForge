local _, ns = ...

ns.TEXTURE = "Interface/AddOns/BitForge_UnitFrame/Assets/Textures/statusbar"

ns.DB_DEFAULTS = {
    char = {
        positions  = {},
        unitframes = true,
        classpanel = true,
    },
}

-- Default anchor positions per unit.
-- relativeFrame is stored as a string and resolved at runtime via _G[name].
ns.FRAME_DEFAULTS = {
    player       = { "TOPRIGHT", "UIParent", "TOPRIGHT", -200, -200 },
    target       = { "TOPLEFT", "UIParent", "TOPLEFT", 200, -200 },
    focus        = { "CENTER", "UIParent", "CENTER", -200, -260 },
    targettarget = { "CENTER", "UIParent", "CENTER", 200, -260 },
    pet          = { "CENTER", "UIParent", "CENTER", -200, -320 },
    party        = { "TOPLEFT", "UIParent", "TOPLEFT", 50, -200 },
    raid_small   = { "TOPLEFT", "UIParent", "TOPLEFT", 50, -200 },
    raid_medium  = { "TOPLEFT", "UIParent", "TOPLEFT", 50, -200 },
    raid_large   = { "TOPLEFT", "UIParent", "TOPLEFT", 50, -200 },
    boss1        = { "RIGHT", "UIParent", "RIGHT", -50, 160 },
    boss2        = { "RIGHT", "UIParent", "RIGHT", -50, 110 },
    boss3        = { "RIGHT", "UIParent", "RIGHT", -50, 60 },
    boss4        = { "RIGHT", "UIParent", "RIGHT", -50, 10 },
    boss5        = { "RIGHT", "UIParent", "RIGHT", -50, -40 },
}

local _, ns     = ...

-- Visual config
ns.BTN_SIZE     = 36             -- action button width/height (pixels)
ns.BTN_PADDING  = 2              -- gap between adjacent buttons (pixels)
ns.ICON_ZOOM    = 0.06           -- icon crop factor (0 = no crop)
ns.BORDER_SIZE  = 1              -- border pixel thickness (0 = disabled)
ns.BORDER_COLOR = { 0, 0, 0, 1 } -- border RGBA

-- Bar definitions: Blizzard internals — do not change.
-- isStance / isPetBar: reuse Blizzard buttons instead of creating new ones.
-- slotOffset: first action slot for this bar (0-indexed into the 120-slot pool).
ns.BAR_DEFS     = {
    { key = "MainBar",   count = 12, blizzBtnPrefix = "ActionButton",              blizzFrame = "MainActionBar",       slotOffset = 0 },
    { key = "Bar2",      count = 12, blizzBtnPrefix = "MultiBarBottomLeftButton",  blizzFrame = "MultiBarBottomLeft",  slotOffset = 60 },
    { key = "Bar3",      count = 12, blizzBtnPrefix = "MultiBarBottomRightButton", blizzFrame = "MultiBarBottomRight", slotOffset = 48 },
    { key = "Bar4",      count = 12, blizzBtnPrefix = "MultiBarRightButton",       blizzFrame = "MultiBarRight",       slotOffset = 24 },
    { key = "Bar5",      count = 12, blizzBtnPrefix = "MultiBarLeftButton",        blizzFrame = "MultiBarLeft",        slotOffset = 36 },
    { key = "Bar6",      count = 12, blizzBtnPrefix = "MultiBar5Button",           blizzFrame = "MultiBar5",           slotOffset = 144 },
    { key = "Bar7",      count = 12, blizzBtnPrefix = "MultiBar6Button",           blizzFrame = "MultiBar6",           slotOffset = 156 },
    { key = "Bar8",      count = 12, blizzBtnPrefix = "MultiBar7Button",           blizzFrame = "MultiBar7",           slotOffset = 168 },
    { key = "StanceBar", count = 10, blizzBtnPrefix = "StanceButton",              blizzFrame = "StanceBar",           isStance = true },
    { key = "PetBar",    count = 10, blizzBtnPrefix = "PetActionButton",           blizzFrame = "PetActionBar",        isPetBar = true },
}

ns.BAR_LOOKUP   = {}
for _, def in ipairs(ns.BAR_DEFS) do
    ns.BAR_LOOKUP[def.key] = def
end

-- WoW keybind action name prefix per bar.
ns.BINDING_PREFIX = {
    MainBar   = "ACTIONBUTTON",
    Bar2      = "MULTIACTIONBAR1BUTTON",
    Bar3      = "MULTIACTIONBAR2BUTTON",
    Bar4      = "MULTIACTIONBAR3BUTTON",
    Bar5      = "MULTIACTIONBAR4BUTTON",
    Bar6      = "MULTIACTIONBAR5BUTTON",
    Bar7      = "MULTIACTIONBAR6BUTTON",
    Bar8      = "MULTIACTIONBAR7BUTTON",
    StanceBar = "SHAPESHIFTBUTTON",
    PetBar    = "BONUSACTIONBUTTON",
}

-- DB defaults — passed to BitForge:AllocateModuleDB.
-- count/rows/point/x/y per bar. No "enabled" field — visibility is CVar-driven.
-- All layout config is per-character (each alt can have a different bar layout).
ns.DB_DEFAULTS = {
    char = {
        MainBar   = { count = 12, rows = 1, point = "BOTTOM", x = 0, y = 50 },
        Bar2      = { count = 12, rows = 1, point = "BOTTOM", x = 0, y = 92 },
        Bar3      = { count = 12, rows = 1, point = "BOTTOM", x = 0, y = 134 },
        Bar4      = { count = 12, rows = 1, point = "RIGHT", x = -4, y = 0 },
        Bar5      = { count = 12, rows = 1, point = "LEFT", x = 4, y = 0 },
        Bar6      = { count = 12, rows = 1, point = "BOTTOM", x = 0, y = 176 },
        Bar7      = { count = 12, rows = 1, point = "BOTTOM", x = 0, y = 218 },
        Bar8      = { count = 12, rows = 1, point = "BOTTOM", x = 0, y = 260 },
        StanceBar = { count = 10, rows = 1, point = "BOTTOM", x = -300, y = 50 },
        PetBar    = { count = 10, rows = 1, point = "BOTTOM", x = 300, y = 50 },
    },
}

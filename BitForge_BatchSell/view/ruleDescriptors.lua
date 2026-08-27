---@class BitForge.BatchSell
local ns = select(2, ...)

---@class BitForge.BatchSell.View
local view = ns.view

---@class BitForge.BatchSell.Enum
local enum = ns.enum

-- Eight subclasses carry a stored key; four of those also carry lastExpansion.
-- Generated rather than typed, so a subclass gaining or losing a column in
-- DB_DEFAULTS surfaces as a test failure rather than a silent mismatch.
--
-- These carry no `name`: view/ruleControls.lua draws the eight subclasses as
-- eight menus, naming each row from sub:<subclassID> and each menu entry from
-- option:<key>, so twenty-eight settings: labels would be twenty-eight strings
-- nobody reads.

-- keepForDisenchant's own option list, worded about what a disenchant
-- YIELDS rather than about the item's own age -- unlike SPARE_OPTIONS
-- (view/ruleControls.lua), whose spare: labels are worded about the item's
-- expansion and are exactly what this setting must not say. Same stored
-- values as SPARE_OPTIONS (CURRENT/ALL/NONE match model/rules.lua's SPARE
-- table), only the labels differ.
local MATERIALS_OPTIONS = {
    { value = "CURRENT", labelKey = "materials:current" },
    { value = "ALL",     labelKey = "materials:all" },
    { value = "NONE",    labelKey = "materials:none" },
}

local CONSUMABLE_SUBCLASSES = { 0, 1, 2, 3, 5, 7, 8, 9 }
local CONSUMABLE_LAST = { [1] = true, [2] = true, [3] = true, [5] = true }
local CONSUMABLE_COLUMNS = { "current", "recipesNow", "recipesOld" }

local consumableControls = {}
for _, subclass in ipairs(CONSUMABLE_SUBCLASSES) do
    for _, column in ipairs(CONSUMABLE_COLUMNS) do
        consumableControls[#consumableControls + 1] =
            { section = "consumables", subclass = subclass, key = column, kind = "check" }
    end
    if CONSUMABLE_LAST[subclass] then
        consumableControls[#consumableControls + 1] =
            { section = "consumables", subclass = subclass, key = "lastExpansion", kind = "check" }
    end
end

-- Data, not a builder. A test reads this without running any of it, which is
-- what lets the completeness test need none of the frame stubs the window does.
--
-- Built from DB_DEFAULTS outward, not from the wireframe inward: its coverage
-- is checked against the defaults directly, not against what the wireframe
-- happens to draw.
--
-- Each CONTROL carries its own (section, key) rather than the criterion
-- carrying one. Weapons & Armor is why: seven of its controls are rules.gear and
-- the eighth is rules.armor.sellRelics, and there is no separate Armor row.
---@class BitForge.BatchSell.View.RuleDescriptors
local ruleDescriptors = {
    -- Every Item, in cascade order. Six of the nine carry no control at all.
    { key = "temp",    group = "cross", locked = true, controls = {} },
    { key = "black",   group = "cross", locked = true, controls = {} },
    { key = "gates",   group = "cross", locked = true, controls = {} },
    { key = "white",   group = "cross", locked = true, controls = {} },
    { key = "tempIn",  group = "cross", locked = true, controls = {} },
    { key = "junk",    group = "cross", controls = {
        { section = "junk", key = "sell", kind = "check", name = "sellJunk" },
    } },
    { key = "epic",    group = "cross", locked = true, controls = {} },
    { key = "reagent", group = "cross", controls = {
        { section = "reagents", key = "keep", kind = "check", name = "keepUsedReagents" },
        { section = "reagents", key = "currentExpansionOnly", kind = "check",
          name = "reagentsCurrentOnly" },
    } },
    { key = "cosmetic", group = "cross", controls = {
        { section = "cosmetics", key = "keepUncollectedCosmetic", kind = "check",
          name = "keepUncollectedCosmetic" },
    } },

    -- By Item Type. One row per criterion, which is one row per item class
    -- everywhere except gear, which is two classes judged by one function
    -- against one settings block.
    { key = "consumables", group = "class", controls = consumableControls },
    { key = "bags",        group = "class", locked = true, controls = {} },
    { key = "gear",        group = "class", controls = {
        -- Both ranges start at 0 rather than at the step: 0 is a real setting
        -- on each -- no tolerance, or no quality credit -- not an off-state.
        { section = "gear", key = "margin",             kind = "slider",   name = "margin",
          min = 0, max = 30, step = 2 },
        -- Not 0-32 in item levels: the position above 30 is the always-keep
        -- one, drawn as a word by the readout and read by compareToSlot as an
        -- unbounded step.
        { section = "gear", key = "qualityMargin",      kind = "slider",   name = "qualityMargin",
          min = 0, max = enum.QUALITY_MARGIN_ALWAYS, step = 2,
          topName = "qualityMarginAlways" },
        { section = "gear", key = "keepForDisenchant",  kind = "dropdown", name = "keepForDisenchant",
          options = MATERIALS_OPTIONS },
        { section = "gear", key = "spareBindOnAccount", kind = "dropdown", name = "spareBindOnAccount" },
        { section = "gear", key = "spareBindOnEquip",   kind = "dropdown", name = "spareBindOnEquip" },
        -- Armor only. There is no weapon equivalent and no armor copy of
        -- anything above it.
        { section = "armor", key = "sellRelics", kind = "check", name = "sellRelics" },
    } },
    { key = "gems", group = "class", controls = {
        { section = "gems", key = "current",            kind = "check", name = "gemsCurrent" },
        { section = "gems", key = "recipesNow",         kind = "check", name = "gemsRecipesNow" },
        { section = "gems", key = "recipesOld",         kind = "check", name = "gemsRecipesOld" },
        { section = "gems", key = "keepArtifactRelics", kind = "check", name = "keepArtifactRelics" },
    } },
    { key = "tradeGoods", group = "class", controls = {
        -- One key, one control. KIND.professions enumerates Enum.Profession
        -- itself -- fifteen entries, including FirstAid and Archaeology,
        -- which the shipped reagent catalogue currently spares nothing for
        -- but a live profession scan can still set.
        { section = "tradeGoods", key = "professions", kind = "professions", name = "spareProfessions" },
    } },
    { key = "enhancements", group = "class", controls = {
        { section = "enhancements", key = "keepLastExpansion", kind = "check",
          name = "enhancementsKeepLast" },
    } },
    { key = "recipes", group = "class", controls = {
        { section = "recipes", key = "keepLearnable", kind = "check", name = "keepLearnable" },
        { section = "recipes", key = "keepTradeable", kind = "check", name = "keepTradeableRecipes" },
    } },
    { key = "misc", group = "class", controls = {
        { section = "misc", key = "sellCollectedMounts", kind = "check", name = "sellCollectedMounts" },
        { section = "misc", key = "sellCollectedToys",   kind = "check", name = "sellCollectedToys" },
        { section = "misc", key = "sellPets",            kind = "check", name = "sellCollectedPets" },
        { section = "misc", key = "sellHoliday",         kind = "check", name = "sellHoliday" },
        { section = "misc", key = "sellMountEquipment",  kind = "check", name = "sellMountEquipment" },
    } },
    { key = "profession", group = "class", locked = true, controls = {} },
    { key = "housing", group = "class", controls = {
        { section = "housing", key = "sellCollectedDecor", kind = "check", name = "sellCollectedDecor" },
        { section = "housing", key = "keepTradeableDyes",  kind = "check", name = "keepTradeableDyes" },
    } },
    -- Implemented by NOT being in CLASS_RULES, which is also how whatever class
    -- Blizzard adds next lands here.
    { key = "none", group = "class", locked = true, controls = {} },
}

view.ruleDescriptors = ruleDescriptors

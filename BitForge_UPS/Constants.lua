local _, ns = ...

ns.Constants = {}
local Constants = ns.Constants

-- Ordered WoW expansions for UI display
Constants.EXPANSIONS = {
    { id = 0,  key = "classic" },
    { id = 1,  key = "tbc" },
    { id = 2,  key = "wotlk" },
    { id = 3,  key = "cata" },
    { id = 4,  key = "mop" },
    { id = 5,  key = "wod" },
    { id = 6,  key = "legion" },
    { id = 7,  key = "bfa" },
    { id = 8,  key = "sl" },
    { id = 9,  key = "df" },
    { id = 10, key = "tww" },
    { id = 11, key = "midnight" },
}

-- skillLineIDs for gathering professions — never recommended, never stored.
-- Verify IDs against GetProfessionInfo() output during implementation.
Constants.GATHERING_PROFESSIONS = {
    [182] = true, -- Herbalism
    [186] = true, -- Mining
    [393] = true, -- Skinning
    [356] = true, -- Fishing
    [794] = true, -- Archaeology
}

-- "classID:subClassID" → { skillLineIDs of crafting professions that consume it }
-- Verify classID/subClassID values with: /run local n,_,_,_,_,_,_,_,_,_,_,c,s = C_Item.GetItemInfoInstant(itemID); print(c,s)
-- Verify skillLineIDs with: /run local _,_,_,_,_,_,sl = GetProfessionInfo(GetProfessions()); print(sl)
Constants.CONSUMER_MAP = {
    ["7:9"]  = { 171, 773 },      -- Trade Goods: Herb       → Alchemy, Inscription
    ["7:7"]  = { 164, 202, 755 }, -- Trade Goods: Metal/Stone → Blacksmithing, Engineering, Jewelcrafting
    ["7:4"]  = { 165 },           -- Trade Goods: Leather    → Leatherworking
    ["7:5"]  = { 197 },           -- Trade Goods: Cloth      → Tailoring
    ["7:11"] = { 333 },           -- Trade Goods: Enchanting → Enchanting
    ["3:0"]  = { 755 },           -- Gem                     → Jewelcrafting
    ["7:8"]  = { 185 },           -- Trade Goods: Cooking    → Cooking
}

-- Built at load time: skillLineID → { categoryKey, ... }
Constants.PROFESSION_CATEGORIES = {}
for categoryKey, skillLineIDs in pairs(Constants.CONSUMER_MAP) do
    for _, id in ipairs(skillLineIDs) do
        Constants.PROFESSION_CATEGORIES[id] = Constants.PROFESSION_CATEGORIES[id] or {}
        table.insert(Constants.PROFESSION_CATEGORIES[id], categoryKey)
    end
end

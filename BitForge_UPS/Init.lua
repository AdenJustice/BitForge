---@class BitForge.UPS
local ns = select(2, ...)

---@class BitForge.UPS.Enum
local enum = {
    -- Where an item belongs. These strings are persisted in db.global.overrides,
    -- so changing a value orphans every override a user has set.
    DESTINATION = {
        WARBAND = "warband",
        PRIVATE = "private",
        IGNORE  = "ignore",
    },

    -- Offered in a private item's target-quantity submenu. Round numbers a
    -- player would actually pick, with anything else reachable through
    -- "Other...", because a menu listing every plausible quantity is unusable.
    TARGET_PRESETS = { 5, 20, 40, 100, 200 },

    -- Item classes whose members are crafting reagents. classID comes from
    -- C_Item.GetItemInfoInstant return 6 of 7 (ItemDocumentation.lua:647-656).
    REAGENT_CLASSES = {
        [Enum.ItemClass.Tradegoods] = true,
        [Enum.ItemClass.Reagent]    = true,
    },

    -- Which profession a recipe teaches, keyed by subClassID -- GetItemInfoInstant
    -- return 7 of 7. Enum.ItemRecipeSubclass has 12 values
    -- (ItemConstantsDocumentation.lua) and this covers 10 of them.
    --
    -- Book and FirstAid are omitted rather than mapped: Book is a subclass of
    -- reference items, not profession recipes, and FirstAid is not a profession a
    -- modern client can learn. An unmapped subclass makes WantedByAlt return false,
    -- so both fall through to ignore, which is the safe direction for an item kind
    -- no alt can ever want.
    RECIPE_PROFESSION = {
        [Enum.ItemRecipeSubclass.Leatherworking] = Enum.Profession.Leatherworking,
        [Enum.ItemRecipeSubclass.Tailoring]      = Enum.Profession.Tailoring,
        [Enum.ItemRecipeSubclass.Engineering]    = Enum.Profession.Engineering,
        [Enum.ItemRecipeSubclass.Blacksmithing]  = Enum.Profession.Blacksmithing,
        [Enum.ItemRecipeSubclass.Cooking]        = Enum.Profession.Cooking,
        [Enum.ItemRecipeSubclass.Alchemy]        = Enum.Profession.Alchemy,
        [Enum.ItemRecipeSubclass.Enchanting]     = Enum.Profession.Enchanting,
        [Enum.ItemRecipeSubclass.Fishing]        = Enum.Profession.Fishing,
        [Enum.ItemRecipeSubclass.Jewelcrafting]  = Enum.Profession.Jewelcrafting,
        [Enum.ItemRecipeSubclass.Inscription]    = Enum.Profession.Inscription,
    },

    -- The current character's carried bags. Fixed by the game, unlike bank tabs,
    -- which are enumerated at runtime because only purchased ones exist.
    BAG_INDICES = {
        Enum.BagIndex.Backpack,
        Enum.BagIndex.Bag_1,
        Enum.BagIndex.Bag_2,
        Enum.BagIndex.Bag_3,
        Enum.BagIndex.Bag_4,
        Enum.BagIndex.ReagentBag,
    },

    COLOR = {
        -- Marks a curation row whose destination the user set by hand, so a
        -- chosen destination is distinguishable at a glance from one a rule
        -- produced. Without the distinction the window cannot answer the only
        -- question curation ever raises: "did I already decide this one?"
        OVERRIDE = CreateColor(1, 0.82, 0),
    },
}
ns.enum = enum

---@class BitForge.UPS.Locale
ns.locale = {}

---@class BitForge.UPS.Model
ns.model = {}

---@class BitForge.UPS.View
ns.view = {}

---@class BitForge.UPS.Control
ns.control = {}

---@class BitForge.BatchSell
local ns = select(2, ...)

---@class BitForge.BatchSell.Enum
---@field NON_DISENCHANTABLE_IDS table<number, boolean>  Populated by ItemData.lua
---@field CLASS_PREFS table<string, table>  Populated by ItemData.lua
---@field SLOT_LOOKUP table<string, number[]>  Populated by ItemData.lua
local enum = {
    DECISION = {
        SELL = "SELL",
        KEEP = "KEEP",
    },

    -- Which step of the cascade produced the decision. Returned alongside the
    -- verdict so a test can assert the ordering, not just the outcome.
    RULE = {
        TEMP_EXCLUDED     = "TEMP_EXCLUDED",
        BLACKLISTED       = "BLACKLISTED",
        LOCKED            = "LOCKED",
        EQUIPMENT_SET     = "EQUIPMENT_SET",
        NO_SELL_PRICE     = "NO_SELL_PRICE",
        REFUNDABLE        = "REFUNDABLE",
        WHITELISTED       = "WHITELISTED",
        TEMP_INCLUDED     = "TEMP_INCLUDED",
        JUNK              = "JUNK",
        JUNK_SOLD         = "JUNK_SOLD",
        ABOVE_EPIC        = "ABOVE_EPIC",
        BIND_ON_ACCOUNT   = "BIND_ON_ACCOUNT",
        DISENCHANTABLE    = "DISENCHANTABLE",
        -- Per-class terminals. Each criterion names its own outcome so a
        -- tooltip can say what actually happened rather than "this kind of
        -- item is kept".
        BAG_KEPT              = "BAG_KEPT",
        PROFESSION_GEAR_KEPT  = "PROFESSION_GEAR_KEPT",
        ENHANCEMENT_CURRENT        = "ENHANCEMENT_CURRENT",
        ENHANCEMENT_LAST_EXPANSION = "ENHANCEMENT_LAST_EXPANSION",
        ENHANCEMENT_OUTDATED       = "ENHANCEMENT_OUTDATED",
        CONSUMABLE_CURRENT        = "CONSUMABLE_CURRENT",
        CONSUMABLE_LAST_EXPANSION = "CONSUMABLE_LAST_EXPANSION",
        CONSUMABLE_REAGENT        = "CONSUMABLE_REAGENT",
        GEM_CURRENT               = "GEM_CURRENT",
        GEM_REAGENT               = "GEM_REAGENT",
        GEM_ARTIFACT_RELIC_KEPT   = "GEM_ARTIFACT_RELIC_KEPT",
        TRADE_GOOD_SPARED         = "TRADE_GOOD_SPARED",
        -- The shared sale terminal for every per-class criterion above:
        -- nothing kept the item, and that is the same sentence whichever
        -- class asked -- naming the class here would only repeat what the
        -- tooltip it is attached to already shows.
        NOT_WANTED                = "NOT_WANTED",
        REAGENT_WANTED    = "REAGENT_WANTED",
        NOT_EQUIPPABLE    = "NOT_EQUIPPABLE",
        EQUIPPABLE        = "EQUIPPABLE",
        OUTCLASSED        = "OUTCLASSED",
        OUTDATED_EXPAC    = "OUTDATED_EXPAC",
        BIND_ON_EQUIP        = "BIND_ON_EQUIP",
        ARMOR_RELIC          = "ARMOR_RELIC",
        RECIPE_LEARNABLE  = "RECIPE_LEARNABLE",
        HOLIDAY_ITEM      = "HOLIDAY_ITEM",
        MOUNT_EQUIPMENT   = "MOUNT_EQUIPMENT",
        -- Shared across mounts, pets, housing decor, cosmetic armor and
        -- recipes: whether the collection or profession catalogue already
        -- has it, and whether an unbound piece can still reach someone who
        -- wants it. One sentence per outcome, not one per class.
        ALREADY_COLLECTED = "ALREADY_COLLECTED",
        NOT_COLLECTED     = "NOT_COLLECTED",
        STILL_TRADEABLE   = "STILL_TRADEABLE",
        ALREADY_LEARNED   = "ALREADY_LEARNED",
        -- The global fallthrough, and a routine outcome rather than a
        -- defensive tail: every abstaining criterion lands on it, as does
        -- model.Decide's unread-quality guard. Its reason string is
        -- player-facing, so it has to read as an answer and not as a gap.
        DEFAULT           = "DEFAULT",
    },

    -- bindType values returned by C_Item.GetItemInfo, read off Enum.ItemBind
    -- rather than written out. A hand-copied number is exactly what went wrong
    -- before: ON_ACCOUNT was 4, which is Quest, so the account rules matched
    -- quest items and never fired on warbound gear.
    BIND_TYPE = {
        NONE                        = Enum.ItemBind.None,
        ON_PICKUP                   = Enum.ItemBind.OnAcquire,
        ON_EQUIP                    = Enum.ItemBind.OnEquip,
        ON_USE                      = Enum.ItemBind.OnUse,
        QUEST                       = Enum.ItemBind.Quest,
        TO_WOW_ACCOUNT              = Enum.ItemBind.ToWoWAccount,
        TO_BNET_ACCOUNT             = Enum.ItemBind.ToBnetAccount,
        TO_BNET_ACCOUNT_UNTIL_EQUIP = Enum.ItemBind.ToBnetAccountUntilEquipped,
    },

    -- The bind types that make an item another character's to use: warband,
    -- Battle.net account, and the until-equipped variant of the latter. Used
    -- only as the fallback in control.scanner -- C_Item.IsItemBindToAccount is
    -- the authority wherever there is an item to ask about.
    BIND_TYPE_ACCOUNT = {
        [Enum.ItemBind.ToWoWAccount]              = true,
        [Enum.ItemBind.ToBnetAccount]             = true,
        [Enum.ItemBind.ToBnetAccountUntilEquipped] = true,
    },

    -- A recipe's subclass IS its profession: Enum.ItemRecipeSubclass has one
    -- entry per crafting profession. Mapped to Enum.Profession rather than a
    -- skill-line ID or a trade-skill slot index -- confirmed by tracing
    -- BitForge/control/control.lua's ReadProfessions (which resolves GetProfessionInfo's
    -- skillLine through C_TradeSkillUI.GetProfessionInfoBySkillLineID().profession)
    -- and BitForge/model.lua's GetAccountProfessions, which builds its mask
    -- with lshift(1, profession) against that same enum.
    --
    -- Mining, Herbalism, Skinning and Archaeology have no entry at all:
    -- Enum.ItemRecipeSubclass simply does not define one for them, since none
    -- of the four teaches anything a recipe item could represent. Book (0) is
    -- the one subclass it does define that maps to no profession -- a generic
    -- pattern or manual, not tied to one -- and is left out deliberately, so a
    -- reader does not mistake the gap for an oversight; a recipe filed there
    -- leaves facts.recipeProfession nil and the criterion abstains.
    RECIPE_SUBCLASS_PROFESSION = {
        [Enum.ItemRecipeSubclass.Leatherworking] = Enum.Profession.Leatherworking,
        [Enum.ItemRecipeSubclass.Tailoring]      = Enum.Profession.Tailoring,
        [Enum.ItemRecipeSubclass.Engineering]    = Enum.Profession.Engineering,
        [Enum.ItemRecipeSubclass.Blacksmithing]  = Enum.Profession.Blacksmithing,
        [Enum.ItemRecipeSubclass.Cooking]        = Enum.Profession.Cooking,
        [Enum.ItemRecipeSubclass.Alchemy]        = Enum.Profession.Alchemy,
        [Enum.ItemRecipeSubclass.FirstAid]       = Enum.Profession.FirstAid,
        [Enum.ItemRecipeSubclass.Enchanting]     = Enum.Profession.Enchanting,
        [Enum.ItemRecipeSubclass.Fishing]        = Enum.Profession.Fishing,
        [Enum.ItemRecipeSubclass.Jewelcrafting]  = Enum.Profession.Jewelcrafting,
        [Enum.ItemRecipeSubclass.Inscription]    = Enum.Profession.Inscription,
    },

    -- The status one item holds within one scope. A scope stores a single value per
    -- item, which is what makes blacklist and whitelist mutually exclusive: there is
    -- no second flag left to contradict the first.
    LIST_STATUS = {
        BLACKLIST = "blacklist",
        WHITELIST = "whitelist",
    },

    -- Which of the two lists an item belongs to. The values match the db proxy key
    -- names deliberately, so a scope indexes the database directly: db[scope].list.
    LIST_SCOPE = {
        GLOBAL = "global",
        CHAR   = "char",
    },

    COLOR = {
        -- Marks a merchant row whose character status contradicts its warband status.
        CHAR_OVERRIDE = CreateColor(1, 0.5, 0.25),
        -- The debug scan-result block on item tooltips. Grey, so it reads as
        -- an annotation rather than as part of the item's own tooltip.
        DEBUG = CreateColor(0.55, 0.55, 0.55),
        -- The player-facing verdict on an item tooltip.
        SELL = CreateColor(1, 0.35, 0.35),
        KEEP = CreateColor(0.4, 0.9, 0.4),
    },

    -- Glyph prefixed to a merchant row carrying a character override. Punctuation
    -- rather than prose, so it is a constant and not a locale string; the sentence
    -- explaining it lives in L["tooltip:charOverride"].
    CHAR_OVERRIDE_MARK = "!",

    -- The quality margin's slider position above its 0-30 range, and not a
    -- number of item levels: model.compareToSlot reads it as the step
    -- unbounded, which keeps any higher quality whatever its item level and
    -- lets no item level buy a lower one back. Stored as the position rather
    -- than as a large number so the track's own arithmetic stays honest.
    QUALITY_MARGIN_ALWAYS = 32,

    -- Bumped whenever the stored shape changes incompatibly. Every version
    -- needs a migration step registered in control.lua; core refuses to start
    -- the module against a shape nothing converted.
    SCHEMA_VERSION = 11,
}
ns.enum = enum

---@class BitForge.BatchSell.Locale
ns.locale = {}

---@class BitForge.BatchSell.Model
ns.model = {}

---@class BitForge.BatchSell.View
ns.view = {}

---@class BitForge.BatchSell.Control
ns.control = {}

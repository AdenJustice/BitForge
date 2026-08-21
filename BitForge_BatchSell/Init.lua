---@class BitForge.BatchSell
local ns = select(2, ...)

---@class BitForge.BatchSell.Enum
---@field NON_DISENCHANTABLE_IDS table<string, boolean>  Populated by ItemData.lua
---@field CLASS_PREFS table<string, table>  Populated by ItemData.lua
---@field SLOT_LOOKUP table<string, number[]>  Populated by ItemData.lua
local enum = {
    -- Outcome of model.Decide.
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
        CATEGORY          = "CATEGORY",
        CURRENT_EXPANSION = "CURRENT_EXPANSION",
        BIND_ON_ACCOUNT   = "BIND_ON_ACCOUNT",
        DISENCHANTABLE    = "DISENCHANTABLE",
        EQUIPPABLE        = "EQUIPPABLE",
        OUTCLASSED        = "OUTCLASSED",
        SELL_MODE         = "SELL_MODE",
        -- The defensive tail. Unreachable by construction -- see model.Decide --
        -- and kept so a future gap in the rules keeps an item rather than sells it.
        DEFAULT           = "DEFAULT",
    },

    -- The three buckets model.GetCategory sorts an item into. Equipment is
    -- decided by the gear rules; the other two by their own sell mode.
    CATEGORY_KEY = {
        EQUIPMENT = "EQUIPMENT",
        MATERIALS = "MATERIALS",
        OTHER     = "OTHER",
    },

    -- How far back a non-equipment category is willing to sell. KEEP_CURRENT
    -- reads the live expansion level, so it tracks a new expansion launching
    -- without the player touching anything; KEEP_FROM pins to a chosen one.
    -- Materials offers all four, Other only KEEP_ALL and KEEP_CURRENT.
    SELL_MODE = {
        KEEP_ALL     = "KEEP_ALL",
        KEEP_CURRENT = "KEEP_CURRENT",
        KEEP_FROM    = "KEEP_FROM",
        SELL_ALL     = "SELL_ALL",
    },

    -- bindType values returned by C_Item.GetItemInfo.
    BIND_TYPE = {
        ON_PICKUP  = 1,
        ON_EQUIP   = 2,
        ON_ACCOUNT = 4,
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

    -- Bumped whenever the stored shape changes incompatibly. Every version
    -- needs a migration step registered in control.lua; core refuses to start
    -- the module against a shape nothing converted.
    SCHEMA_VERSION = 2,
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

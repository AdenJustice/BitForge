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
        BIND_ON_ACCOUNT   = "BIND_ON_ACCOUNT",
        EQUIPPABLE        = "EQUIPPABLE",
        CLOSE_TO_EQUIPPED = "CLOSE_TO_EQUIPPED",
        DISENCHANTABLE    = "DISENCHANTABLE",
        PAST_EXPANSION    = "PAST_EXPANSION",
        QUALITY_THRESHOLD = "QUALITY_THRESHOLD",
        DEFAULT           = "DEFAULT",
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
    },

    -- Glyph prefixed to a merchant row carrying a character override. Punctuation
    -- rather than prose, so it is a constant and not a locale string; the sentence
    -- explaining it lives in L["tooltip:charOverride"].
    CHAR_OVERRIDE_MARK = "!",
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

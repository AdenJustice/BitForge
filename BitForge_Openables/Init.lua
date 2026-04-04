---@class BitForge.Openables
local ns = select(2, ...)

---@class BitForge.Openables.Enum
local enum = {
    -- Ranking priorities, highest first. Carried over from upstream's PRI_* constants.
    PRIORITY = {
        QUEST = 40, -- quest-gated items, while the gate still permits them
        OPEN  = 30, -- containers, caches, lockboxes
        TOKEN = 20, -- reputation and currency tokens
        LEARN = 10, -- recipes, toys, transmog, other learnables
    },

    -- Why detector.Classify surfaced an item. Carried on the candidate purely
    -- as diagnostics -- nothing in the pipeline branches on it -- so the DEBUG
    -- tooltip can explain a surprising pick without re-deriving the decision.
    REASON = {
        QUEST_GATE   = "QUEST_GATE",   -- quest-gated item, gate still open; detail is the questID
        ALLOW_LIST   = "ALLOW_LIST",   -- hand-listed in ItemData.lua
        LOCKED_BOX   = "LOCKED_BOX",   -- Locked tooltip line, and an unlock spell is known
        HAS_LOOT     = "HAS_LOOT",     -- ContainerItemInfo.hasLoot: the client says it holds loot
        OPENABLE_LINE = "OPENABLE_LINE", -- the client's own "right click to open" line
        TOOLTIP_LINE = "TOOLTIP_LINE", -- a typed tooltip line accepted it; detail is that line type
        ITEM_SPELL   = "ITEM_SPELL",   -- no typed line matched; GetItemSpell/IsUsableItem accepted it
    },

    -- Why detector.Classify turned an item away. Returned alongside the nil
    -- priority, so nothing in the pipeline sees it -- callers test the priority
    -- and stop. It exists for the DEBUG dump, which is otherwise left asking why
    -- an item that plainly looks openable never reaches the button.
    REJECTED = {
        BLACKLIST      = "BLACKLIST",      -- permanently blacklisted by the player
        SESSION_SKIP   = "SESSION_SKIP",   -- right-clicked away for this session
        DENY_LIST      = "DENY_LIST",      -- hand-listed in ItemData.lua
        SHORT_STACK    = "SHORT_STACK",    -- STACK_GATED, and fewer carried than the threshold
        QUEST_TAKEN    = "QUEST_TAKEN",    -- QUEST_GATED, and the quest is on or completed
        NO_UNLOCK      = "NO_UNLOCK",      -- a locked box, but no unlock spell is known
        REJECT_LINE    = "REJECT_LINE",    -- a typed line said it cannot be used; detail is that line
        UNUSABLE       = "UNUSABLE",       -- a requirement line, and IsUsableItem agrees it is unmet
        DENIED_CLASS   = "DENIED_CLASS",   -- whole item class is never openable
        ON_USE_ARMOR   = "ON_USE_ARMOR",   -- on-use armor accepted on a plain Use: line
        ON_USE_MISC    = "ON_USE_MISC",    -- Miscellaneous/Other accepted on a plain Use: line
        HOLIDAY        = "HOLIDAY",        -- Miscellaneous/Holiday
        QUESTLESS_ITEM = "QUESTLESS_ITEM", -- a quest item that starts no quest
        NO_EVIDENCE    = "NO_EVIDENCE",    -- nothing accepted it: no typed line, no usable spell
    },

    -- Spells that can open a locked container.
    -- verify in-game: /run print(IsPlayerSpell(1804))
    SPELL_PICK_LOCK = 1804,
    -- verify in-game: Mechagnome lockbox racial. Confirm the ID on a Mechagnome character.
    SPELL_SKELETON_PINKIE = 312370,

    BUTTON_SIZE_MIN = 24,
    BUTTON_SIZE_MAX = 64,
    BUTTON_SIZE_STEP = 2,

    -- Debounce window for rescans, in seconds. Zero coalesces to end of frame.
    RESCAN_DELAY = 0,
}
ns.enum = enum

---@class BitForge.Openables.Locale
ns.locale = {}

---@class BitForge.Openables.Model
ns.model = {}

---@class BitForge.Openables.View
ns.view = {}

---@class BitForge.Openables.Control
ns.control = {}

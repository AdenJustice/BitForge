---@class BitForge.Core
local ns = select(2, ...)

---@class BitForge.Core.Enum
local enum = {
    DB_DEFAULTS = {
        -- minimapPos is the button's angle on the minimap ring in degrees.
        -- 45 is the angle the button sat at when its position was hardcoded
        -- (at a hardcoded radius of 80), so an existing install keeps the same
        -- angle. The radius is no longer hardcoded -- it now tracks the
        -- minimap's real size -- so the button itself moves outward, from
        -- inside the map onto the ring, even though the angle is unchanged.
        -- professions is [charKey] = { Enum.Profession, ... }, rewritten at every
        -- login rather than merged: dropping a profession has to be able to
        -- remove it, or the account would go on believing someone can use a
        -- reagent nobody can.
        --
        -- characterClasses is [charKey] = ClassFile ("MAGE"), a store that runs
        -- parallel to knownCharacters rather than inside it. That list is an
        -- array of plain strings walked with ipairs by every module that asks
        -- who the account has, so giving it a second shape would break all of
        -- them at once. Purely additive, so an existing profile is seeded with
        -- an empty table and fills in one character at a time as each logs in.
        global = {
            knownCharacters  = {},
            characterClasses = {},
            minimapPos       = 45,
            professions      = {},
        },
        modules = {},
    },
    PLAYER_NAME = UnitName("player"),
    -- Every module addon is named BitForge_<Module>. Core strips this to derive
    -- the key a module's saved data lives under, and scans for it to discover
    -- which modules are installed, so both directions read it from here.
    ADDON_PREFIX = "BitForge_",
}
ns.enum = enum

---@class BitForge.Core.Locale
ns.locale = {}
---@class BitForge.Core.Model
ns.model = {}
---@class BitForge.Core.View
ns.view = {}
---@class BitForge.Core.Control
ns.control = {}

BitForge = {}

-- Registered in place of a migration step for a version whose stored shape
-- cannot be carried forward. Compared by identity, never called.
BitForge.SCHEMA_RESET = {}

---@class BitForge.Core.Events
BitForge.Events = {
    -- Lifecycle. Published by core, not relayed from a frame event. Sticky:
    -- a subscriber arriving after one of these fired is replayed immediately.
    CORE_LOADED  = "BITFORGE_CORE_LOADED",
    PLAYER_READY = "BITFORGE_PLAYER_READY",

    -- Relays. Each is forwarded verbatim from the identically named WoW frame
    -- event, which is why key and value match: core derives the frame event to
    -- register from the value alone. Subscribers receive the raw WoW payload.

    -- World and player state
    PLAYER_ENTERING_WORLD                 = "PLAYER_ENTERING_WORLD",
    PLAYER_FLAGS_CHANGED                  = "PLAYER_FLAGS_CHANGED",
    PLAYER_LEVEL_UP                       = "PLAYER_LEVEL_UP",
    PLAYER_REGEN_ENABLED                  = "PLAYER_REGEN_ENABLED",
    PLAYER_MONEY                          = "PLAYER_MONEY",
    PLAYER_INTERACTION_MANAGER_FRAME_SHOW = "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    PLAYER_INTERACTION_MANAGER_FRAME_HIDE = "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",

    -- Inventory and items
    BAG_UPDATE_DELAYED     = "BAG_UPDATE_DELAYED",
    ITEM_DATA_LOAD_RESULT  = "ITEM_DATA_LOAD_RESULT",
    EQUIPMENT_SETS_CHANGED = "EQUIPMENT_SETS_CHANGED",

    -- Bank
    BANKFRAME_OPENED = "BANKFRAME_OPENED",
    BANKFRAME_CLOSED = "BANKFRAME_CLOSED",

    -- Merchant
    MERCHANT_SHOW   = "MERCHANT_SHOW",
    MERCHANT_CLOSED = "MERCHANT_CLOSED",

    -- Spells. Fires when the spell awaiting a target changes -- the player
    -- putting one like Disenchant on the cursor, or taking it off again. No
    -- payload says which: what is pending has to be read back from
    -- SpellIsTargeting and the item's own tooltip.
    --
    -- UPDATE_SPELL_TARGET_ITEM_CONTEXT was relayed alongside this for a while,
    -- because it was unclear which of the two a raised Disenchant announces. It
    -- is neither: that event arrives when the cursor is cleared and not when
    -- the spell goes up, so it never once woke the probe and is gone.
    CURRENT_SPELL_CAST_CHANGED = "CURRENT_SPELL_CAST_CHANGED",

    -- Professions
    SKILL_LINES_CHANGED     = "SKILL_LINES_CHANGED",
    TRADE_SKILL_LIST_UPDATE = "TRADE_SKILL_LIST_UPDATE",
    NEW_RECIPE_LEARNED      = "NEW_RECIPE_LEARNED",

    -- Reputation
    UPDATE_FACTION                     = "UPDATE_FACTION",
    MAJOR_FACTION_RENOWN_LEVEL_CHANGED = "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",

    -- Quests
    QUEST_ACCEPTED  = "QUEST_ACCEPTED",
    QUEST_TURNED_IN = "QUEST_TURNED_IN",
    QUEST_REMOVED   = "QUEST_REMOVED",

    -- UI
    ACTIONBAR_UPDATE_COOLDOWN = "ACTIONBAR_UPDATE_COOLDOWN",
    CVAR_UPDATE               = "CVAR_UPDATE",
    UPDATE_BINDINGS           = "UPDATE_BINDINGS",
}

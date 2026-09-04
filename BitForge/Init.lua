---@class BitForge.Core
local ns = select(2, ...)

---@class BitForge.Core.Enum
local enum = {
    DB_DEFAULTS = {
        -- minimapPos is the button's angle on the minimap ring in degrees. 45 is
        -- where it sat while its position was hardcoded, so an existing install
        -- keeps its angle -- but not its place: the radius now tracks the
        -- minimap's real size rather than a hardcoded 80, so the button moves
        -- outward, from inside the map onto the ring.
        --
        -- professions is [charKey] = { Enum.Profession, ... }, rewritten at every
        -- login rather than merged: dropping a profession has to be able to
        -- remove it, or the account would go on believing someone can use a
        -- reagent nobody can.
        --
        -- characterClasses is [charKey] = ClassFile ("MAGE"), parallel to
        -- knownCharacters rather than inside it: that list is an array of plain
        -- strings walked with ipairs by every module that asks who the account
        -- has, so a second shape would break all of them at once. Purely
        -- additive, so an existing profile is seeded empty and fills in one
        -- character at a time as each logs in.
        --
        -- lastSeenVersion is the running addon version the player last opened
        -- the What's New window at (or had it auto-opened for), compared by
        -- identity against enum.RELEASE_NOTES rather than by arithmetic --
        -- see model.ReleaseNotesSince. Seeded as an empty string rather than
        -- left absent so SeedDefaults always has something to write and an
        -- existing profile picks the key up on its next login.
        --
        -- upgradeNoticeSeen records that view.upgradeNotice has raised the
        -- one-time notice about the suite becoming six separate downloads. A
        -- boolean rather than a version: it marks one event in the suite's
        -- history, not what the player last read, so nothing about it wants
        -- comparing against RELEASE_NOTES. Seeded false for the same reason
        -- lastSeenVersion is seeded empty.
        --
        -- versionSkewTold is what the player has already been told about a
        -- module running at a version core was not released beside, as
        -- [addonName] = { core = <core's version>, module = <the module's> }.
        -- The pair rather than the module's version alone: core moving on
        -- while a stale module stands still is a new fact, and one worth
        -- saying again. Seeded empty for the same reason lastSeenVersion is
        -- seeded blank, and it never grows past one entry per module the
        -- player has ever had installed -- CleanupDatabase prunes db.modules,
        -- not db.global, so an entry outlives the folder that earned it.
        --
        -- reportWindowPoint is the report window's last dragged position -- that
        -- window alone, per issue #312 -- in the { point, relPoint, x, y } shape
        -- BitForge_AzerothPrime already stores its button's position in, because an
        -- anchor pair survives a resolution change where a raw screen offset
        -- would not. Seeded false rather than left absent, so SeedDefaults still
        -- has something to write for an existing profile; false means "never
        -- dragged", exactly what the window's own CENTER anchor already
        -- describes, so ShowReport leaves it alone.
        global = {
            knownCharacters   = {},
            characterClasses  = {},
            minimapPos        = 45,
            professions       = {},
            lastSeenVersion   = "",
            upgradeNoticeSeen = false,
            versionSkewTold   = {},
            reportWindowPoint = false,
        },
        modules = {},
    },
    PLAYER_NAME = UnitName("player"),
    -- Every module addon is named BitForge_<Module>. Core strips this to derive
    -- the key a module's saved data lives under, and scans for it to discover
    -- which modules are installed, so both directions read it from here.
    ADDON_PREFIX = "BitForge_",
    -- What core answers to on the slash-command surface, where it stands beside
    -- the modules. Stated rather than derived: core has no ADDON_PREFIX to strip
    -- and no BitForgeDB.modules entry for a derived name to agree with, and its
    -- own addon name shares a first letter with a module -- which would lengthen
    -- an abbreviation players already type.
    CORE_KEY = "Core",
    -- The one module that was renamed rather than split off. Two things read
    -- it and they have to agree: view.upgradeNotice tells a player holding
    -- this folder to install BitForge_AzerothPrime, and model.VersionSkew
    -- passes over it for that reason -- a line telling them to update
    -- "BitForge Dispatch" names a CurseForge project that no longer exists,
    -- and would contradict the window on the same screen.
    RENAMED_MODULE = "BitForge_Dispatch",
    -- Where a player is told to paste a report. An enum constant rather than a
    -- locale key: a URL is the same in eleven languages, and
    -- Scripts/check_addon_conventions.py reports a non-English value
    -- byte-identical to its enUS counterpart as a problem of its own.
    REPORT_URL = "https://github.com/AdenJustice/BitForge/issues",
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

    -- Slash commands. Published by core, which owns /bitforge and /bfdump,
    -- resolves the module name the player abbreviated and forwards the rest of
    -- the line. Payload is (addonName, argumentString): the full
    -- BitForge_<Module> name, so a handler compares it against its own
    -- ADDON_NAME without string surgery, and the remainder of the line
    -- unsplit, because every handler parses it with its own match.
    --
    -- Two keys rather than one carrying a verb: a module that ships only
    -- diagnostics has no reason to hear player commands, nor the reverse.
    --
    -- Never sticky. A replayed command would run a second time for whoever
    -- subscribed after it was typed.
    MODULE_COMMAND = "BITFORGE_MODULE_COMMAND",
    MODULE_DUMP    = "BITFORGE_MODULE_DUMP",

    -- Relays. Each is forwarded verbatim from the identically named WoW frame
    -- event, which is why key and value match: core derives the frame event to
    -- register from the value alone. Subscribers receive the raw WoW payload.

    PLAYER_ENTERING_WORLD                 = "PLAYER_ENTERING_WORLD",
    PLAYER_FLAGS_CHANGED                  = "PLAYER_FLAGS_CHANGED",
    PLAYER_LEVEL_UP                       = "PLAYER_LEVEL_UP",
    PLAYER_REGEN_ENABLED                  = "PLAYER_REGEN_ENABLED",
    PLAYER_MONEY                          = "PLAYER_MONEY",
    PLAYER_INTERACTION_MANAGER_FRAME_SHOW = "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    PLAYER_INTERACTION_MANAGER_FRAME_HIDE = "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",

    -- Zone and sub-zone transitions. Three events for one concept, which is
    -- what Blizzard's own ZoneText.lua registers: NEW_AREA covers the zone,
    -- the other two cover sub-zone and indoor transitions -- so a player
    -- walking into a building moves between maps without the zone changing.
    ZONE_CHANGED           = "ZONE_CHANGED",
    ZONE_CHANGED_INDOORS   = "ZONE_CHANGED_INDOORS",
    ZONE_CHANGED_NEW_AREA  = "ZONE_CHANGED_NEW_AREA",

    BAG_UPDATE_DELAYED     = "BAG_UPDATE_DELAYED",
    ITEM_DATA_LOAD_RESULT  = "ITEM_DATA_LOAD_RESULT",
    EQUIPMENT_SETS_CHANGED = "EQUIPMENT_SETS_CHANGED",

    -- One item equipped, unequipped, or swapped between two equipped slots.
    -- Distinct from EQUIPMENT_SETS_CHANGED, which fires only for a saved
    -- set: a ring moved from finger 1 to finger 2 touches neither a bag slot
    -- nor a set, so this is the only signal for that swap.
    PLAYER_EQUIPMENT_CHANGED = "PLAYER_EQUIPMENT_CHANGED",

    -- A bag slot locking or unlocking. Distinct from BAG_UPDATE_DELAYED: an
    -- interrupted cast unlocks its slot without changing what is in any bag,
    -- so it is the only signal that a hold on an in-flight item should release.
    ITEM_LOCK_CHANGED      = "ITEM_LOCK_CHANGED",

    -- Announces that a sparse or cache tooltip lookup has resolved. Distinct
    -- from ITEM_DATA_LOAD_RESULT: item data and tooltip data are two caches, and
    -- an item whose data is cached can still answer C_TooltipInfo.GetBagItem
    -- with nothing. Payload is a nilable dataInstanceID, forwarded verbatim --
    -- nil means every tooltip, so a subscriber that retains no instance IDs
    -- treats any firing as "re-read".
    TOOLTIP_DATA_UPDATE    = "TOOLTIP_DATA_UPDATE",

    BANKFRAME_OPENED = "BANKFRAME_OPENED",
    BANKFRAME_CLOSED = "BANKFRAME_CLOSED",

    MERCHANT_SHOW   = "MERCHANT_SHOW",
    MERCHANT_CLOSED = "MERCHANT_CLOSED",

    -- Spells. Fires when the spell awaiting a target changes -- the player
    -- putting one like Disenchant on the cursor, or taking it off again. No
    -- payload says which: what is pending has to be read back from
    -- SpellIsTargeting and the item's own tooltip.
    --
    -- Never relay UPDATE_SPELL_TARGET_ITEM_CONTEXT alongside this to catch a
    -- raised Disenchant. It arrives when the cursor is cleared, not when the
    -- spell goes up, so it never once woke the probe that watched for one.
    CURRENT_SPELL_CAST_CHANGED = "CURRENT_SPELL_CAST_CHANGED",

    SKILL_LINES_CHANGED     = "SKILL_LINES_CHANGED",
    TRADE_SKILL_LIST_UPDATE = "TRADE_SKILL_LIST_UPDATE",
    NEW_RECIPE_LEARNED      = "NEW_RECIPE_LEARNED",

    NEW_TOY_ADDED               = "NEW_TOY_ADDED",
    TRANSMOG_COLLECTION_UPDATED = "TRANSMOG_COLLECTION_UPDATED",

    UPDATE_FACTION                     = "UPDATE_FACTION",
    MAJOR_FACTION_RENOWN_LEVEL_CHANGED = "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",

    QUEST_ACCEPTED  = "QUEST_ACCEPTED",
    QUEST_TURNED_IN = "QUEST_TURNED_IN",
    QUEST_REMOVED   = "QUEST_REMOVED",

    ACTIONBAR_UPDATE_COOLDOWN = "ACTIONBAR_UPDATE_COOLDOWN",
    CVAR_UPDATE               = "CVAR_UPDATE",
    UPDATE_BINDINGS           = "UPDATE_BINDINGS",
}

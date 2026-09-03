---@class BitForge.TaskTome
local ns = select(2, ...)

---@class BitForge.TaskTome.Enum
local enum = {
    OPT_FOLLOW        = "follow",
    OPT_IN            = "optin",
    OPT_OUT           = "optout",
    RESET_NONE        = "none",
    RESET_DAILY       = "daily",
    RESET_WEEKLY      = "weekly",
    -- Completion Scope. Values are persisted in task records; do not change them.
    SCOPE_CHAR        = "char",
    SCOPE_WARBAND     = "warband",
    -- Floor for the re-arm delay. C_DateAndTime can legitimately return 0 at the
    -- instant of a reset; this only bounds how often an at-boundary check re-runs,
    -- it does not by itself keep a re-check from re-clearing anything.
    RESET_MIN_DELAY   = 1, -- seconds
    -- Floor for the re-arm delay after a failed check. A throw can leave a stamp
    -- unadvanced and still in the past, which RESET_MIN_DELAY would retry at 1 Hz;
    -- a persistent fault should report about once a minute, not stream.
    RESET_ERROR_DELAY = 60, -- seconds
    -- Bumped whenever the stored shape changes incompatibly. A database below
    -- this version is reset rather than migrated; see the design (#59) 5.3.
    SCHEMA_VERSION    = 1,
    -- Widget view modes. Persisted in db.char; do not change the values.
    SCOPE_ME          = "me",
    SCOPE_ALL         = "all",
    ORIENT_BY_CHAR    = "byCharacter",
    ORIENT_BY_TASK    = "byTask",
}
ns.enum = enum

---@class BitForge.TaskTome.Locale
ns.locale = {}

-- Declared here so later files populate these tables rather than replacing
-- them. view/widget.lua and view/configFrame.lua capture ns.control at
-- file-read time and the .toc loads them before control.lua, so a replacement
-- would leave them holding a stale table.

---@class BitForge.TaskTome.Model
ns.model = {}

---@class BitForge.TaskTome.View
ns.view = {}

---@class BitForge.TaskTome.Control
ns.control = {}

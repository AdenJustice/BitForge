---@class BitForge.TaskTome
local ns = select(2, ...)

-- =========================================================
-- Enums / Constants
-- =========================================================

---@class BitForge.TaskTome.Enum
local enum = {
    -- Opt State
    OPT_FOLLOW        = "follow",
    OPT_IN            = "optin",
    OPT_OUT           = "optout",
    -- Reset Type
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
}
ns.enum = enum

-- =========================================================
-- Locale
-- =========================================================

---@class BitForge.TaskTome.Locale
ns.locale = {}

-- =========================================================
-- Namespace
-- =========================================================
--
-- Declared here so later files populate these tables rather than replacing
-- them. view.lua captures ns.control at file-read time, so a replacement would
-- leave it holding a stale table once the TOC loads views before controls.

---@class BitForge.TaskTome.Model
ns.model = {}

---@class BitForge.TaskTome.View
ns.view = {}

---@class BitForge.TaskTome.Control
ns.control = {}

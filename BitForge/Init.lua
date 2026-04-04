---@class BitForge.Core
local ns = select(2, ...)

---@class BitForge.Core.Enum
local enum = {
    DB_DEFAULTS = {
        global = { knownCharacters = {} },
        modules = {},
    },
    PLAYER_NAME = UnitName("player")
}
ns.enum = enum

---@class BitForge.Core.Model
ns.model = {}
---@class BitForge.Core.View
ns.view = {}
---@class BitForge.Core.Control
ns.control = {}

BitForge = {}

-- Set to true locally while developing to force-reseed savedvariable defaults
-- and enable debug output. The ship skill will toggle it if this is true.
BitForge.DEBUG = false

BitForge.Events = {
    CORE_LOADED = "BITFORGE_CORE_LOADED",
    PLAYER_READY = "BITFORGE_PLAYER_READY",
    PLAYER_LEAVING = "BITFORGE_PLAYER_LEAVING",
    MODULE_ENABLED = "BITFORGE_MODULE_ENABLED",   -- arg: addonName
    MODULE_DISABLED = "BITFORGE_MODULE_DISABLED", -- arg: addonName
    BANK_OPENED = "BITFORGE_BANK_OPENED",
    BANK_CLOSED = "BITFORGE_BANK_CLOSED",
    SKILL_LINES_CHANGED = "BITFORGE_SKILL_LINES_CHANGED",
}

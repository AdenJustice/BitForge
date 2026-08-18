---@class BitForge.AutoBalance
local ns = select(2, ...)

---@class BitForge.AutoBalance.Enum
local enum = {
    -- Target balances offered by the settings dropdown, in gold.
    BALANCE_OPTIONS = { 1000, 5000, 10000, 20000, 50000, 100000 },

    -- Outcomes of model.Plan. NONE and NO_FUNDS move no money.
    ACTION = {
        NONE     = "NONE",
        DEPOSIT  = "DEPOSIT",
        WITHDRAW = "WITHDRAW",
        COLLECT  = "COLLECT",
        NO_FUNDS = "NO_FUNDS",
    },

    -- Bank money is not readable the instant the banker frame shows. Poll for
    -- readiness rather than guessing a settle delay.
    READY_RETRY_DELAY = 0.1,
    READY_MAX_ATTEMPTS = 10,

    -- How long to wait for PLAYER_MONEY to confirm a dispatched transfer, in seconds.
    CONFIRM_TIMEOUT = 2,

    -- Bumped whenever the stored shape changes incompatibly. Every version
    -- needs a migration step registered in control.lua; core refuses to start
    -- the module against a shape nothing converted.
    SCHEMA_VERSION = 1,
}
ns.enum = enum

---@class BitForge.AutoBalance.Locale
ns.locale = {}

---@class BitForge.AutoBalance.Model
ns.model = {}

---@class BitForge.AutoBalance.View
ns.view = {}

---@class BitForge.AutoBalance.Control
ns.control = {}

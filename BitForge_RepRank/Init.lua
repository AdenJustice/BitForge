---@class BitForge.RepRank
local ns = select(2, ...)

-- =========================================================
-- Enums / Constants
-- =========================================================

---@class BitForge.RepRank.Enum
local enum = {
    -- Bumped whenever the stored shape changes incompatibly.
    SCHEMA_VERSION    = 1,
    -- FactionData.reaction for Neutral. A faction at or below this with no
    -- standing inside the tier counts as untouched, which is what the window's
    -- default filter hides.
    NEUTRAL_TIER      = 4,
    -- Seconds the incremental refresh coalesces behind. UPDATE_FACTION fires in
    -- bursts -- one turn-in can emit several -- and the refresh re-reads every
    -- known faction, so it must not run once per event.
    REFRESH_DELAY     = 1,
    -- Which of the four progress bars a record carries, and so which colour the
    -- row paints it. Stored rather than re-derived at display time for the same
    -- reason the standing label is: only a character who can see the faction can
    -- say what kind it is for them.
    BAR_KIND          = {
        PARAGON    = "paragon",
        MAJOR      = "major",
        FRIENDSHIP = "friendship",
        STANDARD   = "standard",
    },
}
ns.enum = enum

-- =========================================================
-- Locale
-- =========================================================

---@class BitForge.RepRank.Locale
ns.locale = {}

-- =========================================================
-- Namespace
-- =========================================================

---@class BitForge.RepRank.Model
ns.model = {}

---@class BitForge.RepRank.View
ns.view = {}

---@class BitForge.RepRank.Control
ns.control = {}

---@class BitForge.EUI
local ns = select(2, ...)

-- Numeric control over the frame positions of EllesmereUI, a large closed-
-- source addon suite. This file is also where the two citations the rest of the
-- module leans on are spelled out, once, rather than at every site:
--
-- "THE STANDALONE ADDON" is BitForgeUI ("BitForge Layout" 3.0.0), the separate
-- addon this module replaces. A comment citing `Core/Apply.lua` or
-- `Core/UI/Detail.lua` means a file of it, and names the source of a decision
-- rather than somewhere to go and look: BitForgeUI is a different project, is
-- not in this repository, and is not shipped with this one.
--
-- `docs/eui-integration.md` is the upstream ledger -- every dependency this
-- module has on EllesmereUI's internals, written down as a numbered fact
-- against a pinned upstream commit, so a bump has something concrete to be
-- diffed against. A comment citing "fact 5" or "fact 9" means an entry in it.
-- Like this comment it belongs to the BitForge development repository and is
-- stripped from the published addon, so the reasoning each fact carries is also
-- written out at the function that depends on it -- the citation says which
-- shared fact that reasoning is an instance of, and never replaces it.

---@class BitForge.EUI.Enum
local enum = {
    -- Bumped only when the stored shape changes. Version 1 is the initial
    -- shape: BitForge_EUI does not read the standalone addon's
    -- BitForgeLayoutDB, so there is no step 0 and no SCHEMA_RESET.
    SCHEMA_VERSION = 1,

    -- EllesmereUI's modules register their elements from their own init and
    -- first PLAYER_ENTERING_WORLD, so the registry is incomplete at
    -- PLAYER_LOGIN -- EUI defers its own equivalent pass for the same reason.
    -- Two passes rather than one long delay: the first is early enough that a
    -- corrected position is not seen as a jump, the second catches anything
    -- that registered late. Apply is value-guarded, so the second pass costs
    -- nothing when the first already did the work.
    FIRST_PASS  = 1.0,
    SECOND_PASS = 3.0,

    -- Escape-to-close works by frame NAME: UISpecialFrames is a list of names,
    -- so the editor window needs a global one.
    EDITOR_FRAME_SUFFIX = "Editor",

    -- The anchor point names SetPoint accepts. An extended anchor naming
    -- anything outside this set is refused with the "badpoint" reason rather
    -- than passed to SetPoint, which would raise.
    ANCHOR_POINTS = {
        TOPLEFT = true, TOP = true, TOPRIGHT = true,
        LEFT = true, CENTER = true, RIGHT = true,
        BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
    },
}
ns.enum = enum

---@class BitForge.EUI.Locale
ns.locale = {}
---@class BitForge.EUI.Model
ns.model = {}
---@class BitForge.EUI.View
ns.view = {}
---@class BitForge.EUI.Control
ns.control = {}

---@class BitForge.Dispatch
local ns = select(2, ...)

local C_Container = C_Container

---@type BitForge.Dispatch.Enum
local enum = ns.enum

---@type BitForge.Dispatch.Model
local model = ns.model

---@class BitForge.Dispatch.Control
local control = ns.control

-- The QUEST_GATED curation review, and a developer's tool end to end: it
-- reports on OpenableData.lua's own hand-curated table, and nothing in game
-- has ever read a verdict back.
--
-- It used to file into db.global, so the records accumulated on every player's
-- saved variables whatever the debug flag said. They file into db.debug.dump
-- now -- the container that exists for exactly this, that core empties at the
-- start of a play session, and that no schema step touches. Schema step 4 in
-- control/control.lua is what deletes the records already stored.
--
-- BitForge_Dispatch.toc wraps this file in #@debug@, so a release build ships
-- no source for it at all; control/openScanner.lua's one call site nil-checks
-- the sub-key rather than calling through it.

---@class BitForge.Dispatch.Control.CurationReview
local curationReview = {}

-- Reviewed once per session per item: a verdict cannot change while the item
-- sits there, and bag updates fire scans constantly.
local reviewed = {}

--- One curated list's sub-table inside the debug dump, created on first use,
--- or nil while diagnostics are off.
---@param listName string
---@return table|nil
local function storeFor(listName)
    local dump = model.GetDebugDump()
    if not dump then return nil end

    local review = dump.curationReview
    if not review then
        review = {}
        dump.curationReview = review
    end

    local list = review[listName]
    if not list then
        list = {}
        review[listName] = list
    end
    return list
end

--- Records what the client says about one QUEST_GATED entry, once per session.
---
--- Every hand-curated table in OpenableData.lua is a standing bet that the API
--- cannot answer something, and an entry stops earning its place the moment
--- the client can supply what it hard-codes. QUEST_GATED hard-codes each listed
--- item's quest, on the premise that no API maps one to the other. Where
--- GetContainerItemQuestInfo answers, the entry is dead weight -- Classify
--- already prefers the client. A disagreement matters more than either: the
--- table would name the wrong quest.
---
--- Driven off the scan rather than swept on demand because what it needs can
--- only be established with the item in a bag: GetContainerItemQuestInfo
--- answers for an item the player holds and for nothing else. So verdicts are
--- recorded opportunistically as such items pass through, and entries retired
--- on evidence rather than guesswork.
---
--- Never add an ALLOW_LIST review beside this one: the scan path stopped asking
--- what the ladder says without an entry (#389), and /bfdump dispatch allowlist
--- asks it of the whole list on demand instead.
---@param bag number
---@param slot number
---@param itemID number
function curationReview.ReviewQuestGated(bag, slot, itemID)
    local curated = enum.QUEST_GATED[itemID]
    if curated == nil or reviewed[itemID] then return end

    -- The memo is set only once there is somewhere to file into. The flag is
    -- read live -- /run takes effect without a reload -- so marking the item
    -- reviewed while diagnostics were still off would cost it the one review
    -- this session was ever going to give it.
    local list = storeFor("QUEST_GATED")
    if not list then return end
    reviewed[itemID] = true

    local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
    local reported = questInfo and questInfo.questID

    local verdict
    if not reported then
        verdict = ("needed: client reports no quest, table says %d"):format(curated)
    elseif reported == curated then
        verdict = ("REDUNDANT client reports quest %d, matching the table"):format(reported)
    else
        verdict = ("MISMATCH client reports quest %d, table says %d"):format(reported, curated)
    end

    list[itemID] = verdict

    -- Only where the client answered: a "needed" verdict is the ordinary case
    -- for most of the table, and printing one per entry would bury the two
    -- that mean something.
    if reported then
        BitForge:Print(("Openables: QUEST_GATED entry %d -- %s"):format(itemID, verdict))
    end
end

control.curationReview = curationReview

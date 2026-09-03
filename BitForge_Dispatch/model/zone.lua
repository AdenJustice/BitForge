---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs

local C_Map = C_Map

---@class BitForge.Dispatch.Model
local model = ns.model

---@class BitForge.Dispatch.Model.Zone
local zone = {}

-- The whole module's map reading lives in this file (spec #390 section 1).
-- Nothing else in BitForge_Dispatch calls C_Map, which is what leaves the
-- harness one seam to drive and the rest of the model free of the client.

local here

--- Where the player is, or nil when the client would not say.
---
--- Two guarded readings and nothing else -- no position, no exploration, no
--- zone text. GetBestMapForUnit answers with the SMALLEST map the player is on
--- and is nilable (a loading screen has none); GetMapInfo is MayReturnNothing,
--- so parentMapID is nil here even though the field itself is documented
--- non-nilable. That distinction is the whole of section 3's table: nil is
--- "the client declined", 0 is "this map has no container", and #378 is what
--- reading the first as the second costs -- a missing answer taken for a
--- positive one, shipped once already.
---
--- Memoised, because a scan asks this once per candidate and the answer cannot
--- change without one of the three ZONE_CHANGED* events firing. A nil reading
--- is deliberately not memoised: only GetBestMapForUnit ran on that path, so
--- re-asking costs one call, and holding the nil would need a second flag to
--- tell "unread" from "read as nothing" -- and would freeze a reading taken
--- during a loading screen until the next ZONE_CHANGED*.
---@return table|nil  { uiMapID = number, parentMapID = number|nil }
function zone.Here()
    if here then return here end

    local uiMapID = C_Map.GetBestMapForUnit("player")
    if not uiMapID then return nil end

    local mapInfo = C_Map.GetMapInfo(uiMapID)
    here = { uiMapID = uiMapID, parentMapID = mapInfo and mapInfo.parentMapID }
    return here
end

--- Dropped by the zone-event handler immediately before it requests a rescan --
--- in that order, or the rescan re-reads the memo it was meant to replace.
function zone.Invalidate()
    here = nil
end

---@param subzoneIDs number[]
---@param uiMapID number
---@return boolean
local function holds(subzoneIDs, uiMapID)
    for index = 1, #subzoneIDs do
        if subzoneIDs[index] == uiMapID then return true end
    end
    return false
end

--- Both halves compared, and an empty subzoneIDs is the wildcard: any map whose
--- parent is zoneID. A wildcard is still a constraint -- it drops the map half,
--- never the parent one.
---
--- The parent comparison closes both paths, which is why it is one line: an
--- unread parent accepts whichever half named the place. A missing half is not
--- a mismatched one, and where a map id was named it pins the place on its own.
---@param entry table  { zoneID = number, subzoneIDs = number[] }
---@param at table     zone.Here()'s reading
---@return boolean
local function entryMatches(entry, at)
    local subzoneIDs = entry.subzoneIDs
    if #subzoneIDs > 0 and not holds(subzoneIDs, at.uiMapID) then
        return false
    end
    return at.parentMapID == nil or at.parentMapID == entry.zoneID
end

--- Whether the player is somewhere the item's entries name.
---
--- Unknown never condemns: with no reading at all there is nothing to compare,
--- so the item is offered. That is the direction model/openRules.lua already
--- takes for every lazily-missing fact it reads.
---@param entries table[]  one item's enum.ZONE_GATED value
---@return boolean
function zone.Matches(entries)
    local at = zone.Here()
    if not at then return true end

    for _, entry in ipairs(entries) do
        if entryMatches(entry, at) then return true end
    end
    return false
end

model.zone = zone

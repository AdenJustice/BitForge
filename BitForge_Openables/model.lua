---@type string, BitForge.Openables
local ADDON_NAME, ns = ...

local pairs = pairs
local sort = table.sort
local wipe = wipe or function(target)
    for key in pairs(target) do target[key] = nil end
end

local DB_DEFAULTS = {
    global = {
        enabled      = true,
        locked       = false,
        buttonSize   = 42,
        showCount    = true,
        showCooldown = true,
        blacklist    = {},
        point        = { point = "CENTER", relPoint = "CENTER", x = 0, y = -150 },
        -- [listName] = { [itemID] = verdict string }. Filled in as items from a
        -- hand-curated table pass through the player's bags; see
        -- model.RecordCurationReview.
        curationReview = {},
    },
    char = {
        -- [parentProfessionName] = { [professionName] = skillLevel }, one entry
        -- per expansion's line. Char-scoped because a rank is the character's
        -- own, and nested rather than flat so a re-harvest can replace one
        -- profession's lines wholesale -- a merge would keep a line the player
        -- has since dropped, and nothing reports that.
        professionRanks = {},
    },
}
local db

---@class BitForge.Openables.Model
local model = ns.model

-- Session skips are deliberately not persisted: a session skip that survived a
-- reload would be indistinguishable from a permanent blacklist.
model.sessionSkip = {}

-- Items already clicked this round. The back of the queue rather than out of
-- it: model.Rank sorts a deferred item last instead of dropping it, so it comes
-- back the moment nothing else is left. Not persisted, for the same reason
-- session skips are not, and weaker still -- a deferral is meant to outlast one
-- click, not one session.
model.deferred = {}

BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB)
    db = moduleDB
    wipe(model.sessionSkip)
    wipe(model.deferred)
end)

--- Whether this module's diagnostics are switched on for this profile.
---
--- Set by hand in the saved variables -- BitForgeDB.modules.Openables.debug --
--- rather than from a setting, and read live, so it is false for every player
--- who has not gone looking for it. Control and view reach it through here for
--- the same reason they reach every other stored value through here: db is
--- private to this file.
---
--- db.debug is the container core normalized, so the flag is .enabled inside it
--- and not the container itself -- one left behind with diagnostics switched
--- off is still a table, and returning it raw would read as permanently on.
---@return boolean
function model.IsDebug()
    local diagnostics = db.debug
    return (diagnostics and diagnostics.enabled) and true or false
end

--- The debug container's scratch table, or nil while diagnostics are off.
---
--- Handed out rather than written through: a caller assembles its whole record
--- and drops it in. The container a module holds is the stored one, so anything
--- filed here reaches the saved variables and survives the session that
--- produced it -- which is the entire reason the dump exists.
---
--- Deliberately outside the schema, like the flag beside it: never seeded,
--- never migrated. Core empties it at the start of each play session, so a
--- dump reads as the record of one diagnostics session rather than of every
--- session since the flag went on.
---@return table|nil
function model.GetDebugDump()
    local diagnostics = db.debug
    if not (diagnostics and diagnostics.enabled) then return nil end
    return diagnostics.dump
end

function model.IsEnabled() return db.global.enabled end

function model.SetEnabled(value) db.global.enabled = value end

function model.GetLocked() return db.global.locked end

function model.SetLocked(value) db.global.locked = value end

function model.GetButtonSize() return db.global.buttonSize end

function model.SetButtonSize(value) db.global.buttonSize = value end

function model.GetShowCount() return db.global.showCount end

function model.SetShowCount(value) db.global.showCount = value end

function model.GetShowCooldown() return db.global.showCooldown end

function model.SetShowCooldown(value) db.global.showCooldown = value end

function model.IsBlacklisted(itemID)
    return db.global.blacklist[itemID] == true
end

function model.SetBlacklisted(itemID, value)
    db.global.blacklist[itemID] = value and true or nil
end

function model.GetBlacklist()
    local list = {}
    for itemID in pairs(db.global.blacklist) do
        list[#list + 1] = itemID
    end
    sort(list)
    return list
end

function model.ClearBlacklist()
    wipe(db.global.blacklist)
end

function model.IsSkipped(itemID)
    return model.sessionSkip[itemID] == true
end

function model.Skip(itemID)
    model.sessionSkip[itemID] = true
end

function model.ClearSkips()
    wipe(model.sessionSkip)
end

--- Whether this item has already been clicked and sent to the back of the queue.
---
--- A real boolean, never nil: model.Rank compares this field between two
--- candidates, and a field that is nil on some and false on others makes the
--- comparator inconsistent -- table.sort raises on that rather than merely
--- misordering.
---@return boolean
function model.IsDeferred(itemID)
    return model.deferred[itemID] == true
end

--- Send this item to the back of the queue, and start a new round when it was
--- already at the back.
---
--- Deferring twice is the wrap: every other candidate has been clicked through
--- to get back here. Leaving the flag set would change no state at all, and
--- model.Rank is deterministic over bags that have not moved -- so the next
--- scan would return this same item, and every click after it.
function model.Defer(itemID)
    if model.deferred[itemID] then
        wipe(model.deferred)
    end
    model.deferred[itemID] = true
end

function model.ClearDeferred()
    wipe(model.deferred)
end

-- What the last click acted on, while its use is still resolving. Session
-- state like model.deferred: nothing persists it, and a fresh login starts
-- with an empty button anyway.
local inFlight

--- Mark what a click acted on, so the scan it triggers does not repaint.
---
--- Separate from Defer even though the same click sets both: the deferral is
--- durable and outlives the round, while this lives only until the use
--- resolves.
function model.MarkInFlight(itemID)
    inFlight = itemID
end

function model.InFlightItem()
    return inFlight
end

function model.ClearInFlight()
    inFlight = nil
end

-- Every hand-curated table in ItemData.lua is a standing bet that the API cannot
-- answer something, and each is one patch away from being wrong. An entry stops
-- earning its place the moment the client can supply what it hard-codes.
--
-- That can only be established with the item in a bag -- hasLoot, the openable
-- tooltip line and GetContainerItemQuestInfo all answer only for an item the
-- player holds -- so verdicts are recorded opportunistically as such items pass
-- through, and kept here for the player to report back. Entries then get retired
-- on evidence rather than guesswork.
function model.RecordCurationReview(listName, itemID, verdict)
    local list = db.global.curationReview[listName]
    if not list then
        list = {}
        db.global.curationReview[listName] = list
    end
    list[itemID] = verdict
end

function model.GetCurationReview()
    return db.global.curationReview
end

function model.ClearCurationReview()
    wipe(db.global.curationReview)
end

function model.GetPoint()
    return db.global.point
end

function model.SetPoint(point, relPoint, x, y)
    local stored = db.global.point
    stored.point, stored.relPoint, stored.x, stored.y = point, relPoint, x, y
end

--- Every expansion line this character has been seen to hold, by profession.
---
--- The stored table itself rather than a copy: detector.RefreshProfessions
--- walks it on every skill-line change and at startup, and callers only read.
---@return table<string, table<string, number>>
function model.GetProfessionRanks()
    return db.char.professionRanks
end

--- Replaces one profession's lines with what the client just stated.
---
--- Wholesale rather than merged. A rank only ever rises, so merging looks safe
--- -- but the client stops reporting a line the player has dropped, and a merge
--- would keep answering requirements with it forever.
---@param parentName string
---@param lines table<string, number>
function model.SetProfessionRanks(parentName, lines)
    if not parentName then return end
    db.char.professionRanks[parentName] = lines
end

-- Pure: no API calls, no frame access. Cooldown and deferral state arrive as
-- candidate fields so this stays testable outside the game.
function model.Rank(candidates)
    sort(candidates, function(left, right)
        -- Ahead of cooldown and priority both: a deferral is the click that
        -- has already happened, and the whole point of it is that the next
        -- click reaches something else. It rejects nothing -- once every
        -- candidate is deferred the key is equal across the field, drops out of
        -- the comparison, and the ordinary order resumes, which is what puts
        -- the wrapped round back on its first item. model.Defer clears the
        -- field on that item's next click; ranking holds no reset of its own.
        if left.deferred ~= right.deferred then
            return not left.deferred
        end
        if left.onCooldown ~= right.onCooldown then
            return not left.onCooldown
        end
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        if left.stackCount ~= right.stackCount then
            return left.stackCount < right.stackCount
        end
        return left.itemID < right.itemID
    end)
    return candidates
end

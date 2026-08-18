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
    char = {},
}
local db

---@class BitForge.Openables.Model
local model = ns.model

-- Session skips are deliberately not persisted: a session skip that survived a
-- reload would be indistinguishable from a permanent blacklist.
model.sessionSkip = {}

BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB)
    db = moduleDB
    wipe(model.sessionSkip)
end)

--- Whether this module's diagnostics are switched on for this profile.
---
--- Set by hand in the saved variables -- BitForgeDB.modules.Openables.debug --
--- rather than from a setting, and read live, so it is nil for every player who
--- has not gone looking for it. Control and view reach it through here for the
--- same reason they reach every other stored value through here: db is private
--- to this file.
---@return boolean|nil
function model.IsDebug() return db.debug end

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

-- Pure: no API calls, no frame access. Cooldown state arrives as a candidate field
-- so this stays testable outside the game.
function model.Rank(candidates)
    sort(candidates, function(left, right)
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

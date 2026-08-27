---@type string, BitForge.RepRank
local ADDON_NAME, ns = ...

local next, pairs, sort, lower, find = next, pairs, table.sort, string.lower, string.find

-- The stored shape. chars is rewritten wholesale per character by each full
-- scan, so a faction that has dropped off a character's list disappears rather
-- than lingering; factions is merged, because an alt-only faction's name has to
-- survive every session in which nobody who knows it logs in.
local DB_DEFAULTS = {
    global = {
        chars       = {},   -- [charKey] = { [factionID] = record }
        factions    = {},   -- [factionID] = { name, isAccountWide, isMajor, expansionID, uiPriority }
        chatAlerts  = true,
        toastAlerts = true,
    },
    char = {
        windowPos     = { x = 0, y = 0 },
        showUntouched = false,
        sortByRank    = false,
    },
}

local db
BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB) db = moduleDB end)

---@type BitForge.RepRank.Enum
local enum = ns.enum
---@type BitForge.RepRank.Locale
local locale = ns.locale

---@class BitForge.RepRank.Model
local model = ns.model

--- Whether the account has ever recorded a character's reputations.
---
--- Handed to core as spec.hasData so a profile that has never stored anything
--- is stamped silently instead of warned about. The defaults have already been
--- seeded by the time this runs, so it must test for content, not presence.
---@return boolean
function model.HasData()
    return next(db.global.chars) ~= nil
end

--- Reads one character's record for a faction.
---@param charKey   string
---@param factionID number
---@return table|nil
function model.RecordFor(charKey, factionID)
    local forChar = db.global.chars[charKey]
    return forChar and forChar[factionID]
end

--- Every record a character holds, keyed by faction ID.
---
--- Returns nil rather than an empty table for a character who has never been
--- scanned, so the caller can tell "nothing recorded yet" from "recorded, and
--- holds nothing" -- the first needs a full scan, the second does not.
---@param charKey string
---@return table<number, table>|nil
function model.RecordsFor(charKey)
    return db.global.chars[charKey]
end

--- Writes one record, creating the character's table on first use.
---@param charKey   string
---@param factionID number
---@param record    table
function model.SetRecord(charKey, factionID, record)
    local forChar = db.global.chars[charKey]

    if not forChar then
        forChar = {}
        db.global.chars[charKey] = forChar
    end

    forChar[factionID] = record
end

--- Replaces a character's entire record table.
---
--- Wholesale rather than merged, following core's professions precedent: a
--- faction that has dropped off this character's list has to be able to
--- disappear, and a merge would keep it forever.
---@param charKey string
---@param records table<number, table>
function model.ReplaceCharRecords(charKey, records)
    db.global.chars[charKey] = records
end

--- Merges what one observer could see about a faction into the shared entry.
---
--- Field-wise rather than wholesale, and the inverse of ReplaceCharRecords for
--- a reason: these fields describe the faction, not the observer, so they do
--- not vary between characters and a later reading can only add to an earlier
--- one. Last writer wins per field, which is correct precisely because the two
--- writers cannot disagree.
---@param factionID number
---@param info      table
function model.MergeFaction(factionID, info)
    local stored = db.global.factions[factionID]

    if not stored then
        stored = {}
        db.global.factions[factionID] = stored
    end

    for key, value in pairs(info) do
        stored[key] = value
    end
end

--- What every observer agrees about a faction: its name and its kind.
---@param factionID number
---@return table|nil
function model.FactionInfo(factionID)
    return db.global.factions[factionID]
end

--- How far into paragon a record is, as two comparable numbers.
---
--- A record with no paragon table reads as (0, 0), so it ties with a record
--- that has just crossed into paragon and banked nothing yet. That tie is the
--- honest answer rather than a gap in the ordering: both characters sit at the
--- same standing with no paragon progress to separate them, and the game gives
--- no third thing to rank them by. Any actual progress breaks it immediately.
---@param record table
---@return number level, number value
local function paragonProgress(record)
    local paragon = record.paragon
    if not paragon then return 0, 0 end
    return paragon.level or 0, paragon.value or 0
end

--- Whether record `a` outranks record `b`.
---
--- Four keys in order: tier, renown, standing inside the tier, then paragon.
--- An explicit comparator rather than a packed composite integer, because the
--- packing would need a bit budget per field that is guessed rather than known
--- -- and because this is the one piece of the module worth testing exhaustively
--- outside the game.
---
--- Strict: equal records return false in both directions, which is what
--- table.sort requires of a comparator.
---@param a table
---@param b table
---@return boolean
function model.CompareRecords(a, b)
    if a.tier ~= b.tier then
        return a.tier > b.tier
    end

    local renownA, renownB = a.renown or 0, b.renown or 0
    if renownA ~= renownB then
        return renownA > renownB
    end

    if a.value ~= b.value then
        return a.value > b.value
    end

    local levelA, valueA = paragonProgress(a)
    local levelB, valueB = paragonProgress(b)

    if levelA ~= levelB then
        return levelA > levelB
    end

    return valueA > valueB
end

--- The character furthest along with a faction, and their record.
---
--- A character with no record for the faction is not a candidate: "nobody has
--- touched this" is a distinct answer from "everybody is at zero", and the
--- window has to be able to give it.
---@param factionID number
---@return string|nil charKey, table|nil record
function model.LeaderFor(factionID)
    local bestKey, bestRecord

    for charKey, records in pairs(db.global.chars) do
        local record = records[factionID]

        if record and (not bestRecord or model.CompareRecords(record, bestRecord)) then
            bestKey, bestRecord = charKey, record
        end
    end

    return bestKey, bestRecord
end

--- Whether any character has made progress with a faction.
---
--- Drives the window's default filter, which hides the several hundred
--- factions nobody has touched. The rule is deliberately coarse: above Neutral,
--- or any standing inside the current tier, or any paragon progress. The handful
--- of factions that start below Neutral read as untouched until the player earns
--- something back, which is the right answer for a list whose question is
--- "where have I made progress".
---@param factionID number
---@return boolean
function model.IsTouched(factionID)
    for _, records in pairs(db.global.chars) do
        local record = records[factionID]

        if record then
            if record.tier > enum.NEUTRAL_TIER or record.value > 0 or record.paragon then
                return true
            end
        end
    end

    return false
end

--- Every character holding a claimable paragon chest for a faction.
---
--- Sorted so the row's tooltip and the login summary list characters in a
--- stable order rather than pairs() order, which varies between sessions.
---@param factionID number
---@return string[]
function model.PendingFor(factionID)
    local pending = {}

    for charKey, records in pairs(db.global.chars) do
        local record = records[factionID]

        if record and record.paragon and record.paragon.pending then
            pending[#pending + 1] = charKey
        end
    end

    sort(pending)

    return pending
end

--- The standing a warband row displays.
---
--- Every character reports the same standing for an account-wide faction, so
--- whichever record is at hand is correct. The current character is preferred
--- only because it is the freshest reading, not because the others could differ.
---@param factionID number
---@return table|nil
local function warbandRecord(factionID)
    local current = model.RecordFor(BitForge:GetCurrentCharacter(), factionID)
    if current then return current end

    for _, records in pairs(db.global.chars) do
        if records[factionID] then return records[factionID] end
    end
end

--- Orders two rows by the window's default rule.
---
--- Major factions first, by expansionID descending and then uiPriority, because
--- those are the two keys Blizzard's own expansion landing page sorts on.
--- Everything else by factionID descending: IDs are allocated roughly as content
--- ships, so descending puts current content on top. It is a heuristic rather
--- than a guarantee, but it needs no hardcoded expansion table and so cannot go
--- stale the way an explicit list would.
---@param a table
---@param b table
---@return boolean
local function defaultOrder(a, b)
    local infoA = db.global.factions[a.factionID] or {}
    local infoB = db.global.factions[b.factionID] or {}

    if (infoA.isMajor or false) ~= (infoB.isMajor or false) then
        return infoA.isMajor or false
    end

    if infoA.isMajor then
        local expansionA, expansionB = infoA.expansionID or 0, infoB.expansionID or 0
        if expansionA ~= expansionB then
            return expansionA > expansionB
        end

        local priorityA, priorityB = infoA.uiPriority or 0, infoB.uiPriority or 0
        if priorityA ~= priorityB then
            return priorityA < priorityB
        end
    end

    return a.factionID > b.factionID
end

--- Orders two rows by their leading record, best first.
---
--- Rows whose faction nobody has recorded sort last: there is no record to
--- compare, and an unranked row above a ranked one would read as a better
--- standing than the ones below it.
---@param a table
---@param b table
---@return boolean
local function rankOrder(a, b)
    if not a.record then return false end
    if not b.record then return true end
    if model.CompareRecords(a.record, b.record) then return true end
    if model.CompareRecords(b.record, a.record) then return false end
    return defaultOrder(a, b)
end

-- Ungrouped factions sort after every real heading. A faction reaches this only
-- until the next full scan records its heading -- one login, for factions stored
-- before grouping existed -- so it is a transient state rather than a category.
local UNGROUPED_RANK = math.huge

--- Wraps a row comparator so groups never interleave.
---
--- Which expansion a faction belongs to is structure; the sort mode orders rows
--- inside a group rather than across them. Without this, sorting by rank would
--- scatter one expansion's factions through every other expansion's heading.
---
--- Ordered by the heading's position in the reputation pane rather than by name
--- or by expansion ID: the client already lists them in an order the player sees
--- every time they open that pane, and it needs no expansion table to go stale.
---@param order fun(a: table, b: table): boolean
---@return fun(a: table, b: table): boolean
local function byGroupThen(order)
    return function(a, b)
        local infoA = db.global.factions[a.factionID] or {}
        local infoB = db.global.factions[b.factionID] or {}
        local rankA = infoA.groupIndex or UNGROUPED_RANK
        local rankB = infoB.groupIndex or UNGROUPED_RANK
        if rankA ~= rankB then return rankA < rankB end
        return order(a, b)
    end
end

--- The window's two row lists, filtered and sorted.
---@param options { showUntouched: boolean, search: string|nil, sortByRank: boolean|nil }
---@return { warband: table[], characters: table[] }
function model.BuildSections(options)
    local search = options.search
    if search == "" then search = nil end
    if search then search = lower(search) end

    local warband, characters = {}, {}

    for factionID, info in pairs(db.global.factions) do
        local include = options.showUntouched or model.IsTouched(factionID)

        if include and search and not find(lower(info.name or ""), search, 1, true) then
            include = false
        end

        if include then
            local row

            if info.isAccountWide then
                local record = warbandRecord(factionID)
                row = {
                    factionID = factionID,
                    name      = info.name or locale["standing:unknown"],
                    label     = record and record.label or locale["standing:unknown"],
                    leader    = nil,
                    record    = record,
                    pending   = model.PendingFor(factionID),
                    group     = info.group,
                }
                warband[#warband + 1] = row
            else
                local leaderKey, leaderRecord = model.LeaderFor(factionID)
                row = {
                    factionID = factionID,
                    name      = info.name or locale["standing:unknown"],
                    label     = leaderRecord and leaderRecord.label or locale["standing:unknown"],
                    leader    = leaderKey,
                    record    = leaderRecord,
                    pending   = model.PendingFor(factionID),
                    group     = info.group,
                }
                characters[#characters + 1] = row
            end
        end
    end

    local order = byGroupThen(options.sortByRank and rankOrder or defaultOrder)
    sort(warband, order)
    sort(characters, order)

    return { warband = warband, characters = characters }
end

---@return boolean
function model.GetShowUntouched()
    return db.char.showUntouched
end

---@param value boolean
function model.SetShowUntouched(value)
    db.char.showUntouched = value
end

---@return boolean
function model.GetSortByRank()
    return db.char.sortByRank
end

---@param value boolean
function model.SetSortByRank(value)
    db.char.sortByRank = value
end

--- Where the player last left the window, as an offset from the screen centre.
---@return number x, number y
function model.GetWindowPos()
    return db.char.windowPos.x, db.char.windowPos.y
end

---@param x number
---@param y number
function model.SetWindowPos(x, y)
    db.char.windowPos.x, db.char.windowPos.y = x, y
end

--- Every pending paragon chest across the account.
---
--- The current character's entries lead: those are the ones claimable right now
--- without logging anywhere. The rest follow in a stable order, because pairs()
--- order varies between sessions and a summary that reshuffled itself every
--- login would read as new information.
---@return { charKey: string, factionID: number, name: string }[]
function model.CollectPending()
    local currentKey = BitForge:GetCurrentCharacter()
    local pending = {}

    for charKey, records in pairs(db.global.chars) do
        for factionID, record in pairs(records) do
            if record.paragon and record.paragon.pending then
                local info = db.global.factions[factionID]
                pending[#pending + 1] = {
                    charKey   = charKey,
                    factionID = factionID,
                    name      = (info and info.name) or locale["standing:unknown"],
                }
            end
        end
    end

    sort(pending, function(a, b)
        local aIsCurrent = a.charKey == currentKey
        local bIsCurrent = b.charKey == currentKey

        if aIsCurrent ~= bIsCurrent then return aIsCurrent end
        if a.charKey ~= b.charKey then return a.charKey < b.charKey end
        if a.name ~= b.name then return a.name < b.name end

        -- Faction ID last, because every key above it can tie: two factions
        -- nobody has named yet both resolve to the same placeholder, and
        -- table.sort leaves genuinely-equal elements in whatever order pairs()
        -- produced -- which is the varies-between-sessions order this sort
        -- exists to replace.
        return a.factionID < b.factionID
    end)

    return pending
end

---@return boolean
function model.GetChatAlerts()
    return db.global.chatAlerts
end

---@param value boolean
function model.SetChatAlerts(value)
    db.global.chatAlerts = value
end

---@return boolean
function model.GetToastAlerts()
    return db.global.toastAlerts
end

---@param value boolean
function model.SetToastAlerts(value)
    db.global.toastAlerts = value
end

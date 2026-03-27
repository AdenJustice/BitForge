local ns = select(2, ...)

local wipe = table.wipe

ns.Model = {}
local model = ns.Model
local db

function model.Init(_db)
    db = _db
end

-- =========================================================
-- char
-- =========================================================

function model.IsEnabled() return db.char.enabled end

function model.SetEnabled(v) db.char.enabled = v end

function model.IsInitialized() return db.char.initialized end

function model.SetInitialized(v) db.char.initialized = v end

function model.GetGuildBankPull() return db.char.guildBankPull end

function model.SetGuildBankPull(v) db.char.guildBankPull = v end

function model.GetGuildBankPush() return db.char.guildBankPush end

function model.SetGuildBankPush(v) db.char.guildBankPush = v end

-- =========================================================
-- global: assignments
-- =========================================================

function model.GetAssignments()
    return db.global.assignments
end

function model.GetAssignment(categoryKey)
    return db.global.assignments[categoryKey]
end

function model.SetAssignment(categoryKey, entry)
    db.global.assignments[categoryKey] = entry
end

function model.RemoveAssignment(categoryKey)
    db.global.assignments[categoryKey] = nil
end

function model.AssignChar(categoryKey, charKey)
    local entry = db.global.assignments[categoryKey]
    if entry then
        entry.chars = entry.chars or {}
        entry.chars[charKey] = true
    end
end

function model.UnassignChar(categoryKey, charKey)
    local entry = db.global.assignments[categoryKey]
    if entry then
        entry.chars = entry.chars or {}
        entry.chars[charKey] = nil
    end
end

function model.IsCharAssigned(categoryKey, charKey)
    local entry = db.global.assignments[categoryKey]
    return entry ~= nil and entry.chars ~= nil and entry.chars[charKey] == true
end

function model.SetExpansions(categoryKey, expansions)
    local entry = db.global.assignments[categoryKey]
    if entry then
        entry.expansions = expansions
    end
end

function model.AddItem(categoryKey, itemID)
    local entry = db.global.assignments[categoryKey]
    if entry then
        entry.items = entry.items or {}
        entry.items[itemID] = true
    end
end

function model.RemoveItem(categoryKey, itemID)
    local entry = db.global.assignments[categoryKey]
    if entry then
        entry.items = entry.items or {}
        entry.items[itemID] = nil
    end
end

-- =========================================================
-- global: custom category counter
-- =========================================================

function model.NewCustomKey()
    local key = "custom:" .. db.global.nextCustomID
    db.global.nextCustomID = db.global.nextCustomID + 1
    return key
end

function model.IsCustomCategory(key)
    return key:sub(1, 7) == "custom:"
end

-- =========================================================
-- global: professions
-- =========================================================

function model.GetProfessions(charKey)
    return db.global.professions[charKey] or {}
end

function model.SetProfessions(charKey, list)
    db.global.professions[charKey] = list
end

-- =========================================================
-- global: item counts (built-in tracking only)
-- =========================================================

-- Increment count for itemID held by charKey (called during bank scan).
function model.IncrementItemCount(itemID, charKey, delta)
    if not db.global.itemCounts[itemID] then
        db.global.itemCounts[itemID] = {}
    end
    db.global.itemCounts[itemID][charKey] =
        (db.global.itemCounts[itemID][charKey] or 0) + (delta or 1)
end

-- Wipe all built-in counts (called when an adapter activates).
function model.WipeItemCounts()
    wipe(db.global.itemCounts)
end

-- Returns count for a specific item held by charKey.
function model.GetRawItemCount(itemID, charKey)
    local t = db.global.itemCounts[itemID]
    return t and t[charKey] or 0
end

--- Returns the raw itemCounts table (itemID -> charKey -> count).
function model.GetRawItemCounts()
    return db.global.itemCounts
end

--- Returns total count of items explicitly registered to this category held by charKey.
function model.GetExplicitItemCount(charKey, categoryKey)
    local entry = db.global.assignments[categoryKey]
    if not entry or not entry.items then return 0 end

    local total = 0
    for itemID in pairs(entry.items) do
        total = total + model.GetRawItemCount(itemID, charKey)
    end
    return total
end

-- Wipe all counts for currentChar (called at start of each bank scan).
function model.WipeCharItemCounts(charKey)
    for _, charCounts in pairs(db.global.itemCounts) do
        charCounts[charKey] = nil
    end
end

-- =========================================================
-- item class cache (session-only, not persisted)
-- =========================================================

local itemClassCache = {}

function model.CacheItemClass(itemID, cID, sID)
    itemClassCache[itemID] = { cID = cID, sID = sID }
end

function model.GetCachedItemClass(itemID)
    local t = itemClassCache[itemID]
    if t then return t.cID, t.sID end
    return nil, nil
end

function model.WipeItemClassCache()
    wipe(itemClassCache)
end

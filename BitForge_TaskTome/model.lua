---@type string, BitForge.TaskTome
local ADDON_NAME, ns = ...

local ipairs = ipairs
local sort = table.sort
local pairs = pairs
local next = next
local time = time

local DB_DEFAULTS = {
    global = {
        tasks              = {},
        nextId             = 1,
        warbandCompletions = {},   -- [taskId]
        -- Keyed by character so any session can read every character's standing,
        -- and so the reset sweep can clear an alt that is not logged in.
        charCompletions    = {},   -- [charKey][taskId]
        optStates          = {},   -- [charKey][taskId]
        charResets         = {},   -- [charKey] = { daily, weeklyStart }
        warbandReset       = { daily = 0, weeklyStart = 0 },
    },
    char = {
        -- Only what is genuinely private to one character: geometry and which
        -- view this character likes to look at.
        widgetVisible     = false,
        widgetLocked      = true,
        widgetPos         = { x = 0, y = 0 },
        widgetSize        = { w = 260, h = 320 },
        widgetScope       = "me",
        widgetOrientation = "byCharacter",
        configPos         = { x = 0, y = 0 },
    },
}
local db

BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB)
    db = moduleDB
end)

---@class BitForge.TaskTome.Model
local model = ns.model
---@type BitForge.TaskTome.Enum
local enum = ns.enum

function model.GetTask(id)
    return db.global.tasks[id]
end

function model.GetAllTasks()
    return db.global.tasks
end

function model.CreateTask(fields)
    local id = db.global.nextId
    db.global.nextId = id + 1
    db.global.tasks[id] = {
        id = id,
        name = fields.name or "",
        parentId = fields.parentId or nil,
        sortOrder = fields.sortOrder or 1,
        reset = fields.reset or enum.RESET_NONE,
        warbandAssigned = fields.warbandAssigned or false,
        completionScope = fields.completionScope or enum.SCOPE_CHAR,
    }
    return id
end

function model.UpdateTask(id, fields)
    local task = db.global.tasks[id]
    if not task then return end
    for key, val in pairs(fields) do
        if key ~= "id" then
            task[key] = val
        end
    end
end

function model.DeleteTask(id)
    db.global.tasks[id] = nil
end

local function taskSortComparator(a, b)
    return a.sortOrder < b.sortOrder
end

function model.GetChildren(parentId)
    local children = {}
    for _, task in pairs(db.global.tasks) do
        if task.parentId == parentId then
            children[#children + 1] = task
        end
    end
    sort(children, taskSortComparator)
    return children
end

-- Never add a GetRoots: GetChildren(nil) already answers "the roots". There was
-- one, both cross-character builders reached for it because it read like the
-- entry point, and every task nested under a parent went missing from both.

function model.GetDescendantIds(id)
    local result = {}
    local function collect(taskId)
        for _, child in pairs(db.global.tasks) do
            if child.parentId == taskId then
                result[#result + 1] = child.id
                collect(child.id)
            end
        end
    end
    collect(id)
    return result
end

function model.GetMaxSortOrder(parentId)
    local max = 0
    for _, task in pairs(db.global.tasks) do
        if task.parentId == parentId and task.sortOrder > max then
            max = task.sortOrder
        end
    end
    return max
end

function model.SetSortOrder(id, order)
    if db.global.tasks[id] then
        db.global.tasks[id].sortOrder = order
    end
end

function model.SetParent(id, newParentId)
    if db.global.tasks[id] then
        db.global.tasks[id].parentId = newParentId
    end
end

local function charCompletionsFor(charKey)
    local all = db.global.charCompletions
    local forChar = all[charKey]
    if not forChar then
        forChar = {}
        all[charKey] = forChar
    end
    return forChar
end

function model.IsCompletedFor(taskId, charKey)
    local task = db.global.tasks[taskId]
    if not task then return false end
    if task.completionScope == enum.SCOPE_WARBAND then
        return db.global.warbandCompletions[taskId] ~= nil
    end
    local forChar = db.global.charCompletions[charKey]
    return forChar ~= nil and forChar[taskId] ~= nil
end

function model.IsCompleted(taskId)
    return model.IsCompletedFor(taskId, BitForge:GetCurrentCharacter())
end

function model.SetWarbandCompleted(taskId)
    db.global.warbandCompletions[taskId] = { completedAt = time() }
end

function model.ClearWarbandCompleted(taskId)
    db.global.warbandCompletions[taskId] = nil
end

function model.SetCharCompletedFor(taskId, charKey)
    charCompletionsFor(charKey)[taskId] = { completedAt = time() }
end

function model.ClearCharCompletedFor(taskId, charKey)
    local forChar = db.global.charCompletions[charKey]
    if forChar then forChar[taskId] = nil end
end

function model.SetCharCompleted(taskId)
    model.SetCharCompletedFor(taskId, BitForge:GetCurrentCharacter())
end

function model.ClearCharCompleted(taskId)
    model.ClearCharCompletedFor(taskId, BitForge:GetCurrentCharacter())
end

-- Keyed by character like completions, and for a stronger reason: the config
-- frame writes another character's opt state directly, so this is the one
-- cross-character write the UI performs.
local function optStatesFor(charKey)
    local all = db.global.optStates
    local forChar = all[charKey]
    if not forChar then
        forChar = {}
        all[charKey] = forChar
    end
    return forChar
end

function model.GetOptStateFor(taskId, charKey)
    local forChar = db.global.optStates[charKey]
    return (forChar and forChar[taskId]) or enum.OPT_FOLLOW
end

function model.SetOptStateFor(taskId, charKey, state)
    optStatesFor(charKey)[taskId] = state
end

function model.GetOptState(taskId)
    return model.GetOptStateFor(taskId, BitForge:GetCurrentCharacter())
end

function model.SetOptState(taskId, state)
    model.SetOptStateFor(taskId, BitForge:GetCurrentCharacter(), state)
end

--- Erases every stored trace of `taskId` -- the warband completion, and every
--- character's completion and opt state.
---
--- Iterates the stored tables rather than the roster. Both now live in
--- account-wide storage, so a character that has since dropped off
--- `GetKnownCharacters` still owns a row here, and sweeping only the roster
--- would leave it behind for good. Ids are never reused, so what is left behind
--- is unreachable storage rather than a wrong answer -- but it grows without
--- bound, and every deletion adds to it.
function model.ClearAllRecordsFor(taskId)
    db.global.warbandCompletions[taskId] = nil
    for _, forChar in pairs(db.global.charCompletions) do
        forChar[taskId] = nil
    end
    for _, forChar in pairs(db.global.optStates) do
        forChar[taskId] = nil
    end
end

-- Each stamp set clears exactly the completions it owns. Scoping them this way
-- is what prevents a second character, logging in with a stale stamp, from
-- clearing a warband completion the first character legitimately re-earned
-- after the boundary.
function model.ClearCharCompletionsForReset(charKey, resetType)
    for _, task in pairs(db.global.tasks) do
        if task.reset == resetType and task.completionScope ~= enum.SCOPE_WARBAND then
            model.ClearCharCompletedFor(task.id, charKey)
        end
    end
end

function model.ClearWarbandCompletionsForReset(resetType)
    for _, task in pairs(db.global.tasks) do
        if task.reset == resetType and task.completionScope == enum.SCOPE_WARBAND then
            db.global.warbandCompletions[task.id] = nil
        end
    end
end

local function charResetFor(charKey)
    local all = db.global.charResets
    local stamps = all[charKey]
    if not stamps then
        stamps = { daily = 0, weeklyStart = 0 }
        all[charKey] = stamps
    end
    return stamps
end

function model.GetCharReset(charKey)
    return charResetFor(charKey)
end

function model.SetCharReset(charKey, field, value)
    charResetFor(charKey)[field] = value
end

function model.GetWarbandReset()
    return db.global.warbandReset
end

function model.SetWarbandReset(field, value)
    db.global.warbandReset[field] = value
end

--- Whether a weekly reset has happened since `storedStart` was recorded.
---
--- Pure. Compares the stored last-seen reset start against the client's current
--- one: a change means a boundary was crossed, with no arithmetic and no
--- prediction. A stored 0 means never seeded and is never due, so a fresh
--- profile does not clear completions it never recorded.
---
--- Either reading being absent means "nothing to compare", never "due". The
--- caller already declines to sweep without a usable client reading; this is the
--- same rule stated where it can be tested, and it keeps a missing stored stamp
--- from raising on `nil > 0` inside a pass the caller cannot see into.
---@param storedStart  number|nil
---@param currentStart number|nil
---@return boolean
function model.IsWeeklyDue(storedStart, currentStart)
    if not storedStart or not currentStart then return false end
    return storedStart > 0 and storedStart ~= currentStart
end

function model.IsWidgetVisible()
    return db.char.widgetVisible
end

function model.SetWidgetVisible(visible)
    db.char.widgetVisible = visible
end

function model.IsWidgetLocked()
    return db.char.widgetLocked
end

function model.SetWidgetLocked(locked)
    db.char.widgetLocked = locked
end

function model.GetWidgetPos()
    return db.char.widgetPos
end

function model.SetWidgetPos(x, y)
    db.char.widgetPos.x = x; db.char.widgetPos.y = y
end

function model.GetWidgetScope()
    return db.char.widgetScope
end

function model.SetWidgetScope(scope)
    db.char.widgetScope = scope
end

function model.GetWidgetOrientation()
    return db.char.widgetOrientation
end

function model.SetWidgetOrientation(orientation)
    db.char.widgetOrientation = orientation
end

function model.GetWidgetSize()
    return db.char.widgetSize
end

function model.SetWidgetSize(width, height)
    db.char.widgetSize.w = width; db.char.widgetSize.h = height
end

function model.GetConfigPos()
    return db.char.configPos
end

function model.SetConfigPos(x, y)
    db.char.configPos.x = x; db.char.configPos.y = y
end

function model.IsTaskVisibleFor(taskId, charKey)
    local task = db.global.tasks[taskId]
    if not task then return false end

    local optState = model.GetOptStateFor(taskId, charKey)
    if optState == enum.OPT_OUT then return false end
    if optState == enum.OPT_IN then return true end
    -- "follow" defers to whether the task is assigned to the whole warband
    return task.warbandAssigned == true
end

function model.IsTaskVisible(taskId)
    return model.IsTaskVisibleFor(taskId, BitForge:GetCurrentCharacter())
end

-- Returns a tree structure suitable for building TreeDataProvider, from the
-- point of view of one character.
-- Only includes visible tasks. Parents with zero visible children are excluded.
-- Result shape: { { task=TaskRecord, children={ ... } }, ... }
function model.GetVisibleTaskTreeFor(charKey)
    local function buildSubtree(parentId)
        local children = model.GetChildren(parentId)
        local result = {}
        for _, task in ipairs(children) do
            local subtree = buildSubtree(task.id)
            if task.reset == enum.RESET_NONE and model.IsCompletedFor(task.id, charKey) then
                -- skip: permanently completed one-time tasks are hidden
            elseif model.IsTaskVisibleFor(task.id, charKey) or #subtree > 0 then
                result[#result + 1] = { task = task, children = subtree }
            end
        end
        return result
    end
    return buildSubtree(nil)
end

function model.GetVisibleTaskTree()
    return model.GetVisibleTaskTreeFor(BitForge:GetCurrentCharacter())
end

-- Cross-character trees (pure)
--
-- Both builders carry doneCount/totalCount on every node. The counts are
-- accumulated during the walk the builder already performs rather than
-- recomputed per row at render time, so the view stays a pure formatter.
--
-- "Assignee" is not a stored field: it is IsTaskVisibleFor over the roster, so
-- the opt-in/opt-out rules govern these views without being reimplemented here.

--- Characters for whom `taskId` is visible, in roster order.
---@return string[]
function model.GetAssignees(taskId)
    local assignees = {}
    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        if model.IsTaskVisibleFor(taskId, charKey) then
            assignees[#assignees + 1] = charKey
        end
    end
    return assignees
end

--- Every task in the tree, in depth-first sortOrder, at any depth.
---
--- Both cross-character groupings need the whole tree rather than its roots: an
--- account-wide task nested under a category is still account-wide, and a task
--- created with "Add Child Task" is still a task somebody owes.
---@return table[] tasks
local function everyTaskDepthFirst()
    local tasks = {}
    local function walk(parentId)
        for _, task in ipairs(model.GetChildren(parentId)) do
            tasks[#tasks + 1] = task
            walk(task.id)
        end
    end
    walk(nil)
    return tasks
end

--- Every account-wide task, as a trailing group node. Shared completion state
--- means one row each rather than a row per character.
---
--- Nesting does not exempt a task from the group: a `SCOPE_WARBAND` task under a
--- category parent used to be dropped from every character's subtree and
--- collected by nobody, so it vanished from both orientations while staying
--- visible in "me" mode.
local function accountWideGroup()
    local children, done = {}, 0
    for _, task in ipairs(everyTaskDepthFirst()) do
        -- Assigned to nobody means shown to nobody, exactly as an unassigned
        -- char-scoped task is excluded from the by-task axis rather than
        -- rendered as an empty row.
        if task.completionScope == enum.SCOPE_WARBAND and #model.GetAssignees(task.id) > 0 then
            -- `children = {}` is load-bearing: the view's insertTasks walks
            -- `#entry.children`, so a node without it errors on a nil index.
            children[#children + 1] = { task = task, children = {} }
            if model.IsCompletedFor(task.id, nil) then done = done + 1 end
        end
    end
    if #children == 0 then return nil end
    return {
        isAccountWide = true,
        children      = children,
        doneCount     = done,
        totalCount    = #children,
    }
end

--- Counts the char-scoped leaves of a visible-task subtree for one character.
local function countSubtree(subtree, charKey)
    local done, total = 0, 0
    for _, entry in ipairs(subtree) do
        if entry.task.completionScope ~= enum.SCOPE_WARBAND then
            total = total + 1
            if model.IsCompletedFor(entry.task.id, charKey) then done = done + 1 end
        end
        local childDone, childTotal = countSubtree(entry.children, charKey)
        done, total = done + childDone, total + childTotal
    end
    return done, total
end

--- Drops account-wide tasks from a visible tree; they are grouped separately.
---
--- A dropped node's children are spliced in where it stood rather than going
--- with it. Only the account-wide task itself belongs to the account-wide group;
--- a char-scoped chore that happens to live underneath one is still that
--- character's, and losing it would read as data loss rather than as grouping.
local function withoutAccountWide(subtree)
    local kept = {}
    for _, entry in ipairs(subtree) do
        local children = withoutAccountWide(entry.children)
        if entry.task.completionScope ~= enum.SCOPE_WARBAND then
            kept[#kept + 1] = { task = entry.task, children = children }
        else
            for _, child in ipairs(children) do
                kept[#kept + 1] = child
            end
        end
    end
    return kept
end

---@return table[] nodes  one per character, then the account-wide group
function model.GetTreeByCharacter()
    local nodes = {}
    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        local subtree = withoutAccountWide(model.GetVisibleTaskTreeFor(charKey))
        local done, total = countSubtree(subtree, charKey)
        -- A character with nothing outstanding is excluded, matching the rule
        -- that a parent with no visible children does not appear.
        if total > 0 then
            nodes[#nodes + 1] = {
                charKey    = charKey,
                children   = subtree,
                doneCount  = done,
                totalCount = total,
            }
        end
    end

    local accountWide = accountWideGroup()
    if accountWide then nodes[#nodes + 1] = accountWide end
    return nodes
end

--- The by-task axis, flat: every char-scoped task that anybody is assigned,
--- at any depth, each carrying its assignees as its children.
---
--- Flat rather than nested, and deliberately: on this axis a task's children are
--- the characters who owe it, so nesting subtasks under the same parent would
--- mix two kinds of child row and leave `doneCount/totalCount` meaning neither
--- one. Depth-first order still lists a subtask directly after its parent, so
--- the grouping stays legible without being structural. Walking only the roots
--- hid every task created with "Add Child Task", and excluded a category
--- parent's whole subtree along with the parent whenever the parent itself had
--- no assignees.
---@return table[] nodes  one per char-scoped task, then the account-wide group
function model.GetTreeByTask()
    local nodes = {}
    for _, task in ipairs(everyTaskDepthFirst()) do
        if task.completionScope ~= enum.SCOPE_WARBAND then
            local assignees = model.GetAssignees(task.id)
            if #assignees > 0 then
                local children, done = {}, 0
                for _, charKey in ipairs(assignees) do
                    local completed = model.IsCompletedFor(task.id, charKey)
                    children[#children + 1] = { charKey = charKey, completed = completed }
                    if completed then done = done + 1 end
                end
                nodes[#nodes + 1] = {
                    task       = task,
                    children   = children,
                    doneCount  = done,
                    totalCount = #assignees,
                }
            end
        end
    end

    local accountWide = accountWideGroup()
    if accountWide then nodes[#nodes + 1] = accountWide end
    return nodes
end

--- Whether this database holds anything a player would miss.
---
--- Checked rather than assumed from the version alone: a brand-new profile also
--- reads version 0, and telling a new player their data was cleared would be
--- both false and alarming.
function model.HasStoredData()
    if next(db.global.tasks) ~= nil then return true end
    if next(db.global.warbandCompletions) ~= nil then return true end
    if next(db.global.charCompletions) ~= nil then return true end
    if next(db.global.optStates) ~= nil then return true end
    return false
end

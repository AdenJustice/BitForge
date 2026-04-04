---@class BitForge.TaskTome
local ns = select(2, ...)

local ipairs = ipairs
local sort = table.sort
local pairs = pairs
local time = time

local DB_DEFAULTS = {
    global = {
        tasks = {},
        nextId = 1,
        nextDailyReset = 0,
        nextWeeklyReset = 0,
        warbandCompletions = {},
    },
    char = {
        optStates = {},
        charCompletions = {},
        widgetVisible = false,
        widgetLocked = true,
        widgetPos = { x = 0, y = 0 },
        configPos = { x = 0, y = 0 },
    },
}
local db

BitForge:AllocateModuleDB("TaskTome", DB_DEFAULTS, function(moduleDB)
    db = moduleDB
end)

---@class BitForge.TaskTome.Model
local model = ns.model
---@type BitForge.TaskTome.Enum
local enum = ns.enum

-- =========================================================
-- Task CRUD
-- =========================================================

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

-- =========================================================
-- Tree Navigation
-- =========================================================

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

function model.GetRoots()
    local roots = {}
    for _, task in pairs(db.global.tasks) do
        if task.parentId == nil then
            roots[#roots + 1] = task
        end
    end
    sort(roots, taskSortComparator)
    return roots
end

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

-- =========================================================
-- Completions
-- =========================================================

function model.IsCompleted(taskId)
    local task = db.global.tasks[taskId]
    if not task then return false end
    if task.completionScope == enum.SCOPE_WARBAND then
        return db.global.warbandCompletions[taskId] ~= nil
    end
    return db.char.charCompletions[taskId] ~= nil
end

function model.SetWarbandCompleted(taskId)
    db.global.warbandCompletions[taskId] = { completedAt = time() }
end

function model.ClearWarbandCompleted(taskId)
    db.global.warbandCompletions[taskId] = nil
end

function model.SetCharCompleted(taskId)
    db.char.charCompletions[taskId] = { completedAt = time() }
end

function model.ClearCharCompleted(taskId)
    db.char.charCompletions[taskId] = nil
end

function model.ClearAllCompletionsForReset(resetType)
    for _, task in pairs(db.global.tasks) do
        if task.reset == resetType then
            if task.completionScope == enum.SCOPE_WARBAND then
                db.global.warbandCompletions[task.id] = nil
            else
                db.char.charCompletions[task.id] = nil
            end
        end
    end
end

-- =========================================================
-- Opt State
-- =========================================================

function model.GetOptState(taskId)
    return db.char.optStates[taskId] or enum.OPT_FOLLOW
end

function model.SetOptState(taskId, state)
    db.char.optStates[taskId] = state
end

-- =========================================================
-- Reset Timestamps
-- =========================================================

function model.GetNextDailyReset() return db.global.nextDailyReset end

function model.SetNextDailyReset(t) db.global.nextDailyReset = t end

function model.GetNextWeeklyReset() return db.global.nextWeeklyReset end

function model.SetNextWeeklyReset(t) db.global.nextWeeklyReset = t end

-- =========================================================
-- Reset scheduling (pure)
-- =========================================================

--- Which reset types have come due at `now`.
--- Pure: no API calls, no db reads — the stored timestamps arrive as arguments
--- so the decision can be tested outside the game.
---
--- A stored timestamp of 0 means "never seeded" and is never due. Callers seed
--- before checking, so this only guards a fresh install: without it, a new
--- profile would clear completions it had never recorded.
---
--- Daily is returned first when both are due, which is the common case — a
--- weekly reset boundary is always also a daily one.
---@param now        number
---@param nextDaily  number
---@param nextWeekly number
---@return string[] dueTypes
function model.GetDueResets(now, nextDaily, nextWeekly)
    local due = {}
    if nextDaily > 0 and now >= nextDaily then
        due[#due + 1] = enum.RESET_DAILY
    end
    if nextWeekly > 0 and now >= nextWeekly then
        due[#due + 1] = enum.RESET_WEEKLY
    end
    return due
end

-- =========================================================
-- Widget State
-- =========================================================

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

function model.GetConfigPos()
    return db.char.configPos
end

function model.SetConfigPos(x, y)
    db.char.configPos.x = x; db.char.configPos.y = y
end

-- =========================================================
-- Visibility (computed, no WoW API)
-- =========================================================

function model.IsTaskVisible(taskId)
    local task = db.global.tasks[taskId]
    if not task then return false end

    local optState = model.GetOptState(taskId)
    if optState == enum.OPT_OUT then return false end
    if optState == enum.OPT_IN then return true end
    -- "follow"
    return task.warbandAssigned == true
end

-- Returns a tree structure suitable for building TreeDataProvider.
-- Only includes visible tasks. Parents with zero visible children are excluded.
-- Result shape: { { task=TaskRecord, children={ ... } }, ... }
function model.GetVisibleTaskTree()
    local function buildSubtree(parentId)
        local children = model.GetChildren(parentId)
        local result = {}
        for _, task in ipairs(children) do
            local subtree = buildSubtree(task.id)
            -- one-time completed tasks are hidden
            if task.reset == enum.RESET_NONE and model.IsCompleted(task.id) then
                -- skip: permanently completed one-time tasks are hidden
            elseif model.IsTaskVisible(task.id) or #subtree > 0 then
                -- Include if the task itself is visible, or it has visible children;
                -- parents whose every child is invisible are excluded.
                result[#result + 1] = { task = task, children = subtree }
            end
        end
        return result
    end
    return buildSubtree(nil)
end

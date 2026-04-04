---@class BitForge.TaskTome
local ns = select(2, ...)
local E = BitForge.Events

local ipairs = ipairs
local time = time

local model = ns.model
local locale = ns.locale
local enum = ns.enum
local view = ns.view

---@class BitForge.TaskTome.Control
local control = ns.control

-- =========================================================
-- EventBus
-- =========================================================

function ns:Subscribe(event, fn)
    BitForge.Subscribe(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

-- ================================================================================
-- Resets
-- ================================================================================
--
-- The reset schedule is region-specific, so it comes from the client rather than
-- from constants of our own. We still persist the expected reset time: asking
-- only "how many seconds until the next reset" can never reveal that a reset
-- already happened while the client was suspended.

local resets = {}
local resetTimer

-- Fallback periods, used only when the client's countdown does not yield a
-- strictly-future timestamp.
local RESET_PERIOD = {
    [enum.RESET_DAILY]  = 86400,
    [enum.RESET_WEEKLY] = 604800,
}

local function secondsUntil(resetType)
    if resetType == enum.RESET_DAILY then
        return C_DateAndTime.GetSecondsUntilDailyReset()
    end
    return C_DateAndTime.GetSecondsUntilWeeklyReset()
end

--- The next reset for `resetType` per the client, as an absolute timestamp
--- comparable to time(), or nil when the countdown does not yield a
--- strictly-future timestamp.
---
--- Both countdown APIs are documented Nilable = false (DateAndTimeDocumentation.lua),
--- and neither is documented as clamping at a boundary. The guard is defensive
--- rather than a claim about observed behaviour: nothing in that contract promises
--- a strictly-positive reading in the instants either side of a reset, and the cost
--- of being wrong is a stamp that is due again on the very next check. Returning nil
--- also keeps a genuine client reading distinguishable from the fallback guess,
--- which is what lets the reconcile pass in resets.Check adopt only the former.
---
--- The upper bound is not defensive but definitional: a countdown to the next
--- daily reset cannot exceed one day, nor a weekly one week. It matters because
--- the reconcile pass consults the client on every check, including during the
--- PLAYER_ENTERING_WORLD loading screen, before the server has necessarily sent
--- time data. Nothing here can bound a wrong-but-plausible reading -- that is
--- design-doc item 8, and it needs a live client to settle.
local function clientNextReset(resetType)
    local seconds = secondsUntil(resetType)
    if not seconds or seconds <= 0 or seconds > RESET_PERIOD[resetType] then
        return nil
    end
    return time() + seconds
end

--- The next reset for `resetType` as an absolute timestamp comparable to time().
---
--- Falling back to one whole period when the client has no usable reading restores
--- the strictly-future guarantee the hand-rolled advanceToNext used to provide:
--- without it a non-future stamp is due again on the very next check and re-clears
--- completions the player has just recorded. The fallback is a guess, though, so a
--- stamp seeded from it can be off by up to a period; the reconcile pass in
--- resets.Check is what eventually replaces it with the client's truth.
local function nextResetTime(resetType)
    return clientNextReset(resetType) or (time() + RESET_PERIOD[resetType])
end

local function storeNextReset(resetType, value)
    if resetType == enum.RESET_DAILY then
        model.SetNextDailyReset(value)
    else
        model.SetNextWeeklyReset(value)
    end
end

--- Arms a one-shot timer for the nearer of the two stored resets, replacing any
--- timer still outstanding. The cancel matters: without it every zone transition
--- would stack another timer on the last.
---
--- `minDelay` raises the floor for this arming only, so a caller that knows the
--- last check failed can keep a past-due stamp from retrying at 1 Hz.
---@param minDelay? number  seconds; defaults to enum.RESET_MIN_DELAY
function resets.Arm(minDelay)
    if resetTimer then
        resetTimer:Cancel()
        resetTimer = nil
    end

    local floor = minDelay or enum.RESET_MIN_DELAY
    local nearest = model.GetNextDailyReset()
    local weekly = model.GetNextWeeklyReset()
    if weekly < nearest then nearest = weekly end

    local delay = nearest - time()
    if delay < floor then
        delay = floor
    end

    resetTimer = C_Timer.NewTimer(delay, resets.Check)
end

local RESET_TYPES = { enum.RESET_DAILY, enum.RESET_WEEKLY }

--- Seeds, applies, and reconciles the stored stamps, appending each reset type
--- that fires to `due`. Split out of resets.Check so the whole body can run under
--- an xpcall; see the re-arm reasoning there.
---
--- `due` is an out-parameter rather than a return value on purpose. A throw after
--- ClearAllCompletionsForReset would discard a return, leaving completions cleared
--- in the database while the UI still shows them until something unrelated
--- repaints. Appending as we go means the caller can refresh whatever actually
--- happened before the error.
---
--- Passing it through xpcall's trailing arguments is a WoW extension to stock Lua
--- 5.1, not an oversight -- Blizzard relies on it (Blizzard_SettingsPanel.lua:534,
--- Blizzard_SharedXMLBase/FunctionUtil.lua:4). Do not "fix" it into a closure.
local function applyDueResets(due)
    -- Seed anything never seeded. Not for the due comparison below -- GetDueResets
    -- already treats 0 as never due -- but for resets.Arm, which takes the nearer of
    -- the two stamps and would otherwise compute its delay against 0, floor it to
    -- RESET_MIN_DELAY, and spin at 1 Hz. On the common path the reconcile pass
    -- overwrites what this writes with the identical value; on the fallback path,
    -- where the client gives nothing, this is the only writer.
    if model.GetNextDailyReset() == 0 then
        storeNextReset(enum.RESET_DAILY, nextResetTime(enum.RESET_DAILY))
    end
    if model.GetNextWeeklyReset() == 0 then
        storeNextReset(enum.RESET_WEEKLY, nextResetTime(enum.RESET_WEEKLY))
    end

    for _, resetType in ipairs(model.GetDueResets(
        time(), model.GetNextDailyReset(), model.GetNextWeeklyReset()))
    do
        model.ClearAllCompletionsForReset(resetType)
        due[#due + 1] = resetType
        storeNextReset(resetType, nextResetTime(resetType))
    end

    -- Reconcile every stamp against the client. Without this a stamp is only ever
    -- written when it is 0 or when it just came due, so a stamp left by an older
    -- build's hardcoded calendar -- or seeded from the fallback guess at an
    -- arbitrary login time -- would stand uncorrected for a whole period. A
    -- not-yet-due stamp has not fired, so replacing it can only correct a wrong
    -- prediction; no boundary is skipped.
    --
    -- Two invariants:
    --   * This must run after the due loop. The client's answer is always strictly
    --     future, so reconciling first would overwrite the very stamp GetDueResets
    --     needs to see as past, and no reset would ever fire.
    --   * Only a reading the client actually gave is adopted. Adopting the fallback
    --     here would let one bad reading overwrite a good stamp on every check.
    for _, resetType in ipairs(RESET_TYPES) do
        local fromClient = clientNextReset(resetType)
        if fromClient then
            storeNextReset(resetType, fromClient)
        end
    end
end

--- One reset check. Idempotent, so it is safe to call from any trigger: a second
--- call finds nothing due and simply re-arms.
function resets.Check()
    -- The timer is one-shot, so any error escaping this callback without a fresh
    -- Arm() leaves the module with no timer at all: no reset fires again until a
    -- loading screen or an AFK->active edge happens to re-enter Check. Two throw
    -- sites are live, and each is covered by a different mechanism -- applyDueResets
    -- by the xpcall below, RefreshTree by running after Arm(). Ordering alone covers
    -- only the second. Either way the timer survives and an error costs one check,
    -- not every remaining reset this session.
    --
    -- RefreshTree is the one left outside the xpcall because it ends in
    -- SetDataProvider, which rebuilds the row frames. A reset landing mid-drag would
    -- pull those out from under the drag behaviour installed at view.lua:369-377 --
    -- not the re-entrancy view.lua:203-204 warns about, which needs a Refresh nested
    -- inside the frame factory and cannot happen from a timer in single-threaded Lua.
    --
    -- xpcall with CallErrorHandler rather than pcall and a re-raise: the handler runs
    -- before the stack unwinds, so the error reaches BugSack attributed to the line
    -- that actually failed. CallErrorHandler exists to do this -- it adjusts the
    -- reported callstack height itself (Blizzard_SharedXMLBase/ErrorUtil.lua:1).
    -- pcall discards the stack before we could re-raise, so the report would blame
    -- this function instead of the one that threw.
    local due = {}
    local ok = xpcall(applyDueResets, CallErrorHandler, due)

    -- On failure, back the retry well off RESET_MIN_DELAY. A throw can leave a stamp
    -- unadvanced and still in the past, which Arm floors to one second -- so a
    -- persistent fault would re-enter Check at 1 Hz and stream errors rather than
    -- report once. The pre-xpcall behaviour was one error and a dead timer; neither
    -- extreme is right.
    resets.Arm(not ok and enum.RESET_ERROR_DELAY or nil)

    if #due > 0 then
        -- RefreshTree ends in widget.Refresh, so it covers both views.
        view.configFrame.RefreshTree()
    end
end

-- ================================================================================
-- Tasks
-- ================================================================================

local tasks = {}

-- Note: mutates fields.sortOrder before passing to model. Callers must not
-- rely on fields being unchanged after this call.
function tasks.CreateTask(fields)
    fields.sortOrder = model.GetMaxSortOrder(fields.parentId) + 1
    return model.CreateTask(fields)
end

function tasks.UpdateTask(id, fields)
    model.UpdateTask(id, fields)
end

-- Deletes a task and all descendants, clearing their completions and opt states.
function tasks.DeleteTask(id)
    local toDelete = { id }
    local descendants = model.GetDescendantIds(id)
    for _, did in ipairs(descendants) do
        toDelete[#toDelete + 1] = did
    end
    for _, did in ipairs(toDelete) do
        model.ClearWarbandCompleted(did)
        model.ClearCharCompleted(did)
        model.SetOptState(did, nil)
        model.DeleteTask(did)
    end
end

function tasks.CompleteTask(id)
    if model.IsCompleted(id) then return end
    local task = model.GetTask(id)
    if not task then return end
    if task.completionScope == enum.SCOPE_WARBAND then
        model.SetWarbandCompleted(id)
    else
        model.SetCharCompleted(id)
    end
end

function tasks.UncompleteTask(id)
    local task = model.GetTask(id)
    if not task then return end
    if task.completionScope == enum.SCOPE_WARBAND then
        model.ClearWarbandCompleted(id)
    else
        model.ClearCharCompleted(id)
    end
end

function tasks.SetOptState(taskId, state)
    model.SetOptState(taskId, state)
end

-- Moves a task to a new parent at a given sortOrder position.
-- newParentId: nil = move to root level.
-- newSortOrder: insertion point among siblings (1-based).
-- Shifts existing siblings' sortOrders to make room.
function tasks.MoveTask(id, newParentId, newSortOrder)
    -- Guard: cannot move onto self
    if newParentId == id then return end

    -- Guard: cannot move onto own descendant (cycle)
    if newParentId ~= nil then
        local descendants = model.GetDescendantIds(id)
        for _, did in ipairs(descendants) do
            if did == newParentId then return end
        end
    end

    local task = model.GetTask(id)
    if not task then return end

    -- Remove from old siblings: shift down all siblings with sortOrder > task.sortOrder
    local oldSiblings = model.GetChildren(task.parentId)
    for _, sibling in ipairs(oldSiblings) do
        if sibling.id ~= id and sibling.sortOrder > task.sortOrder then
            model.SetSortOrder(sibling.id, sibling.sortOrder - 1)
        end
    end

    -- Update parent
    model.SetParent(id, newParentId)

    -- Insert into new siblings: shift up all siblings with sortOrder >= newSortOrder
    local newSiblings = model.GetChildren(newParentId)
    for _, sibling in ipairs(newSiblings) do
        if sibling.id ~= id and sibling.sortOrder >= newSortOrder then
            model.SetSortOrder(sibling.id, sibling.sortOrder + 1)
        end
    end

    model.SetSortOrder(id, newSortOrder)
end

control.resets = resets
control.tasks = tasks

-- ================================================================================
-- Events
-- ================================================================================
--
-- The timer is the primary mechanism, but a daily reset can be up to 24 hours
-- out and whether C_Timer survives an OS suspend with its deadline intact is not
-- determinable from the client source. These two events cover the moments a
-- drifted timer would matter: coming back to the game.
--
-- EventRegistry callbacks receive the registry's owner ID as their first
-- argument, ahead of the payload.

local wasAFK = false

-- Fires on login, on reload, and on every zone transition.
local function onEnteringWorld()
    resets.Check()
end

-- PLAYER_FLAGS_CHANGED payload is (unitTarget); the leading parameter is the
-- EventRegistry owner ID. Only the AFK-to-active edge is interesting.
local function onPlayerFlagsChanged(_, unitTarget)
    if unitTarget ~= "player" then return end
    local isAFK = UnitIsAFK("player")
    if wasAFK and not isAFK then
        resets.Check()
    end
    wasAFK = isAFK
end

local function onPlayerReady()
    wasAFK = UnitIsAFK("player")
    resets.Check()
    if model.IsWidgetVisible() then
        view.widget.Show()
    end
    BitForge.RegisterMinimapButton({
        label    = locale["status:widgetTitle"],
        icon     = "Interface\\Icons\\INV_Misc_Note_01",
        onToggle = view.widget.Toggle,
    })
    view.settingsPanel.Init()
end

EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD", onEnteringWorld)
EventRegistry:RegisterFrameEventAndCallback("PLAYER_FLAGS_CHANGED", onPlayerFlagsChanged)

ns:Subscribe(E.PLAYER_READY, onPlayerReady)

---@type string, BitForge.TaskTome
local ADDON_NAME, ns = ...
local events = BitForge.Events

local ipairs = ipairs
local time = time

local model = ns.model
local locale = ns.locale
local enum = ns.enum
local view = ns.view

---@class BitForge.TaskTome.Control
local control = ns.control

function ns:Subscribe(event, fn)
    BitForge.Subscribe(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

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
--- the design (#59) 8, and it needs a live client to settle.
local function clientNextReset(resetType)
    local seconds = secondsUntil(resetType)
    if not seconds or seconds <= 0 or seconds > RESET_PERIOD[resetType] then
        return nil
    end
    return time() + seconds
end

--- The client's last weekly reset boundary, or nil when it has not given a
--- usable reading.
---
--- The same guard clientNextReset applies, and for the same reason. The
--- consequence of trusting a bad reading is far worse here than on the daily
--- path, because nothing downstream can tell it apart from a genuine boundary
--- crossing. A 0 differs from every stored stamp, so IsWeeklyDue says "due" for
--- every character and for the warband at once, and the pass clears every weekly
--- completion on the account; the stamp then heals itself, leaving no trace but
--- the missing ticks.
---
--- Returning nil rather than a fallback guess is the point. There is no
--- arithmetic that can reconstruct this value, so the only safe answer to "no
--- reading" is to leave the weekly stamps exactly as they are and re-check on
--- the next pass, which is at most RESET_MIN_DELAY away.
local function clientWeeklyStart()
    local startTime = C_DateAndTime.GetWeeklyResetStartTime()
    if not startTime or startTime <= 0 then
        return nil
    end
    return startTime
end

--- Arms a one-shot timer for the nearer of every stamp set's daily stamp,
--- replacing any timer still outstanding. The cancel matters: without it every
--- zone transition would stack another timer on the last.
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

    -- The nearest daily across every stamp set. Weekly needs no entry here: it
    -- is detected by comparing reset-start times, not by waiting for a
    -- deadline, so waking for the daily boundary is enough to catch it.
    local nearest = model.GetWarbandReset().daily
    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        local stamps = model.GetCharReset(charKey)
        if stamps.daily > 0 and (nearest == 0 or stamps.daily < nearest) then
            nearest = stamps.daily
        end
    end

    local delay = nearest - time()
    if delay < floor then
        delay = floor
    end

    resetTimer = C_Timer.NewTimer(delay, resets.Check)
end

--- Seeds, sweeps, and advances every stamp, recording in `changed` whether any
--- completion was actually cleared. Split out of resets.Check so the whole body
--- can run under an xpcall; see the re-arm reasoning there.
---
--- `changed` is an out-parameter rather than a return value on purpose. A throw
--- after a clear would discard a return, leaving completions cleared in the
--- database while the UI still shows them until something unrelated repaints.
local function applyDueResets(changed)
    local nowDaily = clientNextReset(enum.RESET_DAILY)
    local weeklyStart = clientWeeklyStart()

    --- One stamp set: seed what is unseeded, clear what is due, advance.
    ---@param stamps    table     the stored { daily, weeklyStart } record
    ---@param setStamp  fun(field: string, value: number)
    ---@param clear     fun(resetType: string)
    local function sweep(stamps, setStamp, clear)
        -- Seed rather than fire on a first sight of either stamp. A fresh
        -- profile has recorded no completions, so there is nothing to clear.
        if stamps.daily == 0 then
            setStamp("daily", nowDaily or (time() + RESET_PERIOD[enum.RESET_DAILY]))
        elseif time() >= stamps.daily then
            clear(enum.RESET_DAILY)
            changed[#changed + 1] = enum.RESET_DAILY
            setStamp("daily", nowDaily or (time() + RESET_PERIOD[enum.RESET_DAILY]))
        elseif nowDaily then
            -- Reconcile: a stamp written by an older build, or seeded from the
            -- fallback guess, is corrected. A not-yet-due stamp has not fired,
            -- so replacing it can only correct a wrong prediction.
            setStamp("daily", nowDaily)
        end

        -- Skipped entirely without a reading, rather than seeded or cleared from
        -- one. Unlike the daily path there is no fallback worth guessing at: the
        -- stored stamp is only ever compared against a client reading, so
        -- leaving it untouched costs one pass and nothing else.
        if weeklyStart then
            if stamps.weeklyStart == 0 then
                setStamp("weeklyStart", weeklyStart)
            elseif model.IsWeeklyDue(stamps.weeklyStart, weeklyStart) then
                clear(enum.RESET_WEEKLY)
                changed[#changed + 1] = enum.RESET_WEEKLY
                setStamp("weeklyStart", weeklyStart)
            end
        end
    end

    -- Every character, not just the one online. An alt that has not logged in
    -- for a week is corrected by this session; without this the alt would never
    -- see its own boundary, because the stamp that would have told it had
    -- already been advanced by whoever was online at the time.
    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        sweep(
            model.GetCharReset(charKey),
            function(field, value) model.SetCharReset(charKey, field, value) end,
            function(resetType) model.ClearCharCompletionsForReset(charKey, resetType) end
        )
    end

    sweep(
        model.GetWarbandReset(),
        model.SetWarbandReset,
        model.ClearWarbandCompletionsForReset
    )
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
    -- pull those out from under the widget's OnDragStart/OnDragStop handlers -- not
    -- the re-entrancy widget.Refresh warns about, which needs a Refresh nested inside
    -- the frame factory and cannot happen from a timer in single-threaded Lua.
    --
    -- xpcall with CallErrorHandler rather than pcall and a re-raise: the handler runs
    -- before the stack unwinds, so the error reaches BugSack attributed to the line
    -- that actually failed. CallErrorHandler exists to do this -- it adjusts the
    -- reported callstack height itself (Blizzard_SharedXMLBase/ErrorUtil.lua).
    -- pcall discards the stack before we could re-raise, so the report would blame
    -- this function instead of the one that threw.
    local changed = {}
    local ok = xpcall(applyDueResets, CallErrorHandler, changed)

    -- On failure, back the retry well off RESET_MIN_DELAY. A throw can leave a stamp
    -- unadvanced and still in the past, which Arm floors to one second -- so a
    -- persistent fault would re-enter Check at 1 Hz and stream errors rather than
    -- report once. The pre-xpcall behaviour was one error and a dead timer; neither
    -- extreme is right.
    resets.Arm(not ok and enum.RESET_ERROR_DELAY or nil)

    if #changed > 0 then
        -- RefreshTree ends in widget.Refresh, so it covers both views.
        view.configFrame.RefreshTree()
    end
end

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

-- Deletes a task and all its descendants. ClearAllRecordsFor clears every
-- character's rows, not just the logged-in one's.
function tasks.DeleteTask(id)
    local toDelete = { id }
    local descendants = model.GetDescendantIds(id)
    for _, descendantId in ipairs(descendants) do
        toDelete[#toDelete + 1] = descendantId
    end
    for _, taskId in ipairs(toDelete) do
        model.ClearAllRecordsFor(taskId)
        model.DeleteTask(taskId)
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

function tasks.SetOptStateFor(taskId, charKey, state)
    model.SetOptStateFor(taskId, charKey, state)
end

-- Moves a task to a new parent at a given sortOrder position.
-- newParentId: nil = move to root level.
-- newSortOrder: insertion point among siblings (1-based).
-- Shifts existing siblings' sortOrders to make room.
function tasks.MoveTask(id, newParentId, newSortOrder)
    if newParentId == id then return end

    if newParentId ~= nil then
        local descendants = model.GetDescendantIds(id)
        for _, did in ipairs(descendants) do
            if did == newParentId then return end
        end
    end

    local task = model.GetTask(id)
    if not task then return end

    local oldSiblings = model.GetChildren(task.parentId)
    for _, sibling in ipairs(oldSiblings) do
        if sibling.id ~= id and sibling.sortOrder > task.sortOrder then
            model.SetSortOrder(sibling.id, sibling.sortOrder - 1)
        end
    end

    model.SetParent(id, newParentId)

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

-- The timer is the primary mechanism, but a daily reset can be up to 24 hours
-- out and whether C_Timer survives an OS suspend with its deadline intact is not
-- determinable from the client source. These two events cover the moments a
-- drifted timer would matter: coming back to the game.
local wasAFK = false

-- Fires on login, on reload, and on every zone transition.
local function onEnteringWorld()
    resets.Check()
end

-- PLAYER_FLAGS_CHANGED payload is (unitTarget). Only the AFK-to-active edge is
-- interesting.
local function onPlayerFlagsChanged(unitTarget)
    if unitTarget ~= "player" then return end
    local isAFK = UnitIsAFK("player")
    if wasAFK and not isAFK then
        resets.Check()
    end
    wasAFK = isAFK
end

--- The normal startup sequence, run either directly or after the upgrade popup
--- is acknowledged.
local function startModule()
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

local function onPlayerReady()
    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        -- Named explicitly: ResolveModuleTitle's .toc fallback only ever reads
        -- the untranslated "BitForge – TaskTome" line every module's .toc
        -- ships, since no module ships a localized ## Title-<locale>. This is
        -- the module's own translated display name instead.
        title   = locale["settings:taskTomePanel"],
        hasData = model.HasStoredData,
        steps   = {
            -- The pre-cross-character shape stored completions per character in
            -- a layout with no warband equivalent; there is nothing to map it
            -- onto. See the design (#59) 5.3.
            [1] = BitForge.SCHEMA_RESET,
        },
    }, startModule)
end

ns:Subscribe(events.PLAYER_ENTERING_WORLD, onEnteringWorld)
ns:Subscribe(events.PLAYER_FLAGS_CHANGED, onPlayerFlagsChanged)
ns:Subscribe(events.PLAYER_READY, onPlayerReady)

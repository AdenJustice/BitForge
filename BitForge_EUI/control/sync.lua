---@class BitForge.EUI
local ns = select(2, ...)

---@class BitForge.EUI.Control
local control = ns.control
---@type BitForge.EUI.Model
local model = ns.model
---@type BitForge.EUI.Locale
local locale = ns.locale

---@type BitForge.EUI.Control.Adapters
local adapters = control.adapters
---@type BitForge.EUI.Control.Resolver
local resolver = control.resolver

local format = string.format

-- Ported from the standalone addon's Core/Apply.lua, Core/Capture.lua and the
-- seedOrApply/countAttached pair in Core/Events.lua. The anchor-resolution
-- math (validating a definition, walking the graph for a cycle, computing an
-- extended anchor's position) stayed in control/resolver.lua -- this file is
-- what DOES something with those verdicts: it decides what gets written,
-- writes it through control.adapters, and reports what happened.

-- EllesmereUI's own layer flush uses half a pixel as the "already this size"
-- threshold. Matching it means a layout captured from a live UI does not
-- report a phantom change on the next run.
local SIZE_EPSILON = 0.5

---@param current table|nil  { point, relPoint?, x, y }
---@param point string
---@param relPoint string
---@param x number
---@param y number
---@return boolean
local function samePosition(current, point, relPoint, x, y)
    return current ~= nil
        and current.point == point
        and (current.relPoint or current.point) == relPoint
        and current.x == x
        and current.y == y
end

---@param current table|nil  { target, side, offsetX, offsetY }
---@param want table  { target, side, offsetX, offsetY }
---@return boolean
local function sameAnchor(current, want)
    return current ~= nil
        and current.target == want.target
        and current.side == want.side
        and (current.offsetX or 0) == (want.offsetX or 0)
        and (current.offsetY or 0) == (want.offsetY or 0)
end

--- Applies one layout entry's anchor and plain-position fields. Size is
--- handled separately below, since it is independent of both.
---
--- The value guard for a plain position compares against a live read of
--- EllesmereUI, matching EllesmereUI's own reference implementation
--- (`EllesmereUI_SpecOverrides.lua` -- fact 6 in docs/eui-integration.md) that
--- this module's apply is deliberately modelled on. The resolved table
--- `model.GetResolved` returns stays scoped to what control/resolver.lua
--- writes for an extended anchor -- Capture's own drag detection reads that
--- table, and a plain-position record in it would be read as something it is
--- not.
---
--- Runs inside adapters.RunApplying at the call site, so anything raised here
--- is reported with its stack intact and the remaining entries still get
--- their turn.
---@param key string
---@param entry table
---@param state table  { badAnchor, pending, anchorsChanged }
---@return boolean changed
---@return boolean anchorOwned
local function applyEntry(key, entry, state)
    local changed, anchorOwned = false, false

    -- No anchor in this entry means the layout makes no attachment claim for
    -- this key, so a record of one resolved earlier is stale. Left behind,
    -- the next capture would compare a live position against a relationship
    -- that no longer exists, read the difference as a drag, and delete an
    -- attachment nobody touched.
    if not entry.anchor then model.ClearResolved(key) end

    if entry.anchor and not state.badAnchor[key] then
        local anchor = entry.anchor
        local channel = resolver.Channel(key, entry)

        if channel == "bitforge" then
            -- One of the seventy-six point/relPoint pairs EllesmereUI's own
            -- five-way `side` mechanism cannot express. Deferred to the
            -- second phase, once every size in this layout has settled,
            -- since resolving reads the target's LIVE edges and this loop is
            -- still changing them.
            state.pending[#state.pending + 1] = key
        else
            -- "eui": a bare anchor, or one of the five point/relPoint pairs
            -- that map onto EllesmereUI's own `side`. Handing it back lets
            -- EllesmereUI own the anchor entirely -- its cascade, its
            -- triggers, its drag-lock -- which beats a one-shot snapshot
            -- whenever it can express the relationship at all. Central and
            -- flat, with no per-module setter to route through, so this is
            -- the one direct write in this file.
            local side = anchor.side
            if anchor.point and anchor.relPoint then
                side = resolver.PairToSide(anchor.point, anchor.relPoint)
            end
            local want = {
                target  = anchor.target,
                side    = side,
                offsetX = anchor.offsetX or 0,
                offsetY = anchor.offsetY or 0,
            }
            if not sameAnchor(adapters.ReadAnchor(key), want) then
                adapters.WriteAnchor(key, want)
                changed = true
                state.anchorsChanged = true
            end
            -- Whatever was resolved for this key before is no longer ours.
            model.ClearResolved(key)
        end

        -- Either way the anchor owns the position: plain coordinates must not
        -- also be written below.
        anchorOwned = true
    end

    -- WIDER THAN THE REFERENCE IMPLEMENTATION, deliberately. EllesmereUI's own
    -- layer flush gates the whole position write on `e.point` alone
    -- (`EllesmereUI_SpecOverrides.lua:2020-2021` -- fact 6), which drops an
    -- entry naming a coordinate and no point on the floor without a word. This
    -- honours it instead, at the price of the `or` defaults just below: an
    -- entry carrying only `x` is applied with CENTER and y=0 invented around
    -- it.
    --
    -- That trade only ever falls on a HAND-EDITED SavedVariable now.
    -- control/editor.lua's Commit completes the whole triple from the element's
    -- live position whenever a pending edit touches any of point/relPoint/x/y,
    -- or clears an anchor, so the editor cannot produce a partial entry at all;
    -- and control/sync.lua's own capture always writes a point. Narrowing this
    -- back to `entry.point` would therefore change nothing the module writes --
    -- only what it is willing to read back from a file the player edited by
    -- hand, and silence is the worse answer there.
    --
    -- Not symmetrical, and knowingly so: a bare `relPoint` is still skipped.
    -- Honouring one would mean inventing the child's OWN corner from nothing,
    -- which is a larger fabrication than the two defaults above, and the editor
    -- can no longer produce that shape either.
    if not anchorOwned and (entry.point or entry.x or entry.y) then
        if adapters.IsAnchored(key) then
            -- Positioned by an EllesmereUI anchor this layout does not
            -- mention at all. Writing coordinates here would fight a system
            -- that will win.
            anchorOwned = true
        else
            local point = entry.point or "CENTER"
            local relPoint = entry.relPoint or point
            local x, y = entry.x or 0, entry.y or 0

            if not samePosition(adapters.ReadPosition(key), point, relPoint, x, y) then
                if adapters.WritePosition(key, point, relPoint, x, y) then
                    -- WritePosition is not guaranteed to move the frame:
                    -- some of EllesmereUI's setters record and stop. Applying
                    -- unconditionally is what its own flush does.
                    adapters.ApplyPosition(key)
                    changed = true
                end
            end
        end
    end

    if entry.w or entry.h then
        local currentWidth, currentHeight = adapters.ReadSize(key)
        local wantsWidth = entry.w ~= nil
            and not (currentWidth and math.abs(currentWidth - entry.w) < SIZE_EPSILON)
        local wantsHeight = entry.h ~= nil
            and not (currentHeight and math.abs(currentHeight - entry.h) < SIZE_EPSILON)

        -- WriteSize attempts both setters whenever either is present, so it is
        -- called once with whichever dimension is not changing held at its
        -- current value.
        if wantsWidth or wantsHeight then
            if adapters.WriteSize(key, entry.w or currentWidth, entry.h or currentHeight) then
                changed = true
            end
        end
    end

    return changed, anchorOwned
end

--- Second-phase work for one extended anchor: resolve it against the
--- target's now-final geometry, via control/resolver.lua, and write the
--- result through the adapter boundary.
---
--- Runs inside adapters.RunApplying at the call site, like applyEntry.
---@param key string
---@param entry table
---@param state table  { bad, resolved, anchorsChanged }
---@return boolean changed
local function resolvePendingEntry(key, entry, state)
    local resolvedPosition, reason = resolver.ResolveExtended(key, entry)
    if not resolvedPosition then
        -- RESOLVE FIRST, REPORT AFTER: a target whose frame has no rectangle
        -- yet (`norect`) is the ordinary state of a normal login, not a
        -- broken layout.
        state.bad[#state.bad + 1] = { key = key, target = entry.anchor.target, reason = reason }
        return false
    end

    local changed = false

    -- EllesmereUI must not also hold a bare anchor for this key, or its
    -- cascade keeps repositioning the element behind this write.
    if adapters.ReadAnchor(key) then
        adapters.WriteAnchor(key, nil)
        changed = true
        state.anchorsChanged = true
    end

    if not samePosition(adapters.ReadPosition(key), resolvedPosition.point, resolvedPosition.relPoint,
        resolvedPosition.x, resolvedPosition.y) then
        if adapters.WritePosition(key, resolvedPosition.point, resolvedPosition.relPoint,
            resolvedPosition.x, resolvedPosition.y) then
            adapters.ApplyPosition(key)
            changed = true
        end
    end

    -- Record what EllesmereUI now HOLDS because of this write, not merely
    -- what was computed: a setter that transforms the value on the way in
    -- would otherwise read back as a drag on the next capture. resolver
    -- already recorded the computed value as a fallback on its way out; this
    -- corrects it against the actual stored value when the two differ.
    local stored = adapters.ReadPosition(key)
    if stored and stored.point then
        model.SetResolved(key, stored.point, stored.relPoint or stored.point, stored.x, stored.y)
    end

    state.resolved = state.resolved + 1
    return changed
end

--- EllesmereUI stores CENTER/CENTER coordinates as an offset from UIParent's
--- centre. Reporting the same convention means a captured value is directly
--- comparable with a stored one, and directly editable by hand.
---@param frame table|nil
---@return number|nil centerX
---@return number|nil centerY
local function centreOffset(frame)
    if not frame then return nil end
    local left, right = frame:GetLeft(), frame:GetRight()
    local bottom, top = frame:GetBottom(), frame:GetTop()
    if not (left and right and bottom and top) then return nil end

    local ratio = (frame:GetEffectiveScale() or 1) / (UIParent:GetEffectiveScale() or 1)
    local centerX = ((left + right) / 2) * ratio - (UIParent:GetWidth() or 0) / 2
    local centerY = ((bottom + top) / 2) * ratio - (UIParent:GetHeight() or 0) / 2
    return centerX, centerY
end

--- Should this extended anchor survive the capture? "No record" means Apply
--- never wrote a position for this key -- refused, or never ran -- so nothing
--- here is evidence of anything; a drag is only detectable by comparing
--- against a record this module made. Capture cannot recompute the answer
--- either: if the target moved since the last apply, a fresh computation
--- differs for reasons that are not a drag, so this compares against what was
--- recorded writing, and only a genuine mismatch counts as a player move.
---@param key string
---@return boolean
local function anchorSurvives(key)
    local record = model.GetResolved()[key]
    if not record then return true end

    local position = adapters.ReadPosition(key)
    if not position then return true end

    return position.point == record.point
        and (position.relPoint or position.point) == record.relPoint
        and position.x == record.x
        and position.y == record.y
end

--- One element's captured entry: its anchor if EllesmereUI owns one, else its
--- stored position, else a measurement of the live frame for an element that
--- has never been moved.
---
--- Never records a size: EllesmereUI reports a live size, not a stored one,
--- so a snapshot of it would start applying a size nobody asked for. A size
--- only ever enters the layout by a player's own hand (the editor), and the
--- caller carries a previous entry's size forward so rebuilding the layout
--- does not erase it.
---@param key string
---@param element table
---@return table|nil
local function captureOne(key, element)
    local anchor = adapters.ReadAnchor(key)
    if anchor and anchor.target then
        return {
            anchor = {
                target  = anchor.target,
                side    = anchor.side,
                offsetX = anchor.offsetX or 0,
                offsetY = anchor.offsetY or 0,
            },
        }
    end

    local position = adapters.ReadPosition(key)
    if position and position.point then
        local entry = { point = position.point, x = position.x or 0, y = position.y or 0 }
        -- Only carried when it genuinely differs: applying falls back to
        -- point when relPoint is absent, so a matching pair is stored once
        -- rather than twice.
        if position.relPoint and position.relPoint ~= position.point then
            entry.relPoint = position.relPoint
        end
        return entry
    end

    local centerX, centerY = centreOffset(element.getFrame and element.getFrame(key))
    if centerX then
        return { point = "CENTER", x = centerX, y = centerY }
    end

    return nil
end

-- Set by the pass that seeds, so a second pass of the SAME login re-captures
-- instead of applying. Without it the second pass would push the freshly
-- seeded layout back into EllesmereUI -- writing positions for elements that
-- had none, exactly the rearrangement seeding exists to avoid.
local seededThisSession = false

---@class BitForge.EUI.Control.Sync
local sync = {}

--- Snapshot EllesmereUI's current geometry into the layout. Reads the live
--- registry rather than EllesmereUI's own SavedVariables, which only record
--- an element that has been moved -- a default-positioned element leaves no
--- trace there, which would make a first-run seed silently incomplete.
---@return number count
---@return table detached  sorted keys whose extended anchor was dropped
---                         because something other than this module moved them
function sync.Capture()
    local elements = adapters.Elements()
    if not elements then return 0, {} end

    local previous = model.GetLayout()
    local layout, detached = {}, {}
    local count = 0

    for key, element in pairs(elements) do
        -- One element's getter raising must not cost the whole snapshot; a
        -- partial layout is recoverable, a failed seed is not.
        local ok, entry = xpcall(captureOne, CallErrorHandler, key, element)
        if ok and entry then
            local previousEntry = previous[key]
            local wasExtended = previousEntry and previousEntry.anchor
                and previousEntry.anchor.point and previousEntry.anchor.relPoint

            if wasExtended then
                -- anchorSurvives reads the element's own position a second
                -- time, outside captureOne's guard -- so it needs its own.
                local survivesOk, survives = xpcall(anchorSurvives, CallErrorHandler, key)
                -- A raise leaves nothing established, which is not evidence
                -- of a drag either -- so the anchor is kept.
                if (not survivesOk) or survives then
                    entry = previousEntry
                else
                    detached[#detached + 1] = key
                    model.ClearResolved(key)
                end
            end

            if previousEntry and entry ~= previousEntry then
                if entry.w == nil then entry.w = previousEntry.w end
                if entry.h == nil then entry.h = previousEntry.h end
            end

            layout[key] = entry
            count = count + 1
        end
    end

    -- Anything the registry did not account for -- an element belonging to a
    -- disabled EllesmereUI module never registers -- is carried forward
    -- untouched rather than dropped. Not added to `count`: that reports what
    -- was read from EllesmereUI this session, and these were not.
    for key, entry in pairs(previous) do
        if layout[key] == nil then layout[key] = entry end
    end

    table.sort(detached)

    -- model exposes a per-key setter, not a whole-table replace. Every
    -- previous key is guaranteed present above (recaptured or carried
    -- forward), so writing key by key here never drops one.
    for key, entry in pairs(layout) do
        model.SetLayoutEntry(key, entry)
    end

    return count, detached
end

--- Push the saved layout into EllesmereUI. One shot: EllesmereUI owns the
--- result afterwards.
---@return table  { applied, unchanged, anchorOwned, resolved, unknown,
---                  badAnchors, failed, refused, noEllesmere }
function sync.Apply()
    local result = {
        applied     = 0,
        unchanged   = 0,
        anchorOwned = 0,
        resolved    = 0,
        unknown     = {},
        badAnchors  = {},
        failed      = {},
        refused     = false,
    }

    -- Action bars are SecureHandlerStateTemplate frames and genuinely
    -- protected; SetPoint on them is blocked in combat. Refusing wholesale
    -- beats applying half a layout and leaving the rest for the player to
    -- wonder about.
    if InCombatLockdown() then
        result.refused = true
        return result
    end

    if not adapters.IsPresent() then
        result.refused = true
        result.noEllesmere = true
        return result
    end

    local layout = model.GetLayout()
    local elements = adapters.Elements()

    -- Deterministic order: a run over a hash table would otherwise report its
    -- unknown keys in a different order each time.
    local keys = {}
    for key in pairs(layout) do keys[#keys + 1] = key end
    table.sort(keys)

    -- Resolved before anything is written, so a refused anchor never reaches
    -- EllesmereUI and a cycle is caught as a whole rather than one edge at a
    -- time.
    result.badAnchors = resolver.FindBadAnchors(layout)
    local badAnchor = {}
    for _, bad in ipairs(result.badAnchors) do badAnchor[bad.key] = bad.reason end

    -- `pending` collects the extended anchors for the second phase; `bad` is
    -- result.badAnchors, which that phase appends to when a resolve fails.
    local state = {
        anchorsChanged = false,
        badAnchor      = badAnchor,
        bad            = result.badAnchors,
        pending        = {},
        resolved       = 0,
    }
    local counted = {}
    local failedKeys = {}

    adapters.RunApplying(function()
        for _, key in ipairs(keys) do
            local element = elements[key]
            if not element then
                result.unknown[#result.unknown + 1] = key
            else
                -- xpcall, not pcall: the handler runs at the raise, where the
                -- element's frame and locals are still live, so BugGrabber
                -- gets a real stack. One bad element must not cost the rest
                -- of the layout.
                local ok, changed, anchorOwned = xpcall(applyEntry, CallErrorHandler, key, layout[key], state)
                if not ok then
                    result.failed[#result.failed + 1] = key
                    failedKeys[key] = true
                else
                    if anchorOwned then result.anchorOwned = result.anchorOwned + 1 end
                    if changed then
                        result.applied = result.applied + 1
                        counted[key] = true
                    elseif not anchorOwned then
                        result.unchanged = result.unchanged + 1
                    end
                end
            end
        end
    end)

    if state.anchorsChanged then
        adapters.ReapplyAnchors()
    end

    -- SECOND PHASE: the anchors EllesmereUI cannot express. Resolution reads
    -- live edges, so it has to happen after every size and every EllesmereUI-
    -- owned anchor in this layout has settled -- which also makes a mixed
    -- chain work: EllesmereUI's own anchor first, this module's hanging off
    -- the element it just moved.
    if #state.pending > 0 then
        local phaseChanged = false

        adapters.RunApplying(function()
            for _, key in ipairs(state.pending) do
                local ok, changed = xpcall(resolvePendingEntry, CallErrorHandler, key, layout[key], state)
                if not ok then
                    -- An element whose size write raised is already listed:
                    -- applyEntry collected it for this phase before the
                    -- raise, and its anchor is worth attempting regardless.
                    -- Listing it twice is not.
                    if not failedKeys[key] then
                        result.failed[#result.failed + 1] = key
                        failedKeys[key] = true
                    end
                elseif changed then
                    phaseChanged = true
                    if not counted[key] then
                        result.applied = result.applied + 1
                        counted[key] = true
                    end
                end
            end
        end)

        -- A resolved element can itself be the target of one of EllesmereUI's
        -- own anchors, and clearing an anchor above changes what its cascade
        -- covers. Guarded, so a run that resolved nothing new stays a no-op.
        if phaseChanged then
            adapters.ReapplyAnchors()
        end
    end

    -- FindBadAnchors sorts; the second phase appends. Sorting again keeps the
    -- report identical from one run to the next.
    table.sort(result.badAnchors, function(a, b) return a.key < b.key end)

    -- Same rule as above, for keys this layout does not mention at all: this
    -- run never visits them, so nothing in the pass could have cleared their
    -- records. Collected first rather than deleted mid-traversal, so the
    -- loop reads unambiguously.
    local orphans = {}
    for key in pairs(model.GetResolved()) do
        if layout[key] == nil then orphans[#orphans + 1] = key end
    end
    for _, key in ipairs(orphans) do model.ClearResolved(key) end

    result.resolved = state.resolved

    return result
end

--- The three-way login branch: seed on the first run, re-capture on a second
--- pass of the same seeding login, apply on every later login.
---
--- Returns Apply's own result table on the branch that reaches it, and
--- nothing on the other two -- control.lua's login timer callback reads this
--- to tell a combat refusal from a pass that never attempted one, without
--- control.lua having to re-derive which branch this call took.
---@return table|nil result  control.sync.Apply()'s result, when this pass ran it
function sync.SeedOrApply()
    if not adapters.IsPresent() then return end

    -- Anchors first: a layout entry may target one, and Apply validates
    -- targets against the live registry. Built here, before the branch,
    -- rather than left to Apply's own call further down -- building it late
    -- would make the first login pass refuse an anchor that works on the
    -- second, which reads as an intermittent timing bug.
    local _, refusals = resolver.BuildAnchorFrames()
    for _, refusal in ipairs(refusals) do
        BitForge:Print(resolver.FormatRefusal(refusal))
    end

    if not model.IsSeeded() then
        -- First run. Record where everything already is and move nothing: a
        -- player installing this module has not asked for their UI to be
        -- rearranged.
        local count = sync.Capture()

        -- An empty registry is legitimate rather than an error -- adapters
        -- .IsPresent answers yes to one with nothing in it (fact 1,
        -- docs/eui-integration.md) -- but it is not a seed. A pass that read
        -- nothing recorded nothing, and stamping the profile on the strength of
        -- it would leave every element reading as unmanaged for good, with
        -- nothing short of a hand-typed /bitforge eui capture able to undo it.
        -- Left unstamped, the second pass of this login -- or the next login --
        -- seeds instead.
        if count > 0 then
            model.SetSeeded()
            seededThisSession = true
            BitForge:Print(format(locale["capture:seeded"], count))
        end
        return
    end

    if seededThisSession then
        -- Same login, later pass: fold in anything that registered late
        -- rather than applying a layout the player has not had a chance to
        -- edit yet.
        sync.Capture()
        return
    end

    return sync.Apply()
end

--- Clears the same-login seeding flag. Module-local upvalue, not saved state:
--- a fresh login always starts here, so this exists for tests to reset it
--- between scenarios.
function sync.ResetSession()
    seededThisSession = false
end

--- Counts layout entries whose anchor carries BOTH point and relPoint -- the
--- extended anchors EllesmereUI cannot express and therefore cannot preserve
--- across a drag. A bare `side` anchor is EllesmereUI's own and is not at
--- risk here.
---
--- Only entries with a Resolved record count: that record means Apply
--- actually wrote a position for this key, and only those are at risk from a
--- drag. An anchor Apply refused was never written, so dragging that element
--- destroys nothing -- warning about it would claim something was attached
--- when nothing was.
---@return number
function sync.CountAttached()
    local layout = model.GetLayout()
    local resolved = model.GetResolved()
    local count = 0

    for key, entry in pairs(layout) do
        local anchor = type(entry) == "table" and entry.anchor
        if anchor and anchor.point and anchor.relPoint and resolved[key] then
            count = count + 1
        end
    end

    return count
end

control.sync = sync

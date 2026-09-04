---@class BitForge.AzerothPrime
local ns = select(2, ...)

local ipairs = ipairs
local C_Item = C_Item
local C_Timer = C_Timer

local enum = ns.enum
local model = ns.model
local view = ns.view

---@class BitForge.AzerothPrime.Control
local control = ns.control
local detector = control.detector

---@class BitForge.AzerothPrime.Control.OpenScanner
local openScanner = {}

local current
local ranked
local scanQueued = false
local pendingItems = {}

--- Start an async load for an item's data, returning true when one was needed.
---
--- onItemDataLoaded discards any result whose itemID is not pending, so a
--- caller that requests a load on its own never hears back about it.
---@param itemID number
---@return boolean started
function openScanner.RequestItemData(itemID)
    if C_Item.IsItemDataCachedByID(itemID) then return false end
    pendingItems[itemID] = true
    C_Item.RequestLoadItemDataByID(itemID)
    return true
end

function openScanner.GetCurrent()
    return current
end

--- Whether itemID was awaiting a load this scanner itself requested, clearing
--- it either way.
---
--- pendingItems is private to this file, so control.lua's
--- ITEM_DATA_LOAD_RESULT handler reaches it through here.
---@param itemID number
---@return boolean wasPending
function openScanner.ConsumePendingItem(itemID)
    if not pendingItems[itemID] then return false end
    pendingItems[itemID] = nil
    return true
end

--- The whole ranked field the last scan produced, winner first, or nil when it
--- found nothing.
---
--- The button shows candidates[1] and discards the rest, which is exactly what
--- makes a surprising pick hard to explain: the interesting part is what it
--- beat. Held rather than recomputed so the dump reports the decision that was
--- actually taken, not one taken again against bags that have since changed.
---@return table|nil
function openScanner.GetRanked()
    return ranked
end

local function collectCandidates()
    local candidates = {}
    for _, entry in ipairs(model.facts.Walk()) do
        -- entry.itemID comes free off Walk's own container read rather than
        -- a resolved model.facts.Get record: the itemID has to be in hand
        -- before RequestItemData can ask whether the record behind it is
        -- buildable yet, and Get's own "not loaded" nil answers for an empty
        -- slot and an unloaded item alike, so it cannot tell them apart.
        if not openScanner.RequestItemData(entry.itemID) then
            -- Read here rather than aliased at file scope: debug/ loads
            -- after every control file, so a file-scope alias would hold nil
            -- for the life of the session even on a developer's build.
            local curationReview = control.curationReview
            if curationReview then
                curationReview.ReviewQuestGated(
                    entry.bagIndex, entry.slotIndex, entry.itemID)
            end

            -- The record for this slot, now that RequestItemData confirms
            -- the item data it needs has loaded. entry.slotInfo is handed
            -- through so the container is not read a second time for a slot
            -- Walk has already covered.
            --
            -- Deliberately model.facts.Get and not sellScanner.Gather, and
            -- the difference is the whole cost of this path: Gather runs
            -- supplement(), which is a C_Item.IsCosmeticItem for every slot
            -- plus a C_ToyBox lookup for every Miscellaneous one and a live
            -- tooltip scan for every recipe and battle pet. Gathered here,
            -- that was 250-odd client calls per BAG_UPDATE_DELAYED on a full
            -- bag for slots this path was about to discard.
            local record = model.facts.Get(entry.bagIndex, entry.slotIndex, entry.slotInfo)

            local priority, locked, reason, detail, startsQuest
            if record then
                -- The open claimant alone first, and everything else only for
                -- the slots it actually claimed. An item it abstains on cannot
                -- be awarded OPEN whatever the other two answer, so neither
                -- supplementing the record nor hearing them buys this path
                -- anything -- and neither is free.
                --
                -- Asked through the arbiter rather than model.openRules.Claim
                -- so this ask and Resolve's own are one: the claims entry is
                -- memoised on the record, and Resolve reuses it.
                local openClaim = model.arbiter.Claim(record, model.openRules.CLAIMANT)

                local verdict
                if openClaim.claim == enum.CLAIM.OPEN then
                    -- NOW the supplement, because now the sell claimant is
                    -- going to be asked. Gather writes supplement()'s
                    -- class-scoped fields onto this same cached record and
                    -- hands it back; whichever path resolves a slot first is
                    -- the one whose record every later consumer reads back, so
                    -- resolving one short of those fields would memoise a sell
                    -- answer taken on evidence nobody had gathered.
                    --
                    -- Reached through `control` rather than aliased at the top
                    -- of this file: control/sellScanner.lua loads after this
                    -- one. Guarded, because a raise inside supplement() would
                    -- otherwise take the button down on every bag update --
                    -- SafeGather's own comment argues that in full.
                    local gathered = control.sellScanner.SafeGather(
                        entry.bagIndex, entry.slotIndex, entry.slotInfo)
                    -- One resolution per record per generation -- the sell
                    -- path's own Scan reads this same verdict back rather
                    -- than asking the claimants again.
                    verdict = gathered and model.arbiter.Resolve(gathered) or nil
                end

                if verdict and verdict.disposition == enum.CLAIM.OPEN then
                    priority = verdict.strength
                    reason   = verdict.reason
                    detail   = verdict.detail
                    -- Both are open-path facts the claim contract stops short
                    -- of (model/arbiter.lua's callClaimant says why it carries
                    -- `detail` and not these two). LOCKED_BOX is the only rung
                    -- that reports a lockbox the character can open, so the
                    -- reason IS that fact; startsQuest is the record's own, and
                    -- free here because the ladder's quest rung already
                    -- computed it for every item it walked.
                    locked      = reason == enum.REASON.LOCKED_BOX
                    startsQuest = record.startsQuest
                end
            else
                -- No resolved record, so there is nothing for the sell or bank
                -- claimants to read -- sellScanner.Scan skips this slot for the
                -- same reason, so nothing else resolves it and no claimant is
                -- asked twice. The open ladder still answers, off the partial
                -- record Classify builds, exactly as it did before the arbiter.
                priority, locked, reason, detail, startsQuest =
                    detector.Classify(entry.bagIndex, entry.slotIndex, entry.itemID)
            end

            if priority then
                local startTime, duration = C_Item.GetItemCooldown(entry.itemID)
                candidates[#candidates + 1] = {
                    itemID       = entry.itemID,
                    bag          = entry.bagIndex,
                    slot         = entry.slotIndex,
                    priority     = priority,
                    stackCount   = (record and record.stackCount) or entry.slotInfo.stackCount or 1,
                    onCooldown   = (startTime or 0) > 0 and (duration or 0) > 0,
                    -- The client locks a slot for the duration of a cast
                    -- and unlocks it when the cast ends, however it ended.
                    -- Not `locked`, which is detector.IsLockedBox -- a
                    -- lockbox needing a key, and a different fact.
                    slotLocked   = (record and record.isLocked) or entry.slotInfo.isLocked or false,
                    -- Rank's first key. Boolean, never nil -- see
                    -- model.openRules.IsDeferred.
                    deferred     = model.openRules.IsDeferred(entry.itemID),
                    locked       = locked or false,
                    -- Drives the button's quest bang, so it is state the
                    -- view reads rather than diagnostics.
                    startsQuest  = startsQuest or false,
                    -- Diagnostics for the debug tooltip; see enum.REASON.
                    reason       = reason,
                    reasonDetail = detail,
                }
            end
        end
    end
    return candidates
end

--- Whether a click is still resolving, in which case the button stays as it is.
---
--- The bag slot's lock is what separates a cast in flight from a use that
--- simply failed, and the difference is load-bearing: a failed use changes no
--- bags and never locks, so it is not in flight and the deferral advances the
--- button at once, which is the whole of #39's fix.
---
--- The mark is itemID-scoped, like the deferral it rides beside -- so with the
--- same item stacked across slots (lockboxes, Knowledge Tomes are typical),
--- any locked copy holds. Stopping at the first matching candidate would judge
--- the hold by whichever slot collectCandidates happened to reach first, not
--- the one the cast actually locked.
---
--- Clears the mark as a side effect once it cannot hold. Absent, or present
--- with every copy unlocked, both mean the use resolved -- including an
--- interrupted cast, which is why unlocked releases rather than only absent.
local function holdsForInFlight(candidates)
    local itemID = model.openRules.InFlightItem()
    if not itemID then return false end

    for _, candidate in ipairs(candidates) do
        if candidate.itemID == itemID and candidate.slotLocked then
            return true
        end
    end

    model.openRules.ClearInFlight()
    return false
end

function openScanner.Scan()
    scanQueued = false

    if not model.IsOpenEnabled() then
        current, ranked = nil, nil
        model.openRules.ClearInFlight()
        view.button.ClearItem()
        return
    end

    local candidates = collectCandidates()
    -- A held scan returns before `ranked` is reassigned below, so the
    -- ranked-field dump (/bfdump azerothprime open all) never captures a locked
    -- row -- the single-item report (/bfdump azerothprime open <id>) reads the
    -- slot live and is where a hold is actually visible.
    if holdsForInFlight(candidates) then return end

    if #candidates == 0 then
        current, ranked = nil, nil
        view.button.ClearItem()
        return
    end

    model.openRules.Rank(candidates)
    -- Cleared on both early returns above, so the field never outlives the scan
    -- that produced it and read back as a decision still standing.
    ranked = candidates
    current = candidates[1]
    view.button.SetItem(current)
end

-- Debounced to one scan per frame. A loot burst that empties a container fires
-- many bag events; without this the scan would run for each of them.
function openScanner.RequestScan()
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(enum.RESCAN_DELAY, openScanner.Scan)
end

control.openScanner = openScanner

---@class BitForge.Dispatch
local ns = select(2, ...)

local format = string.format
local wipe = table.wipe
local remove = table.remove

local ClearCursor = ClearCursor
local GetCursorInfo = GetCursorInfo
local InCombatLockdown = InCombatLockdown
local ItemLocation = ItemLocation
local C_Container = C_Container
local C_Bank = C_Bank
local C_Timer = C_Timer

local BankFrame = BankFrame

local model = ns.model
local enum = ns.enum
local locale = ns.locale
local view = ns.view

---@class BitForge.Dispatch.Control
local control = ns.control
local inventory = control.inventory

---@class BitForge.Dispatch.Control.Deposit
local deposit = {}

-- Seconds to wait for BAG_UPDATE_DELAYED to confirm a move before declaring it
-- failed. Generous: the event follows the client's own bag refresh, not ours.
local MOVE_TIMEOUT = 1

local queue = {}
local moved = 0
local running = false
local pendingMove   -- { srcBag, srcSlot, itemID, beforeCount, generation }

-- Bumped for every move issued. The watchdog timer captures the value it was
-- armed with, so a timer left over from a move that already completed cannot
-- fire against the move that replaced it.
local moveGeneration = 0

--- Whether a move may be attempted right now.
---
--- Pure so the ordering is testable. Combat is checked first because it is the
--- condition under which the attempt is most likely to error rather than simply
--- fail, and a caller that reports only one reason should report that one.
---@param bankOpen   boolean
---@param cursorType string|nil  GetCursorInfo()'s first return, nil when empty
---@param isLocked   boolean     the source slot's ContainerItemInfo.isLocked
---@param inCombat   boolean
---@return boolean ok, string|nil localeKey
function deposit.CanMove(bankOpen, cursorType, isLocked, inCombat)
    if inCombat then return false, "msg:blockedCombat" end
    if not bankOpen then return false, "msg:blockedBankClosed" end
    if cursorType ~= nil then return false, "msg:blockedCursor" end
    if isLocked then return false, "msg:blockedLocked" end
    return true, nil
end

--- Whether the source slot shows the move completed.
---
--- C_Container.PickupContainerItem returns nothing, so success cannot be read
--- from the call. Re-reading the slot is the only honest signal: an empty slot,
--- or a smaller stack, means the client acted.
---@param beforeCount number
---@param afterCount  number|nil  nil when the slot is now empty
---@return boolean
function deposit.DidMoveComplete(beforeCount, afterCount)
    if afterCount == nil then return true end
    -- A smaller stack means the client moved part of it -- the destination slot
    -- held a partial stack of the same item and absorbed only what fit. The
    -- remainder is deliberately abandoned here rather than chased with a second
    -- move: the next run snapshots the bags again and collects it.
    return afterCount < beforeCount
end

function deposit.IsRunning()
    return running
end

--- Carried-bag slots (keyed "bag:slot", control/control.lua's own scheme for
--- the same shape) the arbiter has awarded away from the bank claimant, to
--- OPEN or SELL. BuildPlan drops these even though bankRules.ResolveByRule
--- alone would still send them somewhere; model.bankRules.PlanMoves and
--- everything it calls are untouched, so a slot that survives this filter is
--- resolved exactly as it always was.
---
--- Only a slot the bank claimant itself wants is worth a full
--- model.arbiter.Resolve -- the same gate control/openScanner.lua applies to
--- its own claimant, and for the same reason: a slot bank never considers
--- pays nothing more here, and Resolve is what is needed to tell "bank
--- claims it and nothing outranks it" from "bank claims it, but OPEN or SELL
--- do".
---
--- Gathered through control.sellScanner.Gather rather than a bare
--- model.facts.Get, for the reason control/openScanner.lua's own comment
--- gives: Resolve asks the sell claimant too, and a record short of
--- supplement()'s class-scoped fields would memoise a sell answer taken on
--- evidence that had not been gathered yet -- for the rest of the
--- generation, not just for this call. Reached through `control` rather than
--- aliased at the top of this file for the same load-order reason
--- openScanner.lua gives: control/sellScanner.lua loads after this one.
---
--- A carried-bag slot always has a bag:slot to build a record from; when that
--- record cannot resolve yet (item data not cached), the slot carries no key
--- here and BuildPlan below lets PlanMoves decide it the way it always has --
--- the same fallback a bank-tab entry gets in the warband snapshot, because a
--- bank tab has no bag slot and so never has a record at all (#348).
---@return table  { ["bag:slot"] = true }
local function bankOutrankedSlots()
    local outranked = {}
    for _, entry in ipairs(model.facts.Walk()) do
        -- model.facts.Get, not sellScanner.Gather, for the reason
        -- control/openScanner.lua's own gate gives: bankRules.Claim reads
        -- facts.itemID and nothing else, so supplement()'s class-scoped
        -- lookups buy this ask nothing, and a slot the bank does not claim is
        -- discarded before they could matter.
        local record = model.facts.Get(entry.bagIndex, entry.slotIndex, entry.slotInfo)
        if record then
            local bankClaim = model.arbiter.Claim(record, model.bankRules.CLAIMANT)
            if bankClaim.claim then
                -- Now the supplement, because now the sell claimant is going
                -- to be asked. Guarded for the reason SafeGather gives.
                local gathered = control.sellScanner.SafeGather(
                    entry.bagIndex, entry.slotIndex, entry.slotInfo)
                local verdict = gathered and model.arbiter.Resolve(gathered) or nil
                if verdict and verdict.claimant ~= model.bankRules.CLAIMANT then
                    outranked[entry.bagIndex .. ":" .. entry.slotIndex] = true
                end
            end
        end
    end
    return outranked
end

--- Snapshots both sources and returns the plan for them.
---
--- The warband tabs are read only when some private override exists. That read
--- walks every purchased tab and is the most expensive thing the module does,
--- and until a user curates a private item there is nothing in shared storage
--- the reclaim pass could ever claim.
---
--- The carried-bag snapshot is filtered against bankOutrankedSlots before it
--- ever reaches PlanMoves, so an item the arbiter awarded to OPEN or SELL
--- this generation is never offered to the planner at all. The warband
--- snapshot is not filtered -- see bankOutrankedSlots' own comment for why a
--- bank tab has no record to arbitrate.
---@return table plan
function deposit.BuildPlan()
    local warbandSnapshot
    if model.HasPrivateOverrides() then
        warbandSnapshot = inventory.Snapshot(inventory.GetWarbandTabs())
    end

    local outranked = bankOutrankedSlots()
    local bagSnapshot = {}
    for _, entry in ipairs(inventory.Snapshot()) do
        if not outranked[entry.bag .. ":" .. entry.slot] then
            bagSnapshot[#bagSnapshot + 1] = entry
        end
    end

    return model.bankRules.PlanMoves(bagSnapshot, warbandSnapshot, inventory.Holdings())
end

local function finish(reasonKey)
    running = false
    pendingMove = nil
    wipe(queue)

    if view.bankButton then
        view.bankButton.SetIdle()
    end

    if reasonKey then
        BitForge:Print(locale[reasonKey])
        -- A run that stops partway still moved something, and the player has no
        -- other way to tell how much. Reuse the completion line rather than
        -- inventing a partial-stop string for every block reason.
        if moved > 0 then
            BitForge:Print(format(locale["msg:done"], moved))
        end
    elseif moved == 0 then
        BitForge:Print(locale["msg:nothingToDo"])
    else
        BitForge:Print(format(locale["msg:done"], moved))
    end

    moved = 0
end

local executeNext

--- Confirms the outstanding move, then starts the next one. Driven by
--- BAG_UPDATE_DELAYED rather than a timer: a timer fires on the next frame
--- whether or not the client has processed anything.
function deposit.OnBagUpdateDelayed()
    if not pendingMove then return end

    local info = C_Container.GetContainerItemInfo(pendingMove.srcBag, pendingMove.srcSlot)
    local afterCount = info and info.stackCount or nil

    if not deposit.DidMoveComplete(pendingMove.beforeCount, afterCount) then
        ClearCursor()
        finish("msg:moveFailed")
        return
    end

    moved = moved + 1
    pendingMove = nil

    if view.bankButton then
        view.bankButton.SetWorking(moved)
    end

    executeNext()
end

executeNext = function()
    local descriptor = remove(queue, 1)
    if not descriptor then
        finish(nil)
        return
    end

    local info = C_Container.GetContainerItemInfo(descriptor.srcBag, descriptor.srcSlot)
    -- The slot emptied or changed hands between planning and now, or the item's
    -- destination changed while the preview sat open -- the curation window is a
    -- live writer. Re-resolving here makes "only what the user asked for moves"
    -- a rule enforced at the point of action, not a property that happens to
    -- hold because nothing writes overrides. ResolveMove is asked the same
    -- question the planner asked it, which is what descriptor.fromWarband is
    -- carried for.
    -- None of these are failures; skip the descriptor and carry on.
    if not info or info.itemID ~= descriptor.itemID
        or model.bankRules.ResolveMove(info.itemID, descriptor.fromWarband) ~= descriptor.destination then
        executeNext()
        return
    end

    local toPrivate = descriptor.destination == enum.DESTINATION.PRIVATE
    local bankType = toPrivate and Enum.BankType.Character or Enum.BankType.Account

    -- Resolve classifies by item class, which cannot see that a soulbound or
    -- otherwise non-transferable reagent is refused by the destination bank.
    -- Asking the client is the only reliable test. Skipping keeps one such item
    -- from aborting every deposit the player attempts for the rest of the session.
    local itemLocation = ItemLocation:CreateFromBagAndSlot(descriptor.srcBag, descriptor.srcSlot)
    if not C_Bank.IsItemAllowedInBankType(bankType, itemLocation) then
        executeNext()
        return
    end

    local cursorType = GetCursorInfo()
    local ok, reasonKey = deposit.CanMove(
        BankFrame and BankFrame:IsShown() or false,
        cursorType,
        info.isLocked and true or false,
        InCombatLockdown())

    if not ok then
        finish(reasonKey)
        return
    end

    local destBag, destSlot
    if toPrivate then
        destBag, destSlot = inventory.FindFreePrivateSlot()
    else
        destBag, destSlot = inventory.FindFreeWarbandSlot()
    end

    if not destBag then
        finish(toPrivate and "msg:noVacancyPrivate" or "msg:noVacancy")
        return
    end

    moveGeneration = moveGeneration + 1
    local thisGeneration = moveGeneration

    local beforeCount = info.stackCount or 1

    pendingMove = {
        srcBag      = descriptor.srcBag,
        srcSlot     = descriptor.srcSlot,
        itemID      = descriptor.itemID,
        beforeCount = beforeCount,
        generation  = thisGeneration,
    }

    -- A target quantity can call for part of a stack. Splitting puts only that
    -- part on the cursor, so the drop cannot overflow the destination slot and
    -- leave a remainder held -- which the next executeNext would read as
    -- blockedCursor and stop the run over.
    if descriptor.count < beforeCount then
        C_Container.SplitContainerItem(descriptor.srcBag, descriptor.srcSlot, descriptor.count)
    else
        C_Container.PickupContainerItem(descriptor.srcBag, descriptor.srcSlot)
    end
    C_Container.PickupContainerItem(destBag, destSlot)

    -- A refused drop changes no bag contents, so BAG_UPDATE_DELAYED never fires
    -- and nothing would ever clear pendingMove: the run would hang forever with
    -- the item stranded on the cursor. The pre-flight check above cannot see
    -- every refusal -- the destination slot can fill between FindFreeWarbandSlot
    -- and the drop -- so the timer is the backstop that always releases both.
    C_Timer.After(MOVE_TIMEOUT, function()
        if pendingMove and pendingMove.generation == thisGeneration then
            ClearCursor()
            finish("msg:moveFailed")
        end
    end)
end

--- Runs a plan to completion. Ignored when one is already running.
---@param plan table  from deposit.BuildPlan or model.bankRules.PlanMoves
function deposit.Start(plan)
    if running then return end
    if not model.IsBankEnabled() then return end

    wipe(queue)
    for index = 1, #plan do
        queue[index] = plan[index]
    end

    moved = 0
    running = true

    if view.bankButton then
        view.bankButton.SetWorking(0)
    end

    executeNext()
end

--- Aborts a run in flight, e.g. because the bank frame just closed. A move
--- issued into a bank that just closed may never report back at all, so the
--- caller must not wait for the next OnBagUpdateDelayed to discover it.
function deposit.Abort(reasonKey)
    if not running then return end
    if pendingMove then ClearCursor() end
    finish(reasonKey)
end

--- The single entry point. Builds a plan, shows it for confirmation when the
--- preview is on, and otherwise runs it straight away.
function deposit.Run()
    if running then return end
    if not model.IsBankEnabled() then return end

    local plan = deposit.BuildPlan()

    if #plan == 0 then
        BitForge:Print(locale["msg:nothingToDo"])
        return
    end

    if model.GetPreviewMoves() then
        view.previewDialog.Show(plan, deposit.Start)
    else
        deposit.Start(plan)
    end
end

control.deposit = deposit

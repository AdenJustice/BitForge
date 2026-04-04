---@class BitForge.UPS
local ns = select(2, ...)

local model = ns.model
local enum = ns.enum
local locale = ns.locale
local view = ns.view
local events = BitForge.Events

---@class BitForge.UPS.Control
local control = ns.control

function ns:Subscribe(event, callback)
    BitForge.Subscribe(event, callback, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

local ipairs = ipairs

local BankFrame = BankFrame
local C_Bank = C_Bank
local C_Container = C_Container

-- ================================================================================
-- Inventory
-- ================================================================================

---@class BitForge.UPS.Control.Inventory
local inventory = {}

--- The warband bank tabs this account has actually purchased.
---
--- Enumerated rather than hardcoded: a fixed AccountBankTab_1..5 list walks tabs
--- the player may not own and stops being correct the day Blizzard adds one.
---@return table  array of Enum.BagIndex, empty when none are purchased
function inventory.GetWarbandTabs()
    return C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Account) or {}
end

--- The character bank tabs this character has actually purchased.
---
--- Enumerated for the same reason the warband tabs are: only purchased tabs
--- exist, and a fixed list stops being correct the day Blizzard adds one.
---@return table  array of Enum.BagIndex, empty when none are purchased
function inventory.GetCharacterBankTabs()
    return C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character) or {}
end

--- Snapshot of every occupied slot across a list of containers.
---
--- The deposit planner's sole input, called with no argument for the carried
--- bags. The curation source passes an explicit list, which is the only
--- difference between reading a bag and reading a bank tab.
---@param containers table|nil  defaults to the carried bags
---@return table  { { bag, slot, itemID, count }, ... }
function inventory.Snapshot(containers)
    local snapshot = {}

    for _, bag in ipairs(containers or enum.BAG_INDICES) do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                snapshot[#snapshot + 1] = {
                    bag    = bag,
                    slot   = slot,
                    itemID = info.itemID,
                    count  = info.stackCount or 1,
                }
            end
        end
    end

    return snapshot
end

--- Everything the built-in curation source can see.
---
--- The carried bags always; both banks' purchased tabs only while a bank is
--- open. Tab contents are unreadable with the frame down, so listing them
--- unconditionally would report an empty bank as an accurate one and the user
--- would curate against a list silently missing everything they have stored.
---@return table  array of Enum.BagIndex
function inventory.GetCurationContainers()
    local containers = {}

    for _, bag in ipairs(enum.BAG_INDICES) do
        containers[#containers + 1] = bag
    end

    if BankFrame and BankFrame:IsShown() then
        for _, tab in ipairs(inventory.GetCharacterBankTabs()) do
            containers[#containers + 1] = tab
        end
        for _, tab in ipairs(inventory.GetWarbandTabs()) do
            containers[#containers + 1] = tab
        end
    end

    return containers
end

--- First empty slot across a list of tabs.
--- Called immediately before each move, never at plan time.
---@param tabs table  array of Enum.BagIndex
---@return number|nil bag, number|nil slot
function inventory.FindFreeSlot(tabs)
    for _, tab in ipairs(tabs) do
        local numSlots = C_Container.GetContainerNumSlots(tab)
        for slot = 1, numSlots do
            if not C_Container.GetContainerItemInfo(tab, slot) then
                return tab, slot
            end
        end
    end
    return nil, nil
end

---@return number|nil bag, number|nil slot
function inventory.FindFreeWarbandSlot()
    return inventory.FindFreeSlot(inventory.GetWarbandTabs())
end

---@return number|nil bag, number|nil slot
function inventory.FindFreePrivateSlot()
    return inventory.FindFreeSlot(inventory.GetCharacterBankTabs())
end

--- How much of each item the current character already has to hand.
---
--- Their carried bags plus their own bank, and deliberately not the warband
--- bank: this is what a target quantity is measured against, and the whole
--- point of a target is to decide how much to take *out* of shared storage.
--- Counting shared storage as "already have" would make every target read as
--- met and the reclaim pass would take nothing.
---@return table  { [itemID] = count }
function inventory.Holdings()
    local holdings = {}

    local containers = {}
    for _, bag in ipairs(enum.BAG_INDICES) do
        containers[#containers + 1] = bag
    end
    for _, tab in ipairs(inventory.GetCharacterBankTabs()) do
        containers[#containers + 1] = tab
    end

    for _, entry in ipairs(inventory.Snapshot(containers)) do
        holdings[entry.itemID] = (holdings[entry.itemID] or 0) + entry.count
    end

    return holdings
end

local format = string.format
local wipe = table.wipe
local remove = table.remove

local ClearCursor = ClearCursor
local GetCursorInfo = GetCursorInfo
local InCombatLockdown = InCombatLockdown
local ItemLocation = ItemLocation
local C_Timer = C_Timer

local GetProfessions = GetProfessions
local GetProfessionInfo = GetProfessionInfo
local C_TradeSkillUI = C_TradeSkillUI
local time = time

-- ================================================================================
-- Recipes
-- ================================================================================

---@class BitForge.UPS.Control.Recipes
local recipes = {}

-- [skillLineID] = true. The prompt is the only path to a scan --
-- C_TradeSkillUI.OpenTradeSkill is protected, so UPS cannot open a profession
-- window itself; repeating the prompt every login would be nagging about
-- something the player may have decided not to do.
local prompted = {}

--- The current character's professions, read live from the client.
---
--- GetProfessions returns five slot indices with holes in it -- a character with
--- no archaeology gets nil in the third position -- so the returns are indexed
--- positionally rather than walked, which would stop at the first hole.
---@return table  { { skillLineID = number, profession = number, name = string }, ... }
function recipes.ReadProfessions()
    local found = {}

    local first, second, archaeology, fishing, cooking = GetProfessions()
    local slots = { first, second, archaeology, fishing, cooking }

    for index = 1, 5 do
        local slot = slots[index]
        if slot then
            -- skillLine is return 7 of 10.
            local _, _, _, _, _, _, skillLineID = GetProfessionInfo(slot)
            if skillLineID then
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                -- ProfessionInfo.profession is Nilable
                -- (TradeSkillUITypesDocumentation.lua:361-376). A nil means the
                -- client has no Enum.Profession for this line, and a nil is not
                -- something WantedByAlt could ever match, so the slot is skipped.
                if info and info.profession ~= nil then
                    found[#found + 1] = {
                        skillLineID = skillLineID,
                        profession  = info.profession,
                        name        = info.professionName,
                    }
                end
            end
        end
    end

    return found
end

--- Writes the current character's professions into the DB, replacing whatever
--- was there. Replacement rather than merge: dropping a profession has to be
--- able to remove it, or an alt would go on wanting recipes for a profession
--- they no longer have.
function recipes.RecordProfessions()
    local charKey = BitForge:GetCurrentCharacter()
    local list = {}

    for _, entry in ipairs(recipes.ReadProfessions()) do
        list[#list + 1] = entry.profession
    end

    model.SetProfessions(charKey, list)
end

--- Records which recipes of one skill line the current character has learned.
---
--- Adds what the walk reports learned and retracts what it reports unlearned,
--- and touches nothing else. GetFilteredRecipeIDs honours the player's active
--- filters, so a recipe can be missing from the walk entirely; leaving those
--- alone makes a filtered scan incomplete rather than wrong.
---@param skillLineID number
---@return number learned  how many recipes were seen learned
function recipes.HarvestSkillLine(skillLineID)
    local charKey = BitForge:GetCurrentCharacter()
    local seen = 0

    for _, recipeID in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if info then
            -- TradeSkillRecipeInfo.learned is a bool
            -- (TradeSkillUIDocumentation.lua:952). The walk returns unlearned
            -- recipes too -- Blizzard's own list splits them into Learned and
            -- Unlearned groups at Blizzard_Professions.lua:840 -- so treating
            -- every returned ID as known would record the whole profession.
            if info.learned then
                model.SetRecipeKnown(charKey, recipeID, true)
                seen = seen + 1
            else
                model.SetRecipeKnown(charKey, recipeID, false)
            end
        end
    end

    model.SetRecipeScan(charKey, skillLineID, time())

    return seen
end

--- Harvests whatever skill line the profession window currently shows.
---
--- Only what the player is looking at. UPS cannot open the window itself --
--- C_TradeSkillUI.OpenTradeSkill is protected, and calling it from addon code
--- raises ADDON_ACTION_BLOCKED -- and it will not walk the player's expansion
--- tabs to collect data they did not ask for. A scan is therefore always
--- partial, which is why the prompt is gated on the character having no scans
--- at all rather than on this line.
local function harvestOpenWindow()
    local current = C_TradeSkillUI.GetChildProfessionInfo()
    if not current then return end

    recipes.HarvestSkillLine(current.professionID)
end

--- Records one newly learned recipe without re-scanning anything.
---
--- NEW_RECIPE_LEARNED carries (recipeID, recipeLevel, baseRecipeID)
--- (Blizzard_ProfessionsRecipeSchematicForm.lua:208). The base ID is preferred:
--- a multi-rank recipe fires with a per-rank recipeID, and the base is the ID a
--- recipe item names.
---@param recipeID number
---@param recipeLevel number|nil
---@param baseRecipeID number|nil
function recipes.OnNewRecipeLearned(recipeID, recipeLevel, baseRecipeID)
    local identifier = baseRecipeID or recipeID
    if not identifier then return end

    model.SetRecipeKnown(BitForge:GetCurrentCharacter(), identifier, true)
end

--- Tells the player to open each profession once, so there is something to harvest.
---
--- UPS cannot do this itself: C_TradeSkillUI.OpenTradeSkill is protected, and
--- calling it from addon code raises ADDON_ACTION_BLOCKED without opening
--- anything. The player is the only way in.
---
--- Gated on the character having no scans at all, not on a per-skill-line
--- stamp: harvesting records the child line the window was showing, while this
--- list carries whatever GetProfessions reports, and the two need not be the
--- same ID. Once any profession has been opened the prompt stops for good.
function recipes.PromptForScans()
    local charKey = BitForge:GetCurrentCharacter()
    if model.HasAnyRecipeScan(charKey) then return end

    for _, entry in ipairs(recipes.ReadProfessions()) do
        -- Once per profession per session. Repeating it every login would be
        -- nagging about something the player may have decided not to do.
        if not prompted[entry.skillLineID] then
            prompted[entry.skillLineID] = true
            BitForge:Print(format(locale["msg:openProfession"], entry.name))
        end
    end
end

-- ================================================================================
-- Deposit
-- ================================================================================

---@class BitForge.UPS.Control.Deposit
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

--- True while a plan is executing.
function deposit.IsRunning()
    return running
end

--- Snapshots both sources and returns the plan for them.
---
--- The warband tabs are read only when some private override exists. That read
--- walks every purchased tab and is the most expensive thing the module does,
--- and until a user curates a private item there is nothing in shared storage
--- the reclaim pass could ever claim.
---@return table plan
function deposit.BuildPlan()
    local warbandSnapshot
    if model.HasPrivateOverrides() then
        warbandSnapshot = inventory.Snapshot(inventory.GetWarbandTabs())
    end

    return model.PlanMoves(inventory.Snapshot(), warbandSnapshot, inventory.Holdings())
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
local function onBagUpdateDelayed()
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
    -- live writer from Phase 3 on. Re-resolving here makes "only what the user
    -- asked for moves" a rule enforced at the point of action, not a property
    -- that happens to hold because nothing writes overrides in this phase.
    -- ResolveMove is asked the same question the planner asked it, which is
    -- what descriptor.fromWarband is carried for.
    -- None of these are failures; skip the descriptor and carry on.
    if not info or info.itemID ~= descriptor.itemID
        or model.ResolveMove(info.itemID, descriptor.fromWarband) ~= descriptor.destination then
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
---@param plan table  from deposit.BuildPlan or model.PlanMoves
function deposit.Start(plan)
    if running then return end
    if not model.IsEnabled() then return end

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

EventRegistry:RegisterFrameEventAndCallback("BAG_UPDATE_DELAYED", function()
    onBagUpdateDelayed()
end)

--- The single entry point. Builds a plan, shows it for confirmation when the
--- preview is on, and otherwise runs it straight away.
function deposit.Run()
    if running then return end
    if not model.IsEnabled() then return end

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

control.inventory = inventory
control.recipes = recipes
control.deposit = deposit

-- ================================================================================
-- Events
-- ================================================================================

local function onBankOpened()
    view.bankButton.OnBankOpened()

    -- The built-in source's container list is gated on the bank being open
    -- (inventory.GetCurationContainers), so an open curation window is showing a
    -- different account the moment the bank frame appears or disappears.
    view.curationWindow.Reload()
end

local function onBankClosed()
    -- Abort here rather than letting the next BAG_UPDATE_DELAYED walk into
    -- CanMove and discover it: a move issued against a bank that just closed may
    -- never report back at all, and the run would hang with the item held.
    if running then
        if pendingMove then ClearCursor() end
        finish("msg:blockedBankClosed")
    end

    view.bankButton.OnBankClosed()
    view.previewDialog.Hide()

    -- The built-in source's container list is gated on the bank being open
    -- (inventory.GetCurationContainers), so an open curation window is showing a
    -- different account the moment the bank frame appears or disappears.
    view.curationWindow.Reload()
end

local function onPlayerReady()
    view.settingsPanel.Init()

    BitForge.RegisterMinimapButton({
        label    = locale["curation:open"],
        icon     = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
        onToggle = view.curationWindow.Toggle,
    })

    -- Free and passive: professions are available the moment the player is in
    -- the world. Recipes are not -- UPS cannot open a profession window itself,
    -- so PromptForScans asks the player to open theirs.
    recipes.RecordProfessions()
    recipes.PromptForScans()
end

EventRegistry:RegisterFrameEventAndCallback("TRADE_SKILL_LIST_UPDATE", function()
    harvestOpenWindow()
end)

EventRegistry:RegisterFrameEventAndCallback("NEW_RECIPE_LEARNED",
    function(_, recipeID, recipeLevel, baseRecipeID)
        recipes.OnNewRecipeLearned(recipeID, recipeLevel, baseRecipeID)
    end)

-- Losing or gaining a profession invalidates what was recorded for this
-- character, so the profession list is rebuilt. Learned recipes are left alone:
-- they are re-harvested on the next window open, and discarding them here would
-- make every recipe look wanted in the meantime.
EventRegistry:RegisterFrameEventAndCallback("SKILL_LINES_CHANGED", function()
    recipes.RecordProfessions()
end)

ns:Subscribe(events.BANK_OPENED, onBankOpened)
ns:Subscribe(events.BANK_CLOSED, onBankClosed)
ns:Subscribe(events.PLAYER_READY, onPlayerReady)

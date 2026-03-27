local ns = select(2, ...)
local E  = BitForge.Events

function ns:Subscribe(event, fn)
    BitForge.EventBus:RegisterCallback(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.EventBus:UnregisterCallback(event, self)
end

local ipairs = ipairs
local pairs  = pairs
local next   = next
local select = select

local wipe = table.wipe
local remove = table.remove
local max    = math.max
local floor  = math.floor
local format = string.format

local C_Container = C_Container
local C_Item      = C_Item

local model = ns.Model
local constants = ns.Constants

ns.Controller = {}
local controller = ns.Controller

ns:Subscribe(E.CORE_LOADED, function()
    BitForge:AllocateModuleDB("UPS", {
        global = {
            assignments  = {},
            nextCustomID = 1,
            itemCounts   = {},
            professions  = {},
        },
        char = {
            enabled       = true,
            guildBankPull = false,
            guildBankPush = false,
            initialized   = false,
        },
    }, model.Init)
end)

ns:Subscribe(E.PLAYER_READY, function()
    ns.Adapters.Detect()
    ns.ProfessionScanner.Scan()
    ns.Controller.CheckSetup()
end)

ns:Subscribe(E.SKILL_LINES_CHANGED, function()
    ns.ProfessionScanner.Scan()
end)

function controller.IsBankButtonEnabled()
    return model.IsEnabled() and next(model.GetAssignments()) ~= nil
end

function controller.ResetCharAssignments(charKey)
    for key in pairs(model.GetAssignments()) do
        model.UnassignChar(key, charKey)
    end
end

-- Returns categoryKey and entry if the item matches any assignment for charKey.
-- Priority: manual items table override → class/subclass fallback.
-- Returns nil, nil if no match.
local function ResolveCategory(itemID, classID, subClassID)
    local assignments = model.GetAssignments()

    -- Step 1: manual override
    for key, entry in pairs(assignments) do
        if entry.items and entry.items[itemID] then
            return key, entry
        end
    end

    -- Step 2: class/subclass
    local categoryKey = classID .. ":" .. subClassID
    local entry = assignments[categoryKey]
    if entry then
        if entry.expansions == nil then
            return categoryKey, entry
        end
        local expacID = C_Item.GetItemExpansionPackID(itemID)
        if entry.expansions[expacID] then
            return categoryKey, entry
        end
    end

    return nil, nil
end

-- Returns true if currentChar is assigned to this item's category.
local function IsAssignedToCurrentChar(itemID, classID, subClassID)
    local charKey = BitForge:GetCurrentCharacter()
    local _, entry = ResolveCategory(itemID, classID, subClassID)
    return entry ~= nil and entry.chars ~= nil and entry.chars[charKey] == true
end

-- =========================================================
-- Bag index constants
-- =========================================================
-- Defined here so every scan function below can reference them as upvalues.

local CHAR_BAGS = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
    Enum.BagIndex.ReagentBag,
}

local CHAR_BANK_TABS = {
    Enum.BagIndex.Characterbanktab,
    Enum.BagIndex.CharacterBankTab_1,
    Enum.BagIndex.CharacterBankTab_2,
    Enum.BagIndex.CharacterBankTab_3,
    Enum.BagIndex.CharacterBankTab_4,
    Enum.BagIndex.CharacterBankTab_5,
    Enum.BagIndex.CharacterBankTab_6,
}

-- Account bank (warband bank) numbered tabs — root tab aggregates the same
-- items as the numbered tabs and must not be double-counted.
local WARBAND_TABS = {
    Enum.BagIndex.AccountBankTab_1,
    Enum.BagIndex.AccountBankTab_2,
    Enum.BagIndex.AccountBankTab_3,
    Enum.BagIndex.AccountBankTab_4,
    Enum.BagIndex.AccountBankTab_5,
}

-- Scans bags + personal bank for the current character and updates itemCounts.
-- Called on each BANKFRAME_OPENED when no adapter is active.
function controller.ScanAndStoreItemCounts()
    if ns.Adapters.HasAdapter() then return end

    local charKey = BitForge:GetCurrentCharacter()
    model.WipeCharItemCounts(charKey)
    model.WipeItemClassCache()

    local bagLists = { CHAR_BAGS, CHAR_BANK_TABS, WARBAND_TABS }

    for _, bags in ipairs(bagLists) do
        for _, bag in ipairs(bags) do
            if bag then
                local numSlots = C_Container.GetContainerNumSlots(bag)
                for slot = 1, numSlots do
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.itemID then
                        model.IncrementItemCount(info.itemID, charKey, info.stackCount or 1)
                        if not model.GetCachedItemClass(info.itemID) then
                            local cID, sID = select(12, C_Item.GetItemInfoInstant(info.itemID))
                            if cID then
                                model.CacheItemClass(info.itemID, cID, sID)
                            end
                        end
                    end
                end
            end
        end
    end
end

local moveQueue   = {}
local moveCount   = 0
local isResolving = false

local function FinishResolve()
    isResolving = false
    if ns.BankButton then
        ns.BankButton.SetIdle()
    end
    if moveCount == 0 then
        BitForge:Print(ns.L["msg:nothingToDo"])
    else
        BitForge:Print(format(ns.L["msg:done"], moveCount))
    end
    moveCount = 0
end

local function ExecuteNextMove()
    if #moveQueue == 0 then
        FinishResolve()
        return
    end
    local move = remove(moveQueue, 1)
    local ok = move()
    if ok then
        moveCount = moveCount + 1
        if ns.BankButton then
            ns.BankButton.SetParceling(moveCount)
        end
        C_Timer.After(0, ExecuteNextMove)
    else
        -- Move failed (e.g., no destination slot). Abort remaining queue.
        wipe(moveQueue)
        FinishResolve()
    end
end

-- Enqueues a deferred item move. moveFn must return true on success.
local function EnqueueMove(moveFn)
    moveQueue[#moveQueue + 1] = moveFn
end

-- =========================================================
-- WoW item movement helpers
-- =========================================================
-- Account bank (warband bank) uses Enum.BagIndex.AccountBankTab_1..5.
-- Both personal bank and account bank are accessible while BANKFRAME is open.

local function FindFreeWarbandSlot()
    for _, tab in ipairs(WARBAND_TABS) do
        local numSlots = C_Container.GetContainerNumSlots(tab)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(tab, slot)
            if not info then
                return tab, slot
            end
        end
    end
    return nil, nil
end

local function MoveToWarbandBank(srcBag, srcSlot)
    return function()
        local dstBag, dstSlot = FindFreeWarbandSlot()
        if not dstBag then
            ClearCursor()
            return false
        end
        C_Container.PickupContainerItem(srcBag, srcSlot)
        C_Container.PickupContainerItem(dstBag, dstSlot)
        return true
    end
end

local function MoveFromWarbandBank(warbandBag, warbandSlot, destBag, destSlot)
    return function()
        C_Container.PickupContainerItem(warbandBag, warbandSlot)
        C_Container.PickupContainerItem(destBag, destSlot)
        return true
    end
end

local function FindFreeBagSlot()
    for _, bag in ipairs(CHAR_BAGS) do
        if bag then
            local numSlots = C_Container.GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if not info then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

-- =========================================================
-- Push
-- =========================================================

local function BuildPushQueue()
    local charKey = BitForge:GetCurrentCharacter()

    local function scanBags(bagList)
        for _, bag in ipairs(bagList) do
            if bag then
                local numSlots = C_Container.GetContainerNumSlots(bag)
                for slot = 1, numSlots do
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.itemID then
                        local cID, sID = select(6, C_Item.GetItemInfoInstant(info.itemID))
                        if cID then
                            if not IsAssignedToCurrentChar(info.itemID, cID, sID) then
                                local b, s = bag, slot
                                EnqueueMove(MoveToWarbandBank(b, s))
                            end
                        end
                    end
                end
            end
        end
    end

    scanBags(CHAR_BAGS)
    scanBags(CHAR_BANK_TABS)
    -- guild bank (if enabled)
    if model.GetGuildBankPush() then
        -- Placeholder: guild bank uses GetGuildBankItemInfo(tab, slot)
    end
end

-- =========================================================
-- Pull
-- =========================================================

local function GetCurrentCharCategoryCount(charKey, categoryKey, entry)
    -- Count items explicitly in the items table
    local total = model.GetExplicitItemCount(charKey, categoryKey)

    -- Count class/subclass matched items not already in items table
    if entry.classID and entry.subClassID then
        local matchKey = entry.classID .. ":" .. entry.subClassID
        local allCounts = model.GetRawItemCounts()
        for itemID, charCounts in pairs(allCounts) do
            if not (entry.items and entry.items[itemID]) then
                local cID, sID = model.GetCachedItemClass(itemID)
                if not cID then
                    cID, sID = select(12, C_Item.GetItemInfoInstant(itemID))
                    if cID then model.CacheItemClass(itemID, cID, sID) end
                end
                if cID and sID and (cID .. ":" .. sID) == matchKey then
                    total = total + (charCounts[charKey] or 0)
                end
            end
        end
    end
    return total
end

local function BuildPullQueue()
    local charKey     = BitForge:GetCurrentCharacter()
    local assignments = model.GetAssignments()

    -- Collect all characters assigned to each category for fair-share calc
    local function getAssigneeCount(categoryKey)
        local entry = assignments[categoryKey]
        if not entry or not entry.chars then return 1 end
        local count = 0
        for _ in pairs(entry.chars) do count = count + 1 end
        return max(count, 1)
    end

    -- Scan warband bank tabs
    for _, tab in ipairs(WARBAND_TABS) do
        local numSlots = C_Container.GetContainerNumSlots(tab)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(tab, slot)
            if info and info.itemID then
                local itemID = info.itemID
                local _, _, _, _, _, _, _, _, _, _, _, cID, sID =
                    C_Item.GetItemInfoInstant(itemID)
                if cID then
                    local categoryKey, entry = ResolveCategory(itemID, cID, sID)
                    if categoryKey and entry and entry.chars and entry.chars[charKey] then
                        local assigneeCount = getAssigneeCount(categoryKey)
                        local pullAmount

                        if assigneeCount == 1 then
                            pullAmount = info.stackCount or 1
                        else
                            local total     = GetCurrentCharCategoryCount(charKey, categoryKey, entry)
                            local wbTotal   = info.stackCount or 1
                            local fairShare = floor((total + wbTotal) / assigneeCount)
                            pullAmount      = max(0, fairShare - total)
                        end

                        if pullAmount > 0 then
                            local destBag, destSlot = FindFreeBagSlot()
                            if destBag then
                                local t, s = tab, slot
                                EnqueueMove(MoveFromWarbandBank(t, s, destBag, destSlot))
                            else
                                C_Container.SortBags()
                                BitForge:Print(ns.L["msg:noVacancy"])
                                wipe(moveQueue)
                                return
                            end
                        end
                    end
                end
            end
        end
    end
end

-- =========================================================
-- Entry point
-- =========================================================

function controller.Resolve()
    if isResolving then return end
    if not model.IsEnabled() then return end

    wipe(moveQueue)
    moveCount   = 0
    isResolving = true

    if ns.BankButton then
        ns.BankButton.SetParceling(0)
    end

    -- Refresh built-in item counts before resolve
    controller.ScanAndStoreItemCounts()

    BuildPushQueue()
    BuildPullQueue()

    ExecuteNextMove()
end

function controller.CheckUnclassified()
    if not model.IsInitialized() then return end

    local charKey = BitForge:GetCurrentCharacter()
    local found   = false

    local function scanBag(bag)
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local _, _, _, _, _, _, _, _, _, _, _, cID, sID =
                    C_Item.GetItemInfoInstant(info.itemID)
                if cID then
                    local categoryKey = cID .. ":" .. sID
                    if constants.CONSUMER_MAP[categoryKey] then
                        if not model.IsCharAssigned(categoryKey, charKey) then
                            found = true
                            return true -- short-circuit
                        end
                    end
                end
            end
        end
        return false
    end

    if not found then
        for _, bag in ipairs(CHAR_BAGS) do
            if bag and scanBag(bag) then
                found = true; break
            end
        end
    end
    if not found then
        for _, bag in ipairs(CHAR_BANK_TABS) do
            if bag and scanBag(bag) then
                found = true; break
            end
        end
    end

    if ns.BankButton then
        ns.BankButton.ShowUnclassifiedBadge(found)
    end
end

function controller.CheckSetup()
    if not model.IsInitialized() then
        ns.SetupDialog.Open(false)
    end
end

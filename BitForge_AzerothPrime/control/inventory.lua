---@class BitForge.AzerothPrime
local ns = select(2, ...)

local ipairs = ipairs

local BankFrame = BankFrame
local C_Bank = C_Bank
local C_Container = C_Container

local enum = ns.enum
local model = ns.model

---@class BitForge.AzerothPrime.Control
local control = ns.control

---@class BitForge.AzerothPrime.Control.Inventory
local inventory = {}

--- The warband bank tabs this account has actually purchased.
---
--- Enumerated rather than hardcoded: a fixed AccountBankTab_1..5 list walks tabs
--- the player may not own and stops being correct the day Blizzard adds one.
---@return table  array of Enum.BagIndex, empty when none are purchased
function inventory.GetWarbandTabs()
    return C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Account) or {}
end

--- The character bank tabs this character has actually purchased. Enumerated
--- for the reason GetWarbandTabs above gives.
---@return table  array of Enum.BagIndex, empty when none are purchased
function inventory.GetCharacterBankTabs()
    return C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character) or {}
end

--- Snapshot of every occupied slot across a list of containers.
---
--- The deposit planner's sole input. With no argument it reads
--- model.facts.Walk's own shared pass over the carried bags rather than the
--- container again, so a snapshot taken alongside the open or sell path in the
--- same generation costs nothing beyond the walk they already paid for.
---
--- Deliberately not built through model.facts.Get: GetContainerItemInfo's
--- own itemID and stackCount are already the cheapest possible read of what
--- a record's eager fields would carry, so resolving a full record here
--- would only add a table and a metatable per occupied slot for no cheaper
--- an answer. bankRules.PlanMoves, Holdings below and the built-in adapter
--- all key their entries by this bag/slot/itemID/count shape -- both in the
--- client and in the plain tables their own tests hand-build -- so this
--- stays the narrow four-field shape rather than becoming a list of records.
---@param containers table|nil  defaults to the carried bags
---@return table  { { bag, slot, itemID, count }, ... }
function inventory.Snapshot(containers)
    local snapshot = {}

    if not containers then
        for _, entry in ipairs(model.facts.Walk()) do
            snapshot[#snapshot + 1] = {
                bag    = entry.bagIndex,
                slot   = entry.slotIndex,
                itemID = entry.itemID,
                count  = entry.slotInfo.stackCount or 1,
            }
        end
        return snapshot
    end

    -- Two callers pass an explicit list: the curation window
    -- (GetCurationContainers) and deposit.BuildPlan (GetWarbandTabs). Bank
    -- tabs are not carried bags and Walk never reads them, so there is no
    -- shared pass to reuse for either list. Only the curation list can overlap
    -- the carried bags -- with the bank closed it degenerates to exactly
    -- enum.BAG_INDICES -- and it still reads them directly: an on-demand
    -- window is low-traffic next to the open/sell/bank triggers that share one
    -- walk, so the duplicate read is not worth the special case.
    for _, bag in ipairs(containers) do
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

control.inventory = inventory

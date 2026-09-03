---@type string, BitForge.AutoBalance
local ADDON_NAME, ns = ...

local format = string.format

local C_Bank = C_Bank
local C_Timer = C_Timer
local GetMoney = GetMoney
local GetMoneyString = GetMoneyString

local enum = ns.enum
local model = ns.model
local events = BitForge.Events

---@class BitForge.AutoBalance.Control
local control = ns.control

function ns:Subscribe(event, callback)
    BitForge.Subscribe(event, callback, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

local ACCOUNT_BANK = Enum.BankType.Account

local playerName

-- The only code in the module that touches C_Bank. Nothing is printed at
-- dispatch: the message waits for PLAYER_MONEY to confirm the server moved the
-- money, so a rejected transfer stays silent rather than reporting a success
-- that never happened.
local transfer = {}

local MESSAGE_KEY = {
    [enum.ACTION.DEPOSIT]  = "msg:deposit",
    [enum.ACTION.WITHDRAW] = "msg:withdraw",
    [enum.ACTION.COLLECT]  = "msg:collect",
}

-- { action = <enum.ACTION>, before = <copper carried before the request> }
local pending

--- Dispatches a transfer and arms confirmation. Does nothing if the bank
--- refuses the direction of travel.
---@param action string  enum.ACTION.DEPOSIT, WITHDRAW, or COLLECT
---@param amount number  Copper to move
function transfer.Dispatch(action, amount)
    if amount <= 0 then return end

    -- Captured before the call: the deduction is a server round trip, so
    -- GetMoney() still reports the old value here, but reading it first removes
    -- any dependence on that timing.
    local before = GetMoney()

    if action == enum.ACTION.DEPOSIT then
        if not C_Bank.CanDepositMoney(ACCOUNT_BANK) then return end
        C_Bank.DepositMoney(ACCOUNT_BANK, amount)
    elseif action == enum.ACTION.WITHDRAW or action == enum.ACTION.COLLECT then
        if not C_Bank.CanWithdrawMoney(ACCOUNT_BANK) then return end
        C_Bank.WithdrawMoney(ACCOUNT_BANK, amount)
    else
        -- Only DEPOSIT, WITHDRAW, and COLLECT are legal here; balancer.Run
        -- already filters NONE and NO_FUNDS. Bail explicitly rather than
        -- relying on that invariant holding at this call site too.
        return
    end

    pending = { action = action, before = before }

    local armedRecord = pending
    C_Timer.After(enum.CONFIRM_TIMEOUT, function()
        -- Retire the record only if this same dispatch is still outstanding.
        if pending == armedRecord then
            pending = nil
        end
    end)
end

--- Reports what actually moved. Driven by PLAYER_MONEY.
function transfer.Confirm()
    if not pending then return end

    local moved
    if pending.action == enum.ACTION.DEPOSIT then
        moved = pending.before - GetMoney()
    else
        moved = GetMoney() - pending.before
    end

    -- A change in the wrong direction is not this transfer. Keep waiting; the
    -- timeout retires the record if the server never acts.
    if moved <= 0 then return end

    local action = pending.action
    pending = nil
    BitForge:Print(format(ns.locale[MESSAGE_KEY[action]], GetMoneyString(moved, true)))
end

--- True while a dispatched transfer is still awaiting confirmation.
function transfer.IsPending()
    return pending ~= nil
end

control.transfer = transfer

local balancer = {}

local function canTransferMoney()
    return C_Bank.CanUseBank(ACCOUNT_BANK)
        and C_Bank.DoesBankTypeSupportMoneyTransfer(ACCOUNT_BANK)
end

--- Runs one balance pass. Safe to call when the bank is not usable.
function balancer.Run()
    if not canTransferMoney() then return end

    -- A dispatched transfer is still awaiting confirmation. Re-running now would
    -- recompute the same action from money the server has not yet adjusted and
    -- dispatch it a second time.
    if transfer.IsPending() then return end

    local collector = model.GetCollectorName()
    local isCollector = collector ~= "" and collector == playerName

    local action, amount = model.Plan(
        GetMoney(),
        C_Bank.FetchDepositedMoney(ACCOUNT_BANK),
        model.GetDesiredBalance() * COPPER_PER_GOLD,
        model.GetMarginalRatio(),
        isCollector)

    if action == enum.ACTION.NONE then return end

    -- No server round trip happens for this one, so it prints directly rather
    -- than going through the confirmation path.
    if action == enum.ACTION.NO_FUNDS then
        BitForge:Print(ns.locale["msg:noFunds"])
        return
    end

    transfer.Dispatch(action, amount)
end

control.balancer = balancer

local armed = false
local attempts = 0

-- Bumped every time a poll chain is (re)armed. A boolean alone cannot tell a
-- stale chain from the current one: re-arming after a rapid hide/show would
-- flip `armed` back to true and let an in-flight timer from the previous
-- chain keep running, so it drives the new cycle's `attempts` counter too.
-- Capturing the generation at arm time and checking it on each fire lets a
-- stale chain retire itself instead.
local generation = 0

local function bankReady()
    return C_Bank.CanDepositMoney(ACCOUNT_BANK) or C_Bank.CanWithdrawMoney(ACCOUNT_BANK)
end

local function pollReady(chainGeneration)
    if not armed or chainGeneration ~= generation then return end

    if bankReady() then
        armed = false
        balancer.Run()
        return
    end

    attempts = attempts + 1
    if attempts >= enum.READY_MAX_ATTEMPTS then
        armed = false
        return
    end

    C_Timer.After(enum.READY_RETRY_DELAY, function()
        pollReady(chainGeneration)
    end)
end

-- BankFrame registers three interaction types against the same frame
-- (Blizzard_UIPanels_Game/Mainline/BankFrame.lua). Which one the server
-- sends for a given banker is not knowable from client source, so wake on all
-- three and let the capability check in balancer.Run decide whether the Warband
-- Bank is actually usable.
local BANK_INTERACTIONS = {
    [Enum.PlayerInteractionType.Banker]          = true,
    [Enum.PlayerInteractionType.CharacterBanker] = true,
    [Enum.PlayerInteractionType.AccountBanker]   = true,
}

local function onInteractionShow(interactionType)
    if not BANK_INTERACTIONS[interactionType] then return end
    if armed then return end
    armed = true
    attempts = 0
    generation = generation + 1
    pollReady(generation)
end

local function onInteractionHide(interactionType)
    if not BANK_INTERACTIONS[interactionType] then return end
    armed = false
end

local function onPlayerMoney()
    transfer.Confirm()
end

local function startModule()
    playerName = BitForge:GetCurrentCharacter()
    ns.view.Init()
end

local function onPlayerReady()
    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        steps   = {
            -- Data written before this module was versioned already matches the
            -- version-1 shape, so adopting the version is the whole migration.
            [1] = function() end,
        },
    }, startModule)
end

ns:Subscribe(events.PLAYER_INTERACTION_MANAGER_FRAME_SHOW, onInteractionShow)
ns:Subscribe(events.PLAYER_INTERACTION_MANAGER_FRAME_HIDE, onInteractionHide)
ns:Subscribe(events.PLAYER_MONEY, onPlayerMoney)
ns:Subscribe(events.PLAYER_READY, onPlayerReady)

local ns = select(2, ...)
local E  = BitForge.Events

function ns:Subscribe(event, fn)
    BitForge.EventBus:RegisterCallback(event, fn, self)
end

function ns:Unsubscribe(event)
    BitForge.EventBus:UnregisterCallback(event, self)
end

local format = string.format
local abs    = math.abs
local min    = math.min

local C_Bank         = C_Bank
local GetMoney       = GetMoney
local GetMoneyString = GetMoneyString

local model = ns.Model

local ACCOUNT_BANK   = Enum.BankType.Account
local ACCOUNT_BANKER = Enum.PlayerInteractionType.AccountBanker

local playerName
local pendingBalance  = false
local interactionHandle

local function Deposit(amount)
    if not C_Bank.CanDepositMoney(ACCOUNT_BANK) then return end
    C_Bank.DepositMoney(ACCOUNT_BANK, amount)
    BitForge:Print(format(ns.L["msg:deposit"], GetMoneyString(amount, true)))
end

local function Withdraw(amount)
    if not C_Bank.CanWithdrawMoney(ACCOUNT_BANK) then return end
    C_Bank.WithdrawMoney(ACCOUNT_BANK, amount)
    BitForge:Print(format(ns.L["msg:withdraw"], GetMoneyString(amount, true)))
end

local function DoBalance()
    local collector = model.GetCollectorName()
    if collector ~= "" and collector == playerName then
        local available = C_Bank.FetchDepositedMoney(ACCOUNT_BANK)
        if available > 0 then
            Withdraw(available)
        end
    else
        local currentCopper = GetMoney()
        local desiredCopper = model.GetDesiredBalance() * ns.COPPER_PER_GOLD
        local diff          = currentCopper - desiredCopper
        local threshold     = desiredCopper * model.GetMarginalRatio()
        if abs(diff) > threshold then
            if diff > 0 then
                Deposit(diff)
            else
                local available = C_Bank.FetchDepositedMoney(ACCOUNT_BANK)
                if available <= 0 then
                    BitForge:Print(ns.L["msg:noFunds"])
                    return
                end
                Withdraw(min(-diff, available))
            end
        end
    end
end

local function OnInteraction(_, interactionType)
    if interactionType == ACCOUNT_BANKER and not pendingBalance then
        pendingBalance = true
        C_Timer.After(0.1, function()
            pendingBalance = false
            DoBalance()
        end)
    end
end

ns:Subscribe(E.CORE_LOADED, function()
    BitForge:AllocateModuleDB("AutoBalance", ns.DB_DEFAULTS, model.Init)
end)

ns:Subscribe(E.PLAYER_READY, function()
    playerName = BitForge:GetCurrentCharacter()
    interactionHandle = EventRegistry:RegisterFrameEventAndCallback("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnInteraction)
end)

ns:Subscribe(E.PLAYER_LEAVING, function()
    if interactionHandle then
        interactionHandle:Unregister()
        interactionHandle = nil
    end
end)

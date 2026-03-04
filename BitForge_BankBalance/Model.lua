--- @type string, ns.BankBalance
local ADDON_NAME, ns = ...
--- @class BitForge.Models.BankBalance: BitForge.Models.Base
local model = ns.model

--- =========================================================
--- Default
--- =========================================================

local defaults = {
    char = {
        useGlobal = true,
        balance = 1000,
        useMargin = true,
        marginRatio = 0.05,
    },
    global = {
        balance = 1000,
        useMargin = true,
        marginRatio = 0.05,
    },
}

--- =========================================================
--- Data Management
--- =========================================================

local function getData()
    return model.db.char.useGlobal and model.db.global or model.db.char
end

--- @return number target desired balance
--- @return number lowerBound lower bound of the desired balance considering margin
--- @return number upperBound upper bound of the desired balance considering margin
function model:GetTargetGold()
    local enum = getData()
    local margin = enum.useMargin and (enum.balance * (enum.marginRatio or 0)) or 0
    local t = enum.balance

    return t - margin, t, t + margin
end

function model:SetUseGlobal(useGlobal)
    useGlobal = (useGlobal == nil) and true or useGlobal
    self.db.char.useGlobal = useGlobal
end

function model:GetUseGlobal()
    return self.db.char.useGlobal
end

function model:SetDesiredBalance(balance)
    getData().balance = balance
end

function model:GetDesiredBalance()
    return getData().balance
end

function model:SetUseMargin(useMargin)
    local data = getData()
    data.useMargin = useMargin
end

function model:GetUseMargin()
    local enum = getData()
    return enum.useMargin
end

function model:SetMarginRatio(marginRatio)
    local data = getData()
    data.marginRatio = marginRatio or defaults.char.marginRatio
end

function model:GetMarginRatio()
    local enum = getData()
    return enum.marginRatio
end

--- =========================================================
--- Overridable Methods
--- =========================================================

function model:OnInit()
    self.db = BitForgeAPI.RegisterDatabase(ADDON_NAME, defaults)
end

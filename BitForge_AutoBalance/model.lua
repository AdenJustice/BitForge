---@type string, BitForge.AutoBalance
local ADDON_NAME, ns = ...

local abs = math.abs
local min = math.min

local DB_DEFAULTS = {
    global = {
        collectorName = "",
        marginalRatio = 0.1,
        desiredBalance = 10000,
    },
    char = {
        useCharSettings = false,
        desiredBalance = 10000,
        marginalRatio = 0.1,
    },
}
local db

BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB)
    db = moduleDB
end)

---@class BitForge.AutoBalance.Model
local model = ns.model
local enum = ns.enum

function model.GetUseCharSettings()
    return db.char.useCharSettings
end

function model.SetUseCharSettings(value)
    db.char.useCharSettings = value
end

function model.GetDesiredBalance()
    return db.char.useCharSettings and db.char.desiredBalance or db.global.desiredBalance
end

function model.SetDesiredBalance(value)
    if db.char.useCharSettings then
        db.char.desiredBalance = value
    else
        db.global.desiredBalance = value
    end
end

function model.GetMarginalRatio()
    return db.char.useCharSettings and db.char.marginalRatio or db.global.marginalRatio
end

function model.SetMarginalRatio(value)
    if db.char.useCharSettings then
        db.char.marginalRatio = value
    else
        db.global.marginalRatio = value
    end
end

function model.GetCollectorName()
    return db.global.collectorName
end

function model.SetCollectorName(value)
    db.global.collectorName = value
end

--- Decides what to do with the current gold situation.
--- Pure: no API calls, no frame access, so it runs under the headless harness.
--- All amounts are in copper.
---@param carried       number  Gold currently carried by the player
---@param banked        number  Gold currently in the Warband Bank
---@param desiredCopper number  Target carried balance
---@param ratio         number  Deadband as a fraction of the target; 0 means always act
---@param isCollector   boolean Whether this character is the designated collector
---@return string action  A value from ns.enum.ACTION
---@return number amount  Copper to move; 0 for NONE and NO_FUNDS
function model.Plan(carried, banked, desiredCopper, ratio, isCollector)
    local ACTION = enum.ACTION

    -- The collector drains the bank outright and never consults the target.
    -- An empty bank is silent here: nothing was requested, so nothing failed.
    if isCollector then
        if banked > 0 then
            return ACTION.COLLECT, banked
        end
        return ACTION.NONE, 0
    end

    local diff = carried - desiredCopper
    local threshold = desiredCopper * ratio
    if abs(diff) <= threshold then
        return ACTION.NONE, 0
    end

    if diff > 0 then
        return ACTION.DEPOSIT, diff
    end

    if banked <= 0 then
        return ACTION.NO_FUNDS, 0
    end

    return ACTION.WITHDRAW, min(-diff, banked)
end

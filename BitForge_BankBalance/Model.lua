--- @type string, ns_BB
local ADDON_NAME, ns = ...
--- @class BB_Model: BF_BaseModel
local model = ns.model

--- =========================================================
--- Caches
--- =========================================================

local _error = error

--- =========================================================
--- Default
--- =========================================================

local defaults = {
    char = {
        useGlobal = true,
        threshold = 10000000,
        useMargin = false,
        marginRatio = 0.05,
    },
    global = {
        threshold = 10000000,
        useMargin = false,
        marginRatio = 0.05,
    },
}

--- =========================================================
--- Helpers
--- =========================================================

local function assertInitialized(self)
    if not self.initialized then
        _error("Database not initialized.", 3)
    end
end

--- =========================================================
--- Data Management
--- =========================================================

local function getData()
    assertInitialized(model)

    return model.db.char.useGlobal and model.db.global or model.db.char
end

--- @return number target target gold threshold
--- @return number lowerBound lower bound of the target threshold considering margin
--- @return number upperBound upper bound of the target threshold considering margin
function model:GetTargetGold()
    assertInitialized(self)

    local enum = getData()
    local margin = enum.useMargin and (enum.threshold * (enum.marginRatio or 0)) or 0
    local t = enum.threshold

    return t - margin, t, t + margin
end

function model:SetUseGlobal(useGlobal)
    assertInitialized(self)

    useGlobal = useGlobal ~= nil and useGlobal or true
    self.db.char.useGlobal = useGlobal
end

function model:GetUseGlobal()
    assertInitialized(self)

    return self.db.char.useGlobal
end

function model:SetThreshold(threshold)
    assertInitialized(self)

    getData().threshold = threshold
end

function model:GetThreshold()
    assertInitialized(self)

    return getData().threshold
end

function model:SetUseMargin(useMargin)
    assertInitialized(self)

    local data = getData()
    data.useMargin = useMargin
end

function model:GetUseMargin()
    assertInitialized(self)

    local enum = getData()
    return enum.useMargin
end

function model:SetMarginRatio(marginRatio)
    assertInitialized(self)

    local data = getData()
    data.marginRatio = marginRatio or defaults.char.marginRatio
end

function model:GetMarginRatio()
    assertInitialized(self)

    local enum = getData()
    return enum.marginRatio
end

--- =========================================================
--- Overridable Methods
--- =========================================================

function model:OnInit()
    self.db = BitForgeAPI.RegisterDatabase(ADDON_NAME, defaults)
end

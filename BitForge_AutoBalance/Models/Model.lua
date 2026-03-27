local _, ns = ...

ns.Model = {}
local Model = ns.Model
local db

function Model.Init(_db)
    db = _db
end

function Model.GetDesiredBalance() return db.global.desiredBalance end

function Model.SetDesiredBalance(v) db.global.desiredBalance = v end

function Model.GetMarginalRatio() return db.global.marginalRatio end

function Model.SetMarginalRatio(v) db.global.marginalRatio = v end

function Model.GetCollectorName() return db.global.collectorName end

function Model.SetCollectorName(v) db.global.collectorName = v end


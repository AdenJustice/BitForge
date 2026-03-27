local ns = select(2, ...)

ns.Model = {}
local model = ns.Model
local db

function model.Init(_db)
    db = _db
end

function model.GetPosition(unit)
    return db.char.positions[unit]
end

function model.SavePosition(unit, point, relativeName, relPoint, x, y)
    db.char.positions[unit] = { point, relativeName, relPoint, x, y }
end

function model.GetUnitFramesEnabled() return db.char.unitframes end

function model.SetUnitFramesEnabled(v) db.char.unitframes = v end

function model.GetClassPanelEnabled() return db.char.classpanel end

function model.SetClassPanelEnabled(v) db.char.classpanel = v end

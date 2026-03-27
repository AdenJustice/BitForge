local _, ns = ...

ns.Model = {}
local Model = ns.Model
local db

function Model.Init(_db)
    db = _db
end

-- Returns the layout config table for one bar key (e.g. "MainBar").
-- Contains: count, rows, point, x, y.
function Model.GetBarConfig(key)
    return db.char[key]
end

-- Returns the full layout config table (all bar keys).
function Model.GetAllBarConfigs()
    return db.char
end

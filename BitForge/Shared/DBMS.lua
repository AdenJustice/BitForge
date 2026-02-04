--- @type ns_core
local ns            = select(2, ...)
local params        = ns.params
--- @class BF_DBMS
local dbms          = ns.dbms

--- =========================================================
--- Caches
--- =========================================================

local _type         = type
local _setmetatable = setmetatable
local _pairs        = pairs
local _next         = next

--- =========================================================
--- Internals
--- =========================================================

local sv                 -- reference to _G[varName]
local charGUID           -- current character's GUID
local storedDefs         -- original defaults for ResetSection
local nsStoredDefs  = {} -- defaults per registered namespace

--- Applies `defs` as fallback defaults on `tbl` via __index metatable.
--- Missing keys fall back to defs[key], or defs['*'] if no exact match.
--- When the fallback is a table, a new sub-table is lazily created in `tbl`
--- and recursively gets applyDefaults applied to it.
--- @param tbl table The table to apply defaults to
--- @param defs table? The defaults table
--- @return table tbl
local function applyDefaults(tbl, defs)
    if not defs then return tbl end

    _setmetatable(tbl, {
        __index = function(t, k)
            local v = defs[k]
            if v == nil then v = defs['*'] end
            if v == nil then return nil end

            if _type(v) == "table" then
                local sub = {}
                t[k] = sub
                applyDefaults(sub, v)
                return sub
            end

            return v
        end,
    })

    return tbl
end

--- Removes keys from `tbl` whose value matches the default, then prunes empty sub-tables.
--- Scalar equality is used; does not deep-equal two default tables with identical contents.
--- @param tbl table
--- @param defs table?
local function removeDefaults(tbl, defs)
    if not defs then return end

    for k, v in _pairs(tbl) do
        local d = defs[k]
        if d == nil then d = defs['*'] end

        if _type(v) == "table" and _type(d) == "table" then
            removeDefaults(v, d)
            if _next(v) == nil then
                tbl[k] = nil
            end
        elseif v == d then
            tbl[k] = nil
        end
    end
end

--- Ensures `container[key]` exists as a table and applies defaults to it.
--- @param container table The parent table
--- @param key any The key within `container`
--- @param sectionDefaults table? The defaults for this section
--- @return table section
local function initSection(container, key, sectionDefaults)
    if not container[key] then
        container[key] = {}
    end

    applyDefaults(container[key], sectionDefaults)

    return container[key]
end

--- =========================================================
--- DBMS
--- =========================================================

--- Initializes the database. Must be called once before accessing dbms.global or dbms.char.
--- Sets dbms.global and dbms.char directly on this object.
--- @param varName string The SavedVariables global name (e.g. "BitForgeDB")
--- @param defs table Defaults table with optional `global` and `char` sub-tables
function dbms:Init(varName, defs)
    if not _G[varName] then _G[varName] = {} end

    sv         = _G[varName]
    charGUID   = params.character.guid
    storedDefs = defs

    if not sv.char then sv.char = {} end
    if not sv.namespaces then sv.namespaces = {} end

    self.global = initSection(sv, "global", defs and defs.global)
    self.char   = initSection(sv.char, charGUID, defs and defs.char)
end

--- Returns a scoped namespace with its own `global` and `char` sections, backed by `nsDefs`.
--- @param name string Namespace name (must be unique)
--- @param nsDefs table Defaults table with optional `global` and `char` sub-tables
--- @return table db A plain table with `.global` and `.char` fields
function dbms:RegisterNamespace(name, nsDefs)
    if not sv.namespaces[name] then sv.namespaces[name] = {} end

    nsStoredDefs[name] = nsDefs

    local nsSV = sv.namespaces[name]
    if not nsSV.char then nsSV.char = {} end

    return {
        global = initSection(nsSV, "global", nsDefs and nsDefs.global),
        char   = initSection(nsSV.char, charGUID, nsDefs and nsDefs.char),
    }
end

--- Removes all values identical to their defaults from the saved variables,
--- keeping BitForgeDB clean. Call this on PLAYER_LOGOUT.
function dbms:CleanUp()
    removeDefaults(sv.global, storedDefs and storedDefs.global)
    removeDefaults(sv.char[charGUID], storedDefs and storedDefs.char)

    for name, nsSV in _pairs(sv.namespaces) do
        local nd = nsStoredDefs[name]
        removeDefaults(nsSV.global, nd and nd.global)
        if nsSV.char then
            removeDefaults(nsSV.char[charGUID], nd and nd.char)
        end
    end
end

--- Resets a scope for the current character and re-applies defaults.
--- @param scope string "global" or "char"
function dbms:ResetSection(scope)
    if scope == "global" then
        sv.global = {}
        self.global = initSection(sv, "global", storedDefs and storedDefs.global)
    elseif scope == "char" then
        sv.char[charGUID] = {}
        self.char = initSection(sv.char, charGUID, storedDefs and storedDefs.char)
    end
end

--- =========================================================
--- Plugin Factory
--- =========================================================

--- @class BitForgeAPI
local api = BitForgeAPI

--- Registers a new plugin namespace with its own database sections.
--- @param name string Namespace name (must be unique)
--- @param nsDefs table Defaults table with optional `global` and `char` sub-tables
--- @return table db A plain table with `.global` and `.char` fields for
function api.RegisterDatabase(name, nsDefs)
    return dbms:RegisterNamespace(name, nsDefs)
end

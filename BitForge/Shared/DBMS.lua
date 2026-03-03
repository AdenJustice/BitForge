--- @class ns.Core
local ns            = select(2, ...)
local params        = ns.params

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

local instance -- the single DBMS instance, captured at construction

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
--- DBMS Class
--- =========================================================

--- @class BitForge.DBMS
--- @field _sv table The raw SavedVariables table
--- @field _charGUID string The current character's GUID
--- @field _defs table? The defaults table passed at construction
--- @field _nsDefs table A map of namespace name to defaults table
--- @field charMap table The `char` section of the SavedVariables, keyed by GUID
--- @field namespaces table The `namespaces` section of the SavedVariables
local DBMS = {}
DBMS.__index = DBMS

--- Creates and initializes a new DBMS instance.
--- @param varName string The SavedVariables global name (e.g. "BitForgeDB")
--- @param defs table Defaults table with optional `global` and `char` sub-tables
--- @return BitForge.DBMS
function DBMS.new(varName, defs)
    if not _G[varName] then _G[varName] = {} end

    local self     = setmetatable({}, DBMS)

    local sv       = _G[varName]
    local charGUID = params.character.guid

    if not sv.char then sv.char = {} end
    if not sv.namespaces then sv.namespaces = {} end

    self._sv        = sv
    self._charGUID  = charGUID
    self._defs      = defs
    self._nsDefs    = {}

    self.global     = initSection(sv, "global", defs and defs.global)
    self.char       = initSection(sv.char, charGUID, defs and defs.char)
    self.charMap    = sv.char
    self.namespaces = sv.namespaces

    instance        = self
    return self
end

--- Returns a scoped namespace with its own `global` and `char` sections, backed by `nsDefs`.
--- @param name string Namespace name (must be unique)
--- @param nsDefs table Defaults table with optional `global` and `char` sub-tables
--- @return table db A plain table with `.global` and `.char` fields
function DBMS:RegisterNamespace(name, nsDefs)
    local sv       = self._sv
    local charGUID = self._charGUID

    if not sv.namespaces[name] then sv.namespaces[name] = {} end

    self._nsDefs[name] = nsDefs

    local nsSV = sv.namespaces[name]
    if not nsSV.char then nsSV.char = {} end

    return {
        global = initSection(nsSV, "global", nsDefs and nsDefs.global),
        char   = initSection(nsSV.char, charGUID, nsDefs and nsDefs.char),
    }
end

--- Removes all values identical to their defaults from the saved variables,
--- keeping the DB clean. Call this on PLAYER_LOGOUT.
function DBMS:CleanUp()
    local sv       = self._sv
    local charGUID = self._charGUID
    local defs     = self._defs
    local nsDefs   = self._nsDefs

    removeDefaults(sv.global, defs and defs.global)
    removeDefaults(sv.char[charGUID], defs and defs.char)

    for name, nsSV in _pairs(sv.namespaces) do
        local nd = nsDefs[name]
        removeDefaults(nsSV.global, nd and nd.global)
        if nsSV.char then
            removeDefaults(nsSV.char[charGUID], nd and nd.char)
        end
    end
end

--- Resets a scope for the current character and re-applies defaults.
--- @param scope string "global" or "char"
function DBMS:ResetSection(scope)
    local sv       = self._sv
    local charGUID = self._charGUID
    local defs     = self._defs

    if scope == "global" then
        sv.global = {}
        self.global = initSection(sv, "global", defs and defs.global)
    elseif scope == "char" then
        sv.char[charGUID] = {}
        self.char = initSection(sv.char, charGUID, defs and defs.char)
    end
end

ns.DBMS = DBMS

--- =========================================================
--- Plugin Factory
--- =========================================================

--- @class BitForgeAPI
local api = BitForgeAPI

--- Registers a new plugin namespace with its own database sections.
--- @param name string Namespace name (must be unique)
--- @param nsDefs table Defaults table with optional `global` and `char` sub-tables
--- @return table db A plain table with `.global` and `.char` fields
function api.RegisterDatabase(name, nsDefs)
    return instance:RegisterNamespace(name, nsDefs)
end

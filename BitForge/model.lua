---@type BitForge.Core
local ns = select(2, ...)

local ipairs = ipairs
local next = next
local pairs = pairs
local setmetatable = setmetatable
local type = type

---@class BitForge.Core.Model
local model = ns.model

local db
local pendingAllocations = {}
local moduleRegistry = {}
local moduleDefaultsRegistry = {}

local function SeedDefaults(tbl, src)
    if not src then return end
    for k, v in pairs(src) do
        if tbl[k] == nil then
            tbl[k] = type(v) == "table" and CopyTable(v) or v
        elseif type(v) == "table" and type(tbl[k]) == "table" then
            -- Seeding has to reach as deep as PruneMatchingDefaults does. The
            -- prune walks nested tables and drops individual keys that match
            -- their default, so a partially-modified record -- a dragged frame
            -- whose anchor names still read "CENTER" while its offsets moved --
            -- is saved with those keys missing. Filling only absent top-level
            -- keys left the hole permanent, and the module then read nil out of
            -- a record it had every reason to believe was complete.
            --
            -- Safe against resurrecting deleted collection entries because a
            -- default only contributes keys it actually declares, and every
            -- collection default in the suite is an empty table.
            SeedDefaults(tbl[k], v)
        end
    end
end

local function Allocate(name, moduleDefaults, callback)
    local modules = db.modules
    modules[name] = modules[name] or {}
    local module = modules[name]
    module.global = module.global or {}
    module.char = module.char or {}
    local charKey = BitForge:GetCurrentCharacter()
    module.char[charKey] = module.char[charKey] or {}

    SeedDefaults(module.global, moduleDefaults and moduleDefaults.global)
    SeedDefaults(module.char[charKey], moduleDefaults and moduleDefaults.char)

    moduleDefaultsRegistry[name] = moduleDefaults

    local realGlobal = module.global
    local realChar = module.char[charKey]
    local globalDef = moduleDefaults and moduleDefaults.global
    local charDef = moduleDefaults and moduleDefaults.char

    local globalProxy = setmetatable({}, {
        __index    = function(_, k)
            local v = realGlobal[k]; if v ~= nil then return v end; return globalDef and globalDef[k]
        end,
        __newindex = function(_, k, v) realGlobal[k] = v end,
    })

    local charProxy = setmetatable({}, {
        __index    = function(_, k)
            local v = realChar[k]; if v ~= nil then return v end; return charDef and charDef[k]
        end,
        __newindex = function(_, k, v) realChar[k] = v end,
    })

    callback({ global = globalProxy, char = charProxy })
end

function model.InitializeDatabase()
    BitForgeDB = BitForgeDB or {}
    BitForgeDB.global = BitForgeDB.global or {}
    BitForgeDB.modules = BitForgeDB.modules or {}
    SeedDefaults(BitForgeDB.global, ns.enum.DB_DEFAULTS.global)
    db = BitForgeDB

    for _, req in ipairs(pendingAllocations) do
        Allocate(req.name, req.defaults, req.callback)
    end
    pendingAllocations = {}
end

--- Reads a value from the Core global settings.
---@param key string
---@return any
function model.ReadDatabase(key)
    return db and db.global[key]
end

--- Writes a value to the Core global settings.
---@param key string
---@param value any
function model.UpdateDatabase(key, value)
    if db then
        db.global[key] = value
    end
end

local function PruneMatchingDefaults(realTbl, src)
    if not src then return end
    for k, defaultVal in pairs(src) do
        local savedVal = realTbl[k]
        if savedVal ~= nil then
            if type(defaultVal) == "table" and type(savedVal) == "table" then
                PruneMatchingDefaults(savedVal, defaultVal)
                if not next(savedVal) then
                    realTbl[k] = nil
                end
            elseif savedVal == defaultVal then
                realTbl[k] = nil
            end
        end
    end
end

--- Strips saved values identical to their registered defaults from BitForgeDB.
--- Called on PLAYER_LOGOUT after all module PLAYER_LEAVING handlers have run.
function model.CleanupDatabase()
    if not db then return end
    for name, moduleDefaults in pairs(moduleDefaultsRegistry) do
        local module = db.modules[name]
        if module then
            if module.global then
                PruneMatchingDefaults(module.global, moduleDefaults and moduleDefaults.global)
                if not next(module.global) then
                    module.global = nil
                end
            end
            if module.char then
                for charKey, charData in pairs(module.char) do
                    PruneMatchingDefaults(charData, moduleDefaults and moduleDefaults.char)
                    if not next(charData) then
                        module.char[charKey] = nil
                    end
                end
                if not next(module.char) then
                    module.char = nil
                end
            end
            if not module.global and not module.char then
                db.modules[name] = nil
            end
        end
    end
end

---@return { name: string, title: string, enabled: boolean, loaded: boolean }[]
function model.GetModuleList()
    return moduleRegistry
end

---@param modules { name: string, title: string, enabled: boolean, loaded: boolean }[]
function model.SetModuleList(modules)
    moduleRegistry = modules
end

--- Allocates a dedicated DB table for a module and delivers a live reference via callback.
--- If called before DB:Init(), the request is queued and processed once Init() completes.
--- db.global is account-wide; db.char is isolated to the current character.
---@param name     string  Unique module name (e.g. "Sample")
---@param defaults { global: table|nil, char: table|nil }
---@param callback fun(db: table)  db.global = account-wide, db.char = current character
function BitForge:AllocateModuleDB(name, defaults, callback)
    if db then
        Allocate(name, defaults, callback)
    else
        pendingAllocations[#pendingAllocations + 1] = {
            name = name,
            defaults = defaults,
            callback = callback,
        }
    end
end

--- Returns the "CharName-Realm" key for the currently logged-in character.
---@return string
function BitForge:GetCurrentCharacter()
    return UnitName("player") .. "-" .. GetRealmName()
end

--- Returns the account-wide list of known characters.
---@return string[]
function BitForge:GetKnownCharacters()
    return db and db.global.knownCharacters or {}
end

--- Registers the current character in the account-wide known characters list if not already present.
function BitForge:RegisterCharacter()
    if not db then return end
    local key = self:GetCurrentCharacter()
    local known = db.global.knownCharacters
    for _, existing in ipairs(known) do
        if existing == key then return end
    end
    known[#known + 1] = key
end

local _, ns = ...
local DB = {}
ns.DB = DB

local defaults = {
    global  = { knownCharacters = {} },
    modules = {},
}
local pendingAllocations = {}

local function SeedDefaults(tbl, src)
    if not src then return end
    for k, v in pairs(src) do
        if tbl[k] == nil then
            tbl[k] = CopyTable(v)
        end
    end
end

local function Allocate(name, moduleDefaults, callback)
    local modules        = ns.db.modules
    modules[name]        = modules[name] or {}
    local module         = modules[name]
    module.global        = module.global or {}
    module.char          = module.char or {}
    local charKey        = BitForge:GetCurrentCharacter()
    module.char[charKey] = module.char[charKey] or {}

    SeedDefaults(module.global, moduleDefaults and moduleDefaults.global)
    SeedDefaults(module.char[charKey], moduleDefaults and moduleDefaults.char)

    callback({ global = module.global, char = module.char[charKey] })
end

function DB.Init()
    BitForgeDB         = BitForgeDB or {}
    BitForgeDB.global  = BitForgeDB.global or {}
    BitForgeDB.modules = BitForgeDB.modules or {}
    SeedDefaults(BitForgeDB.global, defaults.global)
    ns.db = BitForgeDB

    for _, req in ipairs(pendingAllocations) do
        Allocate(req.name, req.defaults, req.callback)
    end
    pendingAllocations = {}
end

--- Allocates a dedicated DB table for a module and delivers a live reference via callback.
--- If called before DB:Init(), the request is queued and processed once Init() completes.
--- db.global is account-wide; db.char is isolated to the current character.
---@param name     string  Unique module name (e.g. "Sample")
---@param defaults { global: table|nil, char: table|nil }
---@param callback fun(db: table)  db.global = account-wide, db.char = current character
function BitForge:AllocateModuleDB(name, defaults, callback)
    if ns.db then
        Allocate(name, defaults, callback)
    else
        pendingAllocations[#pendingAllocations + 1] = {
            name     = name,
            defaults = defaults,
            callback = callback,
        }
    end
end

--- Returns the "Realm:CharName" key for the currently logged-in character.
---@return string
function BitForge:GetCurrentCharacter()
    return UnitName("player") .. "-" .. GetRealmName()
end

--- Returns the account-wide list of known characters.
---@return string[]
function BitForge:GetKnownCharacters()
    return ns.db and ns.db.global.knownCharacters or {}
end

--- Registers the current character in the account-wide known characters list if not already present.
function BitForge:RegisterCharacter()
    if not ns.db then return end
    local key   = self:GetCurrentCharacter()
    local known = ns.db.global.knownCharacters
    for _, existing in ipairs(known) do
        if existing == key then return end
    end
    known[#known + 1] = key
end

--- Reads a value from the Core global settings.
---@param key string
---@return any
function DB.Get(key)
    return ns.db and ns.db.global[key]
end

--- Writes a value to the Core global settings.
---@param key string
---@param value any
function DB.Set(key, value)
    if ns.db then
        ns.db.global[key] = value
    end
end

---@type BitForge.Core
local ns = select(2, ...)

local ipairs = ipairs
local next = next
local pairs = pairs
local setmetatable = setmetatable
local sub = string.sub
local type = type
local wipe = table.wipe

---@class BitForge.Core.Model
local model = ns.model

---@type BitForge.Core.Locale
local locale = ns.locale

local db
local pendingAllocations = {}
local moduleRegistry = {}
local moduleDefaultsRegistry = {}
local moduleProxyRegistry = {}
local moduleFreshRegistry = {}
local moduleAddonNames = {}

local PREFIX = ns.enum.ADDON_PREFIX
local PREFIX_LEN = #PREFIX

--- The key a module's saved data lives under, derived from the addon name the
--- module passes in from its own `...`.
---
--- Every module addon is BitForge_<Module> and stores under the bare <Module>,
--- so the saved file is not a column of repeated prefixes. Deriving it here
--- rather than having each module hand over a second, hand-written short name
--- is what keeps the two from ever drifting apart.
---
--- A name without the prefix passes through unchanged: the public entry points
--- are callable with an arbitrary string, and a caller that names a module core
--- has never seen should reach the same "no such module" path either way.
---@param addonName string
---@return string
local function ModuleKey(addonName)
    if sub(addonName, 1, PREFIX_LEN) == PREFIX then
        return sub(addonName, PREFIX_LEN + 1)
    end
    return addonName
end

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

--- The module's stored diagnostics value, normalized to a container.
---
--- The shape a module reads is `{ enabled = <boolean>, dump = <table> }`, but
--- the value in the saved file is hand-written, so it arrives in whatever shape
--- a developer typed. The documented one-liner is still a bare
--- `/run BitForgeDB.modules.UPS.debug = true`, and indexing that scalar for
--- .enabled would raise, so a truthy scalar is upgraded in place the first time
--- it is read. A container typed without its dump table is completed the same
--- way, so nothing downstream has to check whether dump exists.
---
--- The upgrade is a write during a read, which is what keeps the flag live: the
--- container the module ends up holding is the one in the saved file, so a dump
--- written into it persists rather than landing in a copy.
---@param module table  The module's raw saved container.
---@return table|nil
local function DebugContainer(module)
    local stored = module.debug
    if not stored then return nil end
    if type(stored) ~= "table" then
        stored = { enabled = true }
        module.debug = stored
    end
    if stored.dump == nil then
        stored.dump = {}
    end
    return stored
end

local function Allocate(name, moduleDefaults, callback)
    local modules = db.modules
    -- Recorded before the container is created: a module with no prior
    -- container has no data to upgrade, and the schema system uses this to
    -- stamp a new profile rather than prompt a player about data they never
    -- had. Assigned rather than only set true, so a second login in the same
    -- session (the tests do this) correctly reads false.
    --
    -- A container holding nothing but a hand-written debug flag is still a
    -- profile that has never stored anything, so it reads as fresh too --
    -- otherwise switching a module's diagnostics on would make the schema
    -- system offer to convert data that was never there.
    local existing = modules[name]
    moduleFreshRegistry[name] = existing == nil
        or (existing.global == nil and existing.char == nil)
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

    -- db.debug is read through __index rather than copied in, so it answers
    -- whatever is in the saved file at the moment it is asked. That makes
    -- `/run BitForgeDB.modules.UPS.debug = true` take effect on the next check
    -- instead of the next login. It is deliberately not part of the module's
    -- defaults or its schema: nothing seeds it, nothing migrates it, and a
    -- module that has never been flagged reads nil.
    --
    -- What comes back is the container, not a boolean: a module asks it for
    -- .enabled and parks diagnostics in .dump. Returning the container rather
    -- than unwrapping it here is what lets a dump written by a module reach the
    -- saved file, since it is the stored table itself.
    local proxies = setmetatable({ global = globalProxy, char = charProxy }, {
        __index = function(_, k)
            if k == "debug" then return DebugContainer(module) end
        end,
    })
    moduleProxyRegistry[name] = proxies

    callback(proxies)
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

--- The schema version stored for a module.
---
--- Core owns db.modules[<name>].global.schemaVersion outright: modules neither
--- declare it in their defaults nor read it. It lives inside the module's own
--- global table rather than beside it because TaskTome shipped it there first,
--- and moving it would read back as 0 for every existing user -- firing that
--- module's reset step and wiping real data on upgrade.
---@param name string
---@return number
function model.GetModuleSchemaVersion(name)
    local module = db and db.modules[name]
    local stored = module and module.global and module.global.schemaVersion
    return stored or 0
end

---@param name    string
---@param version number
function model.SetModuleSchemaVersion(name, version)
    local module = db and db.modules[name]
    if module and module.global then
        module.global.schemaVersion = version
    end
end

--- Whether this session created the module's container, meaning a profile that
--- has never stored anything for it.
---@param name string
---@return boolean
function model.WasModuleCreatedFresh(name)
    return moduleFreshRegistry[name] == true
end

--- The { global, char } proxies a module was handed at allocation.
---
--- Migration steps are given these rather than the raw saved tables, so a step
--- writes through exactly the same path the module does.
---@param name string
---@return table|nil
function model.GetModuleProxies(name)
    return moduleProxyRegistry[name]
end

--- What has to happen before a module may run against its stored database.
---
--- Migration-first: every version between the stored one and the target needs a
--- registered step. A gap is reported rather than skipped, because a silent
--- pass would start the module against a shape nothing ever converted.
---
--- "current" -- nothing to do. Also covers a database from a newer build: a
---              rollback usually reads as a superset, and refusing to start is
---              worse for the player than reading extra fields.
--- "run"     -- an ordered array of { version, step } to apply.
--- "gap"     -- the first version with no registered step.
---@param stored  number
---@param version number
---@param steps   table<number, function>|nil
---@return string       verdict
---@return table|number|nil detail
function model.ResolveSchemaUpgrade(stored, version, steps)
    if stored >= version then return "current" end

    local plan = {}
    for target = stored + 1, version do
        local step = steps and steps[target]
        if step == nil then return "gap", target end

        plan[#plan + 1] = { version = target, step = step }

        -- A reset re-seeds the current defaults, which is the current shape by
        -- definition, so any step past it would run against data it was never
        -- written for.
        if step == BitForge.SCHEMA_RESET then break end
    end

    return "run", plan
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
--- Called on PLAYER_LOGOUT, which core registers privately: no module observes
--- logout, so there is nothing to run ahead of this.
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
            -- A debug flag is hand-written, never defaulted, so there is no
            -- default for it to match and nothing above prunes it. It does have
            -- to keep its container alive on its own, though: a module flagged
            -- for diagnostics but otherwise left at defaults would lose the
            -- flag on logout if an empty global and char were enough to drop
            -- the whole entry.
            --
            -- The diagnostics container earns that only while it carries
            -- something. Switched off with nothing dumped it says exactly what
            -- an absent one says, and because any table is truthy, leaving it
            -- behind would pin the module's whole entry in the saved file
            -- forever. The empty dump goes first -- reading the flag next
            -- session recreates it -- and a container left holding neither an
            -- enabled flag nor a dump goes with it.
            local diagnostics = module.debug
            if type(diagnostics) == "table" then
                if diagnostics.dump and not next(diagnostics.dump) then
                    diagnostics.dump = nil
                end
                if not diagnostics.enabled and not diagnostics.dump then
                    module.debug = nil
                end
            end

            if not module.global and not module.char and not module.debug then
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
--- db.global is account-wide; db.char is isolated to the current character;
--- db.debug is the module's diagnostics container, `{ enabled, dump }` or nil,
--- read live.
---
--- Pass the addon's own name from `...` -- core derives the storage key and
--- keeps the full name to look the module's .toc title up by.
---@param addonName string  The addon's name from `...`, e.g. "BitForge_UPS"
---@param defaults  { global: table|nil, char: table|nil }
---@param callback  fun(db: table)  db.global = account-wide, db.char = current character
function BitForge:AllocateModuleDB(addonName, defaults, callback)
    local name = ModuleKey(addonName)
    moduleAddonNames[name] = addonName

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

--- Clears a module's entire saved database -- the account-wide table and every
--- character's slot -- and re-seeds its registered defaults.
---
--- Wipes in place rather than replacing tables. A module captures its db proxies
--- at file-read time and those proxies close over the specific tables bound at
--- allocation, so swapping in fresh ones would leave the module writing to a
--- detached table that is never saved. That failure is silent until the next
--- login, which is why this is the one thing the tests pin explicitly.
---
--- Safe to call for a module that has never allocated.
---@param addonName string  the addon's name from `...`, e.g. "BitForge_UPS"
function BitForge:ResetModuleDB(addonName)
    if not db then return end
    local name = ModuleKey(addonName)
    local module = db.modules[name]
    if not module then return end

    local defaults = moduleDefaultsRegistry[name]

    if module.global then
        wipe(module.global)
        SeedDefaults(module.global, defaults and defaults.global)
    end

    if module.char then
        -- The current character's table is wiped in place because a live proxy
        -- points at it; every other character's is dropped outright, since
        -- nothing holds a reference and the next login re-creates it.
        local charKey = BitForge:GetCurrentCharacter()
        for key, charData in pairs(module.char) do
            if key == charKey then
                wipe(charData)
                SeedDefaults(charData, defaults and defaults.char)
            else
                module.char[key] = nil
            end
        end
    end
end

-- One shared popup, so a login that upgrades two modules asks twice in sequence
-- rather than racing one dialog. Requests past the first wait in this queue.
local schemaResetQueue = {}

--- The title a popup names a module by.
---
--- Read from the addon's .toc rather than a locale key: every module already
--- ships a localized Title, and asking each for one would mean four modules'
--- worth of new strings in eleven files to say what the .toc already says.
---@param name string
---@return string
local function ResolveModuleTitle(name)
    -- The addon name recorded at allocation, not one rebuilt from the storage
    -- key: a module reaching the reset popup has allocated by definition, so
    -- the real name it passed in is already on hand.
    local addonName = moduleAddonNames[name]
    if not addonName then return name end
    local _, title = C_AddOns.GetAddOnInfo(addonName)
    return title or name
end

---@param name    string
---@param version number
---@param detail  string
local function ReportSchemaFailure(name, version, detail)
    -- Deliberately untranslated: this fires only when a module ships a broken
    -- step chain, which is a bug report for the developer, not player copy.
    CallErrorHandler(("BitForge: %s cannot upgrade its saved data to schema version %d (%s). The module will not start.")
        :format(name, version, tostring(detail)))
end

local function ShowNextSchemaReset()
    local request = schemaResetQueue[1]
    if not request then return end

    StaticPopupDialogs["BITFORGE_SCHEMA_RESET"].text =
        locale["msg:schemaResetBody"]:format(request.title)
    StaticPopup_Show("BITFORGE_SCHEMA_RESET")
end

-- Acknowledge-only, and startup waits behind it. There is no cancel: the module
-- cannot run against the old schema, so declining would leave it inert and the
-- player mystified about why nothing works.
StaticPopupDialogs["BITFORGE_SCHEMA_RESET"] = {
    text         = "",
    button1      = locale["btn:schemaResetAccept"],
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = false,
    showAlert    = true,
    OnAccept     = function()
        local request = table.remove(schemaResetQueue, 1)
        if request then
            BitForge:ResetModuleDB(request.name)
            -- Stamped after the wipe, which clears the global table the version
            -- lives in.
            model.SetModuleSchemaVersion(request.name, request.version)
            if request.onReady then request.onReady() end
        end

        -- Deferred rather than called inline: StaticPopup_OnClick hides
        -- whichever dialog is on screen for this popup key right after this
        -- handler returns, and StaticPopup_Show reuses that same frame for
        -- the next request because this dialog does not declare `multiple`.
        -- Showing the queued popup synchronously here would show it and then
        -- hide it again in the same click.
        if schemaResetQueue[1] then C_Timer.After(0, ShowNextSchemaReset) end
    end,
}

--- Brings a module's saved database up to its current schema, then starts it.
---
--- Migration-first: every version between what is stored and spec.version needs
--- an entry in spec.steps, keyed by the version that step produces. A step is a
--- function receiving the module's { global, char } proxies, or
--- BitForge.SCHEMA_RESET for a version whose shape cannot be carried forward.
--- The version only advances after a step returns without error, so a step
--- that throws partway through is re-invoked from the top on the next login,
--- against whatever it already mutated before failing -- a step must be safe
--- to run again from scratch, not merely safe to run once.
---
--- The char proxy a step receives is bound to whichever character is
--- currently logging in. A step that converts a per-character key only
--- converts that one character's table, while the version stamped afterward
--- is account-wide and will read as already-migrated for every other
--- character forever. A step touching char data is responsible for its own
--- per-character bookkeeping if it needs every alt converted.
---
--- onReady runs on every path that leaves the database usable, and does not run
--- at all when the chain is broken -- a module must never start against a shape
--- nothing converted.
---
--- A step runs against a database into which the CURRENT target-version
--- defaults have already been deep-merged -- Allocate seeds them at file-read
--- time, long before PLAYER_READY reaches this function. A step therefore
--- cannot use "the new key is absent" as its signal, because that key was
--- already filled in with its default before the step ever ran; it must test
--- the OLD key's presence instead.
---@param addonName string  The addon's name from `...`, e.g. "BitForge_UPS"
---@param spec      { version: number, title: string|nil, hasData: (fun(): boolean)|nil, steps: table }
---@param onReady   fun()|nil
function BitForge:UpgradeModuleDB(addonName, spec, onReady)
    local name = ModuleKey(addonName)

    -- A module must have allocated its database (via AllocateModuleDB) before
    -- asking to upgrade it. Without this guard an unallocated module reads as
    -- having nothing to convert -- WasModuleCreatedFresh and
    -- GetModuleSchemaVersion both answer as if the module were current -- or,
    -- worse, a reset step is accepted, ResetModuleDB and SetModuleSchemaVersion
    -- both silently no-op against a container that does not exist, and the
    -- module starts believing data was cleared that never existed to clear.
    if not model.GetModuleProxies(name) then
        ReportSchemaFailure(name, spec.version, "the module has not allocated a database")
        return
    end

    local version = spec.version

    -- A container created this session belongs to a profile that has never
    -- stored anything for this module, so there is nothing to convert and
    -- nothing to warn about.
    if model.WasModuleCreatedFresh(name) then
        model.SetModuleSchemaVersion(name, version)
        if onReady then onReady() end
        return
    end

    local verdict, detail = model.ResolveSchemaUpgrade(
        model.GetModuleSchemaVersion(name), version, spec.steps)

    if verdict == "current" then
        if onReady then onReady() end
        return
    end

    if verdict == "gap" then
        ReportSchemaFailure(name, detail, "no migration step is registered for it")
        return
    end

    local moduleDB = model.GetModuleProxies(name)

    for _, entry in ipairs(detail) do
        if entry.step == BitForge.SCHEMA_RESET then
            -- Asked rather than assumed: a profile holding only defaults reads
            -- as pre-upgrade too, and telling that player their data was
            -- cleared would be both false and alarming.
            local hasData = spec.hasData == nil or spec.hasData()
            if not hasData then
                model.SetModuleSchemaVersion(name, version)
                if onReady then onReady() end
                return
            end

            schemaResetQueue[#schemaResetQueue + 1] = {
                name    = name,
                version = version,
                onReady = onReady,
                title   = spec.title or ResolveModuleTitle(name),
            }
            if #schemaResetQueue == 1 then ShowNextSchemaReset() end
            return
        end

        local ok, err = pcall(entry.step, moduleDB)
        if not ok then
            ReportSchemaFailure(name, entry.version, err)
            return
        end

        -- Stamped per step, not once at the end: a chain that dies partway
        -- through does not replay the steps that already succeeded on the
        -- next login. It does replay the one that failed, against whatever
        -- that step already mutated before throwing -- see the doc comment
        -- above on why a step must tolerate that.
        model.SetModuleSchemaVersion(name, entry.version)
    end

    if onReady then onReady() end
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

-- ================================================================================
-- Reagent catalogue
-- ================================================================================
--
-- enum.REAGENT_PROFESSIONS maps an item ID to a bitmask of the professions that
-- consume it, generated into ReagentData.lua by Scripts/scrape_reagents.py. It
-- answers one question -- does anyone want this item as a crafting reagent? --
-- so a consumer can decline to vendor something an alt needs.
--
-- The shipped table is not complete and cannot be. It carries one item ID per
-- reagent slot, so the other quality tiers of a reagent are absent, and no
-- optional or finishing reagents at all, because Wowhead exposes those only as
-- modified-crafting category IDs. What an open profession window shows is
-- exact, so control.lua records the difference and this folds it back on top.
--
-- ABSENCE MEANS "NOT KNOWN", NEVER "NOBODY WANTS THIS". A consumer that reads
-- nil as a no would sell the very items this exists to protect, and would do it
-- silently. Fall through to your own rules instead.

local band, bor, lshift = bit.band, bit.bor, bit.lshift

-- db.global.reagentScan once the merge has run, nil before it. Held here so the
-- recording path cannot write into a store that was never reconciled with the
-- shipped table's version.
local reagentScan

--- Folds previously recorded scan results into the shipped catalogue in memory.
---
--- One-way and in-memory on purpose: the shipped table is a Lua literal rebuilt
--- from source every session, so nothing accumulates across logins except the
--- scan store itself.
function model.MergeReagentScan()
    local catalogue = ns.enum.REAGENT_PROFESSIONS
    if not (db and catalogue) then return end

    local stored = db.global.reagentScan

    -- A newly shipped catalogue supersedes everything recorded against the old
    -- one: either it now holds those reagents outright, or the game changed
    -- under them. Reset rather than prune entry by entry, which cannot tell
    -- those two apart and would keep stale credits alive forever.
    if not stored or stored.interface ~= ns.enum.REAGENT_DATA_INTERFACE then
        stored = {
            interface = ns.enum.REAGENT_DATA_INTERFACE,
            professions = {},
            reagents = {},
        }
        db.global.reagentScan = stored
    end

    for itemID, mask in pairs(stored.reagents) do
        catalogue[itemID] = bor(catalogue[itemID] or 0, mask)
    end

    reagentScan = stored
end

--- Whether a profession has already been scanned against the shipped catalogue.
---
--- Recorded account-wide rather than per session: a profession's recipe list
--- only gains entries when the game patches, and a patch moves the interface
--- the catalogue is stamped with, which resets this along with everything else.
---@param profession number  Enum.Profession
---@return boolean
function model.HasScannedProfession(profession)
    return reagentScan ~= nil and reagentScan.professions[profession] == true
end

--- Records the reagents a profession window showed that the catalogue lacked.
---
--- Only the difference is stored. After a good scrape most professions add
--- nothing, and storing the whole window would put tens of thousands of entries
--- in every player's saved variables to restate what is already shipped.
---@param profession number    Enum.Profession
---@param itemIDs    number[]  every reagent the window's recipes consume
---@return number added  reagents newly credited to this profession
function model.RecordReagentScan(profession, itemIDs)
    local catalogue = ns.enum.REAGENT_PROFESSIONS
    if not (reagentScan and catalogue) then return 0 end

    reagentScan.professions[profession] = true

    local professionBit = lshift(1, profession)
    local added = 0

    for _, itemID in ipairs(itemIDs) do
        local known = catalogue[itemID] or 0
        if band(known, professionBit) == 0 then
            catalogue[itemID] = bor(known, professionBit)
            reagentScan.reagents[itemID] =
                bor(reagentScan.reagents[itemID] or 0, professionBit)
            added = added + 1
        end
    end

    return added
end

--- Whether core's own diagnostics are switched on.
---
--- Hand-written into the saved variables -- `/run BitForgeDB.debug = true` --
--- and read live, so it takes effect on the next check without a reload. Core's
--- flag is a plain boolean rather than the { enabled, dump } container a module
--- gets: nothing in core writes diagnostics out to be shared.
---@return boolean
function model.IsDebug()
    return db ~= nil and db.debug ~= nil and db.debug ~= false
end

--- Whether the shipped catalogue predates the running client.
---
--- Recipes added by a patch are missing until a profession window is opened on
--- them, so this is a prompt to re-run the update_wowhead skill, not a fault.
---@return boolean
function model.IsReagentDataStale()
    local stamped = ns.enum.REAGENT_DATA_INTERFACE
    if not stamped then return false end
    return (select(4, GetBuildInfo()) or 0) > stamped
end

--- The professions that use an item as a crafting reagent, as a bitmask.
---
--- Returns nil when the item is not in the catalogue, which means NOT KNOWN --
--- see the note at the top of this section before treating it as a no.
---@param itemID number
---@return number|nil mask  test against enum.REAGENT_PROFESSION_BIT
function BitForge:GetReagentProfessions(itemID)
    local catalogue = ns.enum.REAGENT_PROFESSIONS
    return catalogue and catalogue[itemID]
end

-- ================================================================================
-- Profession registry
-- ================================================================================
--
-- GetProfessions() only ever answers for the character who is logged in, so the
-- account-wide picture has to be accumulated one login at a time. It lives in
-- core because two modules ask the same question of it -- BatchSell to decide
-- whether a reagent is worth keeping, UPS to decide whether it is worth
-- depositing -- and a second copy refreshed by a second code path would
-- eventually disagree with the first.
--
-- Stored per character rather than as a bare account mask, because UPS asks a
-- per-character question: whether one named alt has a profession AND has not
-- learned a given recipe. The mask is derived from it.

-- Rebuilt on demand and dropped whenever the registry changes, rather than
-- recomputed per item: BatchSell asks this once per bag slot at a merchant.
local accountProfessionMask

--- The professions recorded for a character, or nil if none ever were.
---@param charKey string  as returned by BitForge:GetCurrentCharacter()
---@return table|nil  array of Enum.Profession
function BitForge:GetCharacterProfessions(charKey)
    return db and db.global.professions[charKey]
end

--- Whether a character holds a profession.
---
--- Compared by equality rather than truthiness: Enum.Profession.FirstAid is 0,
--- and a guard that treated 0 as absent would silently drop it.
---@param charKey string
---@param profession number  an Enum.Profession
---@return boolean
function BitForge:HasProfession(charKey, profession)
    local recorded = db and db.global.professions[charKey]
    if not recorded then return false end

    for _, entry in ipairs(recorded) do
        if entry == profession then return true end
    end

    return false
end

--- Replaces the professions recorded for a character.
---
--- Replacement rather than merge, and that is the whole reason this is not
--- append-only: a character who abandons a profession must stop counting for it,
--- or the account keeps reagents for a trade nobody has.
---@param charKey    string
---@param professions table  array of Enum.Profession
function BitForge:RecordCharacterProfessions(charKey, professions)
    if not db then return end
    db.global.professions[charKey] = professions
    accountProfessionMask = nil
end

--- Every profession any known character has, as a bitmask.
---
--- Only characters that have logged in since the registry existed are in it, so
--- a bank alt nobody has visited is missing. That is a floor, not a fault: the
--- mask under-reports, and both consumers treat a profession they do not know
--- about as one that does not want the item -- the same direction as an item
--- missing from the catalogue.
---@return number  test against enum.REAGENT_PROFESSION_BIT
function BitForge:GetAccountProfessions()
    if accountProfessionMask then return accountProfessionMask end
    if not db then return 0 end

    local mask = 0
    for _, professions in pairs(db.global.professions) do
        for _, profession in ipairs(professions) do
            mask = bor(mask, lshift(1, profession))
        end
    end

    accountProfessionMask = mask
    return mask
end

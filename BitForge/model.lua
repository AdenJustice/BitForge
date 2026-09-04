---@type string, BitForge.Core
local ADDON_NAME, ns = ...

local ipairs = ipairs
local next = next
local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local type = type
local sub = string.sub
local sort = table.sort
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
--- Core is the one name stated rather than derived -- see enum.CORE_KEY for why.
---
--- Any other name without the prefix passes through unchanged: the public entry
--- points are callable with an arbitrary string, and a caller that names a
--- module core has never seen should reach the same "no such module" path
--- either way.
---@param addonName string
---@return string
local function ModuleKey(addonName)
    if addonName == ADDON_NAME then
        return ns.enum.CORE_KEY
    end
    if sub(addonName, 1, PREFIX_LEN) == PREFIX then
        return sub(addonName, PREFIX_LEN + 1)
    end
    return addonName
end

-- Published so the slash-command surface names a module exactly as its saved
-- data is keyed, rather than carrying a second copy of the strip.
model.ModuleKey = ModuleKey

--- Where an addon's diagnostics dump is read back from in the saved variables.
---
--- Core's is the database root: it has no BitForgeDB.modules entry, so the one
--- place that prints the path is the one place that has to know the difference.
---@param addonName string  the addon's name from `...`
---@return string
function model.DumpPath(addonName)
    if addonName == ADDON_NAME then
        return "BitForgeDB.debug.dump"
    end
    return "BitForgeDB.modules." .. ModuleKey(addonName) .. ".debug.dump"
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

--- A stored diagnostics value, normalized to a container.
---
--- The shape a caller reads is `{ enabled = <boolean>, dump = <table> }`, but
--- the value in the saved file is hand-written, so it arrives in whatever shape
--- a developer typed. The documented one-liner is still a bare
--- `/run BitForgeDB.modules.AzerothPrime.debug = true`, and indexing that scalar for
--- .enabled would raise, so a truthy scalar is upgraded in place the first time
--- it is read. A container typed without its dump table is completed the same
--- way, so nothing downstream has to check whether dump exists.
---
--- The upgrade is a write during a read, which is what keeps the flag live: the
--- container the caller ends up holding is the one in the saved file, so a dump
--- written into it persists rather than landing in a copy.
---
--- Takes the table the flag hangs off rather than a module name, because core's
--- own flag is a sibling of BitForgeDB.global exactly as a module's is a sibling
--- of its own -- one shape, one normalizer, two places it hangs.
---@param owner table  the raw saved table carrying a `debug` field.
---@return table|nil
local function DebugContainer(owner)
    local stored = owner.debug
    if not stored then return nil end
    if type(stored) ~= "table" then
        stored = { enabled = true }
        owner.debug = stored
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
    -- `/run BitForgeDB.modules.AzerothPrime.debug = true` take effect on the next check
    -- instead of the next login. It is deliberately not part of the module's
    -- defaults or its schema: nothing seeds it, nothing migrates it, and a
    -- module that has never been flagged reads nil.
    --
    -- What comes back is the container, not a boolean: a module asks it for
    -- .enabled and parks diagnostics in .dump.
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

    -- The retired reagent scan's store: nothing reads it now that the catalogue
    -- is generated from the client's own recipe lists. Unconditional so a profile
    -- that has not been opened in a year is still cleared on its next login.
    db.global.reagentScan = nil

    for _, req in ipairs(pendingAllocations) do
        Allocate(req.name, req.defaults, req.callback)
    end
    pendingAllocations = {}
end

---@param key string
---@return any
function model.ReadDatabase(key)
    return db and db.global[key]
end

---@param key string
---@param value any
function model.UpdateDatabase(key, value)
    if db then
        db.global[key] = value
    end
end

local VERSION_PATTERN = "^v%d+%.%d+%.%d+%.%d+$"

--- An addon's version, or nil when the .toc's token was never substituted.
--- Core's own unless another addon is named.
---
--- BitForge.toc carries `## Version: @project-version@`, which the CurseForge
--- packager replaces from the tag. A development checkout has the literal, and
--- a literal is not a version -- so it reads as nil here rather than being
--- compared against release numbers it can never match.
---
--- Any installed addon can be asked, because GetAddOnMetadata reads the .toc
--- and calls into nothing the addon itself supplies: a module packaged before
--- core ever compared versions is readable, and so is one too broken to run.
---@param addonName string|nil  the addon to read; core itself when absent
---@return string|nil
function model.GetAddonVersion(addonName)
    local version = C_AddOns.GetAddOnMetadata(addonName or ADDON_NAME, "Version")
    if type(version) ~= "string" or not version:match(VERSION_PATTERN) then
        return nil
    end
    return version
end

--- The releases a player has not seen, newest first.
---
--- Compared by identity rather than by arithmetic: the changelog skips a
--- revision, repeats dates across adjacent releases and is not monotonic in the
--- gaps between them, so the shipped table's own order is the only ordering
--- that holds.
---
--- A fresh install gets the newest release alone. Handing someone their first
--- five releases of history would be an archive, not news.
---@param seenVersion string|nil
---@param runningVersion string|nil
---@return table  a new array; never the shipped table
function model.ReleaseNotesSince(seenVersion, runningVersion)
    local notes = ns.enum.RELEASE_NOTES
    if not runningVersion or not notes or #notes == 0 then return {} end
    if seenVersion == runningVersion then return {} end

    if not seenVersion or seenVersion == "" then
        return { notes[1] }
    end

    local unseen = {}
    for _, release in ipairs(notes) do
        if release.version == seenVersion then
            return unseen
        end
        unseen[#unseen + 1] = release
    end
    -- seenVersion never matched an entry: it is older than anything shipped
    -- (or a stray value), and falling off the end here having collected every
    -- release is deliberate, not a miss -- it is the "not in the shipped
    -- list" row of the rule.
    return unseen
end

--- The newest shipped release, for the slash command's fallback when nothing
--- is unseen (or the running version is unreadable, so ReleaseNotesSince
--- never returns anything at all).
---@return table
function model.NewestRelease()
    return ns.enum.RELEASE_NOTES[1]
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


--- Empties one diagnostics dump, in place.
---
--- Emptied in place rather than replaced, so whoever is holding the table from
--- earlier in the session goes on writing into the one that is stored.
---
--- Reaches the raw container rather than DebugContainer, so a profile whose
--- diagnostics have not been read yet this session is swept too, without
--- normalizing a container into existence for one that has none.
---@param owner table  the raw saved table carrying a `debug` field.
local function WipeDump(owner)
    local diagnostics = owner.debug
    if type(diagnostics) == "table" and type(diagnostics.dump) == "table" then
        wipe(diagnostics.dump)
    end
end

--- Empties core's debug dump and every module's, in place.
function model.WipeDebugDumps()
    if not db then return end
    WipeDump(db)
    for _, module in pairs(db.modules) do
        WipeDump(module)
    end
end

--- Drops a diagnostics container that is no longer carrying anything.
---
--- A debug flag is hand-written, never defaulted, so there is no default for it
--- to match and the prune above never reaches it. It does have to keep its own
--- container alive, though: a profile flagged for diagnostics but otherwise left
--- at defaults would lose the flag on logout if an empty global and char were
--- enough to drop the whole entry.
---
--- The container earns that only while it carries something. Switched off with
--- nothing dumped it says exactly what an absent one says, and because any table
--- is truthy, one left behind would pin its entry in the saved file forever. The
--- empty dump goes first -- reading the flag next session recreates it -- and a
--- container left holding neither an enabled flag nor a dump goes with it.
---@param owner table  the raw saved table carrying a `debug` field.
local function PruneDebugContainer(owner)
    local diagnostics = owner.debug
    if type(diagnostics) ~= "table" then return end

    if diagnostics.dump and not next(diagnostics.dump) then
        diagnostics.dump = nil
    end
    if not diagnostics.enabled and not diagnostics.dump then
        owner.debug = nil
    end
end

--- Strips saved values identical to their registered defaults from BitForgeDB.
--- Called on PLAYER_LOGOUT, which core registers privately: no module observes
--- logout, so there is nothing to run ahead of this.
function model.CleanupDatabase()
    if not db then return end
    PruneDebugContainer(db)
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
            PruneDebugContainer(module)

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

--- Every loaded module carrying a version core was not released beside, minus
--- the ones the player has already been told about at this exact pair of
--- versions.
---
--- Plain equality, never an ordering. The six projects share one release
--- stream and one tag, so anything released together carries the identical
--- string and any difference at all means the two were not installed together.
--- Nothing finer is available to ask -- a .toc's `## Dependencies:` is a bare
--- name list and has never carried a version qualifier -- and nothing finer is
--- meant: a difference here says the pair was never tested together, not that
--- it is known to be broken.
---
--- A version that does not parse on either side is "cannot tell" rather than a
--- mismatch, so a development checkout says nothing and records nothing, and
--- the real answer is still spoken the first time a released build reads it.
---
--- Reports without recording. The caller records each pair after saying it,
--- through model.RecordVersionSkewTold -- so a failure between the two costs a
--- login rather than the message, and a diagnostic that wants to see the
--- current answer can ask without consuming it.
---@return { name: string, version: string, coreVersion: string }[]
function model.VersionSkew()
    local coreVersion = model.GetAddonVersion()
    if not db or not coreVersion then return {} end

    local told = db.global.versionSkewTold
    local skewed = {}
    for _, entry in ipairs(moduleRegistry) do
        local name = entry.name
        -- Asked of the client rather than read off the scan's `loaded` flag,
        -- for the reason CommandTargets gives: that flag is taken while core's
        -- own ADDON_LOADED is being handled, before any module addon has been
        -- read, so it answers false for every one of them.
        -- The renamed module is the one folder here a player must not be sent
        -- to update: its CurseForge project is gone, and view.upgradeNotice is
        -- already telling them to install BitForge_AzerothPrime instead. Both
        -- fire on the same login for anyone who updated core and kept the old
        -- folders, which is what every existing install looks like the first
        -- time it takes the split.
        if C_AddOns.IsAddOnLoaded(name) and name ~= ns.enum.RENAMED_MODULE then
            local version = model.GetAddonVersion(name)
            if version and version ~= coreVersion then
                local last = told[name]
                if not last or last.core ~= coreVersion or last.module ~= version then
                    skewed[#skewed + 1] =
                        { name = name, version = version, coreVersion = coreVersion }
                end
            end
        end
    end
    return skewed
end

--- Records that a player has been told about one module's skew, so the same
--- pair is not named again at the next login.
---
--- Separate from the query above and called after the line is said, the way
--- view.releaseNotes.ShowIfNew writes lastSeenVersion after it opens the
--- window rather than before.
---@param name        string  the module's addon name
---@param version     string  the version it is running
---@param coreVersion string  the version core is running
function model.RecordVersionSkewTold(name, version, coreVersion)
    if not db then return end
    db.global.versionSkewTold[name] = { core = coreVersion, module = version }
end

--- Allocates a dedicated DB table for a module and delivers a live reference via
--- callback. Called before model.InitializeDatabase, the request is queued and
--- delivered once that runs.
--- db.global is account-wide; db.char is isolated to the current character;
--- db.debug is the module's diagnostics container, `{ enabled, dump }` or nil,
--- read live.
---
--- Pass the addon's own name from `...` -- core derives the storage key and
--- keeps the full name to look the module's .toc title up by.
---@param addonName string  The addon's name from `...`, e.g. "BitForge_AzerothPrime"
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

--- The raw stored table of a module nothing registered this session.
---
--- Raw rather than proxied, and deliberately: a retired module registered no
--- defaults, so there is nothing for a proxy to fall back to. That is also the
--- trap this function hands its caller -- the logout prune deleted every key
--- that matched the retired module's shipped default and nothing re-seeded
--- them, so a missing key means "the player left it alone", never "the player
--- turned it off". Whoever adopts the table has to supply those defaults.
---
--- Refuses a key a loaded module owns: that data is live, reachable through its
--- own proxies, and not anyone else's to take.
---
--- A container holding neither global nor char is not data. Allocate reads that
--- same shape as a fresh profile -- one carrying only a hand-set debug flag has
--- never stored a setting -- and adoption has to agree with it, or a player who
--- once switched diagnostics on would be told their settings were carried
--- across when there were none.
---@param key string  a storage key, e.g. "Openables" -- not an addon name
---@return table|nil
function BitForge:GetRetiredModuleDB(key)
    if not db or model.GetModuleProxies(key) then return nil end
    local stored = db.modules[key]
    if not stored or (stored.global == nil and stored.char == nil) then return nil end
    return stored
end

--- Deletes a retired module's stored table once its data has been adopted.
---
--- Nothing else ever will. CleanupDatabase only visits modules that registered
--- defaults this session, which is exactly why a retired table survives long
--- enough to be adopted -- and exactly why one left behind would sit in the
--- saved variables forever.
---@param key string
function BitForge:DropRetiredModuleDB(key)
    if not db or model.GetModuleProxies(key) then return end
    db.modules[key] = nil
end

--- One character's slot in a LIVE module's own table, created and seeded from
--- that module's own registered defaults if it does not already exist.
---
--- Takes the addon's own name, unlike GetRetiredModuleDB/DropRetiredModuleDB
--- above: those take a bare storage key because no live module is left to hand
--- core its own name, and here the caller is loaded like any other.
---
--- For adoption and migration only, where a module legitimately has to write
--- a character other than the one currently logging in -- ordinary operation
--- never needs this, because a module already holds a proxy bound to exactly
--- the character it is allowed to touch. A module reaching for this from a
--- normal code path is doing something wrong.
---
--- Seeding is not optional politeness: a slot created by raw assignment holds
--- only whatever was assigned into it, and nothing re-seeds it until that
--- character's own next login -- so any code reading it before then would see
--- holes where a live module sees registered defaults. An existing slot is
--- seeded too (SeedDefaults only fills what is missing), but never re-seeded
--- OVER a value already stored there.
---
--- The character currently logging in reaches through this the exact table
--- its own char proxy already writes through -- the same table, not a copy --
--- so a write through either one is visible through the other immediately.
---@param addonName string  the addon's own name from `...`
---@param charKey string
---@return table|nil  nil if the module has not allocated a database this session
function BitForge:GetModuleCharSlot(addonName, charKey)
    local name = ModuleKey(addonName)
    if not db or not model.GetModuleProxies(name) then return nil end

    local module = db.modules[name]
    module.char[charKey] = module.char[charKey] or {}

    local defaults = moduleDefaultsRegistry[name]
    SeedDefaults(module.char[charKey], defaults and defaults.char)

    return module.char[charKey]
end

--- Every charKey a LIVE module's own stored table already holds a slot for.
---
--- The enumeration half of GetModuleCharSlot above, and it exists for the same
--- callers: a migration can reach any character's slot it can name, and has no
--- way to name them. The char proxy exposes one key and offers no way to ask
--- which others exist, so a step converting per-character data would otherwise
--- convert the character logging in and silently leave every alt behind --
--- and the version stamped afterwards is account-wide, so no later login ever
--- comes back for them.
---
--- Deliberately not BitForge:GetKnownCharacters(). That registry is a
--- different set, and in the direction that matters a superset: it names
--- every character that has logged in with BitForge loaded, including ones
--- that never touched this module. Feeding those keys to GetModuleCharSlot
--- would create and seed a slot for every one of them -- per-character
--- storage invented for characters that never stored any.
---
--- Creates nothing itself: only keys already stored come back. Sorted, so a
--- migration visits them in the same order twice.
---@param addonName string  the addon's own name from `...`
---@return string[]  empty when the module has not allocated a database this session
function BitForge:GetModuleCharKeys(addonName)
    local name = ModuleKey(addonName)
    if not db or not model.GetModuleProxies(name) then return {} end

    local keys = {}
    for charKey in pairs(db.modules[name].char) do
        keys[#keys + 1] = charKey
    end
    sort(keys)

    return keys
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
---@param addonName string  the addon's name from `...`, e.g. "BitForge_AzerothPrime"
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

--- Whether any retired key a spec names still holds data to adopt.
---@param keys string[]|nil
---@return boolean
local function HasRetiredData(keys)
    if not keys then return false end
    for _, key in ipairs(keys) do
        if BitForge:GetRetiredModuleDB(key) then return true end
    end
    return false
end

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
--- A step runs against a database into which the CURRENT target-version
--- defaults have already been deep-merged -- Allocate seeds them at file-read
--- time, long before PLAYER_READY reaches this function. A step therefore
--- cannot use "the new key is absent" as its signal, because that key was
--- already filled in with its default before the step ever ran; it must test
--- the OLD key's presence instead.
---@param addonName string  The addon's name from `...`, e.g. "BitForge_AzerothPrime"
---@param spec      { version: number, title: string|nil, adopts: string[]|nil, hasData: (fun(): boolean)|nil, steps: table }
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
    --
    -- Unless the spec declares that it inherits a retired module's data: a
    -- module that merges others is new for EVERY player alive, so this
    -- short-circuit would skip its adoption for all of them. Being new is
    -- precisely the state those steps exist for.
    if model.WasModuleCreatedFresh(name) and not HasRetiredData(spec.adopts) then
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
        ---@cast detail number
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

--- The class file name recorded for a character, or nil if none ever was.
---
--- nil is the ordinary answer, not an error: the registry only learns a class
--- when that character logs in, so every alt on an existing account reads nil
--- until it is next played. A caller must render the unadorned character rather
--- than treat the absence as a fault.
---@param charKey string  as returned by BitForge:GetCurrentCharacter()
---@return string|nil  a ClassFile, e.g. "MAGE"
function BitForge:GetCharacterClass(charKey)
    return db and db.global.characterClasses[charKey]
end

--- Registers the current character in the account-wide known characters list if
--- not already present, and records the class it plays.
---
--- The class is written on every login rather than only alongside a first-time
--- insertion. A profile that predates the registry already holds every character
--- in knownCharacters, so a first-time-only write would leave all of them
--- classless forever.
function BitForge:RegisterCharacter()
    if not db then return end
    local key = self:GetCurrentCharacter()

    -- UnitClassBase MayReturnNothing. Nothing back leaves whatever was recorded
    -- before in place rather than erasing a good answer with a missing one.
    --
    -- A secret is treated identically, for the same reason: it is an answer
    -- this cannot use, and an unusable answer must not evict a usable one. The
    -- function carries SecretWhenUnitIdentityRestricted exactly as UnitClass
    -- does -- it is not exempt -- and while the documented condition ("the unit
    -- isn't player-controlled or in the party/raid") means "player" should
    -- never trip it, the docs promise nothing, characterClasses is
    -- SavedVariables, and no behaviour is defined for serialising a secret.
    -- Blizzard refuses the equivalent write outright: every setter in
    -- Blizzard_SharedXMLBase/SecureTypes.lua asserts against storing one.
    --
    -- issecretvalue itself is guarded rather than assumed present. It is
    -- documented and addon-callable on 12.1, but this runs on core's login path,
    -- where calling a nil global would take the whole suite's startup with it --
    -- and the cost of not finding out is one extra global lookup.
    local classFile = UnitClassBase("player")
    if classFile ~= nil and not (issecretvalue and issecretvalue(classFile)) then
        db.global.characterClasses[key] = classFile
    end

    local known = db.global.knownCharacters
    for _, existing in ipairs(known) do
        if existing == key then return end
    end
    known[#known + 1] = key
end

-- enum.REAGENT_PROFESSIONS maps an item ID to a bitmask of the professions that
-- consume it, generated from the game client's own recipe lists -- see
-- ReagentData.lua for how and when. It answers one question -- does anyone
-- want this item as a crafting reagent? -- so a consumer can decline to vendor
-- something an alt needs.
--
-- ABSENCE MEANS THE CAPTURE DID NOT SEE IT, which is not the same as nothing
-- wanting the item, and nothing here can tell the two apart. What a consumer
-- does with a nil is therefore its own policy: AzerothPrime's sell rules read the
-- table as complete and sell on one (#330). model.IsReagentDataStale is what says
-- whether that reading is still safe, and it is reported in debug only.

local bor, lshift = bit.bor, bit.lshift

--- Core's own diagnostics container, normalized, or nil while it has never been
--- flagged.
---
--- Hand-written as `/run BitForgeDB.debug = true` and read live, so it takes
--- effect on the next check without a reload. The same container a module gets,
--- hanging off the database root instead of a module entry, so it goes through
--- the same normalize / wipe / prune path a module's does.
---@return table|nil
local function CoreDiagnostics()
    if not db then return nil end
    return DebugContainer(db)
end

---@return boolean
function model.IsDebug()
    local diagnostics = CoreDiagnostics()
    return (diagnostics and diagnostics.enabled) and true or false
end

--- Core's debug scratch table, or nil while diagnostics are off.
---
--- Handed out rather than written through: a caller assembles its whole record
--- and drops it in. The container is the stored one, so anything filed here
--- reaches the saved variables and survives the session that produced it.
---@return table|nil
function model.GetDebugDump()
    local diagnostics = CoreDiagnostics()
    if not (diagnostics and diagnostics.enabled) then return nil end
    return diagnostics.dump
end

--- Whether the shipped catalogue predates the running client.
---
--- It will, from the first patch after the last capture: the captures behind the
--- catalogue are each one client at one build, and a rebuild means retaking
--- them all on a current client and shipping the result again -- nothing in the
--- addon does that on its own.
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

-- GetProfessions() only ever answers for the character who is logged in, so the
-- account-wide picture has to be accumulated one login at a time. It lives in
-- core because two features ask the same question of it -- AzerothPrime's sell
-- rules to decide whether a reagent is worth keeping, its bank feature to
-- decide whether it is worth depositing -- and a second copy refreshed by a
-- second code path would eventually disagree with the first.
--
-- Stored per character rather than as a bare account mask, because the bank
-- feature asks a per-character question: whether one named alt has a
-- profession AND has not learned a given recipe. The mask is derived from it.

-- Rebuilt on demand and dropped whenever the registry changes, rather than
-- recomputed per item: AzerothPrime's sell rules ask this once per bag slot at a
-- merchant.
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

--- The same mask for one character alone.
---
--- A bound item can never reach an alt, so the account-wide mask cannot vouch
--- for one: a consumer holding a soulbound reagent has to ask whether *this*
--- character's professions want it. Folded here rather than in the consumer
--- because the bit encoding is core's -- a module folding the array itself
--- would be a second copy of it, free to drift.
---@param charKey string
---@return number  test against enum.REAGENT_PROFESSION_BIT
function BitForge:GetCharacterProfessionMask(charKey)
    local recorded = db and db.global.professions[charKey]
    if not recorded then return 0 end

    local mask = 0
    for _, profession in ipairs(recorded) do
        mask = bor(mask, lshift(1, profession))
    end

    return mask
end

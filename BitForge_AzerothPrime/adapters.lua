---@class BitForge.AzerothPrime
local ns = select(2, ...)

local ipairs = ipairs
local next = next
local pairs = pairs
local pcall = pcall
local sort = table.sort
local tonumber = tonumber
local type = type
local find = string.find
local match = string.match

-- Stands in for a missing bucket so a walk over someone else's SavedVariables
-- can iterate unconditionally. Never written to.
local EMPTY = {}

---@class BitForge.AzerothPrime.Control
local control = ns.control

---@class BitForge.AzerothPrime.Control.Adapters
local adapters = {}

--- An inventory source the curation window can read.
---
--- Adapters serve the curation window only. They are never on the deposit hot
--- path -- deposits read C_Container directly, so a broken or absent third-party
--- addon can cost the user a wider item list and nothing else.
---@class AzerothPrime.Adapter
---@field name     string   identifier, and the display name for third-party sources
---@field priority number   lower is offered first
---@field IsLoaded fun(): boolean
---@field GetOwned fun(): table   -- { [itemID] = { [charKey] = count } }

local registry = {}

--- Adds a source. Called once per source at file-read time.
---@param adapter AzerothPrime.Adapter
function adapters.Register(adapter)
    registry[#registry + 1] = adapter
    sort(registry, function(left, right) return left.priority < right.priority end)
end

--- The registered sources, in priority order.
---@return table  array of AzerothPrime.Adapter
function adapters.GetRegistered()
    return registry
end

--- The first loaded source in a list, or the fallback.
---
--- Pure over its arguments so the whole of detection is testable without
--- mutating the live registry. IsLoaded runs inside pcall: a third-party source
--- is someone else's code reaching into someone else's SavedVariables, and one
--- that errors must cost the user its own data, not the window.
---@param sources table       array of AzerothPrime.Adapter, priority-ordered
---@param fallback AzerothPrime.Adapter
---@return AzerothPrime.Adapter
function adapters.SelectActive(sources, fallback)
    for _, adapter in ipairs(sources) do
        local ok, loaded = pcall(adapter.IsLoaded)
        if ok and loaded then
            return adapter
        end
    end

    return fallback
end

-- Forward declaration: GetActive and GetOwned both fall back to the built-in
-- source, which is defined below because it is the thing being fallen back to.
local builtInAdapter

---@return AzerothPrime.Adapter
function adapters.GetActive()
    return adapters.SelectActive(registry, builtInAdapter)
end

--- What the account owns, and the name of the source that said so.
---
--- The GetOwned call is guarded for the same reason IsLoaded is, and the shape
--- is checked as well as the call: a source that returns nil or a string would
--- otherwise produce an empty window that looks like an empty account.
---@return table owned  { [itemID] = { [charKey] = count } }
---@return string name  the source that produced it
function adapters.GetOwned()
    local adapter = adapters.GetActive()

    local ok, owned = pcall(adapter.GetOwned)
    if ok and type(owned) == "table" then
        return owned, adapter.name
    end

    -- Falling back to a source that just failed would only fail again, this time
    -- outside the guard, so the error would escape into the window instead of
    -- costing one adapter its data.
    if adapter == builtInAdapter then
        return {}, adapter.name
    end

    return builtInAdapter.GetOwned(), builtInAdapter.name
end

--- Adds one holding to an owned table.
---
--- Summed rather than assigned: the same item sits in several stacks across a
--- character's bags and bank tabs, and a curation row reports one total. Every
--- field is validated because these values come out of someone else's
--- SavedVariables, where a shape change is a patch away.
---@param owned table    { [itemID] = { [charKey] = count } }
---@param itemID number|nil
---@param charKey string|nil
---@param count number|nil
local function addHolding(owned, itemID, charKey, count)
    if type(itemID) ~= "number" or type(charKey) ~= "string" then return end

    count = tonumber(count) or 1
    if count <= 0 then return end

    local holders = owned[itemID]
    if not holders then
        holders = {}
        owned[itemID] = holders
    end

    holders[charKey] = (holders[charKey] or 0) + count
end

--- The item ID at the head of a stored item reference.
---
--- The four sources store three different shapes between them: a full item
--- link, a bare numeric ID, and BagBrother's colon-joined payload
--- ("2447:0:0:0"). All three put the ID first once the link header is stripped.
---
--- A reference that does not start with a number is a battle pet or a keystone
--- ("battlepet:...", "keystone:..."), which no rule in this module classifies
--- and which returns nil so addHolding drops it.
---@param reference string|number|nil
---@return number|nil
local function itemIDFromReference(reference)
    if type(reference) == "number" then return reference end
    if type(reference) ~= "string" then return nil end

    return tonumber(match(reference, "item:(%d+)")) or tonumber(match(reference, "^(%d+)"))
end

--- Syndicator's character caches.
---
--- The best public surface of the four: a documented API namespace with its own
--- readiness gate, rather than a SavedVariable read behind someone else's back.
--- Shapes verified against ~/Developer/References/Syndicator -- an occupied slot is
--- { itemID, itemCount, ... } and an empty one is a bare table
--- (Tracking/BagCache.lua:367-386).
---@type AzerothPrime.Adapter
local syndicatorAdapter = {
    name = "Syndicator",

    priority = 10,

    IsLoaded = function()
        return Syndicator ~= nil
            and Syndicator.API ~= nil
            and Syndicator.API.IsReady ~= nil
            and Syndicator.API.IsReady() == true
    end,

    GetOwned = function()
        local owned = {}

        for _, fullName in ipairs(Syndicator.API.GetAllCharacters()) do
            local characterData = Syndicator.API.GetCharacter(fullName)

            if characterData then
                -- Rebuilt from details rather than taken from the table key:
                -- the key uses GetNormalizedRealmName() and BitForge's own
                -- character keys use GetRealmName(), so on a realm with spaces
                -- the two disagree (Syndicator/Tracking/Initialize.lua:72-76).
                -- Holder keys are display-only, but a column spelling the realm
                -- differently from every other window reads as a different
                -- character.
                local details = characterData.details
                local charKey = details and details.character and details.realm
                    and (details.character .. "-" .. details.realm)
                    or fullName

                for _, container in ipairs(characterData.bags or {}) do
                    for _, slot in ipairs(container) do
                        addHolding(owned, slot.itemID, charKey, slot.itemCount)
                    end
                end

                for _, container in ipairs(characterData.bank or {}) do
                    for _, slot in ipairs(container) do
                        addHolding(owned, slot.itemID, charKey, slot.itemCount)
                    end
                end

                for _, tab in ipairs(characterData.bankTabs or {}) do
                    for _, slot in ipairs(tab.slots or {}) do
                        addHolding(owned, slot.itemID, charKey, slot.itemCount)
                    end
                end
            end
        end

        -- The warband bank belongs to no character, so it is attributed to the
        -- one looking at the window. Leaving it out would make an item the user
        -- has already deposited vanish from the list they curate against.
        local warband = Syndicator.API.GetWarband and Syndicator.API.GetWarband(1)
        if warband then
            local charKey = BitForge:GetCurrentCharacter()
            for _, tab in ipairs(warband.bank or {}) do
                for _, slot in ipairs(tab.slots or {}) do
                    addHolding(owned, slot.itemID, charKey, slot.itemCount)
                end
            end
        end

        return owned
    end,
}

--- Altoholic's storage backend.
---
--- The only source with an API built for third-party consumption
--- (DataStore:RegisterMethod / RegisterModule), and the enumeration this window
--- needs is part of that registered surface: IterateContainerSlots,
--- IteratePlayerBankSlots and IterateWarbandBank each walk their slots and hand
--- back an unpacked itemID and count, so none of DataStore's bit-packed slot
--- encoding is touched here.
---
--- Verified against ~/Developer/References/datastore_containers (thaoky, the author) and
--- ~/Developer/References/DataStore.
---@type AzerothPrime.Adapter
local dataStoreAdapter = {
    name = "DataStore_Containers",

    priority = 20,

    IsLoaded = function()
        -- Registered methods are reached through DataStore's __index metamethod,
        -- which returns nil for a method no loaded module registered
        -- (DataStore/API/Core.lua:65). So this also answers "is the Containers
        -- module present", not merely "is DataStore".
        return DataStore ~= nil
            and DataStore.IterateCharacters ~= nil
            and DataStore.IterateContainerSlots ~= nil
    end,

    GetOwned = function()
        local owned = {}

        DataStore:IterateCharacters(function(characterKey)
            -- Keys are "account.realm.character" (DataStore.lua:152-174).
            -- Rebuilt into BitForge's "Name-Realm" shape so the holders column
            -- reads the same as every other window's.
            local realm, name = match(characterKey, "^[^.]+%.([^.]+)%.(.+)$")
            ---@type string
            local charKey = (name and realm) and (name .. "-" .. realm) or characterKey

            DataStore:IterateContainerSlots(characterKey,
                function(_, itemID, _, itemCount)
                    addHolding(owned, itemID, charKey, itemCount)
                end)

            -- Non-retail clients keep the bank outside Containers, and the
            -- method is absent there rather than empty.
            if DataStore.IteratePlayerBankSlots then
                DataStore:IteratePlayerBankSlots(characterKey,
                    function(itemID, _, itemCount)
                        addHolding(owned, itemID, charKey, itemCount)
                    end)
            end
        end)

        if DataStore.IterateWarbandBank then
            local charKey = BitForge:GetCurrentCharacter()
            DataStore:IterateWarbandBank(function(itemID, _, itemCount)
                addHolding(owned, itemID, charKey, itemCount)
            end)
        end

        return owned
    end,
}

--- BagSync's per-unit caches.
---
--- Reachable but internal: _G.BagSync is the AceAddon namespace and the Data
--- module's IterateUnits is the only enumeration point, with no public contract
--- behind it. Verified against ~/Developer/References/BagSync -- IterateUnits yields
--- { realm, name, data, isGuild, ... } (wireframe/data.lua:1478-1487) and a
--- slot is a "link;count;options" string (core.lua:410-431).
---@type AzerothPrime.Adapter
local bagSyncAdapter = {
    name = "BagSync",

    priority = 30,

    IsLoaded = function()
        return BagSync ~= nil
            and BagSync.GetModule ~= nil
            and BagSync:GetModule("Data", true) ~= nil
    end,

    GetOwned = function()
        local owned = {}

        --- One "link;count;options" slot string.
        ---@param entry any
        ---@param charKey string
        local function addEntry(entry, charKey)
            if type(entry) ~= "string" then return end

            -- Split on the first two semicolons only: the third field is an
            -- encoded options blob, and item links carry no semicolon of their
            -- own, so the head is always the reference.
            local reference, count = match(entry, "^([^;]*);?(%d*)")
            addHolding(owned, itemIDFromReference(reference), charKey, tonumber(count) or 1)
        end

        --- A bucket holding one array of slots per container.
        local function addContainers(bucket, charKey)
            for _, slots in pairs(type(bucket) == "table" and bucket or EMPTY) do
                if type(slots) == "table" then
                    for _, entry in pairs(slots) do
                        addEntry(entry, charKey)
                    end
                end
            end
        end

        local data = BagSync:GetModule("Data", true)

        for unitObject in data:IterateUnits() do
            -- Guilds share the unit shape but are not characters, and this
            -- module has no guild bank destination to curate against.
            if type(unitObject) == "table" and not unitObject.isGuild
                and type(unitObject.data) == "table" then
                local charKey = (unitObject.name and unitObject.realm)
                    and (unitObject.name .. "-" .. unitObject.realm)
                    or unitObject.name

                if type(charKey) == "string" then
                    -- The three buckets that mirror what the built-in source
                    -- reads: carried bags and both halves of the bank. Each is
                    -- keyed by container, then by slot
                    -- (wireframe/data.lua:1012-1015). equip, mailbox, auction
                    -- and void are deliberately left out -- they are worn or in
                    -- transit rather than stored, and a deposit can never
                    -- reach them.
                    addContainers(unitObject.data.bag, charKey)
                    addContainers(unitObject.data.bank, charKey)
                    addContainers(unitObject.data.reagents, charKey)
                end
            end
        end

        -- The warband bank lives under a system realm key that IterateUnits
        -- skips by design (wireframe/data.lua:1227-1230, 1423), so it has to be
        -- read directly. Attributed to the current character, as in every other
        -- source.
        local warbandDB = BagSyncDB and BagSyncDB["warband§"]
        if type(warbandDB) == "table" then
            addContainers(warbandDB.tabs, BitForge:GetCurrentCharacter())
        end

        return owned
    end,
}

--- Bagnon's storage backend.
---
--- BrotherBags[realm][ownerID][bagID].items[slot] holds "payload;count" strings,
--- and the addon object's own methods are UI-oriented
--- (Frame:GetItemInfo(bag, slot)), so the SavedVariable is the practical
--- integration point. Verified against ~/Developer/References/BagBrother --
--- Cacher:ParseItem appends the count *after* the payload and only when it
--- exceeds one (core/features/caching.lua:277-308), and PopulateBag files the
--- slots under .items (core/features/caching.lua:255-271).
---@type AzerothPrime.Adapter
local bagBrotherAdapter = {
    name = "BagBrother",

    priority = 40,

    IsLoaded = function()
        return type(BrotherBags) == "table" and next(BrotherBags) ~= nil
    end,

    GetOwned = function()
        local owned = {}

        --- Every slot in one owner's cache of containers.
        ---@param cache table
        ---@param charKey string
        local function addCache(cache, charKey)
            for _, container in pairs(type(cache) == "table" and cache or EMPTY) do
                local items = type(container) == "table" and container.items

                for _, entry in pairs(type(items) == "table" and items or EMPTY) do
                    if type(entry) == "string" then
                        -- The count is appended after the payload and omitted
                        -- for a single item, so an entry with no semicolon is a
                        -- stack of one.
                        local reference, count = match(entry, "^([^;]*);?(%d*)")
                        addHolding(owned, itemIDFromReference(reference), charKey,
                            tonumber(count) or 1)
                    end
                end
            end
        end

        for realm, owners in pairs(BrotherBags) do
            -- "account" is the warband bank rather than a realm
            -- (core/features/caching.lua:194), so its contents are one level
            -- shallower and belong to nobody in particular.
            if realm == "account" then
                addCache(owners, BitForge:GetCurrentCharacter())
            else
                for ownerID, cache in pairs(type(owners) == "table" and owners or EMPTY) do
                    -- A guild's id ends in "*" (core/api/owners.lua:105-107).
                    if type(ownerID) == "string" and not find(ownerID, "*", 1, true) then
                        addCache(cache, ownerID .. "-" .. realm)
                    end
                end
            end
        end

        return owned
    end,
}

---@type AzerothPrime.Adapter
builtInAdapter = {
    name = "builtin",

    -- The highest priority number in the suite, so every third-party source is
    -- offered the job first. It is also why detection always terminates: this
    -- one is registered last and cannot fail to load.
    priority = 100,

    -- Reads the client directly, so there is nothing to be missing.
    IsLoaded = function() return true end,

    GetOwned = function()
        local owned = {}
        local charKey = BitForge:GetCurrentCharacter()

        -- control.inventory is populated by control.lua, which the TOC loads
        -- after this file. Resolved here at call time rather than captured at
        -- file-read time, when it would capture nil.
        local inventory = control.inventory

        for _, entry in ipairs(inventory.Snapshot(inventory.GetCurationContainers())) do
            local holders = owned[entry.itemID]
            if not holders then
                holders = {}
                owned[entry.itemID] = holders
            end

            holders[charKey] = (holders[charKey] or 0) + entry.count
        end

        return owned
    end,
}

-- Registered in priority order for readability; the registry sorts regardless,
-- and the built-in source's priority of 100 is what keeps it last.
adapters.Register(syndicatorAdapter)
adapters.Register(dataStoreAdapter)
adapters.Register(bagSyncAdapter)
adapters.Register(bagBrotherAdapter)
adapters.Register(builtInAdapter)

control.adapters = adapters

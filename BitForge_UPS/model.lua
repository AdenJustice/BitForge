---@type string, BitForge.UPS
local ADDON_NAME, ns = ...

local select = select
local ipairs = ipairs
local pairs = pairs
local next = next
local type = type
local C_Item = C_Item
local format = string.format
local find = string.find
local lower = string.lower
local sort = table.sort

local DB_DEFAULTS = {
    global = {
        -- [itemID] = a DESTINATION string for warband/ignore, or a table
        -- { dest = "private", owners = { [charKey] = true, ... }, target = number|nil }
        -- for private. owners is a set, not a single key: a single field would
        -- make a second character's claim silently overwrite the first, and the
        -- user would only notice later, when an item stopped coming back to the
        -- character they thought owned it. An empty set means "any character,
        -- first come".
        overrides = {},

        -- [charKey] = { Enum.Profession, ... }. Refilled from GetProfessions()
        -- at every login, so a character whose professions changed while UPS
        -- was disabled corrects itself on their next one.
        professions = {},

        -- [charKey] = { [recipeSpellID] = true }. Absent means "never scanned",
        -- which reads as "knows nothing" and biases toward depositing --
        -- deliberately, see the design's 5.5.
        knownRecipes = {},

        -- [charKey] = { [skillLineID] = timestamp }. Exists so the curation
        -- window can name characters that have never been scanned; an unscanned
        -- character is indistinguishable from one who knows nothing without it.
        recipeScans = {},
    },
    char = {
        enabled      = true,
        previewMoves = true,
    },
}
local db

-- Item IDs already named by the 5.6 diagnostic below. Session-scoped, never
-- persisted -- it is a development aid, not state the module reasons about.
local reportedSpells = {}

-- =========================================================
-- retired keys
-- =========================================================

-- Written by the module this one replaces. None appear in DB_DEFAULTS, so the
-- core's logout prune -- which only removes values matching a default -- would
-- never clear them and they would outlive the design they belonged to.
local RETIRED_GLOBAL = { "assignments", "nextCustomID", "itemCounts" }
local RETIRED_CHAR   = { "guildBankPull", "guildBankPush", "initialized" }

local function dropRetiredKeys(moduleDB)
    for _, key in ipairs(RETIRED_GLOBAL) do
        moduleDB.global[key] = nil
    end
    for _, key in ipairs(RETIRED_CHAR) do
        moduleDB.char[key] = nil
    end
end

-- Called at file-read time, per the core DB contract.
BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB)
    db = moduleDB
    dropRetiredKeys(moduleDB)
end)

---@class BitForge.UPS.Model
local model = ns.model
local enum = ns.enum

-- =========================================================
-- char settings
-- =========================================================

function model.IsEnabled() return db.char.enabled end

function model.SetEnabled(value) db.char.enabled = value end

function model.GetPreviewMoves() return db.char.previewMoves end

function model.SetPreviewMoves(value) db.char.previewMoves = value end

-- =========================================================
-- overrides
-- =========================================================

function model.GetOverride(itemID)
    return db.global.overrides[itemID]
end

function model.SetOverride(itemID, destination)
    db.global.overrides[itemID] = destination
end

function model.ClearOverride(itemID)
    db.global.overrides[itemID] = nil
end

-- =========================================================
-- recipe knowledge
-- =========================================================

--- The professions recorded for a character, or nil if none ever were.
---@param charKey string
---@return table|nil  array of Enum.Profession
function model.GetProfessions(charKey)
    return db.global.professions[charKey]
end

---@param charKey string
---@param professions table  array of Enum.Profession
function model.SetProfessions(charKey, professions)
    db.global.professions[charKey] = professions
end

--- Whether a character holds a profession.
---
--- Compared by equality rather than truthiness: Enum.Profession.FirstAid is 0,
--- and a guard that treated 0 as absent would silently drop it.
---@param charKey string
---@param profession number  an Enum.Profession
---@return boolean
function model.HasProfession(charKey, profession)
    local recorded = db.global.professions[charKey]
    if not recorded then return false end

    for _, entry in ipairs(recorded) do
        if entry == profession then return true end
    end

    return false
end

---@param charKey string
---@param spellID number
---@return boolean
function model.IsRecipeKnown(charKey, spellID)
    local known = db.global.knownRecipes[charKey]
    return known ~= nil and known[spellID] == true
end

--- Records or retracts one learned recipe.
---
--- Retraction is not symmetry for its own sake: a harvest reports both learned
--- and unlearned recipes, and the unlearned ones are how losing a profession
--- ever gets noticed. Retracting a recipe that was never recorded creates no
--- table, so a character UPS knows nothing about stays absent from the DB
--- rather than gaining an empty entry the logout prune would have to clear.
---@param charKey string
---@param spellID number
---@param known boolean
function model.SetRecipeKnown(charKey, spellID, known)
    local recorded = db.global.knownRecipes[charKey]

    if not recorded then
        if not known then return end
        recorded = {}
        db.global.knownRecipes[charKey] = recorded
    end

    recorded[spellID] = known and true or nil
end

---@param charKey string
---@param skillLineID number
---@return number|nil timestamp
function model.GetRecipeScan(charKey, skillLineID)
    local scans = db.global.recipeScans[charKey]
    return scans and scans[skillLineID] or nil
end

---@param charKey string
---@param skillLineID number
---@param timestamp number
function model.SetRecipeScan(charKey, skillLineID, timestamp)
    local scans = db.global.recipeScans[charKey]

    if not scans then
        scans = {}
        db.global.recipeScans[charKey] = scans
    end

    scans[skillLineID] = timestamp
end

--- Whether a character has ever had any recipe scan recorded.
---
--- Deliberately "any", not "this skill line": UPS cannot open a profession
--- window itself -- C_TradeSkillUI.OpenTradeSkill is protected -- so it only
--- ever harvests the expansion tab the player happened to be looking at. Which
--- child lines that covers is not knowable in advance, so the only honest
--- question is whether this character has been seen at all.
---@param charKey string
---@return boolean
function model.HasAnyRecipeScan(charKey)
    local scans = db.global.recipeScans[charKey]
    return scans ~= nil and next(scans) ~= nil
end

--- Whether some character other than this one wants this recipe.
---
--- "Wants" is: holds the profession the recipe belongs to, and has no record of
--- having learned it. The current character is excluded because a recipe in
--- their own bags is already where they can learn it -- moving it to shared
--- storage would only add a round trip.
---
--- A character with the profession but no recipe scan has no records at all, so
--- every recipe for that profession reads as wanted. That is the design's 5.5
--- bias, and it is deliberate in this direction: over-depositing costs a bank
--- slot until the recipe is vendored, where the opposite error strands a recipe
--- an alt needs in the wrong character's bags.
---@param subClassID number|nil  GetItemInfoInstant return 7 of 7
---@param itemID number
---@return boolean
function model.WantedByAlt(subClassID, itemID)
    local profession = subClassID and enum.RECIPE_PROFESSION[subClassID]
    if not profession then return false end

    -- Return 2 of 2 (ItemDocumentation.lua:948). Whether this is the recipe's
    -- own spellID or a separate teaching spell is unconfirmed in a live client
    -- -- see the design's 5.6. If it is a teaching spell the lookup below never
    -- matches and the rule degrades to "any alt with the profession", which is
    -- the same safe direction as an unscanned alt.
    local spellID = select(2, C_Item.GetItemSpell(itemID))
    if not spellID then return false end

    -- The 5.6 unknown, made observable in play rather than left to a macro run
    -- at a remembered moment: if this ID is the recipe's own then it turns up in
    -- some character's knownRecipes once they have been scanned, and if it is a
    -- separate teaching spell it never will. Once per item per session.
    if db.debug and not reportedSpells[itemID] then
        reportedSpells[itemID] = true
        BitForge:Print(format("UPS debug: recipe item %d casts spell %d", itemID, spellID))
    end

    local current = BitForge:GetCurrentCharacter()

    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        if charKey ~= current
            and model.HasProfession(charKey, profession)
            and not model.IsRecipeKnown(charKey, spellID) then
            return true
        end
    end

    return false
end

-- =========================================================
-- resolver
-- =========================================================

--- Where the rules alone would put an item, ignoring every override.
---
--- Split out of Resolve so the curation window can distinguish a destination the
--- user chose from one the rules produced, and so SetDestination can decline to
--- store a choice that only restates a rule.
---@param itemID number
---@return string destination  an enum.DESTINATION value
function model.ResolveByRule(itemID)
    -- Returns 6 and 7 of 7. select() past the end of the list yields nothing
    -- rather than erroring, so an item with no client data leaves both nil.
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))

    if classID then
        if enum.REAGENT_CLASSES[classID] then
            return enum.DESTINATION.WARBAND
        end

        if classID == Enum.ItemClass.Recipe and model.WantedByAlt(subClassID, itemID) then
            return enum.DESTINATION.WARBAND
        end
    end

    return enum.DESTINATION.IGNORE
end

--- Where an item belongs, and for a private item, who may claim it.
---
--- A user override wins; otherwise the item's class decides. Anything unmatched
--- is ignored, so the module only ever moves what it was configured or told to
--- move.
---@param itemID number
---@return string destination   an enum.DESTINATION value
---@return table|nil owners     the owner set, only for private
---@return number|nil target    the per-owner target quantity, only for private
function model.Resolve(itemID)
    local override = db.global.overrides[itemID]

    if type(override) == "table" then
        return override.dest, override.owners, override.target
    end

    if override then
        return override
    end

    return model.ResolveByRule(itemID)
end

--- Whether the current character may claim a private item.
---
--- True when they are in the owner set, and true when the set holds nobody the
--- account still knows -- an empty set means "any character, first come", and a
--- set of only stale keys reverts to that rather than becoming unreachable.
--- Stranding an item with nobody entitled to it is the failure direction this
--- avoids.
---@param owners table|nil
---@return boolean
function model.IsMine(owners)
    if not owners then return true end

    if owners[BitForge:GetCurrentCharacter()] then return true end

    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        if owners[charKey] then
            -- Some character the account still knows owns this, and it is not
            -- us, so the claim belongs to them.
            return false
        end
    end

    return true
end

--- Where one stack goes from where it currently is, or nil to leave it alone.
---
--- The design's 6.4 table in executable form, and the only place it exists. The
--- planner calls it to emit descriptors and the executor calls it again
--- immediately before each move, so "only what the user asked for moves" is a
--- rule enforced at the point of action rather than a property assumed to have
--- survived from plan time.
---
--- There is never a move out of the warband bank except a private item coming
--- home: crafting already reaches shared storage in place, so pulling anything
--- else back into bags would be work with no result.
---@param itemID number
---@param fromWarband boolean  true when the stack is in a warband tab
---@return string|nil destination  a descriptor destination, or nil for "do not move"
function model.ResolveMove(itemID, fromWarband)
    local destination, owners = model.Resolve(itemID)

    if destination == enum.DESTINATION.PRIVATE then
        if model.IsMine(owners) then
            return enum.DESTINATION.PRIVATE
        end

        -- A non-owner still moves it somewhere an owner can reach. From the
        -- warband bank it already is there, so there is nothing left to do.
        if fromWarband then return nil end

        return enum.DESTINATION.WARBAND
    end

    if fromWarband then return nil end

    if destination == enum.DESTINATION.WARBAND then
        return enum.DESTINATION.WARBAND
    end

    return nil
end

--- Records the destination the user picked for an item in the curation window.
---
--- Stores an override only when the choice differs from what the rules would
--- have produced; picking the rule's own answer clears the override instead.
--- overrides has no per-itemID default, so the core's logout prune -- which
--- removes only values matching a default -- can never match an individual
--- entry once written. An override that restated a rule would therefore sit in
--- SavedVariables forever and freeze that item against any later rule change,
--- which is exactly the staleness this module is built not to accumulate.
---
--- Private is the exception on both counts: no rule produces it, so it is
--- always stored, and re-picking it preserves the owner set rather than
--- resetting a careful assignment back to first-come.
---@param itemID number
---@param destination string  an enum.DESTINATION value
function model.SetDestination(itemID, destination)
    if destination == enum.DESTINATION.PRIVATE then
        local existing = db.global.overrides[itemID]
        if type(existing) == "table" and existing.dest == enum.DESTINATION.PRIVATE then
            return
        end

        db.global.overrides[itemID] = {
            dest   = enum.DESTINATION.PRIVATE,
            owners = {},
        }
        return
    end

    if destination == model.ResolveByRule(itemID) then
        db.global.overrides[itemID] = nil
    else
        db.global.overrides[itemID] = destination
    end
end

-- =========================================================
-- private owners and targets
-- =========================================================

--- A private override's owner set, or nil when the item is not private.
---@param itemID number
---@return table|nil
local function privateOwners(itemID)
    local override = db.global.overrides[itemID]
    if type(override) ~= "table" or override.dest ~= enum.DESTINATION.PRIVATE then
        return nil
    end

    return override.owners
end

---@param itemID number
---@param charKey string
---@return boolean
function model.IsOwner(itemID, charKey)
    local owners = privateOwners(itemID)
    return owners ~= nil and owners[charKey] == true
end

--- Adds or removes one owner, and prunes owners the account no longer knows.
---
--- Pruning happens on write rather than on read, so IsMine stays pure over its
--- argument and the tests can hand it a literal. A set emptied by pruning
--- reverts to first-come, which keeps the item moving instead of stranding it.
---@param itemID number
---@param charKey string
function model.ToggleOwner(itemID, charKey)
    local owners = privateOwners(itemID)
    if not owners then return end

    owners[charKey] = not owners[charKey] or nil

    local known = {}
    for _, key in ipairs(BitForge:GetKnownCharacters()) do
        known[key] = true
    end

    for key in pairs(owners) do
        if not known[key] then owners[key] = nil end
    end
end

--- The owners of a private item, sorted, or an empty array.
---
--- Sorted so a curation row's text is stable across rebuilds: a set has no
--- order, and a row that reshuffled its owner names on every refresh would read
--- as changing when nothing had.
---@param itemID number
---@return table  array of charKey
function model.GetOwners(itemID)
    local list = {}

    local owners = privateOwners(itemID)
    if owners then
        for charKey in pairs(owners) do
            list[#list + 1] = charKey
        end
        sort(list)
    end

    return list
end

--- Whether any private override exists at all.
---
--- The reclaim pass reads every purchased warband tab, which is the most
--- expensive read the module performs. This is the gate that skips it, and it
--- is false for every profile until the user curates a private item.
---@return boolean
function model.HasPrivateOverrides()
    for _, override in pairs(db.global.overrides) do
        if type(override) == "table" and override.dest == enum.DESTINATION.PRIVATE then
            return true
        end
    end

    return false
end

--- The per-owner target quantity for a private item, or nil for "take it all".
---@param itemID number
---@return number|nil
function model.GetTarget(itemID)
    local override = db.global.overrides[itemID]
    if type(override) ~= "table" or override.dest ~= enum.DESTINATION.PRIVATE then
        return nil
    end

    return override.target
end

--- Sets or clears the per-owner target quantity.
---
--- Ignored for a non-private item: a target is a rule about how much of a
--- shared stack one owner may claim, and nothing else in the module produces a
--- shared stack with owners.
---@param itemID number
---@param target number|nil
function model.SetTarget(itemID, target)
    local override = db.global.overrides[itemID]
    if type(override) ~= "table" or override.dest ~= enum.DESTINATION.PRIVATE then
        return
    end

    override.target = target
end

-- =========================================================
-- curation
-- =========================================================

--- One curation row for one owned item.
---@param itemID number
---@param holders table  { [charKey] = count }
---@return table row
local function buildCurationRow(itemID, holders)
    -- Returns 2, 3, 5 and 6 of 7 (ItemDocumentation.lua:647-656). itemType and
    -- itemSubType are the client's own localized class names, so the window
    -- never has to map a classID onto a string of its own.
    local _, typeName, subTypeName, _, icon, classID = C_Item.GetItemInfoInstant(itemID)

    local sortedHolders = {}
    local total = 0

    for charKey, count in pairs(holders) do
        sortedHolders[#sortedHolders + 1] = { charKey = charKey, count = count }
        total = total + count
    end

    sort(sortedHolders, function(left, right) return left.charKey < right.charKey end)

    return {
        itemID = itemID,
        -- An item the client has not cached yet has no name. Falling back to the
        -- ID keeps the row in the list: dropping it would silently shrink the
        -- very list the user is curating against, and the row is still usable --
        -- its icon, class and destination all resolve.
        name        = C_Item.GetItemNameByID(itemID) or tostring(itemID),
        icon        = icon,
        classID     = classID,
        className   = typeName,
        subTypeName = subTypeName,
        destination = model.Resolve(itemID),
        -- The destination alone cannot answer "did I already decide this one?",
        -- because a chosen warband and a rule-produced warband read identically.
        isOverride  = db.global.overrides[itemID] ~= nil,
        -- Who may claim this item, as opposed to holders, which is who happens
        -- to be carrying it. Empty for everything that is not private.
        owners      = model.GetOwners(itemID),
        target      = model.GetTarget(itemID),
        holders     = sortedHolders,
        total       = total,
    }
end

---@param row table
---@param filters table|nil
---@return boolean
local function matchesFilters(row, filters)
    if not filters then return true end

    if filters.destination and row.destination ~= filters.destination then
        return false
    end

    if filters.classID and row.classID ~= filters.classID then
        return false
    end

    if filters.search and filters.search ~= "" then
        -- Plain find rather than a pattern match: item names are full of
        -- hyphens, parentheses and percent signs, and searching for one as a
        -- pattern either errors or matches the wrong rows.
        if not find(lower(row.name), lower(filters.search), 1, true) then
            return false
        end
    end

    return true
end

--- The curation window's row list.
---
--- Pure over the owned table an adapter produced plus synchronous item lookups,
--- so the whole of the window's ordering, filtering and destination resolution
--- is testable without a client. The view decorates rows with textures and
--- decides nothing.
---@param owned table         { [itemID] = { [charKey] = count } }
---@param filters table|nil   { destination = string|nil, classID = number|nil, search = string|nil }
---@return table rows         sorted by name, then itemID
function model.BuildCurationRows(owned, filters)
    local rows = {}

    for itemID, holders in pairs(owned) do
        local row = buildCurationRow(itemID, holders)
        if matchesFilters(row, filters) then
            rows[#rows + 1] = row
        end
    end

    -- itemID breaks the tie so the order is stable across rebuilds; two items
    -- sharing a name would otherwise swap places on every refresh.
    sort(rows, function(left, right)
        if left.name == right.name then
            return left.itemID < right.itemID
        end
        return left.name < right.name
    end)

    return rows
end

--- The distinct item classes present in an owned table, for the class filter.
---
--- Derived from what the user actually holds rather than from Enum.ItemClass:
--- a filter listing thirteen classes when the account owns items in three is a
--- list of dead ends.
---@param owned table  { [itemID] = { [charKey] = count } }
---@return table  { { classID = number, name = string }, ... } sorted by name
function model.GetOwnedClasses(owned)
    local seen = {}
    local classes = {}

    for itemID in pairs(owned) do
        -- Returns 2 and 6 of 7. itemType is the client's own localized class
        -- name, which is what the filter's option list shows.
        local _, typeName, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)

        if classID and typeName and not seen[classID] then
            seen[classID] = true
            classes[#classes + 1] = { classID = classID, name = typeName }
        end
    end

    sort(classes, function(left, right) return left.name < right.name end)

    return classes
end

--- Characters that hold a profession but have never had a recipe scan.
---
--- "Never scanned" is the absence of any scan stamp rather than a per-profession
--- check: professions are stored as Enum.Profession values and scans are stamped
--- by skillLineID, and nothing maps one onto the other without a loaded trade
--- skill line -- which is precisely what an unscanned character does not have. A
--- character with one profession scanned and a second never opened therefore
--- reads as scanned. That understates the warning rather than crying wolf, which
--- is the right direction for a banner nobody can act on twice.
---@return table  array of charKey, sorted
function model.GetUnscannedCharacters()
    local unscanned = {}

    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        local professions = db.global.professions[charKey]

        if professions and #professions > 0 and not model.HasAnyRecipeScan(charKey) then
            unscanned[#unscanned + 1] = charKey
        end
    end

    sort(unscanned)

    return unscanned
end

-- =========================================================
-- planner
-- =========================================================

--- Turns inventory snapshots into an ordered list of move descriptors.
---
--- Pure: it reads the snapshots and the override table and calls no container
--- API, which is what lets the preview dialog render the result and the tests
--- exercise it headlessly. Descriptors carry no destination slot -- the
--- executor resolves one immediately before each move, because a slot chosen
--- at plan time is stale by the second move.
---
--- Both passes emit the same descriptor shape and share one queue: the deposit
--- pass reads the carried bags, and the reclaim pass reads the warband tabs to
--- bring privately-owned items home. fromWarband records which question
--- ResolveMove was asked, so the executor can ask the same one again.
---@param bagSnapshot table          { { bag, slot, itemID, count }, ... }
---@param warbandSnapshot table|nil  the same, from the warband tabs; nil skips the reclaim pass
---@param holdings table|nil         { [itemID] = count } the current character already has
---@return table plan                { { srcBag, srcSlot, itemID, count, destination, fromWarband }, ... }
function model.PlanMoves(bagSnapshot, warbandSnapshot, holdings)
    local plan = {}

    local function add(entry, destination, fromWarband, count)
        plan[#plan + 1] = {
            srcBag      = entry.bag,
            srcSlot     = entry.slot,
            itemID      = entry.itemID,
            count       = count,
            destination = destination,
            fromWarband = fromWarband,
        }
    end

    for _, entry in ipairs(bagSnapshot or {}) do
        local destination = model.ResolveMove(entry.itemID, false)
        if destination then
            add(entry, destination, false, entry.count)
        end
    end

    -- Claimed across the whole reclaim pass rather than per stack: a target is
    -- a quantity the character should end up holding, so two stacks of the same
    -- item in the warband bank fill it once between them rather than twice each.
    local claimed = {}

    for _, entry in ipairs(warbandSnapshot or {}) do
        local destination = model.ResolveMove(entry.itemID, true)

        if destination then
            local count = entry.count
            local target = model.GetTarget(entry.itemID)

            if target then
                local have = (holdings and holdings[entry.itemID] or 0)
                    + (claimed[entry.itemID] or 0)
                local shortfall = target - have

                if shortfall < count then count = shortfall end
            end

            if count > 0 then
                claimed[entry.itemID] = (claimed[entry.itemID] or 0) + count
                add(entry, destination, true, count)
            end
        end
    end

    return plan
end

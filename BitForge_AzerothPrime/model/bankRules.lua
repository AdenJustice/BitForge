---@class BitForge.AzerothPrime
local ns = select(2, ...)

local select = select
local ipairs = ipairs
local pairs = pairs
local C_Item = C_Item
local find = string.find
local lower = string.lower
local band = bit.band
local sort = table.sort

---@class BitForge.AzerothPrime.Model
local model = ns.model
---@type BitForge.AzerothPrime.Enum
local enum = ns.enum

---@class BitForge.AzerothPrime.Model.BankRules
local bankRules = {}

--- The name this file registers its claimant under, stated once, the same way
--- model/openRules.lua and model/rules.lua state their own. Read back by
--- control/deposit.lua, which asks this one claimant alone before deciding
--- whether a carried-bag slot is worth a full model.arbiter.Resolve.
bankRules.CLAIMANT = "bank"

--- Whether some character other than this one wants this recipe.
---
--- "Wants" is: holds the profession the recipe belongs to, and has no record of
--- having learned it. The current character is excluded because a recipe in
--- their own bags is already where they can learn it -- moving it to shared
--- storage would only add a round trip.
---
--- A character with the profession but no recipe scan has no records at all, so
--- every recipe for that profession reads as wanted. That is the design (#55) 5.5
--- bias, and it is deliberate in this direction: over-depositing costs a bank
--- slot until the recipe is vendored, where the opposite error strands a recipe
--- an alt needs in the wrong character's bags.
---@param subClassID number|nil  GetItemInfoInstant return 7 of 7
---@param itemID number
---@return boolean
function bankRules.WantedByAlt(subClassID, itemID)
    local profession = subClassID and enum.RECIPE_PROFESSION[subClassID]
    if not profession then return false end

    -- Whether this is the recipe's own spellID or a separate teaching spell
    -- is unconfirmed in a live client -- see the design (#55) 5.6. If it is
    -- a teaching spell the lookup below never matches and the rule degrades
    -- to "any alt with the profession", which is the same safe direction as
    -- an unscanned alt.
    --
    -- Read through a record for one reason only: the question is stated in
    -- one place. It buys nothing else here. GetPartial deliberately neither
    -- reads nor writes model.facts' record cache (its own comment says why),
    -- so this allocates a fresh record and its __computed table per call and
    -- pays for C_Item.GetItemSpell again each time, exactly as the direct call
    -- it replaced did.
    local spellID = model.facts.GetPartial(nil, nil, itemID).recipeSpellID
    if not spellID then return false end

    local debugNotices = model.debugNotices
    if debugNotices then debugNotices.RecipeSpellObserved(itemID, spellID) end

    local current = BitForge:GetCurrentCharacter()

    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        if charKey ~= current
            and BitForge:HasProfession(charKey, profession)
            and not model.IsRecipeKnown(charKey, spellID) then
            return true
        end
    end

    return false
end

--- Where the rules alone would put an item, ignoring every override.
---
--- Split out of Resolve so the curation window can distinguish a destination the
--- user chose from one the rules produced, and so SetDestination can decline to
--- store a choice that only restates a rule.
---@param itemID number
---@return string destination  an enum.DESTINATION value
function bankRules.ResolveByRule(itemID)
    -- classID/subClassID stay a direct client call rather than a record
    -- field. This function is called with a bare itemID from curation rows
    -- that span other characters' bags and bank tabs alongside this one's --
    -- there is often no live bag:slot to key a record by at all. Even where
    -- one exists, GetPartial's itemID-only record would not help: classID
    -- and subclassID are set in Get's GetItemInfo-resolved sell layer, never
    -- on GetPartial's bare skeleton -- so a record read here would silently
    -- answer nil for every item instead of classifying any of them.
    --
    -- Returns 6 and 7 of 7. select() past the end of the list yields nothing
    -- rather than erroring, so an item with no client data leaves both nil.
    local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))

    if classID then
        if enum.REAGENT_CLASSES[classID] then
            -- The class says "this is a reagent"; the catalogue says whether
            -- anyone on the account can craft with it. nil is NOT KNOWN, and an
            -- unknown reagent is deposited rather than left behind -- the same
            -- outcome as before the catalogue existed.
            if not model.GetOnlyWantedReagents() then
                return enum.DESTINATION.WARBAND
            end

            -- Read through the record's own field rather than the catalogue
            -- directly, for the reason WantedByAlt's own read above gives:
            -- reagentProfessions states the GetReagentProfessions question
            -- once, and this asks the same one. The sell path's records do not
            -- pay for this one -- GetPartial shares nothing with them, so the
            -- catalogue is asked again on every call here.
            local professions = model.facts.GetPartial(nil, nil, itemID).reagentProfessions
            if not professions
                or band(professions, BitForge:GetAccountProfessions()) ~= 0 then
                return enum.DESTINATION.WARBAND
            end
        end

        if classID == Enum.ItemClass.Recipe and bankRules.WantedByAlt(subClassID, itemID) then
            return enum.DESTINATION.WARBAND
        end
    end

    return enum.DESTINATION.IGNORE
end

--- A private item's owners in the shape IsMine reads them.
---
--- model/overrides.lua stores them sorted and hands out no reference to the
--- record behind them, so nothing outside its own setters can write the store
--- and skip the invalidation it performs. Rebuilding a set here is what that
--- costs, and it is paid only for a private destination -- the only one
--- owners and a target mean anything for, which SetDestination below is what
--- keeps true.
---@param itemID number
---@return table  charKey -> true
local function ownerSet(itemID)
    local owners = {}

    for _, charKey in ipairs(model.overrides.GetOwners(itemID)) do
        owners[charKey] = true
    end

    return owners
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
function bankRules.Resolve(itemID)
    local destination = model.overrides.GetBank(itemID)

    if destination == enum.DESTINATION.PRIVATE then
        ---@cast destination string
        return destination, ownerSet(itemID), model.overrides.GetTarget(itemID)
    end

    if destination then
        return destination
    end

    return bankRules.ResolveByRule(itemID)
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
function bankRules.IsMine(owners)
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
function bankRules.SetDestination(itemID, destination)
    local overrides = model.overrides

    if destination == enum.DESTINATION.PRIVATE then
        if overrides.GetBank(itemID) == enum.DESTINATION.PRIVATE then
            return
        end

        overrides.SetBank(itemID, enum.DESTINATION.PRIVATE)
        return
    end

    -- Cleared by hand, where the store this path left behind dropped them
    -- along with the whole entry it replaced. A merged record addresses every
    -- field on its own, so writing `bank` alone would strand an owner set on
    -- an item nobody may own, and clearing `bank` alone would leave a record
    -- standing that holds no override at all.
    overrides.ClearOwners(itemID)
    overrides.SetTarget(itemID, nil)

    if destination == bankRules.ResolveByRule(itemID) then
        overrides.SetBank(itemID, nil)
    else
        overrides.SetBank(itemID, destination)
    end
end

--- Drops every bank opinion an item carries, whatever it held.
---
--- The curation window's "reset to default", phrased as picking the rule's
--- own answer rather than as clearing three fields: the invariant that owners
--- and a target exist only under a private destination then stays in
--- SetDestination alone, instead of being restated at a second call site the
--- way the store this replaced allowed. No rule produces PRIVATE, so this
--- always takes the branch above that clears.
---@param itemID number
function bankRules.ClearDestination(itemID)
    bankRules.SetDestination(itemID, bankRules.ResolveByRule(itemID))
end

--- Where one stack goes from where it currently is, or nil to leave it alone.
---
--- The design (#55) 6.4 table in executable form, and the only place it exists. The
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
function bankRules.ResolveMove(itemID, fromWarband)
    local destination, owners = bankRules.Resolve(itemID)

    if destination == enum.DESTINATION.PRIVATE then
        if bankRules.IsMine(owners) then
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

--- One curation row for one owned item.
---@param itemID number
---@param holders table  { [charKey] = count }
---@return table row
local function buildCurationRow(itemID, holders)
    -- Returns 2, 3, 5 and 6 of 7 (ItemDocumentation.lua). itemType and
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
        destination = bankRules.Resolve(itemID),
        -- The destination alone cannot answer "did I already decide this one?",
        -- because a chosen warband and a rule-produced warband read
        -- identically. The `bank` field rather than the record: one item's
        -- record can hold a sell or an open opinion and no bank one at all.
        isOverride  = model.overrides.GetBank(itemID) ~= nil,
        -- Who may claim this item, as opposed to holders, which is who happens
        -- to be carrying it. Empty for everything that is not private.
        owners      = model.overrides.GetOwners(itemID),
        target      = model.overrides.GetTarget(itemID),
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
function bankRules.BuildCurationRows(owned, filters)
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
function bankRules.GetOwnedClasses(owned)
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
function bankRules.GetUnscannedCharacters()
    local unscanned = {}

    for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
        local professions = BitForge:GetCharacterProfessions(charKey)

        if professions and #professions > 0 and not model.HasAnyRecipeScan(charKey) then
            unscanned[#unscanned + 1] = charKey
        end
    end

    sort(unscanned)

    return unscanned
end

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
function bankRules.PlanMoves(bagSnapshot, warbandSnapshot, holdings)
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
        local destination = bankRules.ResolveMove(entry.itemID, false)
        if destination then
            add(entry, destination, false, entry.count)
        end
    end

    -- Claimed across the whole reclaim pass rather than per stack: a target is
    -- a quantity the character should end up holding, so two stacks of the same
    -- item in the warband bank fill it once between them rather than twice each.
    local claimed = {}

    for _, entry in ipairs(warbandSnapshot or {}) do
        local destination = bankRules.ResolveMove(entry.itemID, true)

        if destination then
            local count = entry.count
            local target = model.overrides.GetTarget(entry.itemID)

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

-- Deposit claims have no ladder of their own, unlike OPEN's five-tier
-- enum.PRIORITY -- WARBAND and PRIVATE share one FIXED_ORDER tier in
-- model/arbiter.lua (bankRules never claims both for the same item), so
-- nothing here ranks one claim over another. Not borrowed from enum.PRIORITY:
-- those tiers are the open path's own and are printed into player-visible
-- curation-review text, so reusing one would tie this path's strength to a
-- renumbering that has nothing to do with it. Mirrors rules.lua's
-- SELL_STRENGTH.
local DEPOSIT_STRENGTH = 1

-- enum.DESTINATION.IGNORE is deliberately absent: it is this path saying it
-- has no opinion, not a claim to leave the item alone. Mapping it to a claim
-- would make the bank path outrank sell for every item it does not care
-- about. A lookup miss therefore reads as nil -- an abstention -- by
-- construction, which is also what a fourth DESTINATION member would get
-- until someone decided it should claim.
--
-- Not the same job as rules.lua's OVERRIDE_RULE, which looks similar: that
-- one IS the `overridden` return, while this one is the `claim` return and
-- `overridden` is derived separately below from whether a stored override
-- exists at all.
local CLAIM_FOR_DESTINATION = {
    [enum.DESTINATION.WARBAND] = enum.CLAIM.DEPOSIT_WARBAND,
    [enum.DESTINATION.PRIVATE] = enum.CLAIM.DEPOSIT_PRIVATE,
}

--- The bank claimant.
---
--- Wraps ResolveByRule, not Resolve: the arbiter ranks a promoting override
--- ahead of the whole fixed order (model/arbiter.lua's rank()), so this has to
--- tell Resolve *which* claims are that override rather than handing back an
--- already-blended answer with no way to tell the two apart. The stored
--- override is read separately, through model.overrides.GetBank, and decides
--- the destination itself whenever it exists -- not just the `overridden`
--- flag -- because PRIVATE has no rule of its own to fall back to
--- (ResolveByRule never returns it; bankRules.SetDestination's own comment
--- says why) and an explicit WARBAND/IGNORE override must be able to disagree
--- with the rule.
---@param facts table  a model.facts record, or an equivalent plain table
---@return string|nil claim       enum.CLAIM.DEPOSIT_WARBAND/DEPOSIT_PRIVATE, or nil to abstain
---@return number|nil strength    DEPOSIT_STRENGTH when claiming, else nil
---@return string|nil reason      the enum.DESTINATION value the claim came from
---@return boolean|nil overridden true when a stored override supplied the destination
function bankRules.Claim(facts)
    local itemID = facts.itemID
    local stored = model.overrides.GetBank(itemID)
    local overridden = stored ~= nil or nil
    local destination = stored or bankRules.ResolveByRule(itemID)

    local claim = CLAIM_FOR_DESTINATION[destination]
    if not claim then
        return nil, nil, destination, overridden
    end

    return claim, DEPOSIT_STRENGTH, destination, overridden
end

model.bankRules = bankRules

-- The third and last of the three claimants (spec #331 section 3), registered
-- after the publication above and never before, for the reason
-- model/openRules.lua's own registration gives.
model.arbiter.Register(bankRules.CLAIMANT, bankRules.Claim)

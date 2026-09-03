---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs
local next = next
local pairs = pairs
local sort = table.sort

---@type BitForge.Dispatch.Enum
local enum = ns.enum
local GLOBAL = enum.LIST_SCOPE.GLOBAL

-- `sell` is the one field with two scopes, so it is the one field a query can
-- span them. Hoisted rather than built per call, and ordered the way
-- GetSellEntries sorts, so the two cannot drift.
local SELL_SCOPES = { enum.LIST_SCOPE.CHAR, enum.LIST_SCOPE.GLOBAL }

---@class BitForge.Dispatch.Model
local model = ns.model

--- The merged store for a player's opinion about one item (spec #331 section
--- 5, plan #368): what three separate stores -- Openables' blacklist,
--- BatchSell's sell lists, UPS's bank destinations -- became. Schema step 3
--- dropped all three; this is the only place an override is kept now.
---
--- One record per itemID, every field optional:
---
---   itemOverrides[itemID] = {
---       open   = false,                            -- nil = no opinion, false = never offer, true = always
---       sell   = "blacklist"|"whitelist"|nil,       -- enum.LIST_STATUS, by value
---       bank   = "warband"|"private"|"ignore"|nil,  -- enum.DESTINATION, by value
---       owners = { [charKey] = true },              -- private destinations only
---       target = number|nil,
---   }
---
--- Two scopes, db.global.itemOverrides and db.char.itemOverrides, and only
--- `sell` carries a character scope: the other two stores had one scope each
--- before this merge and gain nothing from a second, and section 5 preserves
--- scopes rather than unifying them. A char.itemOverrides[itemID] entry
--- therefore carries `sell` and nothing else -- structurally, not just by
--- convention: every accessor for `open`, `bank`, `owners` and `target` below
--- reaches only the global store, and there is no path from this file that
--- writes any of them into db.char.
---
--- This is deliberately a pure data store. It has no opinion about whether a
--- `target` makes sense without a `bank == PRIVATE`, or whether `owners`
--- matters when `bank` is not set -- each field has its own address in one
--- flat record, and nothing here gates one field's write on another's value.
--- That question belongs to whichever claimant reads the field, and all three
--- read it now: model/openRules.lua takes `open`, model/facts.lua takes
--- `sell`, model/bankRules.lua takes `bank`, `owners` and `target`. The last
--- is where the rule this file declines to hold ended up -- `owners` and
--- `target` are meaningful only under `bank == PRIVATE`, and
--- bankRules.SetDestination is what keeps that true, clearing both whenever it
--- leaves a private destination. Nothing here enforces it: a setter below will
--- write a target onto an item that has no `bank` field at all.
---
--- Invalidation is uniform and belongs to SetField alone. Never reason it per
--- call site against what a claimant happens to read today -- that is how a
--- setter goes stale by omission, which is the constraint spec #331 states for
--- this store. The price is one redundant generation turnover on a rare manual
--- gesture (toggling an owner, typing a target in the curation window).
---@class BitForge.Dispatch.Model.Overrides
local overrides = {}

--- Captured once and revoked immediately, which is what turns "one write path"
--- from a comment into a fact: any later file reaching for
--- model.GetOverrideStore raises "attempt to call a nil value" rather than
--- silently reading or writing db.itemOverrides around this file's
--- invalidation. See model.lua's own comment for why .toc order makes this
--- file the sole reader.
---@type fun(scope: string): table<number, table>
local GetOverrideStore = model.GetOverrideStore
model.GetOverrideStore = nil

--- Writes one field of one item's record: creates the record on its first
--- write, and drops it once its last field is cleared, so an item nobody has
--- ever set never appears to db.itemOverrides -- neither the collection's
--- own default (which must stay {}, see model.lua) nor the logout prune ever
--- has a per-item shape to walk into.
---
--- The one place this file turns the fact generation over. Every public
--- setter below ends here, ToggleOwner included through its own owners
--- write, so nothing in this file can mutate the store without invalidating.
---@param store  table   itemID -> record, from GetOverrideStore above
---@param itemID number
---@param key    string  "open"|"sell"|"bank"|"owners"|"target"
---@param value  any     nil clears the field
local function SetField(store, itemID, key, value)
    local record = store[itemID]
    if value == nil then
        if record then
            record[key] = nil
            if not next(record) then store[itemID] = nil end
        end
    else
        record = record or {}
        record[key] = value
        store[itemID] = record
    end

    model.facts.Invalidate()
end

--- @param itemID number
--- @return boolean|nil  nil = no opinion, false = never offer, true = always
function overrides.GetOpen(itemID)
    local record = GetOverrideStore(GLOBAL)[itemID]
    return record and record.open
end

--- @param itemID number
--- @param value  boolean|nil  nil clears the opinion
function overrides.SetOpen(itemID, value)
    SetField(GetOverrideStore(GLOBAL), itemID, "open", value)
end

--- Every item carrying one open opinion, sorted ascending.
---
--- Sorted for the reason GetOwners below is: a set has no order, and the
--- blacklist window draws one row per itemID.
---
--- By value rather than "every item with an `open` field", because the window
--- reading it lists one opinion -- false, never offer -- and the field can
--- hold the other. ClearAllOpen takes the same argument for the same reason,
--- which is what makes the list a window draws and the list its Clear All
--- empties the same set by construction rather than by agreement.
---@param value boolean  the opinion to collect
---@return table  array of itemID
function overrides.GetOpenItems(value)
    local list = {}

    for itemID, record in pairs(GetOverrideStore(GLOBAL)) do
        if record.open == value then
            list[#list + 1] = itemID
        end
    end
    sort(list)

    return list
end

--- Clears one open opinion from every item carrying it.
---
--- Field by field through SetField rather than a wipe, and that is the whole
--- of it: `open` is one of five fields on a shared record, so an item that
--- also carries a `sell` or a `bank` opinion keeps it -- a mistake the three
--- separate stores this merged could not express and this one can.
---
--- SetField is also what turns the generation over: without it Clear All
--- empties the list and the button still shows nothing, every verdict
--- memoised before the clear having recorded the suppression.
---@param value boolean  the opinion to clear
function overrides.ClearAllOpen(value)
    -- nil is the absence of an opinion rather than a wildcard for one, and an
    -- item carrying no `open` opinion has nothing here to clear. Without this
    -- every such record matches, is written back to the nil it already holds,
    -- and turns the generation over once each for no change at all.
    if value == nil then return end

    local store = GetOverrideStore(GLOBAL)

    for _, itemID in ipairs(overrides.GetOpenItems(value)) do
        SetField(store, itemID, "open", nil)
    end
end

--- @param itemID number
--- @param scope  string  enum.LIST_SCOPE value
--- @return string|nil  enum.LIST_STATUS value, or nil when unset
function overrides.GetSell(itemID, scope)
    local record = GetOverrideStore(scope)[itemID]
    return record and record.sell
end

--- @param itemID number
--- @param scope  string      enum.LIST_SCOPE value
--- @param status string|nil  enum.LIST_STATUS value; nil clears it
function overrides.SetSell(itemID, scope, status)
    SetField(GetOverrideStore(scope), itemID, "sell", status)
end

--- Every entry of one sell status, across both scopes.
---
--- One entry per scope per item rather than a merged view: an item listed in
--- both is two entries, because each is independently removable and that is
--- what having two scopes means. model.facts.EffectiveSell answers the other
--- question -- which of the two governs.
---
--- Sorted by scope then itemID so a list tab's order survives a refresh.
--- Sorting by name would read better and cannot be relied on: an entry is an
--- itemID, and an item the client has never loaded has no name yet.
---@param status string  enum.LIST_STATUS value
---@return table  array of { itemID = number, scope = string }
function overrides.GetSellEntries(status)
    local entries = {}

    for _, scope in ipairs(SELL_SCOPES) do
        for itemID, record in pairs(GetOverrideStore(scope)) do
            if record.sell == status then
                entries[#entries + 1] = { itemID = itemID, scope = scope }
            end
        end
    end

    sort(entries, function(left, right)
        if left.scope ~= right.scope then return left.scope < right.scope end
        return left.itemID < right.itemID
    end)

    return entries
end

--- Clears one sell status from one scope.
---
--- Scoped both ways on purpose. The other scope is a different list the
--- player did not ask to reset, and within this scope the field holds either
--- status -- so clearing every record's `sell` here would empty the whitelist
--- from the blacklist's own reset button. Per item through SetField for the
--- reasons ClearAllOpen above gives.
---@param scope  string  enum.LIST_SCOPE value
---@param status string  enum.LIST_STATUS value
function overrides.ClearAllSell(scope, status)
    -- The same non-value as ClearAllOpen's above, refused the same way: the two
    -- clears differing on what nil means would be the surprise.
    if status == nil then return end

    local store = GetOverrideStore(scope)
    local matched = {}

    for itemID, record in pairs(store) do
        if record.sell == status then
            matched[#matched + 1] = itemID
        end
    end

    for _, itemID in ipairs(matched) do
        SetField(store, itemID, "sell", nil)
    end
end

--- @param itemID number
--- @return string|nil  enum.DESTINATION value, or nil when unset
function overrides.GetBank(itemID)
    local record = GetOverrideStore(GLOBAL)[itemID]
    return record and record.bank
end

--- @param itemID number
--- @param destination string|nil  enum.DESTINATION value; nil clears it
function overrides.SetBank(itemID, destination)
    SetField(GetOverrideStore(GLOBAL), itemID, "bank", destination)
end

--- Whether any item's record carries this destination.
---
--- The one question in this file that spans records instead of answering for
--- one item, and it is here because it has to be asked before any itemID
--- exists to ask about: model.HasPrivateOverrides gates the reclaim pass,
--- which reads every purchased warband tab and is the most expensive thing
--- the module does. Parameterised rather than named for private, because what
--- a destination means is the reading claimant's question and not this
--- store's.
---@param destination string  enum.DESTINATION value
---@return boolean
function overrides.AnyBank(destination)
    for _, record in pairs(GetOverrideStore(GLOBAL)) do
        if record.bank == destination then return true end
    end

    return false
end

--- @param itemID number
--- @return number|nil
function overrides.GetTarget(itemID)
    local record = GetOverrideStore(GLOBAL)[itemID]
    return record and record.target
end

--- @param itemID number
--- @param target number|nil  nil clears it
function overrides.SetTarget(itemID, target)
    SetField(GetOverrideStore(GLOBAL), itemID, "target", target)
end

---@param itemID number
---@return table|nil  charKey -> true
local function ownerSet(itemID)
    local record = GetOverrideStore(GLOBAL)[itemID]
    return record and record.owners
end

--- The owners of a private item, sorted, or an empty array.
---
--- Sorted so a curation row's text is stable across rebuilds: a set has no
--- order, and a row that reshuffled its owner names on every refresh would
--- read as changing when nothing had.
---@param itemID number
---@return table  array of charKey
function overrides.GetOwners(itemID)
    local list = {}

    local owners = ownerSet(itemID)
    if owners then
        for charKey in pairs(owners) do
            list[#list + 1] = charKey
        end
        sort(list)
    end

    return list
end

--- Replaces an item's whole owner set, or clears it.
---
--- The field's only wholesale writer, and a file local rather than a public
--- setter because it is the one accessor here that takes a table: it stores
--- the table by reference, so a caller outside this file would keep a live
--- handle on the store and could write the field afterwards without SetField
--- ever running -- the single write path defeated by the one setter that
--- hands out the address. Nothing this file publishes takes a table, so there
--- is no such handle to keep. ToggleOwner is the only caller that passes one,
--- and the table it passes is the stored one already.
---@param itemID number
---@param owners table|nil  charKey -> true; nil clears the set
local function SetOwners(itemID, owners)
    SetField(GetOverrideStore(GLOBAL), itemID, "owners", owners)
end

--- Drops an item's owner set.
---
--- The published half of SetOwners above, and the only half anything outside
--- needs: model/bankRules.lua's SetDestination clears the set when it leaves
--- a private destination -- the store it replaced dropped the owners with the
--- whole entry, and a merged record addresses each field on its own. Adding
--- and removing one owner is ToggleOwner's job.
---@param itemID number
function overrides.ClearOwners(itemID)
    SetOwners(itemID, nil)
end

---@param itemID number
---@param charKey string
---@return boolean
function overrides.IsOwner(itemID, charKey)
    local owners = ownerSet(itemID)
    return owners ~= nil and owners[charKey] == true
end

--- Adds or removes one owner, and prunes owners the account no longer knows
--- -- the discipline the store this replaced applied, kept rather than
--- relaxed on the move: an owner set is only ever meaningful for characters
--- that still exist, whatever reads it.
---
--- Pruning happens on write rather than on read, so IsOwner stays pure over
--- its argument and a test can hand it a literal. A set emptied by pruning
--- reverts to first-come, which keeps the item moving instead of stranding
--- it.
---@param itemID number
---@param charKey string
function overrides.ToggleOwner(itemID, charKey)
    local owners = ownerSet(itemID) or {}

    owners[charKey] = not owners[charKey] or nil

    local known = {}
    for _, key in ipairs(BitForge:GetKnownCharacters()) do
        known[key] = true
    end
    for key in pairs(owners) do
        if not known[key] then owners[key] = nil end
    end

    SetOwners(itemID, next(owners) and owners or nil)
end

model.overrides = overrides

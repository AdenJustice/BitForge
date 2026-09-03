---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs
local pairs = pairs
local pcall = pcall
local sort = table.sort
local type = type

-- Enum.CraftingReagentType is Modifying = 0, Basic = 1, Finishing = 2,
-- Automatic = 3 (ProfessionConstantsDocumentation.lua). Only Basic is ever
-- collected: a Modifying or Finishing reagent buys quality or an extra
-- effect and the craft happens without it, so sparing one would keep more
-- than flagging the recipe asked for -- and keeping less is what this feature
-- is for. Automatic falls out with them for a different reason: no file in
-- wow-ui-source's addon tree names it, so nothing says a slot of that type
-- ever reaches an item a player could sell.
local BASIC = Enum.CraftingReagentType.Basic

---@class BitForge.Dispatch.Model
local model = ns.model

--- The recipes a player says they actually craft (spec #379), and the reagent
--- lookup the sell scan needs from them.
---
--- The flag is ours -- db.global.sparedRecipes[recipeID] = true, and nothing
--- ever stores false. Deliberately not the game's own favourite or tracked
--- lists: both already mean something to the player, and tracking in
--- particular is a shopping list that goes on and off around every craft, so
--- hanging sell behaviour on it would change what BitForge sells every time a
--- player finished something.
---
--- The index is the other half, and it is a cache rather than a store: the
--- sell scan starts from an item ID in a bag and asks whether anything wants
--- it, so it needs reagent -> flagged, which is the inverse of what the flags
--- record. Held in memory only and re-derived from the flags, so a patch that
--- swaps one material for another self-corrects at the next login with no
--- migration and nothing stale to clean up. It is a set keyed by item ID and
--- not a count: two flagged recipes sharing a reagent name it once, and
--- unflagging one of them must leave it named.
---
--- One write path -- Toggle -- and it is what rebuilds the index and turns the
--- fact generation over, the discipline model/overrides.lua states for its own
--- store. Do not add a second setter, and do not publish a name that takes the
--- store or the index as an argument: a caller holding either table could write
--- it afterwards with none of this running.
---@class BitForge.Dispatch.Model.SparedRecipes
local sparedRecipes = {}

--- Captured once and revoked immediately, exactly as model/overrides.lua does
--- with GetOverrideStore -- see model.lua's own comment on why. Anything that
--- reaches for model.GetSparedRecipeStore after this file has loaded fails
--- loudly rather than editing the flag set behind Toggle's back.
---@type fun(): table<number, true>
local GetSparedRecipeStore = model.GetSparedRecipeStore
model.GetSparedRecipeStore = nil

--- itemID -> true, replaced wholesale by Rebuild. Empty until the module's
--- own onReady builds it, which reads as "nothing spared" -- the floor this
--- file is required to degrade to rather than raise.
local reagentIndex = {}

---@param recipeID number
---@return boolean
function sparedRecipes.IsSpared(recipeID)
    return GetSparedRecipeStore()[recipeID] == true
end

--- Every flagged recipe, ascending.
---
--- Sorted because a set has no order and the diagnostics dump prints this
--- list: an order that reshuffled between two reads would read as a change
--- nobody made.
---@return number[]
function sparedRecipes.List()
    local list = {}

    for recipeID in pairs(GetSparedRecipeStore()) do
        list[#list + 1] = recipeID
    end
    sort(list)

    return list
end

--- Adds one recipe's Basic reagent item IDs to `index`.
---
--- Every read here is guarded, and that is the point of the function: spec
--- #379 names GetRecipeSchematic at login as unproved -- the probe ran in a
--- session where a profession window had already been opened -- and this
--- index is built from the module's own onReady, so an answer the guards did
--- not expect would be a module that never starts rather than a feature that
--- keeps nothing. The call itself is protected for the same reason;
--- BitForge_Dev's FetchSchematic protects the same call the same way.
---@param index table<number, true>
---@param recipeID number
local function Collect(index, recipeID)
    local resolved, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
    if not resolved or type(schematic) ~= "table" then return end

    for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
        if slot.reagentType == BASIC then
            for _, reagent in ipairs(slot.reagents or {}) do
                -- A type test rather than a presence test: CraftingReagent's
                -- itemID is Nilable and a currency reagent carries none, and
                -- a 12.0 secret value is not a number either -- neither may
                -- become a key of a set the sell scan looks items up in.
                if type(reagent.itemID) == "number" then
                    index[reagent.itemID] = true
                end
            end
        end
    end
end

--- Re-resolves the reagent index from the flag set.
---
--- Built into a fresh table and swapped in at the end rather than emptied in
--- place: unflagging a recipe has to drop the reagents no other flagged
--- recipe still names, and rebuilding from the flags is the only thing that
--- knows which those are.
function sparedRecipes.Rebuild()
    local index = {}

    for _, recipeID in ipairs(sparedRecipes.List()) do
        Collect(index, recipeID)
    end

    reagentIndex = index
end

--- Flags or unflags one recipe, and answers the state it left it in.
---
--- The one write path. It invalidates because model.Decide reads the index:
--- a verdict memoised before the flag changed would otherwise stand until an
--- unrelated bag event turned the generation over.
---@param recipeID number
---@return boolean  whether the recipe is spared now
function sparedRecipes.Toggle(recipeID)
    local store = GetSparedRecipeStore()

    -- nil rather than false: an unflagged recipe is an absent entry, so
    -- nothing a player has turned off leaves a row in the saved file, and
    -- IsSpared and List agree about what the store holds without either
    -- having to read a stored false as absence.
    local flagged = not store[recipeID] or nil
    store[recipeID] = flagged

    sparedRecipes.Rebuild()
    model.facts.Invalidate()

    return flagged == true
end

--- Whether any flagged recipe needs this item as a Basic reagent.
---@param itemID number
---@return boolean
function sparedRecipes.WantsReagent(itemID)
    return reagentIndex[itemID] == true
end

model.sparedRecipes = sparedRecipes

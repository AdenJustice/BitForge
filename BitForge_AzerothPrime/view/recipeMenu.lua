---@class BitForge.AzerothPrime
local ns = select(2, ...)

local type = type

local Menu = Menu

local locale = ns.locale
local model = ns.model
---@class BitForge.AzerothPrime.View
local view = ns.view

-- Blizzard tags the recipe row's own right-click menu and builds it only when
-- `elementData.recipeInfo.learned and Professions.InLocalCraftingMode()`
-- (Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeList.lua:61; the tag
-- below is set three lines further in, at :63). That gate is accepted rather
-- than worked around: a player flags recipes this character has learned, at
-- their own profession window. The customer-orders list carries a different tag
-- and spec #379 defers it.
local RECIPE_LIST_TAG = "MENU_PROFESSIONS_RECIPE_LIST_FAVORITE"

--- One entry on a recipe row's own right-click menu: keep what this recipe is
--- made of (spec #379). A menu entry rather than anything drawn on the row, so
--- there is no layout of Blizzard's to follow and nothing to reposition when
--- they change it; the cost is the gate above.
---@class BitForge.AzerothPrime.View.RecipeMenu
local recipeMenu = {}

--- The recipe behind one recipe-list row, or nil when the row is not one.
---
--- GetData, never GetElementData. The recipe list is built with
--- CreateScrollBoxListTreeListView, so its element data is a tree node whose
--- recipeInfo is nil, and the row's own table sits one unwrap below it --
--- ScrollBoxListView.lua:81 ships that unwrap as `frame:GetData()` and its own
--- comment names the TreeDataProvider case.
---
--- Every step is a question rather than an assumption, because this runs inside
--- a menu pass Blizzard wraps in securecallfunction (Menu.lua:2636): a raise
--- here costs the entry and posts an error over somebody else's menu. The
--- honest answer to a row that is not a recipe, or to a shape that has moved,
--- is to add no entry at all.
---
--- The last guard is a type test rather than a presence test for the reason
--- model/sparedRecipes.lua gives about reagent item IDs: a 12.0 secret value is
--- not a number, and must not become a key of the flag set.
---@param owner table?
---@return number?
local function RecipeIDFromOwner(owner)
    if not owner or type(owner.GetData) ~= "function" then return end

    local data = owner:GetData()
    if type(data) ~= "table" then return end

    local recipeInfo = data.recipeInfo
    if type(recipeInfo) ~= "table" then return end

    local recipeID = recipeInfo.recipeID
    if type(recipeID) ~= "number" then return end

    return recipeID
end

--- MenuUtil hands both callbacks the element's own data (Menu.lua:699 and
--- :892), which is the recipeID given to CreateCheckbox.
---@param recipeID number
---@return boolean
local function IsSpared(recipeID)
    return model.sparedRecipes.IsSpared(recipeID)
end

--- Deliberately swallows Toggle's return. A responder's return value is a
--- MenuResponse and overrides the description's own (Menu.lua:934), so handing
--- back the boolean Toggle answers would replace the checkbox's Refresh with a
--- response no menu knows -- and only on the half of the toggle that flags.
---@param recipeID number
local function ToggleSpared(recipeID)
    model.sparedRecipes.Toggle(recipeID)
end

--- Registered once from the module's own startup. Menu.ModifyMenu appends a
--- callback per call (Menu.lua:2659) rather than replacing one, so this is not
--- idempotent and must not be called a second time.
function recipeMenu.Init()
    Menu.ModifyMenu(RECIPE_LIST_TAG, function(owner, rootDescription)
        local recipeID = RecipeIDFromOwner(owner)
        if not recipeID then return end

        rootDescription:CreateCheckbox(
            locale["menu:markRecipeReagents"], IsSpared, ToggleSpared, recipeID)
    end)
end

view.recipeMenu = recipeMenu

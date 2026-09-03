---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs
local format = string.format
local time = time

local GetProfessions = GetProfessions
local GetProfessionInfo = GetProfessionInfo
local C_TradeSkillUI = C_TradeSkillUI

local model = ns.model
local locale = ns.locale

---@class BitForge.Dispatch.Control
local control = ns.control

---@class BitForge.Dispatch.Control.Recipes
local recipes = {}

-- [skillLineID] = true. The prompt is the only path to a scan --
-- C_TradeSkillUI.OpenTradeSkill is protected, so this module cannot open a
-- profession window itself; repeating the prompt every login would be nagging
-- about something the player may have decided not to do.
local prompted = {}

--- The current character's professions, read live from the client.
---
--- GetProfessions returns five slot indices with holes in it -- a character with
--- no archaeology gets nil in the third position -- so the returns are indexed
--- positionally rather than walked, which would stop at the first hole.
---@return table  { { skillLineID = number, profession = number, name = string }, ... }
function recipes.ReadProfessions()
    local found = {}

    local first, second, archaeology, fishing, cooking = GetProfessions()
    local slots = { first, second, archaeology, fishing, cooking }

    for index = 1, 5 do
        local slot = slots[index]
        if slot then
            -- skillLine is return 7 of 10.
            local _, _, _, _, _, _, skillLineID = GetProfessionInfo(slot)
            if skillLineID then
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                -- ProfessionInfo.profession is Nilable
                -- (TradeSkillUITypesDocumentation.lua). A nil means the client
                -- has no Enum.Profession for this line, and a nil is not
                -- something WantedByAlt could ever match, so the slot is skipped.
                if info and info.profession ~= nil then
                    found[#found + 1] = {
                        skillLineID = skillLineID,
                        profession  = info.profession,
                        name        = info.professionName,
                    }
                end
            end
        end
    end

    return found
end

--- Records which recipes of one skill line the current character has learned.
---
--- Adds what the walk reports learned and retracts what it reports unlearned,
--- and touches nothing else. GetFilteredRecipeIDs honours the player's active
--- filters, so a recipe can be missing from the walk entirely; leaving those
--- alone makes a filtered scan incomplete rather than wrong.
---@param skillLineID number
---@return number learned  how many recipes were seen learned
function recipes.HarvestSkillLine(skillLineID)
    local charKey = BitForge:GetCurrentCharacter()
    local seen = 0

    for _, recipeID in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if info then
            -- TradeSkillRecipeInfo.learned is a bool
            -- (TradeSkillUIDocumentation.lua). The walk returns unlearned
            -- recipes too -- Blizzard_Professions.lua splits its own list into
            -- Learned and Unlearned groups -- so treating every returned ID as
            -- known would record the whole profession.
            if info.learned then
                model.SetRecipeKnown(charKey, recipeID, true)
                seen = seen + 1
            else
                model.SetRecipeKnown(charKey, recipeID, false)
            end
        end
    end

    model.SetRecipeScan(charKey, skillLineID, time())

    return seen
end

--- Records one newly learned recipe without re-scanning anything.
---
--- NEW_RECIPE_LEARNED carries (recipeID, recipeLevel, baseRecipeID)
--- (Blizzard_ProfessionsRecipeSchematicForm.lua). The base ID is preferred:
--- a multi-rank recipe fires with a per-rank recipeID, and the base is the ID a
--- recipe item names.
---@param recipeID number
---@param recipeLevel number|nil
---@param baseRecipeID number|nil
function recipes.OnNewRecipeLearned(recipeID, recipeLevel, baseRecipeID)
    local identifier = baseRecipeID or recipeID
    if not identifier then return end

    model.SetRecipeKnown(BitForge:GetCurrentCharacter(), identifier, true)
end

--- Tells the player to open each profession once, so there is something to harvest.
---
--- This module cannot do this itself: C_TradeSkillUI.OpenTradeSkill is
--- protected, and calling it from addon code raises ADDON_ACTION_BLOCKED
--- without opening anything. The player is the only way in.
---
--- Gated on the character having no scans at all, not on a per-skill-line
--- stamp: harvesting records the child line the window was showing, while this
--- list carries whatever GetProfessions reports, and the two need not be the
--- same ID. Once any profession has been opened the prompt stops for good.
function recipes.PromptForScans()
    local charKey = BitForge:GetCurrentCharacter()
    if model.HasAnyRecipeScan(charKey) then return end

    for _, entry in ipairs(recipes.ReadProfessions()) do
        if not prompted[entry.skillLineID] then
            prompted[entry.skillLineID] = true
            BitForge:Print(format(locale["msg:openProfession"], entry.name))
        end
    end
end

control.recipes = recipes

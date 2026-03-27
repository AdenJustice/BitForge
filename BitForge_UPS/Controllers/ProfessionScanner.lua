local ns = select(2, ...)

local ipairs = ipairs

local constants = ns.Constants
local model     = ns.Model

ns.ProfessionScanner = {}
local scanner = ns.ProfessionScanner

function scanner.Scan()
    local charKey = BitForge:GetCurrentCharacter()
    local crafting = {}

    -- GetProfessions() returns up to 6 slot indices (or nil).
    -- Slots: primary1, primary2, archaeology, fishing, cooking, firstAid(removed)
    -- Verify slot count/order matches WoW 12.0 API.
    local slots = { GetProfessions() }
    for _, slot in ipairs(slots) do
        if slot then
            -- GetProfessionInfo returns: name, icon, level, maxLevel, numAbilities,
            -- spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset
            local _, _, _, _, _, _, skillLine = GetProfessionInfo(slot)
            if skillLine and not constants.GATHERING_PROFESSIONS[skillLine] then
                crafting[#crafting + 1] = skillLine
            end
        end
    end

    model.SetProfessions(charKey, crafting)
end

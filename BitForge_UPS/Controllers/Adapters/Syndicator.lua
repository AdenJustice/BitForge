local ns = select(2, ...)

ns.SyndicatorAdapter = {}
local adapter = ns.SyndicatorAdapter

-- Syndicator uses "Name - Realm" (spaces around dash).
-- BitForge uses "Name-Realm" (no spaces).
-- Verify Syndicator key format against: Syndicator.API.GetCharacters()
local function toSyndicatorKey(bitforgeKey)
    local name, realm = bitforgeKey:match("^(.-)%-(.+)$")
    if name and realm then
        return name .. " - " .. realm
    end
    return bitforgeKey
end

-- Returns count of itemID held by charKey, or nil if Syndicator unavailable.
-- IMPORTANT: Verify the correct Syndicator API call during implementation.
-- Syndicator may expose: Syndicator.API.GetItemCount(characterKey, itemID)
-- or require iterating Syndicator.API.GetBagData / GetBankData.
function adapter.GetItemCount(charKey, itemID)
    if not (Syndicator and Syndicator.API) then return nil end
    local synKey = toSyndicatorKey(charKey)
    -- TODO during implementation: verify exact Syndicator API signature.
    -- Placeholder — replace with confirmed call:
    if Syndicator.API.GetItemCount then
        return Syndicator.API.GetItemCount(synKey, itemID)
    end
    return nil
end

local ns = select(2, ...)

local model = ns.Model

ns.Adapters         = {}
local adapters      = ns.Adapters
local activeAdapter = nil

-- Detects the first supported external addon and activates it.
-- Called on PLAYER_READY. Wipes built-in itemCounts if an adapter is found.
function adapters.Detect()
    if C_AddOns.IsAddOnLoaded("Syndicator") then
        activeAdapter = ns.SyndicatorAdapter
        model.WipeItemCounts()
        return
    end
    -- future: Altoholic, etc.
    activeAdapter = nil
end

-- Returns true when an external adapter is active.
function adapters.HasAdapter()
    return activeAdapter ~= nil
end

-- Returns the name of the active adapter, or "Built-in".
function adapters.GetName()
    if activeAdapter == ns.SyndicatorAdapter then return "Syndicator" end
    return "Built-in"
end

-- Returns count of itemID held by charKey.
-- Delegates to adapter if active, otherwise reads db.global.itemCounts.
function adapters.GetItemCount(charKey, itemID)
    if activeAdapter then
        local count = activeAdapter.GetItemCount(charKey, itemID)
        return count or 0
    end
    return model.GetRawItemCount(itemID, charKey)
end

local ns = select(2, ...)
local E  = BitForge.Events

local ipairs = ipairs
local pairs = pairs
local wipe = table.wipe

local C_CooldownViewer = C_CooldownViewer

local model = ns.Model

-- Tracked spell ID caches — rebuilt on every pool refresh
local trackedBuffSpells = {} -- { [spellID] = true }
local trackedBarSpells  = {} -- { [spellID] = true }
local trackedCdSpells   = {} -- { [spellID] = true }

-- =========================================================
-- Helpers
-- =========================================================

local function CollectCategory(category, out)
    local ids = C_CooldownViewer.GetCooldownViewerCategorySet(category)
    for _, cooldownID in ipairs(ids) do
        local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
        if info then
            out[info.spellID] = true
        end
    end
end

-- =========================================================
-- Live Update Functions
-- =========================================================

local function UpdateBuffIcons()
    local spells = {}
    for spellID in pairs(trackedBuffSpells) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        spells[#spells + 1] = {
            spellID        = spellID,
            isActive       = aura ~= nil,
            duration       = aura and aura.duration or 0,
            expirationTime = aura and aura.expirationTime or 0,
        }
    end
    ns.ClassPanelView.UpdateBuffIcons(spells)
end

local function UpdateBuffBars()
    local spells = {}
    for spellID in pairs(trackedBarSpells) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        spells[#spells + 1] = {
            spellID        = spellID,
            isActive       = aura ~= nil,
            duration       = aura and aura.duration or 0,
            expirationTime = aura and aura.expirationTime or 0,
        }
    end
    ns.ClassPanelView.UpdateBuffBars(spells)
end

local function UpdateCooldownIcons()
    local spells = {}
    for spellID in pairs(trackedCdSpells) do
        local cd = C_Spell.GetSpellCooldown(spellID)
        spells[#spells + 1] = {
            spellID  = spellID,
            start    = cd and cd.startTime or 0,
            duration = cd and cd.duration or 0,
            enabled  = cd and cd.isEnabled or false,
        }
    end
    ns.ClassPanelView.UpdateCooldownIcons(spells)
end

-- =========================================================
-- Pool Refresh
-- =========================================================

local function RefreshAllPools()
    wipe(trackedBuffSpells)
    wipe(trackedBarSpells)
    wipe(trackedCdSpells)

    CollectCategory(Enum.CooldownViewerCategory.TrackedBuff, trackedBuffSpells)
    CollectCategory(Enum.CooldownViewerCategory.TrackedBar, trackedBarSpells)
    CollectCategory(Enum.CooldownViewerCategory.Essential, trackedCdSpells)
    CollectCategory(Enum.CooldownViewerCategory.Utility, trackedCdSpells)

    UpdateBuffIcons()
    UpdateBuffBars()
    UpdateCooldownIcons()
end

-- =========================================================
-- Lifecycle
-- =========================================================

ns:Subscribe(E.PLAYER_READY, function()
    if not model.GetClassPanelEnabled() then return end

    -- Pool-refresh event handler
    local refreshFrame = CreateFrame("Frame")
    refreshFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "TRAIT_CONFIG_UPDATED" then
            if (...) ~= C_ClassTalents.GetActiveConfigID() then return end
        end
        RefreshAllPools()
    end)
    refreshFrame:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
    refreshFrame:RegisterEvent("COOLDOWN_VIEWER_TABLE_HOTFIXED")
    refreshFrame:RegisterEvent("COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED")
    refreshFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    refreshFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

    -- Live state handler (aura / cooldown ticks)
    local liveFrame = CreateFrame("Frame")
    liveFrame:SetScript("OnEvent", function(self, event)
        if event == "UNIT_AURA" then
            UpdateBuffIcons()
            UpdateBuffBars()
        else -- SPELL_UPDATE_COOLDOWN
            UpdateCooldownIcons()
        end
    end)
    liveFrame:RegisterUnitEvent("UNIT_AURA", "player")
    liveFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

    -- Initial load: refresh if CooldownViewer data is already available
    local isAvailable = C_CooldownViewer.IsCooldownViewerAvailable()
    if isAvailable then
        RefreshAllPools()
    end
    -- If not yet available, COOLDOWN_VIEWER_DATA_LOADED will trigger RefreshAllPools
end)

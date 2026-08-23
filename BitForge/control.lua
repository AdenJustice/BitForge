---@class BitForge.Core
local ns = select(2, ...)
local model = ns.model
local view = ns.view
local enum = ns.enum
---@class BitForge.Core.Control
local control = ns.control
local E = BitForge.Events

local C_AddOns = C_AddOns
local C_Timer = C_Timer
local C_TradeSkillUI = C_TradeSkillUI
local EventRegistry = EventRegistry
local ipairs = ipairs
local pcall = pcall
local select = select
local type = type
local format = string.format
local sub = string.sub

-- ================================================================================
-- Minimap button
-- ================================================================================

---@class BitForge.Core.Control.MinimapButton
local minimapButton = {}

local entries = {}

--- Builds the shared module menu. Anchored to whatever opened it -- the minimap
--- button or the addon compartment entry.
---@param anchor Frame
function minimapButton.OpenMenu(anchor)
    MenuUtil.CreateContextMenu(anchor, function(_, rootDescription)
        rootDescription:CreateTitle("BitForge")
        for _, entry in ipairs(entries) do
            rootDescription:CreateButton(entry.label, entry.onToggle)
        end
    end)
end

---@param angle number degrees
function minimapButton.OnPositionChanged(angle)
    model.UpdateDatabase("minimapPos", angle)
end

--- Built at PLAYER_LOGIN rather than on load: the position depends on the
--- minimap's real dimensions and on GetMinimapShape, and any UI addon providing
--- either has finished loading by then.
function minimapButton.Init()
    view.minimapButton.Create(minimapButton.OpenMenu, minimapButton.OnPositionChanged)
    view.minimapButton.SetPosition(
        model.ReadDatabase("minimapPos") or enum.DB_DEFAULTS.global.minimapPos)
end

control.minimapButton = minimapButton

--- Registers a module entry in the BitForge menu.
---@param entry { label: string, icon: string, onToggle: function }  icon is reserved for future menu icon support
function BitForge.RegisterMinimapButton(entry)
    entries[#entries + 1] = entry
end

-- The addon compartment calls these by name out of the TOC, so they have to be
-- globals rather than namespace members. Blizzard dispatches them as
-- _G[func](addonName, ...) after calling forceinsecure()
-- (Blizzard_Minimap/Mainline/AddonCompartment.lua:97-119).

-- Only the enter and leave callbacks are handed the frame; the click callback
-- receives the mouse button's name instead (:99-103). Hovering necessarily
-- precedes clicking, so the anchor is captured here.
local compartmentAnchor

function BitForge_OnAddonCompartmentEnter(_, anchor)
    compartmentAnchor = anchor
    view.minimapButton.ShowTooltip(anchor, "minimap:compartmentTooltip")
end

function BitForge_OnAddonCompartmentLeave()
    GameTooltip:Hide()
end

function BitForge_OnAddonCompartmentClick()
    minimapButton.OpenMenu(compartmentAnchor or AddonCompartmentFrame)
end

-- ================================================================================
-- Profession registry
-- ================================================================================

--- The current character's professions, as Enum.Profession values.
---
--- GetProfessions returns five slot indices with holes in it -- a character with
--- no archaeology gets nil in the third position -- so the returns are indexed
--- positionally rather than walked, which would stop at the first hole.
---@return table  array of Enum.Profession
local function ReadProfessions()
    local found = {}

    local first, second, archaeology, fishing, cooking = GetProfessions()
    local slots = { first, second, archaeology, fishing, cooking }

    for index = 1, 5 do
        local slot = slots[index]
        if slot then
            -- skillLine is return 7 of 10.
            local skillLineID = select(7, GetProfessionInfo(slot))
            if skillLineID then
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                -- ProfessionInfo.profession is Nilable. A nil means the client
                -- has no Enum.Profession for this line, and the catalogue is
                -- keyed by Enum.Profession, so the slot has nothing to match.
                if info and info.profession ~= nil then
                    found[#found + 1] = info.profession
                end
            end
        end
    end

    return found
end

local function RecordProfessions()
    BitForge:RecordCharacterProfessions(BitForge:GetCurrentCharacter(), ReadProfessions())
end

-- Gaining or losing a profession has to be seen without a reload, or the account
-- goes on protecting reagents for a trade that was just abandoned.
ns:Subscribe(E.SKILL_LINES_CHANGED, RecordProfessions)

-- ================================================================================
-- Lifecycle
-- ================================================================================
--
-- The bus and the relay registry live in events.lua. Only the two events core
-- publishes itself are wired here; every other event in BitForge.Events is a
-- relay that registers itself when a module first subscribes to it.

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    BitForge:RegisterCharacter()
    minimapButton.Init()
    model.MergeReagentScan()
    RecordProfessions()

    if model.IsReagentDataStale() and model.IsDebug() then
        BitForge:Print(
            "reagent data predates this client -- run the update_wowhead skill")
    end

    control.TriggerEvent(E.PLAYER_READY)
end)

-- The debug dumps are per-play-session scratch tables. PLAYER_ENTERING_WORLD is
-- the only event that tells a fresh login from a /reload, and the distinction is
-- the whole point: a reload is how a dump is flushed to disk to be read, so
-- clearing on one would empty every dump on the way to looking at it.
--
-- Registered directly rather than subscribed through the bus. PLAYER_ENTERING_WORLD
-- is a relay, and a relay registers its frame event only once a module subscribes
-- -- core taking one out for its own housekeeping would pin it for every profile.
EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD",
    function(_, isInitialLogin)
        if not isInitialLogin then return end
        model.WipeDebugDumps()
    end)

-- No module observes logout, so this stays a private core registration rather
-- than an entry in BitForge.Events.
EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGOUT", function()
    model.CleanupDatabase()
end)

-- ================================================================================
-- Settings
-- ================================================================================

local PREFIX = enum.ADDON_PREFIX
local PREFIX_LEN = #PREFIX

-- =========================================================
-- Scan
-- =========================================================

local function ScanModules()
    local modules = {}
    local count = C_AddOns.GetNumAddOns()
    for i = 1, count do
        local name, title = C_AddOns.GetAddOnInfo(i)
        if name and sub(name, 1, PREFIX_LEN) == PREFIX then
            -- GetAddOnEnableState: 0=disabled, 1=enabled(other char), 2=enabled(this char)
            local state = C_AddOns.GetAddOnEnableState(name, enum.PLAYER_NAME)
            modules[#modules + 1] = {
                name = name,
                title = title or name,
                enabled = state == 2,
                loaded = C_AddOns.IsAddOnLoaded(name),
            }
        end
    end
    model.SetModuleList(modules)
end

--- Called when a module checkbox is toggled.
---@param addonName string
---@param enable boolean
local function OnToggle(addonName, enable)
    if enable then
        C_AddOns.EnableAddOn(addonName)
        if not C_AddOns.IsAddOnLoaded(addonName) then
            C_AddOns.LoadAddOn(addonName)
        end
    else
        C_AddOns.DisableAddOn(addonName)
    end
end

-- =========================================================
-- Events
-- =========================================================

local function OnCoreLoaded()
    ScanModules()

    local modules = model.GetModuleList()
    local callbacks = {}
    for _, mod in ipairs(modules) do
        local name = mod.name
        callbacks[name] = {
            getValue = function()
                return C_AddOns.GetAddOnEnableState(name, enum.PLAYER_NAME) == 2
            end,
            setValue = function(value)
                OnToggle(name, value)
            end,
        }
    end

    view:Register(modules, callbacks)
end

-- OnCoreLoaded must run before TriggerEvent(CORE_LOADED) so that
-- BitForge.settingsCategory is set before any module's CORE_LOADED handler
-- fires. TriggerEvent dispatches via pairs() which gives no ordering guarantee,
-- so we cannot rely on subscription order to ensure the core runs first.
EventUtil.ContinueOnAddOnLoaded("BitForge", function()
    model.InitializeDatabase()
    OnCoreLoaded()
    control.TriggerEvent(E.CORE_LOADED)
end)

-- ================================================================================
-- Reagent catalogue -- filling the shipped table's gaps from an open window
-- ================================================================================
--
-- ReagentData.lua is scraped from Wowhead, which lists one item ID per reagent
-- slot -- so the other quality tiers of a reagent are absent -- and exposes
-- optional reagents only as modified-crafting category IDs, so those are absent
-- entirely. An open profession window is exact by comparison:
-- GetChildProfessionInfo states whose window it is, so nothing has to be
-- inferred, and GetFilteredRecipeIDs answers with the whole profession, learned
-- and unlearned, whatever expansion tab is showing.
--
-- So this recovers what the scrape missed, but only for professions somebody on
-- the account actually has -- C_TradeSkillUI.OpenTradeSkill is protected and
-- the player is the only way in. The two sources cover each other: the scrape
-- reaches every profession and the window reaches every reagent.

local scanning = false

--- Every distinct reagent item the given recipes consume.
---
--- Each entry in a slot, not just the first: a slot's quality tiers are
--- separate item IDs, and reagents[1] alone would drop exactly the ones the
--- scrape already missed.
---@param recipeIDs number[]
---@return number[]
local function CollectReagents(recipeIDs)
    local items, seen = {}, {}

    for _, recipeID in ipairs(recipeIDs) do
        local resolved, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
        if resolved and type(schematic) == "table" then
            for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
                for _, reagent in ipairs(slot.reagents or {}) do
                    local itemID = reagent.itemID
                    -- A 12.0 secret value would not survive being stored, and
                    -- the type test is what keeps one out of the database.
                    if type(itemID) == "number" and not seen[itemID] then
                        seen[itemID] = true
                        items[#items + 1] = itemID
                    end
                end
            end
        end
    end

    return items
end

local function OnTradeSkillListUpdate()
    -- Forcing the filters below raises this same event, so without the guard
    -- the scan would re-enter itself before the first pass restored anything.
    -- Professions is Blizzard_ProfessionsTemplates' global, absent until the
    -- professions UI has loaded.
    if scanning or not Professions then return end

    local child = C_TradeSkillUI.GetChildProfessionInfo()
    -- This answers with a table even when no window is open, so professionID is
    -- what actually says whether one is showing. Testing the table for nil
    -- would scan on every list update from a closed frame.
    if not child or (child.professionID or 0) == 0 then return end

    local profession = child.profession
    if profession == nil or model.HasScannedProfession(profession) then return end

    -- GetFilteredRecipeIDs honours the player's filters, and a filtered list is
    -- short rather than wrong, so they are forced for the duration. Blizzard's
    -- own save and restore is used rather than a hand-rolled one: it covers the
    -- search text, the makeable, skill-up and first-craft toggles, the source
    -- type and every inventory slot, and it goes on covering them when a patch
    -- adds another. The argument to SetDefaultFilters leaves the player's
    -- selected skill line alone.
    scanning = true
    local restore = Professions.GetCurrentFilterSet()
    Professions.SetDefaultFilters(true)

    -- One frame with the filters forced. The client rebuilds the filtered list
    -- on the event the change itself raises, so reading it in this frame would
    -- answer with the view that was already on screen.
    C_Timer.After(0, function()
        local recipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs()
        local added = 0
        if type(recipeIDs) == "table" then
            added = model.RecordReagentScan(profession, CollectReagents(recipeIDs))
        end

        Professions.ApplyfilterSet(restore)
        scanning = false

        -- Restoring raises the event once more. By then the profession is
        -- recorded as scanned, so the handler above returns before doing
        -- anything and the player is left on their own filters.
        if model.IsDebug() then
            BitForge:Print(format("reagents: profession %d added %d", profession, added))
        end
    end)
end

ns:Subscribe(E.TRADE_SKILL_LIST_UPDATE, OnTradeSkillListUpdate)

---@type string, BitForge.Core
local ADDON_NAME, ns = ...
local model = ns.model
local view = ns.view
local enum = ns.enum
---@type BitForge.Core.Locale
local locale = ns.locale
-- Nilable: a release build ships no debug/notices.lua at all, so a
-- non-nilable field would tell the language server the nil check below is
-- dead code.
---@class BitForge.Core.Control
---@field debugNotices BitForge.Core.Control.DebugNotices|nil
local control = ns.control
local events = BitForge.Events

local C_AddOns = C_AddOns
local C_TradeSkillUI = C_TradeSkillUI
local EventRegistry = EventRegistry
local ipairs = ipairs
local select = select
local sub = string.sub

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
-- globals rather than namespace members. Blizzard's AddonCompartment.lua
-- dispatches them as _G[func](addonName, ...) after calling forceinsecure().

-- Only the enter and leave callbacks are handed the frame; the click callback
-- receives the mouse button's name instead. Hovering necessarily precedes
-- clicking, so the anchor is captured here.
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
ns:Subscribe(events.SKILL_LINES_CHANGED, RecordProfessions)

-- The bus and the relay registry live in events.lua. Only core's two lifecycle
-- events are published from here; every other entry in BitForge.Events is a
-- relay that registers itself when a module first subscribes to it.

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    BitForge:RegisterCharacter()
    minimapButton.Init()
    RecordProfessions()

    local debugNotices = control.debugNotices
    if debugNotices then debugNotices.ReagentDataStale() end

    control.TriggerEvent(events.PLAYER_READY)
end)

-- The debug dumps are per-play-session scratch tables, and the What's New
-- popup is per-login rather than per-reload. PLAYER_ENTERING_WORLD is the only
-- event that tells the two apart, and the distinction matters for both: a
-- reload is how a dump is flushed to disk to be read, so clearing on one would
-- empty every dump on the way to looking at it, and notes that reappeared on
-- every reload would be worse than notes nobody saw.
--
-- Registered directly rather than subscribed through the bus. PLAYER_ENTERING_WORLD
-- is a relay, and a relay registers its frame event only once a module subscribes
-- -- core taking one out for its own housekeeping would pin it for every profile.
EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD",
    function(_, isInitialLogin)
        if not isInitialLogin then return end
        model.WipeDebugDumps()
        view.releaseNotes.ShowIfNew()
    end)

-- Core's first command handler. The one subcommand reopens the notes
-- ShowIfNew already raised (or would have, once the running version is
-- readable) for a player who dismissed them unread.
ns:SubscribeCommand(events.MODULE_COMMAND, function(addonName, argument)
    if addonName ~= ADDON_NAME then return end
    if argument:lower():match("^%s*whatsnew%s*$") then
        view.releaseNotes.Show()
        return
    end
    BitForge:Print(locale["cmd:coreUsage"])
end)

-- No module observes logout, so this stays a private core registration rather
-- than an entry in BitForge.Events.
EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGOUT", function()
    model.CleanupDatabase()
end)

local PREFIX = enum.ADDON_PREFIX
local PREFIX_LEN = #PREFIX

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
-- fires. Subscription order cannot carry that: TriggerEvent dispatches through
-- pairs(), which guarantees no ordering.
EventUtil.ContinueOnAddOnLoaded("BitForge", function()
    model.InitializeDatabase()
    OnCoreLoaded()
    control.TriggerEvent(events.CORE_LOADED)
end)

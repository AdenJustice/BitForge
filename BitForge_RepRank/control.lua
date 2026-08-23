---@type string, BitForge.RepRank
local ADDON_NAME, ns = ...

local format = string.format
local match = string.match
local ipairs = ipairs
local pairs = pairs

local C_GossipInfo = C_GossipInfo
local C_MajorFactions = C_MajorFactions
local C_Reputation = C_Reputation
local C_Timer = C_Timer
local GetText = GetText
local UnitSex = UnitSex

---@type BitForge.RepRank.Enum
local enum = ns.enum
---@type BitForge.RepRank.Model
local model = ns.model
---@type BitForge.RepRank.Locale
local locale = ns.locale
---@type BitForge.RepRank.View
local view = ns.view

---@class BitForge.RepRank.Control
local control = ns.control

local E = BitForge.Events

--- The owner every subscription is registered under. Core requires one, and
--- routing them all through ns keeps the module's unsubscribes symmetrical.
function ns:Subscribe(event, handler)
    BitForge.Subscribe(event, handler, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

-- =========================================================
-- Scanner
-- =========================================================

---@class BitForge.RepRank.Control.Scanner
local scanner = {}

-- How many visible rows the last pass observed, always read in the player's own
-- view: the full scan takes it *after* the collapsed set is restored, and the
-- refresh takes it again on the way out. The last reading rather than the
-- largest one -- a player who expands everything and then collapses it again
-- would leave a high-water mark above anything their own view can ever reach,
-- and new-faction discovery dead for the rest of the session. See Refresh.
local lastCount = 0

-- Whether startup has finished. Until it has, a scan announces nothing: the
-- login summary already reports everything pending, and the session's first
-- scan would otherwise repeat every one of those lines as though they were news.
local started = false

--- Announces paragon chests that appeared since the stored reading.
---
--- A local rather than a member of scanner: both scan paths call it, and nothing
--- outside this file should be able to. The `started` check is redundant with
--- the collection gate and kept anyway -- an empty list is the only thing this
--- should ever be handed before startup finishes, and it costs one comparison
--- to make that true rather than merely expected.
---@param transitions { charKey: string, factionID: number, name: string }[]
local function announceTransitions(transitions)
    if not started or #transitions == 0 then return end

    control.alerts.Announce(transitions)
end

--- The display string for a faction, resolved now, by the character who can
--- actually see it.
---
--- This is the reason the store holds strings rather than raw numbers. A
--- character cannot reliably resolve a friendship rank -- or in some cases any
--- naming at all -- for a faction it has never encountered, so resolving at
--- display time would leave blanks on precisely the alt-only factions the
--- module exists to surface.
---@param factionID   number
---@param reaction    number
---@param renownLevel number|nil
---@return string
local function resolveLabel(factionID, reaction, renownLevel)
    if renownLevel then
        return format(locale["standing:renown"], renownLevel)
    end

    local friendship = C_GossipInfo.GetFriendshipReputation(factionID)
    if friendship and friendship.friendshipFactionID > 0 and friendship.reaction then
        return friendship.reaction
    end

    -- Through GetText with the character's gender rather than a bare global
    -- read: five of the eleven locales this module ships inflect the standing
    -- names, and the label is *stored*, so a form resolved without the gender
    -- would sit in the database until that character was rescanned.
    return GetText("FACTION_STANDING_LABEL" .. reaction, UnitSex("player"))
        or locale["standing:unknown"]
end

--- The paragon half of a record, or nil when the faction has no paragon for
--- this character.
---
--- A chest the character is too low to claim is stored with pending false: the
--- state is real and becomes claimable the moment they level past the gate, but
--- it must not announce or mark a row before then.
---@param factionID number
---@return table|nil
local function readParagon(factionID)
    if not C_Reputation.IsFactionParagonForCurrentPlayer(factionID) then return end

    local currentValue, _, _, hasRewardPending, tooLowLevel, storageLevel =
        C_Reputation.GetFactionParagonInfo(factionID)

    if currentValue == nil then return end

    return {
        pending = (hasRewardPending and not tooLowLevel) or false,
        level   = storageLevel or 0,
        value   = currentValue,
    }
end

--- Builds one character's record for a faction, and merges what this reading
--- reveals about the faction itself.
---@param factionData table
---@return table record
local function recordFor(factionData)
    local factionID = factionData.factionID
    local isMajor = C_Reputation.IsMajorFaction(factionID)
    local renownLevel, majorData

    if isMajor then
        majorData = C_MajorFactions.GetMajorFactionData(factionID)
        renownLevel = C_MajorFactions.GetCurrentRenownLevel(factionID)
    end

    model.MergeFaction(factionID, {
        name          = factionData.name,
        isAccountWide = factionData.isAccountWide,
        isMajor       = isMajor,
        expansionID   = majorData and majorData.expansionID,
        uiPriority    = majorData and majorData.uiPriority,
    })

    return {
        tier    = factionData.reaction,
        renown  = renownLevel,
        value   = factionData.currentStanding,
        paragon = readParagon(factionID),
        label   = resolveLabel(factionID, factionData.reaction, renownLevel),
    }
end

--- Every header the player currently has collapsed, by name.
---
--- Iteratively, because a collapsed header hides its children from the index
--- walk -- and Blizzard nests headers, so one of those children can itself be a
--- collapsed header (`isHeader and isChild`, as ReputationFrame reads it). One
--- pass sees only the outermost layer; expanding what it found reveals the next,
--- and the loop ends when a pass finds nothing new.
---
--- Headers are opened one at a time rather than through ExpandAllFactionHeaders,
--- which clears every collapsed flag at once -- including the nested ones no
--- pass has read yet, which is precisely what has to be recorded first.
---@return string[]
local function collapsedHeaderNames()
    local names, seen = {}, {}
    local found

    repeat
        found = {}

        for index = 1, C_Reputation.GetNumFactions() do
            local factionData = C_Reputation.GetFactionDataByIndex(index)

            if factionData and factionData.isHeader and factionData.isCollapsed
                and not seen[factionData.name] then
                seen[factionData.name] = true
                names[#names + 1] = factionData.name
                found[#found + 1] = index
            end
        end

        -- Highest index first: expanding a header renumbers every row below it,
        -- so working downwards leaves the indices still to be opened valid.
        for position = #found, 1, -1 do
            C_Reputation.ExpandFactionHeader(found[position])
        end
    until #found == 0

    return names
end

--- Walks every faction the current character has and rewrites their records.
---
--- GetNumFactions counts only *visible* rows, so a collapsed header hides its
--- children from the walk entirely -- and which children depends on how the
--- player last left the pane. The walk therefore expands everything first and
--- restores the player's collapsed set and legacy flag afterwards. Restoring is
--- not politeness: without it the reputation pane is re-expanded on every login.
function scanner.Full()
    local legacyShown = C_Reputation.AreLegacyReputationsShown()

    -- Legacy first, and only then the collapsed set: a collapsed header inside
    -- a legacy set the player has switched off is not in the index walk at all
    -- until this runs, so reading the collapsed set before it would leave that
    -- header expanded afterwards.
    C_Reputation.SetLegacyReputationsShown(true)

    local collapsed = collapsedHeaderNames()

    -- The discovery pass above already opened everything it could reach; this
    -- closes over anything it could not.
    C_Reputation.ExpandAllFactionHeaders()

    local charKey = BitForge:GetCurrentCharacter()
    local records, transitions = {}, {}

    for index = 1, C_Reputation.GetNumFactions() do
        local factionData = C_Reputation.GetFactionDataByIndex(index)

        if factionData and (not factionData.isHeader or factionData.isHeaderWithRep) then
            local record = recordFor(factionData)

            -- Checked before the write, because NewlyPending compares against
            -- what is still stored -- and gated on `started`, so a scan that
            -- will announce nothing does not reach for the alerts table at all.
            if started and record.paragon
                and control.alerts.NewlyPending(charKey, factionData.factionID, record.paragon) then
                transitions[#transitions + 1] = {
                    charKey   = charKey,
                    factionID = factionData.factionID,
                    name      = factionData.name,
                }
            end

            records[factionData.factionID] = record
        end
    end

    model.ReplaceCharRecords(charKey, records)

    -- Restore by name rather than by the indices captured above: expanding the
    -- headers renumbered every row beneath them, so the old indices now point
    -- at different factions.
    local byName = {}
    for _, name in ipairs(collapsed) do byName[name] = true end

    for index = C_Reputation.GetNumFactions(), 1, -1 do
        local factionData = C_Reputation.GetFactionDataByIndex(index)
        if factionData and factionData.isHeader and byName[factionData.name] then
            C_Reputation.CollapseFactionHeader(index)
        end
    end

    C_Reputation.SetLegacyReputationsShown(legacyShown)

    -- Measured last, in the player's restored view, so Refresh compares like
    -- with like.
    lastCount = C_Reputation.GetNumFactions()

    announceTransitions(transitions)
end

-- Whether a refresh is already waiting to run. UPDATE_FACTION arrives in
-- bursts -- one turn-in can emit several -- and each refresh re-reads every
-- known faction, so they coalesce behind a single timer.
local refreshPending = false

-- Whether a requested scan is still waiting for the reputation pane to close.
local scanDeferred = false

-- Whether core has resolved this module's database. The subscriptions
-- themselves stay live and unguarded from file scope, as core intends -- it is
-- the database access behind them that has to wait. A refresh that ran before
-- onReady would read and write a store the schema upgrade has not reached yet,
-- which is how a migration silently loses data once there is a real one to run.
local ready = false

-- Whether the hook that resumes a deferred scan is installed. HookScript cannot
-- be undone, so it goes on once and reads scanDeferred on every hide rather than
-- being added and removed per deferral.
local hideHookInstalled = false

--- Runs a full scan, or waits for the reputation pane to close first.
---
--- Expanding every header underneath a player who is reading the pane is a
--- visible glitch, and the scan has no deadline -- so it waits for the pane's
--- own hide. ReputationFrame is load-on-demand and may not exist at startup, but
--- this branch runs only when it demonstrably exists and is shown, which is
--- exactly when a hook can be installed.
function scanner.Request()
    if ReputationFrame and ReputationFrame:IsShown() then
        scanDeferred = true

        if not hideHookInstalled then
            hideHookInstalled = true

            ReputationFrame:HookScript("OnHide", function()
                if scanDeferred then scanner.Request() end
            end)
        end

        return
    end

    scanDeferred = false
    scanner.Full()
end

--- Re-reads the current character's already-known factions.
---
--- By ID rather than by index, which is what keeps this path free of UI side
--- effects: no header expansion, nothing for the player to see. UPDATE_FACTION
--- does not say which faction changed, and re-reading a few hundred known IDs is
--- cheaper than one expand-and-restore cycle.
---
--- A faction encountered mid-session is not in the known list at all, so a grown
--- visible-row count hands off to a full scan instead. That covers every kind of
--- new faction rather than only the ones that announce themselves, at the cost
--- of one redundant scan when the player expands a header by hand -- which
--- restores their state and settles.
function scanner.Refresh()
    local charKey = BitForge:GetCurrentCharacter()
    local known = model.RecordsFor(charKey)

    -- Only a full scan answers either of these: nothing recorded for this
    -- character yet, or a faction that has appeared since the last reading,
    -- which the walk below cannot see because it is not in the known-ID list.
    if not known or C_Reputation.GetNumFactions() > lastCount then
        scanner.Request()

        -- It ran unless the pane is open, and a scan that ran has already
        -- rewritten every record this pass would have.
        if not scanDeferred then return end

        known = model.RecordsFor(charKey)
    end

    -- A deferred scan falls through to here rather than returning. This path
    -- reads by ID and touches no headers, so it is safe to run while the player
    -- has the pane open -- and while they do, it is the only thing keeping the
    -- store current.
    if not known then return end

    local transitions = {}

    for factionID in pairs(known) do
        local factionData = C_Reputation.GetFactionDataByID(factionID)

        if factionData then
            local record = recordFor(factionData)

            if started and record.paragon
                and control.alerts.NewlyPending(charKey, factionID, record.paragon) then
                transitions[#transitions + 1] = {
                    charKey   = charKey,
                    factionID = factionID,
                    name      = factionData.name,
                }
            end

            model.SetRecord(charKey, factionID, record)
        end
    end

    -- Read on the way out, in whatever view the player is in, so the next
    -- refresh compares against what this one actually saw.
    lastCount = C_Reputation.GetNumFactions()

    announceTransitions(transitions)
end

--- Coalesces refresh requests behind one timer.
---
--- Silent until the database is resolved: see `ready` above.
function scanner.ScheduleRefresh()
    if not ready or refreshPending then return end

    refreshPending = true

    C_Timer.After(enum.REFRESH_DELAY, function()
        refreshPending = false
        scanner.Refresh()
    end)
end

control.scanner = scanner

-- =========================================================
-- Alerts
-- =========================================================

---@class BitForge.RepRank.Control.Alerts
local alerts = {}

--- The character half of a "Name-Realm" key.
---
--- Realms are identical across an account, so spelling them out in a chat line
--- says nothing the player does not already know.
---@param charKey string
---@return string
local function shortCharacterName(charKey)
    return match(charKey, "^([^-]+)") or charKey
end

--- Whether a fresh paragon reading is a transition worth announcing.
---
--- Compared against the *stored* record rather than a session-local table: that
--- is what keeps a /reload from re-announcing every chest the account already
--- knows about. A faction with no stored record is a first sighting and counts.
---@param charKey   string
---@param factionID number
---@param paragon   table
---@return boolean
function alerts.NewlyPending(charKey, factionID, paragon)
    if not paragon.pending then return false end

    local stored = model.RecordFor(charKey, factionID)
    if not stored or not stored.paragon then return true end

    return not stored.paragon.pending
end

--- Announces pending chests on both channels.
---
--- One chat line per chest, and a single toast carrying the count: the detail
--- belongs in chat, and a login burst that stacked one toast per faction would
--- bury the rest of the alert queue. Either channel can be switched off without
--- affecting the other.
---
--- The current character's lines name only the faction; an alt's name the
--- character too, because that is the part the player has to act on.
---@param pending { charKey: string, factionID: number, name: string }[]
function alerts.Announce(pending)
    local count = #pending
    if count == 0 then return end

    if model.GetChatAlerts() then
        local currentKey = BitForge:GetCurrentCharacter()

        for _, entry in ipairs(pending) do
            if entry.charKey == currentKey then
                BitForge:Print(format(locale["alert:pendingSelf"], entry.name))
            else
                BitForge:Print(format(locale["alert:pendingAlt"],
                    shortCharacterName(entry.charKey), entry.name))
            end
        end
    end

    if model.GetToastAlerts() then
        view.toast.Show(count)
    end
end

--- The login summary: everything pending across the account, announced once.
function alerts.AnnounceLogin()
    local pending = model.CollectPending()
    if #pending == 0 then return end

    alerts.Announce(pending)
end

control.alerts = alerts

--- Marks the database safe to touch.
---
--- Called at the top of control.Start, which core invokes only once the schema
--- upgrade has resolved. Public so a test can arm the scanner without standing
--- up the whole of startup.
function control.MarkReady()
    ready = true
end

--- Marks startup complete, arming the live transition announcements.
---
--- Called at the bottom of control.Start, for the reason spelled out there.
--- Public for the same reason MarkReady is.
function control.MarkStarted()
    started = true
end

--- The module's real startup, run only once core has resolved the database.
---
--- Order matters: the scan writes the store the summary reads, so announcing
--- first would report the previous session's state.
function control.Start()
    -- First: everything below this line reads or writes the database, and core
    -- has only just finished resolving it.
    control.MarkReady()

    view.toast.Register()
    view.settingsPanel.Init()

    BitForge.RegisterMinimapButton({
        label    = locale["minimap:label"],
        icon     = nil,
        onToggle = function() view.window.Toggle() end,
    })

    scanner.Request()
    alerts.AnnounceLogin()

    -- Last: from here a scan announces what changed, rather than repeating the
    -- summary that just ran.
    control.MarkStarted()
end

ns:Subscribe(E.PLAYER_READY, function()
    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        steps   = {
            -- The module's initial version: there is no earlier shape to carry
            -- forward, so adopting the version is the whole migration.
            [1] = function() end,
        },
        hasData = model.HasData,
    }, control.Start)
end)

ns:Subscribe(E.UPDATE_FACTION, function()
    scanner.ScheduleRefresh()
end)

ns:Subscribe(E.MAJOR_FACTION_RENOWN_LEVEL_CHANGED, function()
    scanner.ScheduleRefresh()
end)

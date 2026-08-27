---@type string, BitForge.EUI
local ADDON_NAME, ns = ...

local events = BitForge.Events

---@class BitForge.EUI.Control
local control = ns.control

---@type BitForge.EUI.Model
local model = ns.model
---@type BitForge.EUI.Locale
local locale = ns.locale
---@type BitForge.EUI.Enum
local enum = ns.enum
---@type BitForge.EUI.View
local view = ns.view

local format = string.format

-- Ported from the standalone addon's Core/Events.lua (the wiring half) and
-- Core/Commands.lua. Every fact this file relies on about the anchor math and
-- write path lives in control/resolver.lua and control/sync.lua -- this file
-- decides WHEN those run (login, a slash command, leaving combat) and reports
-- what they did.

function ns:Subscribe(event, handler)
    BitForge.Subscribe(event, handler, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

--- Subscribes to one of core's two command events. Separate from ns:Subscribe
--- because core also has to be told which addon is answering: the bus knows
--- only an owner table, and /bitforge's roster names modules.
function ns:SubscribeCommand(event, handler)
    BitForge.SubscribeCommand(ADDON_NAME, event, handler, self)
end

-- Set when an apply was refused for combat and is owed a retry.
local applyPending = false

ns:Subscribe(events.PLAYER_READY, function()
    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        -- Keyed by the version each step produces. Version 1 is the initial
        -- shape and there is nothing before it to convert, but the entry must
        -- exist: core treats a missing step as a gap and stops the module.
        steps   = { [1] = function() end },
        hasData = model.HasData,
    }, control.OnPlayerReady)
end)

--- Reports a combat refusal the same way wherever it can happen: the two
--- deferred login passes below, the manual /bitforge eui apply further down,
--- and the PLAYER_REGEN_ENABLED retry itself if it comes back refused again.
--- `noEllesmere` needs a different remedy -- waiting for combat to end will
--- not fix a missing addon -- so it is left for the caller to report on its
--- own instead of being folded in here.
---
--- Silent when applyPending is already true: both login passes can land in
--- the same combat, and a second "still in combat" so soon after the first
--- would just be noise.
---@param result table|nil  what control.sync.Apply() answered, or what
---                          control.sync.SeedOrApply() passed through from it
---@return boolean deferred
local function deferForCombat(result)
    if not (type(result) == "table" and result.refused and not result.noEllesmere) then
        return false
    end
    if not applyPending then
        applyPending = true
        BitForge:Print(locale["apply:deferredCombat"])
    end
    return true
end

-- Retry an apply combat refused. Subscribed at file scope, below
-- deferForCombat's definition so this closure can see it, and gated on a
-- flag: CLAUDE.md forbids subscribing from inside another handler, because a
-- deferred subscription defers the frame registration with it.
ns:Subscribe(events.PLAYER_REGEN_ENABLED, function()
    if not applyPending then return end
    applyPending = false

    -- No BuildAnchorFrames() call here: both entry points that can arm this
    -- retry -- doApply below, and control.sync.SeedOrApply during login --
    -- already rebuilt anchor frames before deferring, so a rebuild here would
    -- be redundant.
    local result = control.sync.Apply()

    if result.noEllesmere then
        BitForge:Print(locale["error:noEllesmere"])
        return
    end
    if deferForCombat(result) then return end

    BitForge:Print(format(locale["apply:deferredDone"], result.applied, result.unchanged))
end)

--- One deferred login pass. Wrapped in xpcall so a raise in the resolver or
--- the write path does not cost the other pass its turn; on success, whether
--- it reached and was refused by an Apply is read from SeedOrApply's return.
local function loginPass()
    local ok, result = xpcall(control.sync.SeedOrApply, CallErrorHandler)
    if ok then deferForCombat(result) end
end

-- Ports the standalone addon's Core/Events.lua:82-93. Passed to
-- control.adapters.OnUnlockMode, which wraps it in its own xpcall --
-- EllesmereUI's own dispatcher already wraps every listener in pcall, which
-- unwinds the stack before anything here could report a raise, so the safety
-- net has to sit on our side of that call.
local function onUnlockMode(active, closeAction)
    if active then
        -- Opening: warn before the drag, since the drag is what destroys the
        -- attachment and nothing can confirm the loss after the fact.
        local attached = control.sync.CountAttached()
        if attached > 0 then
            BitForge:Print(format(locale["unlock:attachedWarning"], attached))
        end
        return
    end

    -- Closing. Only a saved session is worth capturing: "discard" and "exit"
    -- leave EllesmereUI's stored positions untouched, so there is nothing new
    -- to read. Ordering is what makes this safe -- EllesmereUI commits
    -- positions immediately before firing this listener, so a drag is already
    -- committed by the time Capture reads it.
    if closeAction ~= "save" then return end

    local _, detached = control.sync.Capture()
    if #detached > 0 then
        BitForge:Print(format(locale["unlock:noLongerAttached"], table.concat(detached, ", ")))
    end
end

--- The module's real startup, run once core resolves the schema. Ports the
--- source's PLAYER_LOGIN handler: the unlock-mode listener registers
--- unconditionally, then two deferred passes give EllesmereUI's own modules
--- time to register their elements before this module reads the registry.
function control.OnPlayerReady()
    control.adapters.OnUnlockMode(onUnlockMode)

    C_Timer.After(enum.FIRST_PASS, loginPass)
    C_Timer.After(enum.SECOND_PASS, loginPass)
end

-- Slash commands -- ported from the standalone addon's Core/Commands.lua.
-- Subcommand keywords stay ASCII and untranslated: the player types them.

local function isUnmanaged(key)
    return model.GetLayout()[key] == nil
end

--- Everything `list` and `dump <key>` both want to know about one registered
--- element: its anchor or position, its size, and whether the saved layout
--- manages it. Reads only, through control.adapters -- never EllesmereUI
--- directly -- so both callers stay on the right side of the quarantine.
---@param key string
---@return table  { anchored, anchorTarget?, anchorSide?, point?, x?, y?,
---                  width?, height?, managed }
local function elementFacts(key)
    local facts = { managed = not isUnmanaged(key) }

    facts.anchored = control.adapters.IsAnchored(key)
    if facts.anchored then
        local anchor = control.adapters.ReadAnchor(key) or {}
        facts.anchorTarget, facts.anchorSide = anchor.target, anchor.side
    else
        local position = control.adapters.ReadPosition(key)
        if position then
            facts.point = position.point or "CENTER"
            facts.x, facts.y = position.x or 0, position.y or 0
        end
    end

    facts.width, facts.height = control.adapters.ReadSize(key)

    return facts
end

--- One element as a line of `/bitforge eui list`. `element` is the registry
--- itself, and `element.label` is read off it by name -- fact 9,
--- docs/eui-integration.md: the display fields are not behind an adapter, so a
--- rename upstream lands here rather than in adapters.lua.
---@param key string
---@param element table  the raw EllesmereUI registry entry
---@return string
local function describeElement(key, element)
    local facts = elementFacts(key)
    local parts = { key }

    if element.label and element.label ~= key then
        parts[#parts + 1] = "(" .. element.label .. ")"
    end

    if facts.anchored then
        parts[#parts + 1] = format(locale["list:anchored"], tostring(facts.anchorTarget), tostring(facts.anchorSide))
    elseif facts.point then
        parts[#parts + 1] = format("%s %.0f,%.0f", facts.point, facts.x, facts.y)
    else
        parts[#parts + 1] = locale["list:noPosition"]
    end

    if facts.width and facts.height then
        parts[#parts + 1] = format("%.0fx%.0f", facts.width, facts.height)
    end

    if not facts.managed then
        parts[#parts + 1] = locale["list:unmanaged"]
    end

    return table.concat(parts, " ")
end

local function doList(rest)
    local elements = control.adapters.Elements()
    if not elements then
        BitForge:Print(locale["error:noRegistry"])
        return
    end

    -- "-u" restricts to elements the saved layout does not manage. Stripped
    -- before the substring filter so the two combine: "list -u bar".
    rest = rest or ""
    local onlyUnmanaged = false
    local stripped = rest:gsub("^%-u%s*", "")
    if stripped ~= rest then
        onlyUnmanaged = true
        rest = stripped
    end
    local filter = rest

    local keys, unmanaged, total = {}, 0, 0
    for key in pairs(elements) do
        total = total + 1
        if isUnmanaged(key) then unmanaged = unmanaged + 1 end
        local matches = (filter == "" or key:lower():find(filter, 1, true))
        if matches and (not onlyUnmanaged or isUnmanaged(key)) then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys)

    if #keys == 0 then
        BitForge:Print(locale["list:none"])
        return
    end

    for _, key in ipairs(keys) do
        -- One element's getter raising must not cut the listing short.
        local ok, line = xpcall(describeElement, CallErrorHandler, key, elements[key])
        BitForge:Print(ok and line or format(locale["list:readFailed"], key))
    end
    BitForge:Print(format(locale["list:count"], #keys, unmanaged, total))
end

local function doApply()
    -- control.sync.SeedOrApply is the only caller that rebuilds anchor frames
    -- at login; this command is the second, so a target added since the last
    -- login does not read as unknown until the player reloads.
    local _, refusals = control.resolver.BuildAnchorFrames()
    for _, refusal in ipairs(refusals) do
        BitForge:Print(control.resolver.FormatRefusal(refusal))
    end

    local result = control.sync.Apply()

    if result.noEllesmere then
        BitForge:Print(locale["error:noEllesmere"])
        return
    end
    if deferForCombat(result) then return end

    BitForge:Print(format(locale["apply:applied"], result.applied, result.unchanged))

    if result.anchorOwned > 0 then
        BitForge:Print(format(locale["apply:anchorOwned"], result.anchorOwned))
    end
    if result.resolved > 0 then
        BitForge:Print(format(locale["apply:resolved"], result.resolved))
    end

    if #result.badAnchors > 0 then
        BitForge:Print(format(locale["apply:badAnchors"], #result.badAnchors))
        -- The hint explains one reason only -- a target that is not an
        -- element key. Printing it after every reason told a player who HAD
        -- written point/relPoint to go and write point/relPoint, which reads
        -- as the module not having understood them.
        local anyUnknown = false
        for _, bad in ipairs(result.badAnchors) do
            BitForge:Print(format(locale["apply:badAnchorLine"], bad.key, bad.target, locale["reason:" .. bad.reason]))
            if bad.reason == "unknown" then anyUnknown = true end
        end
        if anyUnknown then BitForge:Print(locale["apply:badAnchorHint"]) end
    end
    if #result.unknown > 0 then
        BitForge:Print(format(locale["apply:unknownKeys"], #result.unknown, table.concat(result.unknown, ", ")))
        BitForge:Print(locale["apply:unknownHint"])
    end
    if #result.failed > 0 then
        BitForge:Print(format(locale["apply:failedKeys"], #result.failed, table.concat(result.failed, ", ")))
    end
end

local function doCapture()
    if not control.adapters.IsPresent() then
        BitForge:Print(locale["error:noRegistry"])
        return
    end

    local count, detached = control.sync.Capture()
    BitForge:Print(format(locale["capture:result"], count))
    if #detached > 0 then
        BitForge:Print(format(locale["unlock:noLongerAttached"], table.concat(detached, ", ")))
    end
end

-- reset discards player data, so it never acts on the first invocation.
--
-- "anchors" is a separate, separately confirmed step because the two are not
-- equally recoverable: a wiped layout is rebuilt from EllesmereUI on the next
-- login, but anchor definitions exist only here and nothing can re-derive them.
local function doReset(rest)
    local wantAnchors = rest:find("anchors", 1, true) ~= nil
    local confirmed = rest:find("confirm", 1, true) ~= nil

    if not confirmed then
        BitForge:Print(wantAnchors and locale["reset:anchorsConfirm"] or locale["reset:confirm"])
        return
    end

    model.WipeLayout()
    if wantAnchors then
        model.WipeAnchors()
        BitForge:Print(locale["reset:anchorsDone"])
    else
        BitForge:Print(locale["reset:done"])
    end
end

local function handleCommand(input)
    local command, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = (command or ""):lower()
    rest = (rest or ""):lower()

    if command == "ui" then
        view.editor.Toggle()
    elseif command == "apply" then
        doApply()
    elseif command == "capture" then
        doCapture()
    elseif command == "list" then
        doList(rest)
    elseif command == "reset" then
        doReset(rest)
    elseif command == "rl" then
        ReloadUI()
    else
        BitForge:Print(locale["cmd:help"])
        BitForge:Print(locale["cmd:helpUi"])
        BitForge:Print(locale["cmd:helpApply"])
        BitForge:Print(locale["cmd:helpCapture"])
        BitForge:Print(locale["cmd:helpList"])
        BitForge:Print(locale["cmd:helpListUnmanaged"])
        BitForge:Print(locale["cmd:helpReset"])
    end
end

ns:SubscribeCommand(events.MODULE_COMMAND, function(addon, argument)
    if addon ~= ADDON_NAME then return end
    handleCommand(argument)
end)

-- The one command in the suite that had real users, kept as an alias that says
-- so once and then does what it always did. The other four only ever existed
-- behind a diagnostics flag, so nothing is owed to them.
SLASH_BITFORGEEUI1 = "/bfeui"
SlashCmdList["BITFORGEEUI"] = function(input)
    BitForge:Print(locale["cmd:deprecated"])
    handleCommand(input)
end

-- Diagnostics dump -- BitForge_BatchSell's /bfdump batchsell is the worked
-- example this follows. The record's own field names stay unlocalized, like
-- that one: a diagnostic dump is read by a developer pasting it back, not by
-- a player. Only the report window's footnote goes through ns.locale, since
-- that is what the player reads before deciding to paste it anywhere.

-- The scalar keys BuildElementDump's table literal writes. Fixed here rather
-- than read with pairs: a table literal's pairs() order is unspecified, and a
-- report has to render identically for every player who copies one out.
local DUMP_FIELDS = { "label", "folder", "anchored", "anchor", "position", "size", "managed" }

--- One registered element's known geometry, flattened to strings so it is
--- pastable verbatim -- flattening is what makes a value that could be secret
--- in 12.0 safe to put in front of a player. `label` and `folder` are read by
--- name off the registry entry (fact 9, docs/eui-integration.md).
---@param key string
---@param element table  the raw EllesmereUI registry entry
---@return table
local function BuildElementDump(key, element)
    local facts = elementFacts(key)

    return {
        label    = tostring(element.label or key),
        folder   = tostring(element.folder or "?"),
        anchored = tostring(facts.anchored),
        anchor   = facts.anchored
            and format("target=%s side=%s", tostring(facts.anchorTarget), tostring(facts.anchorSide))
            or "nil",
        position = facts.point
            and format("%s %s,%s", facts.point, tostring(facts.x), tostring(facts.y))
            or "nil",
        size     = format("%sx%s", tostring(facts.width), tostring(facts.height)),
        managed  = tostring(facts.managed),
    }
end

--- One registered element's known geometry as text a player can select and
--- paste.
---@param key string
---@param element table
---@return string
local function RenderElementDump(key, element)
    local record = BuildElementDump(key, element)
    local lines = {
        "BitForge EUI -- element report",
        BitForge:ReportHeader(ADDON_NAME),
        "",
        format("key = %s", key),
    }

    for _, field in ipairs(DUMP_FIELDS) do
        lines[#lines + 1] = format("%s = %s", field, tostring(record[field]))
    end

    return table.concat(lines, "\n")
end

--- Show one registered element's known geometry in the report window.
---
--- Nothing is stored: the record used to be parked in the module's debug
--- container for a later session to dig out of SavedVariables, which is why
--- it needed the debug flag to stop it accumulating unasked. Rendered and
--- shown, it records nothing, so it needs no flag and no /reload.
---@param key string|nil
function control.DumpElement(key)
    if not key then
        BitForge:Print("EUI: /bfdump eui <key>")
        return
    end

    local elements = control.adapters.Elements()
    local element = elements and elements[key]
    if not element then
        BitForge:Print(("EUI: %s is not a registered element"):format(key))
        return
    end

    BitForge:ShowReport(RenderElementDump(key, element), locale["report:blurb"],
        BitForge:DiagnosticReportTitle())
end

ns:SubscribeCommand(events.MODULE_DUMP, function(addon, argument)
    if addon ~= ADDON_NAME then return end
    control.DumpElement(argument:match("%S+"))
end)

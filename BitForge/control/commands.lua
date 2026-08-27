---@type string, BitForge.Core
local ADDON_NAME, ns = ...

---@type BitForge.Core.Model
local model = ns.model
---@type BitForge.Core.Locale
local locale = ns.locale
---@class BitForge.Core.Control
local control = ns.control

local events = BitForge.Events

local C_AddOns = C_AddOns
local error = error
local ipairs = ipairs
local tostring = tostring
local concat = table.concat
local sort = table.sort
local format = string.format
local lower = string.lower
local sub = string.sub

-- Every slash command in the suite arrives here. A module registers no command
-- of its own: it subscribes to one of the two command events and answers only
-- when the payload names it.
--
-- Core resolves the abbreviation because dispatch is a broadcast. A module
-- cannot see its siblings, so two modules matching the same prefix would both
-- answer and neither could tell. Core holds the installed list and is the only
-- place the ambiguity is visible at all.

---@class BitForge.Core.Control.Commands
local commands = {}

-- Which addons answer which command event. A bus subscription knows an owner
-- table and nothing else, so neither the roster nor the "no such command"
-- refusal could be answered from the bus alone. Filled by SubscribeCommand,
-- which *is* the subscription -- there is no second list to keep in step.
--
-- A command subscription lasts the session: there is no inverse, and nothing
-- ever clears an entry. A module that dropped its handler with a bare
-- ns:Unsubscribe would keep its roster line and stay past the refusal, so its
-- command would broadcast to nobody -- the silence the refusal exists to
-- prevent. Adding the inverse is what to do if a module ever needs one; no
-- module unsubscribes today.
local answering = {
    [events.MODULE_COMMAND] = {},
    [events.MODULE_DUMP]    = {},
}

--- Subscribes an addon to a command event and lists it in /bitforge's roster.
---
--- The addon name has to be the module's own first vararg: core dispatches on
--- it and the handler compares it against the same value, so a hand-written
--- string is a command nothing can answer.
---@param addonName string  the addon's name from `...`
---@param event string  BitForge.Events.MODULE_COMMAND or MODULE_DUMP
---@param callback fun(addonName: string, argument: string)
---@param owner table
function BitForge.SubscribeCommand(addonName, event, callback, owner)
    local subscribers = answering[event]
    if not subscribers then
        error("BitForge.SubscribeCommand: " .. tostring(event) .. " is not a command event", 2)
    end

    subscribers[addonName] = true
    BitForge.Subscribe(event, callback, owner)
end

--- Core's own wrapper, for the commands core itself answers.
---
--- Core subscribes through the same entry point a module does rather than being
--- special-cased at dispatch: it is one more name in the namespace, and the
--- roster, the abbreviation and the "answers no such command" refusal all fall
--- out of that without a second code path.
---@param event string  BitForge.Events.MODULE_COMMAND or MODULE_DUMP
---@param callback fun(addonName: string, argument: string)
function ns:SubscribeCommand(event, callback)
    BitForge.SubscribeCommand(ADDON_NAME, event, callback, self)
end

--- Everything a slash command can name, by full addon name.
---
--- Core and every module that is loaded. Core is unconditional -- it is always
--- the addon this is running in -- while a module's loaded state is read live
--- rather than from the scan's `loaded` flag: that flag is taken while core's
--- own ADDON_LOADED is being handled, which is before any module addon has been
--- read, so it answers false for all of them.
---@return string[]
local function CommandTargets()
    local names = { ADDON_NAME }
    for _, entry in ipairs(model.GetModuleList()) do
        if C_AddOns.IsAddOnLoaded(entry.name) then
            names[#names + 1] = entry.name
        end
    end
    -- By the name each one is printed under, not by its addon name. Those agree
    -- for every module and disagree for core, which would otherwise lead a list
    -- it is alphabetically in the middle of.
    sort(names, function(left, right)
        return model.ModuleKey(left) < model.ModuleKey(right)
    end)
    return names
end

--- The shortest prefix of a module's typed name that names only it.
---@param addonName string
---@param installed string[]  every module the prefix has to stay unique against
---@return string
local function Abbreviation(addonName, installed)
    local short = lower(model.ModuleKey(addonName))

    for length = 1, #short do
        local prefix = sub(short, 1, length)
        local unique = true
        for _, other in ipairs(installed) do
            if other ~= addonName and sub(lower(model.ModuleKey(other)), 1, length) == prefix then
                unique = false
                break
            end
        end
        if unique then return prefix end
    end

    return short
end

--- The module -- or core -- a player named.
---
--- An exact name wins outright, so a module whose name is a prefix of another's
--- stays reachable rather than reading as ambiguous against it.
---@param typed string
---@return string|nil addonName
---@return string[] candidates  what an unresolved prefix matched, for the report
function commands.Resolve(typed)
    local wanted = lower(typed)
    if wanted == "" then return nil, {} end

    local matches = {}
    for _, addonName in ipairs(CommandTargets()) do
        local short = lower(model.ModuleKey(addonName))
        if short == wanted then return addonName, {} end
        if sub(short, 1, #wanted) == wanted then
            matches[#matches + 1] = addonName
        end
    end

    if #matches == 1 then return matches[1], {} end
    return nil, matches
end

--- The roster, as the lines it prints: one module per line with the shortest
--- abbreviation that reaches it and the commands it answers.
---
--- This is the whole reason /bitforge takes no subcommand. The complaint the
--- rewrite answers is that the old five commands were impossible to remember,
--- and a list that is computed from what is installed cannot go stale the way
--- a written-down one does.
---@return string[]
function commands.Roster()
    local installed = CommandTargets()
    local lines = {}

    for _, addonName in ipairs(installed) do
        local answers = {}
        if answering[events.MODULE_COMMAND][addonName] then answers[#answers + 1] = "/bitforge" end
        if answering[events.MODULE_DUMP][addonName] then answers[#answers + 1] = "/bfdump" end

        local line = format("%s (%s)", model.ModuleKey(addonName), Abbreviation(addonName, installed))
        if #answers > 0 then
            line = line .. " -- " .. concat(answers, ", ")
        end
        lines[#lines + 1] = line
    end

    return lines
end

--- Resolves what the player typed and publishes the rest of the line.
---
--- The remainder is passed whole rather than split: every handler parses its
--- own arguments, and one of them takes free text with spaces in it.
---@param event string  BitForge.Events.MODULE_COMMAND or MODULE_DUMP
---@param slash string  the command as typed, named in the refusal
---@param input string|nil
local function Dispatch(event, slash, input)
    local typed, argument = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")

    if typed == "" then
        BitForge:Print(locale["cmd:usage"])
        for _, line in ipairs(commands.Roster()) do
            BitForge:Print(line)
        end
        return
    end

    local addonName, candidates = commands.Resolve(typed)
    if not addonName then
        if #candidates > 1 then
            local named = {}
            for index, candidate in ipairs(candidates) do
                named[index] = model.ModuleKey(candidate)
            end
            BitForge:Print(format(locale["cmd:ambiguousModule"], typed, concat(named, ", ")))
        else
            BitForge:Print(format(locale["cmd:unknownModule"], typed))
        end
        return
    end

    -- Refused rather than fired. A broadcast nobody answers is silence, which
    -- reads exactly like a command that worked.
    if not answering[event][addonName] then
        BitForge:Print(format(locale["cmd:noSuchCommand"], model.ModuleKey(addonName), slash))
        return
    end

    control.TriggerEvent(event, addonName, argument)
end

--- Reports a filed diagnostics record and how to keep it.
---
--- Centralized because the persistence rule is not discoverable from anywhere
--- else: core empties every dump on PLAYER_ENTERING_WORLD when isInitialLogin is
--- set, so a /reload both preserves the dump and flushes it to the saved file --
--- which is the only way to read one -- while logging back in clears it.
---@param addonName string  the addon's name from `...`
---@param message string  what was filed, e.g. "dumped item 12345"
function BitForge:ReportDump(addonName, message)
    self:Print(format("%s: %s. /reload, then read %s -- the next login wipes it",
        model.ModuleKey(addonName), message, model.DumpPath(addonName)))
end

control.commands = commands

SLASH_BITFORGE1 = "/bitforge"
SlashCmdList["BITFORGE"] = function(input)
    Dispatch(events.MODULE_COMMAND, "/bitforge", input)
end

SLASH_BITFORGEDUMP1 = "/bfdump"
SlashCmdList["BITFORGEDUMP"] = function(input)
    Dispatch(events.MODULE_DUMP, "/bfdump", input)
end

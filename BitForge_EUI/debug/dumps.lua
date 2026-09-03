---@type string, BitForge.EUI
local ADDON_NAME, ns = ...

local events = BitForge.Events

---@class BitForge.EUI.Control
local control = ns.control

---@type BitForge.EUI.Locale
local locale = ns.locale

local format = string.format

-- Diagnostics dump -- BitForge_Dispatch's /bfdump dispatch sell is the worked
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
    local facts = control.elementFacts(key)

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
--- Rendered and shown, never stored, so it needs no debug flag and no
--- /reload. Parking the record in the module's debug container instead would
--- need the flag back, to stop it accumulating unasked.
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
end, true)

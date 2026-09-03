---@class BitForge.Core
local ns = select(2, ...)

local format = string.format

---@type BitForge.Core.Enum
local enum = ns.enum
---@type BitForge.Core.Model
local model = ns.model

---@class BitForge.Core.Control
local control = ns.control

---@class BitForge.Core.Control.DebugNotices
local debugNotices = {}

--- Says the reagent catalogue was built for an older client, if it was.
---
--- Here rather than in control.lua because the whole of it is a developer's
--- notice: nothing a player can act on, and the catalogue is reshipped after a
--- patch by whoever builds the release. The caller nil-checks this file's
--- sub-key, so a release build keeps the call and drops the message.
function debugNotices.ReagentDataStale()
    if not (model.IsReagentDataStale() and model.IsDebug()) then return end
    BitForge:Print(format(
        "reagent catalogue was built for interface %d; this client is newer,"
        .. " so recipes added since are missing from it",
        enum.REAGENT_DATA_INTERFACE))
end

control.debugNotices = debugNotices

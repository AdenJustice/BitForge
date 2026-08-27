---@type string, BitForge.EUI
local ADDON_NAME, ns = ...

-- Everything the player can change lives in SavedVariables. The module ships
-- no layout of its own, so an addon update cannot touch it -- that is the whole
-- reason the store exists: a layout kept in a source file is destroyed by the
-- next release.
--
-- Account-wide, matching the standalone addon this replaces. EllesmereUI has
-- its own profile system; a player running per-character EUI profiles gets one
-- BitForge layout seeded from whichever EUI profile was active. Recorded as a
-- known limitation in docs/eui-integration.md rather than fixed here.
local DB_DEFAULTS = {
    global = {
        -- Told apart from an empty layout: "never seeded" and "deliberately
        -- emptied" must not look the same, or the first login after a reset
        -- would re-seed instead of applying.
        seeded   = false,
        -- [key] = { point, relPoint, x, y, w, h, anchor = { target, side |
        --           point/relPoint, offsetX, offsetY } }
        layout   = {},
        -- [key] = { w, h, ... }. Virtual anchor frames. UNLIKE the layout this
        -- is irreplaceable: these exist only here and nothing in the game can
        -- re-derive them.
        anchors  = {},
        -- [key] = { point, relPoint, x, y }. What the resolver last wrote.
        -- Bookkeeping, not layout: it lives outside `layout` so the rule "every
        -- value is written where it is read" stays true of the layout. It is
        -- capture's only way to tell our own write from a user drag.
        resolved = {},
    },
}

local db
BitForge:AllocateModuleDB(ADDON_NAME, DB_DEFAULTS, function(moduleDB) db = moduleDB end)

---@class BitForge.EUI.Model
local model = ns.model

function model.IsSeeded() return db.global.seeded == true end
function model.SetSeeded() db.global.seeded = true end

function model.GetLayout() return db.global.layout end

function model.SetLayoutEntry(key, entry) db.global.layout[key] = entry end

--- Discard the layout. The next login re-seeds from EllesmereUI, so this costs
--- nothing permanent -- EUI still holds the real positions.
function model.WipeLayout()
    db.global.layout = {}
    db.global.seeded = false
    -- The bookkeeping describes writes made for a layout that no longer
    -- exists. Left behind, it would make the next capture misread a drag as
    -- our own write.
    db.global.resolved = {}
end

function model.GetAnchors() return db.global.anchors end
function model.SetAnchor(key, def) db.global.anchors[key] = def end

--- UNLIKE WipeLayout this is irreversible, which is why the command layer
--- confirms it separately.
function model.WipeAnchors() db.global.anchors = {} end

function model.GetResolved() return db.global.resolved end

function model.SetResolved(key, point, relPoint, x, y)
    db.global.resolved[key] = { point = point, relPoint = relPoint, x = x, y = y }
end

function model.ClearResolved(key) db.global.resolved[key] = nil end

--- Does this profile hold anything a reset would destroy? Only the anchors
--- qualify: a layout re-seeds itself from EllesmereUI on the next login, but an
--- anchor definition exists nowhere else and cannot be re-derived.
function model.HasData()
    return next(db.global.anchors) ~= nil
end

-- db.debug is the container core normalized, so the flag is .enabled inside it.
-- Never test the container itself for truth: any table is truthy.
function model.IsDebug()
    local diagnostics = db.debug
    return (diagnostics and diagnostics.enabled) == true
end

--- The dump table, or nil while diagnostics are off.
function model.GetDebugDump()
    local diagnostics = db.debug
    if not (diagnostics and diagnostics.enabled) then return nil end
    return diagnostics.dump
end

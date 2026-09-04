---@type string, BitForge.EUI
local ADDON_NAME, ns = ...

-- THE ONLY FILE THAT CALLS INTO EllesmereUI.
--
-- The NAME appears elsewhere -- in comments across the module and in
-- player-facing strings in every locale -- but the globals are reached from
-- here and nowhere else, and that is what the boundary is about.
--
-- Nearly every fact this module depends on about EUI's internals is one
-- function below, and each is numbered against docs/eui-integration.md. When
-- Scripts/track_eui.sh reports upstream movement, this file is where to look
-- first -- that correspondence is the reason the boundary exists.
--
-- THE QUARANTINE HOLDS FOR CALLS, NOT FOR SHAPE, and the difference is worth
-- being exact about rather than overclaiming. Positions, sizes, anchors and
-- registration all go through this file, and above it the module speaks one
-- shape: { key, point, relPoint, x, y, w, h, anchored }. But Elements() hands
-- back EllesmereUI's raw registry, and the entries in it are read BY FIELD NAME
-- elsewhere -- noAnchorTo, noAnchorTarget, noResize, getFrame, label, folder,
-- order. That gap is fact 9 -- and NO function below cites it: this mention
-- DESCRIBES the fact rather than depending on it, which is why the ledger
-- lists this file as citing it not at all. The citations are in
-- control/resolver.lua, control/control.lua and control/editor.lua, and a
-- rename upstream lands in those files while this one stays untouched. A review
-- that reads only this file has not covered it.

---@class BitForge.EUI.Control
local control = ns.control

---@class BitForge.EUI.Control.Adapters
local adapters = {}

--- Fact 1 (docs/eui-integration.md): the registry, not the addon table, is the
--- real readiness signal. `EllesmereUI` is created early in the suite's TOC
--- (EllesmereUI_Lite.lua, TOC line 23) and stands whether or not Unlock Mode's
--- registration API loaded behind it -- EUI_UnlockMode.lua is TOC line 50 and
--- is what creates the registry -- so reading only `EllesmereUI ~= nil` would
--- answer "present" while there is still nothing to read or write. The
--- registry is legitimately EMPTY, too -- EllesmereUI's own modules populate
--- it from their own init and their first PLAYER_ENTERING_WORLD -- so its
--- presence is the test and its contents never are.
---@return boolean
function adapters.IsPresent()
    return EllesmereUI ~= nil and EllesmereUI._unlockRegisteredElements ~= nil
end

--- Fact 1: the raw registry EllesmereUI's modules populate,
--- `EllesmereUI._unlockRegisteredElements`, keyed by element key. Every other
--- adapter in this file reads an entry out of this table rather than
--- maintaining a second list of its own.
---@return table|nil
function adapters.Elements()
    if not adapters.IsPresent() then return nil end
    return EllesmereUI._unlockRegisteredElements
end

--- Fact 2: positions are read through the element's own `loadPosition`, never
--- through EllesmereUIDB directly. Storage varies per module -- Unit Frames
--- writes `positions[key]`, Action Bars `barPositions[key]`, Raid Frames a
--- bare `unlockPos` -- and the element callback is what keeps this
--- storage-agnostic. Absent element or callback answers nil rather than
--- raising.
---@param key string
---@return table|nil  { point, x, y }
function adapters.ReadPosition(key)
    local elements = adapters.Elements()
    local element = elements and elements[key]
    if not (element and element.loadPosition) then return nil end

    local ok, position = xpcall(element.loadPosition, CallErrorHandler, key)
    if not ok then return nil end
    return position
end

--- Fact 2: sizes are read through the element's own `getSize`, for the same
--- storage-agnostic reason as ReadPosition. Absent element or callback
--- answers nil, nil rather than raising.
---@param key string
---@return number|nil width
---@return number|nil height
function adapters.ReadSize(key)
    local elements = adapters.Elements()
    local element = elements and elements[key]
    if not (element and element.getSize) then return nil, nil end

    local ok, width, height = xpcall(element.getSize, CallErrorHandler, key)
    if not ok then return nil, nil end
    return width, height
end

--- Fact 2: whether an element is currently on screen is read through the
--- element's own `isHidden`, for the same storage-agnostic reason as
--- ReadPosition. UNLIKE every other element callback in this file it takes no
--- key: EllesmereUI calls it as `elem.isHidden()` throughout
--- (EUI_UnlockMode.lua:6375, 7588, 10112, 12355) and its modules define it as a
--- closure over the element they registered. Passing a key would be harmless
--- today and wrong the moment one of them starts reading its first argument.
--- Absent element or callback answers false -- an element that never says it is
--- hidden is shown.
---@param key string
---@return boolean
function adapters.IsHidden(key)
    local elements = adapters.Elements()
    local element = elements and elements[key]
    if not (element and element.isHidden) then return false end

    local ok, hidden = xpcall(element.isHidden, CallErrorHandler)
    return (ok and hidden) == true
end

--- Fact 3: positions are written through the element's own `savePosition`,
--- never through EllesmereUIDB directly. Two setters have side effects a
--- direct write would skip -- Action Bars' `savePosition` transforms the value
--- on the way in for some inputs and not others, and Unit Frames' chains
--- boss2-boss5 off boss1. Returns false when the element or callback is
--- absent, or when the call raised.
---@param key string
---@param point string
---@param relPoint string
---@param x number
---@param y number
---@return boolean  true when a write happened
function adapters.WritePosition(key, point, relPoint, x, y)
    local elements = adapters.Elements()
    local element = elements and elements[key]
    if not (element and element.savePosition) then return false end

    local ok = xpcall(element.savePosition, CallErrorHandler, key, point, relPoint, x, y)
    return ok == true
end

--- Fact 3: sizes are written through the element's own `setWidth`/`setHeight`,
--- for the same reason as WritePosition. Both are attempted so a caller need
--- not know which dimension changed; either missing callback simply skips its
--- half of the write. Returns false when neither write happened.
---@param key string
---@param width number
---@param height number
---@return boolean  true when at least one dimension was written
function adapters.WriteSize(key, width, height)
    local elements = adapters.Elements()
    local element = elements and elements[key]
    if not element then return false end

    local wrote = false

    if element.setWidth then
        local ok = xpcall(element.setWidth, CallErrorHandler, key, width)
        wrote = wrote or (ok == true)
    end

    if element.setHeight then
        local ok = xpcall(element.setHeight, CallErrorHandler, key, height)
        wrote = wrote or (ok == true)
    end

    return wrote
end

--- Fact 3: `savePosition` is not guaranteed to move the frame. Some of
--- EllesmereUI's implementations record and stop; others record and then
--- reposition, gated on `_unlockActive` rather than the flag RunApplying sets,
--- so they reposition in exactly our case. A caller cannot tell which it has,
--- so this runs after every WritePosition -- as EllesmereUI's own layer flush
--- does. Skipping it leaves any element that does not self-reposition with a
--- correct database and a stale screen.
--- Returns false when the element or callback is absent, or when the call
--- raised.
---@param key string
---@return boolean  true when a write happened
function adapters.ApplyPosition(key)
    local elements = adapters.Elements()
    local element = elements and elements[key]
    if not (element and element.applyPosition) then return false end

    local ok = xpcall(element.applyPosition, CallErrorHandler, key)
    return ok == true
end

--- Fact 4: an EllesmereUI size setter may gate on
--- `EllesmereUI._unlockLayerApplying` and drop the write outside Unlock Mode,
--- silently. Unit Frames is the only module doing so at the pinned commit, but
--- the flag is set for EVERY size write regardless: it is the suite's
--- sanctioned mechanism rather than that one module's private habit, and which
--- modules gate is a per-release detail this file must not encode. EUI's own
--- spec-override flush sets exactly this flag to get its size writes past the
--- gate, and this is the same mechanism used on our behalf.
---
--- The flag is cleared on EVERY path, including a raise inside `body` -- an
--- error that skipped the clear would leave every later size write in the
--- session silently dropped by EUI's gate, which is worse than the error
--- itself. xpcall, not pcall: the handler must run at the raise, where the
--- caller's locals and the element's frame are still live, so BugGrabber
--- captures a real stack.
---@param body function
---@param ... any  forwarded to body
function adapters.RunApplying(body, ...)
    if not adapters.IsPresent() then
        xpcall(body, CallErrorHandler, ...)
        return
    end

    EllesmereUI._unlockLayerApplying = true
    xpcall(body, CallErrorHandler, ...)
    EllesmereUI._unlockLayerApplying = nil
end

--- Fact 5: an anchor is central and flat, one shape for every element, with no
--- per-module setter to route through -- so `EllesmereUI.IsUnlockAnchored` is
--- the documented exception to "always go through the element".
---@param key string
---@return boolean
function adapters.IsAnchored(key)
    if not (EllesmereUI and EllesmereUI.IsUnlockAnchored) then return false end
    -- Dot-defined, so no self is threaded through.
    local ok, anchored = xpcall(EllesmereUI.IsUnlockAnchored, CallErrorHandler, key)
    return ok and anchored == true
end

--- Fact 5: `EllesmereUIDB.unlockAnchors[key]` is read directly, the same
--- documented exception as IsAnchored.
---@param key string
---@return table|nil  { target, side, offsetX, offsetY }
function adapters.ReadAnchor(key)
    if not (EllesmereUIDB and EllesmereUIDB.unlockAnchors) then return nil end
    return EllesmereUIDB.unlockAnchors[key]
end

--- Fact 5: the whole of `EllesmereUIDB.unlockAnchors`, the same documented
--- exception as ReadAnchor, for callers that must walk every EllesmereUI-native
--- anchor rather than look one up by key. The resolver's cycle detection is
--- the reason this exists: a cycle can close through an anchor EllesmereUI
--- owns and our own layout never mentions, and that edge is invisible to a
--- walk that only knows the per-key lookup. Answers an empty table rather
--- than nil when EllesmereUI or its database is absent, so the caller can
--- iterate unconditionally.
---@return table  [key] = { target, side, offsetX, offsetY }
function adapters.AllAnchors()
    if not (EllesmereUIDB and EllesmereUIDB.unlockAnchors) then return {} end
    return EllesmereUIDB.unlockAnchors
end

--- Fact 5: `EllesmereUIDB.unlockAnchors[key]` is written directly, the same
--- documented exception as IsAnchored and ReadAnchor. Returns false when
--- EllesmereUI is not present -- there is no table to write into.
---@param key string
---@param def table|nil  { target, side, offsetX, offsetY }, nil to remove
---@return boolean  true when a write happened
function adapters.WriteAnchor(key, def)
    if not EllesmereUIDB then return false end
    EllesmereUIDB.unlockAnchors = EllesmereUIDB.unlockAnchors or {}
    EllesmereUIDB.unlockAnchors[key] = def
    return true
end

--- Fact 5: without a forced re-anchor pass after an anchor changes, anchored
--- frames sit at stale coordinates until something else nudges them -- a
--- visible jump later instead of now.
function adapters.ReapplyAnchors()
    if not (EllesmereUI and EllesmereUI.ReapplyAllUnlockAnchorsForced) then return end
    xpcall(EllesmereUI.ReapplyAllUnlockAnchorsForced, CallErrorHandler)
end

--- Fact 7: EllesmereUI resolves an anchor's target by KEY, through
--- `registeredElements[target].getFrame(target)` -- never by frame name or
--- object -- so a virtual anchor frame has to become a real registered element
--- to be a legal target. Built via `MakeUnlockElement` and registered via
--- `RegisterUnlockElements`, exactly as EUI's own modules register.
---
--- `getFrame` takes its own key at EVERY upstream site
--- (`EUI_UnlockMode.lua:106-107`, `:208`, `:4681`, `:4797`, `:10796`), and this
--- module's own two call sites -- control/resolver.lua's target lookup and
--- control/sync.lua's centre measurement -- pass it. UNLIKE `isHidden` above,
--- which really does take none: the difference is upstream's, not a style
--- choice, and the argument is dropped here only because the frame this
--- particular element wraps is already closed over.
---
--- The registry is shared and the write is unconditional, so registering over
--- a key EllesmereUI already owns would replace a real element and break its
--- mover. Nothing here can tell the difference, which is why
--- control.resolver.ValidateAnchorDef refuses the collision before a key ever
--- reaches this function.
---
--- Deliberately exposes no `savePosition`/`loadPosition`: both of EUI's save
--- sites are guarded by `if elem and elem.savePosition then`, so a drag in
--- Unlock Mode has nowhere to persist to rather than half-working.
---@param key string
---@param frame table  the frame the caller positions and sizes
---@param label string
function adapters.RegisterAnchorFrame(key, frame, label)
    if not (EllesmereUI and EllesmereUI.MakeUnlockElement and EllesmereUI.RegisterUnlockElements) then
        return
    end

    -- Dot-defined (EllesmereUI.lua:5649): one argument, no self. A leading
    -- self here would bind `opts` to the whole framework table and silently
    -- discard the real options table.
    local ok, element = xpcall(EllesmereUI.MakeUnlockElement, CallErrorHandler, {
        key      = key,
        label    = label,
        group    = ADDON_NAME,
        getFrame = function() return frame end,
        getSize  = function() return frame:GetWidth(), frame:GetHeight() end,
    })
    if not ok then return end

    -- Colon-defined, so self is threaded through explicitly.
    xpcall(EllesmereUI.RegisterUnlockElements, CallErrorHandler, EllesmereUI, { element }, ADDON_NAME)
end

--- Fact 8: `_NotifyUnlockModeListeners` calls each listener inside
--- EllesmereUI's own pcall, which unwinds the stack before anything could be
--- reported -- an error raised in `handler` would otherwise be swallowed and
--- never reach BugGrabber. The listener body runs under our own xpcall
--- instead, which is why the wrapping happens here rather than being left to
--- EUI's pcall.
---@param handler fun(active: boolean, closeAction: string|nil)
function adapters.OnUnlockMode(handler)
    if not (EllesmereUI and EllesmereUI.RegisterUnlockModeListener) then return end

    local function wrapped(...)
        return xpcall(handler, CallErrorHandler, ...)
    end

    -- Colon-defined, so self is threaded through explicitly.
    xpcall(EllesmereUI.RegisterUnlockModeListener, CallErrorHandler, EllesmereUI, ADDON_NAME, wrapped)
end

-- Not one of the numbered facts above -- RegisterSkin is the suite's own
-- skinning API (SKINNING_API.md), separate from the Unlock Mode registry.
-- Registered under this module's own folder name rather than core's, so
-- EllesmereUI's per-addon toggle covers the editor window alone. Built here,
-- not in view/editor.lua, because this file is the suite's only point of
-- contact with EllesmereUI -- registering there would put the host addon's
-- name outside it.
local skinBridge = BitForge.UI.NewSkinBridge()

if EllesmereUI and EllesmereUI.RegisterSkin then
    EllesmereUI.RegisterSkin(ADDON_NAME, skinBridge.Deliver)
end

--- Hands the editor window's facade to `handler`, now or whenever the host
--- answers -- view/editor.lua's build() calls this instead of reaching
--- BitForge.UI.Skin directly, keeping the host addon's name inside this file.
---@param handler fun(facade: table)
function adapters.OnSkin(handler)
    skinBridge.OnSkin(handler)
end

control.adapters = adapters

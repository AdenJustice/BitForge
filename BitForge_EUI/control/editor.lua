---@type string, BitForge.EUI
local ADDON_NAME, ns = ...

---@class BitForge.EUI.Control
local control = ns.control
---@type BitForge.EUI.Model
local model = ns.model
---@type BitForge.EUI.Locale
local locale = ns.locale
---@type BitForge.EUI.Enum
local enum = ns.enum

---@type BitForge.EUI.Control.Adapters
local adapters = control.adapters
---@type BitForge.EUI.Control.Resolver
local resolver = control.resolver

local format = string.format

-- Ports the standalone addon's Core/Rows.lua (the list model) and Core/Edit.lua
-- (the pending-edit buffer and the detail pane's view-model).
--
-- EVERY decision the editor makes lives here: what a row is, in what order,
-- which markers it carries, what the form shows for a key, what a save would
-- write, and what refuses it. Nothing in view/ branches on element state, which
-- is what makes the editor testable at all -- a widget is only reachable
-- through the frame it built.
--
-- This file is also where the two storage shapes are reconciled. A screen
-- position stores x/y; an element anchor stores offsetX/offsetY. The form has
-- one pair of number boxes, and the mapping between them lives here so no
-- widget has to know it.

-- Our own anchor frames are their own group, listed after every EllesmereUI
-- folder. EllesmereUI stamps `folder` from RegisterUnlockElements' second
-- argument (EUI_UnlockMode.lua:39), which adapters.RegisterAnchorFrame passes
-- ADDON_NAME, so a registered anchor frame already reports this folder and the
-- two halves cannot drift apart.
local ANCHOR_FOLDER = ADDON_NAME

-- The key a new anchor frame is drafted under. The empty string IS the absence
-- of a key, which is precisely what Validate refuses until the player types
-- one -- a draft parked under an invented placeholder could be saved by
-- accident, and would register under the placeholder.
local DRAFT_KEY = ""

-- A missing `order` sorts after every element that has one, rather than ahead
-- of order 0. EllesmereUI leaves it unset on elements it does not care to
-- position within their module.
local NO_ORDER = math.huge

-- Unique sentinel: "explicitly cleared" is not the same as "not edited", and
-- nil cannot express the difference in a table. The target dropdown's Screen
-- entry is what needs it -- picking Screen means "this entry has no anchor",
-- which a stored nil would read as "the player did not touch the target".
local NONE = {}

-- What a new anchor frame starts as. Sized rather than empty: an anchor with no
-- size has no resolvable edges and ValidateAnchorDef refuses it outright, so a
-- sizeless draft would open on a form that cannot be saved and would not say
-- why until Save was pressed.
local ANCHOR_DEFAULTS = {
    w = 100, h = 100, point = "CENTER", relPoint = "CENTER", x = 0, y = 0,
}

-- The fields a pending edit may carry, per store. Listed rather than copied
-- wholesale so a field the form does not own -- `delete`, `anchorKey` -- can
-- never reach the saved shape as a stray key.
local ANCHOR_FIELDS = { "point", "relPoint", "x", "y", "w", "h", "label" }

-- A canonical pair for the target probe below. Legality does not depend on
-- WHICH pair is chosen -- only on it being a valid one -- and CENTER over
-- CENTER is the pair EllesmereUI itself uses when no side is set.
local PROBE_POINT, PROBE_RELPOINT = "CENTER", "CENTER"

-- Reading order, not alphabetical: these are positions on a rectangle, and a
-- menu running BOTTOM, BOTTOMLEFT, BOTTOMRIGHT, CENTER makes the player
-- translate. Filtered through enum.ANCHOR_POINTS so this list can only ever
-- offer points SetPoint accepts -- one set of legal names, ordered here.
local POINT_ORDER = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}
local ANCHOR_POINTS = {}
for _, point in ipairs(POINT_ORDER) do
    if enum.ANCHOR_POINTS[point] then
        ANCHOR_POINTS[#ANCHOR_POINTS + 1] = point
    end
end

-- [key] = { [field] = value }. Nothing a player types reaches the saved layout
-- until Commit; until then it lives here, and every read below goes through the
-- composers so the form shows the edit rather than the value it will replace.
local pending = {}

-- Bumped by every mutator. The target dropdown is expensive to regenerate --
-- Targets walks the anchor graph once per candidate -- and it must not be
-- rebuilt on every keystroke in the search box. A caller that remembers this
-- number knows whether anything it derived from the buffer is still valid,
-- without guessing.
local generation = 0

---@param source table|nil
---@return table
local function shallowCopy(source)
    local copy = {}
    for key, value in pairs(source or {}) do copy[key] = value end
    return copy
end

---@param text any
---@return string
local function lower(text)
    return string.lower(tostring(text or ""))
end

---@param filter string|nil  already lowercased
---@param key string
---@param label string
---@return boolean
local function matches(filter, key, label)
    if filter == nil then return true end
    return string.find(lower(key), filter, 1, true) ~= nil
        or string.find(lower(label), filter, 1, true) ~= nil
end

--- Which store a key belongs to. An anchor key and an element key can never
--- collide -- ValidateAnchorDef refuses a definition that would register over a
--- live element -- so the key alone answers this, and no caller has to hand the
--- buffer a kind it could get wrong.
---@param key string
---@return boolean
local function isAnchorKey(key)
    return key == DRAFT_KEY or model.GetAnchors()[key] ~= nil
end

--- The key a pending anchor row would be SAVED under: what the player typed
--- into it, or the row's own key when nothing was typed.
---
--- One notion, whatever the row: a draft naming itself and an existing anchor
--- being renamed are the same question, and Validate refuses both when the
--- answer lands on a key another definition already holds. The form only offers
--- the key box on a draft -- an existing anchor's key is its identity in
--- EllesmereUI's registry, and moving it orphans every layout entry that
--- targets it -- but the rule that protects the definition itself lives here
--- rather than in a disabled widget.
---@param key string
---@return string
local function nextAnchorKey(key)
    local fields = pending[key]
    local typed = fields and fields.anchorKey
    if typed == nil then return key end
    return (tostring(typed):gsub("^%s*(.-)%s*$", "%1"))
end

--- The anchor definition as it will be: the stored one -- or the draft's
--- defaults -- with every pending field laid over it.
---@param key string
---@return table
local function nextAnchorDef(key)
    local stored = model.GetAnchors()[key]
    local def = shallowCopy(type(stored) == "table" and stored or ANCHOR_DEFAULTS)

    local fields = pending[key]
    if fields then
        for _, field in ipairs(ANCHOR_FIELDS) do
            local value = fields[field]
            if value ~= nil then
                def[field] = value ~= NONE and value or nil
            end
        end
    end

    return def
end

--- The layout entry as it will be: the stored one with every pending field laid
--- over it, in storage shape.
---
--- Where a number lands depends on whether the entry carries an anchor, which
--- is why the target is applied first: a screen position stores x/y and an
--- element anchor stores offsetX/offsetY, and the form has one pair of boxes
--- for both.
---
--- Copies rather than mutating in place: the stored entry is the database's own
--- table, and editing it directly would write through with no Save.
---@param key string
---@return table
local function nextEntry(key)
    local stored = model.GetLayout()[key]
    local entry = shallowCopy(type(stored) == "table" and stored or nil)
    if type(entry.anchor) == "table" then entry.anchor = shallowCopy(entry.anchor) end

    local fields = pending[key]
    if not fields then return entry end

    if fields.target ~= nil then
        if fields.target == NONE then
            entry.anchor = nil
        else
            local anchor = entry.anchor or {}
            anchor.target = fields.target
            anchor.point = anchor.point or entry.point or "CENTER"
            anchor.relPoint = anchor.relPoint or entry.relPoint or "CENTER"
            anchor.offsetX = anchor.offsetX or 0
            anchor.offsetY = anchor.offsetY or 0
            entry.anchor = anchor
            -- Coordinates belong to the anchor now; leaving them behind would
            -- be two sources of truth for one position.
            entry.point, entry.relPoint, entry.x, entry.y = nil, nil, nil, nil
        end
    end

    local anchor = entry.anchor
    if fields.point ~= nil then
        if anchor then anchor.point = fields.point else entry.point = fields.point end
    end
    if fields.relPoint ~= nil then
        if anchor then anchor.relPoint = fields.relPoint else entry.relPoint = fields.relPoint end
    end
    if fields.x ~= nil then
        if anchor then anchor.offsetX = fields.x else entry.x = fields.x end
    end
    if fields.y ~= nil then
        if anchor then anchor.offsetY = fields.y else entry.y = fields.y end
    end
    if fields.w ~= nil then entry.w = fields.w end
    if fields.h ~= nil then entry.h = fields.h end

    return entry
end

--- The screen position for one key, field by field: the entry's own value where
--- it carries one, the element's own live position where it does not.
---
--- PER FIELD, not all or nothing, because the form and the commit both read
--- this and they must not disagree. Typing into one box composes an entry
--- carrying that axis alone; an all-or-nothing fallback would answer 0 for the
--- other axis the instant the first was touched -- repainting a value the
--- player never edited, and storing a different one than the form last showed.
---
--- CENTER/0/0 is the last resort and nothing more: it is reached only for an
--- element EllesmereUI has stored no position for at all. The layout stays
--- literal -- every value is written where it is read -- because Commit writes
--- exactly what this returns, from this same function.
---@param key string
---@param entry table  the composed entry, with any anchor already resolved away
---@return string point
---@return string relPoint
---@return number x
---@return number y
local function screenPosition(key, entry)
    -- Nothing to fall back to, so nothing to ask the element. Worth the early
    -- return: the target dropdown's per-candidate isSelected calls Detail once
    -- for every registered element, and there are roughly seventy of them.
    if entry.point and entry.x and entry.y then
        return entry.point, entry.relPoint or entry.point, entry.x, entry.y
    end

    local live = adapters.ReadPosition(key) or {}
    local point = entry.point or live.point or "CENTER"
    return point,
        entry.relPoint or entry.point or live.relPoint or point,
        entry.x or live.x or 0,
        entry.y or live.y or 0
end

--- Write the whole triple into an entry that carries only part of one.
---
--- An entry composed from a single edited box is a partial position, and
--- control/sync.lua fills the gaps at apply time with CENTER/0/0 -- so editing
--- one axis would invent the other and move the frame. Completing it here, from
--- what the form showed, is what keeps the two ends honest.
---@param key string
---@param entry table  mutated in place
local function completeScreenPosition(key, entry)
    local point, relPoint, x, y = screenPosition(key, entry)
    entry.point, entry.x, entry.y = point, x, y
    -- Only when it genuinely differs, the same convention control/sync.lua's
    -- capture writes: applying falls back to point when relPoint is absent, so
    -- a matching pair is stored once rather than twice.
    entry.relPoint = (relPoint ~= point) and relPoint or nil
end

--- Every saved anchor definition with the buffer laid over it. The draft is
--- deliberately absent: it has no key yet, so it has no row -- the
--- "+ New anchor frame" row is the way back to it until it is saved.
---@return table  [key] = def
local function nextAnchors()
    local anchors = {}
    for key, def in pairs(model.GetAnchors()) do anchors[key] = def end

    for key, fields in pairs(pending) do
        if key ~= DRAFT_KEY and isAnchorKey(key) then
            if fields.delete then
                anchors[key] = nil
            else
                local savedKey = nextAnchorKey(key)
                -- A row typed blank has no key to be listed under -- Validate
                -- refuses it -- so it keeps its place under the one it still
                -- has. A row that changed key MOVES: listing it under both
                -- would show two definitions where the player edited one.
                if savedKey == DRAFT_KEY then savedKey = key end
                if savedKey ~= key then anchors[key] = nil end
                anchors[savedKey] = nextAnchorDef(key)
            end
        end
    end

    return anchors
end

---@class BitForge.EUI.Control.Editor
local editor = {}

editor.NONE = NONE

editor.DRAFT_KEY = DRAFT_KEY

---@return table
function editor.AnchorPoints()
    return ANCHOR_POINTS
end

---@return number
function editor.Generation()
    return generation
end

--- Hold one field of one key's edit. Nothing reaches the database until Commit.
---@param key string
---@param field string
---@param value any  editor.NONE to clear the field
function editor.SetPending(key, field, value)
    if key == nil or field == nil then return end

    local fields = pending[key]
    if not fields then
        fields = {}
        pending[key] = fields
    end

    fields[field] = value
    generation = generation + 1
end

--- A copy of the buffer: { [key] = { [field] = value } }. A copy rather than
--- the buffer itself -- every edit goes through SetPending, and handing out the
--- live table is an invitation to write round it.
---@return table
function editor.GetPending()
    local copy = {}
    for key, fields in pairs(pending) do copy[key] = shallowCopy(fields) end
    return copy
end

--- How many field edits are held. Counted per field rather than per key:
--- moving one element left and up is two changes to the player who made them.
---@return number
function editor.PendingCount()
    local count = 0
    for _, fields in pairs(pending) do
        for _ in pairs(fields) do count = count + 1 end
    end
    return count
end

function editor.Revert()
    pending = {}
    generation = generation + 1
end

--- Everything pending, laid over the stored layout: what Commit would write.
--- The target list and validation both need the anchor graph as it WILL be,
--- not as it is.
---@return table
function editor.ProspectiveLayout()
    local prospective = {}
    for key, entry in pairs(model.GetLayout()) do prospective[key] = entry end

    for key in pairs(pending) do
        if not isAnchorKey(key) then prospective[key] = nextEntry(key) end
    end

    return prospective
end

--- The flat row list the scroll box renders, in order.
---
--- A pure projection: the live EllesmereUI registry, plus the saved layout,
--- plus the buffer, plus a small view state in -- rows out. Reads the registry
--- and NEVER EllesmereUI's SavedVariables, which record only elements that have
--- been moved: reading those would hide exactly the elements the player has
--- never positioned, which are the ones they most need to find.
---
--- Rows describe the layout as it WILL be, so a marker follows the edit that
--- changed it rather than waiting for a save.
---@param state table|nil  { collapsed = { [folder] = true }, filter = string }
---@return table  { { kind, key, folder, label, unmanaged, attachedEui,
---                   attachedBitForge, hidden }, ... }
function editor.BuildRows(state)
    state = state or {}
    local collapsed = state.collapsed or {}
    local filter = state.filter and lower(state.filter) or nil
    if filter == "" then filter = nil end

    local elements = adapters.Elements()
    if not elements then return {} end

    local layout = editor.ProspectiveLayout()
    local anchors = nextAnchors()

    -- Bucket by folder. An element registered without one is grouped under its
    -- own key rather than dropped: EllesmereUI stamps folder from the call site
    -- and only a caller that passed none can leave it nil, but a missing
    -- element is worse than an odd heading.
    --
    -- `folder`, `label` and `order` below are read by name off the registry
    -- entry adapters.Elements() hands back -- fact 9, docs/eui-integration.md,
    -- the fact about the entry's shape rather than about a call, so nothing in
    -- adapters.lua stands in front of them. `order` is this list's primary sort
    -- key, and a rename of it upstream would silently reorder the whole editor
    -- rather than raise.
    local byFolder = {}
    for key, element in pairs(elements) do
        -- Our own anchor frames arrive through the registry too, once
        -- BuildAnchorFrames has registered them. They are listed from their
        -- saved definitions below instead, so they are skipped here rather than
        -- appearing twice.
        if anchors[key] == nil then
            local folder = element.folder or key
            local label = element.label or key
            if matches(filter, key, label) then
                local entry = layout[key]
                local channel = resolver.Channel(key, entry)
                local bucket = byFolder[folder]
                if not bucket then
                    bucket = {}
                    byFolder[folder] = bucket
                end
                bucket[#bucket + 1] = {
                    kind             = "element",
                    key              = key,
                    label            = label,
                    folder           = folder,
                    order            = element.order or NO_ORDER,
                    unmanaged        = entry == nil,
                    attachedEui      = channel == "eui",
                    attachedBitForge = channel == "bitforge",
                    hidden           = adapters.IsHidden(key),
                }
            end
        end
    end

    -- Anchor frames come from the saved definitions, not from the registry: one
    -- BuildAnchorFrames refused never registers at all, and a definition the
    -- editor cannot show is one the player cannot repair. Anything the registry
    -- stamped with our folder and the definitions no longer mention keeps its
    -- place in the same bucket.
    local anchorBucket = byFolder[ANCHOR_FOLDER] or {}
    byFolder[ANCHOR_FOLDER] = nil
    for key, def in pairs(anchors) do
        local label = (type(def) == "table" and def.label) or key
        if matches(filter, key, label) then
            anchorBucket[#anchorBucket + 1] = {
                kind             = "anchor",
                key              = key,
                label            = label,
                folder           = ANCHOR_FOLDER,
                order            = NO_ORDER,
                -- An anchor frame is not a layout entry and is positioned by
                -- its own definition, so neither marker can apply to it.
                unmanaged        = false,
                attachedEui      = false,
                attachedBitForge = false,
                hidden           = false,
            }
        end
    end

    local folders = {}
    for folder in pairs(byFolder) do folders[#folders + 1] = folder end
    table.sort(folders)

    -- Ours last, and offered even when it is empty: it is where "+ New" lives,
    -- and a player with no anchors yet is exactly who needs to find it.
    -- Alphabetically it would sort near the top and drop a creation button into
    -- the middle of the list.
    if #anchorBucket > 0 or matches(filter, ANCHOR_FOLDER, locale["ui:anchorGroup"]) then
        byFolder[ANCHOR_FOLDER] = anchorBucket
        folders[#folders + 1] = ANCHOR_FOLDER
    end

    local rows = {}
    for _, folder in ipairs(folders) do
        local bucket = byFolder[folder] or {}
        table.sort(bucket, function(first, second)
            if first.order ~= second.order then return first.order < second.order end
            if first.label ~= second.label then return first.label < second.label end
            return first.key < second.key
        end)

        -- A filter force-expands: the player searched precisely because
        -- scrolling was not finding it, so a collapsed group swallowing the hit
        -- is a bug.
        local isCollapsed = filter == nil and collapsed[folder] == true

        rows[#rows + 1] = {
            kind      = "group",
            folder    = folder,
            label     = (folder == ANCHOR_FOLDER) and locale["ui:anchorGroup"] or folder,
            count     = #bucket,
            collapsed = isCollapsed,
        }

        if not isCollapsed then
            for _, row in ipairs(bucket) do
                row.order = nil    -- a sort key, not something a widget should read
                rows[#rows + 1] = row
            end
            if folder == ANCHOR_FOLDER then
                rows[#rows + 1] = {
                    kind   = "newanchor",
                    folder = ANCHOR_FOLDER,
                    label  = locale["ui:anchorNew"],
                }
            end
        end
    end

    return rows
end

--- Everything the form needs about one key, with the buffer already laid over
--- the store, or nil when the key stopped existing under the pane.
---@param key string
---@return table|nil
function editor.Detail(key)
    if isAnchorKey(key) then
        local def = nextAnchorDef(key)
        local savedKey = nextAnchorKey(key)

        local shown = {
            key       = key,
            kind      = "anchor",
            isDraft   = key == DRAFT_KEY,
            anchorKey = savedKey,
            label     = def.label,
            unmanaged = false,
            target    = nil,
            point     = def.point or "CENTER",
            relPoint  = def.relPoint or def.point or "CENTER",
            x         = def.x or 0,
            y         = def.y or 0,
            w         = def.w,
            h         = def.h,
            -- Ours are positioned by their own definition and nothing else, so
            -- EllesmereUI must not re-anchor them -- which is why
            -- adapters.RegisterAnchorFrame registers them with no savePosition.
            -- Resizing them is what the w/h fields are for.
            channel     = "screen",
            canAnchorTo = false,
            noteKey     = "reason:noanchor",
            canResize   = true,
            hidden      = false,
        }

        -- The same verdict BuildAnchorFrames would reach, so the form shows the
        -- refusal /bitforge eui apply prints rather than saving a definition
        -- that silently never appears. A draft with no key yet is not a
        -- refusal to show -- it is simply unfinished, and Validate says so.
        if savedKey ~= DRAFT_KEY then
            local ok, localeKey, arg = resolver.ValidateAnchorDef(savedKey, def)
            if not ok then
                shown.refusal = { key = savedKey, localeKey = localeKey, arg = arg }
            end
        end

        return shown
    end

    local elements = adapters.Elements()
    local element = elements and elements[key]
    if not element then return nil end

    local entry = nextEntry(key)
    local anchor = entry.anchor
    -- noAnchorTo and noResize are read by name off the registry entry (fact 9,
    -- docs/eui-integration.md). Both are computed at registration for some
    -- modules and recomputed on every re-registration, so they are read live
    -- here rather than captured anywhere.
    local shown = {
        key         = key,
        kind        = "element",
        unmanaged   = model.GetLayout()[key] == nil and pending[key] == nil,
        canAnchorTo = not element.noAnchorTo,
        canResize   = not element.noResize,
        hidden      = adapters.IsHidden(key),
    }

    -- One note line, showing WHY something is unavailable rather than hiding
    -- it. Hidden outranks the rest: an element that is not on screen is the
    -- first thing to explain about a form that appears to do nothing.
    if shown.hidden then
        shown.noteKey = "ui:hiddenNote"
    elseif not shown.canAnchorTo then
        shown.noteKey = "reason:noanchor"
    elseif not shown.canResize then
        shown.noteKey = "ui:noResize"
    end

    if anchor and anchor.target then
        shown.target = anchor.target
        -- The name the dropdown offered, so the collapsed control reads the
        -- same as the menu it was picked from. Falls back to the key, which is
        -- what a target whose element has since unregistered still has.
        local targetElement = elements[anchor.target]
        shown.targetLabel = (targetElement and targetElement.label) or anchor.target
        shown.point = anchor.point or "CENTER"
        shown.relPoint = anchor.relPoint or "CENTER"
        shown.x = anchor.offsetX or 0
        shown.y = anchor.offsetY or 0
    else
        -- Screen. Falls back to the element's own live position so the form
        -- opens on the truth rather than on zeros -- display only; nothing is
        -- stored until the player edits and saves. Never a derived default:
        -- the layout is literal, every value is written where it is read, and
        -- an entry that invented one would put a defaults layer behind the
        -- store's back. Commit writes exactly these values, from this same
        -- function, so the form and the store cannot disagree.
        shown.point, shown.relPoint, shown.x, shown.y = screenPosition(key, entry)
    end

    -- The stored size if the layout carries one, the live size otherwise, so
    -- the boxes are never blank on an element that has a size.
    if entry.w or entry.h then
        shown.w, shown.h = entry.w, entry.h
    else
        shown.w, shown.h = adapters.ReadSize(key)
    end

    shown.channel = resolver.Channel(key, entry) or "screen"
    if shown.channel == "eui" and anchor then
        if anchor.point and anchor.relPoint then
            shown.side = resolver.PairToSide(anchor.point, anchor.relPoint)
        else
            shown.side = anchor.side
        end
    end

    return shown
end

--- Every element `key` may legally anchor to, sorted for display.
---
--- Probes FindBadAnchors rather than re-deriving the rules. The dropdown must
--- offer exactly what a login accepts: two implementations of "is this anchor
--- legal" would drift, and the drift would present as an editor that cheerfully
--- saves an anchor the next login refuses. This way noAnchorTarget, noAnchorTo,
--- self-anchoring, unknown targets and cycle detection all come for free.
---
--- Screen is NOT in this list. It is not an element, and the dropdown adds it
--- as its own first entry.
---@param key string
---@return table  { { key, label, folder }, ... }
function editor.Targets(key)
    local elements = adapters.Elements()
    if not elements then return {} end

    local probe = editor.ProspectiveLayout()
    local saved = probe[key]
    local targets = {}

    -- No `candidate ~= key` guard: FindBadAnchors already answers that with its
    -- `self` reason, and a local short-circuit here would be a second
    -- implementation of the one rule this function exists to avoid duplicating.
    for candidate, element in pairs(elements) do
        probe[key] = { anchor = {
            target = candidate, point = PROBE_POINT, relPoint = PROBE_RELPOINT,
        } }

        local rejected = false
        for _, bad in ipairs(resolver.FindBadAnchors(probe)) do
            if bad.key == key then
                rejected = true
                break
            end
        end

        if not rejected then
            targets[#targets + 1] = {
                key    = candidate,
                label  = element.label or candidate,
                folder = element.folder or "",
            }
        end
    end

    -- The probe table is a local copy, but leaving it consistent costs nothing
    -- and stops a future caller reusing it wrong.
    probe[key] = saved

    table.sort(targets, function(first, second)
        if first.folder ~= second.folder then return first.folder < second.folder end
        if first.label ~= second.label then return first.label < second.label end
        return first.key < second.key
    end)
    return targets
end

--- Everything wrong with what Commit would write, as values.
---
--- Only keys the buffer touched. A pre-existing bad anchor -- a hand-edit, or
--- an element whose module has since been disabled -- is Apply's business and
--- is already reported at login; blocking every save until unrelated stored
--- data is repaired would make the editor useless for the one job it has.
---@return table  { { key, localeKey, arg?, target? }, ... } sorted by key
function editor.Validate()
    local problems = {}

    for key, fields in pairs(pending) do
        if isAnchorKey(key) and not fields.delete then
            local savedKey = nextAnchorKey(key)
            if savedKey == DRAFT_KEY then
                problems[#problems + 1] = { key = key, localeKey = "ui:anchorKeyEmpty" }
            elseif savedKey ~= key and model.GetAnchors()[savedKey] ~= nil then
                -- The row would land on a definition it did not start from --
                -- a draft named after an existing anchor, or one anchor
                -- renamed onto another. Either way the definition already
                -- there is destroyed, and UNLIKE the delete path, which
                -- confirms first, nothing on this one would ask: an anchor
                -- exists only in our SavedVariables and nothing in the game
                -- can re-derive it.
                --
                -- resolver.ValidateAnchorDef cannot answer this. Its collision
                -- check treats an existing virtual frame at the key as our own
                -- from an earlier build, which is exactly what makes
                -- BuildAnchorFrames idempotent -- at that layer a rebuild and a
                -- creation over one are identical. Only the editor knows which
                -- the player meant.
                --
                -- Outranks the definition check below rather than joining it:
                -- the key is the identity, and nothing about the rest of a
                -- definition matters while it is pointed at someone else's.
                problems[#problems + 1] = { key = savedKey, localeKey = "ui:anchorKeyTaken" }
            else
                local ok, localeKey, arg = resolver.ValidateAnchorDef(savedKey, nextAnchorDef(key))
                if not ok then
                    problems[#problems + 1] = { key = savedKey, localeKey = localeKey, arg = arg }
                end
            end
        end
    end

    -- The same check the login runs, over the layout as it will be.
    --
    -- Narrowed to keys the buffer touched, for the reason at the top of this
    -- function: a pre-existing bad anchor is Apply's business, already reported
    -- at login, and blocking every save until unrelated stored data is repaired
    -- would make the editor useless.
    --
    -- WHAT IT COSTS: renaming an anchor orphans every layout entry that targets
    -- the old key, and those entries are not in the buffer -- so their targets
    -- are now unknown and this filter says nothing about it. That is safe only
    -- because the key box is drafts-only (view/detail.lua's SetEnabled on
    -- shown.isDraft): the sole reachable rename is a draft naming itself, which
    -- can orphan nothing, since nothing can target a key that never existed. If
    -- the form ever offers rename on an EXISTING anchor, this filter has to
    -- widen with it -- a second pass over every entry whose anchor target is a
    -- key being renamed -- or the rename has to rewrite those entries. Neither
    -- can be left to the player: the report is the only place the orphaning
    -- would ever be visible.
    for _, bad in ipairs(resolver.FindBadAnchors(editor.ProspectiveLayout())) do
        if pending[bad.key] ~= nil then
            problems[#problems + 1] = {
                key       = bad.key,
                target    = bad.target,
                localeKey = "reason:" .. bad.reason,
            }
        end
    end

    table.sort(problems, function(first, second)
        if first.key ~= second.key then return first.key < second.key end
        return first.localeKey < second.localeKey
    end)
    return problems
end

--- One problem as a line to print.
---
--- The two families read differently. An anchor definition refusal is a whole
--- sentence that names its own key, and control/resolver.lua owns that mapping
--- -- /bitforge eui apply prints the very same sentence for the very same
--- refusal, so it is formatted there and not re-formatted here. A graph verdict
--- is a bare reason that means nothing without the edge it refused, so that one
--- is framed by key and target exactly as doApply frames it.
---@param problem table  { key, localeKey, arg?, target? }
---@return string
function editor.FormatProblem(problem)
    if problem.target then
        return format(locale["apply:badAnchorLine"], problem.key,
            tostring(problem.target), locale[problem.localeKey])
    end
    return resolver.FormatRefusal(problem)
end

--- Write the buffer into the saved layout and anchor definitions.
---@return number|nil count     how many field edits were written, or nil when refused
---@return table|nil  problems  what refused it
function editor.Commit()
    local problems = editor.Validate()
    if #problems > 0 then return nil, problems end

    local count = editor.PendingCount()

    for key, fields in pairs(pending) do
        if isAnchorKey(key) then
            if fields.delete then
                model.SetAnchor(key, nil)
            else
                local savedKey = nextAnchorKey(key)
                -- Read before the origin is cleared: nextAnchorDef composes the
                -- buffer over the STORED definition, so clearing first would
                -- save the draft defaults instead of the anchor being moved.
                local def = nextAnchorDef(key)
                -- A row that changed key moves; leaving the origin behind would
                -- be two definitions where the player edited one. Validate has
                -- already refused a key another definition holds, so nothing
                -- here can be overwritten.
                if savedKey ~= key and key ~= DRAFT_KEY then
                    model.SetAnchor(key, nil)
                end
                model.SetAnchor(savedKey, def)
            end
        else
            local entry = nextEntry(key)

            -- SCREEN HAS TO MEAN SCREEN, and deleting our own anchor does not
            -- say it. What owns the position now is read from the STORED entry,
            -- before this commit takes it away: on the "eui" channel that is
            -- EllesmereUI's own unlockAnchors table, which stays the authority
            -- for as long as it holds an entry, and which an empty layout entry
            -- cannot argue with -- control/sync.lua reads an entry with no
            -- anchor as "this layout makes no attachment claim" and
            -- deliberately writes nothing. Left alone, the frame would not
            -- move, the row would still read as attached, and the next capture
            -- would read EllesmereUI's surviving anchor back into the layout:
            -- the edit discarded AND reverted.
            --
            -- Cleared for the "bitforge" channel too, and for the same reason:
            -- Apply clears EllesmereUI's anchor when it resolves one of ours,
            -- but an entry that never reached an Apply still has it, and
            -- clearing an anchor that is not there costs nothing.
            --
            -- This is the editor's ONLY write into EllesmereUI -- everywhere
            -- else it reads -- and it is contained: view/editor.lua reloads the
            -- moment a commit succeeds, and the login pass then applies the
            -- layout from scratch. No ReapplyAnchors is owed either: a key no
            -- longer in unlockAnchors is not one a re-anchor pass visits.
            local clearedAnchor = fields.target == NONE
                and resolver.Channel(key, model.GetLayout()[key]) ~= nil
            if clearedAnchor then
                adapters.WriteAnchor(key, nil)
            end

            -- With the anchor gone the entry has no position at all, and an
            -- entry that says nothing leaves Apply nothing to write. A partial
            -- one is worse: Apply fills the gaps with CENTER/0/0, so an edit to
            -- one axis would invent the other. Either way the whole triple is
            -- completed from what the form was showing.
            --
            -- EVERY field the form can put into an entry on its own is named
            -- here, relPoint included. Miss one and an edit to that box alone
            -- writes an entry control/sync.lua's guard also skips -- so nothing
            -- reaches EllesmereUI, while Detail composes the buffer over the
            -- live position and reports the edit as taken for good.
            if entry.anchor == nil and (clearedAnchor
                or entry.point or entry.relPoint or entry.x or entry.y) then
                completeScreenPosition(key, entry)
            end

            model.SetLayoutEntry(key, entry)
            -- The relationship changed, so a record of the last one resolved
            -- describes something that no longer exists. Apply rebuilds it on
            -- the reload that follows -- but the reload is not instant, and an
            -- Unlock Mode save in between would compare a live position against
            -- the old record and delete an attachment nobody touched. Clearing
            -- errs toward keeping the anchor: capture reads no record as no
            -- evidence of a drag.
            model.ClearResolved(key)
        end
    end

    editor.Revert()
    return count
end

control.editor = editor

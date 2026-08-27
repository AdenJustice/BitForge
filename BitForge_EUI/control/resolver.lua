---@class BitForge.EUI
local ns = select(2, ...)

---@class BitForge.EUI.Control
local control = ns.control
---@type BitForge.EUI.Model
local model = ns.model
---@type BitForge.EUI.Enum
local enum = ns.enum
---@type BitForge.EUI.Locale
local locale = ns.locale

---@type BitForge.EUI.Control.Adapters
local adapters = control.adapters

local format = string.format

-- Nine refusal reasons, and nothing else: `unknown`, `self`, `cycle`,
-- `halfpair`, `badpoint`, `notarget`, `noanchor`, `norect`, `notextended`.
-- Each is the suffix of a "reason:<name>" locale key in Locales/enUS.lua; the
-- caller adds the prefix. A tenth reason, or one of these nine going
-- unreachable, is a silent change to what the module tells a player about a
-- broken anchor.

--- Is this entry's anchor legal, ignoring the anchor graph as a whole? Shared
--- by FindBadAnchors (which additionally walks the graph for a cycle) and
--- ResolveExtended (which sees one entry and has no graph to walk). Returns a
--- reason name, or nil when nothing here refuses the anchor.
---@param key string
---@param anchor table  { target, point, relPoint, side, offsetX, offsetY }
---@return string|nil
local function checkAnchorReason(key, anchor)
    local target = anchor.target
    local hasPoint, hasRelPoint = anchor.point ~= nil, anchor.relPoint ~= nil

    -- A half-specified pair is a mistake in hand-edited data, and must be
    -- reported rather than silently falling back to `side`.
    if hasPoint ~= hasRelPoint then
        return "halfpair"
    end

    if hasPoint and not (enum.ANCHOR_POINTS[anchor.point] and enum.ANCHOR_POINTS[anchor.relPoint]) then
        return "badpoint"
    end

    -- EllesmereUI's own restrictions, read by name off the registry entry
    -- adapters.Elements() hands back (fact 9, docs/eui-integration.md -- the
    -- fact about the entry's SHAPE, which no adapter stands in front of). A
    -- hand-edited layout can name any target, and these two are not cosmetic:
    -- noAnchorTo almost always means "my size changes with auras or icon
    -- count", which a one-shot snapshot handles worse than EllesmereUI's
    -- continuous cascade does.
    local elements = adapters.Elements()
    local selfElement = elements and elements[key]
    local targetElement = elements and elements[target]
    if selfElement and selfElement.noAnchorTo then
        return "noanchor"
    elseif targetElement and targetElement.noAnchorTarget then
        return "notarget"
    end

    if target == key then
        return "self"
    end

    if not targetElement then
        return "unknown"
    end

    return nil
end

-- Virtual anchor frames, reused across rebuilds and keyed by anchor key, so a
-- rebuild repositions and resizes an existing frame rather than leaking a new
-- one every time.
local virtualFrames = {}

---@class BitForge.EUI.Control.Resolver
local resolver = {}

-- EllesmereUI's own anchor system expresses exactly five relationships, keyed
-- off `side` (EUI_UnlockMode.lua's ApplyAnchorPosition, copied into the
-- pre-load stub ReapplyOwnAnchor -- per docs/eui-integration.md). Those
-- five are five of the eighty-one point/relPoint pairs -- the same
-- arithmetic, offset signs included -- because LEFT/RIGHT/TOP/BOTTOM as an
-- anchor point already mean "the midpoint of that edge", which is the
-- cross-axis centring EllesmereUI hardcodes. Copied verbatim from the
-- standalone addon's Core/Attach.lua, not re-derived: a mismatch here would
-- silently hand one of EllesmereUI's five relationships to this module's own
-- resolver, or vice versa.
local SIDE_TO_PAIR = {
    LEFT   = { "RIGHT",  "LEFT"   },
    RIGHT  = { "LEFT",   "RIGHT"  },
    TOP    = { "BOTTOM", "TOP"    },
    BOTTOM = { "TOP",    "BOTTOM" },
    CENTER = { "CENTER", "CENTER" },
}

local PAIR_TO_SIDE = {}
for side, pair in pairs(SIDE_TO_PAIR) do
    PAIR_TO_SIDE[pair[1] .. " " .. pair[2]] = side
end

--- The side EllesmereUI would use for this pair, or nil when the pair is one
--- of the seventy-six it cannot express.
---@param point string|nil
---@param relPoint string|nil
---@return string|nil
function resolver.PairToSide(point, relPoint)
    if not (point and relPoint) then return nil end
    return PAIR_TO_SIDE[point .. " " .. relPoint]
end

--- Which channel would this entry's anchor take: EllesmereUI's own, this
--- module's, or neither?
---
--- "eui" means EllesmereUI owns the anchor entirely -- its cascade, its
--- triggers, its drag-lock -- which beats a one-shot snapshot whenever it can
--- express the relationship at all. "bitforge" means the pair is one of the
--- seventy-six EllesmereUI cannot express, so control/sync.lua resolves it
--- itself. nil means the key carries no anchor at all and is not independently
--- anchored by EllesmereUI either -- positioned against the screen.
---@param key string
---@param entry any  a saved layout entry, unvalidated
---@return "eui"|"bitforge"|nil
function resolver.Channel(key, entry)
    local anchor = type(entry) == "table" and entry.anchor
    if anchor and anchor.target then
        if anchor.point and anchor.relPoint then
            return resolver.PairToSide(anchor.point, anchor.relPoint) and "eui" or "bitforge"
        end
        -- A bare side, or no side at all. EllesmereUI stores side with no
        -- default and reads its absence as centre-on-centre.
        return "eui"
    end

    -- No anchor claim in the layout itself -- but EllesmereUI may still
    -- independently anchor this key (EllesmereUI.IsUnlockAnchored is the
    -- documented exception to reading through the element).
    if adapters.IsAnchored(key) then
        return "eui"
    end

    return nil
end

--- Is this anchor definition usable? Returns ok, locale key, format arg.
---
--- Split from BuildAnchorFrames so the editor can show the same verdicts in
--- its form, before committing: one set of rules, so an editor that accepted
--- a definition BuildAnchorFrames then rejected would write a saved anchor
--- that silently never appears.
---@param key string
---@param entry any  the saved anchor definition, unvalidated
---@return boolean ok
---@return string|nil localeKey
---@return string|nil arg
function resolver.ValidateAnchorDef(key, entry)
    if type(entry) ~= "table" then
        return false, "anchor:badTable"
    end

    -- Size is not optional. EllesmereUI's anchor math bails on a target whose
    -- GetLeft() is nil, and a frame with no size has no resolvable edges -- so
    -- a sizeless anchor is not a smaller anchor, it is an invisible failure.
    local width, height = entry.w, entry.h
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
        return false, "anchor:badSize"
    end

    -- Registering over an existing key would replace a real EllesmereUI
    -- element in the shared registry -- unregistering a unit frame or action
    -- bar and breaking its mover. The registry is shared and last write wins
    -- (fact 7, docs/eui-integration.md), so this is checked rather than hoped
    -- for. An existing virtual frame at this key is our own, from an earlier
    -- build, so that is not a collision.
    local elements = adapters.Elements()
    local existing = elements and elements[key]
    if existing and virtualFrames[key] == nil then
        return false, "anchor:collides", tostring(existing.folder or "?")
    end

    return true
end

--- Create and register every saved anchor. Idempotent: an existing virtual
--- frame is repositioned and resized rather than replaced, so rebuilding
--- never leaks a frame.
---
--- Refusals are returned rather than printed: printing here would foreclose
--- the editor showing the same verdicts in its own form, which is the whole
--- reason ValidateAnchorDef is split from this wrapper. The caller decides
--- whether a refusal reaches chat or a form.
---@return number count     virtual anchor frames registered
---@return table  refusals  { { key = , localeKey = , arg = }, ... }, sorted by key
function resolver.BuildAnchorFrames()
    local anchors = model.GetAnchors()
    if type(anchors) ~= "table" or not adapters.IsPresent() then
        return 0, {}
    end

    -- Deterministic order so a collision -- and a refusal -- is reported the
    -- same way every run.
    local keys = {}
    for key in pairs(anchors) do
        keys[#keys + 1] = key
    end
    table.sort(keys)

    local registered = 0
    -- Built by walking the already-sorted `keys`, so this collects in key
    -- order with no separate sort needed.
    local refusals = {}

    for _, key in ipairs(keys) do
        local entry = anchors[key]
        local ok, localeKey, arg = resolver.ValidateAnchorDef(key, entry)
        if ok then
            local frame = virtualFrames[key]
            if not frame then
                frame = CreateFrame("Frame", "BitForgeEUIAnchor" .. key, UIParent)
                virtualFrames[key] = frame
            end

            -- No texture, no font string: laid out and measurable, but
            -- nothing drawn.
            frame:SetSize(entry.w, entry.h)
            frame:ClearAllPoints()
            frame:SetPoint(entry.point or "CENTER", UIParent,
                entry.relPoint or entry.point or "CENTER",
                entry.x or 0, entry.y or 0)

            adapters.RegisterAnchorFrame(key, frame, entry.label or key)
            registered = registered + 1
        else
            refusals[#refusals + 1] = { key = key, localeKey = localeKey, arg = arg }
        end
    end

    return registered, refusals
end

--- The pure record-to-string mapping for one BuildAnchorFrames refusal.
--- Returns the formatted line and prints nothing -- the caller decides
--- whether it reaches chat (control.lua) or a form (view/detail.lua), exactly
--- the split BuildAnchorFrames' own refusals already establish. The resolver
--- owns the refusal record's shape, so it owns this mapping too, rather than
--- each caller keeping its own copy.
---@param refusal table  { key, localeKey, arg? }
---@return string
function resolver.FormatRefusal(refusal)
    if refusal.arg then
        return format(locale[refusal.localeKey], refusal.key, refusal.arg)
    end
    return format(locale[refusal.localeKey], refusal.key)
end

--- Every layout entry with an anchor that would not resolve, and why. Walks
--- the graph this layout would leave behind so a cycle is caught whole, not
--- one edge at a time -- and BOTH members of a cycle are refused, since
--- refusing only the second would leave a half-applied cycle.
---
--- The graph is EllesmereUI's own anchors first, this layout's edges layered
--- over them: a cycle can close through an anchor EllesmereUI owns and this
--- layout never mentions, and only the merged map makes that edge visible to
--- the walk.
---@param layout table
---@return table  { { key, target, reason }, ... } sorted by key
function resolver.FindBadAnchors(layout)
    local bad = {}

    local effectiveTarget = {}
    for key, info in pairs(adapters.AllAnchors()) do
        if type(info) == "table" and info.target then
            effectiveTarget[key] = info.target
        end
    end
    for key, entry in pairs(layout) do
        if type(entry) == "table" and entry.anchor and entry.anchor.target then
            effectiveTarget[key] = entry.anchor.target
        end
    end

    for key, entry in pairs(layout) do
        local anchor = type(entry) == "table" and entry.anchor
        local target = anchor and anchor.target
        if target then
            local reason = checkAnchorReason(key, anchor)

            if not reason then
                -- Follow the chain from this key. Returning to it is a
                -- cycle; the depth cap catches a loop that never passes back
                -- through the start.
                local seen, node = { [key] = true }, effectiveTarget[key]
                for _ = 1, 64 do
                    if not node then break end
                    if seen[node] then
                        reason = "cycle"
                        break
                    end
                    seen[node] = true
                    node = effectiveTarget[node]
                end
            end

            if reason then
                bad[#bad + 1] = { key = key, target = target, reason = reason }
            end
        end
    end

    table.sort(bad, function(a, b) return a.key < b.key end)
    return bad
end

--- The horizontal and vertical component of an anchor point name.
--- "BOTTOMLEFT" carries both; "LEFT" carries a horizontal edge and a
--- vertical midpoint.
---@param point string
---@return string horizontal  "LEFT" | "RIGHT" | "CENTER"
---@return string vertical    "TOP" | "BOTTOM" | "CENTER"
local function components(point)
    local horizontal = (point:find("LEFT", 1, true) and "LEFT")
        or (point:find("RIGHT", 1, true) and "RIGHT")
        or "CENTER"
    local vertical = (point:find("TOP", 1, true) and "TOP")
        or (point:find("BOTTOM", 1, true) and "BOTTOM")
        or "CENTER"
    return horizontal, vertical
end

--- Resolve one extended anchor -- a point/relPoint pair EllesmereUI cannot
--- express -- into a position, and record it via model.SetResolved: the
--- bookkeeping capture later reads to tell our own write from a player's
--- drag. Nothing is written to EllesmereUI here -- that stays the caller's
--- job, since resolving must finish, whole, before anything reaches
--- EllesmereUI, and a refused anchor (returned above this point) must never
--- be recorded at all.
---
--- Matches EllesmereUI's own convention deliberately: the target's edges are
--- normalised into UIParent space by its effective scale, and the result is a
--- UIParent-space offset with no child-scale division -- exactly what keeps
--- these numbers comparable with EllesmereUI's own cog and with a hand-edited
--- value. The child's own `point` is preserved rather than converted to
--- CENTER, so the child's size never enters the arithmetic and the anchor
--- stays correct when the child resizes.
---@param key string
---@param entry table  { anchor = { target, point, relPoint, offsetX, offsetY } }
---@return table|nil  { point, relPoint, x, y }
---@return string|nil reason
function resolver.ResolveExtended(key, entry)
    local anchor = type(entry) == "table" and entry.anchor
    if not (anchor and anchor.target) then
        return nil, "notextended"
    end

    local reason = checkAnchorReason(key, anchor)
    if reason then
        return nil, reason
    end

    if not (anchor.point and anchor.relPoint) then
        return nil, "notextended"
    end

    local elements = adapters.Elements()
    local targetElement = elements and elements[anchor.target]
    local frame = targetElement and targetElement.getFrame and targetElement.getFrame(anchor.target)
    if not frame then
        return nil, "unknown"
    end
    if not frame:GetLeft() then
        return nil, "norect"
    end

    local uiScale = UIParent:GetEffectiveScale() or 1
    local ratio = (frame:GetEffectiveScale() or 1) / uiScale
    local targetLeft, targetRight = frame:GetLeft() * ratio, frame:GetRight() * ratio
    local targetBottom, targetTop = frame:GetBottom() * ratio, frame:GetTop() * ratio

    local horizontal, vertical = components(anchor.relPoint)
    local pointX = (horizontal == "LEFT" and targetLeft)
        or (horizontal == "RIGHT" and targetRight)
        or ((targetLeft + targetRight) / 2)
    local pointY = (vertical == "BOTTOM" and targetBottom)
        or (vertical == "TOP" and targetTop)
        or ((targetBottom + targetTop) / 2)

    local uiWidth = UIParent:GetWidth() or 0
    local uiHeight = UIParent:GetHeight() or 0

    local point, relPoint = anchor.point, "CENTER"
    local x = pointX + (anchor.offsetX or 0) - uiWidth / 2
    local y = pointY + (anchor.offsetY or 0) - uiHeight / 2

    model.SetResolved(key, point, relPoint, x, y)

    return { point = point, relPoint = relPoint, x = x, y = y }
end

control.resolver = resolver

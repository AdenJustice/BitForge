---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...

local assert = assert
local ipairs = ipairs
local pairs = pairs
local select = select
local concat = table.concat
local format = string.format
local sort = table.sort
local tInvert = tInvert

local C_Item = C_Item
local C_Timer = C_Timer
local C_TooltipInfo = C_TooltipInfo

---@type BitForge.AzerothPrime.Enum
local enum = ns.enum
---@type BitForge.AzerothPrime.Model
local model = ns.model
---@type BitForge.AzerothPrime.Locale
local locale = ns.locale

---@class BitForge.AzerothPrime.Control
local control = ns.control
local sellScanner = control.sellScanner

local openRules = model.openRules
local allowAudit = model.allowAudit
local BUCKET = allowAudit.BUCKET
local UNREAD = allowAudit.UNREAD

---@class BitForge.AzerothPrime.Control.AllowListAudit
local allowListAudit = {}

-- One sweep plus two retries, a second apart. sellScanner.GatherByID answers
-- nil until the client has the item's data and asks for it on the way out, so
-- retrying is what makes the first invocation of the command useful. The
-- ceiling is what stops an id the client will never answer for from retrying
-- for the rest of the session; naming those ids in the report is what stops
-- the ceiling from hiding them.
local ATTEMPTS = 3
local RETRY_DELAY = 1

-- REDUNDANT first: it is the only bucket that implies an edit. The rest run
-- from "the entry is doing work" to "the pass could not decide", so a reader
-- who stops early has read the actionable half.
local BUCKET_ORDER = {
    BUCKET.REDUNDANT,
    BUCKET.REDUNDANT_UNTYPED,
    BUCKET.LOAD_BEARING,
    BUCKET.INERT,
    BUCKET.UNJUDGED_CLASS,
    BUCKET.UNDECIDABLE,
    BUCKET.PLAYER_STATE,
    BUCKET.ANOMALY,
    BUCKET.UNREADABLE,
}

-- Nothing derives the order above from model/allowAudit.lua's BUCKET table, so
-- a tenth bucket added there would render as a group that is silently absent
-- and a census line that never appears -- the same quiet-list failure
-- CLAUDE.md catalogues five of. Raising at load is the loud version.
do
    local placed = {}
    for _, bucket in ipairs(BUCKET_ORDER) do placed[bucket] = true end
    for _, bucket in pairs(BUCKET) do
        if not placed[bucket] then
            error("BitForge_AzerothPrime/debug/allowListAudit.lua: "
                .. "model/allowAudit.lua's " .. bucket .. " bucket has no place"
                .. " in BUCKET_ORDER")
        end
    end
end

local priorityNames

--- One enum.PRIORITY tier as "OPEN(20)", or "-" where no rung awarded one.
--- The number alone is what a reader would otherwise have to translate, and
--- both numbers are the whole of what a LOAD_BEARING allow row is asking them
--- to weigh.
---@param priority number|nil
---@return string
local function PriorityLabel(priority)
    if not priority then return "-" end
    priorityNames = priorityNames or tInvert(enum.PRIORITY)
    return format("%s(%s)", priorityNames[priority] or "?", tostring(priority))
end

--- The two curated lists, and the whole of what differs between auditing them.
--- Both are swept by the same code below; each says which rung to suppress,
--- which of model/allowAudit.lua's two mappings answers for it, what a row of
--- it prints, and the sentences its section of the report needs.
---
--- No bucket is decided here. `Bucket` selects between the two mappings that
--- model/allowAudit.lua publishes -- naming one is not deciding one, and the
--- alternative is a dispatcher in that file taking a list name it would then
--- have to be trusted to branch on.
---@class AzerothPrime.AuditListSpec
---@field key string  the word /bfdump azerothprime allowlist takes to run this one
---@field source string  the enum table it reads, named in the discovery
---   guard's message and nowhere else -- the report says `list =` instead
---@field heading string  the section's own `list =` line
---@field answers string  the question this list's section answers
---@field notes string[]  further `name = text` lines, rendered in this order
---@field suppress AzerothPrime.OpenRulesSuppress  the rung this pass switches off
---@field Entries fun(): table  read at run time, never captured: a test that
---   empties the list is asserting on the discovery guard, and a captured
---   table would hand it the old entries
---@field Bucket fun(claim: string|nil, reason: string|nil, priority: number|nil, itemID: number): string
---@field Row fun(row: table): string

local LISTS = {
    {
        key = "allow",
        source = "enum.ALLOW_LIST",
        heading = "ALLOW -- enum.ALLOW_LIST, items the tooltip and class rules"
            .. " will not surface on their own",
        answers = "would the open rules surface this item without its entry",
        notes = {
            -- Which ladder produced it, per spec #389's Risks: a redundancy
            -- verdict is only true of the rules that reached it, and those
            -- move.
            "excludes = whether the item is retired, and whether its quality"
                .. " has been dropped to Poor -- a listed Poor item the ladder"
                .. " refuses here still reads as LOAD_BEARING, because"
                .. " openRules refuses it at runtime on the quality this pass"
                .. " never weighs. Scripts/audit_allow_list.py answers both"
                .. " from Wowhead",
        },
        suppress = { allowList = true },
        Entries = function() return enum.ALLOW_LIST end,
        -- The class from C_Item.GetItemInfoInstant rather than the record's
        -- own: that is what openRules' class policy branches on, and
        -- facts.classID comes from GetItemInfo instead.
        Bucket = function(claim, reason, priority, itemID)
            return allowAudit.Bucket(claim, reason, priority, {
                bagless = true,
                classID = select(6, C_Item.GetItemInfoInstant(itemID)),
                listedPriority = enum.ALLOW_LIST[itemID],
            })
        end,
        Row = function(row)
            return format("  %d %s rung=%s priority=%s listed=%s",
                row.itemID, tostring(row.name or "?"), tostring(row.rung or "-"),
                PriorityLabel(row.priority),
                PriorityLabel(enum.ALLOW_LIST[row.itemID]))
        end,
    },
    {
        key = "deny",
        source = "enum.DENY_LIST",
        heading = "DENY -- enum.DENY_LIST, items the open rules accept but"
            .. " should not surface",
        answers = "would the open rules refuse this item without its entry",
        notes = {
            -- The one thing the buckets cannot say. Without it fifteen
            -- load-bearing rows read as fifteen findings.
            "policy = an entry the ladder still accepts may be a deliberate"
                .. " policy deny rather than a rules-are-wrong deny, and the"
                .. " two are indistinguishable here. The plain Hearthstone is"
                .. " the standing example -- the ladder will go on accepting it"
                .. " forever and should. Only the entry's own comment in"
                .. " OpenableData.lua says which kind it is, so a LOAD_BEARING"
                .. " row below is not a finding on its own",
        },
        suppress = { denyList = true },
        Entries = function() return enum.DENY_LIST end,
        -- No context and no priority: model/allowAudit.lua's deny mapping is
        -- written against this pass's bag-less record as a premise, and
        -- enum.DENY_LIST pins no rank for an accept to be weighed against.
        Bucket = function(claim, reason)
            return allowAudit.DenyBucket(claim, reason)
        end,
        -- No `listed=` half, for the same reason. A column that read "-" for
        -- all fifteen rows would be inviting the comparison the allow section
        -- makes and this one cannot.
        Row = function(row)
            return format("  %d %s rung=%s priority=%s",
                row.itemID, tostring(row.name or "?"), tostring(row.rung or "-"),
                PriorityLabel(row.priority))
        end,
    },
}

--- What the open ladder says about one listed item with that list's own rung
--- suppressed, or nil while the client has not answered with the item's data
--- -- which is "ask again", not a verdict.
---@param spec AzerothPrime.AuditListSpec
---@param itemID number
---@return table|nil row
local function Classify(spec, itemID)
    -- control/sellScanner.lua's GatherByID, and the choice is load-bearing
    -- rather than convenient: model/allowAudit.lua's bag-less rows are written
    -- against exactly the fields this constructor omits, and
    -- model.facts.GetPartial would compute four of them and falsify those rows
    -- with nothing to catch it.
    local facts = sellScanner.GatherByID(itemID)
    if not facts then return nil end

    local row = { itemID = itemID, name = facts.name }

    -- C_TooltipInfo.GetItemByID is MayReturnNothing. Handing openRules.Claim a
    -- nil would leave the rungs above the tooltip walk answering while nothing
    -- had been read -- #378 exactly -- so a row with no tooltip behind it says
    -- the pass could not look rather than reporting what the ladder made of
    -- not looking. There is no verdict to sort, so the bucket comes from
    -- allowAudit.UnreadBucket instead: the decision stays in the one file that
    -- makes bucket decisions, next to the ladder's own NO_TOOLTIP row, which
    -- says the same thing about the same absence.
    local tooltipData = C_TooltipInfo.GetItemByID(itemID)
    if not tooltipData then
        row.rung = UNREAD.NO_TOOLTIP
        row.bucket = allowAudit.UnreadBucket(row.rung)
        return row
    end

    local claim, priority, reason = openRules.Claim(facts, tooltipData, spec.suppress)
    row.priority, row.rung = priority, reason
    row.bucket = spec.Bucket(claim, reason, priority, itemID)
    return row
end

--- An entry whose item data never arrived. Named rather than dropped: a pass
--- that skipped what it could not read would report a clean list and a shorter
--- one.
---@param itemID number
---@return table row
local function UnreadRow(itemID)
    return {
        itemID = itemID,
        name = C_Item.GetItemNameByID(itemID),
        bucket = allowAudit.UnreadBucket(UNREAD.NO_ITEM_DATA),
        rung = UNREAD.NO_ITEM_DATA,
    }
end

--- One list's section: its own header lines, then every bucket in order.
---@param section table
---@param lines string[]
local function RenderSection(section, lines)
    local spec = section.spec

    local grouped = {}
    for _, row in ipairs(section.rows) do
        local group = grouped[row.bucket]
        if not group then
            group = {}
            grouped[row.bucket] = group
        end
        group[#group + 1] = row
    end

    lines[#lines + 1] = ""
    lines[#lines + 1] = "list = " .. spec.heading
    lines[#lines + 1] = format("entries = %d", section.total)
    lines[#lines + 1] = "answers = " .. spec.answers
    for _, note in ipairs(spec.notes) do lines[#lines + 1] = note end

    for _, bucket in ipairs(BUCKET_ORDER) do
        local group = grouped[bucket]
        lines[#lines + 1] = ""
        lines[#lines + 1] = format("%s (%d)", bucket, group and #group or 0)
        if group then
            -- Sorted by id rather than left in sweep order: a retried entry
            -- lands in a later sweep than its neighbours, and two runs over an
            -- unchanged list have to render the same text for a diff between
            -- them to mean anything.
            sort(group, function(left, right) return left.itemID < right.itemID end)
            for _, row in ipairs(group) do
                lines[#lines + 1] = spec.Row(row)
            end
        end
    end
end

--- The audit as text a person reads and acts on by hand.
---@param sections table[]
---@return string
local function Render(sections)
    local lines = {
        "BitForge AzerothPrime -- curated open list audit",
        BitForge:ReportHeader(ADDON_NAME),
        "",
        "ladder = model/openRules.lua, run with the audited list's own rung suppressed",
        "deletable = REDUNDANT alone; every other bucket is reported and left as it is",
    }

    for _, section in ipairs(sections) do
        RenderSection(section, lines)
    end

    return concat(lines, "\n")
end

--- Run the open ladder over every entry of a curated open list with that
--- list's own rung suppressed, and report which entries the rest of the rules
--- already answer. Reached from /bfdump azerothprime allowlist [allow|deny].
---
--- Deletes nothing and edits no file: a person reads the report and edits
--- OpenableData.lua. Spec #389's "Certainty is the constraint" is why only one
--- of the nine buckets licenses that edit, for either list -- reached on
--- opposite evidence, which is model/allowAudit.lua's whole asymmetry.
---@param list string|nil  one AzerothPrime.AuditListSpec key, or nil for both.
---   debug/dumps.lua matches the word before calling, so an unrecognised
---   one prints the usage line rather than reaching here
function allowListAudit.Run(list)
    local sections = {}
    for _, spec in ipairs(LISTS) do
        if not list or list == spec.key then
            -- Unsorted, deliberately: RenderSection imposes the order, because
            -- rows accumulate across sweeps and a sort here would be undone by
            -- the first retry.
            local ids = {}
            for itemID in pairs(spec.Entries()) do ids[#ids + 1] = itemID end
            sections[#sections + 1] =
                { spec = spec, total = #ids, pending = ids, rows = {} }
        end
    end

    -- #376 again, one level up from the per-section guard below: a run that
    -- matched no list renders a header, every `name = value` line and no
    -- section, which reads exactly like a clean pair of lists. control.lua
    -- matches the word before calling, so today only a caller of this sub-key
    -- can reach it -- and Run is a published sub-key, so today is not the
    -- guarantee.
    assert(#sections > 0, "BitForge AzerothPrime: the audit matched no curated "
        .. "list -- " .. tostring(list) .. " names none of them")

    local function sweep(attempt)
        local outstanding = 0
        for _, section in ipairs(sections) do
            local remaining = {}
            for _, itemID in ipairs(section.pending) do
                local row = Classify(section.spec, itemID)
                if row then
                    section.rows[#section.rows + 1] = row
                else
                    remaining[#remaining + 1] = itemID
                end
            end
            section.pending = remaining
            outstanding = outstanding + #remaining
        end

        if outstanding > 0 and attempt < ATTEMPTS then
            C_Timer.After(RETRY_DELAY, function() sweep(attempt + 1) end)
            return
        end

        for _, section in ipairs(sections) do
            for _, itemID in ipairs(section.pending) do
                section.rows[#section.rows + 1] = UnreadRow(itemID)
            end

            -- The same #376 lesson per section: an empty section reads
            -- exactly like a clean list, and one guard over the whole report
            -- would let the larger list answer for the emptier one. UnreadRow
            -- gives every id a row, so the only way here is that list's enum
            -- table being empty -- the section count is guarded above.
            assert(#section.rows > 0, "BitForge AzerothPrime: the audit found no "
                .. "entry to classify -- " .. section.spec.source .. " is empty")
        end

        BitForge:ShowReport(Render(sections), locale["report:blurbAllowList"],
            BitForge:DiagnosticReportTitle())
    end

    sweep(1)
end

control.allowListAudit = allowListAudit

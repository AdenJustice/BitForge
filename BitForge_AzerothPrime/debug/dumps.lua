---@type string, BitForge.AzerothPrime
local ADDON_NAME, ns = ...

local ipairs = ipairs
local pairs = pairs
local format = string.format
local concat = table.concat
local sort = table.sort
local tInvert = tInvert

-- The verdict dump's reagent audit weighs the same profession mask
-- model.Decide's step 9 does.
local band = bit.band

local SpellCanTargetItem = SpellCanTargetItem
local SpellCanTargetItemID = SpellCanTargetItemID
local SpellIsTargeting = SpellIsTargeting

local C_Container = C_Container
local C_Item = C_Item
local C_MerchantFrame = C_MerchantFrame
local C_SpellBook = C_SpellBook
local C_TooltipInfo = C_TooltipInfo
local C_TradeSkillUI = C_TradeSkillUI

---@type BitForge.AzerothPrime.Enum
local enum = ns.enum

---@type BitForge.AzerothPrime.Model
local model = ns.model

---@type BitForge.AzerothPrime.Locale
local locale = ns.locale

local events = BitForge.Events

---@class BitForge.AzerothPrime.Control
local control = ns.control
local openScanner = control.openScanner
local sellScanner = control.sellScanner

-- Every /bfdump azerothprime form, and the one subscription that routes them.
-- BitForge_AzerothPrime.toc wraps this file in #@debug@, so a release build ships
-- no source for any of it -- and the subscription below is marked diagnostic,
-- which is what makes core drop AzerothPrime's /bfdump line from the roster and
-- refuse the command outright rather than broadcast it to nobody (spec #405).
--
-- What stayed in control/control.lua is the half a PLAYER reaches: the open
-- report view/button.lua's Shift+Alt+right-click shows, and the sell report
-- view/merchantPanel.lua's Report This Verdict shows. Both are rendered from
-- here too -- through control.OpenReportText and control.RenderSellReport --
-- so a developer inspecting a verdict reads the same text a player would have
-- sent, instead of a second renderer that can drift from it.
--
-- Never gate any of it on model.IsDebug(). Shipping is what gates it now, and
-- the flag never did: the commands record nothing -- the record goes to the
-- player, not to disk -- so there is nothing left for a flag to gate. One
-- block below is gated, AppendZoneBlock, and on audience rather than storage;
-- the verdict block's own header states why.

-- Shared by every dump below: the one place any of them needs to turn a bare
-- itemID into a live bag:slot, when the item happens to be carried.
local function FindInBags(itemID)
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID == itemID then return bag, slot end
        end
    end
end

-- /bfdump azerothprime open [itemID] shows everything detector.Classify reads
-- about an item in the report window, so a surprising decision can be
-- inspected without a /reload. With no argument it dumps whatever is on the
-- button.
--
-- Rendered by control.OpenReportText, which is the button gesture's own
-- renderer: the arbiter caveat this dump inherits, and the note line the
-- report prints about it, are stated once in control/control.lua's header
-- above that function.
--
-- /bfdump azerothprime open all shows the other half of the question. A single
-- item's record says why that item was accepted but not why it was the one
-- shown: the button takes candidates[1] and the rest are discarded unseen,
-- so a surprising pick reads as a verdict with nothing to compare it
-- against. The field dump shows the whole ranked list, winner first, which
-- turns the pick back into a margin.
do
    local priorityNames

    local function PriorityName(priority)
        priorityNames = priorityNames or tInvert(enum.PRIORITY)
        return priorityNames[priority] or "?"
    end

    -- One flattened line per candidate, in the order model.openRules.Rank left
    -- them.
    --
    -- The index is carried in the text rather than left to the array order
    -- alone: the record has to be pastable verbatim and still read as a
    -- ranking. Everything the sort actually consults is reported -- priority,
    -- cooldown, stack -- so a pick that looks wrong can be checked against the
    -- comparison that produced it instead of guessed at.
    local function BuildFieldDump(candidates)
        local field = {}
        for index, candidate in ipairs(candidates) do
            field[index] = ("#%d %s [%s] priority=%s (%s) reason=%s detail=%s"
                .. " bag=%s slot=%s stack=%s locked=%s slotLocked=%s onCooldown=%s deferred=%s"):format(
                index,
                tostring(C_Item.GetItemNameByID(candidate.itemID)),
                tostring(candidate.itemID),
                tostring(candidate.priority),
                PriorityName(candidate.priority),
                tostring(candidate.reason),
                tostring(candidate.reasonDetail),
                tostring(candidate.bag),
                tostring(candidate.slot),
                tostring(candidate.stackCount),
                tostring(candidate.locked),
                tostring(candidate.slotLocked),
                tostring(candidate.onCooldown),
                tostring(candidate.deferred))
        end
        return field
    end

    --- The whole ranked field from the last scan as text a player can select
    --- and paste, winner first.
    ---@param candidates table[]
    ---@return string
    local function RenderFieldDump(candidates)
        local lines = {
            "BitForge AzerothPrime -- ranked field",
            BitForge:ReportHeader(ADDON_NAME),
            "",
        }

        for _, line in ipairs(BuildFieldDump(candidates)) do
            lines[#lines + 1] = line
        end

        return concat(lines, "\n")
    end

    --- Show one item's whole classification in the report window.
    ---
    --- Nothing is stored: the record used to be parked in the module's debug
    --- container for a later session to dig out of SavedVariables, which is
    --- why it needed the debug flag to stop it accumulating unasked. Rendered
    --- and shown, it records nothing, so it needs no flag and no /reload.
    ---@param itemID number|nil
    function control.DumpOpenItem(itemID)
        local bag, slot

        if itemID then
            bag, slot = FindInBags(itemID)
            if not bag then
                BitForge:Print(("AzerothPrime: item %d is not in your bags"):format(itemID))
                return
            end
        else
            local candidate = openScanner.GetCurrent()
            if not candidate then
                BitForge:Print("AzerothPrime: nothing on the button to dump")
                return
            end
            bag, slot, itemID = candidate.bag, candidate.slot, candidate.itemID
        end

        BitForge:ShowReport(control.OpenReportText(bag, slot, itemID), locale["report:blurbOpen"],
            BitForge:DiagnosticReportTitle())
    end

    --- Show the whole ranked field from the last scan in the report window,
    --- winner first.
    ---
    --- Read from the scan rather than recomputed: the question being asked is
    --- why the button shows what it shows, and a fresh scan would answer it
    --- against bags that may already have moved on. Like control.DumpOpenItem,
    --- nothing is stored -- see its comment for why the debug gate this used
    --- to need is gone with it.
    function control.DumpOpenField()
        local candidates = openScanner.GetRanked()
        if not candidates or #candidates == 0 then
            BitForge:Print("AzerothPrime: the last scan produced no candidates to rank")
            return
        end

        BitForge:ShowReport(RenderFieldDump(candidates), locale["report:blurbField"],
            BitForge:DiagnosticReportTitle())
    end
end

-- /bfdump azerothprime sell <itemID> captures a whole verdict -- the item, what is
-- equipped in the slot it would fill, the settings that judged the pair, and
-- the rule that decided -- and shows it in the report window, for the player
-- to paste rather than dig out of SavedVariables.
--
-- It takes an ID rather than a bag slot on purpose. The tooltip could already
-- explain anything you were holding, live, and nothing else: a verdict reported
-- after the fact was uninvestigable, because both operands had gone. An ID
-- resolves the candidate from the client's cache and the equipped side from the
-- slots its equip location maps to, so neither has to still be in your bags.
do
    --- Show one item's whole verdict in the report window.
    ---
    --- Nothing is stored: the record used to be parked in db.debug.dump for a
    --- later session to dig out of SavedVariables, which is why it needed the
    --- debug flag to stop it accumulating unasked. Rendered and shown, it
    --- records nothing, so it needs no flag and no /reload.
    ---@param itemID number|nil
    function control.DumpSellItem(itemID)
        if not itemID then
            BitForge:Print("AzerothPrime: /bfdump azerothprime sell <itemID> | disenchant")
            return
        end

        local report = sellScanner.ExplainByID(itemID)
        if not report then
            BitForge:Print(("AzerothPrime: item %d is not cached yet -- try again in a moment")
                :format(itemID))
            return
        end

        BitForge:ShowReport(control.RenderSellReport(report), locale["report:blurbSell"],
            BitForge:DiagnosticReportTitle())
    end

    -- Scaffolding for one open question: which signal distinguishes an item
    -- the player can disenchant from one they cannot
    -- (control/disenchantProbe.lua's own header carries what was tried and
    -- what answers).
    --
    -- Everything needed to pin that down is captured in a single subcommand
    -- deliberately: the state under investigation is destroyed by the act of
    -- investigating it any other way -- a pending spell does not survive being
    -- studied one pasted line at a time, and a bag does not hold still between
    -- them. Run it once with the spell up and once with it down; the report
    -- window is reused rather than stacked, so copy the first result out
    -- before running the second, or it is gone.

    local SCAN_ITEM_LIMIT = 8

    -- Every string in _G, indexed by its value, so a captured tooltip line can
    -- be traced back to the global constant it was built from. A line matched
    -- by constant is matched in all eleven locales; a line matched by its text
    -- is matched in one, and only until the text is reworded.
    --
    -- First key wins. Several constants share a value -- the duplicates are
    -- aliases of each other and naming either one answers the question.
    local function GlobalStringIndex()
        local index = {}
        for key, value in pairs(_G) do
            if type(value) == "string" and value ~= "" and index[value] == nil then
                index[value] = key
            end
        end
        return index
    end

    -- One slot's whole tooltip, flattened. Every line is kept rather than only
    -- the error lines: the line that marks an item as disenchantable has not
    -- been seen yet, and filtering to the type the *negative* line uses would
    -- be assuming the answer.
    local function CaptureTooltip(bagIndex, slotIndex, names)
        local data = C_TooltipInfo.GetBagItem(bagIndex, slotIndex)
        if not data or not data.lines then return { "no tooltip data" } end

        local captured = {}
        for index, line in ipairs(data.lines) do
            local text = tostring(line.leftText)
            captured[#captured + 1] = ("%s type=%s global=%s | %s"):format(
                tostring(index), tostring(line.type),
                tostring(names[text] or "-"), text)
        end
        return captured
    end

    --- One disenchant-probe scan as text: the client's whole state, followed
    --- by every captured item's tooltip lines.
    ---@param scan table
    ---@return string
    local function RenderDisenchantReport(scan)
        local lines = {
            "BitForge AzerothPrime -- disenchant scan",
            BitForge:ReportHeader(ADDON_NAME),
            "",
            scan.state,
        }

        -- Sorted rather than walked in hash order: two runs over the same bag
        -- render their items in whatever order pairs() happens to reach them,
        -- and the reason to run twice is to compare the two texts.
        local keys = {}
        for key in pairs(scan.items) do
            keys[#keys + 1] = key
        end
        sort(keys)

        for _, key in ipairs(keys) do
            lines[#lines + 1] = ""
            lines[#lines + 1] = key
            for _, line in ipairs(scan.items[key]) do
                lines[#lines + 1] = line
            end
        end

        -- Named rather than dropped. An item whose quality the client declined
        -- to answer for is exactly what this scan exists to surface, and a
        -- reader who is not told it was skipped reads the capture as complete.
        if #scan.unreadable > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = ("unreadable quality (%d):"):format(#scan.unreadable)
            for _, entry in ipairs(scan.unreadable) do
                lines[#lines + 1] = "  " .. entry
            end
        end

        return concat(lines, "\n")
    end

    --- Show the client's whole answer about disenchanting in the report window.
    ---
    --- Rendered and shown rather than filed, like control.DumpSellItem -- see
    --- its comment for why the debug gate this used to need is gone with it.
    ---
    --- Reads model.facts.Walk's shared entries and threads entry.slotInfo into
    --- sellScanner.Gather's knownSlotInfo, the same way control.disenchantProbe
    --- and both scanners do: a /bfdump run at a vendor or a bank rides the walk
    --- that session already paid for instead of taking a second one.
    function control.ScanDisenchant()
        local names = GlobalStringIndex()

        local items = {}
        local unreadable = {}
        local seen = 0
        for _, entry in ipairs(model.facts.Walk()) do
            local bagIndex, slotIndex = entry.bagIndex, entry.slotIndex
            local facts = sellScanner.Gather(bagIndex, slotIndex, entry.slotInfo)
            -- Quality can come back secret in 12.0, and >= raises on one.
            -- disenchantProbe.readSlot guards the identical comparison the
            -- same way; this one did not, so a single unreadable item took
            -- the whole command down and the player got an error instead of
            -- the report that would have told them why.
            --
            -- Listed rather than skipped, and walked whatever SCAN_ITEM_LIMIT
            -- has already seen: a dump whose purpose is showing what the addon
            -- can and cannot see betrays itself by dropping the items it
            -- cannot see, and this check costs nothing the limit exists to
            -- cap -- reading a quality is not reading a tooltip.
            if facts and model.IsUnread(facts.quality) then
                unreadable[#unreadable + 1] = ("%s:%s %s %s"):format(
                    tostring(bagIndex), tostring(slotIndex),
                    tostring(facts.itemID), tostring(facts.name))
            end

            -- The same coarse shape the real rule screens on, so the
            -- capture is of the items the question is actually about.
            -- Gated by SCAN_ITEM_LIMIT because this half is the expensive
            -- one: CaptureTooltip below reads and formats a whole tooltip.
            if seen < SCAN_ITEM_LIMIT and facts and not model.IsUnread(facts.quality)
                and facts.quality >= Enum.ItemQuality.Uncommon
                and (facts.classID == Enum.ItemClass.Armor
                    or facts.classID == Enum.ItemClass.Weapon) then
                seen = seen + 1
                local key = ("%s:%s %s %s q=%s cls=%s/%s predicted=%s"):format(
                    tostring(bagIndex), tostring(slotIndex),
                    tostring(facts.itemID), tostring(facts.name),
                    tostring(facts.quality), tostring(facts.classID),
                    tostring(facts.subclassID),
                    tostring(model.PredictDisenchantable(facts)))
                items[key] = CaptureTooltip(bagIndex, slotIndex, names)
            end
        end

        local scan = {
            state = ("targeting=%s canTargetItem=%s canTargetItemID=%s"
                .. " hasDisenchantSpell=%s isEnchanter=%s"):format(
                tostring(SpellIsTargeting()),
                tostring(SpellCanTargetItem()),
                tostring(SpellCanTargetItemID()),
                tostring(C_SpellBook.ContainsAnyDisenchantSpell()),
                tostring(model.GetIsEnchanter())),
            items = items,
            unreadable = unreadable,
        }

        BitForge:ShowReport(RenderDisenchantReport(scan), locale["report:blurbDisenchant"],
            BitForge:DiagnosticReportTitle())
    end
end

-- /bfdump azerothprime <itemID> answers for all three claimants at once: every
-- claim model.arbiter.Resolve collected, in claimant order, and which one
-- won. The two dumps above each answer for one path alone -- this is the one
-- screen that says what every path thought, which is what a player pastes
-- into an issue when they disagree with the addon (spec #356 Task 7).
--
-- Resolved from a bag slot when the item is carried, FindInBags first and
-- model.facts.Get/sellScanner.Gather behind it -- the same record every other
-- command in this file reads, with every LAZY field (hasLoot, tooltipData,
-- questID, carriedCount, isUncollectedAppearance) intact, so the open claimant
-- answers exactly as it would for the button. An item that is NOT carried falls
-- back to sellScanner.GatherByID rather than model.facts.GetPartial, whose
-- "bare skeleton" (bankRules.lua's own phrase) carries neither quality nor
-- classID, and the arbiter needs both to award anything; sellScanner's own
-- explain() already hands a GatherByID record to model.arbiter.Resolve. The
-- `source` field says which of the two answered: a bag-less answer has no
-- loot, tooltip or quest evidence behind it, and the reader has to know that
-- before trusting an ABSTAINED open row.
--
-- The file's one exception to its own no-flag rule sits in this block:
-- AppendZoneBlock below. It is gated, and not for the reason that rule is
-- about. Storage is not what gates it -- it stores nothing either -- the
-- AUDIENCE is: a map id says where the player was standing, which nothing else
-- in this report does, and the report:blurbDispatch footnote says it is
-- carried "with diagnostics enabled". Deleting that gate puts a location in
-- every player's paste and makes the footnote false. Any other block added
-- here takes the file's rule, not the exception.
do
    -- Every field is flattened with tostring, like every other dump in this
    -- file: tooltip-derived data can carry secret values in 12.0, and the
    -- claim reasons are enum keys (enum.RULE, enum.REASON, a DESTINATION),
    -- not sentences, so a raw tostring is the honest rendering of all of
    -- them alike.
    local function Flatten(value)
        return tostring(value)
    end

    -- Four states a claims entry can be in, not three: a losing claim, a
    -- plain abstention, and a suppressing override read identically if all a
    -- dump prints is claim/overridden/failed side by side -- this is what
    -- keeps them apart in the rendered text itself rather than only in the
    -- fields behind it. FAILED comes first because callClaimant's own guard
    -- (model/arbiter.lua) never sets `overridden` on a raised claimant, so
    -- checking claim/overridden first would read a raise as a plain
    -- abstention.
    local function ClaimStatus(entry)
        if entry.failed then return "FAILED" end
        if entry.claim then return "CLAIMED" end
        if entry.overridden == true then return "SUPPRESSED" end
        return "ABSTAINED"
    end

    local function BuildClaimLines(claims)
        local lines = {}
        for index, entry in ipairs(claims) do
            lines[index] = ("claims[%d] claimant=%s status=%s claim=%s strength=%s"
                .. " reason=%s overridden=%s failed=%s"):format(
                index, entry.claimant, ClaimStatus(entry),
                Flatten(entry.claim), Flatten(entry.strength),
                Flatten(entry.reason), Flatten(entry.overridden),
                Flatten(entry.failed == true))
        end
        return lines
    end

    -- Blizzard's own junk sweep takes every Poor-quality item before any
    -- claimant is heard, deliberately outside the arbiter (onMerchantShow's
    -- own comment says why). That leaves this dump as the only place that CAN
    -- say so: the verdict above is honest about what the arbiter decided, but
    -- a player reading KEEP on a grey item while it gets sold anyway has been
    -- told something false by omission if nothing here names the sweep.
    --
    -- The same three gates onMerchantShow itself checks, in the same order,
    -- because all three decide whether the sweep actually fires -- naming
    -- only the rule and skipping IsSellEnabled or IsSellAllJunkEnabled would
    -- warn about a sweep that would not happen.
    local function JunkSweepNote(facts)
        if facts.quality ~= Enum.ItemQuality.Poor then return nil end
        if not model.IsSellEnabled() then return nil end
        if not model.GetRule("junk").sell then return nil end
        if not C_MerchantFrame.IsSellAllJunkEnabled() then return nil end

        return "NOTE: Poor quality, and Sell Junk is on -- Blizzard's own sweep"
            .. " sells this the moment a merchant opens, before any claim below"
            .. " is heard. The disposition below may never be reached."
    end

    -- Which of the reagent rung's two layers answered, and on what (spec
    -- #379). This is the only place that CAN answer it: a reagent neither
    -- layer keeps FALLS THROUGH step 9 rather than being decided there, so
    -- the reason the verdict above reports is whichever later rule sold it --
    -- a rule with nothing to do with reagents. Without this block a player
    -- watching a herb sell has no way to find out that no marked recipe
    -- wanted it and its expansion was unticked.
    --
    -- It answers for the rung, not for the route the cascade actually took: a
    -- Poor item is decided at step 7 and never reaches step 9, and the block
    -- still says what step 9 would have answered. That is the question being
    -- asked, and the disposition above already says what was decided.
    --
    -- The order the answers are weighed in is this report's own, not
    -- model.Decide's: step 9 ANDs the profession mask against the two layers,
    -- so neither is read first there. Here the mask comes first because it
    -- gates the whole rung -- an expansion tick that kept nothing because no
    -- profession on the account uses the item would read as the answer if the
    -- mask were reported second.
    local REAGENT_FIELDS = {
        "professions", "scope", "wanted", "expacID", "expansionTicked",
        "markedRecipe", "audit",
    }

    ---@param facts table
    ---@param settings table  model.GetSettingsSnapshot's own return
    ---@return table|nil  nil for an item the catalogue does not name a
    ---   reagent, which is what model.Decide's step 9 does with the same nil
    local function ReagentAudit(facts, settings)
        local professions = facts.reagentProfessions
        if not professions then return nil end

        local reagents = settings.rules and settings.rules.reagents

        -- The account mask is a lie for a soulbound copy -- no alt can ever
        -- touch this one -- so step 9 narrows to this character's own
        -- professions there. Tested against false rather than for falsiness,
        -- as step 9 tests it: an unread bind state keeps the account mask.
        -- The scope has to be named or `wanted` reads as the wrong number.
        local scope, wanted = "account", settings.accountProfessions
        if model.CanReachAnAlt(facts) == false then
            scope, wanted = "character", settings.characterProfessions
        end

        local ticked = reagents ~= nil
            and model.IsExpansionSelected(reagents.expansions, facts, settings)
        local marked = model.sparedRecipes.WantsReagent(facts.itemID)

        local audit
        if not (reagents and reagents.keep) then
            audit = "RULE_OFF"
        elseif band(professions, wanted) == 0 then
            audit = "NO_PROFESSION"
        elseif ticked then
            audit = "EXPANSION_TICKED"
        elseif marked then
            audit = "MARKED_RECIPE"
        else
            audit = "NARROWED_OUT"
        end

        return {
            professions     = Flatten(professions),
            scope           = scope,
            wanted          = Flatten(wanted),
            expacID         = Flatten(facts.expacID),
            expansionTicked = Flatten(ticked),
            markedRecipe    = Flatten(marked),
            audit           = audit,
        }
    end

    --- Appends the marked-recipe list, so the second layer's answer above is
    --- checkable rather than an assertion the report makes about itself.
    ---
    --- The count is a field of its own because it is the one line that is
    --- always there: a player who has marked nothing still gets an answer to
    --- "which recipes am I sparing for", instead of a section that is absent
    --- for a reason they cannot see.
    ---
    --- GetRecipeInfo answers from the client's own recipe cache, and a
    --- character who has never opened that profession this session has none --
    --- so the ID alone is the honest rendering of a recipe it cannot name,
    --- and it is still what a bug report needs.
    ---
    --- Uncapped, where the disenchant scan in this same file stops at
    --- SCAN_ITEM_LIMIT, and the difference is not length. That limit caps WORK
    --- over a population the addon enumerates: every bag slot, with a whole
    --- tooltip built and formatted for each item it keeps. Here the player
    --- added every entry themselves through the only write path sparedRecipes
    --- has, and an entry costs one cached GetRecipeInfo. Length alone is
    --- already answered a layer up and losslessly -- BitForge:ShowReport
    --- encodes any body over COMPRESS_THRESHOLD and says so in the footnote --
    --- so a cap would buy nothing and pay for it by dropping the rows the
    --- section exists to show.
    ---@param lines string[]
    local function AppendMarkedRecipes(lines)
        local marked = model.sparedRecipes.List()
        lines[#lines + 1] = format("markedRecipes = %d", #marked)

        for index, recipeID in ipairs(marked) do
            local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
            local entry = Flatten(recipeID)
            if info and info.name then
                entry = entry .. " " .. Flatten(info.name)
            end
            lines[#lines + 1] = format("marked[%d] = %s", index, entry)
        end
    end

    -- Where the player was standing, and what the shipped gate says about
    -- this item (spec #390 section 6).
    --
    -- The one block in this file behind model.IsDebug(); the file's own header
    -- refuses the flag for everything else, and this block's header carries the
    -- exception. The reason is the audience rather than storage: this stores
    -- nothing either, but it answers for whoever maintains enum.ZONE_GATED
    -- rather than for the player pasting a verdict they disagree with, and a
    -- map id says where they were standing, which nothing else in this report
    -- does. report:blurbDispatch names it for that reason, as carried only
    -- with diagnostics enabled -- English-only diagnostic copy (CLAUDE.md's
    -- Diagnostics section), so there is one footnote to keep true, not eleven.
    --
    -- Read through model.zone, never C_Map here: that seam owns every such call
    -- in the module (model/zone.lua's own header) and holds the memo the rung
    -- itself read, so the block reports the location the verdict was reached at
    -- rather than a fresher one.

    --- An empty subzoneIDs is the wildcard -- any map whose parent is zoneID
    --- (OpenableData.lua's own comment) -- and it is named rather than left
    --- blank, since an empty value reads as a field that failed to render.
    ---@param subzoneIDs number[]
    ---@return string
    local function SubzoneList(subzoneIDs)
        if #subzoneIDs == 0 then return "any" end

        local ids = {}
        for index = 1, #subzoneIDs do
            ids[index] = Flatten(subzoneIDs[index])
        end
        return concat(ids, ",")
    end

    --- Which entry the gate answered on, as the text the block prints.
    ---
    --- Asked one entry at a time through the same model.zone.Matches the rung
    --- itself calls, rather than re-deciding here: a second copy of section
    --- 3's table would be a copy that can drift, and this block exists to
    --- explain a WRONG_ZONE, not to reach its own opinion of one.
    ---
    --- An unreadable location is a third answer and not "none". Matches falls
    --- through for it -- unknown never condemns -- so the item was offered
    --- rather than refused, and both "none" and an entry index would name a
    --- comparison that never happened.
    ---@param entries table[]  the item's enum.ZONE_GATED value
    ---@return string
    local function MatchedEntry(entries)
        if not model.zone.Here() then return "unread" end

        for index = 1, #entries do
            if model.zone.Matches({ entries[index] }) then return Flatten(index) end
        end
        return "none"
    end

    --- Appends the zone block, or nothing at all with diagnostics off.
    ---
    --- The two readings are appended for every item, gated or not: where the
    --- player was standing is context for any disagreement, not only for a
    --- WRONG_ZONE, and "always" is a property the test holds rather than a
    --- habit this comment claims.
    ---@param lines string[]
    ---@param itemID number
    local function AppendZoneBlock(lines, itemID)
        if not model.IsDebug() then return end

        local at = model.zone.Here()
        lines[#lines + 1] = ""
        lines[#lines + 1] = format("zone.uiMapID = %s", Flatten(at and at.uiMapID))
        lines[#lines + 1] = format("zone.parentMapID = %s", Flatten(at and at.parentMapID))

        local entries = enum.ZONE_GATED[itemID]
        if not entries then return end

        -- The one line that says the item is in the table at all. Not load
        -- bearing against an empty entry list -- tests/test_azerothprime_zone.lua's
        -- walk over the shipped table refuses that as malformed, so it cannot
        -- reach a release -- it is here so a reader sees "this item is gated"
        -- without inferring it from the presence of rows below.
        lines[#lines + 1] = "zone.gated = true"
        for index, entry in ipairs(entries) do
            lines[#lines + 1] = format("zone.entries[%d] = zoneID=%s subzoneIDs=%s",
                index, Flatten(entry.zoneID), SubzoneList(entry.subzoneIDs))
        end
        lines[#lines + 1] = format("zone.matched = %s", MatchedEntry(entries))
    end

    local DUMP_FIELDS = {
        "itemID", "source", "name", "link", "quality", "disposition",
        "claimant", "strength", "reason", "detail", "promoted",
    }

    local function BuildDump(facts, verdict, source)
        return {
            itemID      = Flatten(facts.itemID),
            source      = source,
            name        = Flatten(facts.name),
            link        = Flatten(facts.itemLink),
            quality     = Flatten(facts.quality),
            disposition = Flatten(verdict.disposition),
            claimant    = Flatten(verdict.claimant),
            strength    = Flatten(verdict.strength),
            reason      = Flatten(verdict.reason),
            detail      = Flatten(verdict.detail),
            promoted    = Flatten(verdict.promoted),
        }
    end

    --- One item's whole verdict -- every claim model.arbiter.Resolve
    --- collected and which one won -- as text a player can select and paste.
    ---@param facts table  a model.facts record, or a sellScanner.GatherByID one
    ---@param verdict table  model.arbiter.Resolve's own return
    ---@param source string  which of the two `facts` came from, rendered
    ---   verbatim as the `source` field -- see this block's own header
    ---   comment for why the reader has to be told.
    ---@param settings table  model.GetSettingsSnapshot's own return, which
    ---   the reagent audit reads the two profession masks and the expansion
    ---   threshold from
    ---@return string
    local function RenderDispatchReport(facts, verdict, source, settings)
        local dump = BuildDump(facts, verdict, source)
        local lines = {
            "BitForge AzerothPrime -- combined verdict",
            BitForge:ReportHeader(ADDON_NAME),
            "",
        }

        for _, field in ipairs(DUMP_FIELDS) do
            lines[#lines + 1] = format("%s = %s", field, dump[field])
        end

        local note = JunkSweepNote(facts)
        if note then
            lines[#lines + 1] = ""
            lines[#lines + 1] = note
        end

        local reagent = ReagentAudit(facts, settings)
        if reagent then
            lines[#lines + 1] = ""
            for _, field in ipairs(REAGENT_FIELDS) do
                lines[#lines + 1] = format("reagent.%s = %s", field, reagent[field])
            end
        end

        lines[#lines + 1] = ""
        AppendMarkedRecipes(lines)

        AppendZoneBlock(lines, facts.itemID)

        lines[#lines + 1] = ""
        for _, line in ipairs(BuildClaimLines(verdict.claims)) do
            lines[#lines + 1] = line
        end

        return concat(lines, "\n")
    end

    -- Rendered verbatim as the `source` field when the item is not carried:
    -- every field a bag slot alone can answer for -- hasLoot, a live
    -- tooltip, a quest gate -- is absent from a GatherByID record, so the
    -- open claimant's row can only ever abstain or read the player's own
    -- blacklist for an item resolved this way. Stated once, here, rather
    -- than repeated at every call site.
    local UNCARRIED_SOURCE = "not carried -- gathered by item ID alone, so the open claimant"
        .. " has no loot, tooltip or quest evidence to read and can only abstain or read"
        .. " your own blacklist"

    --- Show one item's whole verdict -- what every claimant said and which
    --- one won -- in the report window.
    ---
    --- Resolves the same way control.DumpOpenItem does when the item is
    --- carried -- FindInBags, then the bag-based record every other command
    --- in this file reads -- and falls back to sellScanner.GatherByID only
    --- when it is not. See this block's own header comment for why the
    --- fallback is GatherByID and not model.facts.GetPartial, and why the
    --- dump has to say which one answered.
    ---
    --- Nothing is stored, like every other command in this file: the record
    --- goes to the player, not to disk.
    ---@param itemID number
    function control.DumpVerdict(itemID)
        local facts, source
        local bag, slot = FindInBags(itemID)
        if bag then
            facts = sellScanner.Gather(bag, slot)
            source = ("bag %d slot %d"):format(bag, slot)
        else
            facts = sellScanner.GatherByID(itemID)
            source = UNCARRIED_SOURCE
        end

        if not facts then
            BitForge:Print(("AzerothPrime: item %d is not cached yet -- try again in a moment")
                :format(itemID))
            return
        end

        local verdict = model.arbiter.Resolve(facts)
        BitForge:ShowReport(
            RenderDispatchReport(facts, verdict, source, model.GetSettingsSnapshot()),
            locale["report:blurbDispatch"], BitForge:DiagnosticReportTitle())
    end
end

-- One argument grammar for all three debug-dump forms. "open" and "sell" name
-- one path's own answer, the same "open"/"sell" split
-- control.openScanner/control.sellScanner already carry; a bare itemID, with
-- no feature word, is the combined form and needs none -- it answers for all
-- three claimants at once, so there is no path left to pick between.
ns:SubscribeCommand(events.MODULE_DUMP, function(addon, argument)
    if addon ~= ADDON_NAME then return end

    local feature, remainder = argument:match("^(%S*)%s*(.-)$")

    if feature == "open" then
        local subcommand = remainder:match("%S+")
        -- Matched before the item ID, not after: "all" carries no digits, so
        -- the ID parse would silently read it as "no argument" and dump the
        -- button.
        if subcommand and subcommand:lower() == "all" then
            control.DumpOpenField()
            return
        end
        control.DumpOpenItem(tonumber(subcommand and subcommand:match("%d+")))
        return
    end

    if feature == "sell" then
        local subcommand = remainder:match("%S+")
        if subcommand and subcommand:lower() == "disenchant" then
            control.ScanDisenchant()
            return
        end
        control.DumpSellItem(tonumber(subcommand and subcommand:match("%d+")))
        return
    end

    -- Takes a list name at most: the subject is a curated list entire rather
    -- than one item, so the only thing to narrow it to is which of the two --
    -- and an unrecognised word falls through to the usage line rather than
    -- being read as "both", which would run 167 entries nobody asked for.
    if feature == "allowlist" then
        local subcommand = remainder:match("%S+")
        local list = subcommand and subcommand:lower()
        if list == nil or list == "allow" or list == "deny" then
            control.allowListAudit.Run(list)
            return
        end
    end

    -- A bare command (feature == "") falls through here rather than reading
    -- as "no itemID" the way "open"/"sell" alone do: neither reads as "dump
    -- the current item" for a command that has no notion of one.
    local itemID = feature ~= "" and tonumber(feature:match("^%d+$"))
    if itemID then
        control.DumpVerdict(itemID)
        return
    end

    BitForge:Print("AzerothPrime: /bfdump azerothprime <itemID> | open [<itemID>|all]"
        .. " | sell [<itemID>|disenchant] | allowlist [allow|deny]")
end, true)

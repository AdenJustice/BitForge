---@class BitForge.AzerothPrime
local ns = select(2, ...)

local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local format = string.format
local sort = table.sort

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local PixelUtil = PixelUtil
local band, bor, lshift = bit.band, bit.bor, bit.lshift

local UI = BitForge.UI
local colors = UI.Colors
local Profession = Enum.Profession

local model = ns.model
local enum = ns.enum
local locale = ns.locale
-- Captured once rather than reached through ns on every call. Safe despite
-- control.lua loading after this file: Init.lua owns the table and control.lua
-- only aliases it, the same way view/merchantPanel.lua reaches control.sellScanner.
local control = ns.control
---@class BitForge.AzerothPrime.View
local view = ns.view

---@class BitForge.AzerothPrime.View.RuleControls
local ruleControls = {}

local PADDING = 8
-- BitForgeFontSmall is 10pt; a wrapped line of it clears in 14.
local SMALL_LINE = 14

-- One row per control, and the gap under it. A stacked row -- the setting's
-- name on a line of its own above the control -- costs a line and a gap more.
-- A slider needs that shape for its readout; a dropdown needs it because its
-- name is a whole phrase in most locales and 170px of row is already spoken
-- for.
local ROW_HEIGHT = 26
local STACKED_ROW_HEIGHT = SMALL_LINE + 4 + ROW_HEIGHT
-- BitForge/Libs/LibBitForgeUI/Templates/Buttons.lua anchors a check button's
-- own label at LEFT + 26, past the tick. Every other builder draws its own
-- label, so it repeats that inset by hand -- without it the pane's rows
-- start their text at four different offsets.
local LABEL_INSET = 26
-- One width for all three dropdown kinds. Dropdown.lua's label anchor reserves
-- ARROW_SIZE 14 + H_PADDING 10 + 6 on the right and H_PADDING 10 on the left,
-- so 170 leaves 130px of text: enough for deDE's "Aktuelle Erweiterung" (118px
-- at 12pt, the widest expansion: row) and for the count the multi-select rows
-- show instead (deDE's "Ausgewählt: 15", 89px). 150 was not -- it left 110.
local DROPDOWN_WIDTH, DROPDOWN_HEIGHT = 170, 22

-- A dependant is greyed, never hidden: a control that vanishes reads as a
-- missing feature, and the rule it belongs to still exists.
--
-- Every dependency here is inverted -- live only while its parent is OFF.
-- model/rules.lua's IsExpansionSelected checks EXPANSION_ALL before
-- EXPANSION_CURRENT and returns KEEP unconditionally the moment either is
-- set, before either recipe column is read -- so recipesNow cannot change an
-- outcome under either bit, and EXPANSION_CURRENT ships as the default, which
-- is what left a control that provably did nothing looking like one that
-- did. recipesOld only goes dead under ALL: CURRENT alone still lets a past
-- item reach the age question. The value below is a predicate rather than a
-- parent key: gems.expansions is a mask and 0 is truthy in Lua, so testing
-- the stored value for truth would read "keep no expansion's gems" as "keep
-- them all" and grey the dependant out for good.
--
-- Keyed by section as well as key: `recipesNow` is also a consumables
-- descriptor, and those all point at one subclass dropdown that a second
-- writer here would grey out whole. The consumables copy of this dependency
-- lives in the menu entry instead, where the option actually is.
--
-- Shared with KIND.subclass's own recipesNow/recipesOld predicate below --
-- one helper per bit rather than the same band() repeated at both call sites.
local function KeepsEveryExpansion(mask)
    return band(mask or 0, enum.EXPANSION_ALL) ~= 0
end

local function KeepsCurrentExpansion(mask)
    return band(mask or 0, bor(enum.EXPANSION_ALL, enum.EXPANSION_CURRENT)) ~= 0
end

local DEAD_UNDER = {
    gems = {
        recipesNow = function(rule) return KeepsCurrentExpansion(rule.expansions) end,
        recipesOld = function(rule) return KeepsEveryExpansion(rule.expansions) end,
    },
}

--- The test that says this control is dead, if it has one.
---@param descriptor table
---@return (fun(rule: table): boolean)|nil
local function DeadUnder(descriptor)
    local section = DEAD_UNDER[descriptor.section]
    return section and section[descriptor.key]
end

-- A whole criterion's controls can be dead for a reason no rule carries.
-- rules.reagents is the case: model.Decide's reagent rung keeps a reagent only
-- where the account's profession mask overlaps the item's, so an account on
-- which no character has a profession keeps nothing by that rule whatever
-- either control says.
--
-- Keyed by criterion rather than added to DEAD_UNDER, which is keyed by
-- control: an entry per key would repeat one predicate and one explanation
-- string across the pane, and a third reagent control would have to remember
-- to add itself to be greyed at all, where a gate on the pane covers whatever
-- the pane comes to hold.
--
-- The relation differs as much as the bookkeeping. DEAD_UNDER greys one
-- control because a sibling setting has already settled its question -- a
-- cause one row away, inside rules, which that control's own tooltip still
-- describes correctly, so it keeps its own words. This greys every control at
-- once for a cause outside the rules that no amount of clicking in this window
-- can change, which is why a gated control is repointed at `why` instead.
--
-- Asked per paint, never captured while the pane is built: a player who learns
-- their first profession mid-session gets these controls back at the next open
-- rather than at the next reload.
local GROUP_GATE = {
    reagent = {
        IsDead = function() return BitForge:GetAccountProfessions() == 0 end,
        why = "ui:reagentsNoProfession",
    },
}

-- Enum.Profession itself, not a copy of it: BitForge/ReagentData.lua
-- introduces its own REAGENT_PROFESSION_BIT as "bit positions, matching
-- Enum.Profession", and that table is core-private (BitForge/Init.lua
-- publishes only SCHEMA_RESET and Events on the global). A second
-- fifteen-key list in this module would be that same hand-written array, just
-- relocated -- and silently short of a sixteenth profession Blizzard adds,
-- since nothing would enumerate it.
--
-- pairs() over a hash has no order, and a picker that reshuffles between
-- sessions is a bug the player sees. Ascending value is Enum.Profession's
-- own order, which is also the order the reagent catalogue's masks were
-- built in (both are lshift(1, profession)).
local PROFESSIONS = {}
do
    for professionKey, professionValue in pairs(Profession) do
        PROFESSIONS[#PROFESSIONS + 1] = { key = professionKey, value = professionValue }
    end
    sort(PROFESSIONS, function(left, right) return left.value < right.value end)
    for _, profession in ipairs(PROFESSIONS) do
        profession.bit = lshift(1, profession.value)
    end
end

--- How many of PROFESSIONS' bits a mask has set, for the closed dropdown's
--- count label -- "mask ~= 0" alone could not tell one ticked profession
--- from all fifteen.
---@param mask number
---@return number
local function ProfessionCount(mask)
    local count = 0
    for _, profession in ipairs(PROFESSIONS) do
        if band(mask, profession.bit) ~= 0 then count = count + 1 end
    end
    return count
end

--- How many rows of an expansion picker a mask has ticked, for the closed
--- label's count. CURRENT counts as a row of its own -- it is one of the
--- picker's checkboxes, and a count that skipped it would say "none" over a
--- control that plainly has something ticked. ALL never reaches here:
--- KIND.expansions' ShowState shows it as a named label before this is ever
--- called, so a mixed mask is the only shape this function sees.
---@param mask number
---@return number
local function ExpansionCount(mask)
    local count = 0
    if band(mask, enum.EXPANSION_CURRENT) ~= 0 then count = count + 1 end
    for expansion = 0, GetExpansionLevel() - 1 do
        if band(mask, lshift(1, expansion)) ~= 0 then count = count + 1 end
    end
    return count
end

--- The Sync of an entry that only points at a row somebody else built. The row
--- is repainted by the descriptor that built it, so doing it again once per
--- stored key would be three more passes over the same dropdown.
local function AlreadySynced() end

--- Every built pane, keyed by criterion, and which one is on screen. WoW
--- frames cannot be destroyed, so a pane is built once and shown or hidden
--- thereafter.
local panes = {}
local shownKey

local function LabelFor(descriptor)
    return locale["settings:" .. descriptor.name]
end

local function TooltipFor(descriptor)
    return locale["settings:" .. descriptor.name .. "Tooltip"]
end

--- Where one control files itself in its pane. consumables is the only section
--- keyed by subclass, and every one of its eight subclasses stores an
--- `expansions`, so leaving the subclass out of the path would file all eight
--- at `consumables.expansions` and lose seven.
---@param section string
---@param key string
---@param subclassID number|nil
---@return string
local function PathOf(section, key, subclassID)
    if subclassID then return section .. "." .. subclassID .. "." .. key end
    return section .. "." .. key
end

--- Rules are read by the manifest, so a change the player can see has to
--- reach it -- but only when the panel is up; away from a vendor a bag scan
--- per click would buy nothing.
local function Rescan()
    if view.merchantPanel.IsOpen() then control.sellScanner.Scan() end
end

--- What a multi-select dropdown says while it is closed: how many of its own
--- options are ticked, or that none are. Never the ticked names joined into a
--- list -- that is what these controls exist to avoid, and at fifteen
--- professions it would not fit the row.
---@param dropdown table
---@param count number
local function ShowSelectedCount(dropdown, count)
    dropdown.Label:SetText(count > 0 and format(locale["ui:selectedCount"], count)
        or locale["spare:none"])
end

--- Hands one dropdown the job of painting its own closed label, from the
--- stored value and never from DropdownButtonMixin's `selections` argument.
---
--- CollectSelectionData collects every IsSelected() description, so
--- `selections` is the ticked options themselves, and DropdownMixin's shared
--- implementation joins them with commas -- all fifteen profession names into
--- a 170px row, or every ticked expansion into one.
---@param dropdown table
---@param ShowStored fun()  repaints the closed label from the stored value
local function OwnsItsClosedLabel(dropdown, ShowStored)
    dropdown.UpdateToMenuSelections = ShowStored
end

--- A dropdown that ignores the mouse wheel. UI.CreateDropdown's mixin re-enables
--- it over the closed button so the wheel rotates the value, which in a pane
--- that scrolls means a player scrolling past a row writes a rule instead --
--- silently, and with a rescan behind it. Turned off here rather than in the
--- toolkit: rotation is defensible in a window whose controls sit still.
---@param container table
---@param placeholder string|nil
---@return table
local function CreateDropdown(container, placeholder)
    local dropdown = UI.CreateDropdown(container, placeholder)
    dropdown:EnableMouseWheel(false)
    return dropdown
end

--- What a control says on hover. A check button carries its own tooltip
--- through the mixin, which fires OnEnter while disabled on purpose
--- (BitForge/Libs/LibBitForgeUI/Templates/Buttons.lua); a slider or a
--- dropdown is explained by the region this file drew over its label, which
--- is never disabled at all.
---
--- KIND.subclass has neither. Its rows are named beside the menu and carry no
--- settings:<name>Tooltip to show, so a GROUP_GATE over consumables would find
--- nothing here to repoint -- and SetTooltips is a CheckButtonMixin method
--- that a dropdown does not answer, so reaching for it would raise inside a
--- paint pass. The guard is silence rather than a raise for that reason; the
--- harness cannot catch it either, since newFrame vivifies any method asked
--- for.
---@param entry table
---@param text string
local function Explain(entry, text)
    if entry.hover then
        entry.hover.explanation = text
    elseif entry.widget.SetTooltips then
        entry.widget:SetTooltips(text)
    end
end

--- Greys or revives every dependant in a pane from its parent's stored value,
--- and every control in it from the pane's own gate. One pass over the pane
--- rather than a branch per click handler, so a pane opens in the same state a
--- click leaves it in.
local function RefreshDependants(pane)
    local gate = pane.gate
    local groupDead = gate ~= nil and gate.IsDead()
    for _, entry in ipairs(pane.entries) do
        local IsDead = DeadUnder(entry.descriptor)
        if gate or IsDead then
            local live = not groupDead
                and not (IsDead and IsDead(model.GetRule(entry.descriptor.section)))
            entry.widget:SetEnabled(live)
            -- A control the gate killed explains the gate; one killed by a
            -- parent setting keeps its own tooltip, since the parent it depends
            -- on is a row away and its own words still describe it.
            if gate then
                Explain(entry, groupDead and locale[gate.why] or TooltipFor(entry.descriptor))
            end
            -- Only a label this file drew, never one CheckButtonMixin owns:
            -- a check button paints its own label from the checked, hovered and
            -- disabled states together, and a second writer here once fought it
            -- for the accent -- the mixin's own OnEnter brightened a greyed
            -- gear-pane checkbox right back. KIND.check learned that and returns
            -- no label, so this reaches only the rows this file labelled itself
            -- -- the reagent picker's, under the gate above.
            if entry.label then
                entry.label:SetTextColor((live and colors.text or colors.textDisabled):GetRGB())
            end
        end
    end
end

--- A write, less the rescan. Takes the pane so the dependants are re-evaluated
--- in the same click rather than at the next reselect.
local function Store(pane, descriptor, value)
    model.SetRuleValue(descriptor.section, descriptor.key, value)
    RefreshDependants(pane)
end

--- The one write path: store, then tell the manifest.
local function Commit(pane, descriptor, value)
    Store(pane, descriptor, value)
    Rescan()
end

--- A GameTooltip on hover for a widget the toolkit does not give one to.
--- UI.CreateCheckButton carries SetTooltips and hooks its own OnEnter, so a
--- checkbox needs none of this; a slider and a dropdown have no such hook, and
--- their explanation hangs off a mouse-enabled region over the row's label
--- instead -- over the label alone, so the widget beside it stays clickable.
---@param parent table
---@param over table  the region to cover
---@param text string
---@return table
local function CreateHoverRegion(parent, over, text)
    local region = CreateFrame("Frame", nil, parent)
    region:SetAllPoints(over)
    region:EnableMouse(true)
    -- On the region rather than closed over, so RefreshDependants can repoint
    -- it: a control the gate above has greyed must stop explaining the setting
    -- it is no longer answering.
    region.explanation = text
    region:SetScript("OnEnter", function(self)
        local r, g, b = colors.textHover:GetRGB()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.explanation, r, g, b, 1, true)
        GameTooltip:Show()
    end)
    region:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return region
end

--- The name of a setting, drawn either beside the control it belongs to or on
--- a line of its own above it. Same inset either way, so the pane reads as one
--- column whichever shape a row took.
---@param container table
---@param descriptor table
---@param offsetY number
---@param text string
---@param beside table|nil  the control sharing the row, if it shares one
---@return table
local function CreateRowLabel(container, descriptor, offsetY, text, beside)
    local label = container:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
    PixelUtil.SetPoint(label, "TOPLEFT", container, "TOPLEFT", LABEL_INSET, -offsetY)
    if beside then
        PixelUtil.SetPoint(label, "BOTTOMRIGHT", beside, "BOTTOMLEFT", -PADDING, 0)
    else
        PixelUtil.SetPoint(label, "TOPRIGHT", container, "TOPRIGHT", 0, -offsetY)
    end
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetTextColor(colors.text:GetRGB())
    label:SetText(text)
    return label
end

--- A dropdown under its own label rather than beside it. Beside is what the
--- eight consumable rows need -- eight of them have to fit one pane -- but it
--- leaves a label 316 - 26 - 170 - 8 = 112px, and `settings:spareBindOnEquip`
--- alone wants 271 of them in itIT and 221 in deDE. Only two of the eight
--- labels in that shape fit at 158px, let alone 112.
---@param container table
---@param descriptor table
---@param offsetY number
---@param placeholder string|nil
---@return table dropdown, table label
local function CreateStackedDropdown(container, descriptor, offsetY, placeholder)
    local label = CreateRowLabel(container, descriptor, offsetY, LabelFor(descriptor))
    local dropdown = CreateDropdown(container, placeholder)
    PixelUtil.SetPoint(dropdown, "TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    PixelUtil.SetSize(dropdown, DROPDOWN_WIDTH, DROPDOWN_HEIGHT, 1, 1)
    return dropdown, label
end

--- One builder per control kind. A criterion's control is skipped outright
--- when its kind has no builder here, so a kind added to a descriptor ahead of
--- its widget draws nothing rather than raising.
---@type table<string, fun(pane: table, container: table, descriptor: table, offsetY: number): table>
local KIND = {}

--- Which builder draws a control -- not `descriptor.kind` alone. The
--- consumable descriptors all say `kind = "check"` whether their stored key is
--- a boolean or a mask, but they are drawn as eight menus rather than
--- twenty-four labelled checkbox rows, and carrying a subclass is what says so.
local function KindOf(descriptor)
    return descriptor.subclass and "subclass" or descriptor.kind
end

KIND.check = function(pane, container, descriptor, offsetY)
    local button = UI.CreateCheckButton(nil, container, LabelFor(descriptor), true)
    PixelUtil.SetPoint(button, "TOPLEFT", container, "TOPLEFT", 0, -offsetY)
    button:SetTooltips(TooltipFor(descriptor))
    button:SetScript("OnClick", function(self)
        Commit(pane, descriptor, self:GetChecked() and true or false)
    end)

    -- No `label`: the button's own is CheckButtonMixin's to paint (see
    -- RefreshDependants), and SetEnabled above is what tells it to.
    return {
        widget = button,
        height = ROW_HEIGHT,
        Sync = function()
            button:SetChecked(model.GetRule(descriptor.section)[descriptor.key] and true or false)
        end,
    }
end

--- One path for both write sites (the change handler and Sync), so a future
--- change cannot land in one and not the other.
---
--- A slider whose descriptor names a topName tops out at a position rather than
--- at a quantity, so the number there would be read as one -- it draws the
--- word instead.
local function WriteReadout(readout, descriptor, value)
    if descriptor.topName and value >= descriptor.max then
        readout:SetText(locale["settings:" .. descriptor.topName])
    else
        readout:SetText(tostring(value))
    end
end

KIND.slider = function(pane, container, descriptor, offsetY)
    local label = CreateRowLabel(container, descriptor, offsetY, LabelFor(descriptor))

    -- The number the track alone cannot say. Bare digits, except at a
    -- descriptor's topName position, where WriteReadout draws its own string
    -- instead.
    local readout = container:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
    PixelUtil.SetPoint(readout, "TOPRIGHT", label, "TOPRIGHT", 0, 0)
    readout:SetJustifyH("RIGHT")
    readout:SetTextColor(colors.point:GetRGB())

    local slider = UI.CreateSlider(container)
    PixelUtil.SetPoint(slider, "TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    PixelUtil.SetPoint(slider, "TOPRIGHT", label, "BOTTOMRIGHT", 0, -4)
    -- Carried on the descriptor since the tree gained a second slider with a
    -- different range.
    slider:SetMinMaxValues(descriptor.min, descriptor.max)
    slider:SetValueStep(descriptor.step)
    slider:SetObeyStepOnDrag(true)

    -- The rescan a drag owes, paid once when the thumb is let go.
    local rescanOwed = false

    -- SetOnChange fires on drags only, not on the SetValue below, so a repaint
    -- cannot write the value back at itself.
    slider:SetOnChange(function(value)
        WriteReadout(readout, descriptor, value)
        -- Stored on every step, so the readout and the rule never disagree.
        -- Only the rescan waits: control.sellScanner.Scan re-decides every
        -- occupied slot -- Gather and model.Decide per item -- then rebuilds
        -- the manifest and repopulates the scroll box, and 0..30 in twos
        -- under SetObeyStepOnDrag is up to fifteen of those in one drag --
        -- with the manifest open, which is the primary way into this window.
        Store(pane, descriptor, value)
        if slider:IsDraggingThumb() then
            rescanOwed = true
        else
            Rescan()
        end
    end)
    -- The drag's other end. Nothing is owed unless a step was taken with the
    -- thumb down, so a press that moved nothing costs no scan.
    slider:HookScript("OnMouseUp", function()
        if rescanOwed then
            rescanOwed = false
            Rescan()
        end
    end)

    return {
        widget = slider,
        label = label,
        readout = readout,
        hover = CreateHoverRegion(container, label, TooltipFor(descriptor)),
        regions = { label, readout },
        height = STACKED_ROW_HEIGHT,
        Sync = function()
            local value = model.GetRule(descriptor.section)[descriptor.key]
            slider:SetValue(value)
            WriteReadout(readout, descriptor, value)
        end,
    }
end

--- tradeGoods.professions is one stored bitmask behind fifteen menu entries,
--- so this is the picker's own control kind rather than fifteen KIND.check
--- rows: one descriptor still means one entry, filed once in pane.byPath. A
--- menu sizes to its own content, so unlike a grid of chips it needs no
--- column arithmetic against the detail pane's width, and it costs one row
--- rather than several.
KIND.professions = function(pane, container, descriptor, offsetY)
    -- The same stacked-dropdown shape every dropdown row in this file uses: a
    -- label naming the setting, the dropdown under it showing the current
    -- state.
    local dropdown, label = CreateStackedDropdown(container, descriptor, offsetY, locale["spare:none"])

    local function ShowCount(mask)
        ShowSelectedCount(dropdown, ProfessionCount(mask))
    end
    -- The mask, never the `selections` argument -- see OwnsItsClosedLabel. The
    -- two direct calls below read only the mask too.
    OwnsItsClosedLabel(dropdown, function()
        ShowCount(model.GetRule(descriptor.section)[descriptor.key] or 0)
    end)

    dropdown:SetupMenu(function(_, root)
        for _, profession in ipairs(PROFESSIONS) do
            -- PROFESSIONS is Enum.Profession itself, so a sixteenth profession
            -- Blizzard adds arrives here before its profession: string does.
            -- The key is not a name, but it is legible and it is not a blank
            -- menu entry.
            root:CreateCheckbox(locale["profession:" .. profession.key] or profession.key,
                function(professionBit)
                    return band(model.GetRule(descriptor.section)[descriptor.key] or 0, professionBit) ~= 0
                end,
                function(professionBit)
                    local mask = model.GetRule(descriptor.section)[descriptor.key] or 0
                    if band(mask, professionBit) ~= 0 then
                        mask = mask - professionBit
                    else
                        mask = bor(mask, professionBit)
                    end
                    Commit(pane, descriptor, mask)
                    ShowCount(mask)
                end,
                profession.bit)
        end
    end)

    return {
        widget = dropdown,
        label = label,
        hover = CreateHoverRegion(container, label, TooltipFor(descriptor)),
        regions = { label },
        height = STACKED_ROW_HEIGHT,
        -- The checkboxes read the stored mask as they are built, so
        -- regenerating is what makes the menu answer a mask written
        -- elsewhere; the closed label is set from that same mask directly,
        -- not left to whatever GenerateMenu's own selection plumbing would
        -- produce.
        Sync = function()
            dropdown:GenerateMenu()
            ShowCount(model.GetRule(descriptor.section)[descriptor.key] or 0)
        end,
    }
end

--- The rows every expansion picker offers, built into whatever menu node is
--- handed in -- a root for a standalone control, a submenu for a consumable row.
---
--- Built per open rather than once at file scope: GetExpansionLevel can change
--- mid-session, on the day an expansion releases, and a cached list would offer
--- no row for the expansion the player is standing in.
---
--- Vanilla is a row like the rest, at bit 0. model.IsExpansionSelected reads
--- expacID 0 as Vanilla and answers it from that bit like any other expansion
--- (spec #379), so without the row nothing could ever set it and every Vanilla
--- item would be sold whatever the player ticked. Its name comes from the
--- client the same way its siblings' do -- Blizzard's own expansion filter
--- starts at 0 for the same reason, and says so (Blizzard_ToyBox.lua,
--- "EXPANSION_NAME is indexed from 0").
---@param node table  a menu root or submenu
---@param GetMask fun(): number
---@param SetMask fun(mask: number)
local function PopulateExpansionRows(node, GetMask, SetMask)
    local function IsTicked(rowBit) return band(GetMask(), rowBit) ~= 0 end
    local function Toggle(rowBit)
        local mask = GetMask()
        if band(mask, rowBit) ~= 0 then
            SetMask(mask - rowBit)
        else
            SetMask(bor(mask, rowBit))
        end
    end

    node:CreateCheckbox(locale["expansion:all"], IsTicked, Toggle, enum.EXPANSION_ALL)
    node:CreateCheckbox(locale["expansion:current"], IsTicked, Toggle, enum.EXPANSION_CURRENT)
    for expansion = 0, GetExpansionLevel() - 1 do
        node:CreateCheckbox(GetExpansionName(expansion), IsTicked, Toggle, lshift(1, expansion))
    end
end

--- An expansion selection is one stored bitmask behind a menu of expansions, so
--- this is a picker of its own rather than a row of checkboxes -- the same shape
--- and the same reason as KIND.professions above, and the same shape Blizzard's
--- own expansion filters use (Blizzard_ToyBox.lua).
KIND.expansions = function(pane, container, descriptor, offsetY)
    local dropdown, label = CreateStackedDropdown(container, descriptor, offsetY, locale["spare:none"])

    local function StoredMask()
        return model.GetRule(descriptor.section)[descriptor.key] or 0
    end

    -- Named while a single role answers for the whole mask, counted otherwise.
    -- A bare count would be a legibility regression against the dropdown this
    -- replaces, which named its choice.
    local function ShowState()
        local mask = StoredMask()
        if band(mask, enum.EXPANSION_ALL) ~= 0 then
            dropdown.Label:SetText(locale["expansion:all"])
        elseif mask == enum.EXPANSION_CURRENT then
            dropdown.Label:SetText(GetExpansionName(GetExpansionLevel()))
        else
            ShowSelectedCount(dropdown, ExpansionCount(mask))
        end
    end

    OwnsItsClosedLabel(dropdown, ShowState)

    dropdown:SetupMenu(function(_, root)
        PopulateExpansionRows(root, StoredMask, function(mask)
            Commit(pane, descriptor, mask)
            ShowState()
        end)
    end)

    return {
        widget = dropdown,
        label = label,
        hover = CreateHoverRegion(container, label, TooltipFor(descriptor)),
        regions = { label },
        height = STACKED_ROW_HEIGHT,
        Sync = function()
            dropdown:GenerateMenu()
            ShowState()
        end,
    }
end

-- The two recipe columns a consumable row offers under its expansion submenu.
-- The submenu itself is not in this list: it shares neither its widget nor its
-- handler with a checkbox, so it is built on its own rather than through a
-- loop pretending to cover all three. These two are what is left for a loop to
-- drive.
local CONSUMABLE_RECIPE_COLUMNS = { "recipesNow", "recipesOld" }

--- rules.consumables is the tree's only section keyed by subclass: eight of
--- them carrying three stored keys each. Each subclass is one row -- a menu of
--- its own options -- rather than a column in a grid: a menu sizes to its own
--- content, so an option can say what it keeps in a phrase, where three column
--- headers would each be one word in eleven languages.
---
--- The descriptor table still holds all twenty-four controls, which is what
--- tests/test_batchsell_descriptors.lua protects, so this runs twenty-four
--- times: the first descriptor of a subclass builds that subclass's row and
--- every later one folds onto it at zero height. pane.byPath still gets an
--- entry per stored key -- that is what __cell addresses -- while pane.height
--- counts each row once.
KIND.subclass = function(pane, container, descriptor, offsetY)
    -- On the pane rather than a file-local: two panes over the same criterion
    -- would otherwise hand each other the first one's widgets.
    local rows = pane.subclassRows
    if not rows then
        rows = {}
        pane.subclassRows = rows
    end

    local subclassID = descriptor.subclass
    local built = rows[subclassID]
    if built then
        return { widget = built, height = 0, Sync = AlreadySynced }
    end

    --- Re-read rather than captured: the menu is generated on open and its
    --- callbacks answer later still, so nothing here may hold a row across a
    --- write it did not make.
    local function Stored()
        return model.GetRule("consumables")[subclassID]
    end

    local dropdown = CreateDropdown(container, locale["spare:none"])
    PixelUtil.SetPoint(dropdown, "TOPRIGHT", container, "TOPRIGHT", 0, -offsetY)
    PixelUtil.SetSize(dropdown, DROPDOWN_WIDTH, DROPDOWN_HEIGHT, 1, 1)

    -- The item type the player sees next to their own bags, named BESIDE the
    -- menu rather than above it like every other dropdown row here: eight of
    -- these share one pane, and a line each for the name would add 144px to it
    -- for nothing the noun beside the menu does not already say. It fits at all
    -- because a sub: string is a noun -- deDE's "Fläschchen & Phiolen" is the
    -- widest at 100px against the 112 the row leaves -- where a settings: label
    -- is a whole phrase.
    --
    -- No hover region over it, unlike every other labelled row: these
    -- descriptors carry no `name`, so there is no settings:<name>Tooltip to
    -- show, and the options inside the menu are phrases that explain
    -- themselves.
    local label = CreateRowLabel(container, descriptor, offsetY,
        locale["sub:" .. subclassID], dropdown)

    -- expansions is a mask, and 0 is truthy in Lua, so it cannot be counted by
    -- the same test as the two booleans beside it.
    local function ShowCount()
        local stored, count = Stored(), 0
        if (stored.expansions or 0) ~= 0 then count = count + 1 end
        if stored.recipesNow then count = count + 1 end
        if stored.recipesOld then count = count + 1 end
        ShowSelectedCount(dropdown, count)
    end
    OwnsItsClosedLabel(dropdown, ShowCount)

    dropdown:SetupMenu(function(_, root)
        local submenu = root:CreateButton(locale["option:expansions"])
        PopulateExpansionRows(submenu,
            function() return Stored().expansions or 0 end,
            function(mask)
                model.SetConsumableRuleValue(subclassID, "expansions", mask)
                Rescan()
                ShowCount()
            end)

        for _, optionKey in ipairs(CONSUMABLE_RECIPE_COLUMNS) do
            local option = root:CreateCheckbox(locale["option:" .. optionKey],
                function() return Stored()[optionKey] and true or false end,
                function()
                    -- The nested setter, always: SetRuleValue indexes a section
                    -- and assigns, so it would replace the subclass table with
                    -- a boolean.
                    model.SetConsumableRuleValue(subclassID, optionKey, not Stored()[optionKey])
                    Rescan()
                    ShowCount()
                end)

            -- The same two bits DEAD_UNDER greys the gems pane on, and for the
            -- reason recorded there. A predicate rather than a boolean because a
            -- checkbox answers MenuResponse.Refresh, which reinitializes the
            -- open menu without regenerating it.
            if optionKey == "recipesNow" then
                option:SetEnabled(function()
                    return not KeepsCurrentExpansion(Stored().expansions)
                end)
            elseif optionKey == "recipesOld" then
                option:SetEnabled(function()
                    return not KeepsEveryExpansion(Stored().expansions)
                end)
            end
        end
    end)

    rows[subclassID] = dropdown

    return {
        widget = dropdown,
        label = label,
        regions = { label },
        height = ROW_HEIGHT,
        -- The checkboxes read the stored row as they are built, so regenerating
        -- is what makes the menu answer a write from elsewhere; the closed
        -- label comes from that same row rather than from GenerateMenu's own
        -- selection plumbing.
        Sync = function()
            dropdown:GenerateMenu()
            ShowCount()
        end,
    }
end

ruleControls.KIND = KIND

local function SetPaneShown(pane, shown)
    for _, entry in ipairs(pane.entries) do
        entry.widget:SetShown(shown)
        if entry.hover then entry.hover:SetShown(shown) end
        for _, region in ipairs(entry.regions or {}) do region:SetShown(shown) end
    end
end

local function BuildPane(container, criterion)
    local pane = { entries = {}, byPath = {}, height = 0, gate = GROUP_GATE[criterion.key] }
    for _, descriptor in ipairs(criterion.controls or {}) do
        local build = KIND[KindOf(descriptor)]
        if build then
            local entry = build(pane, container, descriptor, pane.height)
            entry.descriptor = descriptor
            pane.entries[#pane.entries + 1] = entry
            pane.byPath[PathOf(descriptor.section, descriptor.key, descriptor.subclass)] = entry
            pane.height = pane.height + entry.height
        end
    end
    return pane
end

--- Draws one criterion's controls into `container`, building them on the first
--- call and reusing them on every later one. Whichever criterion was showing
--- is hidden first -- including when this one has no controls to draw, which
--- is what stops a locked criterion leaving the previous one's on screen.
---
--- Answers how tall the drawn pane is, because the caller scrolls it: a scroll
--- child has to be told its own height, and this is the only place that knows
--- it. Zero for a criterion with nothing to draw.
---@param container table  the scroll child the controls are built into
---@param criterion table  a view.ruleDescriptors entry, or a ruleWindow row
---                        carrying the same `key` and `controls`
---@return number height
function ruleControls.Render(container, criterion)
    local showing = shownKey and panes[shownKey]
    if showing then SetPaneShown(showing, false) end

    local pane = panes[criterion.key]
    if not pane then
        pane = BuildPane(container, criterion)
        panes[criterion.key] = pane
    end

    -- No builder puts a value into the widget it just made -- every one of them
    -- leaves that to Sync -- so the first render of a pane has to run this.
    -- Every later one runs it too: a pane is built once and outlives many opens
    -- of the window, and one pass over at most eight controls is cheaper than
    -- making every future writer remember to repaint a pane that was hidden
    -- when it ran. This file is the only writer of any of the 54 keys today.
    for _, entry in ipairs(pane.entries) do entry.Sync() end
    RefreshDependants(pane)
    SetPaneShown(pane, true)
    shownKey = criterion.key
    return pane.height
end

--- Test seam: one criterion's widgets, in the order they were drawn.
---@param criterionKey string
---@return table[]
function ruleControls.__widgets(criterionKey)
    local pane = panes[criterionKey]
    local widgets = {}
    if pane then
        for index, entry in ipairs(pane.entries) do widgets[index] = entry.widget end
    end
    return widgets
end

--- Test seam: the widget that reads and writes one stored key.
---@param criterionKey string
---@param section string
---@param key string
---@return table|nil
function ruleControls.__widget(criterionKey, section, key)
    local pane = panes[criterionKey]
    local entry = pane and pane.byPath[PathOf(section, key)]
    return entry and entry.widget
end

--- Test seam: the widget that reads and writes one consumable subclass's key.
--- Four of these answer the same row, which is the point of it.
---@param subclassID number
---@param key string
---@return table|nil
function ruleControls.__cell(subclassID, key)
    local pane = panes.consumables
    local entry = pane and pane.byPath[PathOf("consumables", key, subclassID)]
    return entry and entry.widget
end

--- Test seam: one consumable subclass's row, or nil for a subclass that stores
--- nothing and so draws none.
---@param subclassID number
---@return table|nil
function ruleControls.__subclassDropdown(subclassID)
    local pane = panes.consumables
    return pane and pane.subclassRows and pane.subclassRows[subclassID] or nil
end

--- The digits beside a slider's track, for a test that has to prove what the
--- player reads rather than what is stored.
---@param criterionKey string
---@param section string
---@param key string
---@return string|nil
function ruleControls.__readout(criterionKey, section, key)
    local pane = panes[criterionKey]
    local entry = pane and pane.byPath[PathOf(section, key)]
    return entry and entry.readout and entry.readout:GetText()
end

--- Test seam: what a hover over that control's row tooltips from. A checkbox
--- is its own hover target; everything else gets a region of its own.
---@param criterionKey string
---@param section string
---@param key string
---@return table|nil
function ruleControls.__hoverRegion(criterionKey, section, key)
    local pane = panes[criterionKey]
    local entry = pane and pane.byPath[PathOf(section, key)]
    return entry and (entry.hover or entry.widget)
end

--- Test seam: how tall one criterion's controls came out. What proves a pane
--- laid its rows out at the pitch it claims -- the consumables pane counts
--- eight rows and not twenty-four -- and what Render answers to the window.
---@param criterionKey string
---@return number
function ruleControls.__contentHeight(criterionKey)
    local pane = panes[criterionKey]
    return pane and pane.height or 0
end

view.ruleControls = ruleControls

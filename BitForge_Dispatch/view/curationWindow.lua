---@type string, BitForge.Dispatch
local ADDON_NAME, ns = ...

local format = string.format
local ipairs = ipairs
local match = string.match
local tconcat = table.concat
local tinsert = table.insert
local tostring = tostring

local CreateFrame = CreateFrame
local C_Item = C_Item
local CreateDataProvider = CreateDataProvider
local CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local GameTooltip = GameTooltip
local MenuUtil = MenuUtil
local PixelUtil = PixelUtil
local ScrollUtil = ScrollUtil

local UI = BitForge.UI
local enum = ns.enum
local model = ns.model
local locale = ns.locale
local control = ns.control

---@class BitForge.Dispatch.View
local view = ns.view

---@class BitForge.Dispatch.View.CurationWindow
local curationWindow = {}

local CURATION_WIDTH = 660
local CURATION_HEIGHT = 480
local CURATION_ROW_HEIGHT = 22
local CURATION_PADDING = 8
local CURATION_CONTROL_HEIGHT = 24

-- The title bar UI.CreateFrame draws is 32px tall (APIs/UI/Templates/Frame.lua),
-- so anything anchored below it starts at -32.
local TITLE_BAR_HEIGHT = 32

-- Fixed columns, measured from the right edge inward, so the name column takes
-- whatever is left and stays readable at the window's fixed width.
local COLUMN_DESTINATION = 120
local COLUMN_HOLDERS = 130
local COLUMN_KIND = 110

-- Two lines of wrapped banner text, or a hairline when there is nothing to say.
-- The scroll box anchors to the banner frame, so it has to have a height either
-- way rather than being hidden.
local BANNER_HEIGHT = 30
local BANNER_HEIGHT_EMPTY = 1

local CURATION_GLOBAL_NAME = ADDON_NAME .. "CurationWindow"

local DESTINATION = enum.DESTINATION

local curationFrame
local ownedCache = {}
local activeSourceName

-- nil in any field means "no filter". Persisted for the session only: a filter
-- is a way of finding one item, not a setting.
local filters = { destination = nil, classID = nil, search = nil }

--- The character half of a "Name-Realm" key. Realms are long and identical
--- across the account, so a row that spelled them out would spend its whole
--- holders column saying the same thing.
---@param charKey string
---@return string
local function shortCharacterName(charKey)
    return match(charKey, "^([^-]+)") or charKey
end

---@param row table
---@return string
local function holderText(row)
    local count = #row.holders
    if count == 0 then return "" end

    if count == 1 then
        return format("%s (%d)", shortCharacterName(row.holders[1].charKey), row.holders[1].count)
    end

    -- The full breakdown is in the tooltip; the column only has to say "more
    -- than one, and here is the first".
    return format("%s +%d", shortCharacterName(row.holders[1].charKey), count - 1)
end

--- The destination column's text.
---
--- For a private row this names only the *current* owners, unlike the Owners
--- submenu, which lists every known character. The row reports state and the
--- menu offers a choice, and the two want opposite lists.
---@param row table
---@return string
local function destinationText(row)
    local text

    if row.destination == DESTINATION.WARBAND then
        text = locale["dest:warband"]
    elseif row.destination == DESTINATION.PRIVATE then
        if #row.owners > 0 then
            local names = {}
            for _, charKey in ipairs(row.owners) do
                names[#names + 1] = shortCharacterName(charKey)
            end
            text = format(locale["dest:privateOwned"], tconcat(names, ", "))
        else
            text = locale["dest:private"]
        end

        if row.target then
            text = text .. " " .. format(locale["curation:targetSuffix"], row.target)
        end
    else
        text = locale["dest:ignore"]
    end

    if row.isOverride then
        return enum.COLOR.OVERRIDE:WrapTextInColorCode(text)
    end

    return text
end

local function onCurationRowMouseDown(row, button)
    if button ~= "RightButton" then return end

    local data = row._data
    if not data then return end

    local itemID = data.itemID

    -- Built on demand for one row and discarded. Per-row destination widgets in
    -- a recycled WowScrollBoxList element would mean re-binding controls on
    -- every scroll.
    MenuUtil.CreateContextMenu(row, function(_, rootDescription)
        rootDescription:CreateTitle(data.name)

        -- The radio reflects the resolved destination rather than the stored
        -- override, so exactly one is always checked. A menu that opened with
        -- nothing selected -- which is what the override alone would give for
        -- almost every row -- reads as broken.
        local function isSelected(destination)
            return model.bankRules.Resolve(itemID) == destination
        end

        local function setSelected(destination)
            model.bankRules.SetDestination(itemID, destination)
            curationWindow.Refresh()
        end

        rootDescription:CreateRadio(locale["dest:warband"], isSelected, setSelected,
            DESTINATION.WARBAND)
        rootDescription:CreateRadio(locale["dest:private"], isSelected, setSelected,
            DESTINATION.PRIVATE)
        rootDescription:CreateRadio(locale["dest:ignore"], isSelected, setSelected,
            DESTINATION.IGNORE)

        -- Owners and targets only mean anything for a private item; offering
        -- them on a warband row would be offering a setting that silently does
        -- nothing. This guard is also what enforces that rather than merely
        -- respecting it: model.overrides.SetTarget and ToggleOwner are ungated
        -- by design -- the store holds no opinion about which of its fields
        -- imply each other -- so build these two submenus outside the guard and
        -- an owner set survives on an item nobody may own.
        if model.bankRules.Resolve(itemID) == DESTINATION.PRIVATE then
            rootDescription:CreateDivider()

            -- Every known character, not only the assigned ones: listing only
            -- the assigned ones would make the set impossible to grow. The keys
            -- come from the core rather than from an adapter, because an owner
            -- key that can never equal GetCurrentCharacter() strands the item
            -- in shared storage with nobody entitled to reclaim it.
            local ownersMenu = rootDescription:CreateButton(locale["menu:owners"])
            for _, charKey in ipairs(BitForge:GetKnownCharacters()) do
                local owner = charKey
                ownersMenu:CreateCheckbox(shortCharacterName(owner),
                    function() return model.overrides.IsOwner(itemID, owner) end,
                    function()
                        model.overrides.ToggleOwner(itemID, owner)
                        curationWindow.Refresh()
                    end)
            end

            local function isTarget(value)
                return model.overrides.GetTarget(itemID) == value
            end

            local function setTarget(value)
                model.overrides.SetTarget(itemID, value)
                curationWindow.Refresh()
            end

            local targetMenu = rootDescription:CreateButton(locale["menu:target"])
            targetMenu:CreateRadio(locale["menu:targetNone"], isTarget, setTarget, nil)
            for _, amount in ipairs(enum.TARGET_PRESETS) do
                targetMenu:CreateRadio(tostring(amount), isTarget, setTarget, amount)
            end
            targetMenu:CreateButton(locale["menu:targetOther"], function()
                view.targetDialog.Show(itemID, data.name, setTarget)
            end)
        end

        rootDescription:CreateDivider()

        -- Redundant with picking the rule's own answer, and kept anyway: it is
        -- the only phrasing that says "stop deciding this for me" without the
        -- user having to know what the rule would decide.
        rootDescription:CreateButton(locale["menu:resetToDefault"], function()
            model.bankRules.ClearDestination(itemID)
            curationWindow.Refresh()
        end)
    end)
end

local function onCurationRowEnter(row)
    local data = row._data
    if not data then return end

    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(data.itemID)

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(locale["curation:heldBy"], 1, 1, 1)
    for _, holder in ipairs(data.holders) do
        GameTooltip:AddDoubleLine(holder.charKey, holder.count, 0.8, 0.8, 0.8, 1, 1, 1)
    end

    -- What "your bank" actually means for this row, including who may claim it
    -- when nobody has been named. The destination column has room for the owner
    -- names but not for the rule.
    if data.destination == DESTINATION.PRIVATE then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(locale["curation:privateTooltip"], 1, 1, 1, true)
    end

    if data.isOverride then
        GameTooltip:AddLine(" ")
        local color = enum.COLOR.OVERRIDE
        GameTooltip:AddLine(locale["curation:overrideTooltip"], color.r, color.g, color.b, true)
    end

    GameTooltip:Show()
end

local function onCurationRowLeave()
    GameTooltip:Hide()
end

local function initCurationRow(row, data)
    if not row.icon then
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(16, 16)
        PixelUtil.SetPoint(row.icon, "LEFT", row, "LEFT", 4, 0)

        row.destination = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.destination, "RIGHT", row, "RIGHT", -4, 0)
        row.destination:SetWidth(COLUMN_DESTINATION)
        row.destination:SetJustifyH("RIGHT")

        row.holders = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.holders, "RIGHT", row.destination, "LEFT", -6, 0)
        row.holders:SetWidth(COLUMN_HOLDERS)
        row.holders:SetJustifyH("RIGHT")

        row.kind = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.kind, "RIGHT", row.holders, "LEFT", -6, 0)
        row.kind:SetWidth(COLUMN_KIND)
        row.kind:SetJustifyH("RIGHT")

        row.label = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
        PixelUtil.SetPoint(row.label, "LEFT", row.icon, "RIGHT", 6, 0)
        PixelUtil.SetPoint(row.label, "RIGHT", row.kind, "LEFT", -6, 0)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)

        -- Bare Frame elements take no mouse input, so without this neither the
        -- context menu nor the tooltip would ever fire.
        row:EnableMouse(true)
        row:SetScript("OnMouseDown", onCurationRowMouseDown)
        row:SetScript("OnEnter", onCurationRowEnter)
        row:SetScript("OnLeave", onCurationRowLeave)
    end

    row._data = data
    row.icon:SetTexture(data.icon or C_Item.GetItemIconByID(data.itemID))
    row.label:SetText(data.name)
    row.kind:SetText(data.subTypeName or data.className or "")
    row.holders:SetText(holderText(data))
    row.destination:SetText(destinationText(data))
end

local function buildCurationWindow()
    local frame = UI.CreateFrame(UIParent, locale["curation:title"])
    frame:SetSize(CURATION_WIDTH, CURATION_HEIGHT)
    frame:SetPoint("CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    _G[CURATION_GLOBAL_NAME] = frame
    tinsert(UISpecialFrames, CURATION_GLOBAL_NAME)

    -- Not redundant with ESC: the search box swallows the first press, and this
    -- window has no Cancel button to double as a way out.
    local closeButton = UI.CreateCloseButton(frame)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() curationWindow.Hide() end)
    frame.closeButton = closeButton

    local search = UI.CreateEditBox(frame)
    search:SetSize(200, CURATION_CONTROL_HEIGHT)
    PixelUtil.SetPoint(search, "TOPLEFT", frame, "TOPLEFT",
        CURATION_PADDING, -(TITLE_BAR_HEIGHT + CURATION_PADDING))
    -- SetScript rather than overriding EditBoxMixin.OnTextChanged: the mixin
    -- binds the function value at OnLoad time, so a later reassignment of the
    -- method would never be seen.
    search:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        filters.search = text ~= "" and text or nil
        curationWindow.Refresh()
    end)
    frame.search = search

    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    searchLabel:SetPoint("BOTTOMLEFT", search, "TOPLEFT", 2, 2)
    searchLabel:SetText(locale["curation:search"])

    local destinationFilter = UI.CreateDropdown(frame, locale["curation:filterDestination"])
    destinationFilter:SetSize(170, CURATION_CONTROL_HEIGHT)
    PixelUtil.SetPoint(destinationFilter, "LEFT", search, "RIGHT", 6, 0)
    destinationFilter:SetupMenu(function(dropdown, rootDescription)
        local options = {
            { value = nil, label = locale["curation:filterDestination"] },
            { value = DESTINATION.WARBAND, label = locale["dest:warband"] },
            { value = DESTINATION.PRIVATE, label = locale["dest:private"] },
            { value = DESTINATION.IGNORE, label = locale["dest:ignore"] },
        }

        for _, option in ipairs(options) do
            local value, label = option.value, option.label
            rootDescription:CreateRadio(label,
                function() return filters.destination == value end,
                function()
                    filters.destination = value
                    dropdown.Label:SetText(label)
                    curationWindow.Refresh()
                end)
        end
    end)
    frame.destinationFilter = destinationFilter

    local classFilter = UI.CreateDropdown(frame, locale["curation:filterClass"])
    classFilter:SetSize(170, CURATION_CONTROL_HEIGHT)
    PixelUtil.SetPoint(classFilter, "LEFT", destinationFilter, "RIGHT", 6, 0)
    frame.classFilter = classFilter

    local sourceLabel = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    sourceLabel:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -6)
    sourceLabel:SetJustifyH("LEFT")
    frame.sourceLabel = sourceLabel

    local countLabel = frame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    countLabel:SetPoint("TOPRIGHT", classFilter, "BOTTOMRIGHT", 0, -6)
    countLabel:SetJustifyH("RIGHT")
    frame.countLabel = countLabel

    -- Unscanned-character banner. A frame rather than a bare FontString so the
    -- scroll box has something with a stable height to anchor to whether or not
    -- there is anything to warn about.
    local bannerFrame = CreateFrame("Frame", nil, frame)
    bannerFrame:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -4)
    bannerFrame:SetPoint("TOPRIGHT", countLabel, "BOTTOMRIGHT", 0, -4)
    PixelUtil.SetHeight(bannerFrame, BANNER_HEIGHT_EMPTY, 1)

    local banner = bannerFrame:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    banner:SetAllPoints(bannerFrame)
    banner:SetJustifyH("LEFT")
    banner:SetJustifyV("TOP")
    banner:SetWordWrap(true)
    banner:SetTextColor(enum.COLOR.OVERRIDE:GetRGB())
    frame.bannerFrame = bannerFrame
    frame.banner = banner

    local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

    scrollBox:SetPoint("TOPLEFT", bannerFrame, "BOTTOMLEFT", 0, -6)
    scrollBox:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",
        -(CURATION_PADDING + 20), CURATION_PADDING)
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(CURATION_ROW_HEIGHT)
    scrollView:SetElementInitializer("Frame", initCurationRow)
    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
    frame.scrollBox = scrollBox

    frame:Hide()
    return frame
end

--- Rebuilds the class filter's options from what the account actually owns.
local function refreshClassFilter()
    local classes = model.bankRules.GetOwnedClasses(ownedCache)
    local dropdown = curationFrame.classFilter

    dropdown:SetupMenu(function(_, rootDescription)
        local anyLabel = locale["curation:filterClass"]
        rootDescription:CreateRadio(anyLabel,
            function() return filters.classID == nil end,
            function()
                filters.classID = nil
                dropdown.Label:SetText(anyLabel)
                curationWindow.Refresh()
            end)

        for _, class in ipairs(classes) do
            local classID, name = class.classID, class.name
            rootDescription:CreateRadio(name,
                function() return filters.classID == classID end,
                function()
                    filters.classID = classID
                    dropdown.Label:SetText(name)
                    curationWindow.Refresh()
                end)
        end
    end)

    -- A class the user had filtered on can vanish when the source changes --
    -- closing the bank, for one. Leaving the filter set would show an empty
    -- window with no visible reason.
    if filters.classID then
        local stillPresent = false
        for _, class in ipairs(classes) do
            if class.classID == filters.classID then stillPresent = true end
        end
        if not stillPresent then
            filters.classID = nil
            dropdown.Label:SetText(locale["curation:filterClass"])
        end
    end
end

--- Re-applies the filters and re-resolves every destination against the current
--- overrides, without re-reading the source. This is what a menu click and a
--- keystroke in the search box both run.
function curationWindow.Refresh()
    if not curationFrame then return end

    local unscanned = model.bankRules.GetUnscannedCharacters()
    if #unscanned > 0 then
        curationFrame.banner:SetText(format(locale["curation:unscanned"],
            tconcat(unscanned, ", ")))
        PixelUtil.SetHeight(curationFrame.bannerFrame, BANNER_HEIGHT, 1)
    else
        curationFrame.banner:SetText("")
        PixelUtil.SetHeight(curationFrame.bannerFrame, BANNER_HEIGHT_EMPTY, 1)
    end

    local rows = model.bankRules.BuildCurationRows(ownedCache, filters)
    curationFrame.countLabel:SetText(format(locale["curation:count"], #rows))

    local provider = CreateDataProvider()
    for _, row in ipairs(rows) do
        provider:Insert(row)
    end
    curationFrame.scrollBox:SetDataProvider(provider)
end

--- Re-reads the active source, then refreshes.
---
--- Separate from Refresh because a source read walks every container the
--- adapter can see, and typing in the search box must not do that per keystroke.
function curationWindow.Reload()
    -- Shown, not merely built: the bank events below fire whether or not this
    -- window is up.
    if not curationFrame or not curationFrame:IsShown() then return end

    ownedCache, activeSourceName = control.adapters.GetOwned()

    -- The built-in source is the only one whose name is not an addon's, so it is
    -- the only one that needs translating; every other name is a proper noun.
    local displayName = activeSourceName == "builtin"
        and locale["curation:sourceBuiltIn"]
        or activeSourceName
    curationFrame.sourceLabel:SetText(format(locale["curation:source"], displayName))

    refreshClassFilter()
    curationWindow.Refresh()
end

function curationWindow.Show()
    if not curationFrame then curationFrame = buildCurationWindow() end
    curationFrame:Show()
    curationWindow.Reload()
end

function curationWindow.Hide()
    if curationFrame then curationFrame:Hide() end
end

function curationWindow.Toggle()
    if curationFrame and curationFrame:IsShown() then
        curationWindow.Hide()
        return
    end
    curationWindow.Show()
end

view.curationWindow = curationWindow

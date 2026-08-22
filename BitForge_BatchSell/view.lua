---@class BitForge.BatchSell
---@field view BitForge.BatchSell.View

---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local format = string.format
local concat = table.concat

local CreateFrame = CreateFrame
local CreateSettingsButtonInitializer = CreateSettingsButtonInitializer
local C_Item = C_Item
local GameTooltip = GameTooltip
local PixelUtil = PixelUtil
local Settings = Settings
local TooltipDataProcessor = TooltipDataProcessor
local tInvert = tInvert

local enum = ns.enum
local model = ns.model
local L = ns.locale
-- Captured once rather than reached through ns on every call. Safe despite
-- control.lua loading after this file: Init.lua owns the table and control.lua
-- only aliases it, so this is the same table the scanner is published on.
local control = ns.control
---@class BitForge.BatchSell.View
local view = ns.view

-- ================================================================================
-- Merchant Panel
-- ================================================================================

view.merchantPanel = {}
do
    local panel = view.merchantPanel
    local frame -- built lazily on first Show so MerchantFrame exists

    -- Which tab is showing. The IDs come back from TabSystemMixin:AddTab in the
    -- order they were added, so they are assigned once at build time.
    local TAB = { MANIFEST = 1, BLACKLIST = 2, WHITELIST = 3 }
    local activeTab = TAB.MANIFEST

    -- The list status each list tab renders. Absent for the manifest tab, which
    -- is what tells Refresh and the row initializer which shape they are on.
    local TAB_STATUS = {
        [TAB.BLACKLIST] = enum.LIST_STATUS.BLACKLIST,
        [TAB.WHITELIST] = enum.LIST_STATUS.WHITELIST,
    }

    local function OnRefreshClick() control.scanner.Scan() end
    local function OnSellClick() control.seller.SellBatch() end

    --- Accepts a bag item dropped anywhere on the panel -- the empty area, or
    --- one of the manifest rows drawn over it, since mouse input does not
    --- bubble from a mouse-enabled child up to its parent. Both ways a player
    --- can complete the gesture route here -- releasing a drag fires
    --- OnReceiveDrag, and clicking with an item already on the cursor fires
    --- OnMouseUp -- mirroring Blizzard's own item-slot convention (see
    --- ContainerFrameItemButtonMixin:OnReceiveDrag / :OnClick).
    ---
    --- OnMouseUp carries the button that was released; OnReceiveDrag carries
    --- none. Guarding on a truthy, non-left button rather than requiring
    --- "LeftButton" outright is what lets one handler serve both scripts --
    --- a right-click over the panel while holding an item is left alone,
    --- matching Blizzard's own RegisterForClicks("LeftButtonUp") convention
    --- for button-type frames.
    ---
    --- Only the manifest tab accepts it. The blacklist and whitelist tabs
    --- ignore the gesture entirely rather than guessing what it should mean
    --- there, leaving it free for a later feature on those tabs. Every
    --- decision beyond that is control.AcceptManifestDrop's -- this is the
    --- thinnest wiring that reaches it.
    local function OnManifestDrop(_, button)
        if button and button ~= "LeftButton" then return end
        if activeTab ~= TAB.MANIFEST then return end
        control.AcceptManifestDrop()
    end

    local function OnRowMouseDown(self)
        local item = self._data
        if not item then return end
        local itemID = item.itemID
        local itemLink = item.itemLink
        local SCOPE, STATUS = enum.LIST_SCOPE, enum.LIST_STATUS
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle(item.name)
            root:CreateButton(L["menu:addToBlacklist"], function()
                model.SetStatus(itemID, SCOPE.GLOBAL, STATUS.BLACKLIST)
                control.scanner.Scan()
            end)
            root:CreateButton(L["menu:addToWhitelist"], function()
                model.SetStatus(itemID, SCOPE.GLOBAL, STATUS.WHITELIST)
                control.scanner.Scan()
            end)
            root:CreateButton(L["menu:addToBlacklistChar"], function()
                model.SetStatus(itemID, SCOPE.CHAR, STATUS.BLACKLIST)
                control.scanner.Scan()
            end)
            root:CreateButton(L["menu:addToWhitelistChar"], function()
                model.SetStatus(itemID, SCOPE.CHAR, STATUS.WHITELIST)
                control.scanner.Scan()
            end)
            -- The inverse of a character override. Without it the only way back
            -- to inheriting the warband status is resetListEntry, which also
            -- destroys the warband entry the player never asked to touch.
            root:CreateButton(L["menu:clearCharOverride"], function()
                model.SetStatus(itemID, SCOPE.CHAR, nil)
                control.scanner.Scan()
            end)
            root:CreateButton(L["menu:resetListEntry"], function()
                model.SetStatus(itemID, SCOPE.GLOBAL, nil)
                model.SetStatus(itemID, SCOPE.CHAR, nil)
                control.scanner.Scan()
            end)
            root:CreateButton(L["menu:temporaryExclude"], function()
                model.AddTempExclude(itemLink)
                control.scanner.Scan()
            end)
        end)
    end

    --- Removes one list entry and re-decides the bags.
    ---
    --- Routed through Scan rather than a local table edit deliberately: an item
    --- leaving the blacklist has to be able to appear in the sell manifest
    --- straight away, and one leaving the whitelist to disappear from it. Scan
    --- calls panel.Refresh itself, which redraws whichever tab is open, so this
    --- is the whole update.
    local function OnRemoveClick(self)
        local entry = self:GetParent()._data
        if not entry then return end
        model.SetStatus(entry.itemID, entry.scope, nil)
        control.scanner.Scan()
    end

    local function OnListRowEnter(self)
        local entry = self._data
        if not entry then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- SetItemByID rather than SetBagItem: a list entry is an itemID with no
        -- bag slot behind it, and the item may not be in the bags at all.
        GameTooltip:SetItemByID(entry.itemID)
        GameTooltip:Show()
    end

    local function OnRowEnter(self)
        local item = self._data
        if not item then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- SetBagItem rather than SetHyperlink: the facts carry the slot, and a
        -- bag reference stays valid where a link may be a secret value.
        GameTooltip:SetBagItem(item.bagIndex, item.slotIndex)
        if item.isCharOverride then
            GameTooltip:AddLine(L["tooltip:charOverride"], 1, 0.5, 0.25, true)
        end
        GameTooltip:Show()
    end

    local function OnRowLeave()
        GameTooltip:Hide()
    end

    local function RowLabel(data)
        local label = data.itemLink
        if data.level and data.level > 0 then
            label = format("%s [%d]", label, data.level)
        end
        -- The label is an item link carrying its own colour codes, so the marker
        -- has to be separately wrapped text; SetTextColor could not tint it.
        if data.isCharOverride then
            local mark = enum.COLOR.CHAR_OVERRIDE:WrapTextInColorCode(enum.CHAR_OVERRIDE_MARK)
            label = format("%s %s", mark, label)
        end
        return label
    end

    --- The label for one list entry: the item link once the client has it, and
    --- the bare itemID until then, prefixed with the scope that holds it.
    ---
    --- An entry the client has never loaded has no name or link, so the load is
    --- requested through the scanner's existing queue -- ITEM_DATA_LOAD_RESULT
    --- already resolves it with a rescan, which refreshes this tab.
    local function ListRowLabel(entry)
        local scopeLabel = entry.scope == enum.LIST_SCOPE.CHAR
            and L["list:character"] or L["list:warband"]
        if entry.scope == enum.LIST_SCOPE.CHAR then
            scopeLabel = enum.COLOR.CHAR_OVERRIDE:WrapTextInColorCode(scopeLabel)
        end

        local itemLink = select(2, C_Item.GetItemInfo(entry.itemID))
        if not itemLink then
            control.scanner.RequestLoad(entry.itemID)
            return format("%s  %d", scopeLabel, entry.itemID)
        end
        return format("%s  %s", scopeLabel, itemLink)
    end

    local function InitRowElement(row, data)
        if not row.icon then
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            PixelUtil.SetPoint(row.icon, "LEFT", row, "LEFT", 4, 0)

            row.value = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
            PixelUtil.SetPoint(row.value, "RIGHT", row, "RIGHT", -4, 0)
            row.value:SetJustifyH("RIGHT")

            row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            PixelUtil.SetPoint(row.remove, "RIGHT", row, "RIGHT", -4, 0)
            row.remove:SetText(L["btn:removeEntry"])
            -- Sized from the label rather than a fixed 64px: some locales
            -- (deDE "Entfernen") sit right at that edge, and UIPanelButtonTemplate
            -- does not truncate.
            row.remove:SetSize(row.remove:GetFontString():GetStringWidth() + 24, 20)
            row.remove:SetScript("OnClick", OnRemoveClick)

            row.label = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
            PixelUtil.SetPoint(row.label, "LEFT", row.icon, "RIGHT", 4, 0)
            row.label:SetJustifyH("LEFT")
            row.label:SetWordWrap(false)

            -- Rows are bare CreateFrame("Frame") elements, and mouse input is
            -- opt-in: without this none of the scripts below ever fire, which
            -- is why the context menu could not be opened.
            row:EnableMouse(true)
            row:SetScript("OnLeave", OnRowLeave)
            -- A row covers the panel wherever the manifest has entries, and
            -- mouse input does not bubble to the panel frame underneath --
            -- so without this, dropping onto an occupied part of the list
            -- would silently do nothing. OnManifestDrop is data-agnostic and
            -- gates on the active tab itself, so wiring it once here, rather
            -- than toggling it alongside OnMouseDown below, is enough for
            -- both the manifest and list tabs.
            row:SetScript("OnReceiveDrag", OnManifestDrop)
            row:SetScript("OnMouseUp", OnManifestDrop)
        end

        row._data = data
        row.icon:SetTexture(C_Item.GetItemIconByID(data.itemID))

        local isList = TAB_STATUS[activeTab] ~= nil
        row.value:SetShown(not isList)
        row.remove:SetShown(isList)
        row.label:ClearAllPoints()
        PixelUtil.SetPoint(row.label, "LEFT", row.icon, "RIGHT", 4, 0)

        if isList then
            PixelUtil.SetPoint(row.label, "RIGHT", row.remove, "LEFT", -4, 0)
            row.label:SetText(ListRowLabel(data))
            row:SetScript("OnMouseDown", nil)
            row:SetScript("OnEnter", OnListRowEnter)
        else
            PixelUtil.SetPoint(row.label, "RIGHT", row.value, "LEFT", -4, 0)
            row.label:SetText(RowLabel(data))
            row.value:SetText(GetCoinTextureString(model.GetTotalSellValue(data)))
            row:SetScript("OnMouseDown", OnRowMouseDown)
            row:SetScript("OnEnter", OnRowEnter)
        end
    end

    local function BuildFrame()
        local f = CreateFrame("Frame", "BitForgeBatchSellPanel", UIParent, "BackdropTemplate")
        f:SetWidth(280)
        f:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
        f:SetHeight(MerchantFrame:GetHeight())
        f:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetFrameStrata("HIGH")
        f:Hide()

        -- Manifest drop target. EnableMouse lets the panel itself answer the
        -- drag/click, without interfering with the tabs, buttons, and rows
        -- built on top of it, each of which handles its own mouse input.
        f:EnableMouse(true)
        f:SetScript("OnMouseUp", OnManifestDrop)
        f:SetScript("OnReceiveDrag", OnManifestDrop)

        -- Title
        local title = f:CreateFontString(nil, "OVERLAY", "BitForgeFontLargeOutlineShadow")
        title:SetPoint("TOP", f, "TOP", 0, -8)
        title:SetText(L["panel:batchSell"])

        -- Tabs. SetTabSelectedCallback must be set before the first SetTab:
        -- TabSystemMixin:SetTab calls the callback unconditionally, and only
        -- applies the visual selection itself when the callback returns falsy.
        local tabSystem = CreateFrame("Frame", nil, f, "TabSystemTemplate")
        tabSystem:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -26)
        -- tabTemplate defaults to the bottom-tapering art and is only read once,
        -- by TabSystemMixin:OnLoad at CreateFrame time above -- so the pool it
        -- already built has to be replaced before the first AddTab, not just
        -- reconfigured, to get the upward-tapering art this top-anchored strip needs.
        tabSystem.tabPool = CreateFramePool("BUTTON", tabSystem, "TabSystemTopButtonTemplate")
        -- Unconstrained, each tab sizes to its own text; ruRU and deDE labels
        -- run wide enough across three tabs to overrun the panel's 280px width.
        tabSystem.maxTabWidth = 84
        tabSystem:SetTabSelectedCallback(function(tabID)
            activeTab = tabID
            panel.Refresh()
        end)
        tabSystem:AddTab(L["panel:sellManifest"])
        tabSystem:AddTab(L["panel:blacklist"])
        tabSystem:AddTab(L["panel:whitelist"])
        f.tabSystem = tabSystem

        -- Status bar
        local status = f:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
        status:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -60)
        status:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -60)
        status:SetJustifyH("LEFT")
        status:SetText(L["status:noItemsToSell"])
        f.status = status

        -- Button row
        local btnRow = CreateFrame("Frame", nil, f)
        PixelUtil.SetHeight(btnRow, 28, 1)
        btnRow:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
        btnRow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

        local refreshBtn = CreateFrame("Button", nil, btnRow, "UIPanelButtonTemplate")
        refreshBtn:SetSize(80, 24)
        refreshBtn:SetPoint("LEFT", btnRow, "LEFT", 0, 0)
        refreshBtn:SetText(L["btn:refresh"])
        refreshBtn:SetScript("OnClick", OnRefreshClick)

        local sellBtn = CreateFrame("Button", nil, btnRow, "UIPanelButtonTemplate")
        sellBtn:SetSize(100, 24)
        sellBtn:SetPoint("RIGHT", btnRow, "RIGHT", 0, 0)
        sellBtn:SetText(L["btn:sellAll"])
        sellBtn:SetScript("OnClick", OnSellClick)
        f.sellBtn = sellBtn

        -- ScrollBox
        local scrollBox = CreateFrame("Frame", nil, f, "WowScrollBoxList")
        local scrollBar = CreateFrame("EventFrame", nil, f, "MinimalScrollBar")

        scrollBox:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -4)
        scrollBox:SetPoint("BOTTOMRIGHT", btnRow, "TOPRIGHT", -20, 4)

        scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
        scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

        local scrollView = CreateScrollBoxListLinearView()
        scrollView:SetElementExtent(24)

        scrollView:SetElementInitializer("Frame", InitRowElement)

        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        f.scrollBox = scrollBox
        f.dataProvider = CreateDataProvider()
        scrollBox:SetDataProvider(f.dataProvider)

        return f
    end

    function panel.Show()
        if not frame then frame = BuildFrame() end
        frame:SetHeight(MerchantFrame:GetHeight())
        -- Show first: Refresh bails on a hidden frame, so refreshing before this
        -- left the panel displaying the previous visit's manifest.
        frame:Show()
        -- Every visit opens on the manifest. A merchant visit is about selling,
        -- and leaving it on whichever list tab was last open would hide the
        -- thing the panel exists for.
        frame.tabSystem:SetTab(TAB.MANIFEST)
        -- SetTab always invokes the callback set in BuildFrame, which itself
        -- calls Refresh -- so this second call is redundant on every open, not
        -- a fallback for the case where the tab was already selected. Kept
        -- deliberately as belt-and-braces: the cost is one rebuild of a few
        -- dozen rows, against a blank panel at a vendor if that were wrong.
        panel.Refresh()
    end

    function panel.Hide()
        if frame then frame:Hide() end
    end

    function panel.Refresh()
        if not frame or not frame:IsShown() then return end

        local listStatus = TAB_STATUS[activeTab]
        frame.dataProvider:Flush()

        if listStatus then
            local entries = model.GetListEntries(listStatus)
            frame.status:SetText(#entries == 0 and L["status:listEmpty"]
                or format(L["status:listCount"], #entries))
            for _, entry in ipairs(entries) do
                frame.dataProvider:Insert(entry)
            end
            -- Nothing on a list tab is sellable, so the button would lie.
            frame.sellBtn:SetEnabled(false)
            return
        end

        local manifest = model.GetManifest()
        local count = model.GetManifestCount()
        local total = model.GetManifestTotalValue()

        if count == 0 then
            frame.status:SetText(L["status:noItemsToSell"])
        else
            frame.status:SetText(format(L["status:itemsTotal"], count, GetCoinTextureString(total)))
        end

        for _, item in ipairs(manifest) do
            frame.dataProvider:Insert(item)
        end
        frame.sellBtn:SetEnabled(true)
    end
end

-- =============================================================================
-- Settings Panel
-- =============================================================================

view.settingsPanel = {}
do
    local panel = view.settingsPanel

    StaticPopupDialogs["BATCHSELL_CONFIRM_RESET_LIST"] = {
        text = L["listReset:confirm"],
        button1 = ACCEPT,
        button2 = CANCEL,
        OnAccept = function(self, data) data.callback() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    -- Label per sell mode. Both dropdowns draw from this, so the two-entry
    -- Other dropdown reuses the four-entry Materials one's labels rather than
    -- needing its own.
    local MODE_LABELS = {
        [enum.SELL_MODE.KEEP_ALL]     = "mode:keepAll",
        [enum.SELL_MODE.KEEP_CURRENT] = "mode:keepCurrent",
        [enum.SELL_MODE.KEEP_FROM]    = "mode:keepFrom",
        [enum.SELL_MODE.SELL_ALL]     = "mode:sellAll",
    }

    --- Builds an options function offering exactly the modes passed, in order.
    --- Materials offers all four; Other only the two that mean anything for a
    --- consumable, since selling the current tier's flasks is never wanted and
    --- pinning an expansion is meaningless for items whose usefulness ends with
    --- the tier they were made for.
    local function ModeOptions(modes)
        return function()
            local container = Settings.CreateControlTextContainer()
            for _, mode in ipairs(modes) do
                container:Add(mode, L[MODE_LABELS[mode]])
            end
            return container:GetData()
        end
    end

    -- LE_EXPANSION_* values, which is what C_Item.GetItemInfo's expansionID
    -- returns: Classic 0 through Midnight 11. The list used to be 1-based
    -- because 0 was needed as an "All Expansions" sentinel, which made every
    -- current-expansion item read as past-expansion. The sell mode replaced the
    -- sentinel, so the values can be the real ones.
    local EXPANSION_IDS = {
        { L["expansion:classic"],            0 },
        { L["expansion:burningCrusade"],     1 },
        { L["expansion:wrathOfTheLichKing"], 2 },
        { L["expansion:cataclysm"],          3 },
        { L["expansion:mistsOfPandaria"],    4 },
        { L["expansion:warlordsOfDraenor"],  5 },
        { L["expansion:legion"],             6 },
        { L["expansion:battleForAzeroth"],   7 },
        { L["expansion:shadowlands"],        8 },
        { L["expansion:dragonflight"],       9 },
        { L["expansion:theWarWithin"],       10 },
        { L["expansion:midnight"],           11 },
    }

    local function ExpansionOptions()
        local container = Settings.CreateControlTextContainer()
        for _, pair in ipairs(EXPANSION_IDS) do
            container:Add(pair[2], pair[1])
        end
        return container:GetData()
    end

    function panel.Init()
        local cat = BitForge.Settings.NewSubcategory(ADDON_NAME, L["panel:batchSell"], L)
        local MODE = enum.SELL_MODE

        cat:AddExpandableSection(L["section:general"], true)
        cat:AddCheckbox("sellJunk", model.GetSellJunk, model.SetSellJunk)
        cat:AddCheckbox("limitBatch", model.GetLimitBatchTo12, model.SetLimitBatchTo12)

        cat:AddExpandableSection(L["section:equipment"], true)
        cat:AddCheckbox("sellEquipment", model.GetSellEquipment, model.SetSellEquipment)
        -- Directly under the toggle it qualifies, with the three direction
        -- toggles under it: the margin only means anything through them.
        cat:AddSlider("ilvlThreshold", model.GetIlvlThreshold, model.SetIlvlThreshold, -50, 0, 1)
        cat:AddCheckbox("marginOnHigherQuality",
            model.GetMarginOnHigherQuality, model.SetMarginOnHigherQuality)
        cat:AddCheckbox("marginOnSameQuality",
            model.GetMarginOnSameQuality, model.SetMarginOnSameQuality)
        cat:AddCheckbox("marginOnLowerQuality",
            model.GetMarginOnLowerQuality, model.SetMarginOnLowerQuality)
        cat:AddCheckbox("keepBindOnAccount", model.GetKeepBindOnAccount, model.SetKeepBindOnAccount)
        cat:AddCheckbox("keepBindOnAccountPastExpac", model.GetKeepBindOnAccountPastExpac,
            model.SetKeepBindOnAccountPastExpac)
        cat:AddCheckbox("keepDisenchantables", model.GetKeepDisenchantables, model.SetKeepDisenchantables)
        cat:AddCheckbox("keepUsedReagents", model.GetKeepUsedReagents, model.SetKeepUsedReagents)
        cat:AddCheckbox("keepDisenchantablesPastExpac", model.GetKeepDisenchantablesPastExpac,
            model.SetKeepDisenchantablesPastExpac)

        cat:AddExpandableSection(L["section:materials"], false)
        cat:AddDropdown("materialsMode", model.GetMaterialsMode, model.SetMaterialsMode,
            ModeOptions({ MODE.KEEP_ALL, MODE.KEEP_CURRENT, MODE.KEEP_FROM, MODE.SELL_ALL }),
            Settings.VarType.String)
        cat:AddDropdown("materialsExpansion", model.GetMaterialsExpansion,
            model.SetMaterialsExpansion, ExpansionOptions)

        cat:AddExpandableSection(L["section:other"], false)
        cat:AddDropdown("otherMode", model.GetOtherMode, model.SetOtherMode,
            ModeOptions({ MODE.KEEP_ALL, MODE.KEEP_CURRENT }),
            Settings.VarType.String)

        cat:AddExpandableSection(L["section:lists"], false)

        local function AddResetInitializer(labelKey, scope, status)
            local function OnClick()
                StaticPopup_Show("BATCHSELL_CONFIRM_RESET_LIST", nil, nil, {
                    callback = function() model.ClearList(scope, status) end,
                })
            end
            return CreateSettingsButtonInitializer("", L[labelKey], OnClick, nil, false)
        end

        local SCOPE, STATUS = enum.LIST_SCOPE, enum.LIST_STATUS
        cat:AddInitializer(AddResetInitializer("listReset:warbandBlacklist", SCOPE.GLOBAL, STATUS.BLACKLIST))
        cat:AddInitializer(AddResetInitializer("listReset:warbandWhitelist", SCOPE.GLOBAL, STATUS.WHITELIST))
        cat:AddInitializer(AddResetInitializer("listReset:charBlacklist", SCOPE.CHAR, STATUS.BLACKLIST))
        cat:AddInitializer(AddResetInitializer("listReset:charWhitelist", SCOPE.CHAR, STATUS.WHITELIST))
    end
end

-- ================================================================================
-- Item Tooltip
-- ================================================================================
--
-- Every bag item tooltip gains the verdict BatchSell would give it and the rule
-- that produced it, in the player's language, but only while the merchant is
-- open -- away from a vendor the verdict is not actionable, and gating it lets
-- every rule stay reachable rather than only the three that ever fire from a
-- manifest (WHITELISTED, OUTCLASSED, SELL_MODE). With the module's debug flag
-- set the tooltip additionally gains the raw facts the cascade weighed to get
-- there, regardless of merchant state.
--
-- Attached as a tooltip post-call rather than by hooking the bag buttons, so it
-- covers every frame that displays a bag item -- the merchant panel rows
-- included, since those build through SetBagItem.
--
-- scanner.Explain runs a full gather, so the two blocks share one call when
-- either wants it. When the merchant is closed and the debug flag is unset,
-- neither does, and Explain is skipped entirely rather than gathering for
-- nothing on every bag item a player hovers away from a vendor.

---@class BitForge.BatchSell.View.ItemTooltip
local itemTooltip = {}
do
    -- bindType arrives as a number and reads as noise; enum.BIND_TYPE names the
    -- three values the cascade tests, and anything else falls back to the number.
    local BIND_TYPE_NAMES = tInvert(enum.BIND_TYPE)

    local function AddDebugLine(tooltip, text)
        tooltip:AddLine(text, enum.COLOR.DEBUG:GetRGB())
    end

    --- The bag slot a tooltip is describing, or nil when it is describing
    --- something else. Merchant panel rows park the facts they were built from
    --- on _data; real item buttons answer ItemButtonMixin:GetBagID, with the
    --- slot as the frame's own ID.
    local function OwnerBagSlot(owner)
        if not owner then return nil end
        local data = owner._data
        if data then return data.bagIndex, data.slotIndex end
        if owner.GetBagID then return owner:GetBagID(), owner:GetID() end
        return nil
    end

    --- The bags scanner.Scan walks. Bank and void storage buttons answer
    --- GetBagID as well, and a verdict on a slot BatchSell never considers would
    --- be a lie -- so those tooltips are left untouched rather than annotated.
    local function IsScannedBag(bagIndex)
        return bagIndex ~= nil
            and bagIndex >= BACKPACK_CONTAINER
            and bagIndex <= NUM_TOTAL_EQUIPPED_BAG_SLOTS
    end

    --- The items equipped in the slots this item could occupy, or nil when it is
    --- not equippable. Both entries of a dual slot are shown rather than reduced,
    --- because model.CompareToEquipped is existential over them: a ring only has
    --- to satisfy the test against one.
    ---
    --- An unreadable entry (see control.lua's equippedItems) carries no level or
    --- quality to format, so it is reported by name instead -- the debug line is
    --- how a developer would otherwise notice model.CompareToEquipped decided
    --- KEEP without any level comparison at all.
    local function EquippedSummary(facts)
        local items = facts.equippedItems
        if not items or #items == 0 then return nil end
        local parts = {}
        for _, equipped in ipairs(items) do
            parts[#parts + 1] = equipped.unreadable
                and "unreadable"
                or format("%d(q%d)", equipped.level, equipped.quality)
        end
        return concat(parts, "/")
    end

    local function StatusName(itemID, scope)
        return model.GetStatus(itemID, scope) or "none"
    end

    --- Deliberately unlocalized: this is developer output, and a locale key per
    --- line would put eleven translations behind a flag no player sets.
    local function AddDebugReport(tooltip, report)
        local facts, settings = report.facts, report.settings

        tooltip:AddLine(" ")
        AddDebugLine(tooltip, format("[debug] verdict %s  rule %s", report.verdict, report.rule))

        local equipped = EquippedSummary(facts)
        AddDebugLine(tooltip, format("[debug] item %d  bag %d slot %d  ilvl %d%s",
            facts.itemID, facts.bagIndex, facts.slotIndex, facts.level,
            equipped and format("  equipped %s", equipped) or ""))

        AddDebugLine(tooltip, format("[debug] quality %d  bind %s  expac %d  price %d x%d = %d",
            facts.quality, BIND_TYPE_NAMES[facts.bindType] or facts.bindType, facts.expacID,
            facts.sellPrice, facts.stackCount, model.GetTotalSellValue(facts)))

        AddDebugLine(tooltip, format("[debug] list: char=%s warband=%s%s",
            StatusName(facts.itemID, enum.LIST_SCOPE.CHAR),
            StatusName(facts.itemID, enum.LIST_SCOPE.GLOBAL),
            facts.isCharOverride and "  (override)" or ""))

        -- A CATEGORY or CURRENT_EXPANSION verdict cannot be reconciled against
        -- the raw facts above without knowing which bucket the item landed in,
        -- and the reagent flag is the one input to that decision no other line
        -- reports.
        AddDebugLine(tooltip, format("[debug] category %s  reagent %s",
            model.GetCategory(facts) or "none", tostring(facts.isCraftingReagent)))

        -- The derived facts the rule cascade branches on. Neither is stored on
        -- the facts table, so without them the rule that fired cannot be
        -- reconciled against the raw values on the lines above.
        AddDebugLine(tooltip, format(
            "[debug] equippable %s  disenchantable %s  locked %s  refundable %s  set %s  excluded %s",
            tostring(model.IsEquippableBy(facts, settings.playerClass)),
            tostring(model.IsDisenchantable(facts, settings.isEnchanter)),
            tostring(facts.isLocked), tostring(facts.isRefundable),
            tostring(facts.inEquipmentSet), tostring(facts.isTempExcluded)))
    end

    --- The two lines a player reads: what will happen, and which rule decided.
    --- Localized, and shown only while the merchant is open -- OnItemTooltip
    --- does not even call this away from a vendor, since the verdict is not
    --- actionable there.
    ---
    --- The reason mapping is total over enum.RULE by construction, and a test
    --- iterates the enum to keep it that way -- a missing string would render as
    --- a blank line in front of a player rather than failing anywhere.
    local function AddVerdict(tooltip, report)
        local isSell = report.verdict == enum.DECISION.SELL
        local color = isSell and enum.COLOR.SELL or enum.COLOR.KEEP
        local heading = isSell and L["verdict:sell"] or L["verdict:keep"]

        tooltip:AddLine(" ")
        tooltip:AddLine(heading, color:GetRGB())
        tooltip:AddLine(L["reason:" .. report.rule], color:GetRGB())
    end

    local function OnItemTooltip(tooltip)
        if tooltip ~= GameTooltip then return end

        local isMerchantOpen = control.IsMerchantOpen()
        local isDebug = model.IsDebug()
        if not isMerchantOpen and not isDebug then return end

        local bagIndex, slotIndex = OwnerBagSlot(tooltip:GetOwner())
        if not IsScannedBag(bagIndex) then return end

        local report = control.scanner.Explain(bagIndex, slotIndex)
        if not report then return end

        if isMerchantOpen then
            AddVerdict(tooltip, report)
        end
        if isDebug then
            AddDebugReport(tooltip, report)
        end
    end

    --- Registered once at startup. Both blocks read their own gate live --
    --- the verdict from control.IsMerchantOpen(), the debug block from
    --- model.IsDebug() -- so neither needs a reload to react to a change.
    function itemTooltip.Init()
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
    end
end
view.itemTooltip = itemTooltip

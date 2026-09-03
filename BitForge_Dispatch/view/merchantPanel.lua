---@type string, BitForge.Dispatch
local ADDON_NAME, ns = ...

local ipairs = ipairs
local format = string.format

local CreateFrame = CreateFrame
local C_Item = C_Item
local C_CurrencyInfo = C_CurrencyInfo
local GameTooltip = GameTooltip
local PixelUtil = PixelUtil

local UI = BitForge.UI
local colors = UI.Colors

local enum = ns.enum
local model = ns.model
local locale = ns.locale
-- Captured once rather than reached through ns on every call. Safe despite
-- control.lua loading after this file: Init.lua owns the table and control.lua
-- only aliases it, so this is the same table the sellScanner is published on.
local control = ns.control
---@class BitForge.Dispatch.View
local view = ns.view

do
    ---@class BitForge.Dispatch.View.MerchantPanel
    local panel = {}
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

    -- The None radio's data. nil is what the model stores for "no entry", but it is
    -- also what a radio carrying no data reports, so the two would be
    -- indistinguishable at the point a click is dispatched.
    local NO_STATUS = "none"

    local function OnRefreshClick() control.sellScanner.Scan() end
    local function OnSellClick() control.seller.SellBatch() end
    local function OnRulesClick() view.ruleWindow.Toggle() end

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
    ---@param _ Frame
    ---@param button string?  the released button, from OnMouseUp only
    local function OnManifestDrop(_, button)
        if button and button ~= "LeftButton" then return end
        if activeTab ~= TAB.MANIFEST then return end
        control.AcceptManifestDrop()
    end

    --- Builds the context menu for one manifest row.
    ---
    --- The two lists are independent and the character scope wins outright
    --- (model.facts.EffectiveSell), so an item has nine states. One radio group
    --- per scope shows both at once; a single group of five could only ever show
    --- one of them, and a warband entry sitting under a character one -- the case
    --- a player opens this menu to understand -- would be invisible.
    ---
    --- The root is an argument rather than something this reaches for, so the menu
    --- can be built and read back without a frame.
    ---@param root any    the root menu description
    ---@param item table  the row's facts table
    function panel.BuildItemMenu(root, item)
        local itemID = item.itemID
        local itemLink = item.itemLink
        local SCOPE, STATUS = enum.LIST_SCOPE, enum.LIST_STATUS

        root:CreateTitle(item.name)

        local function scopeSection(title, scope)
            root:CreateTitle(title)

            local function isSelected(status)
                return (model.overrides.GetSell(itemID, scope) or NO_STATUS) == status
            end

            local function setSelected(status)
                model.overrides.SetSell(itemID, scope, status ~= NO_STATUS and status or nil)
                control.sellScanner.Scan()
            end

            -- CreateRadio sets no response where CreateCheckbox sets Refresh
            -- (Blizzard_Menu/MenuTemplates.lua:345 against :341), and a nil response
            -- closes the whole menu -- so without this a player setting both scopes
            -- never sees the first mark land.
            root:CreateRadio(locale["menu:blacklisted"], isSelected, setSelected, STATUS.BLACKLIST)
                :SetResponse(MenuResponse.Refresh)
            root:CreateRadio(locale["menu:whitelisted"], isSelected, setSelected, STATUS.WHITELIST)
                :SetResponse(MenuResponse.Refresh)
            root:CreateRadio(locale["menu:noStatus"], isSelected, setSelected, NO_STATUS)
                :SetResponse(MenuResponse.Refresh)
        end

        scopeSection(locale["list:character"], SCOPE.CHAR)
        root:CreateDivider()
        scopeSection(locale["list:warband"], SCOPE.GLOBAL)
        root:CreateDivider()

        -- Keeps the default response and closes: it acts once and being done is the
        -- right outcome.
        root:CreateButton(locale["menu:temporaryExclude"], function()
            model.AddTempExclude(itemLink)
            control.sellScanner.Scan()
        end)

        root:CreateDivider()

        -- Its own section because it is a different kind of act: everything above
        -- changes how the item is treated, this one says the treatment is wrong.
        -- Keeps the default response and closes, like the entry above it.
        root:CreateButton(locale["menu:reportVerdict"], function()
            local text = control.SellReportText(item.bagIndex, item.slotIndex)
            if not text then return end
            BitForge:ShowReport(text, locale["report:blurbSell"])
        end)
    end

    local function OnRowMouseDown(self)
        local item = self._data
        if not item then return end
        MenuUtil.CreateContextMenu(self, function(_, root)
            panel.BuildItemMenu(root, item)
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
        model.overrides.SetSell(entry.itemID, entry.scope, nil)
        control.sellScanner.Scan()
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
            GameTooltip:AddLine(locale["tooltip:charOverride"], 1, 0.5, 0.25, true)
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
            and locale["list:character"] or locale["list:warband"]
        if entry.scope == enum.LIST_SCOPE.CHAR then
            scopeLabel = enum.COLOR.CHAR_OVERRIDE:WrapTextInColorCode(scopeLabel)
        end

        local itemLink = select(2, C_Item.GetItemInfo(entry.itemID))
        if not itemLink then
            control.sellScanner.RequestLoad(entry.itemID)
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
            row.remove:SetText(locale["btn:removeEntry"])
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
            -- opt-in: without this none of the scripts below ever fire.
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
            row.value:SetText(C_CurrencyInfo.GetCoinTextureString(model.GetTotalSellValue(data)))
            row:SetScript("OnMouseDown", OnRowMouseDown)
            row:SetScript("OnEnter", OnRowEnter)
        end
    end

    -- Paint the panel in the host UI's theme. Every primitive is idempotent, so
    -- calling this again on an already-skinned window costs a table lookup.
    --
    -- tabSystem.tabs is TabSystemMixin's own array of tab buttons. There is no
    -- accessor for it, and the host's API expects to be handed each tab, so it
    -- is read directly -- guarded, since a Blizzard internal is not a contract.
    local function ApplyHostSkin(hostSkin, f)
        if not hostSkin or not f then return end
        hostSkin.Shell(f)
        hostSkin.Button(f.refreshBtn)
        hostSkin.Button(f.rulesBtn)
        hostSkin.Button(f.sellBtn)
        hostSkin.ScrollBar(f.scrollBar)
        local tabs = f.tabSystem and f.tabSystem.tabs
        if tabs then
            for _, tab in ipairs(tabs) do
                hostSkin.Tab(tab)
            end
        end
    end

    -- Registered at file-read time, not from BuildFrame: the window may never be
    -- built during a session that never visits a vendor, and the handler has to
    -- be on the list before the host dispatches either way. `frame` is nil until
    -- the first visit, which ApplyHostSkin answers by doing nothing -- BuildFrame
    -- picks the facade up itself in that case.
    BitForge.UI.Skin.OnExternalSkin(function(hostSkin)
        ApplyHostSkin(hostSkin, frame)
    end)

    local function BuildFrame()
        local f = CreateFrame("Frame", ADDON_NAME .. "Panel", UIParent, "BackdropTemplate")
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

        local title = f:CreateFontString(nil, "OVERLAY", "BitForgeFontLargeOutlineShadow")
        title:SetPoint("TOP", f, "TOP", 0, -8)
        title:SetText(locale["panel:batchSell"])

        -- Tabs. SetTabSelectedCallback must be set before the first SetTab:
        -- TabSystemMixin:SetTab calls the callback unconditionally, and only
        -- applies the visual selection itself when the callback returns falsy.
        --
        -- Anchored to the frame's bottom edge so the strip hangs below the
        -- panel, matching where the merchant window carries its own tabs. That
        -- is TabSystemTemplate's default tabTemplate, the downward-tapering
        -- art, so nothing needs replacing here -- an upward-tapering strip
        -- would have to swap the pool outright, since TabSystemMixin:OnLoad
        -- reads tabTemplate once at CreateFrame time.
        local tabSystem = CreateFrame("Frame", nil, f, "TabSystemTemplate")
        tabSystem:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 10, 2)
        -- Unconstrained, each tab sizes to its own text; ruRU and deDE labels
        -- run wide enough across three tabs to overrun the merchant window's
        -- width. Three at this cap plus spacing still clear it.
        tabSystem.maxTabWidth = 100
        tabSystem:SetTabSelectedCallback(function(tabID)
            activeTab = tabID
            panel.Refresh()
        end)
        tabSystem:AddTab(locale["panel:sellManifest"])
        tabSystem:AddTab(locale["panel:blacklist"])
        tabSystem:AddTab(locale["panel:whitelist"])
        f.tabSystem = tabSystem

        local status = f:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
        status:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -30)
        status:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -30)
        status:SetJustifyH("LEFT")
        status:SetText(locale["status:noItemsToSell"])
        f.status = status

        local btnRow = CreateFrame("Frame", nil, f)
        PixelUtil.SetHeight(btnRow, 28, 1)
        btnRow:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
        btnRow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

        local refreshBtn = CreateFrame("Button", nil, btnRow, "UIPanelButtonTemplate")
        refreshBtn:SetSize(80, 24)
        refreshBtn:SetPoint("LEFT", btnRow, "LEFT", 0, 0)
        refreshBtn:SetText(locale["btn:refresh"])
        refreshBtn:SetScript("OnClick", OnRefreshClick)
        f.refreshBtn = refreshBtn

        -- Between the two, in the space left once Refresh (80px) and Sell All
        -- (100px) take their own ends of the ~320px row.
        local rulesBtn = CreateFrame("Button", nil, btnRow, "UIPanelButtonTemplate")
        rulesBtn:SetSize(90, 24)
        rulesBtn:SetPoint("CENTER", btnRow, "CENTER", 0, 0)
        rulesBtn:SetText(locale["btn:rules"])
        rulesBtn:SetScript("OnClick", OnRulesClick)
        f.rulesBtn = rulesBtn

        local sellBtn = CreateFrame("Button", nil, btnRow, "UIPanelButtonTemplate")
        sellBtn:SetSize(100, 24)
        sellBtn:SetPoint("RIGHT", btnRow, "RIGHT", 0, 0)
        sellBtn:SetText(locale["btn:sellAll"])
        sellBtn:SetScript("OnClick", OnSellClick)
        f.sellBtn = sellBtn

        -- A wrongly-*kept* item leaves no manifest row, so there is nothing
        -- here to click on for an explanation -- only a tooltip in the bags
        -- can answer that. Above btnRow rather than below status, so it never
        -- competes with the item count/total status already carries.
        local hint = f:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
        hint:SetPoint("BOTTOMLEFT", btnRow, "TOPLEFT", 0, 4)
        hint:SetPoint("BOTTOMRIGHT", btnRow, "TOPRIGHT", 0, 4)
        hint:SetJustifyH("LEFT")
        hint:SetWordWrap(true)
        hint:SetTextColor(colors.text:GetRGB())
        hint:SetText(locale["ui:manifestHint"])
        f.hint = hint

        local scrollBox = CreateFrame("Frame", nil, f, "WowScrollBoxList")
        local scrollBar = CreateFrame("EventFrame", nil, f, "MinimalScrollBar")

        scrollBox:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -4)
        scrollBox:SetPoint("BOTTOMRIGHT", hint, "TOPRIGHT", -20, 4)

        scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
        scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)
        f.scrollBar = scrollBar

        local scrollView = CreateScrollBoxListLinearView()
        scrollView:SetElementExtent(24)

        scrollView:SetElementInitializer("Frame", InitRowElement)

        ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)
        f.scrollBox = scrollBox
        f.dataProvider = CreateDataProvider()
        scrollBox:SetDataProvider(f.dataProvider)

        -- Anchored and sized before the skin pass, not merely before the
        -- return: ApplyHostSkin paints f itself, and UI.CreateSeparatorTexture
        -- (BitForge/APIs/UI/Core.lua) is proof a host facade can read a
        -- frame's real geometry synchronously while painting it. Everything
        -- above this point builds content that needs nothing from
        -- MerchantFrame, but the skin pass is not content -- it has to see
        -- the panel at its real size, not CreateFrame's default 0x0.
        f:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
        -- Both dimensions are taken from the merchant window rather than fixed,
        -- so the panel reads as the second half of it. Re-applied on every open
        -- in panel.Show, since a UI scale change between visits moves both.
        f:SetSize(MerchantFrame:GetWidth(), MerchantFrame:GetHeight())

        -- The window is built on the first merchant visit, which is almost
        -- always after the host handed its facade over -- and the handler
        -- registered above has therefore already run, against a nil frame. This
        -- reads the facade directly rather than waiting for a second dispatch
        -- that is never coming.
        ApplyHostSkin(BitForge.UI.Skin.GetExternalSkin(), f)

        return f
    end

    function panel.Show()
        if not frame then frame = BuildFrame() end
        frame:SetSize(MerchantFrame:GetWidth(), MerchantFrame:GetHeight())
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

    --- Whether the manifest is on screen. Read by view.ruleControls, which
    --- rescans on a rule change only when there is something to rescan for.
    ---@return boolean
    function panel.IsOpen()
        return frame ~= nil and frame:IsShown()
    end

    function panel.Refresh()
        if not frame or not frame:IsShown() then return end

        local listStatus = TAB_STATUS[activeTab]
        frame.dataProvider:Flush()

        if listStatus then
            local entries = model.overrides.GetSellEntries(listStatus)
            frame.status:SetText(#entries == 0 and locale["status:listEmpty"]
                or format(locale["status:listCount"], #entries))
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
            frame.status:SetText(locale["status:noItemsToSell"])
        else
            frame.status:SetText(format(locale["status:itemsTotal"], count,
                C_CurrencyInfo.GetCoinTextureString(total)))
        end

        for _, item in ipairs(manifest) do
            frame.dataProvider:Insert(item)
        end
        -- The manifest still lists what would sell -- that stays true and
        -- informative with the switch off. The button does not: a click
        -- selling nothing would swallow silently in seller.SellBatch's
        -- IsSellEnabled guard, so it is disabled instead of lying.
        frame.sellBtn:SetEnabled(model.IsSellEnabled())
    end

    view.merchantPanel = panel
end

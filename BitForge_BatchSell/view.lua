---@class BitForge.BatchSell
---@field view BitForge.BatchSell.View

---@type string, BitForge.BatchSell
local ADDON_NAME, ns = ...

local ipairs = ipairs
local format = string.format

local CreateFrame = CreateFrame
local CreateSettingsButtonInitializer = CreateSettingsButtonInitializer
local C_Item = C_Item
local GameTooltip = GameTooltip
local PixelUtil = PixelUtil
local Settings = Settings

local enum = ns.enum
local model = ns.model
local L = ns.locale
---@class BitForge.BatchSell.View
local view = ns.view

-- ================================================================================
-- Merchant Panel
-- ================================================================================

view.merchantPanel = {}
do
    local panel = view.merchantPanel
    local frame -- built lazily on first Show so MerchantFrame exists

    local function OnRefreshClick() ns.control.scanner.Scan() end
    local function OnSellClick() ns.control.seller.SellBatch() end

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
                ns.control.scanner.Scan()
            end)
            root:CreateButton(L["menu:addToWhitelist"], function()
                model.SetStatus(itemID, SCOPE.GLOBAL, STATUS.WHITELIST)
                ns.control.scanner.Scan()
            end)
            root:CreateButton(L["menu:addToBlacklistChar"], function()
                model.SetStatus(itemID, SCOPE.CHAR, STATUS.BLACKLIST)
                ns.control.scanner.Scan()
            end)
            root:CreateButton(L["menu:addToWhitelistChar"], function()
                model.SetStatus(itemID, SCOPE.CHAR, STATUS.WHITELIST)
                ns.control.scanner.Scan()
            end)
            -- The inverse of a character override. Without it the only way back
            -- to inheriting the warband status is resetListEntry, which also
            -- destroys the warband entry the player never asked to touch.
            root:CreateButton(L["menu:clearCharOverride"], function()
                model.SetStatus(itemID, SCOPE.CHAR, nil)
                ns.control.scanner.Scan()
            end)
            root:CreateButton(L["menu:resetListEntry"], function()
                model.SetStatus(itemID, SCOPE.GLOBAL, nil)
                model.SetStatus(itemID, SCOPE.CHAR, nil)
                ns.control.scanner.Scan()
            end)
            root:CreateButton(L["menu:temporaryExclude"], function()
                model.AddTempExclude(itemLink)
                ns.control.scanner.Scan()
            end)
        end)
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

    local function InitRowElement(row, data)
        if not row.icon then
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            PixelUtil.SetPoint(row.icon, "LEFT", row, "LEFT", 4, 0)

            row.value = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
            PixelUtil.SetPoint(row.value, "RIGHT", row, "RIGHT", -4, 0)
            row.value:SetJustifyH("RIGHT")

            row.label = row:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
            PixelUtil.SetPoint(row.label, "LEFT", row.icon, "RIGHT", 4, 0)
            PixelUtil.SetPoint(row.label, "RIGHT", row.value, "LEFT", -4, 0)
            row.label:SetJustifyH("LEFT")
            row.label:SetWordWrap(false)

            -- Rows are bare CreateFrame("Frame") elements, and mouse input is
            -- opt-in: without this none of the scripts below ever fire, which
            -- is why the context menu could not be opened.
            row:EnableMouse(true)

            row:SetScript("OnMouseDown", OnRowMouseDown)
            row:SetScript("OnEnter", OnRowEnter)
            row:SetScript("OnLeave", OnRowLeave)
        end

        row._data = data
        row.icon:SetTexture(C_Item.GetItemIconByID(data.itemID))
        row.label:SetText(RowLabel(data))
        row.value:SetText(GetCoinTextureString(model.GetTotalSellValue(data)))
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

        -- Title
        local title = f:CreateFontString(nil, "OVERLAY", "BitForgeFontLargeOutlineShadow")
        title:SetPoint("TOP", f, "TOP", 0, -8)
        title:SetText(L["panel:batchSell"])

        -- Status bar
        local status = f:CreateFontString(nil, "OVERLAY", "BitForgeFontSmallOutline")
        status:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -30)
        status:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -30)
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
        panel.Refresh()
    end

    function panel.Hide()
        if frame then frame:Hide() end
    end

    function panel.Refresh()
        if not frame or not frame:IsShown() then return end

        local manifest = model.GetManifest()
        local count = model.GetManifestCount()
        local total = model.GetManifestTotalValue()

        if count == 0 then
            frame.status:SetText(L["status:noItemsToSell"])
        else
            frame.status:SetText(format(L["status:itemsTotal"], count, GetCoinTextureString(total)))
        end

        frame.dataProvider:Flush()
        for _, item in ipairs(manifest) do
            frame.dataProvider:Insert(item)
        end
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

    local function QualityOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add(0, L["quality:poor"])
        container:Add(1, L["quality:common"])
        container:Add(2, L["quality:uncommon"])
        container:Add(3, L["quality:rare"])
        container:Add(4, L["quality:epic"])
        return container:GetData()
    end

    local EXPANSION_IDS = {
        { L["expansion:all"],                0 },
        { L["expansion:classic"],            1 },
        { L["expansion:burningCrusade"],     2 },
        { L["expansion:wrathOfTheLichKing"], 3 },
        { L["expansion:cataclysm"],          4 },
        { L["expansion:mistsOfPandaria"],    5 },
        { L["expansion:warlordsOfDraenor"],  6 },
        { L["expansion:legion"],             7 },
        { L["expansion:battleForAzeroth"],   8 },
        { L["expansion:shadowlands"],        9 },
        { L["expansion:dragonflight"],       10 },
        { L["expansion:theWarWithin"],       11 },
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

        cat:AddCheckbox("sellJunk", model.GetSellJunk, model.SetSellJunk)
        cat:AddCheckbox("keepEquippable", model.GetKeepEquippable, model.SetKeepEquippable)
        cat:AddCheckbox("keepBindOnAccount", model.GetKeepBindOnAccount, model.SetKeepBindOnAccount)
        cat:AddCheckbox("keepBindOnAccountPastExpac", model.GetKeepBindOnAccountPastExpac,
            model.SetKeepBindOnAccountPastExpac)
        cat:AddCheckbox("keepDisenchantables", model.GetKeepDisenchantables, model.SetKeepDisenchantables)
        cat:AddCheckbox("keepDisenchantablesPastExpac", model.GetKeepDisenchantablesPastExpac,
            model.SetKeepDisenchantablesPastExpac)
        cat:AddCheckbox("limitBatch", model.GetLimitBatchTo12, model.SetLimitBatchTo12)
        cat:AddDropdown("qualityThreshold", model.GetQualityThreshold, model.SetQualityThreshold, QualityOptions)
        cat:AddSlider("ilvlThreshold", model.GetIlvlThreshold, model.SetIlvlThreshold, -50, 0, 1)
        cat:AddCheckbox("sellPastExpansion", model.GetSellPastExpansion, model.SetSellPastExpansion)
        cat:AddDropdown("expansionThreshold", model.GetExpansionThreshold, model.SetExpansionThreshold, ExpansionOptions)

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

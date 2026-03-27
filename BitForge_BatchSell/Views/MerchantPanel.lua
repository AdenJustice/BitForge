local ns = select(2, ...)

local ipairs      = ipairs
local format      = string.format

local CreateFrame = CreateFrame
local C_Item      = C_Item

local model = ns.Model
local L     = ns.L

ns.View               = ns.View or {}
ns.View.MerchantPanel = {}
local panel           = ns.View.MerchantPanel

-- =========================================================
-- Frame construction
-- =========================================================

local frame -- built lazily on first Show so MerchantFrame exists

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
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -8)
    title:SetText(L["panel:batchSell"])

    -- Status bar
    local status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -30)
    status:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -30)
    status:SetJustifyH("LEFT")
    status:SetText(L["status:noItemsToSell"])
    f.status = status

    -- Button row
    local btnRow = CreateFrame("Frame", nil, f)
    btnRow:SetHeight(28)
    btnRow:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 8)
    btnRow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

    local refreshBtn = CreateFrame("Button", nil, btnRow, "UIPanelButtonTemplate")
    refreshBtn:SetSize(80, 24)
    refreshBtn:SetPoint("LEFT", btnRow, "LEFT", 0, 0)
    refreshBtn:SetText(L["btn:refresh"])
    refreshBtn:SetScript("OnClick", function() ns.Controller.RefreshManifest() end)

    local sellBtn = CreateFrame("Button", nil, btnRow, "UIPanelButtonTemplate")
    sellBtn:SetSize(100, 24)
    sellBtn:SetPoint("RIGHT", btnRow, "RIGHT", 0, 0)
    sellBtn:SetText(L["btn:sellAll"])
    sellBtn:SetScript("OnClick", function() ns.Controller.SellBatch() end)
    f.sellBtn = sellBtn

    -- ScrollBox
    local scrollBox = CreateFrame("Frame", nil, f, "WowScrollBoxList")
    local scrollBar = CreateFrame("EventFrame", nil, f, "MinimalScrollBar")

    scrollBox:SetPoint("TOPLEFT", status, "BOTTOMLEFT", 0, -4)
    scrollBox:SetPoint("BOTTOMRIGHT", btnRow, "TOPRIGHT", -20, 4)

    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 2, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 2, 0)

    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(24)

    view:SetElementInitializer("Frame", function(row, data)
        if not row.icon then
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(16, 16)
            row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)

            row.value = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.value:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            row.value:SetJustifyH("RIGHT")

            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.label:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
            row.label:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
            row.label:SetJustifyH("LEFT")
            row.label:SetWordWrap(false)

            row:SetScript("OnMouseDown", function(self)
                local item = self._data
                if not item then return end
                local itemLink = item.itemLink
                MenuUtil.CreateContextMenu(self, function(_, root)
                    root:CreateTitle(item.name)
                    root:CreateButton(L["menu:addToBlacklist"], function()
                        model.SetEnlisted(itemLink, "blacklist", true)
                        ns.Controller.RefreshManifest()
                    end)
                    root:CreateButton(L["menu:addToWhitelist"], function()
                        model.SetEnlisted(itemLink, "whitelist", true)
                        ns.Controller.RefreshManifest()
                    end)
                    root:CreateButton(L["menu:addToBlacklistChar"], function()
                        model.SetEnlisted(itemLink, "charBlacklist", true)
                        ns.Controller.RefreshManifest()
                    end)
                    root:CreateButton(L["menu:addToWhitelistChar"], function()
                        model.SetEnlisted(itemLink, "charWhitelist", true)
                        ns.Controller.RefreshManifest()
                    end)
                    root:CreateButton(L["menu:resetListEntry"], function()
                        model.SetEnlisted(itemLink, "blacklist", false)
                        model.SetEnlisted(itemLink, "whitelist", false)
                        model.SetEnlisted(itemLink, "charBlacklist", false)
                        model.SetEnlisted(itemLink, "charWhitelist", false)
                        ns.Controller.RefreshManifest()
                    end)
                    root:CreateButton(L["menu:temporaryExclude"], function()
                        model.AddTempExclude(itemLink)
                        ns.Controller.RefreshManifest()
                    end)
                end)
            end)
        end

        row._data = data
        row.icon:SetTexture(C_Item.GetItemIconByID(data.itemID))
        row.label:SetText(data.itemLink)
        if data.level and data.level > 0 then
            row.label:SetText(format("%s [%d]", data.itemLink, data.level))
        end
        row.value:SetText(GetCoinTextureString(data:GetTotalSellValue()))
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
    f.scrollBox    = scrollBox
    f.dataProvider = CreateDataProvider()
    scrollBox:SetDataProvider(f.dataProvider)

    return f
end

-- =========================================================
-- Public interface
-- =========================================================

function panel.Show()
    if not frame then frame = BuildFrame() end
    frame:SetHeight(MerchantFrame:GetHeight())
    panel.Refresh()
    frame:Show()
end

function panel.Hide()
    if frame then frame:Hide() end
end

function panel.Refresh()
    if not frame or not frame:IsShown() then return end

    local manifest = model.GetManifest()
    local count    = model.GetManifestCount()
    local total    = model.GetManifestTotalValue()

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

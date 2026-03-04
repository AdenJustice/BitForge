--- @type string, ns.BatchSell
local ADDON_NAME, ns = ...
local gui = ns.gui
local L = ns.locale
--- @class BitForge.Views.BatchSell: BitForge.Views.Base
local view = ns.view

--- =========================================================
--- Caches
--- =========================================================

local _type = type
local _ipairs = ipairs
local _pairs = pairs
local _select = select
local _tonumber = tonumber
local _tostring = tostring
local _format = string.format
local _min = math.min

local _CreateFrame = CreateFrame
local _CreateScrollBoxListLinearView = CreateScrollBoxListLinearView
local _CreateDataProvider = CreateDataProvider
local _InitScrollBoxListWithScrollBar = ScrollUtil.InitScrollBoxListWithScrollBar
local _GetMoneyString = GetMoneyString
local _GetCursorInfo = GetCursorInfo
local _ClearCursor = ClearCursor
local _GetItemInfo = C_Item.GetItemInfo
local _PickupItem = C_Item.PickupItem

local _ACCEPT = ACCEPT
local _CANCEL = CANCEL

local FRAME_WIDTH, FRAME_HEIGHT = MerchantFrame:GetSize()
local TAB_HEIGHT = 24
local TAB_PADDING = 32
local ELEMENT_HEIGHT = 36
local TAB_NAMES = {
    L["tab:manifest"],
    L["tab:blacklist"],
    L["tab:whitelist"],
    L["tab:settings"],
}

local frames = {}
local selectedTab = 1
local settings = {}

--- =========================================================
--- Frame Creation
--- =========================================================

local function createMainFrame()
    local f = gui:CreateFrame(MerchantFrame, {
        width  = FRAME_WIDTH,
        height = FRAME_HEIGHT,
        point  = { "CENTER" },
        title  = L["title:main"],
    })

    -- Make frame not movable
    f:SetMovable(false)
    f:RegisterForDrag()
    f:Hide()

    return f
end

local function createTabBar(f)
    -- Compute the widest tab label to give all tabs a uniform width
    local measureFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local maxTextW = 0
    for _, name in _ipairs(TAB_NAMES) do
        measureFS:SetText(name)
        local w = measureFS:GetStringWidth() or 0
        if w > maxTextW then maxTextW = w end
    end
    measureFS:Hide()

    local tabW = math.ceil(maxTextW + TAB_PADDING)

    local tabItems = {}
    for i, name in _ipairs(TAB_NAMES) do
        tabItems[i] = { id = i, label = name }
    end

    local bar = gui:CreateTabBar(f, {
        position = "bottom",
        width    = FRAME_WIDTH,
        height   = TAB_HEIGHT,
        point    = { "TOPLEFT", f, "BOTTOMLEFT", 0, 0 },
        tabSize  = { tabW, TAB_HEIGHT },
        tabs     = tabItems,
        onChange = function(id) view:OnSelectTab(id) end,
    })

    return bar
end

local function createContentFrame(f)
    local content = _CreateFrame("Frame", nil, f)
    content:SetSize(FRAME_WIDTH - 32, FRAME_HEIGHT - 80)
    content:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 4, -4)
    content:SetPoint("BOTTOMRIGHT", f.Inset, "BOTTOMRIGHT", -4, 40)

    return content
end

local function listElementInitializer(frame, elementData)
    if not frame.initialized then
        frame:SetSize(FRAME_WIDTH - 60, ELEMENT_HEIGHT)
        frame:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")

        -- Icon
        frame.icon = frame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetSize(28, 28)
        frame.icon:SetPoint("LEFT", 4, 0)

        -- Item level
        frame.ilvl = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.ilvl:SetPoint("LEFT", frame.icon, "RIGHT", 4, 0)
        frame.ilvl:SetWidth(40)
        frame.ilvl:SetJustifyH("LEFT")

        -- Item link
        frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.text:SetPoint("LEFT", frame.ilvl, "RIGHT", 4, 0)
        frame.text:SetPoint("RIGHT", frame, "RIGHT", -120, 0)
        frame.text:SetJustifyH("LEFT")
        frame.text:SetWordWrap(false)

        -- Price
        frame.price = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.price:SetPoint("RIGHT", frame, "RIGHT", -70, 0)
        frame.price:SetWidth(60)
        frame.price:SetJustifyH("RIGHT")

        -- Warband icon (campfire)
        frame.warbandIcon = frame:CreateTexture(nil, "ARTWORK")
        frame.warbandIcon:SetAtlas("socialqueuing-icon-group")
        frame.warbandIcon:SetSize(16, 16)
        frame.warbandIcon:SetPoint("RIGHT", frame.price, "LEFT", -4, 0)

        -- Gear button
        frame.gearBtn = _CreateFrame("Button", nil, frame)
        frame.gearBtn:SetSize(20, 20)
        frame.gearBtn:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
        frame.gearBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
        frame.gearBtn:GetHighlightTexture():SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        frame.gearBtn:GetHighlightTexture():SetBlendMode("ADD")

        frame.initialized = true
    end

    -- Set data
    local itemTexture = elementData.icon or _select(10, _GetItemInfo(elementData.itemLink))
    frame.icon:SetTexture(itemTexture)

    if elementData.itemLevel then
        frame.ilvl:SetText(elementData.itemLevel)
        frame.ilvl:Show()
    else
        frame.ilvl:Hide()
    end

    frame.text:SetText(elementData.itemLink or "")

    if elementData.sellPrice then
        frame.price:SetText(_GetMoneyString(elementData.sellPrice))
        frame.price:Show()
    else
        frame.price:Hide()
    end

    -- Warband icon visibility
    if elementData.isGlobal ~= nil then
        frame.warbandIcon:Show()
        frame.warbandIcon:SetDesaturated(not elementData.isGlobal)
        frame.warbandIcon:SetAlpha(elementData.isGlobal and 1 or 0.5)
    else
        frame.warbandIcon:Hide()
    end

    -- Gear button click handler
    frame.gearBtn:SetScript("OnClick", function(btn)
        -- TODO:
    end)

    -- Drag and drop for non-manifest tabs
    if selectedTab ~= 1 then
        frame:SetScript("OnDragStart", function(self)
            _PickupItem(elementData.itemLink)
        end)
        frame:RegisterForDrag("LeftButton")
    else
        frame:SetScript("OnDragStart", nil)
        frame:RegisterForDrag()
    end
end

local function createScroll(parent)
    local scrollBox = _CreateFrame("Frame", nil, parent, "WowScrollBoxList") --[[@as WowScrollBoxList]]
    scrollBox:SetAllPoints(parent)

    local scrollBar = _CreateFrame("EventFrame", nil, parent, "MinimalScrollBar") --[[@as MinimalScrollBar]]
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)

    local listview = _CreateScrollBoxListLinearView()
    listview:SetElementInitializer(
        "Frame",
        function(frame, elementData)
            listElementInitializer(frame, elementData)
        end)
    listview:SetElementExtent(ELEMENT_HEIGHT)

    local dataProvider = _CreateDataProvider()

    _InitScrollBoxListWithScrollBar(scrollBox, scrollBar, listview)
    scrollBox:SetDataProvider(dataProvider)

    return scrollBox, scrollBar, dataProvider
end

local function createBottomSection(f)
    local bar = _CreateFrame("Frame", nil, f)
    bar:SetSize(FRAME_WIDTH - 32, 32)
    bar:SetPoint("BOTTOMLEFT", f.Inset, "BOTTOMLEFT", 4, 4)
    bar:SetPoint("BOTTOMRIGHT", f.Inset, "BOTTOMRIGHT", -4, 4)

    -- Sell All button
    local sellBtn = gui:CreateButton(bar, {
        width   = 140,
        height  = 28,
        point   = { "LEFT", bar, "LEFT", 4, 0 },
        text    = L["button:sell_all"],
        onClick = function() _SendMessage("onSellRequested") end,
    })
    sellBtn:Hide()

    bar.sellBtn = sellBtn

    -- Info text
    local infoText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    infoText:SetText("")
    bar.infoText = infoText

    return bar
end


--- =========================================================
--- Frame Update
--- =========================================================

function view:RefreshManifest(queue)
    assert(not queue or _type(queue) == "table", "Expected table for manifest queue")

    local dp = frames.dataProvider
    dp:Flush()

    if queue and #queue > 0 then
        dp:InsertTable(queue)
    end
end

function view:RefreshBlacklist(blacklistData)
    assert(not blacklistData or _type(blacklistData) == "table", "Expected table for blacklistData")

    local dp = frames.dataProvider
    dp:Flush()
    if blacklistData then
        dp:InsertTable(blacklistData)
    end
end

function view:RefreshWhitelist(whitelistData)
    assert(not whitelistData or _type(whitelistData) == "table", "Expected table for whitelistData")

    local dp = frames.dataProvider
    dp:Flush()

    if whitelistData then
        dp:InsertTable(whitelistData)
    end
end

--- @param show boolean
function view:ToggleSellButton(show)
    assert(frames.bottomBar and frames.bottomBar.sellBtn, "Sell button not initialized")

    frames.bottomBar.sellBtn:SetShown(show)
end

--- =========================================================
---
--- =========================================================
















--- [ helpers ]======================================================================

local function updateBottomSection()
    local bar = frames.bottomBar
    if not bar then return end

    if selectedTab == 1 then
        -- Manifest tab
        local queueCount = settings.queueCount or 0
        local queueValue = settings.queueValue or 0

        bar.sellBtn:SetShown(queueCount > 0)

        if queueCount > 0 then
            local limitTo12 = settings.limitBatchTo12
            local itemsToSell = limitTo12 and _min(queueCount, 12) or queueCount
            bar.infoText:SetText(_format(L["info:items_value"], itemsToSell, _GetMoneyString(queueValue)))
        else
            bar.infoText:SetText(L["info:no_items"])
        end
    else
        bar.sellBtn:Hide()
        bar.infoText:SetText("")
    end
end

local function createSettingsTab()
    local content = frames.content
    if not content then return end

    -- Clear existing settings
    if frames.settingsContent then
        frames.settingsContent:Hide()
        frames.settingsContent = nil
    end

    local settingsFrame = _CreateFrame("Frame", nil, content)
    settingsFrame:SetAllPoints(content)
    settingsFrame:Hide()

    local yOffset = -20

    -- Sell Junk checkbox
    local sellJunkCheck = gui:CreateCheckbox(settingsFrame, {
        point   = { "TOPLEFT", settingsFrame, "TOPLEFT", 10, yOffset },
        text    = L["setting:sell_junk"],
        checked = settings.sellJunk or false,
        onClick = function(self) _SendMessage("onSettingChanged", "sellJunk", self:GetChecked()) end,
    })

    yOffset = yOffset - 40

    -- Disenchantable items checkbox (only if character has Enchanting)
    if settings.hasEnchanting then
        gui:CreateCheckbox(settingsFrame, {
            point   = { "TOPLEFT", settingsFrame, "TOPLEFT", 10, yOffset },
            text    = L["setting:include_disenchantables"],
            checked = settings.keepDisenchantables or false,
            onClick = function(self) _SendMessage("onSettingChanged", "keepDisenchantables", self:GetChecked()) end,
        })

        yOffset = yOffset - 40
    end

    -- Item level threshold
    local ilvlLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ilvlLabel:SetPoint("TOPLEFT", 10, yOffset)
    ilvlLabel:SetText(L["setting:ilvl_threshold"])

    yOffset = yOffset - 30

    local ilvlEdit = gui:CreateEditBox(settingsFrame, {
        width  = 120,
        height = 30,
        point  = { "TOPLEFT", settingsFrame, "TOPLEFT", 10, yOffset },
    })
    ilvlEdit:SetAutoFocus(false)
    ilvlEdit:SetText(_tostring(settings.ilvlThreshold or 0.1))
    ilvlEdit:SetScript("OnEnterPressed", function(self)
        local value = _tonumber(self:GetText())
        if value and value >= 0 then
            _SendMessage("onSettingChanged", "ilvlThreshold", value)
            settings.ilvlThreshold = value
        else
            self:SetText(_tostring(settings.ilvlThreshold or 0.1))
        end
        self:ClearFocus()
    end)

    local ilvlHelp = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ilvlHelp:SetPoint("TOPLEFT", ilvlEdit, "BOTTOMLEFT", 0, -8)
    ilvlHelp:SetText(L["setting:ilvl_threshold_help"])
    ilvlHelp:SetTextColor(0.7, 0.7, 0.7)

    yOffset = yOffset - 70

    -- Limit to 12 items checkbox
    gui:CreateCheckbox(settingsFrame, {
        point   = { "TOPLEFT", settingsFrame, "TOPLEFT", 10, yOffset },
        text    = L["setting:limit_to_12"],
        checked = settings.limitBatchTo12 ~= false,
        onClick = function(self) _SendMessage("onSettingChanged", "limitBatchTo12", self:GetChecked()) end,
    })

    frames.settingsContent = settingsFrame
    return settingsFrame
end

local function _OnItemDrop()
    local cursorType, _, itemLink = _GetCursorInfo()
    if cursorType ~= "item" or not itemLink then return end

    if selectedTab == 2 then
        -- Blacklist tab - add to character blacklist by default
        _SendMessage("onItemDropped", itemLink, "blacklist", false)
    elseif selectedTab == 3 then
        -- Whitelist tab - add to character whitelist by default
        _SendMessage("onItemDropped", itemLink, "whitelist", false)
    end

    _ClearCursor()
end

--- [ public API ]======================================================================

function view:UpdateSettings(updatedSettings)
    for k, v in _pairs(updatedSettings) do
        settings[k] = v
    end
    updateBottomSection()
end

function view:Initialize()
    -- Create main UI structure
    local f = createMainFrame()
    local tabBar = createTabBar(f)
    local content = createContentFrame(f)
    local bottomBar = createBottomSection(f)

    frames.main = f
    frames.tabBar = tabBar
    frames.content = content
    frames.bottomBar = bottomBar

    -- Create scroll view
    local scrollBox, scrollBar, dataProvider = createScroll(content)
    frames.scrollBox = scrollBox
    frames.scrollBar = scrollBar
    frames.dataProvider = dataProvider

    -- Create settings tab
    createSettingsTab()

    -- Select first tab
    self:OnSelectTab(1)

    -- Register for drag and drop
    content:EnableMouse(true)
    content:RegisterForDrag("LeftButton")
    content:SetScript("OnReceiveDrag", function()
        _OnItemDrop()
    end)
    content:SetScript("OnMouseUp", function()
        _OnItemDrop()
    end)
end

function view:Enable()
    -- View is enabled on initialization
end

function view:Disable()
    if frames.main then
        frames.main:Hide()
    end
end

function view:Show()
    if frames.main then
        frames.main:Show()
    end
end

function view:Hide()
    if frames.main then
        frames.main:Hide()
    end
end

function view:OnSelectTab(tabIdx)
    selectedTab = tabIdx

    -- Sync tab bar visual state (guard in TabBarMixin prevents infinite recursion)
    if frames.tabBar then
        frames.tabBar:SetSelectedTab(tabIdx)
    end

    -- Show appropriate content
    if tabIdx == 4 then
        -- Settings tab
        frames.scrollBox:Hide()
        if frames.settingsContent then
            frames.settingsContent:Show()
        end
    else
        -- List tabs
        if frames.settingsContent then
            frames.settingsContent:Hide()
        end
        frames.scrollBox:Show()

        if tabIdx == 1 then
            _SendMessage("onRequestManifest")
        elseif tabIdx == 2 then
            _SendMessage("onRequestBlacklist")
        elseif tabIdx == 3 then
            _SendMessage("onRequestWhitelist")
        end
    end

    updateBottomSection()
end


--- [ Static Popup ]======================================================================

StaticPopupDialogs["BITFORGE_BATCHSELL_CONFIRM"] = {
    text = L["popup:confirm_sell"],
    button1 = _ACCEPT,
    button2 = _CANCEL,
    OnAccept = function()
        _SendMessage("onSellConfirmed")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local _, ns          = ...
local oUF            = _G["oUF"]

ns.ClassPanelView    = {}
local View           = ns.ClassPanelView

-- Layout constants
local PANEL_WIDTH    = 220
local ICON_SIZE      = 26 -- buff icon square
local ICON_GAP       = 4  -- gap between buff icons
local BAR_HEIGHT     = 8  -- ClassPower / Rune bar height
local BAR_GAP        = 2  -- gap between ClassPower / Rune bars
local POWER_HEIGHT   = 12 -- main power bar height
local BUFF_BAR_H     = 18 -- height of each buff bar row
local BUFF_BAR_GAP   = 2  -- gap between buff bar rows
local CD_ICON_SIZE   = 32 -- cooldown icon square
local SECTION_GAP    = 4  -- gap between major sections

local MAX_BUFF_ICONS = 10
local MAX_BUFF_BARS  = 5
local MAX_CD_ICONS   = 20

-- Pre-allocated pools (populated in oUF factory on PLAYER_LOGIN)
local buffIconPool   = {} -- Button[MAX_BUFF_ICONS]
local buffBarPool    = {} -- Frame[MAX_BUFF_BARS], each has .icon, .bar
local cdIconPool     = {} -- Button[MAX_CD_ICONS]

-- ─── oUF Style ────────────────────────────────────────────────

oUF:RegisterStyle("BitForge_ClassPanel", function(self, unit)
    local outerH = BAR_HEIGHT + BAR_GAP + POWER_HEIGHT -- 22 px
    self:SetSize(PANEL_WIDTH, outerH)

    -- Power bar (bottom of oUF frame)
    local power = CreateFrame("StatusBar", nil, self)
    power:SetHeight(POWER_HEIGHT)
    power:SetPoint("BOTTOMLEFT", self)
    power:SetPoint("BOTTOMRIGHT", self)
    power:SetStatusBarTexture(ns.TEXTURE)
    power.colorPower        = true
    power.colorDisconnected = true
    self.Power              = power

    -- ClassPower bars: addon creates the bars; oUF updates values and colors.
    -- PostUpdate redistributes widths when max changes (spec/talent change).
    local classpower        = {}
    for i = 1, 10 do
        local bar = CreateFrame("StatusBar", nil, self)
        bar:SetHeight(BAR_HEIGHT)
        bar:SetStatusBarTexture(ns.TEXTURE)
        classpower[i] = bar
    end
    classpower.PostUpdate = function(element, cur, max, hasMaxChanged, powerType)
        if not hasMaxChanged or max == 0 then return end
        local barW = (PANEL_WIDTH - (max - 1) * BAR_GAP) / max
        for i = 1, 10 do
            element[i]:ClearAllPoints()
            if i <= max then
                element[i]:SetWidth(barW)
                if i == 1 then
                    element[i]:SetPoint("BOTTOMLEFT", power, "TOPLEFT", 0, BAR_GAP)
                else
                    element[i]:SetPoint("LEFT", element[i - 1], "RIGHT", BAR_GAP, 0)
                end
                element[i]:Show()
            else
                element[i]:Hide()
            end
        end
    end
    self.ClassPower       = classpower

    -- Runes (Death Knight only, always 6 — no PostUpdate needed)
    local runes           = {}
    local runeW           = (PANEL_WIDTH - 5 * BAR_GAP) / 6
    for i = 1, 6 do
        local bar = CreateFrame("StatusBar", nil, self)
        bar:SetSize(runeW, BAR_HEIGHT)
        bar:SetStatusBarTexture(ns.TEXTURE)
        if i == 1 then
            bar:SetPoint("BOTTOMLEFT", power, "TOPLEFT", 0, BAR_GAP)
        else
            bar:SetPoint("LEFT", runes[i - 1], "RIGHT", BAR_GAP, 0)
        end
        runes[i] = bar
    end
    self.Runes = runes
end)

-- ─── Pool Constructors ────────────────────────────────────────

local function NewIconButton(parent, size)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(size, size)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = tex

    local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetHideCountdownNumbers(false)
    btn.cooldown = cd

    btn:Hide()
    return btn
end

local function NewBuffBarRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(PANEL_WIDTH, BUFF_BAR_H)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(BUFF_BAR_H, BUFF_BAR_H)
    icon:SetPoint("LEFT", row)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon = icon

    local bar = CreateFrame("StatusBar", nil, row)
    bar:SetStatusBarTexture(ns.TEXTURE)
    bar:SetHeight(BUFF_BAR_H)
    bar:SetPoint("LEFT", icon, "RIGHT", ICON_GAP, 0)
    bar:SetPoint("RIGHT", row)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    row.bar = bar

    row:Hide()
    return row
end

-- ─── Factory ──────────────────────────────────────────────────

oUF:Factory(function(self)
    if not ns.Model.GetClassPanelEnabled() then return end

    self:SetActiveStyle("BitForge_ClassPanel")

    -- ClassPanel container (fixed center, not movable)
    local outerH    = BAR_HEIGHT + BAR_GAP + POWER_HEIGHT                               -- 22
    local buffBarsH = MAX_BUFF_BARS * BUFF_BAR_H + (MAX_BUFF_BARS - 1) * BUFF_BAR_GAP   -- 98
    local totalH    = ICON_SIZE + SECTION_GAP + buffBarsH + SECTION_GAP
        + outerH + SECTION_GAP + CD_ICON_SIZE                                           -- 190
    local panel     = CreateFrame("Frame", "BitForge_ClassPanel", UIParent)
    panel:SetSize(PANEL_WIDTH, totalH)
    panel:SetPoint("CENTER", UIParent)

    -- ClassPanelHooks: BuffIcons row + BuffBars section
    local hooksFrame = CreateFrame("Frame", nil, panel)
    hooksFrame:SetPoint("TOPLEFT", panel)
    hooksFrame:SetSize(PANEL_WIDTH, ICON_SIZE + SECTION_GAP + buffBarsH)

    -- BuffIcons: row of icon buttons anchored to top of hooksFrame
    for i = 1, MAX_BUFF_ICONS do
        local btn = NewIconButton(hooksFrame, ICON_SIZE)
        if i == 1 then
            btn:SetPoint("TOPLEFT", hooksFrame)
        else
            btn:SetPoint("LEFT", buffIconPool[i - 1], "RIGHT", ICON_GAP, 0)
            btn:SetPoint("TOP", hooksFrame)
        end
        buffIconPool[i] = btn
    end

    -- BuffBars: stacked rows below the icon row
    for i = 1, MAX_BUFF_BARS do
        local row = NewBuffBarRow(hooksFrame)
        if i == 1 then
            row:SetPoint("TOPLEFT", hooksFrame, "TOPLEFT", 0, -(ICON_SIZE + SECTION_GAP))
        else
            row:SetPoint("TOPLEFT", buffBarPool[i - 1], "BOTTOMLEFT", 0, -BUFF_BAR_GAP)
        end
        buffBarPool[i] = row
    end

    -- oUF sub-frame: Power + ClassPower/Runes, below hooksFrame
    local unitFrame = self:Spawn("player", "BitForge_ClassPanelUnitFrame")
    unitFrame:SetParent(panel)
    unitFrame:ClearAllPoints()
    local ufTopOffset = -(ICON_SIZE + SECTION_GAP + buffBarsH + SECTION_GAP)
    unitFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, ufTopOffset)
    unitFrame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, ufTopOffset)

    -- ClassPanelCooldowns: CooldownIcons row, below oUF frame
    local cdFrame = CreateFrame("Frame", nil, panel)
    cdFrame:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 0, -SECTION_GAP)
    cdFrame:SetSize(PANEL_WIDTH, CD_ICON_SIZE)

    for i = 1, MAX_CD_ICONS do
        local btn = NewIconButton(cdFrame, CD_ICON_SIZE)
        if i == 1 then
            btn:SetPoint("LEFT", cdFrame)
        else
            btn:SetPoint("LEFT", cdIconPool[i - 1], "RIGHT", ICON_GAP, 0)
        end
        cdIconPool[i] = btn
    end
end)

-- ─── Update Methods (called by ClassPanelController) ──────────

-- spells: array of { spellID=number, isActive=bool, duration=number, expirationTime=number }
function View.UpdateBuffIcons(spells)
    for i = 1, MAX_BUFF_ICONS do
        local btn = buffIconPool[i]
        if not btn then break end -- factory did not run (feature disabled)
        local data = spells[i]
        if data then
            btn.icon:SetTexture(C_Spell.GetSpellTexture(data.spellID))
            if data.isActive and data.duration > 0 then
                btn.cooldown:SetCooldown(data.expirationTime - data.duration, data.duration)
            else
                btn.cooldown:Clear()
            end
            btn:Show()
        else
            btn:Hide()
        end
    end
end

-- spells: array of { spellID=number, isActive=bool, duration=number, expirationTime=number }
function View.UpdateBuffBars(spells)
    for i = 1, MAX_BUFF_BARS do
        local row = buffBarPool[i]
        if not row then break end
        local data = spells[i]
        if data then
            row.icon:SetTexture(C_Spell.GetSpellTexture(data.spellID))
            if data.isActive and data.duration > 0 then
                local remaining = data.expirationTime - GetTime()
                row.bar:SetMinMaxValues(0, data.duration)
                row.bar:SetValue(math.max(0, remaining))
            else
                row.bar:SetMinMaxValues(0, 1)
                row.bar:SetValue(0)
            end
            row:Show()
        else
            row:Hide()
        end
    end
end

-- spells: array of { spellID=number, start=number, duration=number, enabled=boolean }
function View.UpdateCooldownIcons(spells)
    for i = 1, MAX_CD_ICONS do
        local btn = cdIconPool[i]
        if not btn then break end
        local data = spells[i]
        if data then
            btn.icon:SetTexture(C_Spell.GetSpellTexture(data.spellID))
            if data.duration > 0 and data.enabled then
                btn.cooldown:SetCooldown(data.start, data.duration)
            else
                btn.cooldown:Clear()
            end
            btn:Show()
        else
            btn:Hide()
        end
    end
end

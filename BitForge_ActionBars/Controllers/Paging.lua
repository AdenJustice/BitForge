local ns = select(2, ...)

local pairs = pairs
local RegisterStateDriver = RegisterStateDriver
local RegisterAttributeDriver = RegisterAttributeDriver
local CreateFrame = CreateFrame

local NUM_AB_PAGES = NUM_ACTIONBAR_PAGES or 6
local NUM_AB_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12
local PLAYER_CLASS = select(2, UnitClass("player"))

-------------------------------------------------------------------------------
--  SHOWGRID CONTROLLER
--  Central SecureHandlerAttributeTemplate that broadcasts showgrid flag
--  changes to every registered action button.
--
--  Restricted Lua has no bit library; flag tests use modular arithmetic:
--      bit SET:   cur = cur + reason  (if not already set)
--      bit CLEAR: cur = cur - reason  (if set)
--      bit TEST:  cur % (reason*2) >= reason
-------------------------------------------------------------------------------
local SHOWGRID_GAME = 2 -- set by Blizzard during spell drag

local abController = CreateFrame("Frame", "BitForge_ABController", UIParent,
    "SecureHandlerAttributeTemplate")
local _controllerButtons = {}

abController:Execute([[ _bfBtnMap = table.new() ]])

abController:SetAttributeNoHandler("SetShowGrid", [[
    local show, reason = ...
    local cur = self:GetAttribute("showgrid") or 0
    local prev = cur
    if show then
        if cur % (reason * 2) < reason then cur = cur + reason end
    elseif cur % (reason * 2) >= reason then
        cur = cur - reason
    end
    if prev ~= cur then
        self:SetAttribute("showgrid", cur)
        for btn in pairs(_bfBtnMap) do
            btn:RunAttribute("SetShowGrid", show, reason)
        end
    end
]])

local BTN_ON_ATTR_CHANGED = [[
    if name == "action" then
        _bfBtnMap[self] = true
    end
]]

local function RegisterButtonWithController(btn)
    if _controllerButtons[btn] then return end

    if btn:GetAttribute("_bfRegistered") then
        _controllerButtons[btn] = true
        return
    end

    abController:WrapScript(btn, "OnAttributeChanged", BTN_ON_ATTR_CHANGED)

    btn:SetAttributeNoHandler("SetShowGrid", [[
        local show, reason = ...
        local cur = self:GetAttribute("showgrid") or 0
        local prev = cur
        if show then
            if cur % (reason * 2) < reason then cur = cur + reason end
        elseif cur % (reason * 2) >= reason then
            cur = cur - reason
        end
        if prev ~= cur then
            self:SetAttribute("showgrid", cur)
            local vis = (cur > 0 or HasAction(self:GetAttribute("action") or 0))
                and not self:GetAttribute("statehidden")
            if vis then self:Show(true) else self:Hide(true) end
        end
    ]])

    btn:SetAttributeNoHandler("UpdateShown", [[
        local grid   = (self:GetAttribute("showgrid") or 0) > 0
        local hasAct = HasAction(self:GetAttribute("action") or 0)
        local hidden = self:GetAttribute("statehidden")
        if (grid or hasAct) and not hidden then self:Show(true) else self:Hide(true) end
    ]])

    abController:SetFrameRef("add", btn)
    abController:Execute([[ _bfBtnMap[self:GetFrameRef("add")] = true ]])

    btn:SetAttributeNoHandler("_bfRegistered", true)
    _controllerButtons[btn] = true
end

ns.RegisterButtonWithController = RegisterButtonWithController
ns.SHOWGRID_GAME = SHOWGRID_GAME

-------------------------------------------------------------------------------
--  OVERRIDE / VEHICLE CONTROLLER
--  Parented to OverrideActionBar so OnShow/OnHide fire when vehicle UI appears.
--  Propagates overrideui, petbattleui, overridepage states to all bar frames.
-------------------------------------------------------------------------------
local overrideCtrl = CreateFrame("Frame", "BitForge_ABOverrideCtrl",
    OverrideActionBar or UIParent,
    "SecureHandlerAttributeTemplate, SecureHandlerShowHideTemplate")

overrideCtrl:SetAttributeNoHandler("_onattributechanged", [[
    if name == "overrideui" or name == "petbattleui" or name == "overridepage" then
        for _, f in pairs(_bfBarFrames) do
            f:SetAttribute("state-" .. name,
                name == "overridepage" and value or (value == 1))
        end
    else
        local pg = 0
        if HasVehicleActionBar and HasVehicleActionBar() then
            pg = GetVehicleBarIndex() or 0
        elseif HasOverrideActionBar and HasOverrideActionBar() then
            pg = GetOverrideBarIndex() or 0
        elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
            pg = GetTempShapeshiftBarIndex() or 0
        end
        if self:GetAttribute("overridepage") ~= pg then
            self:SetAttribute("overridepage", pg)
        end
    end
]])
overrideCtrl:SetAttributeNoHandler("_onshow", [[ self:SetAttribute("overrideui", 1) ]])
overrideCtrl:SetAttributeNoHandler("_onhide", [[ self:SetAttribute("overrideui", 0) ]])

overrideCtrl:Execute([[ _bfBarFrames = table.new() ]])

for attr, driver in pairs({
    form        = "[form]1;0",
    overridebar = "[overridebar]1;0",
    possessbar  = "[possessbar]1;0",
    sstemp      = "[shapeshift]1;0",
    vehicle     = "[@vehicle,exists]1;0",
    vehicleui   = "[vehicleui]1;0",
    petbattleui = "[petbattle]1;0",
}) do
    RegisterAttributeDriver(overrideCtrl, attr, driver)
end

if OverrideActionBar then
    overrideCtrl:SetAttributeNoHandler("overrideui",
        OverrideActionBar:IsVisible() and 1 or 0)
end

local function RegisterBarWithOverrideCtrl(frame)
    overrideCtrl:SetFrameRef("add", frame)
    overrideCtrl:Execute([[ table.insert(_bfBarFrames, self:GetFrameRef("add")) ]])
    frame:SetAttribute("state-overrideui",
        tonumber(overrideCtrl:GetAttribute("overrideui")) == 1)
    frame:SetAttribute("state-petbattleui",
        tonumber(overrideCtrl:GetAttribute("petbattleui")) == 1)
    frame:SetAttribute("state-overridepage",
        overrideCtrl:GetAttribute("overridepage") or 0)
end

-------------------------------------------------------------------------------
--  PAGING CONDITIONS
--  Class-aware condition string for RegisterStateDriver on the MainBar frame.
-------------------------------------------------------------------------------
local function GetPagingConditions()
    local cond = ""

    if GetOverrideBarIndex then
        cond = cond .. "[overridebar] " .. GetOverrideBarIndex() .. "; "
    end
    if GetVehicleBarIndex then
        cond = cond .. "[vehicleui][possessbar] " .. GetVehicleBarIndex() .. "; "
    end

    if PLAYER_CLASS == "DRUID" then
        cond = cond .. "[bonusbar:1,stealth] 7; [bonusbar:1] 7; [bonusbar:3] 9; [bonusbar:4] 10; "
    elseif PLAYER_CLASS == "ROGUE" then
        cond = cond .. "[bonusbar:1] 7; "
    end

    cond = cond .. "[bonusbar:5] 11; "

    for i = 2, NUM_AB_PAGES do
        cond = cond .. "[bar:" .. i .. "] " .. i .. "; "
    end

    return cond .. "1"
end

-------------------------------------------------------------------------------
--  BAR FRAME CREATION
--  Each bar gets a SecureHandlerStateTemplate frame.
--  MainBar additionally gets paging state drivers and UpdateOffset logic.
--  Bar2-Bar8 get CVar-based visibility drivers.
--  StanceBar/PetBar get their Blizzard-equivalent visibility drivers.
-------------------------------------------------------------------------------
local BAR_VISIBILITY_DRIVERS = {
    Bar2      = "[cvar:SHOW_MULTI_ACTIONBAR_1,1] show; hide",
    Bar3      = "[cvar:SHOW_MULTI_ACTIONBAR_2,1] show; hide",
    Bar4      = "[cvar:SHOW_MULTI_ACTIONBAR_3,1] show; hide",
    Bar5      = "[cvar:SHOW_MULTI_ACTIONBAR_4,1] show; hide",
    Bar6      = "[cvar:SHOW_MULTI_ACTIONBAR_5,1] show; hide",
    Bar7      = "[cvar:SHOW_MULTI_ACTIONBAR_6,1] show; hide",
    Bar8      = "[cvar:SHOW_MULTI_ACTIONBAR_7,1] show; hide",
    StanceBar = "[bonusbar:0,nostealth,nodead,nopossessbar,novehicleui] hide; show",
    PetBar    = "[nopet][petbattle] hide; show",
}

local function CreateBarFrame(def)
    local key   = def.key
    local frame = CreateFrame("Frame", "BitForge_AB_" .. key, UIParent,
        "SecureHandlerStateTemplate")
    frame:SetSize(1, 1)
    frame:SetPoint("CENTER")
    if frame.SetMouseClickEnabled then
        frame:SetMouseClickEnabled(false)
    end
    frame._bfKey = key

    if key == "MainBar" then
        frame:SetAttribute("barLength", NUM_AB_BUTTONS)
        frame:SetAttribute("overrideBarLength", NUM_AB_BUTTONS)
        frame:SetAttribute("state-overridebar", false)

        frame:SetAttribute("_onstate-overridebar", [[ self:RunAttribute("UpdateOffset") ]])
        frame:SetAttribute("_onstate-overridepage", [[ self:RunAttribute("UpdateOffset") ]])
        frame:SetAttribute("_onstate-page", [[ self:RunAttribute("UpdateOffset") ]])

        frame:SetAttribute("UpdateOffset", [[
            local offset = 0
            local overridePage = self:GetAttribute("state-overridepage") or 0
            if overridePage > 0 and self:GetAttribute("state-overridebar") then
                offset = (overridePage - 1) * self:GetAttribute("overrideBarLength")
            else
                local page = self:GetAttribute("state-page") or 1
                if page == 11 then
                    if HasVehicleActionBar() then
                        page = GetVehicleBarIndex()
                    elseif HasOverrideActionBar() then
                        page = GetOverrideBarIndex()
                    elseif HasTempShapeshiftActionBar() then
                        page = GetTempShapeshiftBarIndex()
                    elseif HasBonusActionBar() then
                        page = GetBonusBarIndex()
                    end
                end
                local barLen = self:GetAttribute("barLength")
                offset = (page - 1) * barLen
                if offset >= 132 then offset = offset + 12 end
            end
            self:SetAttribute("actionOffset", offset)
            control:ChildUpdate("offset", offset)
        ]])

        RegisterStateDriver(frame, "page", GetPagingConditions())
    end

    local visDriver = BAR_VISIBILITY_DRIVERS[key]
    if visDriver then
        RegisterAttributeDriver(frame, "state-visibility", visDriver)
    end

    RegisterBarWithOverrideCtrl(frame)
    return frame
end

ns.CreateBarFrame = CreateBarFrame

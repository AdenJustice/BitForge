local setmetatable = setmetatable
local tostring = tostring
local upper = string.upper
local gsub = string.gsub

local Settings = Settings
local SettingsInbound = SettingsInbound
local MinimalSliderWithSteppersMixin = MinimalSliderWithSteppersMixin
local TextureKitConstants = TextureKitConstants

-- =========================================================
-- BitForge.Settings — WoW Settings API helpers for modules
-- =========================================================

BitForge.Settings = {}
local S = BitForge.Settings

local PREFIX_LEN = #"BitForge_"

-- =========================================================
-- Handle Struct
-- =========================================================

local Handle = {}
Handle.__index = Handle

local function BuildKey(prefix, name)
    return "BITFORGE_" .. prefix .. "_" .. gsub(upper(name), "[^%w]", "_")
end

local function ResolveLabel(self, name)
    local key = "settings:" .. name
    local L = self._L
    assert(L[key], "BitForge.Settings: missing locale key '" .. key .. "'")
    return L[key], L[key .. "Tooltip"]
end

--- Creates a WoW Settings subcategory under the BitForge root and returns
--- a category handle for registering settings.
---@param addonName string  The addon's name from `...`, e.g. "BitForge_AutoBalance"
---@param title     string  Already-resolved display title for the subcategory
---@param L         table   The module's locale table (ns.L)
---@return table            Category handle
function S.NewSubcategory(addonName, title, L)
    local prefix = upper(addonName:sub(PREFIX_LEN + 1))
    local category, layout = Settings.RegisterVerticalLayoutSubcategory(
        BitForge.settingsCategory, title)
    return setmetatable({ _prefix = prefix, _L = L, _cat = category, _layout = layout }, Handle)
end

-- =========================================================
-- High-level helpers
-- =========================================================

function Handle:AddCheckbox(name, getter, setter)
    local label, tooltip = ResolveLabel(self, name)
    local setting = Settings.RegisterProxySetting(
        self._cat, BuildKey(self._prefix, name),
        Settings.VarType.Boolean, label, getter(), getter, setter)
    local initializer = Settings.CreateCheckbox(self._cat, setting, tooltip)
    if self._currentSection then
        local section = self._currentSection
        initializer:AddShownPredicate(function() return section:IsExpanded() end)
    end
    return setting
end

--- varType defaults to Settings.VarType.Number; pass Settings.VarType.String for string dropdowns.
function Handle:AddDropdown(name, getter, setter, optionsFn, varType)
    local label, tooltip = ResolveLabel(self, name)
    local setting = Settings.RegisterProxySetting(
        self._cat, BuildKey(self._prefix, name),
        varType or Settings.VarType.Number, label, getter(), getter, setter)
    local initializer = Settings.CreateDropdown(self._cat, setting, optionsFn, tooltip)
    if self._currentSection then
        local section = self._currentSection
        initializer:AddShownPredicate(function() return section:IsExpanded() end)
    end
    return setting
end

--- formatterFn defaults to tostring.
function Handle:AddSlider(name, getter, setter, min, max, step, formatterFn)
    local label, tooltip = ResolveLabel(self, name)
    local setting = Settings.RegisterProxySetting(
        self._cat, BuildKey(self._prefix, name),
        Settings.VarType.Number, label, getter(), getter, setter)
    local options = Settings.CreateSliderOptions(min, max, step)
    options:SetLabelFormatter(
        MinimalSliderWithSteppersMixin.Label.Right,
        formatterFn or tostring)
    local initializer = Settings.CreateSlider(self._cat, setting, options, tooltip)
    if self._currentSection then
        local section = self._currentSection
        initializer:AddShownPredicate(function() return section:IsExpanded() end)
    end
    return setting
end

--- getter() returns r, g, b floats; setter(r, g, b) applies them.
--- Internally bridges to the WoW Settings hex-string color swatch API.
function Handle:AddColorPicker(name, getter, setter)
    local label, tooltip = ResolveLabel(self, name)
    local function hexGetter()
        local r, g, b = getter()
        return CreateColor(r, g, b):GenerateHexColor()
    end
    local function hexSetter(hex)
        local color = CreateColorFromHexString(hex)
        if color then
            setter(color:GetRGB())
        end
    end
    local setting = Settings.RegisterProxySetting(
        self._cat, BuildKey(self._prefix, name),
        Settings.VarType.String, label, hexGetter(), hexGetter, hexSetter)
    local initializer = Settings.CreateColorSwatch(self._cat, setting, tooltip)
    if self._currentSection then
        local section = self._currentSection
        initializer:AddShownPredicate(function() return section:IsExpanded() end)
    end
    return setting
end

-- =========================================================
-- Low-level helpers
-- =========================================================

--- Registers a proxy setting without creating a UI control. label is already-resolved.
function Handle:RegisterProxy(name, varType, label, getter, setter)
    return Settings.RegisterProxySetting(
        self._cat, BuildKey(self._prefix, name),
        varType, label, getter(), getter, setter)
end

function Handle:AddInitializer(initializer)
    if self._layout then
        self._layout:AddInitializer(initializer)
    end
end

--- Adds a collapsible section to the settings list. Items added after this call
--- (via AddCheckbox/AddDropdown/AddSlider) are hidden when the section is collapsed.
---@param name    string       Already-resolved display title for the section
---@param expanded boolean|nil Initial expanded state; defaults to true when nil
---@return table initializer
function Handle:AddExpandableSection(name, expanded)
    local initializer = CreateSettingsExpandableSectionInitializer(name)
    initializer.data.expanded = expanded ~= false

    function initializer:GetExtent()
        return 25
    end

    function initializer:IsExpanded()
        return self.data.expanded ~= false
    end

    local origInitFrame = initializer.InitFrame
    function initializer:InitFrame(frame)
        origInitFrame(self, frame)
        local function updateArrow(frameSelf, isExpanded)
            if frameSelf.Button and frameSelf.Button.Right then
                frameSelf.Button.Right:SetAtlas(
                    isExpanded and "Options_ListExpand_Right_Expanded" or "Options_ListExpand_Right",
                    TextureKitConstants.UseAtlasSize)
            end
        end
        updateArrow(frame, self:IsExpanded())
        frame.CalculateHeight = function(frameSelf)
            return frameSelf:GetElementData():GetExtent()
        end
        frame.OnExpandedChanged = function(frameSelf, _)
            updateArrow(frameSelf, frameSelf:GetElementData():IsExpanded())
            SettingsInbound.RepairDisplay()
        end
    end

    self._currentSection = initializer
    self:AddInitializer(initializer)
    return initializer
end

-- =========================================================
-- Escape hatches
-- =========================================================
--
-- There is deliberately no AddFrame helper. A subcategory's layout comes from
-- Settings.RegisterVerticalLayoutSubcategory, which returns a
-- SettingsVerticalLayoutMixin. That mixin accepts initializers only — it has no
-- AddLayoutChildren method, so a raw frame cannot be parented into the list.
-- An AddFrame that guarded on AddLayoutChildren lived here until it was removed:
-- the guard was never true, so it silently discarded every frame passed to it.
--
-- For custom UI, either wrap it in an initializer and pass that to AddInitializer,
-- or put the content in a standalone window opened from a settings button. See
-- BitForge_Openables (blacklist window) and BitForge_UPS (assignment frame).

function Handle:GetCategory()
    return self._cat
end

function Handle:GetLayout()
    return self._layout
end

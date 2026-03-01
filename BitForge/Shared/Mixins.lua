--- @type string, ns_core
local ADDON_NAME, ns = ...
local params = ns.params
local utils = ns.utils
local assets = ns.assets
local gui = ns.gui
--- @class BF_Mixins
local mixins = ns.mixins

--- =========================================================
--- Caches
--- =========================================================

local _format = string.format
local _type = type
local _error = error

local _CreateFromMixins = CreateFromMixins
local _IsEventValid = C_EventUtils.IsEventValid

--- =========================================================
--- Event Handling Mixin
--- =========================================================

local eventRegistry = _CreateFromMixins(CallbackRegistryMixin)
eventRegistry:OnLoad()

local dispatcher = CreateFrame("Frame")
dispatcher:SetScript("OnEvent", function(_, event, ...)
    eventRegistry:TriggerEvent(event, ...)
end)

--- @class BF_EventMixin
local eventMixin = {}

--- @param event string Event name
--- @param func function The function to run when the event fires
--- @param unit string? Optional unit ID to filter events
function eventMixin:Subscribe(event, func, unit)
    eventRegistry:RegisterCallback(event, func, self)

    if not _IsEventValid(event) then return end

    if unit then
        dispatcher:RegisterUnitEvent(event, unit)
    else
        dispatcher:RegisterEvent(event)
    end
end

--- @param event string Custom event name
function eventMixin:Unsubscribe(event)
    eventRegistry:UnregisterCallback(event, self)

    if not _IsEventValid(event) or eventRegistry:HasRegistrantsForEvent(event) then return end

    dispatcher:UnregisterEvent(event)
end

--- Triggers a custom BitForge event. Should not be used for WoW game events.
--- @param event string Custom event name
function eventMixin:Trigger(event, ...)
    if _IsEventValid(event) then return end

    eventRegistry:TriggerEvent(event, ...)
end

mixins.event = eventMixin

--- =========================================================
--- Base Mixin
--- =========================================================

--- @class BF_BaseMixin: BF_EventMixin
local baseMixin = _CreateFromMixins(eventMixin)
baseMixin.initialized = false
baseMixin.OnInit = nil
baseMixin.enabled = false
baseMixin.OnEnable = nil
baseMixin.OnDisable = nil

function baseMixin:Init()
    if self.initialized then return end
    if self.OnInit then self:OnInit() end

    self.initialized = true
end

function baseMixin:Enable()
    if self.enabled then return end
    if self.OnEnable then self:OnEnable() end

    self.enabled = true
end

function baseMixin:Disable()
    if not self.enabled then return end
    if self.OnDisable then self:OnDisable() end

    self.enabled = false
end

function baseMixin:IsEnabled()
    return self.enabled == true
end

--- =========================================================
--- Model Mixin
--- =========================================================

--- @class BF_BaseModel: BF_BaseMixin
local baseModelMixin = _CreateFromMixins(baseMixin)

function baseModelMixin:OnInit()
    self.db = nil
end

function baseModelMixin:GetDB()
    if not self.initialized then
        _error("Database not initialized.", 2)
    end

    return utils:ReadOnly(self.db)
end

--- Migrate character data from an old GUID to a new GUID (e.g., after a character rename)
--- @param oldGUID string The old character GUID
--- @param newGUID string The new character GUID
function baseModelMixin:MigrateCharacter(oldGUID, newGUID)
    if not self.initialized then
        _error("Database not initialized.", 2)
    end

    -- Copy tracking data from old GUID to new GUID
    local db = self.db.global.characters
    local oldData = db[oldGUID]
    if oldData then
        db[newGUID] = oldData
        db[oldGUID] = nil
    end
end

mixins.model = baseModelMixin

--- =========================================================
--- View Mixin
--- =========================================================

--- @class BF_BaseView: BF_BaseMixin
local baseViewMixin = _CreateFromMixins(baseMixin)

function baseViewMixin:Init(name)
    if self.initialized then return end

    self.printPrefix = _format("[%s]", name or ADDON_NAME)
    if self.OnInit then self:OnInit() end
    self.initialized = true
end

function baseViewMixin:Print(...)
    utils:Print(self.printPrefix, ...)
end

--- Creates a new category in the plugin's configuration UI.
--- @param name string The name of the category to create.
--- @param parent table Optional parent category name for nested categories.
function baseViewMixin:CreateCategory(name, parent)
    self.categories = self.categories or {}
    local category, layout
    if parent then
        category, layout = Settings.RegisterVerticalLayoutSubcategory(parent, name)
    else
        category, layout = Settings.RegisterVerticalLayoutCategory(name)
    end

    self.categories[name] = {
        category = category,
        layout = layout,
    }

    return category, layout
end

function baseViewMixin:CreateSectionHeader(layout, name)
    local initializer = CreateSettingsListSectionHeaderInitializer(name)
    layout:AddInitializer(initializer)
end

mixins.view = baseViewMixin

--- =========================================================
--- Control Mixin
--- =========================================================

--- @class BF_BaseControl: BF_BaseMixin
local baseControlMixin = _CreateFromMixins(baseMixin)

mixins.control = baseControlMixin

--- =========================================================
--- Plugin Factory
--- =========================================================

--- @class BF_PluginMixin
--- @field params BF_Params Read-only access to plugin parameters.
--- @field utils BF_Utils Read-only access to utility functions.
--- @field assets BF_Assets Read-only access to plugin assets.
--- @field gui BF_GUI Read-only access to plugin GUI functions.
--- @field model BF_BaseModel Base model mixin for plugin models.
--- @field view BF_BaseView Base view mixin for plugin views.
--- @field control BF_BaseControl Base control mixin for plugin controls.
local pluginMixin = {
    params = utils:ReadOnly(params),
    utils = utils:ReadOnly(utils),
    assets = utils:ReadOnly(assets),
    gui = utils:ReadOnly(gui),
    model = _CreateFromMixins(baseModelMixin),
    view = _CreateFromMixins(baseViewMixin),
    control = _CreateFromMixins(baseControlMixin),
}

mixins.plugin = pluginMixin

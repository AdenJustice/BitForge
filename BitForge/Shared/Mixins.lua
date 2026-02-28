--- @type string, ns_core
local ADDON_NAME, ns = ...
local params = ns.params
local utils = ns.utils
local assets = ns.assets
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
    self.initialized = true

    if self.OnInit then self:OnInit() end
end

function baseMixin:Enable()
    if self.enabled then return end
    self.enabled = true

    if self.OnEnable then self:OnEnable() end
end

function baseMixin:Disable()
    if not self.enabled then return end
    self.enabled = false

    if self.OnDisable then self:OnDisable() end
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

mixins.view = baseViewMixin

--- =========================================================
--- Control Mixin
--- =========================================================

--- @class BF_BaseControl: BF_BaseMixin
local baseControlMixin = _CreateFromMixins(baseMixin)

--- Initializes the control with an optional name. The name is used for logging purposes.
--- @param name string? Optional name for the plugin.
function baseControlMixin:Init(name)
    self.printPrefix = _format("[%s]", name or ADDON_NAME)

    if self.OnInit then
        self:OnInit()
    end
end

function baseControlMixin:Print(...)
    utils:Print(self.printPrefix, ...)
end

mixins.control = baseControlMixin

--- =========================================================
--- Plugin Factory
--- =========================================================

--- @class BF_PluginMixin
local pluginMixin = {
    params = utils:ReadOnly(params),
    utils = utils:ReadOnly(utils),
    assets = utils:ReadOnly(assets),
    model = _CreateFromMixins(baseModelMixin),
    view = _CreateFromMixins(baseViewMixin),
    control = _CreateFromMixins(baseControlMixin),
}

mixins.plugin = pluginMixin

--- @class ns_core
local ns = select(2, ...)
local mixins = ns.mixins

--- =========================================================
--- Caches
--- =========================================================

local _Mixin = Mixin

--- @class BF_CoreModel: BF_BaseModel
local model = CreateFromMixins(mixins.model)
ns.model = model

--- @class BF_CoreView: BF_BaseView
local view = CreateFromMixins(mixins.view)
ns.view = view

--- @class BF_CoreControl: BF_BaseControl
local control = CreateFromMixins(mixins.control)
ns.control = control

--- Factory function to create a plugin from mixins.
--- @param name string The name of the plugin.
--- @param namespace table The plugin's namespace table.
--- @return BF_PluginNS A new plugin namespace with the appropriate mixins.
function ns.RegisterPlugin(name, namespace)
    --- @class BF_PluginNS: BF_PluginMixin
    return _Mixin(namespace, mixins.plugin)
end

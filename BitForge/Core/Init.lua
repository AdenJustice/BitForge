--- @class ns.Core
local ns = select(2, ...)
local mixins = ns.mixins

--- =========================================================
--- Caches
--- =========================================================

local _Mixin = Mixin

--- @class BF_CoreModel: BitForge.Models.Base
local model = CreateFromMixins(mixins.model)
ns.model = model

--- @class BF_CoreView: BitForge.Views.Base
local view = CreateFromMixins(mixins.view)
ns.view = view

--- @class BF_CoreControl: BitForge.Controls.Base
local control = CreateFromMixins(mixins.control)
ns.control = control

--- Factory function to create a plugin from mixins.
--- @param name string The name of the plugin.
--- @param namespace table The plugin's namespace table.
--- @return BitForge.Plugins.ns A new plugin namespace with the appropriate mixins.
function ns.RegisterPlugin(name, namespace)
    --- @class BitForge.Plugins.ns: BitForge.Mixins.Plugins.Base
    return _Mixin(namespace, mixins.plugin)
end

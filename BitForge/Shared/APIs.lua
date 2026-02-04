--- @class ns_core
local ns = select(2, ...)
--- @class BitForgeAPI
local api = BitForgeAPI

--- =========================================================
--- Caches
--- =========================================================

local _type = type
local _error = error

--- =========================================================
--- APIs
--- =========================================================

--- Factory function to create a plugin from mixins.
--- @param name string The name of the plugin.
--- @param namespace table The plugin's namespace table.
--- @return BF_PluginNS A new plugin namespace with the appropriate mixins.
function api.RegisterPlugin(name, namespace)
    if not name or _type(name) ~= "string" then
        _error("Plugin name must be a string.", 2)
    end
    if not namespace or _type(namespace) ~= "table" then
        _error("Plugin namespace must be a table.", 2)
    end

    return ns.RegisterPlugin(name, namespace)
end

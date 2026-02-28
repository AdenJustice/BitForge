---@type ns_core
local ns = select(2, ...)
local params = ns.params
---@class BF_Assets
local assets = ns.assets

--- =========================================================
--- Caches
--- =========================================================

local _format = string.format
local _lower = string.lower

--- =========================================================
--- Helpers
--- =========================================================

local getAssetPath = function(assetType)
    return _format("%s/Assets/%s", params.core.path, assetType)
end

--- =========================================================
--- Assets
--- =========================================================

--- Gets the file path for a class icon asset.
--- @param class string The class name (e.g. "WARRIOR", "MAGE")
--- @return string iconPath The file path to the class icon asset
function assets:GetClassIcon(class)
    return _format("%s/%s.png", getAssetPath("Class"), _lower(class))
end

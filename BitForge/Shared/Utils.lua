---@type string, ns.Core
local ADDON_NAME, ns = ...
local params = ns.params
---@class BitForge.Utils
local utils = ns.utils

--- =========================================================
--- Caches
--- =========================================================

local _type = type
local _format = string.format
local _pcall = pcall
local _print = print
local _tostring = tostring
local _setmetatable = setmetatable
local _error = error
local _concat = table.concat

--- =========================================================
--- Utilities
--- =========================================================

--- Prints a message to the chat with the addon name as a prefix.
--- @param ... any - The message parts to print.
function utils:Print(...)
    local args = { ... }
    for i = 1, #args do
        args[i] = _tostring(args[i])
    end
    local message = _concat((args), " ", 2)
    _print(_format("%s[%s]|r", params.colors.primaryColor:GenerateHexColorMarkup(), args[1]), message)
end

--- Wraps a callback function in a protected call and prints any errors to the chat.
--- @param cb any The callback function to wrap.
--- @param errorContext any Optional context to include in the error message.
--- @return function callback The wrapped callback function.
function utils:SafeCallback(cb, errorContext)
    return function(...)
        local success, err = _pcall(cb, ...)
        if not success then
            self:Print("Error in " .. (errorContext or "callback") .. ": " .. _tostring(err))
        end
    end
end

--- Creates a read-only version of a table. Any attempt to modify the table will result in an error.
--- @param tbl table The table to make read-only.
--- @return table readOnlyTbl The read-only version of the table.
function utils:ReadOnly(tbl)
    return _setmetatable({}, {
        __index = function(_, key)
            local val = tbl[key]
            return _type(val) == "table" and utils:ReadOnly(val) or val
        end,
        __newindex = function(t, key, value)
            _error("Attempt to modify read-only table", 2)
        end,
        __metatable = false,
    })
end

--- Inverts a table by swapping its keys and values.
--- @param tbl table<string|number, string> The table to invert. All values must be strings.
--- @return table<string, number|string> inverted The inverted table with keys and values swapped.
function utils:InvertTable(tbl)
    local inverted = {}
    for key, value in pairs(tbl) do
        if _type(value) ~= "string" then
            _error("Value must be a string to be used as a key in the inverted table", 2)
        end
        inverted[value] = key
    end
    return inverted
end

--- Converts a camelCase string to PascalCase.
--- @param str string The camelCase string to convert.
--- @return string pascalCase The converted PascalCase string.
function utils:camelCaseToPascalCase(str)
    local converted = str:gsub("(%a)(%a*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return converted
end

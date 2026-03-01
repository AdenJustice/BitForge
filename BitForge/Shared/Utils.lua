---@type string, ns_core
local ADDON_NAME, ns = ...
local params = ns.params
---@class BF_Utils
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
    local args = {...}
    for i = 1, #args do
        args[i] = _tostring(args[i])
    end
    local message = _concat(args, " ")
    _print(_format("%s[%s]|r", params.colors.primaryColor:GenerateHexColorMarkup(), ADDON_NAME), message)
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

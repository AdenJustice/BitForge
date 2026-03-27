local ADDON_NAME, ns = ...

local Output = {}
ns.Output = Output

local PREFIX = "|cff00ccff[BitForge]|r "

function Output:Print(...)
    print(PREFIX, ...)
end

function Output:Debug(...)
    print("|cff888888[BitForge:Debug]|r", ...)
end

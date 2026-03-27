local ADDON_NAME, ns = ...

function BitForge:Print(...)
    ns.Output:Print(...)
end

function BitForge:Debug(...)
    if ns.DB.Get("debug") then
        ns.Output:Debug(...)
    end
end

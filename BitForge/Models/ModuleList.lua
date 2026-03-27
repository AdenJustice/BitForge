local _, ns      = ...

local ModuleList = {}
ns.ModuleList    = ModuleList

local list = {}

---@return { name: string, title: string, enabled: boolean, loaded: boolean }[]
function ModuleList.GetAll()
    return list
end

---@param modules { name: string, title: string, enabled: boolean, loaded: boolean }[]
function ModuleList.SetAll(modules)
    list = modules
end

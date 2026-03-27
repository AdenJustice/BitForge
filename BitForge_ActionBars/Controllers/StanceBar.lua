local ns = select(2, ...)

local _G = _G
local BINDING_PREFIX = ns.BINDING_PREFIX

function ns.SetupStanceBar(frame, def)
    local key     = def.key
    local buttons = {}

    for i = 1, def.count do
        local btn = _G["StanceButton" .. i]
        if btn then
            btn:SetAttributeNoHandler("statehidden", nil)
            ns.ReRegisterStanceEvents(btn)
            btn:SetParent(frame)
            btn.commandName = (BINDING_PREFIX[key] or "") .. i
            buttons[i] = btn
        end
    end

    return buttons
end

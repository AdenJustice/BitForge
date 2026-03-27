local ns = select(2, ...)

local _G = _G
local InCombatLockdown = InCombatLockdown
local GetCursorInfo = GetCursorInfo
local PickupPetAction = PickupPetAction

local BINDING_PREFIX = ns.BINDING_PREFIX

function ns.SetupPetBar(frame, def)
    local key     = def.key
    local buttons = {}

    for i = 1, def.count do
        local btn = _G["PetActionButton" .. i]
        if btn then
            btn:SetAttributeNoHandler("statehidden", nil)
            ns.ReRegisterPetEvents(btn)
            btn:SetParent(frame)
            btn:SetID(i)
            btn.commandName = (BINDING_PREFIX[key] or "") .. i
            btn:HookScript("OnReceiveDrag", function(self)
                if InCombatLockdown() then return end
                local cType = GetCursorInfo()
                if cType == "petaction" then PickupPetAction(self:GetID()) end
            end)
            buttons[i] = btn
        end
    end

    return buttons
end

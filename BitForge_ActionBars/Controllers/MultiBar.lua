local ns = select(2, ...)

local _G = _G

function ns.SetupMultiBar(frame, def)
    local key        = def.key
    local allButtons = ns._allButtons
    local slotOffset = def.slotOffset or 0
    local buttons    = {}

    for i = 1, def.count do
        local slot = slotOffset + i
        local btn  = allButtons[slot]
            or (def.blizzBtnPrefix and _G[def.blizzBtnPrefix .. i])

        if btn then
            btn:SetAttributeNoHandler("statehidden", nil)
            ns.ReRegisterActionEvents(btn)
            btn:SetParent(frame)
            btn:SetID(0)
            btn:SetAttribute("action", slot)
            btn:SetAttribute("showgrid", 1)

            ns.DisableButtonMouseInput(btn)
            ns.ApplyButtonBinding(btn, key, i)

            if ActionBarActionEventsFrame then
                ActionBarActionEventsFrame:RegisterFrame(btn)
            end

            ns.RegisterButtonWithController(btn)
            allButtons[slot] = btn
            buttons[i] = btn
        end
    end

    return buttons
end

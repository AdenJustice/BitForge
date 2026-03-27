local ns = select(2, ...)

local _G = _G
local CreateFrame = CreateFrame

function ns.SetupMainBar(frame, def)
    local key        = def.key
    local allButtons = ns._allButtons
    local buttons    = {}

    for i = 1, def.count do
        local slot = i
        local name = "BitForge_ABMainBtn" .. i
        local btn  = allButtons[slot] or _G[name]

        if not btn then
            btn = CreateFrame("CheckButton", name, frame, "ActionBarButtonTemplate")
            btn:SetAttributeNoHandler("action", 0)
            btn:SetAttributeNoHandler("showgrid", 0)
            btn:SetAttributeNoHandler("useparent-checkfocuscast", true)
            btn:SetAttributeNoHandler("useparent-checkmouseovercast", true)
            btn:SetAttributeNoHandler("useparent-checkselfcast", true)
            ns.DisableButtonMouseInput(btn)
            allButtons[slot] = btn
        end

        ns.RegisterButtonWithController(btn)
        btn:SetParent(frame)
        btn:SetAttribute("index", i)
        btn:SetAttribute("_childupdate-offset", [[
            local offset = message or 0
            local id = self:GetAttribute("index") + offset
            if self:GetAttribute("action") ~= id then
                self:SetAttribute("action", id)
            end
        ]])
        local curOffset = frame:GetAttribute("actionOffset") or 0
        btn:SetAttribute("action", i + curOffset)
        btn:SetAttribute("showgrid", 1)

        if ActionBarActionEventsFrame then
            ActionBarActionEventsFrame:RegisterFrame(btn)
        end

        ns.ApplyButtonBinding(btn, key, i)
        if btn.UpdateAction then btn:UpdateAction() end

        buttons[i] = btn
    end

    return buttons
end

local ADDON_NAME, ns = ...
local E = BitForge.Events
local bus = ns.eventBus

function ns:Subscribe(event, fn)
    bus:RegisterCallback(event, fn, self)
end

function ns:Unsubscribe(event)
    bus:UnregisterCallback(event, self)
end

EventUtil.ContinueOnAddOnLoaded(ADDON_NAME, function()
    ns.playerName = UnitName("player")
    ns.DB.Init()
    bus:TriggerEvent(E.CORE_LOADED)
end)

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
    BitForge:RegisterCharacter()
    bus:TriggerEvent(E.PLAYER_READY)
end)

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGOUT", function()
    bus:TriggerEvent(E.PLAYER_LEAVING)
end)

EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_OPENED", function()
    bus:TriggerEvent(E.BANK_OPENED)
end)

EventRegistry:RegisterFrameEventAndCallback("BANKFRAME_CLOSED", function()
    bus:TriggerEvent(E.BANK_CLOSED)
end)

EventRegistry:RegisterFrameEventAndCallback("SKILL_LINES_CHANGED", function()
    bus:TriggerEvent(E.SKILL_LINES_CHANGED)
end)

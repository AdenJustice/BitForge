---@type string
local ADDON_NAME = ...

-- BitForge.UI is the library, not a copy of it. Every call site in core and in
-- the modules -- UI.CreateFrame, UI.Colors, UI.Skin.StripFrameTextures -- keeps
-- working unchanged, which is what makes the extraction a move rather than a
-- rewrite.
BitForge.UI = LibStub:GetLibrary("LibBitForgeUI-1.0")

local bridge = BitForge.UI.NewSkinBridge()
BitForge.UI.Skin.GetExternalSkin = bridge.GetSkin
BitForge.UI.Skin.OnExternalSkin  = bridge.OnSkin

-- Core registers under its own folder name, and each module under its own, so
-- EllesmereUI's per-addon toggle is per addon rather than one switch for the
-- suite. Registering is free when the host is absent or its skinning is off.
if EllesmereUI and EllesmereUI.RegisterSkin then
    EllesmereUI.RegisterSkin(ADDON_NAME, bridge.Deliver)
end

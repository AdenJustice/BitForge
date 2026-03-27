local ADDON_NAME, ns = ...

BitForge = {}
BitForge.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

-- EventBus: modules register their listeners here
BitForge.EventBus = CreateFromMixins(CallbackRegistryMixin)
BitForge.EventBus:OnLoad()
BitForge.EventBus:SetUndefinedEventsAllowed(true)

ns.eventBus = BitForge.EventBus

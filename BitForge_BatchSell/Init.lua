--- @class ns.BatchSell: BitForge.Plugins.ns
local ns = BitForgeAPI.RegisterPlugin(...)

--- @class BitForge.Locales.BatchSell
local locale = {}
ns.locale = locale

ns.enforcedRuleKeys = {
    "locked",
    "inEquipmentSet",
    "noVendorPrice",
    "stillRefundable",
    "enlisted"
}
ns.protectedRulesEnum = EnumUtil.MakeEnum(ns.enforcedRuleKeys)

ns.optionalRuleKeys = {
    -- exclude higher quailtiy? and include grey items? since potential conflicts with other addons
    "higherQuality",
    -- excludes items that can be equipped by the player's class?
    "equippable",
    -- excludes items that can be disenchanted when his/her profession is enchanting?
    "toDisenchant",
    -- excludes items from current expansion?
    "expansion",
    -- excludes items that doesn't have that lower item level compared to one in the same slot?
    "lowerItemLevel"
}
ns.optionalRulesEnum = EnumUtil.MakeEnum(ns.optionalRuleKeys)

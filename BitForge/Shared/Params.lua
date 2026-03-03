--- @type string, ns.Core
local ADDON_NAME, ns = ...
--- @class BitForge.Params
local params = ns.params

--- =========================================================
--- Caches
--- =========================================================

local _select = select

local _CreateColor = CreateColor
local _GetAddOnMetadata = C_AddOns.GetAddOnMetadata
local _GetBuildInfo = GetBuildInfo
local _GetRealmName = GetRealmName
local _UnitClass = UnitClass
local _UnitFactionGroup = UnitFactionGroup
local _UnitGUID = UnitGUID
local _UnitLevel = UnitLevel
local _GetMaxLevelForLatestExpansion = GetMaxLevelForLatestExpansion
local _UnitName = UnitName
local _UnitRace = UnitRace

--- =========================================================
--- Parameters
--- =========================================================

local wowBuildInfo = { _GetBuildInfo() }

params.wow = {
    buildVersion = wowBuildInfo[1],
    buildNumber = wowBuildInfo[2],
    buildDate = wowBuildInfo[3],
    interfaceVersion = wowBuildInfo[4],
    localizedVersion = wowBuildInfo[5],
    buildInfo = wowBuildInfo[6],
}

params.core = {
    name = ADDON_NAME,
    version = _GetAddOnMetadata(ADDON_NAME, "Version"),
    dbName = ADDON_NAME .. "DB",
    path = "Interface/AddOns/" .. ADDON_NAME,
}

params.character = {
    name = _UnitName("player"),
    realm = _GetRealmName(),
    faction = _UnitFactionGroup("player"),
    class = _select(2, _UnitClass("player")),
    race = _select(2, _UnitRace("player")),
    level = _UnitLevel("player"),
    guid = _UnitGUID("player") --[[@as string]],
}

params.colors = {
    primaryColor = _CreateColor(0, 1, 0.592, 1),
    secondaryColor = _CreateColor(1, 0, 0.918, 1),
    backdrop = _CreateColor(.1, .1, .1, .75),
    border = _CreateColor(0, 0, 0, .75),
}

--- Updates the character's faction and returns whether it's a valid faction (not Neutral).
--- @return boolean isValidFaction
function params:UpdateCharFaction()
    local faction = _UnitFactionGroup("player")
    self.character.faction = faction

    return faction and faction ~= "Neutral" or false
end

--- Updates the character's level and returns whether it's the max level for the latest expansion.
--- @return boolean isMaxLevel
function params:UpdateCharLevel()
    local level = _UnitLevel("player")
    self.character.level = level

    return level == _GetMaxLevelForLatestExpansion()
end

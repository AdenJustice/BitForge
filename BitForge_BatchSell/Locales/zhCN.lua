if GetLocale() ~= "zhCN" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "批量出售"
L["panel:sellManifest"] = "出售清单"
L["panel:blacklist"] = "黑名单"
L["panel:whitelist"] = "白名单"

-- Buttons
L["btn:sellAll"] = "全部出售"
L["btn:refresh"] = "刷新"

-- Context menu
L["menu:addToBlacklist"] = "添加到黑名单"
L["menu:addToWhitelist"] = "添加到白名单"
L["menu:addToBlacklistChar"] = "添加到黑名单（角色）"
L["menu:addToWhitelistChar"] = "添加到白名单（角色）"
L["menu:clearCharOverride"] = "清除角色覆盖设置"
L["menu:resetListEntry"] = "从名单中移除"
L["menu:temporaryExclude"] = "暂时排除"

-- Status
L["status:noItemsToSell"] = "没有可出售的物品"
L["status:itemsTotal"] = "%d 件物品  |  合计：%s"

-- Merchant row
L["tooltip:charOverride"] = "此角色的设置优先于战团名单——该物品将被出售。"

-- Settings
L["settings:sellJunk"] = "出售垃圾"
L["settings:sellJunkTooltip"] = "访问商人时自动出售所有低品质（灰色）物品"
L["settings:keepEquippable"] = "保留可装备物品"
L["settings:keepEquippableTooltip"] = "保留所有适合你职业的可装备物品"
L["settings:keepBindOnAccount"] = "保留绑定账号物品"
L["settings:keepBindOnAccountTooltip"] = "保留绑定账号（传家宝）装备"
L["settings:keepBindOnAccountPastExpac"] = "  包括历史资料片"
L["settings:keepBindOnAccountPastExpacTooltip"] = "同时保留历史资料片中绑定账号的装备"
L["settings:keepDisenchantables"] = "保留可分解物品"
L["settings:keepDisenchantablesTooltip"] = "附魔师：保留BOP/BOE/BOA装备。其他：保留BOE/BOA用于拍卖行或小号"
L["settings:keepDisenchantablesPastExpac"] = "  包括历史资料片"
L["settings:keepDisenchantablesPastExpacTooltip"] = "同时保留历史资料片中可分解的装备"
L["settings:limitBatch"] = "每批限制12件"
L["settings:limitBatchTooltip"] = "每次点击最多出售12件物品以避免服务器限速"
L["settings:qualityThreshold"] = "品质阈值"
L["settings:qualityThresholdTooltip"] = "出售此品质及以下的物品"
L["settings:ilvlThreshold"] = "物品等级余量"
L["settings:ilvlThresholdTooltip"] =
"保留装备等级在已装备物品范围内的可装备物品（负值 = 保留更好的物品）"
L["settings:sellPastExpansion"] = "出售历史资料片物品"
L["settings:sellPastExpansionTooltip"] = "出售早于所选阈值资料片的物品"
L["settings:expansionThreshold"] = "资料片阈值"
L["settings:expansionThresholdTooltip"] = "出售早于所选资料片的物品"

-- Quality labels
L["quality:poor"] = "差"
L["quality:common"] = "普通"
L["quality:uncommon"] = "优秀"
L["quality:rare"] = "精良"
L["quality:epic"] = "史诗"

-- Expansion labels
L["expansion:all"] = "所有资料片"
L["expansion:classic"] = "经典旧世"
L["expansion:burningCrusade"] = "燃烧的远征"
L["expansion:wrathOfTheLichKing"] = "巫妖王之怒"
L["expansion:cataclysm"] = "大地的裂变"
L["expansion:mistsOfPandaria"] = "熊猫人之谜"
L["expansion:warlordsOfDraenor"] = "德拉诺之王"
L["expansion:legion"] = "军团再临"
L["expansion:battleForAzeroth"] = "争霸艾泽拉斯"
L["expansion:shadowlands"] = "暗影国度"
L["expansion:dragonflight"] = "巨龙崛起"
L["expansion:theWarWithin"] = "地心之战"

-- List reset buttons
L["listReset:warbandBlacklist"] = "重置战团黑名单"
L["listReset:warbandWhitelist"] = "重置战团白名单"
L["listReset:charBlacklist"] = "重置角色黑名单"
L["listReset:charWhitelist"] = "重置角色白名单"
L["listReset:confirm"] = "确定要清空此名单吗？此操作无法撤销。"

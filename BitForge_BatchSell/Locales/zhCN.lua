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

-- Section titles
L["section:general"] = "常规"
L["section:equipment"] = "装备"
L["section:materials"] = "制作材料"
L["section:other"] = "消耗品与其他"
L["section:lists"] = "名单"

-- Settings
L["settings:sellJunk"] = "出售垃圾"
L["settings:sellJunkTooltip"] = "访问商人时自动出售所有低品质（灰色）物品"
L["settings:limitBatch"] = "每批限制12件"
L["settings:limitBatchTooltip"] = "每次点击最多出售12件物品以避免服务器限速"
L["settings:sellEquipment"] = "出售装备"
L["settings:sellEquipmentTooltip"] = "允许出售护甲和武器。关闭后装备永远不会被出售"
L["settings:ilvlThreshold"] = "物品等级余量"
L["settings:ilvlThresholdTooltip"] = "物品比该部位已装备的物品低多少等级以内仍会保留"
L["settings:marginOnHigherQuality"] = "  对更高品质应用余量"
L["settings:marginOnHigherQualityTooltip"] = "对品质高于已装备装备的装备应用余量。关闭时，任何品质提升的装备无论等级都会保留"
L["settings:marginOnSameQuality"] = "  对相同品质应用余量"
L["settings:marginOnSameQualityTooltip"] = "对品质与已装备装备相同的装备应用余量。关闭时，仅保留等级等于或高于已装备等级的装备"
L["settings:marginOnLowerQuality"] = "  对更低品质应用余量"
L["settings:marginOnLowerQualityTooltip"] = "对品质低于已装备装备的装备应用余量。关闭时，任何品质降低的装备无论等级都会被出售。品质低两级或以上的装备永远不会获得余量"
L["settings:keepBindOnAccount"] = "保留绑定账号物品"
L["settings:keepBindOnAccountTooltip"] = "保留绑定账号（传家宝）装备"
L["settings:keepBindOnAccountPastExpac"] = "  包括历史资料片"
L["settings:keepBindOnAccountPastExpacTooltip"] = "同时保留历史资料片中绑定账号的装备"
L["settings:keepDisenchantables"] = "保留可分解物品"
L["settings:keepDisenchantablesTooltip"] = "附魔师：保留BOP/BOE/BOA装备。其他：保留BOE/BOA用于拍卖行或小号"
L["settings:keepDisenchantablesPastExpac"] = "  包括历史资料片"
L["settings:keepDisenchantablesPastExpacTooltip"] = "同时保留历史资料片中可分解的装备"
L["settings:keepUsedReagents"] = "保留专业所需材料"
L["settings:keepUsedReagentsTooltip"] = "保留此账号任一专业可使用的制作材料"
L["settings:materialsMode"] = "制作材料"
L["settings:materialsModeTooltip"] = "决定如何处理材料、贸易物品、宝石、附魔和配方"
L["settings:materialsExpansion"] = "  从该资料片起保留"
L["settings:materialsExpansionTooltip"] = "保留从该资料片起的材料，出售更早的材料。仅在制作材料设置为从所选资料片起保留时生效"
L["settings:otherMode"] = "消耗品与其他"
L["settings:otherModeTooltip"] = "决定如何处理消耗品、容器、战斗宠物、专业装备和家宅装饰"

-- Sell modes
L["mode:keepAll"] = "全部保留"
L["mode:keepCurrent"] = "保留当前资料片"
L["mode:keepFrom"] = "从该资料片起保留"
L["mode:sellAll"] = "全部出售"

-- List tabs
L["btn:removeEntry"] = "移除"
L["list:warband"] = "战团"
L["list:character"] = "角色"
L["status:listEmpty"] = "此名单为空"
L["status:listCount"] = "%d 条目"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "批量出售：将被出售"
L["verdict:keep"] = "批量出售：将被保留"
L["reason:TEMP_EXCLUDED"] = "本次商人访问中已排除"
L["reason:BLACKLISTED"] = "在你的黑名单中"
L["reason:LOCKED"] = "该物品已锁定"
L["reason:EQUIPMENT_SET"] = "属于套装的一部分"
L["reason:NO_SELL_PRICE"] = "没有商人会购买它"
L["reason:REFUNDABLE"] = "仍在退款期限内"
L["reason:WHITELISTED"] = "在你的白名单中"
L["reason:TEMP_INCLUDED"] = "本次商人访问中已加入"
L["reason:CATEGORY"] = "此类物品被设置为保留"
L["reason:CURRENT_EXPANSION"] = "来自你正在保留的资料片"
L["reason:BIND_ON_ACCOUNT"] = "绑定账号的装备会被保留"
L["reason:DISENCHANTABLE"] = "值得保留以便分解或转售"
L["reason:REAGENT_WANTED"] = "此账号的专业需要该材料"
L["reason:EQUIPPABLE"] = "相对于已装备的装备而言足够好"
L["reason:OUTCLASSED"] = "不如已装备的装备"
L["reason:SELL_MODE"] = "此类物品被设置为出售"
L["reason:DEFAULT"] = "没有规则认领它，因此予以保留"

-- Expansion labels
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
L["expansion:midnight"] = "至暗之夜"

-- List reset buttons
L["listReset:warbandBlacklist"] = "重置战团黑名单"
L["listReset:warbandWhitelist"] = "重置战团白名单"
L["listReset:charBlacklist"] = "重置角色黑名单"
L["listReset:charWhitelist"] = "重置角色白名单"
L["listReset:confirm"] = "确定要清空此名单吗？此操作无法撤销。"

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "目前无法出售%s：%s"
L["msg:dropUnexcluded"] = "%s不再被排除，将于本次访问中出售"

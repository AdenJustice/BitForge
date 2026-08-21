if GetLocale() ~= "zhTW" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "批次出售"
L["panel:sellManifest"] = "出售清單"
L["panel:blacklist"] = "黑名單"
L["panel:whitelist"] = "白名單"

-- Buttons
L["btn:sellAll"] = "全部出售"
L["btn:refresh"] = "重新整理"

-- Context menu
L["menu:addToBlacklist"] = "加入黑名單"
L["menu:addToWhitelist"] = "加入白名單"
L["menu:addToBlacklistChar"] = "加入黑名單（角色）"
L["menu:addToWhitelistChar"] = "加入白名單（角色）"
L["menu:clearCharOverride"] = "清除角色覆寫設定"
L["menu:resetListEntry"] = "從清單移除"
L["menu:temporaryExclude"] = "暫時排除"

-- Status
L["status:noItemsToSell"] = "沒有可出售的物品"
L["status:itemsTotal"] = "%d 件物品  |  合計：%s"

-- Merchant row
L["tooltip:charOverride"] = "此角色的設定優先於戰團清單——此物品將被出售。"

-- Section titles
L["section:general"] = "一般"
L["section:equipment"] = "裝備"
L["section:materials"] = "製作材料"
L["section:other"] = "消耗品與其他"
L["section:lists"] = "清單"

-- Settings
L["settings:sellJunk"] = "出售垃圾物品"
L["settings:sellJunkTooltip"] = "拜訪商人時自動出售所有低品質（灰色）物品"
L["settings:limitBatch"] = "每批限制12件"
L["settings:limitBatchTooltip"] = "每次點擊最多出售12件物品以避免伺服器速率限制"
L["settings:sellEquipment"] = "出售裝備"
L["settings:sellEquipmentTooltip"] = "允許出售護甲和武器。關閉時裝備永遠不會被出售"
L["settings:ilvlThreshold"] = "物品等級邊際"
L["settings:ilvlThresholdTooltip"] = "物品比該部位已裝備的物品低多少等級以內仍會保留"
L["settings:marginOnHigherQuality"] = "  對更高品質套用邊際"
L["settings:marginOnHigherQualityTooltip"] = "對品質高於已裝備裝備的裝備套用邊際。關閉時，任何品質提升的裝備無論等級都會保留"
L["settings:marginOnSameQuality"] = "  對相同品質套用邊際"
L["settings:marginOnSameQualityTooltip"] = "對品質與已裝備裝備相同的裝備套用邊際。關閉時，僅保留等級等於或高於已裝備等級的裝備"
L["settings:marginOnLowerQuality"] = "  對更低品質套用邊際"
L["settings:marginOnLowerQualityTooltip"] = "對品質低於已裝備裝備的裝備套用邊際。關閉時，任何品質降低的裝備無論等級都會被出售。品質低兩級以上的裝備永遠不會獲得邊際"
L["settings:keepBindOnAccount"] = "保留帳號綁定物品"
L["settings:keepBindOnAccountTooltip"] = "保留帳號綁定（傳家寶）裝備"
L["settings:keepBindOnAccountPastExpac"] = "  包含過去資料片"
L["settings:keepBindOnAccountPastExpacTooltip"] = "同時保留過去資料片中帳號綁定的裝備"
L["settings:keepDisenchantables"] = "保留可分解物品"
L["settings:keepDisenchantablesTooltip"] = "附魔師：保留BOP/BOE/BOA裝備。其他人：保留BOE/BOA用於拍賣場或小號"
L["settings:keepDisenchantablesPastExpac"] = "  包含過去資料片"
L["settings:keepDisenchantablesPastExpacTooltip"] = "同時保留過去資料片中可分解的裝備"
L["settings:materialsMode"] = "製作材料"
L["settings:materialsModeTooltip"] = "決定如何處理材料、貿易物品、寶石、附魔和配方"
L["settings:materialsExpansion"] = "  從該資料片起保留"
L["settings:materialsExpansionTooltip"] = "保留從該資料片起的材料，出售更早的材料。僅在製作材料設定為從所選資料片起保留時生效"
L["settings:otherMode"] = "消耗品與其他"
L["settings:otherModeTooltip"] = "決定如何處理消耗品、容器、戰鬥寵物、專業裝備和家宅裝飾"

-- Sell modes
L["mode:keepAll"] = "全部保留"
L["mode:keepCurrent"] = "保留目前資料片"
L["mode:keepFrom"] = "從該資料片起保留"
L["mode:sellAll"] = "全部出售"

-- List tabs
L["btn:removeEntry"] = "移除"
L["list:warband"] = "戰團"
L["list:character"] = "角色"
L["status:listEmpty"] = "此清單為空"
L["status:listCount"] = "%d 個項目"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "批次出售：將被出售"
L["verdict:keep"] = "批次出售：將被保留"
L["reason:TEMP_EXCLUDED"] = "本次商人拜訪中已排除"
L["reason:BLACKLISTED"] = "在你的黑名單中"
L["reason:LOCKED"] = "此物品已鎖定"
L["reason:EQUIPMENT_SET"] = "屬於套裝的一部分"
L["reason:NO_SELL_PRICE"] = "沒有商人會購買它"
L["reason:REFUNDABLE"] = "仍在退款期限內"
L["reason:WHITELISTED"] = "在你的白名單中"
L["reason:TEMP_INCLUDED"] = "本次商人拜訪中已加入"
L["reason:CATEGORY"] = "此類物品被設定為保留"
L["reason:CURRENT_EXPANSION"] = "來自你正在保留的資料片"
L["reason:BIND_ON_ACCOUNT"] = "帳號綁定的裝備會被保留"
L["reason:DISENCHANTABLE"] = "值得保留以便分解或轉售"
L["reason:EQUIPPABLE"] = "相對於已裝備的裝備而言足夠好"
L["reason:OUTCLASSED"] = "不如已裝備的裝備"
L["reason:SELL_MODE"] = "此類物品被設定為出售"
L["reason:DEFAULT"] = "沒有規則認領它，因此予以保留"

-- Expansion labels
L["expansion:classic"] = "經典舊世"
L["expansion:burningCrusade"] = "燃燒的遠征"
L["expansion:wrathOfTheLichKing"] = "巫妖王之怒"
L["expansion:cataclysm"] = "大地的裂變"
L["expansion:mistsOfPandaria"] = "潘達利亞之謎"
L["expansion:warlordsOfDraenor"] = "德拉諾之王"
L["expansion:legion"] = "軍臨天下"
L["expansion:battleForAzeroth"] = "決戰艾澤拉斯"
L["expansion:shadowlands"] = "暗影國度"
L["expansion:dragonflight"] = "巨龍崛起"
L["expansion:theWarWithin"] = "地心之戰"
L["expansion:midnight"] = "至暗之夜"

-- List reset buttons
L["listReset:warbandBlacklist"] = "重置戰團黑名單"
L["listReset:warbandWhitelist"] = "重置戰團白名單"
L["listReset:charBlacklist"] = "重置角色黑名單"
L["listReset:charWhitelist"] = "重置角色白名單"
L["listReset:confirm"] = "確定要清空此清單嗎？此操作無法撤銷。"

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "目前無法出售%s：%s"
L["msg:dropUnexcluded"] = "%s不再被排除，將於本次拜訪中出售"

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

-- Settings
L["settings:sellJunk"] = "出售垃圾物品"
L["settings:sellJunkTooltip"] = "拜訪商人時自動出售所有低品質（灰色）物品"
L["settings:keepEquippable"] = "保留可裝備物品"
L["settings:keepEquippableTooltip"] = "保留所有適合你職業的可裝備物品"
L["settings:keepBindOnAccount"] = "保留帳號綁定物品"
L["settings:keepBindOnAccountTooltip"] = "保留帳號綁定（傳家寶）裝備"
L["settings:keepBindOnAccountPastExpac"] = "  包含過去資料片"
L["settings:keepBindOnAccountPastExpacTooltip"] = "同時保留過去資料片中帳號綁定的裝備"
L["settings:keepDisenchantables"] = "保留可分解物品"
L["settings:keepDisenchantablesTooltip"] = "附魔師：保留BOP/BOE/BOA裝備。其他人：保留BOE/BOA用於拍賣場或小號"
L["settings:keepDisenchantablesPastExpac"] = "  包含過去資料片"
L["settings:keepDisenchantablesPastExpacTooltip"] = "同時保留過去資料片中可分解的裝備"
L["settings:limitBatch"] = "每批限制12件"
L["settings:limitBatchTooltip"] = "每次點擊最多出售12件物品以避免伺服器速率限制"
L["settings:qualityThreshold"] = "品質門檻"
L["settings:qualityThresholdTooltip"] = "出售此品質及以下的物品"
L["settings:ilvlThreshold"] = "物品等級邊際"
L["settings:ilvlThresholdTooltip"] =
"保留裝備等級在已裝備物品範圍內的可裝備物品（負值 = 保留更好的物品）"
L["settings:sellPastExpansion"] = "出售過去資料片物品"
L["settings:sellPastExpansionTooltip"] = "出售早於所選門檻資料片的物品"
L["settings:expansionThreshold"] = "資料片門檻"
L["settings:expansionThresholdTooltip"] = "出售早於所選資料片的物品"

-- Quality labels
L["quality:poor"] = "差"
L["quality:common"] = "普通"
L["quality:uncommon"] = "優秀"
L["quality:rare"] = "精良"
L["quality:epic"] = "史詩"

-- Expansion labels
L["expansion:all"] = "所有資料片"
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

-- List reset buttons
L["listReset:warbandBlacklist"] = "重置戰團黑名單"
L["listReset:warbandWhitelist"] = "重置戰團白名單"
L["listReset:charBlacklist"] = "重置角色黑名單"
L["listReset:charWhitelist"] = "重置角色白名單"
L["listReset:confirm"] = "確定要清空此清單嗎？此操作無法撤銷。"

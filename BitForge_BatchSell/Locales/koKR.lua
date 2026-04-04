if GetLocale() ~= "koKR" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

-- Panel
L["panel:batchSell"] = "일괄 판매"
L["panel:sellManifest"] = "판매 목록"
L["panel:blacklist"] = "보호 목록"
L["panel:whitelist"] = "판매 목록"

-- Buttons
L["btn:sellAll"] = "모두 판매"
L["btn:refresh"] = "새로 고침"

-- Context menu
L["menu:addToBlacklist"] = "보호 목록에 추가 (전투부대)"
L["menu:addToWhitelist"] = "판매 목록에 추가 (전투부대)"
L["menu:addToBlacklistChar"] = "보호 목록에 추가 (캐릭터)"
L["menu:addToWhitelistChar"] = "판매 목록에 추가 (캐릭터)"
L["menu:clearCharOverride"] = "캐릭터 우선 설정 해제"
L["menu:resetListEntry"] = "목록에서 제거"
L["menu:temporaryExclude"] = "이번에만 제외"

-- Status
L["status:noItemsToSell"] = "판매할 아이템이 없습니다"
L["status:itemsTotal"] = "%d개 아이템  |  합계: %s"

-- Merchant row
L["tooltip:charOverride"] = "이 캐릭터의 설정이 전투부대 목록보다 우선합니다 — 이 아이템은 판매됩니다."

-- Settings
L["settings:sellJunk"] = "쓰레기 아이템 판매"
L["settings:sellJunkTooltip"] = "낮은 품질(회색) 아이템을 상인 방문 시 자동으로 판매합니다"
L["settings:keepEquippable"] = "착용 가능 아이템 유지"
L["settings:keepEquippableTooltip"] = "내 직업이 착용 가능한 모든 아이템을 유지합니다"
L["settings:keepBindOnAccount"] = "전투부대 귀속 아이템 유지"
L["settings:keepBindOnAccountTooltip"] = "전투부대 귀속(가보) 장비를 유지합니다"
L["settings:keepBindOnAccountPastExpac"] = "  이전 확장팩 포함"
L["settings:keepBindOnAccountPastExpacTooltip"] = "이전 확장팩의 전투부대 귀속 장비도 유지합니다"
L["settings:keepDisenchantables"] = "마력 추출 가능 아이템 유지"
L["settings:keepDisenchantablesTooltip"] = "마법부여사: BOP/BOE/BOA 장비 유지. 그 외: 경매장/분신용 BOE/BOA 장비 유지"
L["settings:keepDisenchantablesPastExpac"] = "  이전 확장팩 포함"
L["settings:keepDisenchantablesPastExpacTooltip"] = "이전 확장팩의 마력 추출 가능 장비도 유지합니다"
L["settings:limitBatch"] = "12개씩 판매"
L["settings:limitBatchTooltip"] = "서버 제한 방지를 위해 한 번에 최대 12개까지만 판매합니다"
L["settings:qualityThreshold"] = "품질 기준"
L["settings:qualityThresholdTooltip"] = "이 품질 이하의 아이템을 판매합니다"
L["settings:ilvlThreshold"] = "아이템 레벨 여유"
L["settings:ilvlThresholdTooltip"] = "장착 중인 장비보다 이 수치 내의 아이템은 유지합니다 (음수 = 더 좋은 아이템 유지)"
L["settings:sellPastExpansion"] = "이전 확장팩 아이템 판매"
L["settings:sellPastExpansionTooltip"] = "선택한 기준보다 오래된 확장팩 아이템을 판매합니다"
L["settings:expansionThreshold"] = "확장팩 기준"
L["settings:expansionThresholdTooltip"] = "선택한 확장팩보다 오래된 아이템을 판매합니다"

-- Quality labels
L["quality:poor"] = "낮음"
L["quality:common"] = "일반"
L["quality:uncommon"] = "고급"
L["quality:rare"] = "희귀"
L["quality:epic"] = "영웅"

-- Expansion labels
L["expansion:all"] = "모든 확장팩"
L["expansion:classic"] = "클래식"
L["expansion:burningCrusade"] = "불타는 성전"
L["expansion:wrathOfTheLichKing"] = "리치 왕의 분노"
L["expansion:cataclysm"] = "대격변"
L["expansion:mistsOfPandaria"] = "판다리아의 안개"
L["expansion:warlordsOfDraenor"] = "드레노어의 전쟁군주"
L["expansion:legion"] = "군단"
L["expansion:battleForAzeroth"] = "아제로스 전쟁"
L["expansion:shadowlands"] = "어둠땅"
L["expansion:dragonflight"] = "용군단"
L["expansion:theWarWithin"] = "내면의 전쟁"

-- List reset buttons
L["listReset:warbandBlacklist"] = "전투부대 보호 목록 초기화"
L["listReset:warbandWhitelist"] = "전투부대 판매 목록 초기화"
L["listReset:charBlacklist"] = "캐릭터 보호 목록 초기화"
L["listReset:charWhitelist"] = "캐릭터 판매 목록 초기화"
L["listReset:confirm"] = "이 목록을 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다."

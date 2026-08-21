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

-- Section titles
L["section:general"] = "일반"
L["section:equipment"] = "장비"
L["section:materials"] = "제작 재료"
L["section:other"] = "소모품 및 기타"
L["section:lists"] = "목록"

-- Settings
L["settings:sellJunk"] = "쓰레기 아이템 판매"
L["settings:sellJunkTooltip"] = "낮은 품질(회색) 아이템을 상인 방문 시 자동으로 판매합니다"
L["settings:limitBatch"] = "12개씩 판매"
L["settings:limitBatchTooltip"] = "서버 제한 방지를 위해 한 번에 최대 12개까지만 판매합니다"
L["settings:sellEquipment"] = "장비 판매"
L["settings:sellEquipmentTooltip"] = "방어구와 무기를 판매할 수 있게 합니다. 끄면 장비는 절대 판매되지 않습니다"
L["settings:ilvlThreshold"] = "아이템 레벨 여유"
L["settings:ilvlThresholdTooltip"] = "해당 부위에 장착한 아이템보다 얼마나 낮은 아이템까지 유지할지 정합니다"
L["settings:marginOnHigherQuality"] = "  더 높은 품질에도 여유 적용"
L["settings:marginOnHigherQualityTooltip"] =
"장착 중인 장비보다 품질이 높은 장비에도 여유를 적용합니다. 끄면 품질이 향상된 장비는 아이템 레벨과 상관없이 유지됩니다"
L["settings:marginOnSameQuality"] = "  같은 품질에도 여유 적용"
L["settings:marginOnSameQualityTooltip"] =
"장착 중인 장비와 품질이 같은 장비에도 여유를 적용합니다. 끄면 장착 중인 아이템 레벨 이상인 장비만 유지됩니다"
L["settings:marginOnLowerQuality"] = "  더 낮은 품질에도 여유 적용"
L["settings:marginOnLowerQualityTooltip"] =
"장착 중인 장비보다 품질이 낮은 장비에도 여유를 적용합니다. 끄면 품질이 낮아진 장비는 아이템 레벨과 상관없이 판매됩니다. 품질이 두 단계 이상 낮은 장비에는 여유가 적용되지 않습니다"
L["settings:keepBindOnAccount"] = "전투부대 귀속 아이템 유지"
L["settings:keepBindOnAccountTooltip"] = "전투부대 귀속(가보) 장비를 유지합니다"
L["settings:keepBindOnAccountPastExpac"] = "  이전 확장팩 포함"
L["settings:keepBindOnAccountPastExpacTooltip"] = "이전 확장팩의 전투부대 귀속 장비도 유지합니다"
L["settings:keepDisenchantables"] = "마력 추출 가능 아이템 유지"
L["settings:keepDisenchantablesTooltip"] = "마법부여사: BOP/BOE/BOA 장비 유지. 그 외: 경매장/분신용 BOE/BOA 장비 유지"
L["settings:keepDisenchantablesPastExpac"] = "  이전 확장팩 포함"
L["settings:keepDisenchantablesPastExpacTooltip"] = "이전 확장팩의 마력 추출 가능 장비도 유지합니다"
L["settings:materialsMode"] = "제작 재료"
L["settings:materialsModeTooltip"] =
"시약, 무역 용품, 보석, 마법부여, 제조법을 어떻게 처리할지 정합니다"
L["settings:materialsExpansion"] = "  이 확장팩부터 유지"
L["settings:materialsExpansionTooltip"] =
"이 확장팩부터의 재료는 유지하고 그보다 오래된 것은 판매합니다. 제작 재료 설정이 선택한 확장팩부터 유지로 되어 있을 때만 사용됩니다"
L["settings:otherMode"] = "소모품 및 기타"
L["settings:otherModeTooltip"] =
"소모품, 가방류, 전투 애완동물, 전문기술 장비, 하우징 장식을 어떻게 처리할지 정합니다"

-- Sell modes
L["mode:keepAll"] = "모두 유지"
L["mode:keepCurrent"] = "현재 확장팩 유지"
L["mode:keepFrom"] = "이 확장팩부터 유지"
L["mode:sellAll"] = "모두 판매"

-- List tabs
L["btn:removeEntry"] = "제거"
L["list:warband"] = "전투부대"
L["list:character"] = "캐릭터"
L["status:listEmpty"] = "이 목록은 비어 있습니다"
L["status:listCount"] = "%d개 항목"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "일괄 판매: 판매됨"
L["verdict:keep"] = "일괄 판매: 유지됨"
L["reason:TEMP_EXCLUDED"] = "이번 상인 방문에서 제외됨"
L["reason:BLACKLISTED"] = "보호 목록에 있음"
L["reason:LOCKED"] = "잠긴 아이템입니다"
L["reason:EQUIPMENT_SET"] = "장비 세트의 일부입니다"
L["reason:NO_SELL_PRICE"] = "어떤 상인도 구매하지 않습니다"
L["reason:REFUNDABLE"] = "아직 환불 가능 기간입니다"
L["reason:WHITELISTED"] = "판매 목록에 있음"
L["reason:TEMP_INCLUDED"] = "이번 상인 방문에서 추가됨"
L["reason:CATEGORY"] = "이 종류의 아이템은 유지하도록 설정되어 있습니다"
L["reason:CURRENT_EXPANSION"] = "유지 중인 확장팩의 아이템입니다"
L["reason:BIND_ON_ACCOUNT"] = "전투부대 귀속 장비는 유지됩니다"
L["reason:DISENCHANTABLE"] = "마력 추출하거나 다른 곳에 팔 가치가 있습니다"
L["reason:EQUIPPABLE"] = "장착 중인 장비에 비해 충분히 쓸만합니다"
L["reason:OUTCLASSED"] = "장착 중인 장비보다 성능이 떨어집니다"
L["reason:SELL_MODE"] = "이 종류의 아이템은 판매하도록 설정되어 있습니다"
L["reason:DEFAULT"] = "어떤 규칙도 적용되지 않아 유지됩니다"

-- Expansion labels
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
L["expansion:midnight"] = "한밤"

-- List reset buttons
L["listReset:warbandBlacklist"] = "전투부대 보호 목록 초기화"
L["listReset:warbandWhitelist"] = "전투부대 판매 목록 초기화"
L["listReset:charBlacklist"] = "캐릭터 보호 목록 초기화"
L["listReset:charWhitelist"] = "캐릭터 판매 목록 초기화"
L["listReset:confirm"] = "이 목록을 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "지금은 %s을(를) 판매할 수 없습니다: %s"
L["msg:dropUnexcluded"] = "%s이(가) 더 이상 제외되지 않으며 이번 방문에서 판매됩니다"

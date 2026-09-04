if GetLocale() ~= "koKR" then return end
---@class BitForge.AzerothPrime
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "AzerothPrime"
L["settings:openEnabled"] = "개봉 가능 아이템 버튼 활성화"
L["settings:openEnabledTooltip"] = "가방 속 다음 개봉 또는 사용 가능한 아이템 버튼을 표시합니다"
L["settings:sellEnabled"] = "상인 판매 활성화"
L["settings:sellEnabledTooltip"] = "상인 창을 열면 규칙이 선택한 아이템을 판매합니다. 규칙을 설정하기 전까지는 아무것도 판매되지 않습니다"
L["settings:bankEnabled"] = "전투부대 은행 입고 활성화"
L["settings:bankEnabledTooltip"] = "은행을 방문하면 재료와 부캐릭터에게 필요한 제조법, 직접 지정한 물품을 보관합니다"

-- Leftover-install guard
L["msg:replacedInstalled"] = "AzerothPrime: 이 애드온으로 대체되어 다음을 비활성화했습니다: %s"
L["msg:replacedInstalledFix"] = "이 메시지를 다시 보지 않으려면 이전 설치 폴더를 삭제하세요."

-- Openables button
L["settings:locked"] = "버튼 고정"
L["settings:lockedTooltip"] = "버튼을 드래그할 수 없도록 고정합니다"
L["settings:buttonSize"] = "버튼 크기"
L["settings:buttonSizeTooltip"] = "버튼의 가로 및 세로 크기(픽셀)"
L["settings:showCount"] = "개수 표시"
L["settings:showCountTooltip"] = "보유한 아이템 개수를 표시합니다"
L["settings:showCooldown"] = "재사용 대기시간 표시"
L["settings:showCooldownTooltip"] = "버튼에 재사용 대기시간을 표시합니다"
L["settings:resetPosition"] = "위치 초기화"
L["settings:manageBlacklist"] = "제외 목록 관리"

L["tooltip:use"] = "왼쪽 클릭하여 열거나 사용합니다."
L["tooltip:skip"] = "오른쪽 클릭하여 이번 접속 동안 건너뜁니다."
L["tooltip:blacklist"] = "Ctrl + 오른쪽 클릭하여 영구히 제외합니다."
L["tooltip:report"] = "Shift + Alt + 오른쪽 클릭하여 이 판정을 신고합니다."
L["tooltip:drag"] = "Alt + 드래그하여 이동합니다."

L["report:blurbOpen"] = "이 신고에는 아이템, 그 가방과 칸, 잠김 여부, BitForge가 이를 분류한 방식, 툴팁 텍스트, 그리고 이 캐릭터가 아는 전문기술이 담깁니다. 캐릭터, 서버, 길드, 진영의 이름은 여기에 없습니다."

L["blacklist:windowTitle"] = "제외된 아이템"
L["blacklist:empty"] = "제외된 아이템이 없습니다."
L["blacklist:remove"] = "제거"
L["blacklist:clearAll"] = "모두 지우기"
L["blacklist:unknownItem"] = "아이템 %d"

L["binding:header"] = "BitForge AzerothPrime"
L["binding:use"] = "개봉 아이템 사용"

L["settings:previewMoves"] = "보관 전 미리 보기"
L["settings:previewMovesTooltip"] = "아이템을 옮기기 전에 모든 이동 목록을 확인 창으로 표시합니다"
L["settings:onlyWantedReagents"] = "사용할 수 있는 재료만 입고"
L["settings:onlyWantedReagentsTooltip"] = "이 계정의 전문기술로 제작할 수 있는 재료만 입고합니다. 끄면 경매장용으로 모든 재료를 입고합니다"

L["btn:deposit"] = "보관"
L["btn:depositing"] = "보관 중… %d"

L["preview:title"] = "보관 확인"
L["preview:summary"] = "아이템 %d개, 이동 %d건"
L["preview:toWarband"] = "→ 전투부대 은행"
L["preview:dontAskAgain"] = "다시 묻지 않기"
L["btn:confirm"] = "확인"
L["btn:cancel"] = "취소"

L["msg:nothingToDo"] = "AzerothPrime: 이동할 항목이 없습니다."
L["msg:done"] = "AzerothPrime: 완료. %d개 아이템을 이동했습니다."
L["msg:noVacancy"] = "AzerothPrime: 전투부대 은행이 가득 찼습니다."
L["msg:blockedCombat"] = "AzerothPrime: 중단됨 — 전투 중입니다."
L["msg:blockedBankClosed"] = "AzerothPrime: 중단됨 — 은행이 닫혔습니다."
L["msg:blockedCursor"] = "AzerothPrime: 중단됨 — 커서에 무언가 들려 있습니다."
L["msg:blockedLocked"] = "AzerothPrime: 중단됨 — 아이템이 잠겨 있습니다."
L["msg:moveFailed"] = "AzerothPrime: 중단됨 — 이동을 완료하지 못했습니다."
L["msg:openProfession"] = "AzerothPrime: 알고 있는 제조법을 기록할 수 있도록 %s 창을 한 번 열어 주십시오."

-- Curation window
L["curation:title"] = "물품 분류"
L["curation:open"] = "물품 분류하기"
L["curation:search"] = "검색"
L["curation:filterDestination"] = "모든 보관 위치"
L["curation:filterClass"] = "모든 아이템 종류"
L["curation:source"] = "출처: %s"
L["curation:sourceBuiltIn"] = "현재 캐릭터"
L["curation:count"] = "%d개 아이템"
L["curation:unscanned"] = "제조법을 검사한 적이 없는 캐릭터: %s. 검사하기 전까지는 해당 전문 기술의 모든 제조법이 필요한 것으로 간주되어 보관됩니다."
L["curation:heldBy"] = "보유 캐릭터"
L["curation:overrideTooltip"] = "직접 지정한 위치입니다. 기본값으로 되돌리면 다시 규칙을 따릅니다."

-- Destinations
L["dest:warband"] = "전투부대 은행"
L["dest:private"] = "개인 은행"
L["dest:privateOwned"] = "개인 은행 (%s)"
L["dest:ignore"] = "그대로 두기"

-- Private destination
L["preview:toPrivate"] = "→ 개인 은행"
L["preview:reclaim"] = "전투부대 은행 → 개인 은행"
L["msg:noVacancyPrivate"] = "AzerothPrime: 개인 은행이 가득 찼습니다."
L["curation:privateTooltip"] = "공용 보관함이 아니라 캐릭터 개인 은행에 보관합니다. 소유자를 지정하지 않으면 은행을 먼저 방문한 캐릭터가 가져갑니다."

-- Target quantity
L["curation:targetSuffix"] = "%d개 유지"
L["target:title"] = "목표 수량"
L["target:prompt"] = "소유자마다 %s을(를) 몇 개씩 보유할까요?"

-- Row menu
L["menu:resetToDefault"] = "기본값으로 되돌리기"
L["menu:owners"] = "소유자"
L["menu:target"] = "목표 수량"
L["menu:targetNone"] = "제한 없음"
L["menu:targetOther"] = "직접 입력…"

L["panel:batchSell"] = "일괄 판매"
L["panel:sellManifest"] = "판매 목록"
L["panel:blacklist"] = "보호 목록"
L["panel:whitelist"] = "항상 판매 목록"

L["ui:ruleWindowTitle"] = "일괄 판매 규칙"
L["ui:ruleWindowNothingToConfigure"] = "여기에는 설정할 항목이 없습니다."
L["ui:ruleWindowDisclaimer"] =
"전투 중이거나 인스턴스 안에서는 게임이 아이템의 세부 정보를 알려주지 않을 때가 있습니다. AzerothPrime은 이럴 때 추측하는 대신 해당 아이템을 보관하므로, 목록에 몇 개가 빠질 수 있습니다 -- 이는 정상입니다. 그 밖의 이유로 판정이 잘못된 것 같다면 알려주실 만한 가치가 있습니다."
L["ui:selectedCount"] = "선택: %d개"
L["ui:reagentsNoProfession"] =
"이 계정의 어느 캐릭터에도 아직 전문기술이 없어 이 규칙은 아무것도 보관하지 않습니다. 전문기술이 있는 캐릭터로 접속하면 이 설정을 다시 쓸 수 있습니다."

L["btn:sellAll"] = "모두 판매"
L["btn:refresh"] = "새로 고침"
L["btn:rules"] = "규칙"

L["menu:temporaryExclude"] = "이번 방문만 제외"
L["menu:blacklisted"] = "보호 목록"
L["menu:whitelisted"] = "항상 판매"
L["menu:noStatus"] = "없음"
L["menu:reportVerdict"] = "이 판정 신고"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "이 제조법의 재료 지정"

L["status:noItemsToSell"] = "판매할 아이템이 없습니다"
L["status:itemsTotal"] = "%d개 아이템  |  합계: %s"

L["ui:manifestHint"] = "목록에 없는 아이템이 있나요? 가방에서 아이템 위에 마우스를 올려 이유를 확인하세요."

-- Merchant row
L["tooltip:charOverride"] = "이 캐릭터의 설정이 전투부대 목록보다 우선합니다 — 이 아이템은 판매됩니다."

L["section:general"] = "일반"
L["section:lists"] = "목록"
L["section:everyItem"] = "모든 아이템"
L["section:byItemType"] = "아이템 유형별"

L["settings:openRuleWindow"] = "규칙 보기"
L["settings:openRuleWindowTooltip"] =
"각 규칙이 무엇을 확인하는지, 아이템이 왜 남거나 판매되었는지 설명합니다"
L["settings:sellJunk"] = "쓰레기 아이템 판매"
L["settings:sellJunkTooltip"] = "조잡한 품질(회색) 아이템을 상인 방문 시 자동으로 판매합니다"
L["settings:limitBatch"] = "12개씩 판매"
L["settings:limitBatchTooltip"] = "서버 제한 방지를 위해 한 번에 최대 12개까지만 판매합니다"
L["settings:keepUsedReagents"] = "전문기술이 쓰는 재료 보관"
L["settings:keepUsedReagentsTooltip"] =
"이 계정의 전문기술이 사용할 수 있는 제작 재료를 보관합니다. 귀속된 재료는 다른 캐릭터에게 갈 수 없으므로 이 캐릭터의 전문기술만 그것을 보관합니다"
L["settings:reagentsExpansions"] = "보관할 재료"
L["settings:reagentsExpansionsTooltip"] =
"위 규칙이 어느 확장팩의 재료를 보관하는지 정합니다. 기본값은 현재 확장팩뿐이라 이전 확장팩의 재료는 판매 목록에 오르지만, 지정해 둔 제조법이 아직 필요로 하는 재료는 여기서 무엇을 선택하든 보관합니다"
L["settings:margin"] = "아이템 레벨 여유"
L["settings:marginTooltip"] =
"같은 품질의 장비가 장착한 것보다 몇 점 아래로 내려가면 판매되는지 정합니다. 0이면 장착한 것과 같기만 해도 유지됩니다"
L["settings:qualityMargin"] = "품질 여유"
L["settings:qualityMarginTooltip"] =
"품질 한 단계가 아이템 레벨로 몇 점어치인지 정합니다. 10이면 장착한 것보다 한 단계 낮은 장비는 10만큼만 앞서면 유지되고, 한 단계 높은 장비는 10만큼 뒤져도 유지됩니다. 0이면 품질을 세지 않고 아이템 레벨만으로 판단합니다. '항상'으로 두면 품질이 더 높은 장비는 아이템 레벨과 상관없이 유지되고, 품질이 더 낮은 장비는 아이템 레벨이 아무리 높아도 유지되지 않습니다"
L["settings:qualityMarginAlways"] = "항상"
L["settings:keepForDisenchant"] = "재료 확장팩 기준으로 장비 유지"
L["settings:keepForDisenchantTooltip"] =
"마법부여사가 마력 추출할 수 있는 장비를, 장비 자체의 연식이 아니라 그 장비가 내놓을 재료의 확장팩을 기준으로 유지합니다 -- 이미 끝난 확장팩의 장비에서는 그 확장팩의 재료가 나옵니다. 자신의 마법부여사는 어떤 설정에서도 그 캐릭터만 손에 넣을 수 있는 장비를 항상 유지하지만, 그 범위가 오래된 재료까지 넓어지는지는 이 설정이 계속 정합니다"
L["settings:spareBindOnAccount"] = "전투부대 귀속 장비 남겨두기"
L["settings:spareBindOnAccountTooltip"] =
"어느 확장팩의 전투부대 귀속 장비를 아직 다른 캐릭터에게 넘길 수 있는 동안 남겨둘지 정합니다"
L["settings:spareBindOnEquip"] = "착용 시 귀속 장비 남겨두기"
L["settings:spareBindOnEquipTooltip"] =
"어느 확장팩의 착용 시 귀속 장비를 아직 다른 캐릭터나 경매장에 보낼 수 있는 동안 남겨둘지 정합니다"
L["settings:keepUncollectedCosmetic"] = "미수집 외형 유지"
L["settings:keepUncollectedCosmeticTooltip"] =
"외형을 아직 수집하지 않은 아이템을 유지합니다. 일반 장비는 상인에게 팔아도 외형이 수집되지만, 겉모습 전용 아이템은 사용해야 외형을 주므로 팔아버리면 그 외형은 영영 사라집니다"
L["settings:sellRelics"] = "클래식 유물 판매"
L["settings:sellRelicsTooltip"] =
"우상, 성서, 토템, 인장 -- 대격변에서 사라진 유물 칸 장비를 판매합니다. 군단의 유물 보석과는 하위 분류 번호만 같을 뿐 서로 다른 물건입니다"
L["settings:gemsExpansions"] = "보관할 보석"
L["settings:gemsExpansionsTooltip"] =
"어느 확장팩의 보석을 보관할지 정합니다. 선택하지 않은 것은 아래 두 질문으로 넘어갑니다"
L["settings:gemsRecipesNow"] = "제조법이 쓰는 현재 보석 유지"
L["settings:gemsRecipesNowTooltip"] =
"누구의 전문기술이든 제조법이 재료로 쓰는 현재 확장팩 보석을 유지합니다. 질문은 제조법 목록에 던지며, 목록에 없는 보석은 어떤 제조법도 원하지 않는 것으로 칩니다"
L["settings:gemsRecipesOld"] = "제조법이 쓰는 과거 보석 유지"
L["settings:gemsRecipesOldTooltip"] =
"지난 확장팩 보석에 대한 같은 질문입니다. 내 전문기술이 쓰는 것은 이미 따로 유지되므로, 이 항목은 다른 사람의 제조법을 위한 것입니다"
L["settings:keepArtifactRelics"] = "유물 보석 유지"
L["settings:keepArtifactRelicsTooltip"] =
"군단 유물 무기에 장착하던 유물 보석을 유지합니다. 군단 이후로는 쓰이지 않으니, 수집이 목적이 아니라면 꺼 두는 편이 낫습니다"
L["settings:enhancementsExpansions"] = "보관할 강화 아이템"
L["settings:enhancementsExpansionsTooltip"] =
"어느 확장팩의 강화 아이템을 보관할지 정합니다. 새 확장팩이 나오면 강화가 맞는 장비 범위도 그만큼 좁아지므로, 실제로 착용 중인 장비의 확장팩을 선택하세요"
L["settings:keepLearnable"] = "배울 수 있는 제조법 유지"
L["settings:keepLearnableTooltip"] =
"이 캐릭터가 아직 배우지 않은 제조법을 유지합니다"
L["settings:keepTradeableRecipes"] = "거래 가능한 제조법 유지"
L["settings:keepTradeableRecipesTooltip"] =
"아직 귀속되지 않은 제조법을 유지합니다. 이 캐릭터가 이미 배웠더라도 분신이나 경매장으로 보낼 수 있기 때문입니다"
L["settings:sellCollectedMounts"] = "수집한 탈것 판매"
L["settings:sellCollectedMountsTooltip"] =
"이미 가지고 있는 탈것을 판매합니다. 귀속된 것만 해당하며, 귀속되지 않은 탈것은 아직 누군가에게 갈 수 있으므로 이 설정과 상관없이 유지됩니다"
L["settings:sellCollectedToys"] = "수집한 장난감 판매"
L["settings:sellCollectedToysTooltip"] =
"이미 가지고 있는 장난감을 판매합니다. 가방 속 사본이 귀속된 것만 해당하며, 귀속되지 않은 장난감은 아직 누군가에게 갈 수 있으므로 수집 여부와 상관없이 유지됩니다"
L["settings:sellCollectedPets"] = "수집한 애완동물 판매"
L["settings:sellCollectedPetsTooltip"] =
"이미 가지고 있는 전투 애완동물을 판매합니다. 아직 수집하지 않은 것은 어떤 설정에서도 이 규칙이 팔지 않습니다"
L["settings:sellHoliday"] = "축제 아이템 판매"
L["settings:sellHolidayTooltip"] =
"축제가 가방에 남긴 징표, 의상, 잡동사니를 판매합니다"
L["settings:sellMountEquipment"] = "탈것 장비 판매"
L["settings:sellMountEquipmentTooltip"] =
"탈것 장비를 판매합니다. 한 번에 하나만 계정 전체에 적용되므로 가방 속 여분은 아무 일도 하지 않습니다"
L["settings:sellCollectedDecor"] = "수집한 장식 판매"
L["settings:sellCollectedDecorTooltip"] =
"목록에 이미 등록된 주택 장식을 판매합니다. 목록이 본 적 없는 장식은 유지하며, 목록을 읽지 못한 경우에도 유지합니다"
L["settings:keepTradeableDyes"] = "거래 가능한 염료 유지"
L["settings:keepTradeableDyesTooltip"] =
"염료는 바를 때 소모될 뿐 배우는 것이 아니므로 수집 여부를 물을 수 없습니다. 대신 이 사본이 아직 누군가에게 갈 수 있는지를 묻습니다: 귀속되지 않았으면 유지, 귀속되었으면 판매입니다"
L["settings:spareProfessions"] = "선택한 전문기술은 남겨두기"
L["settings:spareProfessionsTooltip"] =
"여기서 선택한 전문기술이 재료로 쓸 수 있는 무역 용품을 남겨둡니다 -- 아직 배우지 않은 부캐릭터를 위해서, 또는 경매장을 위해서입니다. 이 계정 자신의 전문기술은 이미 전문기술이 쓰는 재료 보관에서 다루고 있습니다"

L["spare:none"] = "없음"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "모든 확장팩"
L["expansion:current"] = "현재 확장팩"

L["profession:FirstAid"] = "응급치료"
L["profession:Blacksmithing"] = "대장기술"
L["profession:Leatherworking"] = "가죽세공"
L["profession:Alchemy"] = "연금술"
L["profession:Herbalism"] = "약초채집"
L["profession:Cooking"] = "요리"
L["profession:Mining"] = "채광"
L["profession:Tailoring"] = "재봉술"
L["profession:Engineering"] = "기계공학"
L["profession:Enchanting"] = "마법부여"
L["profession:Fishing"] = "낚시"
L["profession:Skinning"] = "무두질"
L["profession:Jewelcrafting"] = "보석세공"
L["profession:Inscription"] = "주문각인"
L["profession:Archaeology"] = "고고학"

L["sub:0"] = "일반"
L["sub:1"] = "물약"
L["sub:2"] = "비약"
L["sub:3"] = "영약"
L["sub:5"] = "음식과 음료"
L["sub:7"] = "붕대"
L["sub:8"] = "기타 소모품"
L["sub:9"] = "반투스 룬"

L["option:expansions"] = "보관할 확장팩"
L["option:recipesNow"] = "제조법이 쓰는 이번 확장팩 것도 보관"
L["option:recipesOld"] = "제조법이 쓰는 과거 것도 보관"

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
L["claimed:OPEN"] = "개봉 버튼이 이 아이템을 가져갔습니다"
L["claimed:DEPOSIT_WARBAND"] = "대신 전투부대 은행으로 보냅니다"
L["claimed:DEPOSIT_PRIVATE"] = "대신 캐릭터의 개인 은행으로 보냅니다"
L["reason:TEMP_EXCLUDED"] = "이번 상인 방문에서 제외됨"
L["reason:BLACKLISTED"] = "보호 목록에 있음"
L["reason:LOCKED"] = "잠긴 아이템입니다"
L["reason:EQUIPMENT_SET"] = "장비 세트의 일부입니다"
L["reason:NO_SELL_PRICE"] = "어떤 상인도 구매하지 않습니다"
L["reason:REFUNDABLE"] = "아직 환불 가능 기간입니다"
L["reason:WHITELISTED"] = "항상 판매 목록에 있음"
L["reason:TEMP_INCLUDED"] = "이번 상인 방문에서 추가됨"
L["reason:JUNK"] = "'쓰레기 아이템 판매'가 꺼져 있어 손대지 않습니다"
L["reason:JUNK_SOLD"] = "'쓰레기 아이템 판매'가 켜져 있어 판매합니다"
L["reason:ABOVE_EPIC"] = "영웅 등급보다 높아 판매하지 않습니다"
L["reason:BIND_ON_ACCOUNT"] = "전투부대 귀속 장비는 유지됩니다"
L["reason:DISENCHANTABLE"] = "마력 추출하거나 다른 곳에 팔 가치가 있습니다"
L["reason:BAG_KEPT"] = "가방은 절대 판매되지 않습니다"
L["reason:PROFESSION_GEAR_KEPT"] = "전문기술 장비는 절대 판매되지 않습니다"
L["reason:ENHANCEMENT_EXPANSION"] = "이 확장팩의 아이템 강화는 보관됩니다"
L["reason:CONSUMABLE_EXPANSION"] = "이 확장팩의 소모품은 보관됩니다"
L["reason:CONSUMABLE_REAGENT"] = "어딘가의 제조법이 이것을 재료로 사용합니다"
L["reason:GEM_EXPANSION"] = "이 확장팩의 보석은 보관됩니다"
L["reason:GEM_REAGENT"] = "어딘가의 제조법이 이것을 재료로 사용합니다"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "유물 보석은 보관됩니다"
L["reason:TRADE_GOOD_SPARED"] = "남겨두기로 선택한 전문기술이 이것을 원합니다"
L["reason:NOT_WANTED"] = "어떤 항목도 보관하지 않아 판매됩니다"
L["reason:REAGENT_WANTED"] = "이것을 사용할 수 있는 전문기술이 재료로 필요로 합니다"
L["reason:NOT_EQUIPPABLE"] = "직업이 장착할 수 없거나 권장되지 않는 장비입니다"
L["reason:EQUIPPABLE"] = "장착 중인 장비에 비해 충분히 쓸만합니다"
L["reason:OUTCLASSED"] = "장착 중인 장비보다 성능이 떨어집니다"
L["reason:OUTDATED_EXPAC"] = "착용 중인 지난 확장팩 장비보다 낫습니다"
L["reason:BIND_ON_EQUIP"] = "착용 시 귀속되는 장비는 유지됩니다"
L["reason:ARMOR_RELIC"] = "이제 아무도 유물을 착용할 수 없어 판매됩니다"
L["reason:RECIPE_LEARNABLE"] = "아직 배우지 않아 보관됩니다"
L["reason:HOLIDAY_ITEM"] = "축제 아이템은 판매됩니다"
L["reason:MOUNT_EQUIPMENT"] = "탈것 장비는 판매됩니다"
L["reason:ALREADY_COLLECTED"] = "이미 수집되어 판매됩니다"
L["reason:NOT_COLLECTED"] = "아직 수집되지 않아 보관됩니다"
L["reason:STILL_TRADEABLE"] = "아직 거래할 수 있어 보관됩니다"
L["reason:ALREADY_LEARNED"] = "이미 배워 판매됩니다"
L["reason:DEFAULT"] = "어떤 규칙도 적용되지 않아 유지됩니다"

L["listReset:warbandBlacklist"] = "전투부대 보호 목록 초기화"
L["listReset:warbandWhitelist"] = "전투부대 항상 판매 목록 초기화"
L["listReset:charBlacklist"] = "캐릭터 보호 목록 초기화"
L["listReset:charWhitelist"] = "캐릭터 항상 판매 목록 초기화"
L["listReset:confirm"] = "이 목록을 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다."

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "지금은 %s을(를) 판매할 수 없습니다: %s"
L["msg:dropUnexcluded"] = "%s이(가) 더 이상 제외되지 않으며 이번 방문에서 판매됩니다"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "일시적으로 제외됨"
L["rule:tempSub"] = "이번 상인 방문에서만"
L["rule:tempBlurb"] =
"판매 버튼을 누르기 전에 판매 목록에서 뺀 아이템입니다. 이번 방문 동안은 가방에 남아 있으며, 다음 상인을 만나면 다시 정상적으로 판정됩니다."
L["rule:black"] = "판매 안 함"
L["rule:blackSub"] = "판매 안 함 목록"
L["rule:blackBlurb"] =
"판매 안 함 목록에 있는 아이템은 가방에 남습니다. 이 캐릭터의 설정이 전투부대 목록과 다를 경우, 방향에 상관없이 캐릭터 설정이 우선합니다."
L["rule:gates"] = "판매 불가"
L["rule:gatesSub"] = "상인이 사지 않는 아이템"
L["rule:gatesBlurb"] =
"잠긴 아이템, 장비 세트에 속한 아이템, 판매가가 없는 아이템, 아직 환불 가능 기간인 구매품이 해당됩니다. 항상 판매 목록도 이를 무시할 수 없는데, 어차피 상인이 거래를 거부하기 때문입니다."
L["rule:white"] = "항상 판매"
L["rule:whiteSub"] = "항상 판매 목록"
L["rule:whiteBlurb"] =
"항상 판매 목록에 있는 아이템은, 이후 규칙이 보관을 결정했을 상황에서도 판매됩니다. 원하지 않는 제작 재료 한 개를 처분하는 방법이 바로 이것입니다."
L["rule:tempIn"] = "이번 방문에 추가됨"
L["rule:tempInSub"] = "이번 상인 방문에서만"
L["rule:tempInBlurb"] =
"이 상인에게서 판매 목록으로 끌어다 놓은 아이템입니다. 이번 방문에서 판매되며, 다음 방문에서는 다시 정상적으로 판정됩니다."
L["rule:junk"] = "조잡한 품질"
L["rule:junkSub"] = "기본값은 꺼짐"
L["rule:junkBlurb"] =
"아이템 종류와 상관없이 회색 아이템입니다. 보통 다른 애드온이 이 역할을 맡기 때문에 기본값은 꺼짐입니다. 다른 애드온이 처리하지 않는다면 이 옵션을 켜세요. AzerothPrime이 대신 정리해 드립니다."
L["rule:epic"] = "전설 등급 이상"
L["rule:epicSub"] = "전설, 유물, 가보"
L["rule:epicBlurb"] =
"절대 판매되지 않습니다. 상인이 가격은 표시하지만 실제로는 거래를 거부하므로, AzerothPrime은 이 아이템들을 목록에 올리지 않습니다."
L["rule:reagent"] = "제작 재료"
L["rule:reagentSub"] = "전문기술 목록을 사용합니다"
L["rule:reagentBlurb"] =
"이 계정의 전문기술이 사용할 수 있는 재료라면, 아이템 종류와 상관없이 보관합니다. 재료는 물약으로도, 보석으로도, 무역 용품으로도 나타나므로 아이템 종류보다 먼저 판정됩니다. 따로 설정하지 않으면 현재 확장팩의 재료만 보관하며, 이전 확장팩의 재료라도 지정해 둔 제조법이 아직 필요로 하면 확장팩 선택과 무관하게 함께 보관합니다. 이 목록은 게임의 제조법에서 직접 읽어 오므로, 제조법이 받아들이는 선택 재료와 모든 품질 등급이 이미 들어 있습니다 -- 따로 열어 보거나 훑어야 할 것은 없습니다."
L["rule:cosmetic"] = "수집하지 않은 외형"
L["rule:cosmeticSub"] = "아직 수집하지 않은 겉모습 아이템"
L["rule:cosmeticBlurb"] =
"아직 수집하지 않은 겉모습 아이템은 보관됩니다. 판매한다고 외형이 수집되는 것이 아니라 그냥 사라지므로, 이 창에서 실수를 되돌릴 수 없는 유일한 지점입니다. 이미 수집한 겉모습 아이템은 겉모습이라는 이유만으로 보관되지 않습니다. 더 이상 지킬 것이 없으므로, 그저 원래 무기나 방어구로서 판정을 받습니다."
L["rule:consumables"] = "소모품"
L["rule:consumablesSub"] = "물약, 음식, 주문서, 진기한 물건"
L["rule:consumablesBlurb"] =
"소모품 종류마다 무엇을 보관할지 선택하세요. 어떤 항목도 체크하지 않으면 판매됩니다."
L["rule:bags"] = "가방"
L["rule:bagsSub"] = "모든 종류의 소지품 주머니"
L["rule:bagsBlurb"] =
"절대 판매되지 않습니다. 어떤 가방을 쓸지는 당신의 선택이므로, AzerothPrime은 가방을 판정하지 않습니다."
L["rule:gear"] = "무기 및 방어구"
L["rule:gearSub"] = "현재 착용 중인 장비와 비교하여 판정합니다"
L["rule:gearBlurb"] =
"하나의 설정이 둘 다 판정합니다. 모든 무기와 모든 방어구는 아래 질문들을 순서대로 거치며, 가장 먼저 '보관'으로 답한 질문에서 결정됩니다."
L["rule:gems"] = "보석"
L["rule:gemsSub"] = "소켓과 유물"
L["rule:gemsBlurb"] =
"모든 보석에 동일한 선택 항목이 적용됩니다. 유물은 아래에 별도 옵션이 있는데, 보석 종류의 다른 어떤 부분도 보관할 가치를 바꾸지 않기 때문입니다."
L["rule:tradeGoods"] = "무역 용품"
L["rule:tradeGoodsSub"] = "전문기술별 제작 재료"
L["rule:tradeGoodsBlurb"] =
"누구의 재료를 남겨둘지 선택하세요. 남겨두지 않은 재료는 모두 판매됩니다 -- 다만 실제로 당신의 전문기술이 사용하는 재료라면 위의 제작 재료 규칙에서 이미 보관하고 있습니다."
L["rule:enhancements"] = "아이템 강화"
L["rule:enhancementsSub"] = "마법부여, 기름, 돌"
L["rule:enhancementsBlurb"] =
"새 확장팩이 나오면 이것들을 적용할 수 있는 장비 범위가 제한되어, 오래된 것은 가치를 잃습니다. 실제로 착용 중인 장비의 확장팩을 모두 선택하세요. 이번 확장팩도 예외가 아니며, 이제 자동으로 보관되지 않습니다."
L["rule:recipes"] = "제조법"
L["rule:recipesSub"] = "도안, 설계도, 공식"
L["rule:recipesBlurb"] =
"제조법에는 그것이 속한 전문기술이 함께 담겨 있으므로, 상인 앞에서 곧바로 판정됩니다. 어느 한 전문기술에도 속하지 않는 제조법, 즉 범용 도안이나 설명서는 견줄 기준이 없으므로 그대로 둡니다."
L["rule:misc"] = "기타"
L["rule:miscSub"] = "애완동물, 탈것, 장난감, 축제 아이템"
L["rule:miscBlurb"] =
"주문 재료는 그대로 둡니다. 분류되지 않은 자잘한 아이템 중에서는 장난감만 판정합니다: 장난감 상자에 이미 있고 가방 속 사본이 귀속된 경우 판매됩니다. 회색 아이템은 여기가 아니라 위의 조잡한 품질 규칙에서 처리합니다."
L["rule:profession"] = "전문기술 장비"
L["rule:professionSub"] = "도구와 부속품"
L["rule:professionBlurb"] =
"절대 판매되지 않습니다. 거래 가능한 것은 돈이 되고, 귀속된 것은 스스로 제작했거나 지금 사용 중인 것이므로, 이것을 파는 것이 옳은 경우는 없습니다."
L["rule:housing"] = "주택"
L["rule:housingSub"] = "장식품과 염료"
L["rule:housingBlurb"] =
"장식품은 한 번 수집되면 아이템 자체는 더 이상 쓸모가 없으므로 상인에게 팔아도 됩니다. 염료는 전혀 다른 종류의 물건입니다. 한 번 쓰면 사라지는 소모품이라 사용하면 소모되므로, 수집할 것도 배울 것도 없습니다. 또한 절대 귀속되지 않으므로, 물어볼 가치가 있는 유일한 질문은 그것을 원하는 누군가에게 아직 전달될 수 있는가 하는 것뿐입니다."
L["rule:none"] = "그 외 전부"
L["rule:noneSub"] = "퀘스트 아이템, 열쇠, 문양, 토큰"
L["rule:noneBlurb"] =
"AzerothPrime이 전혀 판정하지 않는 아이템 종류입니다: 퀘스트 아이템, 열쇠, 우리에 갇힌 애완동물, 문양, WoW 토큰, 주문 재료, 화살, 그리고 그 밖에 퇴역한 분류들입니다. 위 규칙을 어떻게 설정하든 이 아이템들은 가방에 그대로 남습니다."

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "이 신고에는 아이템의 링크와 그 밖의 수치, BitForge가 내린 판정과 그것을 결정한 규칙, 이 아이템을 직접 보호 목록이나 항상 판매 목록에 넣었는지 여부, 이 아이템이 채울 칸에 현재 착용 중인 장비, 그리고 그 둘을 판정한 설정이 담깁니다. 아이템 링크는 캐릭터의 레벨과 전문화를 담고 있습니다 -- 이는 링크 자체 형식의 일부라서, 이를 빼면 신고를 재현 가능하게 만드는 세부 정보를 잃게 됩니다. 여기에는 캐릭터, 서버, 길드, 진영 중 어느 것의 이름도 나타나지 않으며, 그 밖의 어떤 칸도 설명하지 않습니다."

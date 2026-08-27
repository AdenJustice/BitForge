if GetLocale() ~= "koKR" then return end
---@class BitForge.UPS
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "Undermine Parcel Service"
L["settings:enabled"] = "UPS 활성화"
L["settings:enabledTooltip"] = "은행을 방문하면 제작 재료를 전투부대 은행에 보관합니다"
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

L["msg:nothingToDo"] = "UPS: 이동할 항목이 없습니다."
L["msg:done"] = "UPS: 완료. %d개 아이템을 이동했습니다."
L["msg:noVacancy"] = "UPS: 전투부대 은행이 가득 찼습니다."
L["msg:blockedCombat"] = "UPS: 중단됨 — 전투 중입니다."
L["msg:blockedBankClosed"] = "UPS: 중단됨 — 은행이 닫혔습니다."
L["msg:blockedCursor"] = "UPS: 중단됨 — 커서에 무언가 들려 있습니다."
L["msg:blockedLocked"] = "UPS: 중단됨 — 아이템이 잠겨 있습니다."
L["msg:moveFailed"] = "UPS: 중단됨 — 이동을 완료하지 못했습니다."
L["msg:openProfession"] = "UPS: 알고 있는 제조법을 기록할 수 있도록 %s 창을 한 번 열어 주십시오."

-- Curation window
L["curation:title"] = "UPS — 물품 분류"
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
L["msg:noVacancyPrivate"] = "UPS: 개인 은행이 가득 찼습니다."
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

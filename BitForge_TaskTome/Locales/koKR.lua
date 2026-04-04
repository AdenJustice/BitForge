if GetLocale() ~= "koKR" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

-- Widget
L["status:widgetTitle"] = "할 일 장부"
L["btn:lockWidget"] = "잠금"
L["btn:unlockWidget"] = "잠금 해제"

-- Config Frame
L["settings:configTitle"] = "할 일 장부 — 설정"
L["btn:addRootTask"] = "최상위 할 일 추가"
L["btn:addChildTask"] = "하위 할 일 추가"
L["btn:deleteTask"] = "할 일 삭제"
L["btn:save"] = "저장"
L["settings:taskName"] = "이름"
L["settings:resetCycle"] = "초기화 주기"
L["settings:warbandAssigned"] = "전투부대 할 일"
L["settings:completionScope"] = "완료 범위"
L["settings:optState"] = "내 참여 상태"

-- Dropdowns
L["menu:resetNone"] = "없음"
L["menu:resetDaily"] = "매일"
L["menu:resetWeekly"] = "매주"
L["menu:scopeChar"] = "캐릭터"
L["menu:scopeWarband"] = "전투부대"
L["menu:optFollow"] = "기본값 따름"
L["menu:optIn"] = "항상 표시"
L["menu:optOut"] = "항상 숨김"

-- Messages / Dialogs
L["msg:deleteConfirm"] = "'%s' 및 하위 할 일 %d개를 삭제하시겠습니까?"
L["msg:deleteSingle"] = "'%s'을(를) 삭제하시겠습니까?"
L["btn:confirmDelete"] = "삭제"
L["btn:cancel"] = "취소"
L["msg:nameRequired"] = "할 일 이름을 입력해야 합니다."

-- Settings panel
L["settings:taskTomePanel"] = "할 일 장부"
L["settings:config"] = "설정"
L["settings:openConfig"] = "열기"

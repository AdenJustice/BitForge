if GetLocale() ~= "koKR" then return end
---@class BitForge.TaskTome
local ns = select(2, ...)
local L = ns.locale

L["status:widgetTitle"] = "할 일 장부"

L["settings:configTitle"] = "할 일 장부 — 설정"
L["btn:addRootTask"] = "최상위 할 일 추가"
L["btn:addChildTask"] = "하위 할 일 추가"
L["btn:deleteTask"] = "할 일 삭제"
L["btn:save"] = "저장"
L["settings:taskName"] = "이름"
L["settings:resetCycle"] = "초기화 주기"
L["settings:warbandAssigned"] = "모든 캐릭터에 배정"
L["settings:completionScope"] = "완료 범위"
L["settings:optState"] = "내 배정"

L["menu:resetNone"] = "없음"
L["menu:resetDaily"] = "매일"
L["menu:resetWeekly"] = "매주"
L["menu:scopeChar"] = "캐릭터"
L["menu:scopeWarband"] = "공유 — 계정 전체에서 완료 1회 인정"
L["menu:optFollow"] = "기본값 따름"
L["menu:optIn"] = "항상 표시"
L["menu:optOut"] = "항상 숨김"

L["msg:deleteConfirm"] = "'%s' 및 하위 할 일 %d개를 삭제하시겠습니까?"
L["msg:deleteSingle"] = "'%s'을(를) 삭제하시겠습니까?"
L["btn:confirmDelete"] = "삭제"
L["btn:cancel"] = "취소"
L["msg:nameRequired"] = "할 일 이름을 입력해야 합니다."

L["settings:taskTomePanel"] = "할 일 장부"
L["settings:config"] = "설정"
L["settings:openConfig"] = "열기"

L["group:accountWide"] = "계정 전체"
L["tooltip:scopeMe"] = "이 캐릭터만 표시 중입니다. 클릭하면 모든 캐릭터를 표시합니다."
L["tooltip:scopeAll"] = "모든 캐릭터를 표시 중입니다. 클릭하면 이 캐릭터만 표시합니다."
L["tooltip:orientByChar"] = "캐릭터별로 그룹화되어 있습니다. 클릭하면 할 일별로 그룹화합니다."
L["tooltip:orientByTask"] = "할 일별로 그룹화되어 있습니다. 클릭하면 캐릭터별로 그룹화합니다."
L["tooltip:openConfig"] = "할 일 장부 설정 창을 엽니다."
L["tooltip:widgetLocked"] = "창이 잠겨 있습니다. 클릭하면 잠금을 해제하여 이동하고 크기를 조절할 수 있습니다."
L["tooltip:widgetUnlocked"] = "창의 잠금이 해제되어 있습니다. 클릭하면 위치와 크기를 잠급니다."

L["settings:editingFor"] = "편집 대상"
L["settings:optStateFor"] = "%s의 배정"

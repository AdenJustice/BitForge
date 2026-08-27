if GetLocale() ~= "koKR" then return end
---@class BitForge.RepRank
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "RepRank"
L["window:title"] = "RepRank"
L["section:warband"] = "전투부대"
L["section:characters"] = "캐릭터"
L["section:ungrouped"] = "기타"
L["column:faction"] = "평판"
L["column:leader"] = "최고"
L["column:standing"] = "등급"
L["column:progress"] = "진행도"
L["filter:showUntouched"] = "진행하지 않은 평판 표시"
L["filter:search"] = "검색"
L["tooltip:pendingTitle"] = "정예 보상 대기 중"
L["minimap:label"] = "RepRank"
L["standing:unknown"] = "알 수 없음"
L["standing:renown"] = "명성 %d"
L["alert:pendingSelf"] = "정예 보상 준비 완료: %s"
L["alert:pendingAlt"] = "%s의 정예 보상 준비 완료: %s"
L["toast:pendingOne"] = "정예 보상 1개 대기 중"
L["toast:pendingMany"] = "정예 보상 %d개 대기 중"
L["settings:chatAlerts"] = "대화창 알림"
L["settings:chatAlertsTooltip"] = "캐릭터에게 정예 보상이 준비되면 대화창에 알립니다."
L["settings:toastAlerts"] = "팝업 알림"
L["settings:toastAlertsTooltip"] = "캐릭터에게 정예 보상이 준비되면 팝업으로 알립니다."

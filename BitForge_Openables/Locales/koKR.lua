if GetLocale() ~= "koKR" then return end
---@class BitForge.Openables
local ns = select(2, ...)
local L = ns.locale

L["panel:title"] = "개봉"
L["settings:enabled"] = "개봉 활성화"
L["settings:enabledTooltip"] = "가방 속 다음 개봉 또는 사용 가능한 아이템 버튼을 표시합니다"
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

L["report:blurb"] = "이 신고에는 아이템, BitForge가 이를 분류한 방식, 툴팁 텍스트, 그리고 이 캐릭터가 아는 전문기술이 담깁니다. 캐릭터, 서버, 길드, 진영의 이름은 여기에 없습니다."

L["blacklist:windowTitle"] = "제외된 아이템"
L["blacklist:empty"] = "제외된 아이템이 없습니다."
L["blacklist:remove"] = "제거"
L["blacklist:clearAll"] = "모두 지우기"
L["blacklist:unknownItem"] = "아이템 %d"

L["binding:header"] = "BitForge 개봉"
L["binding:use"] = "개봉 아이템 사용"

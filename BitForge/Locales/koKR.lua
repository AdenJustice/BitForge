if GetLocale() ~= "koKR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "왼쪽 클릭으로 옵션 열기"
L["minimap:hintDrag"] = "끌어서 이동"
L["minimap:compartmentTooltip"] = "BitForge 메뉴 열기"

L["msg:schemaResetBody"] = "%s의 저장된 데이터가 이전 버전의 것이라 그대로 이어갈 수 없습니다. 데이터를 초기화하고 다시 만듭니다. 이 작업은 한 번만 수행됩니다."
L["btn:schemaResetAccept"] = "초기화하고 계속하기"

L["cmd:usage"] = "/bitforge <모듈> [인자], /bfdump <모듈> [인자] -- 모듈 이름은 하나만 가리키는 앞부분으로 줄여 쓸 수 있습니다"
L["cmd:unknownModule"] = "%s 이름의 모듈이 없습니다 -- /bitforge 로 목록을 확인하세요"
L["cmd:ambiguousModule"] = "%s 은(는) 여러 모듈을 가리킵니다: %s"
L["cmd:noSuchCommand"] = "%s 모듈에는 %s 명령이 없습니다"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- 이번 업데이트에서 무엇이 바뀌었는지 확인합니다"

L["report:windowTitle"] = "아이템 신고"
L["report:windowTitleDiagnostic"] = "진단 보고서"
L["report:howTo"] = "전체 선택 후 Ctrl+C를 누르세요. 아래 주소에 새 이슈로 붙여넣으세요:"
L["report:selectAll"] = "전체 선택"
L["report:encoded"] = "이 보고서는 너무 길어서 압축되었습니다. 그대로 붙여넣으세요 -- 개발자 도구가 압축을 풀어줍니다."

L["whatsNew:windowTitle"] = "BitForge의 새로운 소식"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "닫기"

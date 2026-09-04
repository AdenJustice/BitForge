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

L["upgrade:windowTitle"] = "이제 BitForge는 여섯 개의 개별 다운로드입니다"
L["upgrade:lead"] = "이제부터 BitForge와 각 모듈은 별도의 다운로드입니다 -- 각각 하나의 프로젝트이며, 저마다 따로 업데이트됩니다. BitForge를 업데이트해도 삭제된 것은 없으므로, 이미 설치해 두신 것은 모두 그대로 남아 정상 작동합니다."
L["upgrade:separate"] = "다음 항목은 더 이상 BitForge 다운로드에 포함되지 않으며, 각각을 개별 프로젝트로 설치하시기 전까지는 아무것도 이들을 업데이트하지 않습니다:"
L["upgrade:renamed"] = "BitForge Dispatch는 BitForge AzerothPrime으로 이름이 바뀌었으며, 그 이름의 독립된 프로젝트입니다. 설치하시면 Dispatch에 저장되어 있던 모든 것 -- 규칙, 아이템별 목록, 보관 대상, 차단 목록, 버튼의 크기와 위치 -- 이 함께 넘어옵니다. 이전 Dispatch가 아직 설치되어 있다면 AzerothPrime이 먼저 이를 비활성화하며, 설정은 다음 접속 때 넘어옵니다. 따라서 애드온 목록에서 Dispatch가 회색으로 보이는 것은 오류가 아니라 정상이며, 그때 해당 폴더를 삭제하셔도 됩니다. 한 가지는 넘어오지 않습니다: 개봉 버튼의 단축키입니다. 게임이 단축키를 버튼 이름으로 저장하기 때문이며, 단축키 설정에서 다시 지정해 주십시오."
L["upgrade:close"] = "확인"

L["msg:outOfStep"] = "%s을(를) CurseForge에서 업데이트하세요: 이 애드온은 %s, BitForge는 %s입니다. 이제 각각 별개의 다운로드이므로 애드온 관리자가 한쪽만 업데이트하고 다른 쪽은 그대로 두는 일이 생깁니다."

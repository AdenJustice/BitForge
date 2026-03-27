local _, ns = ...
if GetLocale() ~= "koKR" then return end
local L                               = ns.L

L["settings:unitFramePanel"]          = "유닛 프레임"

L["settings:enableUnitFrames"]        = "유닛 프레임 활성화"
L["settings:enableUnitFramesTooltip"] = "플레이어, 대상, 집중, 펫, 파티, 공격대, 보스 유닛 프레임을 표시합니다."
L["settings:enableClassPanel"]        = "직업 패널 활성화"
L["settings:enableClassPanelTooltip"] = "자원, 발동 효과, 재사용 대기시간을 보여주는 화면 중앙 직업 패널을 표시합니다."
L["msg:bothDisabled"]                 = "두 기능 모두 비활성화됨. BitForge_UnitFrame은 다음 로그인 시 로드되지 않습니다."

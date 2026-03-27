local _, ns = ...
if GetLocale() ~= "koKR" then return end
local L                         = ns.L

-- Settings panel
L["settings:enabled"]           = "UPS 활성화"
L["settings:guildBankPull"]     = "길드 창고에서 가져오기"
L["settings:guildBankPullTip"]  = "길드 창고에서 지정된 아이템을 가져옵니다 (1인 길드 전용)"
L["settings:guildBankPush"]     = "길드 창고로 보내기"
L["settings:guildBankPushTip"]  = "지정되지 않은 아이템을 길드 창고로 보냅니다 (1인 길드 전용)"
L["settings:activeAdapter"]     = "활성 어댑터"
L["settings:manageAssignments"] = "지정 관리"
L["settings:setupWizard"]       = "설정 마법사"
L["panel:title"]                = "언더마인 소포 서비스"

-- Bank button
L["btn:parcel"]                 = "소포 보내기"
L["btn:parceling"]              = "소포 발송 중… %d"

-- Messages
L["msg:noVacancy"]              = "UPS: 빈 슬롯 없음. 목적지 정렬 중 — 소포 보내기를 클릭하여 재시도하세요."
L["msg:done"]                   = "UPS: 완료. %d개 아이템을 이동했습니다."
L["msg:nothingToDo"]            = "UPS: 이동할 항목이 없습니다."
L["msg:unclassified"]           = "분류되지 않은 재료가 있습니다. 지정 관리를 열어 분류하세요."

-- Setup dialog
L["setup:modePrompt"]           = "%s 설정을 어떻게 진행하시겠습니까?"
L["btn:setupReset"]             = "초기화"
L["btn:setupAppend"]            = "추가"
L["setup:categoryOptIn"]        = "%s에 %s을(를) 배정할까요?"
L["setup:expansionFilter"]      = "이전 확장팩의 %s도 포함할까요?"
L["setup:complete"]             = "설정 완료. 지정 프레임에서 언제든지 배정을 수정할 수 있습니다."
L["btn:currentExpacOnly"]       = "현재 확장팩만"
L["btn:skipSetup"]              = "설정 건너뛰기"
L["btn:done"]                   = "완료"
L["btn:yes"]                    = "예"
L["btn:no"]                     = "아니요"

-- Assignment frame
L["panel:assignments"]          = "카테고리 지정"
L["panel:characters"]           = "캐릭터"
L["panel:expansions"]           = "확장팩"
L["panel:itemsDropHint"]        = "아이템을 여기에 끌어다 놓아 경로를 지정하세요"
L["panel:items"]                = "아이템"
L["btn:deleteCategory"]         = "카테고리 삭제"
L["btn:addCategory"]            = "카테고리 추가"
L["menu:removeItem"]            = "카테고리에서 제거"
L["settings:allExpansions"]     = "모든 확장팩"
L["panel:customSection"]        = "사용자 지정"

-- Expansion names
L["expansion:classic"]          = "클래식"
L["expansion:tbc"]              = "불타는 성전"
L["expansion:wotlk"]            = "리치 왕의 분노"
L["expansion:cata"]             = "대격변"
L["expansion:mop"]              = "판다리아의 안개"
L["expansion:wod"]              = "드레노어의 전쟁군주"
L["expansion:legion"]           = "군단"
L["expansion:bfa"]              = "아제로스 전쟁"
L["expansion:sl"]               = "어둠땅"
L["expansion:df"]               = "용군단"
L["expansion:tww"]              = "내면의 전쟁"
L["expansion:midnight"]         = "미드나잇"

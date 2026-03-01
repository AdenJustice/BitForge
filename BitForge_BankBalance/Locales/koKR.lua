if GetLocale() ~= "koKR" then return end

---@type ns_BB
local ns = select(2, ...)
local L = ns.locale

L["message:deposit"] = "입금: %s"
L["message:withdraw"] = "출금: %s"
L["message:withdrawError"] = "전투부대 은행에서 출금할 수 없습니다."
L["message:depositError"] = "전투부대 은행에 입금할 수 없습니다."
L["message:noBalance"] = "출금 가능한 자금이 없습니다."

L["ui:settings_title"] = "BankBalance 설정"
L["ui:use_warband"] = "전투부대 (계정 공통) 설정 사용"
L["ui:threshold_label"] = "목표 임계값 (골드)"
L["ui:use_margin_label"] = "마진 균형 사용"
L["ui:margin_ratio_label"] = "마진 비율"

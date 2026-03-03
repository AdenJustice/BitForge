if GetLocale() ~= "koKR" then return end

---@type ns.BankBalance
local ns = select(2, ...)
local L = ns.locale

L["message:deposit"] = "입금됨: %s"
L["message:withdraw"] = "출금됨: %s"
L["message:withdrawError"] = "전투부대 은행에서 출금할 수 없습니다."
L["message:depositError"] = "전투부대 은행에 입금할 수 없습니다."
L["message:noBalance"] = "출금할 자금이 없습니다."

L["setting:title"] = "BitForge: BankBalance 설정"
L["setting:category"] = "BankBalance"
L["setting:useGlobal"] = "전투부대 설정 사용"
L["setting:useGlobal_tooltip"] = "체크하면 전투부대 설정을 사용합니다. 체크 해제하면 캐릭터 설정을 사용합니다."
L["setting:enableMargin"] = "마진 비율 사용"
L["setting:enableMargin_tooltip"] = "체크하면 범위 값을 사용합니다. 체크 해제하면 단일 값을 사용합니다."
L["setting:marginRatio"] = "마진 비율"
L["setting:marginRatio_tooltip"] = "작은 변동을 무시할 수 있도록 목표 잔액의 '안전 구간'을 만듭니다. 예를 들어 '10%'로 설정하면 잔액이 목표의 90%~110% 범위에 있는 동안에는 아무 동작도 하지 않습니다."
L["setting:balance"] = "목표 잔액"
L["setting:balance_tooltip"] = "목표 잔액을 선택합니다."

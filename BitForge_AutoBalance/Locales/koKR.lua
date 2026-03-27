local _, ns = ...
if GetLocale() ~= "koKR" then return end
local L                          = ns.L

L["settings:desiredBalance"]     = "목표 보유량"
L["settings:marginalRatio"]      = "허용 오차 비율"
L["settings:collectorCharacter"] = "수금 캐릭터"
L["settings:none"]               = "없음"
L["settings:marginalRatioTip"]   = "차액이 목표 × 비율 이내면 거래를 건너뜁니다"
L["settings:always"]             = "항상"

L["msg:deposit"]                 = "워밴드 은행에 %s 입금했습니다"
L["msg:withdraw"]                = "워밴드 은행에서 %s 출금했습니다"
L["msg:collect"]                 = "워밴드 은행에서 %s 수금했습니다"
L["msg:noFunds"]                 = "워밴드 은행에 출금할 금액이 없습니다"

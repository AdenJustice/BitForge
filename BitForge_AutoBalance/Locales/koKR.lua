if GetLocale() ~= "koKR" then return end
---@class BitForge.AutoBalance
local ns = select(2, ...)
local L = ns.locale

L["panel:autoBalance"] = "자동 균형"

L["settings:useCharSettings"] = "캐릭터 설정 사용"
L["settings:useCharSettingsTooltip"] = "계정 공통 설정 대신 이 캐릭터 전용 값을 사용합니다"

L["settings:desiredBalance"] = "목표 보유량"
L["settings:desiredBalanceTooltip"] = "가방에 유지할 목표 금화 보유량"

L["settings:marginalRatio"] = "허용 오차 비율"
L["settings:marginalRatioTooltip"] = "차액이 목표 × 비율 이내면 거래를 건너뜁니다"

L["settings:collectorCharacter"] = "수금 캐릭터"
L["settings:collectorCharacterTooltip"] = "워밴드 은행에서 잉여 금화를 수금할 캐릭터"

L["settings:none"] = "없음"
L["settings:always"] = "항상"

L["msg:deposit"] = "워밴드 은행에 %s 입금했습니다"
L["msg:withdraw"] = "워밴드 은행에서 %s 출금했습니다"
L["msg:collect"] = "워밴드 은행에서 %s 수금했습니다"
L["msg:noFunds"] = "워밴드 은행에 출금할 금액이 없습니다"

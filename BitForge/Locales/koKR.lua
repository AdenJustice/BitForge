if GetLocale() ~= "koKR" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "왼쪽 클릭으로 옵션 열기"
L["minimap:hintDrag"] = "끌어서 이동"
L["minimap:compartmentTooltip"] = "BitForge 메뉴 열기"

-- Schema upgrade
L["msg:schemaResetBody"] = "%s의 저장된 데이터가 이전 버전의 것이라 그대로 이어갈 수 없습니다. 데이터를 초기화하고 다시 만듭니다. 이 작업은 한 번만 수행됩니다."
L["btn:schemaResetAccept"] = "초기화하고 계속하기"

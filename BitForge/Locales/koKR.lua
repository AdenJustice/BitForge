if GetLocale() ~= "koKR" then return end

---@type ns.Core
local ns                                 = select(2, ...)
local L                                  = ns.locale

-- Minimap Button
L["minimapButton:tooltip_settings"]      = "클릭하여 BitForge 설정을 엽니다."

-- Migration Dialog
L["migration:title"]                     = "데이터 마이그레이션"
L["migration:desc"]                      = "다음 캐릭터들은 같은 클래스를 공유하며 동일한 캐릭터일 수 있습니다. 설정을 현재 캐릭터로 이전할 캐릭터를 선택하거나, 건너뛰기를 눌러 새 항목을 만드세요."
L["migration:button_migrate"]            = "마이그레이션"
L["migration:button_skip"]               = "건너뛰기"
L["migration:button_purge"]              = "삭제"
L["migration:button_keep_all"]           = "모두 유지"

-- Purge Dialog
L["purge:title"]                         = "유효하지 않은 캐릭터 데이터 삭제"
L["purge:desc"]                          = "다음 캐릭터들은 최근에 접속하지 않았습니다. 애드온 데이터를 삭제할 캐릭터를 선택하세요. 실제 캐릭터는 삭제되지 않으며, BitForge의 데이터베이스에서만 제거됩니다."
L["purge:label"]                         = "%s (|cffffff00마지막 접속: %d일 전|r)"

-- Settings
L["settings:plugins_header"]             = "설치된 플러그인 목록"
L["settings:plugins_tooltip"]            = "이 캐릭터에서 플러그인을 활성화하려면 체크하세요."
L["settings:characters_header"]          = "캐릭터 관리"
L["settings:lastSeenThreshold"]          = "캐릭터를 유효하지 않음으로 표시하는 기간"
L["settings:lastSeenThreshold_tooltip"]  = "설정한 일수 동안 접속하지 않은 캐릭터는 로그인 시 유효하지 않음으로 표시됩니다. '없음'으로 설정하면 비활성화됩니다."
L["settings:lastSeenThreshold_never"]    = "없음"
L["settings:lastSeenThreshold_days"]     = "%d일"
L["settings:purgeInvalidButton"]         = "유효하지 않은 캐릭터 지금 삭제"
L["settings:purgeInvalidButton_tooltip"] = "임계값 기간 이내에 접속하지 않은 캐릭터의 애드온 데이터를 즉시 삭제합니다."

-- Notifications
L["notification:invalidCharacters"]      = "BitForge: %d개의 캐릭터가 %d일 이상 접속하지 않았습니다. 설정에서 애드온 데이터를 삭제하세요."
L["notification:nothingToPurge"]         = "BitForge: 삭제할 유효하지 않은 캐릭터가 없습니다."
L["notification:purgeComplete"]          = "BitForge: %d개 캐릭터의 애드온 데이터가 삭제되었습니다."

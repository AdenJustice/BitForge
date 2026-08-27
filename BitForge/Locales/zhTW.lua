if GetLocale() ~= "zhTW" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "左鍵點擊開啟選項"
L["minimap:hintDrag"] = "拖曳以移動"
L["minimap:compartmentTooltip"] = "開啟 BitForge 選單"

-- Schema upgrade
L["msg:schemaResetBody"] = "%s 的存檔資料來自舊版本，無法繼續沿用。這些資料將被清除並重新建立。此操作只會發生一次。"
L["btn:schemaResetAccept"] = "清除並繼續"

-- Slash commands
L["cmd:usage"] = "/bitforge <模組> [參數]，/bfdump <模組> [參數] -- 模組名稱可縮寫為任何只符合一個模組的前綴"
L["cmd:unknownModule"] = "沒有名為 %s 的模組 -- 輸入 /bitforge 查看清單"
L["cmd:ambiguousModule"] = "%s 對應到多個模組：%s"
L["cmd:noSuchCommand"] = "%s 沒有 %s 指令"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- 顯示本次更新的內容"

-- Report window
L["report:windowTitle"] = "回報物品"
L["report:howTo"] = "全選後按 Ctrl+C，然後貼到以下網址的新議題中："
L["report:selectAll"] = "全選"

-- The release-notes popup
L["whatsNew:windowTitle"] = "BitForge 更新內容"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "關閉"

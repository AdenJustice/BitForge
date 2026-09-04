if GetLocale() ~= "zhTW" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "左鍵點擊開啟選項"
L["minimap:hintDrag"] = "拖曳以移動"
L["minimap:compartmentTooltip"] = "開啟 BitForge 選單"

L["msg:schemaResetBody"] = "%s 的存檔資料來自舊版本，無法繼續沿用。這些資料將被清除並重新建立。此操作只會發生一次。"
L["btn:schemaResetAccept"] = "清除並繼續"

L["cmd:usage"] = "/bitforge <模組> [參數]，/bfdump <模組> [參數] -- 模組名稱可縮寫為任何只符合一個模組的前綴"
L["cmd:unknownModule"] = "沒有名為 %s 的模組 -- 輸入 /bitforge 查看清單"
L["cmd:ambiguousModule"] = "%s 對應到多個模組：%s"
L["cmd:noSuchCommand"] = "%s 沒有 %s 指令"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- 顯示本次更新的內容"

L["report:windowTitle"] = "回報物品"
L["report:windowTitleDiagnostic"] = "診斷報告"
L["report:howTo"] = "全選後按 Ctrl+C，然後貼到以下網址的新議題中："
L["report:selectAll"] = "全選"
L["report:encoded"] = "這份報告太長，無法直接閱讀，因此已被壓縮。請原樣貼上 -- 開發者的工具會將其解壓縮。"

L["whatsNew:windowTitle"] = "BitForge 更新內容"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "關閉"

L["upgrade:windowTitle"] = "BitForge 現在是六個獨立下載"
L["upgrade:lead"] = "從現在起，BitForge 與各個模組是彼此獨立的下載 —— 每個都是自己的專案，各自更新。更新 BitForge 沒有刪除任何東西，你原有的一切仍然裝著，也仍然能用。"
L["upgrade:separate"] = "以下這些不再包含在 BitForge 的下載裡。在你把它們各自當成獨立專案安裝之前，不會再有任何東西更新它們："
L["upgrade:renamed"] = "BitForge Dispatch 已更名為 BitForge AzerothPrime，並以該名稱成為獨立專案。安裝它之後，Dispatch 儲存過的一切 —— 規則、逐件物品的清單、存放去向、黑名單、按鈕的大小與位置 —— 都會一併帶過來。如果舊的 Dispatch 仍然裝著，AzerothPrime 會先將它停用，你的設定會在下次登入時到位；因此在外掛列表裡看到 Dispatch 變灰是正常現象而不是故障，那時就可以刪除該資料夾了。有一樣帶不過來：可開啟物品按鈕的按鍵綁定，遊戲是按按鈕名稱儲存它的。請在按鍵設定中重新綁定。"
L["upgrade:close"] = "知道了"

L["msg:outOfStep"] = "請在 CurseForge 上更新 %s：它是 %s，而 BitForge 是 %s。現在兩者是各自獨立的下載，外掛管理器可能只更新其中一個。"

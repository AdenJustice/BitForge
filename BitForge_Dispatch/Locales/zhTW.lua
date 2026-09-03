if GetLocale() ~= "zhTW" then return end
---@class BitForge.Dispatch
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "Dispatch"
L["settings:openEnabled"] = "啟用可開啟物品按鈕"
L["settings:openEnabledTooltip"] = "顯示一個按鈕，指向背包中下一件可開啟或可使用的物品"
L["settings:sellEnabled"] = "啟用向商人出售"
L["settings:sellEnabledTooltip"] = "開啟商人視窗時出售規則選中的物品。在你設定規則之前不會出售任何東西"
L["settings:bankEnabled"] = "啟用存入戰隊銀行"
L["settings:bankEnabledTooltip"] = "當你造訪銀行時，存入材料、分身需要的配方，以及你指定的物品"

-- Leftover-install guard
L["msg:replacedInstalled"] = "Dispatch：%s 仍已安裝。"
L["msg:replacedInstalledFix"] = "刪除它，然後重新登入，讓 Dispatch 接手。"

-- Openables button
L["settings:locked"] = "鎖定按鈕"
L["settings:lockedTooltip"] = "禁止拖曳按鈕"
L["settings:buttonSize"] = "按鈕大小"
L["settings:buttonSizeTooltip"] = "按鈕的寬度與高度，以像素為單位"
L["settings:showCount"] = "顯示數量"
L["settings:showCountTooltip"] = "顯示你攜帶的該物品數量"
L["settings:showCooldown"] = "顯示冷卻"
L["settings:showCooldownTooltip"] = "在按鈕上顯示冷卻時間"
L["settings:resetPosition"] = "重設位置"
L["settings:manageBlacklist"] = "管理排除清單"

L["tooltip:use"] = "左鍵點擊以開啟或使用。"
L["tooltip:skip"] = "右鍵點擊以在本次登入期間略過。"
L["tooltip:blacklist"] = "Ctrl + 右鍵點擊以永久排除。"
L["tooltip:report"] = "Shift + Alt + 右鍵點擊以回報此判定。"
L["tooltip:drag"] = "Alt + 拖曳以移動。"

L["report:blurbOpen"] = "這份報告包含物品、它的背包與格子以及是否被鎖定、BitForge 對它的分類方式、它的提示文字，以及本角色已知的專業。這裡不會寫出你角色的名字、所在伺服器、公會或陣營。"

L["report:blurbField"] = "這份報告包含上次掃描排出的每一個候選物品，按排名順序列出：各自的名稱、物品 ID、背包與格子、堆疊數量、優先級以及排到該位置的原因，它是否是需要鑰匙的上鎖箱子、它所在的格子目前是否被鎖定，以及它是否正在冷卻或被延後。這裡不會寫出你角色的名字、所在伺服器、公會或陣營，也不包含任何物品的提示文字。"

L["report:blurbAllowList"] = "這份報告包含插件自己手工維護的兩份開啟名單 —— 開啟白名單與開啟黑名單 —— 中的每一件物品，兩份名單各占一節；指定其中一份執行時只寫這一節。每一行寫有物品 ID 與名稱、忽略該名單後開啟規則得出的判定、作出該判定的那一層規則、這一層給出的優先級，以及僅白名單才有的、名單為它鎖定的優先級，還有該條目所屬的分組。若某一行寫的是該物品的詳細資訊或提示文字始終沒有回傳，那說的是你執行命令時這個客戶端的快取，而不是物品本身；首次執行時白名單中的絕大多數都會這樣寫。它按物品 ID 讀取隨插件附帶的名單和每件物品的提示文字，因此不會描述你背包裡的東西 —— 但名單中被你排除或在本次登入期間略過的物品會被如實標出，取決於本角色狀態的判定也會標出，例如你能否使用該物品、能否打開上鎖的箱子。這裡不會寫出你角色的名字、所在伺服器、公會或陣營。"

L["blacklist:windowTitle"] = "已排除的物品"
L["blacklist:empty"] = "沒有已排除的物品。"
L["blacklist:remove"] = "移除"
L["blacklist:clearAll"] = "全部清除"
L["blacklist:unknownItem"] = "物品 %d"

L["binding:header"] = "BitForge Dispatch"
L["binding:use"] = "使用可開啟物品"

L["settings:previewMoves"] = "存入前預覽"
L["settings:previewMovesTooltip"] = "在存入任何物品之前，顯示列出所有移動操作的確認視窗"
L["settings:onlyWantedReagents"] = "僅存入可使用的材料"
L["settings:onlyWantedReagentsTooltip"] = "僅存入此帳號任一專業能用於製作的材料。關閉則存入全部材料，供拍賣場使用"

L["btn:deposit"] = "存入"
L["btn:depositing"] = "正在存入… %d"

L["preview:title"] = "確認存入"
L["preview:summary"] = "%d 件物品，共 %d 次移動"
L["preview:toWarband"] = "→ 戰隊銀行"
L["preview:dontAskAgain"] = "不再詢問"
L["btn:confirm"] = "確認"
L["btn:cancel"] = "取消"

L["msg:nothingToDo"] = "Dispatch：沒有需要移動的物品。"
L["msg:done"] = "Dispatch：完成。已移動 %d 件物品。"
L["msg:noVacancy"] = "Dispatch：戰隊銀行已滿。"
L["msg:blockedCombat"] = "Dispatch：已停止 — 你正在戰鬥中。"
L["msg:blockedBankClosed"] = "Dispatch：已停止 — 銀行已關閉。"
L["msg:blockedCursor"] = "Dispatch：已停止 — 游標上有物品。"
L["msg:blockedLocked"] = "Dispatch：已停止 — 物品已鎖定。"
L["msg:moveFailed"] = "Dispatch：已停止 — 移動未能完成。"
L["msg:openProfession"] = "Dispatch：請開啟一次%s視窗，讓 Dispatch 記錄你已學會的配方。"

-- Curation window
L["curation:title"] = "物品整理"
L["curation:open"] = "整理物品"
L["curation:search"] = "搜尋"
L["curation:filterDestination"] = "任何去向"
L["curation:filterClass"] = "任何物品類型"
L["curation:source"] = "資料來源：%s"
L["curation:sourceBuiltIn"] = "目前角色"
L["curation:count"] = "共 %d 件物品"
L["curation:unscanned"] = "從未掃描過配方：%s。在掃描之前，其專業的所有配方都會被視為需要並存入銀行。"
L["curation:heldBy"] = "持有角色"
L["curation:overrideTooltip"] = "該去向由你指定。恢復預設後將重新依規則判斷。"

-- Destinations
L["dest:warband"] = "戰隊銀行"
L["dest:private"] = "個人銀行"
L["dest:privateOwned"] = "個人銀行（%s）"
L["dest:ignore"] = "保持不動"

-- Private destination
L["preview:toPrivate"] = "→ 個人銀行"
L["preview:reclaim"] = "戰隊銀行 → 個人銀行"
L["msg:noVacancyPrivate"] = "Dispatch：你的銀行已滿。"
L["curation:privateTooltip"] = "存放在角色自己的銀行，而非共用倉庫。未指定歸屬角色時，最先造訪銀行的角色會取走它。"

-- Target quantity
L["curation:targetSuffix"] = "保留 %d"
L["target:title"] = "目標數量"
L["target:prompt"] = "每位歸屬角色應保留多少個%s？"

-- Row menu
L["menu:resetToDefault"] = "恢復預設"
L["menu:owners"] = "歸屬角色"
L["menu:target"] = "目標數量"
L["menu:targetNone"] = "不限制"
L["menu:targetOther"] = "其他…"

L["panel:batchSell"] = "批次出售"
L["panel:sellManifest"] = "出售清單"
L["panel:blacklist"] = "黑名單"
L["panel:whitelist"] = "白名單"

L["ui:ruleWindowTitle"] = "批次出售規則"
L["ui:ruleWindowNothingToConfigure"] = "這裡沒有可設定的內容。"
L["ui:ruleWindowDisclaimer"] =
"在戰鬥中和副本裡，遊戲有時不會透露物品的詳細資訊。Dispatch 會保留這些物品，而不是去猜測，所以清單中可能會缺少個別物品 -- 這是正常現象。如果某個判定因為其他原因看起來有問題，值得回報。"
L["ui:selectedCount"] = "已選擇：%d 個"
L["ui:reagentsNoProfession"] =
"本帳號還沒有任何角色擁有專業，所以這條規則什麼也不會保留。用一個有專業的角色登入，這些設定就會恢復。"

L["btn:sellAll"] = "全部出售"
L["btn:refresh"] = "重新整理"
L["btn:rules"] = "規則"

L["menu:temporaryExclude"] = "暫時排除"
L["menu:blacklisted"] = "黑名單"
L["menu:whitelisted"] = "白名單"
L["menu:noStatus"] = "無"
L["menu:reportVerdict"] = "回報此判定"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "標記該配方的材料"

L["status:noItemsToSell"] = "沒有可出售的物品"
L["status:itemsTotal"] = "%d 件物品  |  合計：%s"

L["ui:manifestHint"] = "期望的物品沒有出現在清單中？將滑鼠移到背包中的該物品上查看原因。"

-- Merchant row
L["tooltip:charOverride"] = "此角色的設定優先於戰隊清單——此物品將被出售。"

L["section:general"] = "一般"
L["section:lists"] = "清單"
L["section:everyItem"] = "所有物品"
L["section:byItemType"] = "按物品類型"

L["settings:openRuleWindow"] = "查看規則"
L["settings:openRuleWindowTooltip"] =
"說明每條規則檢查的內容，以及物品被保留或出售的原因"
L["settings:sellJunk"] = "出售垃圾物品"
L["settings:sellJunkTooltip"] = "拜訪商人時自動出售所有粗糙品質（灰色）物品"
L["settings:limitBatch"] = "每批限制12件"
L["settings:limitBatchTooltip"] = "每次點擊最多出售12件物品以避免伺服器速率限制"
L["settings:keepUsedReagents"] = "保留專業所需材料"
L["settings:keepUsedReagentsTooltip"] =
"保留此帳號任一專業可使用的製作材料。靈魂綁定的材料無法交給其他角色，因此只有目前角色的專業才會保留它"
L["settings:reagentsExpansions"] = "保留哪些材料"
L["settings:reagentsExpansionsTooltip"] =
"上面的規則保留哪些資料片的材料。預設只勾選目前資料片，所以更早的材料會被列入出售——但你標記過的配方仍然需要的材料例外，無論這裡怎麼勾選都會保留"
L["settings:margin"] = "物品等級邊際"
L["settings:marginTooltip"] =
"同品質的裝備比已裝備的低多少就會出售。設為 0 時只需與已裝備的持平"
L["settings:qualityMargin"] = "品質邊際"
L["settings:qualityMarginTooltip"] =
"一個品質等級折算多少物品等級。設為 10 時，比已裝備低一階的裝備只需高出 10 就能保留，高一階的裝備低 10 以內也能保留。設為 0 時品質不再計入，僅依物品等級判斷。設為「一律」時，品質更高的裝備無論物品等級如何都會保留，品質更低的裝備再高的物品等級也留不住"
L["settings:qualityMarginAlways"] = "一律"
L["settings:keepForDisenchant"] = "按產出材料的資料片保留裝備"
L["settings:keepForDisenchantTooltip"] = "保留附魔師能夠分解的裝備，依據的是它會產出的材料屬於哪個資料片，而不是裝備本身的新舊——來自已完結資料片的裝備，產出的正是該資料片的材料。你自己的附魔師無論此設定為何，都會保留只有他才能拿到的裝備，但這個設定仍然決定這是否延伸到更舊的材料"
L["settings:spareBindOnAccount"] = "留存帳號綁定裝備"
L["settings:spareBindOnAccountTooltip"] = "保留哪些資料片的帳號綁定裝備，前提是它還能傳給其他角色"
L["settings:spareBindOnEquip"] = "留存裝備後綁定裝備"
L["settings:spareBindOnEquipTooltip"] = "保留哪些資料片的裝備後綁定裝備，前提是它還能給其他角色或拍賣場"
L["settings:keepUncollectedCosmetic"] = "保留未收藏的外觀"
L["settings:keepUncollectedCosmeticTooltip"] = "保留任何你尚未收藏其外觀的物品。一般裝備賣給商人仍會收藏外觀，但時裝物品要使用才會給出外觀——賣掉它，那個外觀就永遠沒了"
L["settings:sellRelics"] = "出售傳統聖物"
L["settings:sellRelicsTooltip"] = "出售神像、聖契、圖騰與魔印——浩劫與重生移除的那個聖物欄位。不是軍團再臨的神兵遺物，後者屬於寶石，只是子類編號相同而已"
L["settings:gemsExpansions"] = "保留哪些寶石"
L["settings:gemsExpansionsTooltip"] = "保留哪些資料片的寶石。未勾選的會落到下面兩個問題上"
L["settings:gemsRecipesNow"] = "保留配方需要的目前寶石"
L["settings:gemsRecipesNowTooltip"] = "保留任何專業配方當作材料使用的本資料片寶石，無論那個專業屬於誰。問題問的是配方目錄，目錄中沒有的寶石，視為沒有任何配方需要"
L["settings:gemsRecipesOld"] = "保留配方需要的舊寶石"
L["settings:gemsRecipesOldTooltip"] = "對過往資料片寶石提出同樣的問題。你自己專業要用的東西已經在別處保留了，所以這一項是為別人的配方準備的"
L["settings:keepArtifactRelics"] = "保留神兵遺物"
L["settings:keepArtifactRelicsTooltip"] = "保留鑲嵌在軍團再臨神兵武器上的遺物。軍團再臨之後再無用處，除非你專門收藏，否則值得關掉"
L["settings:enhancementsExpansions"] = "保留哪些強化物品"
L["settings:enhancementsExpansionsTooltip"] = "保留哪些資料片的物品強化。新資料片一出，強化能用在的裝備範圍就會收窄，所以請勾選你實際穿著的那個資料片"
L["settings:keepLearnable"] = "保留可以學習的配方"
L["settings:keepLearnableTooltip"] = "保留這個角色尚未學會的配方"
L["settings:keepTradeableRecipes"] = "保留可交易的配方"
L["settings:keepTradeableRecipesTooltip"] = "保留仍未綁定的配方，這樣即使這個角色已經學會，它也能送給分身或上拍賣場"
L["settings:sellCollectedMounts"] = "出售已收藏的坐騎"
L["settings:sellCollectedMountsTooltip"] = "出售你已經擁有的坐騎，前提是這一份已經靈魂綁定。未綁定的一份無論這裡怎麼設定都會保留，因為它還能到想要的人手裡"
L["settings:sellCollectedToys"] = "出售已收藏的玩具"
L["settings:sellCollectedToysTooltip"] = "出售你已經擁有的玩具，前提是背包裡的這一份已經綁定。未綁定的一份無論你的收藏情況如何都會保留，因為它還能到想要的人手裡"
L["settings:sellCollectedPets"] = "出售已收藏的寵物"
L["settings:sellCollectedPetsTooltip"] = "出售你已經擁有的戰鬥寵物。從未收藏過的寵物，無論怎麼設定這條規則都不會賣"
L["settings:sellHoliday"] = "出售節慶物品"
L["settings:sellHolidayTooltip"] = "出售世界活動留在你背包裡的代幣、服裝與雜物"
L["settings:sellMountEquipment"] = "出售坐騎裝備"
L["settings:sellMountEquipmentTooltip"] = "出售坐騎裝備。同一時間整個帳號只有一件生效，所以背包裡的備用件毫無作用"
L["settings:sellCollectedDecor"] = "出售已收藏的裝飾品"
L["settings:sellCollectedDecorTooltip"] = "出售你的圖鑑中已有的住宅裝飾品。圖鑑從未見過的裝飾品會保留，讀不到圖鑑的那一件同樣保留"
L["settings:keepTradeableDyes"] = "保留可交易的染料"
L["settings:keepTradeableDyesTooltip"] = "染料在塗上時被消耗，從不學習，因此沒有收藏可問。改問的是這一份是否還能到某個人手裡：未綁定則保留，已綁定則出售"
L["settings:spareProfessions"] = "留存這些專業"
L["settings:spareProfessionsTooltip"] =
"如果這裡勾選的任一專業可能會用它作為材料，就保留該貿易物品——用於尚未學會該專業的小號，或用於拍賣場。本帳號自己的專業已經由「保留專業所需材料」涵蓋"

L["spare:none"] = "不留存"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "所有資料片"
L["expansion:current"] = "目前資料片"

L["profession:FirstAid"] = "急救"
L["profession:Blacksmithing"] = "鍛造"
L["profession:Leatherworking"] = "製皮"
L["profession:Alchemy"] = "煉金術"
L["profession:Herbalism"] = "草藥學"
L["profession:Cooking"] = "烹飪"
L["profession:Mining"] = "採礦"
L["profession:Tailoring"] = "裁縫"
L["profession:Engineering"] = "工程學"
L["profession:Enchanting"] = "附魔"
L["profession:Fishing"] = "釣魚"
L["profession:Skinning"] = "剝皮"
L["profession:Jewelcrafting"] = "珠寶設計"
L["profession:Inscription"] = "銘文學"
L["profession:Archaeology"] = "考古學"

L["sub:0"] = "一般"
L["sub:1"] = "藥水"
L["sub:2"] = "增效藥"
L["sub:3"] = "合劑和藥瓶"
L["sub:5"] = "食物和飲料"
L["sub:7"] = "繃帶"
L["sub:8"] = "其他消耗品"
L["sub:9"] = "優勢符文"

L["option:expansions"] = "保留哪些資料片"
L["option:recipesNow"] = "如果有配方需要，也保留本資料片的"
L["option:recipesOld"] = "如果有配方需要，也保留更早的"

-- List tabs
L["btn:removeEntry"] = "移除"
L["list:warband"] = "戰隊"
L["list:character"] = "角色"
L["status:listEmpty"] = "此清單為空"
L["status:listCount"] = "%d 個項目"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "批次出售：將被出售"
L["verdict:keep"] = "批次出售：將被保留"
L["claimed:OPEN"] = "已被開啟按鈕認領"
L["claimed:DEPOSIT_WARBAND"] = "將改為存入戰隊銀行"
L["claimed:DEPOSIT_PRIVATE"] = "將改為存入個人銀行"
L["reason:TEMP_EXCLUDED"] = "本次商人拜訪中已排除"
L["reason:BLACKLISTED"] = "在你的黑名單中"
L["reason:LOCKED"] = "此物品已鎖定"
L["reason:EQUIPMENT_SET"] = "屬於套裝的一部分"
L["reason:NO_SELL_PRICE"] = "沒有商人會購買它"
L["reason:REFUNDABLE"] = "仍在退款期限內"
L["reason:WHITELISTED"] = "在你的白名單中"
L["reason:TEMP_INCLUDED"] = "本次商人拜訪中已加入"
L["reason:JUNK"] = "「出售垃圾物品」已關閉，垃圾物品不予處理"
L["reason:JUNK_SOLD"] = "「出售垃圾物品」已開啟，垃圾物品將被出售"
L["reason:ABOVE_EPIC"] = "品質高於史詩，因此永不出售"
L["reason:BIND_ON_ACCOUNT"] = "帳號綁定的裝備會被保留"
L["reason:DISENCHANTABLE"] = "值得保留以便分解或轉售"
L["reason:BAG_KEPT"] = "背包永不出售"
L["reason:PROFESSION_GEAR_KEPT"] = "專業裝備永不出售"
L["reason:ENHANCEMENT_EXPANSION"] = "本資料片的物品強化被保留"
L["reason:CONSUMABLE_EXPANSION"] = "本資料片的消耗品會被保留"
L["reason:CONSUMABLE_REAGENT"] = "某個配方需要將其作為材料"
L["reason:GEM_EXPANSION"] = "本資料片的寶石會被保留"
L["reason:GEM_REAGENT"] = "某個配方需要將其作為材料"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "神器遺物會被保留"
L["reason:TRADE_GOOD_SPARED"] = "你選擇留存的專業想要它"
L["reason:NOT_WANTED"] = "沒有選項保留它，因此予以出售"
L["reason:REAGENT_WANTED"] = "能夠使用它的專業需要該材料"
L["reason:NOT_EQUIPPABLE"] = "你的職業無法裝備或不建議使用"
L["reason:EQUIPPABLE"] = "相對於已裝備的裝備而言足夠好"
L["reason:OUTCLASSED"] = "不如已裝備的裝備"
L["reason:OUTDATED_EXPAC"] = "優於你目前裝備的上個資料片物品"
L["reason:BIND_ON_EQUIP"] = "裝備後綁定的物品會被保留"
L["reason:ARMOR_RELIC"] = "已無人能裝備聖物，因此予以出售"
L["reason:RECIPE_LEARNABLE"] = "尚未學會，因此予以保留"
L["reason:HOLIDAY_ITEM"] = "節慶物品會被出售"
L["reason:MOUNT_EQUIPMENT"] = "坐騎裝備會被出售"
L["reason:ALREADY_COLLECTED"] = "已經收藏，因此予以出售"
L["reason:NOT_COLLECTED"] = "尚未收藏，因此予以保留"
L["reason:STILL_TRADEABLE"] = "仍可交易，因此予以保留"
L["reason:ALREADY_LEARNED"] = "已經學會，因此予以出售"
L["reason:DEFAULT"] = "沒有規則認領它，因此予以保留"

L["listReset:warbandBlacklist"] = "重置戰隊黑名單"
L["listReset:warbandWhitelist"] = "重置戰隊白名單"
L["listReset:charBlacklist"] = "重置角色黑名單"
L["listReset:charWhitelist"] = "重置角色白名單"
L["listReset:confirm"] = "確定要清空此清單嗎？此操作無法撤銷。"

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "目前無法出售%s：%s"
L["msg:dropUnexcluded"] = "%s不再被排除，將於本次拜訪中出售"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "暫時排除"
L["rule:tempSub"] = "僅限本次商人拜訪"
L["rule:tempBlurb"] =
"在點擊出售前從出售清單中移除的物品。它們會在本次拜訪中留在背包裡，下次拜訪商人時將再次正常判定。"
L["rule:black"] = "永不出售"
L["rule:blackSub"] = "你的永不出售清單"
L["rule:blackBlurb"] =
"永不出售清單中的物品會留在背包裡。當角色與戰隊清單意見不一致時，以本角色的設定為準。"
L["rule:gates"] = "無法出售"
L["rule:gatesSub"] = "商人不會收購這些"
L["rule:gatesBlurb"] =
"已鎖定的物品、屬於套裝的物品、沒有售價的物品，以及仍在退款期內的購買紀錄。你的永遠出售清單不會覆蓋這些，因為商人無論如何都會拒絕這筆交易。"
L["rule:white"] = "永遠出售"
L["rule:whiteSub"] = "你的永遠出售清單"
L["rule:whiteBlurb"] =
"永遠出售清單中的物品會被出售，即使後面的規則原本會保留它。這就是你出售那一件不想要的製作材料的方法。"
L["rule:tempIn"] = "本次加入出售"
L["rule:tempInSub"] = "僅限本次商人拜訪"
L["rule:tempInBlurb"] =
"你在這位商人處拖入出售清單的物品。它們會在本次拜訪中被出售，下次拜訪時會再次正常判定。"
L["rule:junk"] = "粗糙品質"
L["rule:junkSub"] = "預設關閉"
L["rule:junkBlurb"] =
"灰色物品，無論具體是哪種物品。預設關閉，因為這通常由其他外掛負責處理。如果沒有其他外掛處理，開啟這個選項，Dispatch 會替你清理它們。"
L["rule:epic"] = "傳說品質及以上"
L["rule:epicSub"] = "傳說、神器、傳家寶"
L["rule:epicBlurb"] =
"永不出售。商人會為這些物品顯示價格，隨後又拒絕這筆交易，因此 Dispatch 不會把它們列入清單。"
L["rule:reagent"] = "製作材料"
L["rule:reagentSub"] = "使用你的專業清單"
L["rule:reagentBlurb"] =
"保留本帳號任一專業可以使用的材料，無論它是哪種物品。材料既可能是藥水，也可能是寶石或貿易物品，所以這項判定在物品類型之前進行。在你另行設定之前，只保留目前資料片的材料；更早的材料只要還被你標記過的配方需要，也會一併保留，無論資料片怎麼勾選。這份清單直接讀自遊戲本身的配方，所以配方能接受的可選材料和每一個品質等級都已經在裡面了——你不需要開啟或掃描任何東西。"
L["rule:cosmetic"] = "未收藏的外觀"
L["rule:cosmeticSub"] = "你尚未收藏的時裝物品"
L["rule:cosmeticBlurb"] =
"尚未收藏的時裝物品會被保留。出售它並不會收藏其外觀——外觀會直接消失——所以這是整個視窗中唯一一處犯錯無法挽回的地方。已經收藏過的時裝物品不會僅僅因為它是時裝就被出售；它已經沒有需要保護的東西了，會繼續按照它本身是武器還是護甲來判定。"
L["rule:consumables"] = "消耗品"
L["rule:consumablesSub"] = "藥水、食物、卷軸、珍奇物品"
L["rule:consumablesBlurb"] =
"為每種消耗品選擇要保留的內容。沒有勾選任何選項的會被出售。"
L["rule:bags"] = "背包"
L["rule:bagsSub"] = "各種容器"
L["rule:bagsBlurb"] =
"永不出售。攜帶哪些背包由你自己決定，所以 Dispatch 不會對它們做判定。"
L["rule:gear"] = "武器與護甲"
L["rule:gearSub"] = "根據你已裝備的物品來判定"
L["rule:gearBlurb"] =
"同一套設定同時判定這兩類裝備。每件武器和每件護甲都會按順序接受下面這些問題的檢驗，第一個回答「保留」的問題就此定案。"
L["rule:gems"] = "寶石"
L["rule:gemsSub"] = "鑲嵌寶石與神器遺物"
L["rule:gemsBlurb"] =
"同一套選項適用於每一種寶石。神器遺物在下方有自己單獨的選項，因為寶石種類本身的其他方面都不會影響它是否值得保留。"
L["rule:tradeGoods"] = "貿易物品"
L["rule:tradeGoodsSub"] = "按專業分類的製作材料"
L["rule:tradeGoodsBlurb"] =
"選擇要為誰保留材料。沒有留存的都會被出售——不過你自己專業真正會用到的材料，已經由上面的「製作材料」規則保留了。"
L["rule:enhancements"] = "物品強化"
L["rule:enhancementsSub"] = "附魔、油、石頭"
L["rule:enhancementsBlurb"] =
"新資料片會限制這些強化能用在哪些裝備上，所以舊的強化就不再有價值。請勾選你實際穿著裝備所屬的每個資料片，包括本資料片——現在不會再自動保留任何強化。"
L["rule:recipes"] = "配方"
L["rule:recipesSub"] = "圖樣、圖紙、公式"
L["rule:recipesBlurb"] =
"配方本身就帶著它所屬的專業，因此一到商人這裡就會被判定。不屬於任何一個專業的配方——通用的圖樣或手冊——沒有可供判定的依據，會被放過不管。"
L["rule:misc"] = "其他"
L["rule:miscSub"] = "寵物、坐騎、玩具、節慶物品"
L["rule:miscBlurb"] =
"法術材料不會被處理。在未分類的零碎物品中，只有玩具會被判定：一旦它已經在你的收藏中，且背包裡的這一份已經綁定，就會被出售。灰色物品由上面的「粗糙品質」規則處理，不在這裡。"
L["rule:profession"] = "專業裝備"
L["rule:professionSub"] = "工具與配件"
L["rule:professionBlurb"] =
"永不出售。可交易的值錢，而綁定的要嘛是你為自己製作的，要嘛正在使用中，所以沒有任何情況適合把它賣掉。"
L["rule:housing"] = "房屋"
L["rule:housingSub"] = "裝飾品與染料"
L["rule:housingBlurb"] =
"一旦某件裝飾品被收藏，物品本身就沒有進一步用途了，因此可以賣給商人。染料完全不是這類東西：它是一次性消耗品，使用後就用完了，所以既沒有可收藏的內容，也沒有可學習的內容。它也從不綁定，所以唯一值得問的問題是它是否還能送到想要它的人手上。"
L["rule:none"] = "其餘全部"
L["rule:noneSub"] = "任務物品、鑰匙、雕文、代幣"
L["rule:noneBlurb"] =
"Dispatch 完全不判定的物品類型：任務物品、鑰匙、籠中寵物、雕文、WoW 代幣、法術材料、箭矢，以及其他已停用的類別。無論上面的規則如何設定，它們都會留在你的背包裡。"

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "此報告包含物品連結及其其他數據、BitForge 得出的判定以及決定該判定的規則、你自己是否把這件物品加入了黑名單或白名單、你在該物品所占欄位上目前裝備的物品，以及判定這一對比時用到的設定。物品連結會寫明你角色的等級和專精 -- 這是連結本身格式的一部分，拿掉它就會失去讓報告得以重現的細節。這裡不會寫出你角色的名字、所在伺服器、公會或陣營，也不會描述任何其他欄位。"

-- The disenchant scan's own footnote: it discloses several bag items and
-- their tooltips, not the single item/link pair report:blurbSell describes.
L["report:blurbDisenchant"] = "此報告包含客戶端目前的法術索敵狀態，以及本角色是否能夠分解物品。此報告還包含你背包裡最多八件可能值得分解的武器和護甲，每件都附帶它的背包與格子、物品 ID、名稱、品質、物品類型，以及 BitForge 自己對該物品是否能夠分解所做的預測，另加完整的提示文字。對於品質無法讀取的其他任何背包物品，此報告也會說明該物品的背包、格子、物品 ID 和名稱。這裡不會寫出你角色的名字、所在伺服器、公會或陣營。"
L["report:blurbDispatch"] = "此報告包含物品的連結和品質、當你攜帶該物品時它是從哪個背包和欄位得到答案的、每條規則路徑為該物品得出的判定 -- 它自身附帶的額外細節，以及它是否來自已儲存的例外設定 -- 以及各條路徑自身的主張、強度和理由，包括其中任何完全無法作答的路徑。當物品品質為粗糙時，本報告還會說明，根據你自己的出售設定和垃圾規則設定，暴雪自身的「出售垃圾物品」功能是否仍會將其賣出。當物品是製作材料時，本報告還會寫明隨插件附帶的材料表把它列為哪些專業的材料、此帳號已記錄的專業 -- 材料為靈魂綁定時則是目前角色的專業 -- 材料所屬的資料片以及你是否勾選了該資料片、你標記過的配方是否需要它，以及材料規則本身以其中哪一項作答 -- 那是材料規則自己的判定，並不總是決定該物品去向的那一條。它始終會列出你標記過的配方，寫明其 ID，遊戲還能給出名稱時也寫明名稱，因此它寫出的是你製作什麼，而不只是你隨身攜帶什麼。啟用診斷時，本報告還會寫明你當時所在的地圖以及包含它的上層地圖；若該物品被限定在特定地點，還會寫明該限定所列出的地點，以及其中哪一個與你當時所在之處相符。物品連結會寫明你角色的等級和專精 -- 這是連結自身格式的一部分，拿掉它就會失去讓報告得以重現的細節。這裡不會寫出你角色的名字、所在伺服器、公會或陣營。"

if GetLocale() ~= "zhTW" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

L["panel:batchSell"] = "批次出售"
L["panel:sellManifest"] = "出售清單"
L["panel:blacklist"] = "黑名單"
L["panel:whitelist"] = "白名單"

L["ui:ruleWindowTitle"] = "批次出售規則"
L["ui:ruleWindowNothingToConfigure"] = "這裡沒有可設定的內容。"
L["ui:ruleWindowDisclaimer"] =
"在戰鬥中和副本裡，遊戲有時不會透露物品的詳細資訊。BatchSell 會保留這些物品，而不是去猜測，所以清單中可能會缺少個別物品 -- 這是正常現象。如果某個判定因為其他原因看起來有問題，值得回報。"
L["ui:selectedCount"] = "已選擇：%d 個"

L["btn:sellAll"] = "全部出售"
L["btn:refresh"] = "重新整理"
L["btn:rules"] = "規則"

L["menu:temporaryExclude"] = "暫時排除"
L["menu:blacklisted"] = "黑名單"
L["menu:whitelisted"] = "白名單"
L["menu:noStatus"] = "無"
L["menu:reportVerdict"] = "回報此判定"

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
L["settings:margin"] = "物品等級邊際"
L["settings:marginTooltip"] =
"同品質的裝備比已裝備的低多少就會出售。設為 0 時只需與已裝備的持平"
L["settings:qualityMargin"] = "品質邊際"
L["settings:qualityMarginTooltip"] =
"一個品質等級折算多少物品等級。設為 10 時，比已裝備低一階的裝備只需高出 10 就能保留，高一階的裝備低 10 以內也能保留。設為 0 時品質不再計入，僅依物品等級判斷。設為「一律」時，品質更高的裝備無論物品等級如何都會保留，品質更低的裝備再高的物品等級也留不住"
L["settings:qualityMarginAlways"] = "一律"
L["settings:keepForDisenchant"] = "保留值得分解的裝備"
L["settings:keepForDisenchantTooltip"] = "保留附魔師能夠分解的裝備，依其能產出什麼來決定。來自已完結資料片的裝備產出的是該資料片的材料，這就是為什麼這裡選擇的是材料而不是裝備本身。你自己的附魔師無論此設定為何，都會保留只有他才能拿到的裝備——但這個設定仍然決定這是否也延伸到更舊的材料"
L["settings:spareBindOnAccount"] = "留存帳號綁定裝備"
L["settings:spareBindOnAccountTooltip"] = "帳號綁定裝備在還能傳給其他角色時保留哪些：本資料片的、全部、或不留存"
L["settings:spareBindOnEquip"] = "留存裝備後綁定裝備"
L["settings:spareBindOnEquipTooltip"] = "裝備後綁定裝備在還能給其他角色或拍賣場時保留哪些：本資料片的、全部、或不留存"
L["settings:reagentsCurrentOnly"] = "僅限本資料片的材料"
L["settings:reagentsCurrentOnlyTooltip"] = "把上面的規則收窄到本資料片的材料。想要傳統版草藥的配方今天依然一樣想要，所以除非你不願囤積舊材料，否則保持關閉"
L["settings:keepUncollectedCosmetic"] = "保留未收藏的外觀"
L["settings:keepUncollectedCosmeticTooltip"] = "保留任何你尚未收藏其外觀的物品。一般裝備賣給商人仍會收藏外觀，但時裝物品要使用才會給出外觀——賣掉它，那個外觀就永遠沒了"
L["settings:sellRelics"] = "出售傳統聖物"
L["settings:sellRelicsTooltip"] = "出售神像、聖契、圖騰與魔印——浩劫與重生移除的那個聖物欄位。不是軍團再臨的神兵遺物，後者屬於寶石，只是子類編號相同而已"
L["settings:gemsCurrent"] = "保留本資料片的寶石"
L["settings:gemsCurrentTooltip"] = "保留本資料片的寶石。更舊的寶石會落到下面兩個問題上"
L["settings:gemsRecipesNow"] = "保留配方需要的目前寶石"
L["settings:gemsRecipesNowTooltip"] = "保留任何專業配方當作材料使用的本資料片寶石，無論那個專業屬於誰。問題問的是配方目錄，目錄從未見過的寶石會被保留，而不是靠猜"
L["settings:gemsRecipesOld"] = "保留配方需要的舊寶石"
L["settings:gemsRecipesOldTooltip"] = "對過往資料片寶石提出同樣的問題。你自己專業要用的東西已經在別處保留了，所以這一項是為別人的配方準備的"
L["settings:keepArtifactRelics"] = "保留神兵遺物"
L["settings:keepArtifactRelicsTooltip"] = "保留鑲嵌在軍團再臨神兵武器上的遺物。軍團再臨之後再無用處，除非你專門收藏，否則值得關掉"
L["settings:enhancementsKeepLast"] = "保留上個資料片的強化物品"
L["settings:enhancementsKeepLastTooltip"] = "保留緊鄰上一個資料片的物品強化，給仍穿著那批裝備的角色使用。只提供這一個資料片——沒有人還在更早的資料片裡練級"
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

L["spare:current"] = "目前資料片"
L["spare:all"] = "全部"
L["spare:none"] = "不留存"

L["materials:current"] = "目前材料"
L["materials:all"] = "任何材料"
L["materials:none"] = "不保留"

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

L["option:current"] = "保留本資料片的全部"
L["option:lastExpansion"] = "上個資料片的也保留（還在那裡升級時）"
L["option:recipesNow"] = "保留本資料片的，除非沒有任何配方需要"
L["option:recipesOld"] = "保留更早的，除非沒有任何配方需要"

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
L["reason:ENHANCEMENT_CURRENT"] = "本資料片的物品強化被保留"
L["reason:ENHANCEMENT_LAST_EXPANSION"] = "上個資料片的物品強化被保留"
L["reason:ENHANCEMENT_OUTDATED"] = "以前資料片的物品強化被出售"
L["reason:CONSUMABLE_CURRENT"] = "本資料片的消耗品會被保留"
L["reason:CONSUMABLE_LAST_EXPANSION"] = "上個資料片的消耗品會被保留"
L["reason:CONSUMABLE_REAGENT"] = "某個配方需要將其作為材料"
L["reason:GEM_CURRENT"] = "本資料片的寶石會被保留"
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
"灰色物品，無論具體是哪種物品。預設關閉，因為這通常由其他外掛負責處理。如果沒有其他外掛處理，開啟這個選項，BatchSell 會替你清理它們。"
L["rule:epic"] = "傳說品質及以上"
L["rule:epicSub"] = "傳說、神器、傳家寶"
L["rule:epicBlurb"] =
"永不出售。商人會為這些物品顯示價格，隨後又拒絕這筆交易，因此 BatchSell 不會把它們列入清單。"
L["rule:reagent"] = "製作材料"
L["rule:reagentSub"] = "使用你的專業清單"
L["rule:reagentBlurb"] =
"保留本帳號任一專業可以使用的材料，無論它是哪種物品。材料既可能是藥水，也可能是寶石或貿易物品，所以這項判定在物品類型之前進行。這份清單直接讀自遊戲本身的配方，所以配方能接受的可選材料和每一個品質等級都已經在裡面了——你不需要開啟或掃描任何東西。"
L["rule:cosmetic"] = "未收藏的外觀"
L["rule:cosmeticSub"] = "你尚未收藏的時裝物品"
L["rule:cosmeticBlurb"] =
"尚未收藏的時裝物品會被保留。出售它並不會收藏其外觀——外觀會直接消失——所以這是整個視窗中唯一一處犯錯無法挽回的地方。已經收藏過的時裝物品不會僅僅因為它是時裝就被出售；它已經沒有需要保護的東西了，會繼續按照它本身是武器還是護甲來判定。"
L["rule:consumables"] = "消耗品"
L["rule:consumablesSub"] = "藥水、食物、卷軸、珍奇物品"
L["rule:consumablesBlurb"] =
"為每種消耗品選擇要保留的內容。沒有勾選任何選項的會被出售。藥水、增效藥、合劑和食物還有一個額外選項——上個資料片的也一樣——只有在你保留本資料片的同類物品時才會生效。"
L["rule:bags"] = "背包"
L["rule:bagsSub"] = "各種容器"
L["rule:bagsBlurb"] =
"永不出售。攜帶哪些背包由你自己決定，所以 BatchSell 不會對它們做判定。"
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
"新資料片會限制這些強化能用在哪些裝備上，所以舊的強化就不再有價值。本資料片的會被保留，如果你願意，上個資料片的也可以保留。"
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
"BatchSell 完全不判定的物品類型：任務物品、鑰匙、籠中寵物、雕文、WoW 代幣、法術材料、箭矢，以及其他已停用的類別。無論上面的規則如何設定，它們都會留在你的背包裡。"

-- The report window's footnote. What BatchSell discloses is not what Openables
-- discloses, so each module states its own.
L["report:blurb"] = "此報告包含物品連結、你在該物品所占欄位上目前裝備的物品，以及判定這一對比時用到的設定。物品連結會寫明你角色的等級和專精 -- 這是連結本身格式的一部分，拿掉它就會失去讓報告得以重現的細節。這裡不會寫出你角色的名字、所在伺服器、公會或陣營，也不會描述任何其他欄位。"

-- The disenchant scan's own footnote: it discloses several bag items and
-- their tooltips, not the single item/link pair report:blurb describes.
L["report:blurbDisenchant"] = "此報告包含你背包裡最多八件可能值得分解的武器和護甲，以及各自所在的背包欄位和完整的提示文字。這裡不會寫出你角色的名字、所在伺服器、公會或陣營，也不會描述你背包裡的其他任何東西。"

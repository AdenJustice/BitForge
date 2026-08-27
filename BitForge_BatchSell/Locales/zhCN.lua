if GetLocale() ~= "zhCN" then return end
---@class BitForge.BatchSell
local ns = select(2, ...)
local L = ns.locale

L["panel:batchSell"] = "批量出售"
L["panel:sellManifest"] = "出售清单"
L["panel:blacklist"] = "黑名单"
L["panel:whitelist"] = "白名单"

L["ui:ruleWindowTitle"] = "批量出售规则"
L["ui:ruleWindowNothingToConfigure"] = "这里没有可配置的内容。"
L["ui:ruleWindowDisclaimer"] =
"在战斗中和副本里，游戏有时不会透露物品的详细信息。BatchSell 会保留这些物品，而不是去猜测，所以清单中可能会缺少个别物品 -- 这是正常现象。如果某个判定因为其他原因看起来有问题，值得反馈。"
L["ui:selectedCount"] = "已选择：%d 个"

L["btn:sellAll"] = "全部出售"
L["btn:refresh"] = "刷新"
L["btn:rules"] = "规则"

L["menu:temporaryExclude"] = "暂时排除"
L["menu:blacklisted"] = "黑名单"
L["menu:whitelisted"] = "白名单"
L["menu:noStatus"] = "无"
L["menu:reportVerdict"] = "反馈此判定"

L["status:noItemsToSell"] = "没有可出售的物品"
L["status:itemsTotal"] = "%d 件物品  |  合计：%s"

L["ui:manifestHint"] = "期望的物品没有出现在列表中？将鼠标悬停在背包中的该物品上查看原因。"

-- Merchant row
L["tooltip:charOverride"] = "此角色的设置优先于战团名单——该物品将被出售。"

L["section:general"] = "常规"
L["section:lists"] = "名单"
L["section:everyItem"] = "所有物品"
L["section:byItemType"] = "按物品类型"

L["settings:openRuleWindow"] = "查看规则"
L["settings:openRuleWindowTooltip"] =
"说明每条规则检查的内容，以及物品被保留或出售的原因"
L["settings:sellJunk"] = "出售垃圾"
L["settings:sellJunkTooltip"] = "访问商人时自动出售所有粗糙品质（灰色）物品"
L["settings:limitBatch"] = "每批限制12件"
L["settings:limitBatchTooltip"] = "每次点击最多出售12件物品以避免服务器限速"
L["settings:keepUsedReagents"] = "保留专业所需材料"
L["settings:keepUsedReagentsTooltip"] =
"保留此账号任一专业可使用的制作材料。灵魂绑定的材料无法交给其他角色，因此只有当前角色的专业才会保留它"
L["settings:margin"] = "物品等级余量"
L["settings:marginTooltip"] =
"同品质的装备比已装备的低多少就会出售。设为 0 时只需与已装备的持平"
L["settings:qualityMargin"] = "品质余量"
L["settings:qualityMarginTooltip"] =
"一个品质等级折算多少物品等级。设为 10 时，比已装备低一档的装备只需高出 10 就能保留，高一档的装备低 10 以内也能保留。设为 0 时品质不再计入，仅按物品等级判断。设为“始终”时，品质更高的装备无论物品等级如何都会保留，品质更低的装备再高的物品等级也保不住"
L["settings:qualityMarginAlways"] = "始终"
L["settings:keepForDisenchant"] = "保留值得分解的装备"
L["settings:keepForDisenchantTooltip"] = "保留附魔师能够分解的装备，按其能产出什么来决定。来自已完结资料片的装备产出的是那个资料片的材料，这就是为什么这里选择的是材料而不是装备本身。你自己的附魔师无论此设置如何，都会保留只有他才能拿到的装备——但这个设置仍然决定这是否也延伸到更旧的材料"
L["settings:spareBindOnAccount"] = "留存绑定账号装备"
L["settings:spareBindOnAccountTooltip"] = "账号绑定装备在还能传给其他角色时保留哪些：本资料片的、全部、或不留存"
L["settings:spareBindOnEquip"] = "留存装备后绑定装备"
L["settings:spareBindOnEquipTooltip"] = "装备后绑定装备在还能给其他角色或拍卖行时保留哪些：本资料片的、全部、或不留存"
L["settings:reagentsCurrentOnly"] = "仅限本资料片的材料"
L["settings:reagentsCurrentOnlyTooltip"] = "把上面的规则收窄到本资料片的材料。想要经典旧世草药的配方今天依旧一样想要，所以除非你不愿囤积旧材料，否则保持关闭"
L["settings:keepUncollectedCosmetic"] = "保留未收藏的外观"
L["settings:keepUncollectedCosmeticTooltip"] = "保留任何你尚未收藏其外观的物品。普通装备卖给商人仍会收藏外观，但时装物品要使用才会给出外观——卖掉它，那个外观就永远没了"
L["settings:sellRelics"] = "出售经典圣物"
L["settings:sellRelicsTooltip"] = "出售神像、圣契、图腾与魔印——大地的裂变移除的那个圣物栏位。不是军团再临的神器遗物，后者属于宝石，只是子类编号相同而已"
L["settings:gemsCurrent"] = "保留本资料片的宝石"
L["settings:gemsCurrentTooltip"] = "保留本资料片的宝石。更旧的宝石会落到下面两个问题上"
L["settings:gemsRecipesNow"] = "保留配方需要的当前宝石"
L["settings:gemsRecipesNowTooltip"] = "保留任何专业配方当作材料使用的本资料片宝石，无论那个专业属于谁。问题问的是配方目录，目录从未见过的宝石会被保留，而不是靠猜"
L["settings:gemsRecipesOld"] = "保留配方需要的旧宝石"
L["settings:gemsRecipesOldTooltip"] = "对过往资料片宝石提出同样的问题。你自己专业要用的东西已经在别处保留了，所以这一项是为别人的配方准备的"
L["settings:keepArtifactRelics"] = "保留神器遗物"
L["settings:keepArtifactRelicsTooltip"] = "保留镶嵌在军团再临神器武器上的遗物。军团再临之后再无用处，除非你专门收藏，否则值得关掉"
L["settings:enhancementsKeepLast"] = "保留上个资料片的强化物品"
L["settings:enhancementsKeepLastTooltip"] = "保留紧邻上一个资料片的物品强化，给仍穿着那批装备的角色使用。只提供这一个资料片——没有人还在更早的资料片里升级"
L["settings:keepLearnable"] = "保留可以学习的配方"
L["settings:keepLearnableTooltip"] = "保留这个角色尚未学会的配方"
L["settings:keepTradeableRecipes"] = "保留可交易的配方"
L["settings:keepTradeableRecipesTooltip"] = "保留仍未绑定的配方，这样即使这个角色已经学会，它也能送给小号或上拍卖行"
L["settings:sellCollectedMounts"] = "出售已收藏的坐骑"
L["settings:sellCollectedMountsTooltip"] = "出售你已经拥有的坐骑，前提是这一份已经灵魂绑定。未绑定的一份无论这里怎么设置都会保留，因为它还能到想要的人手里"
L["settings:sellCollectedToys"] = "出售已收藏的玩具"
L["settings:sellCollectedToysTooltip"] = "出售你已经拥有的玩具，前提是背包里的这一份已经绑定。未绑定的一份无论你的收藏情况如何都会保留，因为它还能到想要的人手里"
L["settings:sellCollectedPets"] = "出售已收藏的宠物"
L["settings:sellCollectedPetsTooltip"] = "出售你已经拥有的战斗宠物。从未收藏过的宠物，无论怎么设置这条规则都不会卖"
L["settings:sellHoliday"] = "出售节日物品"
L["settings:sellHolidayTooltip"] = "出售世界活动留在你背包里的代币、服装与杂物"
L["settings:sellMountEquipment"] = "出售坐骑装备"
L["settings:sellMountEquipmentTooltip"] = "出售坐骑装备。同一时间整个账号只有一件生效，所以背包里的备用件毫无作用"
L["settings:sellCollectedDecor"] = "出售已收藏的装饰品"
L["settings:sellCollectedDecorTooltip"] = "出售你的图鉴中已有的住宅装饰品。图鉴从未见过的装饰品会保留，读不到图鉴的那一件同样保留"
L["settings:keepTradeableDyes"] = "保留可交易的染料"
L["settings:keepTradeableDyesTooltip"] = "染料在涂上时被消耗，从不学习，因此没有收藏可问。改问的是这一份是否还能到某个人手里：未绑定则保留，已绑定则出售"
L["settings:spareProfessions"] = "留存这些专业"
L["settings:spareProfessionsTooltip"] =
"如果这里勾选的任一专业可能会用它作为材料，就保留该贸易物品——用于尚未学会该专业的小号，或用于拍卖行。本账号自己的专业已经由“保留专业所需材料”覆盖"

L["spare:current"] = "当前资料片"
L["spare:all"] = "全部"
L["spare:none"] = "不留存"

L["materials:current"] = "当前材料"
L["materials:all"] = "任何材料"
L["materials:none"] = "不保留"

L["profession:FirstAid"] = "急救"
L["profession:Blacksmithing"] = "锻造"
L["profession:Leatherworking"] = "制皮"
L["profession:Alchemy"] = "炼金术"
L["profession:Herbalism"] = "草药学"
L["profession:Cooking"] = "烹饪"
L["profession:Mining"] = "采矿"
L["profession:Tailoring"] = "裁缝"
L["profession:Engineering"] = "工程学"
L["profession:Enchanting"] = "附魔"
L["profession:Fishing"] = "钓鱼"
L["profession:Skinning"] = "剥皮"
L["profession:Jewelcrafting"] = "珠宝加工"
L["profession:Inscription"] = "铭文"
L["profession:Archaeology"] = "考古学"

L["sub:0"] = "通用"
L["sub:1"] = "药水"
L["sub:2"] = "增效药"
L["sub:3"] = "合剂和药瓶"
L["sub:5"] = "食物和饮料"
L["sub:7"] = "绷带"
L["sub:8"] = "其它"
L["sub:9"] = "优势符文"

L["option:current"] = "保留本资料片的全部"
L["option:lastExpansion"] = "上个资料片的也保留（还在那里升级时）"
L["option:recipesNow"] = "保留本资料片的，除非没有任何配方需要"
L["option:recipesOld"] = "保留更早的，除非没有任何配方需要"

-- List tabs
L["btn:removeEntry"] = "移除"
L["list:warband"] = "战团"
L["list:character"] = "角色"
L["status:listEmpty"] = "此名单为空"
L["status:listCount"] = "%d 条目"

-- Tooltip verdict. One reason per enum.RULE value; the mapping is total, and
-- tests/test_batchsell_tooltip.lua iterates the enum to prove it stays total.
L["verdict:sell"] = "批量出售：将被出售"
L["verdict:keep"] = "批量出售：将被保留"
L["reason:TEMP_EXCLUDED"] = "本次商人访问中已排除"
L["reason:BLACKLISTED"] = "在你的黑名单中"
L["reason:LOCKED"] = "该物品已锁定"
L["reason:EQUIPMENT_SET"] = "属于套装的一部分"
L["reason:NO_SELL_PRICE"] = "没有商人会购买它"
L["reason:REFUNDABLE"] = "仍在退款期限内"
L["reason:WHITELISTED"] = "在你的白名单中"
L["reason:TEMP_INCLUDED"] = "本次商人访问中已加入"
L["reason:JUNK"] = "“出售垃圾”已关闭，垃圾物品不予处理"
L["reason:JUNK_SOLD"] = "“出售垃圾”已开启，垃圾物品将被出售"
L["reason:ABOVE_EPIC"] = "品质高于史诗，因此永不出售"
L["reason:BIND_ON_ACCOUNT"] = "绑定账号的装备会被保留"
L["reason:DISENCHANTABLE"] = "值得保留以便分解或转售"
L["reason:BAG_KEPT"] = "背包永不出售"
L["reason:PROFESSION_GEAR_KEPT"] = "专业装备永不出售"
L["reason:ENHANCEMENT_CURRENT"] = "本资料片的物品强化被保留"
L["reason:ENHANCEMENT_LAST_EXPANSION"] = "上个资料片的物品强化被保留"
L["reason:ENHANCEMENT_OUTDATED"] = "以前资料片的物品强化被出售"
L["reason:CONSUMABLE_CURRENT"] = "本资料片的消耗品会被保留"
L["reason:CONSUMABLE_LAST_EXPANSION"] = "上个资料片的消耗品会被保留"
L["reason:CONSUMABLE_REAGENT"] = "某个配方需要将其作为材料"
L["reason:GEM_CURRENT"] = "本资料片的宝石会被保留"
L["reason:GEM_REAGENT"] = "某个配方需要将其作为材料"
L["reason:GEM_ARTIFACT_RELIC_KEPT"] = "神器遗物会被保留"
L["reason:TRADE_GOOD_SPARED"] = "你选择留存的专业想要它"
L["reason:NOT_WANTED"] = "没有选项保留它，因此予以出售"
L["reason:REAGENT_WANTED"] = "能够使用它的专业需要该材料"
L["reason:NOT_EQUIPPABLE"] = "你的职业无法装备或不推荐使用"
L["reason:EQUIPPABLE"] = "相对于已装备的装备而言足够好"
L["reason:OUTCLASSED"] = "不如已装备的装备"
L["reason:OUTDATED_EXPAC"] = "优于你当前装备的上个资料片物品"
L["reason:BIND_ON_EQUIP"] = "装备后绑定的物品会被保留"
L["reason:ARMOR_RELIC"] = "已无人能装备圣物，因此予以出售"
L["reason:RECIPE_LEARNABLE"] = "尚未学会，因此予以保留"
L["reason:HOLIDAY_ITEM"] = "节日物品会被出售"
L["reason:MOUNT_EQUIPMENT"] = "坐骑装备会被出售"
L["reason:ALREADY_COLLECTED"] = "已经收藏，因此予以出售"
L["reason:NOT_COLLECTED"] = "尚未收藏，因此予以保留"
L["reason:STILL_TRADEABLE"] = "仍可交易，因此予以保留"
L["reason:ALREADY_LEARNED"] = "已经学会，因此予以出售"
L["reason:DEFAULT"] = "没有规则认领它，因此予以保留"

L["listReset:warbandBlacklist"] = "重置战团黑名单"
L["listReset:warbandWhitelist"] = "重置战团白名单"
L["listReset:charBlacklist"] = "重置角色黑名单"
L["listReset:charWhitelist"] = "重置角色白名单"
L["listReset:confirm"] = "确定要清空此名单吗？此操作无法撤销。"

-- Chat messages. Printed through BitForge:Print, which prefixes [BitForge].
L["msg:dropRefused"] = "目前无法出售%s：%s"
L["msg:dropUnexcluded"] = "%s不再被排除，将于本次访问中出售"

-- Rule window detail pane. One title/sub/blurb triple per
-- ns.view.ruleDescriptors entry, keyed by the descriptor's own `key`.
L["rule:temp"] = "暂时排除"
L["rule:tempSub"] = "仅限本次商人访问"
L["rule:tempBlurb"] =
"在点击出售前从出售清单中移除的物品。它们会在本次访问中留在背包里，下次拜访商人时将再次正常判定。"
L["rule:black"] = "永不出售"
L["rule:blackSub"] = "你的永不出售名单"
L["rule:blackBlurb"] =
"永不出售名单中的物品会留在背包里。当角色与战团名单意见不一致时，以本角色的设置为准。"
L["rule:gates"] = "无法出售"
L["rule:gatesSub"] = "商人不会收购这些"
L["rule:gatesBlurb"] =
"已锁定的物品、属于套装的物品、没有售价的物品，以及仍在退款期内的购买记录。你的永远出售名单不会覆盖这些，因为商人无论如何都会拒绝这笔交易。"
L["rule:white"] = "永远出售"
L["rule:whiteSub"] = "你的永远出售名单"
L["rule:whiteBlurb"] =
"永远出售名单中的物品会被出售，即使后面的规则原本会保留它。这就是你出售那一件不想要的制作材料的方法。"
L["rule:tempIn"] = "本次加入出售"
L["rule:tempInSub"] = "仅限本次商人访问"
L["rule:tempInBlurb"] =
"你在这位商人处拖入出售清单的物品。它们会在本次访问中被出售，下次拜访时会再次正常判定。"
L["rule:junk"] = "粗糙品质"
L["rule:junkSub"] = "默认关闭"
L["rule:junkBlurb"] =
"灰色物品，无论具体是哪种物品。默认关闭，因为这通常由其他插件负责处理。如果没有其他插件处理，打开这个选项，BatchSell 会替你清理它们。"
L["rule:epic"] = "传说品质及以上"
L["rule:epicSub"] = "传说、神器、传家宝"
L["rule:epicBlurb"] =
"永不出售。商人会为这些物品显示价格，随后又拒绝这笔交易，因此 BatchSell 不会把它们列入清单。"
L["rule:reagent"] = "制作材料"
L["rule:reagentSub"] = "使用你的专业清单"
L["rule:reagentBlurb"] =
"保留本账号任一专业可以使用的材料，无论它是哪种物品。材料既可能是药水，也可能是宝石或贸易物品，所以这项判定在物品类型之前进行。这份清单直接读自游戏本身的配方，所以配方能接受的可选材料和每一个品质等级都已经在里面了——你不需要打开或扫描任何东西。"
L["rule:cosmetic"] = "未收藏的外观"
L["rule:cosmeticSub"] = "你尚未收藏的时装物品"
L["rule:cosmeticBlurb"] =
"尚未收藏的时装物品会被保留。出售它并不会收藏其外观——外观会直接消失——所以这是整个窗口中唯一一处犯错无法挽回的地方。已经收藏过的时装物品不会仅仅因为它是时装就被出售；它已经没有需要保护的东西了，会继续按照它本身是武器还是护甲来判定。"
L["rule:consumables"] = "消耗品"
L["rule:consumablesSub"] = "药水、食物、卷轴、珍奇物品"
L["rule:consumablesBlurb"] =
"为每种消耗品选择要保留的内容。没有勾选任何选项的会被出售。药水、增效药、合剂和食物还有一个额外选项——上个资料片的也一样——只有在你保留本资料片的同类物品时才会生效。"
L["rule:bags"] = "背包"
L["rule:bagsSub"] = "各种容器"
L["rule:bagsBlurb"] =
"永不出售。携带哪些背包由你自己决定，所以 BatchSell 不会对它们做判定。"
L["rule:gear"] = "武器与护甲"
L["rule:gearSub"] = "根据你已装备的物品来判定"
L["rule:gearBlurb"] =
"同一套设置同时判定这两类装备。每件武器和每件护甲都会按顺序接受下面这些问题的检验，第一个回答“保留”的问题就此定案。"
L["rule:gems"] = "宝石"
L["rule:gemsSub"] = "镶嵌宝石与神器遗物"
L["rule:gemsBlurb"] =
"同一套选项适用于每一种宝石。神器遗物在下方有自己单独的选项，因为宝石种类本身的其他方面都不会影响它是否值得保留。"
L["rule:tradeGoods"] = "贸易物品"
L["rule:tradeGoodsSub"] = "按专业分类的制作材料"
L["rule:tradeGoodsBlurb"] =
"选择要为谁保留材料。没有留存的都会被出售——不过你自己专业真正会用到的材料，已经由上面的“制作材料”规则保留了。"
L["rule:enhancements"] = "物品强化"
L["rule:enhancementsSub"] = "附魔、油、石头"
L["rule:enhancementsBlurb"] =
"新资料片会限制这些强化能用在哪些装备上，所以旧的强化就不再有价值。本资料片的会被保留，如果你愿意，上个资料片的也可以保留。"
L["rule:recipes"] = "配方"
L["rule:recipesSub"] = "图样、图纸、公式"
L["rule:recipesBlurb"] =
"配方本身就带着它所属的专业，因此一到商人这里就会被判定。不属于任何一个专业的配方——通用的图样或手册——没有可供判定的依据，会被放过不管。"
L["rule:misc"] = "其他"
L["rule:miscSub"] = "宠物、坐骑、玩具、节日物品"
L["rule:miscBlurb"] =
"法术材料不会被处理。在未分类的零碎物品中，只有玩具会被判定：一旦它已经在你的收藏中，且背包里的这一份已经绑定，就会被出售。灰色物品由上面的“粗糙品质”规则处理，不在这里。"
L["rule:profession"] = "专业装备"
L["rule:professionSub"] = "工具与配件"
L["rule:professionBlurb"] =
"永不出售。可交易的值钱，而绑定的要么是你为自己制作的，要么正在使用中，所以没有任何情况适合把它卖掉。"
L["rule:housing"] = "房屋"
L["rule:housingSub"] = "装饰品与染料"
L["rule:housingBlurb"] =
"一旦某件装饰品被收藏，物品本身就没有进一步用途了，因此可以卖给商人。染料完全不是这类东西：它是一次性消耗品，使用后就用完了，所以既没有可收藏的内容，也没有可学习的内容。它也从不绑定，所以唯一值得问的问题是它是否还能送到想要它的人手上。"
L["rule:none"] = "其余全部"
L["rule:noneSub"] = "任务物品、钥匙、雕文、代币"
L["rule:noneBlurb"] =
"BatchSell 完全不判定的物品类型：任务物品、钥匙、笼中宠物、雕文、WoW 代币、法术材料、箭矢，以及其他已停用的类别。无论上面的规则如何设置，它们都会留在你的背包里。"

-- The report window's footnote. What BatchSell discloses is not what Openables
-- discloses, so each module states its own.
L["report:blurb"] = "此报告包含物品链接、你在该物品所占栏位上当前装备的物品，以及判定这一对比时用到的设置。物品链接会写明你角色的等级和专精 -- 这是链接自身格式的一部分，去掉它就会丢失让报告可以重现的细节。这里不会写出你角色的名字、所在服务器、公会或阵营，也不会描述任何其他栏位。"

-- The disenchant scan's own footnote: it discloses several bag items and
-- their tooltips, not the single item/link pair report:blurb describes.
L["report:blurbDisenchant"] = "此报告包含你背包里最多八件可能值得分解的武器和护甲，以及各自所在的背包栏位和完整的提示文字。这里不会写出你角色的名字、所在服务器、公会或阵营，也不会描述你背包里的其他任何东西。"

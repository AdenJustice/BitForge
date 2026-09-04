if GetLocale() ~= "zhCN" then return end
---@class BitForge.AzerothPrime
local ns = select(2, ...)
local L = ns.locale

-- Settings panel
L["panel:title"] = "AzerothPrime"
L["settings:openEnabled"] = "启用可开启物品按钮"
L["settings:openEnabledTooltip"] = "显示一个按钮，指向背包中下一件可开启或可使用的物品"
L["settings:sellEnabled"] = "启用向商人出售"
L["settings:sellEnabledTooltip"] = "打开商人窗口时出售规则选中的物品。在你设置规则之前不会出售任何东西"
L["settings:bankEnabled"] = "启用存入战团银行"
L["settings:bankEnabledTooltip"] = "当你访问银行时，存入材料、小号需要的配方，以及你指定的物品"

-- Leftover-install guard
L["msg:replacedInstalled"] = "AzerothPrime：已停用 %s，此插件已将其取代。"
L["msg:replacedInstalledFix"] = "删除旧的安装文件夹即可不再看到此消息。"

-- Openables button
L["settings:locked"] = "锁定按钮"
L["settings:lockedTooltip"] = "禁止拖动按钮"
L["settings:buttonSize"] = "按钮大小"
L["settings:buttonSizeTooltip"] = "按钮的宽度和高度，以像素为单位"
L["settings:showCount"] = "显示数量"
L["settings:showCountTooltip"] = "显示你携带的该物品数量"
L["settings:showCooldown"] = "显示冷却"
L["settings:showCooldownTooltip"] = "在按钮上显示冷却时间"
L["settings:resetPosition"] = "重置位置"
L["settings:manageBlacklist"] = "管理排除列表"

L["tooltip:use"] = "左键点击以开启或使用。"
L["tooltip:skip"] = "右键点击以在本次登录期间跳过。"
L["tooltip:blacklist"] = "Ctrl + 右键点击以永久排除。"
L["tooltip:report"] = "Shift + Alt + 右键点击以反馈此判定。"
L["tooltip:drag"] = "Alt + 拖动以移动。"

L["report:blurbOpen"] = "这份报告包含物品、它的背包与格子以及是否被锁定、BitForge 对它的分类方式、它的提示文字，以及本角色已知的专业。这里不会写出你角色的名字、所在服务器、公会或阵营。"

L["blacklist:windowTitle"] = "已排除的物品"
L["blacklist:empty"] = "没有已排除的物品。"
L["blacklist:remove"] = "移除"
L["blacklist:clearAll"] = "全部清除"
L["blacklist:unknownItem"] = "物品 %d"

L["binding:header"] = "BitForge AzerothPrime"
L["binding:use"] = "使用可开启物品"

L["settings:previewMoves"] = "存入前预览"
L["settings:previewMovesTooltip"] = "在存入任何物品之前，显示列出全部移动操作的确认窗口"
L["settings:onlyWantedReagents"] = "仅存入可使用的材料"
L["settings:onlyWantedReagentsTooltip"] = "仅存入此账号任一专业能用于制作的材料。关闭则存入全部材料，供拍卖行使用"

L["btn:deposit"] = "存入"
L["btn:depositing"] = "正在存入… %d"

L["preview:title"] = "确认存入"
L["preview:summary"] = "%d 件物品，共 %d 次移动"
L["preview:toWarband"] = "→ 战团银行"
L["preview:dontAskAgain"] = "不再询问"
L["btn:confirm"] = "确认"
L["btn:cancel"] = "取消"

L["msg:nothingToDo"] = "AzerothPrime：没有需要移动的物品。"
L["msg:done"] = "AzerothPrime：完成。已移动 %d 件物品。"
L["msg:noVacancy"] = "AzerothPrime：战团银行已满。"
L["msg:blockedCombat"] = "AzerothPrime：已停止 — 你正在战斗中。"
L["msg:blockedBankClosed"] = "AzerothPrime：已停止 — 银行已关闭。"
L["msg:blockedCursor"] = "AzerothPrime：已停止 — 光标上有物品。"
L["msg:blockedLocked"] = "AzerothPrime：已停止 — 物品已锁定。"
L["msg:moveFailed"] = "AzerothPrime：已停止 — 移动未能完成。"
L["msg:openProfession"] = "AzerothPrime：请打开一次%s窗口，以便 AzerothPrime 记录你已学会的配方。"

-- Curation window
L["curation:title"] = "物品整理"
L["curation:open"] = "整理物品"
L["curation:search"] = "搜索"
L["curation:filterDestination"] = "任意去向"
L["curation:filterClass"] = "任意物品类型"
L["curation:source"] = "数据来源：%s"
L["curation:sourceBuiltIn"] = "当前角色"
L["curation:count"] = "共 %d 件物品"
L["curation:unscanned"] = "从未扫描过配方：%s。在扫描之前，其专业的所有配方都会被视为需要并存入银行。"
L["curation:heldBy"] = "持有角色"
L["curation:overrideTooltip"] = "该去向由你指定。恢复默认后将重新按规则判断。"

-- Destinations
L["dest:warband"] = "战团银行"
L["dest:private"] = "个人银行"
L["dest:privateOwned"] = "个人银行（%s）"
L["dest:ignore"] = "保持不动"

-- Private destination
L["preview:toPrivate"] = "→ 个人银行"
L["preview:reclaim"] = "战团银行 → 个人银行"
L["msg:noVacancyPrivate"] = "AzerothPrime：你的银行已满。"
L["curation:privateTooltip"] = "存放在角色自己的银行中，而非共享仓库。未指定归属角色时，最先访问银行的角色将取走它。"

-- Target quantity
L["curation:targetSuffix"] = "保留 %d"
L["target:title"] = "目标数量"
L["target:prompt"] = "每位归属角色应保留多少个%s？"

-- Row menu
L["menu:resetToDefault"] = "恢复默认"
L["menu:owners"] = "归属角色"
L["menu:target"] = "目标数量"
L["menu:targetNone"] = "不限制"
L["menu:targetOther"] = "其他…"

L["panel:batchSell"] = "批量出售"
L["panel:sellManifest"] = "出售清单"
L["panel:blacklist"] = "黑名单"
L["panel:whitelist"] = "白名单"

L["ui:ruleWindowTitle"] = "批量出售规则"
L["ui:ruleWindowNothingToConfigure"] = "这里没有可配置的内容。"
L["ui:ruleWindowDisclaimer"] =
"在战斗中和副本里，游戏有时不会透露物品的详细信息。AzerothPrime 会保留这些物品，而不是去猜测，所以清单中可能会缺少个别物品 -- 这是正常现象。如果某个判定因为其他原因看起来有问题，值得反馈。"
L["ui:selectedCount"] = "已选择：%d 个"
L["ui:reagentsNoProfession"] =
"本账号还没有任何角色拥有专业，所以这条规则什么也不会保留。用一个有专业的角色登录，这些设置就会恢复。"

L["btn:sellAll"] = "全部出售"
L["btn:refresh"] = "刷新"
L["btn:rules"] = "规则"

L["menu:temporaryExclude"] = "暂时排除"
L["menu:blacklisted"] = "黑名单"
L["menu:whitelisted"] = "白名单"
L["menu:noStatus"] = "无"
L["menu:reportVerdict"] = "反馈此判定"

-- Recipe row menu, in the professions window
L["menu:markRecipeReagents"] = "标记该配方的材料"

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
L["settings:reagentsExpansions"] = "保留哪些材料"
L["settings:reagentsExpansionsTooltip"] =
"上面的规则保留哪些资料片的材料。默认只勾选当前资料片，所以更早的材料会被列入出售——但你标记过的配方仍然需要的材料除外，无论这里怎么勾选都会保留"
L["settings:margin"] = "物品等级余量"
L["settings:marginTooltip"] =
"同品质的装备比已装备的低多少就会出售。设为 0 时只需与已装备的持平"
L["settings:qualityMargin"] = "品质余量"
L["settings:qualityMarginTooltip"] =
"一个品质等级折算多少物品等级。设为 10 时，比已装备低一档的装备只需高出 10 就能保留，高一档的装备低 10 以内也能保留。设为 0 时品质不再计入，仅按物品等级判断。设为“始终”时，品质更高的装备无论物品等级如何都会保留，品质更低的装备再高的物品等级也保不住"
L["settings:qualityMarginAlways"] = "始终"
L["settings:keepForDisenchant"] = "按产出材料的资料片保留装备"
L["settings:keepForDisenchantTooltip"] = "保留附魔师能够分解的装备，依据的是它会产出的材料属于哪个资料片，而不是装备本身的新旧——来自已完结资料片的装备，产出的正是那个资料片的材料。你自己的附魔师无论此设置如何，都会保留只有他才能拿到的装备，但这个设置仍然决定这是否延伸到更旧的材料"
L["settings:spareBindOnAccount"] = "留存绑定账号装备"
L["settings:spareBindOnAccountTooltip"] = "保留哪些资料片的账号绑定装备，前提是它还能传给其他角色"
L["settings:spareBindOnEquip"] = "留存装备后绑定装备"
L["settings:spareBindOnEquipTooltip"] = "保留哪些资料片的装备后绑定装备，前提是它还能给其他角色或拍卖行"
L["settings:keepUncollectedCosmetic"] = "保留未收藏的外观"
L["settings:keepUncollectedCosmeticTooltip"] = "保留任何你尚未收藏其外观的物品。普通装备卖给商人仍会收藏外观，但时装物品要使用才会给出外观——卖掉它，那个外观就永远没了"
L["settings:sellRelics"] = "出售经典圣物"
L["settings:sellRelicsTooltip"] = "出售神像、圣契、图腾与魔印——大地的裂变移除的那个圣物栏位。不是军团再临的神器遗物，后者属于宝石，只是子类编号相同而已"
L["settings:gemsExpansions"] = "保留哪些宝石"
L["settings:gemsExpansionsTooltip"] = "保留哪些资料片的宝石。未勾选的会落到下面两个问题上"
L["settings:gemsRecipesNow"] = "保留配方需要的当前宝石"
L["settings:gemsRecipesNowTooltip"] = "保留任何专业配方当作材料使用的本资料片宝石，无论那个专业属于谁。问题问的是配方目录，目录中没有的宝石，视为没有任何配方需要"
L["settings:gemsRecipesOld"] = "保留配方需要的旧宝石"
L["settings:gemsRecipesOldTooltip"] = "对过往资料片宝石提出同样的问题。你自己专业要用的东西已经在别处保留了，所以这一项是为别人的配方准备的"
L["settings:keepArtifactRelics"] = "保留神器遗物"
L["settings:keepArtifactRelicsTooltip"] = "保留镶嵌在军团再临神器武器上的遗物。军团再临之后再无用处，除非你专门收藏，否则值得关掉"
L["settings:enhancementsExpansions"] = "保留哪些强化物品"
L["settings:enhancementsExpansionsTooltip"] = "保留哪些资料片的物品强化。新资料片一出，强化能用在的装备范围就会收窄，所以请勾选你实际穿着的那个资料片"
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

L["spare:none"] = "不留存"

-- The two rows of an expansion picker that are not expansions. Every other row
-- is named by the game itself (GetExpansionName), which is why this control
-- adds two strings rather than one per expansion.
L["expansion:all"] = "所有资料片"
L["expansion:current"] = "当前资料片"

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

L["option:expansions"] = "保留哪些资料片"
L["option:recipesNow"] = "如果有配方需要，也保留本资料片的"
L["option:recipesOld"] = "如果有配方需要，也保留更早的"

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
L["claimed:OPEN"] = "已被开启按钮认领"
L["claimed:DEPOSIT_WARBAND"] = "将改为存入战团银行"
L["claimed:DEPOSIT_PRIVATE"] = "将改为存入某个角色的个人银行"
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
L["reason:ENHANCEMENT_EXPANSION"] = "本资料片的物品强化被保留"
L["reason:CONSUMABLE_EXPANSION"] = "本资料片的消耗品会被保留"
L["reason:CONSUMABLE_REAGENT"] = "某个配方需要将其作为材料"
L["reason:GEM_EXPANSION"] = "本资料片的宝石会被保留"
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
"灰色物品，无论具体是哪种物品。默认关闭，因为这通常由其他插件负责处理。如果没有其他插件处理，打开这个选项，AzerothPrime 会替你清理它们。"
L["rule:epic"] = "传说品质及以上"
L["rule:epicSub"] = "传说、神器、传家宝"
L["rule:epicBlurb"] =
"永不出售。商人会为这些物品显示价格，随后又拒绝这笔交易，因此 AzerothPrime 不会把它们列入清单。"
L["rule:reagent"] = "制作材料"
L["rule:reagentSub"] = "使用你的专业清单"
L["rule:reagentBlurb"] =
"保留本账号任一专业可以使用的材料，无论它是哪种物品。材料既可能是药水，也可能是宝石或贸易物品，所以这项判定在物品类型之前进行。在你另行设置之前，只保留当前资料片的材料；更早的材料只要还被你标记过的配方需要，也会一并保留，无论资料片怎么勾选。这份清单直接读自游戏本身的配方，所以配方能接受的可选材料和每一个品质等级都已经在里面了——你不需要打开或扫描任何东西。"
L["rule:cosmetic"] = "未收藏的外观"
L["rule:cosmeticSub"] = "你尚未收藏的时装物品"
L["rule:cosmeticBlurb"] =
"尚未收藏的时装物品会被保留。出售它并不会收藏其外观——外观会直接消失——所以这是整个窗口中唯一一处犯错无法挽回的地方。已经收藏过的时装物品不会仅仅因为它是时装就被出售；它已经没有需要保护的东西了，会继续按照它本身是武器还是护甲来判定。"
L["rule:consumables"] = "消耗品"
L["rule:consumablesSub"] = "药水、食物、卷轴、珍奇物品"
L["rule:consumablesBlurb"] =
"为每种消耗品选择要保留的内容。没有勾选任何选项的会被出售。"
L["rule:bags"] = "背包"
L["rule:bagsSub"] = "各种容器"
L["rule:bagsBlurb"] =
"永不出售。携带哪些背包由你自己决定，所以 AzerothPrime 不会对它们做判定。"
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
"新资料片会限制这些强化能用在哪些装备上，所以旧的强化就不再有价值。请勾选你实际穿着装备所属的每个资料片，包括本资料片——现在不会再自动保留任何强化。"
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
"AzerothPrime 完全不判定的物品类型：任务物品、钥匙、笼中宠物、雕文、WoW 代币、法术材料、箭矢，以及其他已停用的类别。无论上面的规则如何设置，它们都会留在你的背包里。"

-- The report window's footnote. What the sell verdict discloses is not what
-- Openables' own report discloses, so each feature states its own.
L["report:blurbSell"] = "此报告包含物品链接及其其他数据、BitForge 得出的判定以及决定该判定的规则、你自己是否把这件物品加入了黑名单或白名单、你在该物品所占栏位上当前装备的物品，以及判定这一对比时用到的设置。物品链接会写明你角色的等级和专精 -- 这是链接自身格式的一部分，去掉它就会丢失让报告可以重现的细节。这里不会写出你角色的名字、所在服务器、公会或阵营，也不会描述任何其他栏位。"

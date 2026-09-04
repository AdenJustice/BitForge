if GetLocale() ~= "zhCN" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

L["minimap:hintClick"] = "左键点击打开选项"
L["minimap:hintDrag"] = "拖动以移动"
L["minimap:compartmentTooltip"] = "打开 BitForge 菜单"

L["msg:schemaResetBody"] = "%s 的存档数据来自旧版本，无法继续沿用。这些数据将被清除并重新建立。此操作只会发生一次。"
L["btn:schemaResetAccept"] = "清除并继续"

L["cmd:usage"] = "/bitforge <模块> [参数]，/bfdump <模块> [参数] -- 模块名可缩写为任意只匹配一个模块的前缀"
L["cmd:unknownModule"] = "没有名为 %s 的模块 -- 输入 /bitforge 查看列表"
L["cmd:ambiguousModule"] = "%s 匹配到多个模块：%s"
L["cmd:noSuchCommand"] = "%s 没有 %s 命令"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- 显示本次更新的内容"

L["report:windowTitle"] = "报告物品"
L["report:windowTitleDiagnostic"] = "诊断报告"
L["report:howTo"] = "全选后按 Ctrl+C，然后粘贴到以下地址的新议题中："
L["report:selectAll"] = "全选"
L["report:encoded"] = "这份报告太长，无法直接阅读，因此已被压缩。请原样粘贴 -- 开发者的工具会将其解压。"

L["whatsNew:windowTitle"] = "BitForge 更新内容"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "关闭"

L["upgrade:windowTitle"] = "BitForge 现在是六个独立下载"
L["upgrade:lead"] = "从现在起，BitForge 及其各个模块是彼此独立的下载 —— 每个都是自己的项目，各自更新。更新 BitForge 没有删除任何东西，你原有的一切仍然装着，也仍然能用。"
L["upgrade:separate"] = "以下这些不再包含在 BitForge 的下载里。在你把它们各自作为独立项目安装之前，不会再有任何东西更新它们："
L["upgrade:renamed"] = "BitForge Dispatch 已更名为 BitForge AzerothPrime，并以该名称成为独立项目。安装它之后，Dispatch 保存过的一切 —— 规则、逐件物品的清单、存放去向、黑名单、按钮的大小和位置 —— 都会一并带过来。如果旧的 Dispatch 仍然装着，AzerothPrime 会先把它停用，你的设置会在下次登录时到位；因此在插件列表里看到 Dispatch 变灰是正常现象而不是故障，那时就可以删除该文件夹了。有一样带不过来：可开启物品按钮的按键绑定，游戏是按按钮名称保存它的。请在按键设置中重新绑定。"
L["upgrade:close"] = "知道了"

L["msg:outOfStep"] = "请在 CurseForge 上更新 %s：它是 %s，而 BitForge 是 %s。现在两者是各自独立的下载，插件管理器可能只更新其中一个。"

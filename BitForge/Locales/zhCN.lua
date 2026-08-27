if GetLocale() ~= "zhCN" then return end
---@class BitForge.Core
local ns = select(2, ...)
local L = ns.locale

-- Minimap button
L["minimap:hintClick"] = "左键点击打开选项"
L["minimap:hintDrag"] = "拖动以移动"
L["minimap:compartmentTooltip"] = "打开 BitForge 菜单"

-- Schema upgrade
L["msg:schemaResetBody"] = "%s 的存档数据来自旧版本，无法继续沿用。这些数据将被清除并重新建立。此操作只会发生一次。"
L["btn:schemaResetAccept"] = "清除并继续"

-- Slash commands
L["cmd:usage"] = "/bitforge <模块> [参数]，/bfdump <模块> [参数] -- 模块名可缩写为任意只匹配一个模块的前缀"
L["cmd:unknownModule"] = "没有名为 %s 的模块 -- 输入 /bitforge 查看列表"
L["cmd:ambiguousModule"] = "%s 匹配到多个模块：%s"
L["cmd:noSuchCommand"] = "%s 没有 %s 命令"
L["cmd:coreUsage"] = "/bitforge core whatsnew -- 显示本次更新的内容"

-- Report window
L["report:windowTitle"] = "报告物品"
L["report:windowTitleDiagnostic"] = "诊断报告"
L["report:howTo"] = "全选后按 Ctrl+C，然后粘贴到以下地址的新议题中："
L["report:selectAll"] = "全选"
L["report:encoded"] = "这份报告太长，无法直接阅读，因此已被压缩。请原样粘贴 -- 开发者的工具会将其解压。"

-- The release-notes popup
L["whatsNew:windowTitle"] = "BitForge 更新内容"
L["whatsNew:version"] = "%s — %s"
L["whatsNew:close"] = "关闭"

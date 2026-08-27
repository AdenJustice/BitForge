---@class BitForge.BatchSell
local ns = select(2, ...)

local ipairs = ipairs
local format = string.format
local concat = table.concat

local GameTooltip = GameTooltip
local TooltipDataProcessor = TooltipDataProcessor
local tInvert = tInvert

local enum = ns.enum
local model = ns.model
local locale = ns.locale
-- Captured once rather than reached through ns on every call. Safe despite
-- control.lua loading after this file: Init.lua owns the table and control.lua
-- only aliases it, so this is the same table the scanner is published on.
local control = ns.control
---@class BitForge.BatchSell.View
local view = ns.view

-- Every bag item tooltip gains the verdict BatchSell would give it and the rule
-- that produced it, in the player's language, but only while the merchant is
-- open -- away from a vendor the verdict is not actionable, and gating it lets
-- every rule stay reachable rather than only the ones a manifest can show,
-- which are the ones that end in a sale. With the module's debug flag set the
-- tooltip additionally gains the raw facts the cascade weighed to get there,
-- regardless of merchant state.
--
-- Attached as a tooltip post-call rather than by hooking the bag buttons, so it
-- covers every frame that displays a bag item -- the merchant panel rows
-- included, since those build through SetBagItem.
--
-- scanner.Explain runs a full gather, so the two blocks share one call when
-- either wants it. When the merchant is closed and the debug flag is unset,
-- neither does, and Explain is skipped entirely rather than gathering for
-- nothing on every bag item a player hovers away from a vendor.

---@class BitForge.BatchSell.View.ItemTooltip
local itemTooltip = {}
do
    -- bindType arrives as a number and reads as noise; enum.BIND_TYPE names
    -- every value Enum.ItemBind defines, and anything else falls back to the
    -- number. The account verdict is printed beside it because that is the fact
    -- the cascade actually reads -- the raw type alone hid the ON_ACCOUNT bug.
    local BIND_TYPE_NAMES = tInvert(enum.BIND_TYPE)

    local function AddDebugLine(tooltip, text)
        tooltip:AddLine(text, enum.COLOR.DEBUG:GetRGB())
    end

    --- The bag slot a tooltip is describing, or nil when it is describing
    --- something else. Merchant panel rows park the facts they were built from
    --- on _data; real item buttons answer ItemButtonMixin:GetBagID, with the
    --- slot as the frame's own ID.
    local function OwnerBagSlot(owner)
        if not owner then return nil end
        local data = owner._data
        if data then return data.bagIndex, data.slotIndex end
        if owner.GetBagID then return owner:GetBagID(), owner:GetID() end
        return nil
    end

    --- The bags scanner.Scan walks. Bank and void storage buttons answer
    --- GetBagID as well, and a verdict on a slot BatchSell never considers would
    --- be a lie -- so those tooltips are left untouched rather than annotated.
    local function IsScannedBag(bagIndex)
        return bagIndex ~= nil
            and bagIndex >= BACKPACK_CONTAINER
            and bagIndex <= NUM_TOTAL_EQUIPPED_BAG_SLOTS
    end

    --- The items equipped in the slots this item could occupy, or nil when it is
    --- not equippable. Both entries of a dual slot are shown rather than reduced,
    --- because model.CompareToEquipped is existential over them: a ring only has
    --- to satisfy the test against one.
    ---
    --- An unreadable entry (see control.lua's equippedItems) carries no level or
    --- quality to format, so it is reported by name instead -- the debug line is
    --- how a developer would otherwise notice model.CompareToEquipped decided
    --- KEEP without any level comparison at all.
    local function EquippedSummary(facts)
        local items = facts.equippedItems
        if not items or #items == 0 then return nil end
        local parts = {}
        for _, equipped in ipairs(items) do
            parts[#parts + 1] = equipped.unreadable
                and "unreadable"
                or format("%d(q%d)", equipped.level, equipped.quality)
        end
        return concat(parts, "/")
    end

    local function StatusName(itemID, scope)
        return model.GetStatus(itemID, scope) or "none"
    end

    --- Deliberately unlocalized: this is developer output, and a locale key per
    --- line would put eleven translations behind a flag no player sets.
    local function AddDebugReport(tooltip, report)
        local facts, settings = report.facts, report.settings

        tooltip:AddLine(" ")
        AddDebugLine(tooltip, format("[BS] verdict %s  rule %s", report.verdict, report.rule))

        local equipped = EquippedSummary(facts)
        AddDebugLine(tooltip, format("[BS] item %d  bag %d slot %d  ilvl %d%s",
            facts.itemID, facts.bagIndex, facts.slotIndex, facts.level,
            equipped and format("  equipped %s", equipped) or ""))

        AddDebugLine(tooltip, format("[BS] class %s/%s",
            tostring(facts.classID), tostring(facts.subclassID)))

        AddDebugLine(tooltip, format("[BS] quality %d  bind %s%s  expac %d  price %d x%d = %d",
            facts.quality, BIND_TYPE_NAMES[facts.bindType] or facts.bindType,
            facts.isBindOnAccount and " (account)" or "", facts.expacID,
            facts.sellPrice, facts.stackCount, model.GetTotalSellValue(facts)))

        AddDebugLine(tooltip, format("[BS] list: char=%s warband=%s%s",
            StatusName(facts.itemID, enum.LIST_SCOPE.CHAR),
            StatusName(facts.itemID, enum.LIST_SCOPE.GLOBAL),
            facts.isCharOverride and "  (override)" or ""))

        -- The derived facts the rule cascade branches on. None is stored on
        -- the facts table, so without them the rule that fired cannot be
        -- reconciled against the raw values on the lines above. disenchantable
        -- is the item's own property; reachable is whether it can ever get to
        -- an enchanter. Step 8 needs both, and they disagree often enough that
        -- one value would not explain a verdict.
        AddDebugLine(tooltip, format(
            "[BS] equippable %s  disenchantable %s  reachable %s  locked %s  refundable %s  set %s  excluded %s",
            tostring(model.IsEquippableBy(facts, settings.playerClass)),
            tostring(model.IsDisenchantable(facts)),
            tostring(model.CanReachAnEnchanter(facts, settings.isEnchanter)),
            tostring(facts.isLocked), tostring(facts.isRefundable),
            tostring(facts.inEquipmentSet), tostring(facts.isTempExcluded)))
    end

    --- The two lines a player reads: what will happen, and which rule decided.
    --- Localized, and shown only while the merchant is open -- OnItemTooltip
    --- does not even call this away from a vendor, since the verdict is not
    --- actionable there.
    ---
    --- The reason mapping is total over enum.RULE by construction, and a test
    --- iterates the enum to keep it that way -- a missing string would render as
    --- a blank line in front of a player rather than failing anywhere.
    local function AddVerdict(tooltip, report)
        local isSell = report.verdict == enum.DECISION.SELL
        local color = isSell and enum.COLOR.SELL or enum.COLOR.KEEP
        local heading = isSell and locale["verdict:sell"] or locale["verdict:keep"]

        tooltip:AddLine(" ")
        tooltip:AddLine(heading, color:GetRGB())
        tooltip:AddLine(locale["reason:" .. report.rule], color:GetRGB())
    end

    local function OnItemTooltip(tooltip)
        if tooltip ~= GameTooltip then return end

        local isMerchantOpen = control.IsMerchantOpen()
        local isDebug = model.IsDebug()
        if not isMerchantOpen and not isDebug then return end

        local bagIndex, slotIndex = OwnerBagSlot(tooltip:GetOwner())
        if not IsScannedBag(bagIndex) then return end

        local report = control.scanner.Explain(bagIndex, slotIndex)
        if not report then return end

        if isMerchantOpen then
            AddVerdict(tooltip, report)
        end
        if isDebug then
            AddDebugReport(tooltip, report)
        end
    end

    --- Registered once at startup. Both blocks read their own gate live --
    --- the verdict from control.IsMerchantOpen(), the debug block from
    --- model.IsDebug() -- so neither needs a reload to react to a change.
    function itemTooltip.Init()
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
    end
end
view.itemTooltip = itemTooltip

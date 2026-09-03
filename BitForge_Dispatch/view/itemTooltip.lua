---@class BitForge.Dispatch
local ns = select(2, ...)

local GameTooltip = GameTooltip
local TooltipDataProcessor = TooltipDataProcessor

local enum = ns.enum
local model = ns.model
local locale = ns.locale
-- Captured once rather than reached through ns on every call. Safe despite
-- control.lua loading after this file: Init.lua owns the table and control.lua
-- only aliases it, so this is the same table the scanner is published on.
local control = ns.control
---@class BitForge.Dispatch.View
local view = ns.view

-- Every bag item tooltip gains the verdict Dispatch would give it and the rule
-- that produced it, in the player's language, but only while the merchant is
-- open: away from a vendor the verdict is not actionable, and gating on the
-- merchant rather than on the manifest is what keeps every rule reachable and
-- not only the ones that end in a sale. The module's debug flag adds the raw
-- facts the cascade weighed, merchant open or not.
--
-- Attached as a tooltip post-call rather than by hooking the bag buttons, so it
-- covers every frame that displays a bag item -- the merchant panel rows
-- included, since those build through SetBagItem.
--
-- scanner.Explain runs a full gather, so the two blocks share one call when
-- either wants it, and it is skipped entirely when neither does rather than
-- gathering for nothing on every bag item hovered away from a vendor.

---@class BitForge.Dispatch.View.ItemTooltip
local itemTooltip = {}
do
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
    --- GetBagID as well, and a verdict on a slot Dispatch never considers would
    --- be a lie -- so those tooltips are left untouched rather than annotated.
    local function IsScannedBag(bagIndex)
        return bagIndex ~= nil
            and bagIndex >= BACKPACK_CONTAINER
            and bagIndex <= NUM_TOTAL_EQUIPPED_BAG_SLOTS
    end

    --- The two lines a player reads: what will happen, and which rule decided.
    --- Localized, and shown only while the merchant is open -- OnItemTooltip
    --- does not even call this away from a vendor, since the verdict is not
    --- actionable there.
    ---
    --- The reason mapping is total over enum.RULE by construction, and a test
    --- iterates the enum to keep it that way -- a missing string would render as
    --- a blank line in front of a player rather than failing anywhere.
    ---
    --- report.claimedBy displaces that reason rather than joining it. Every
    --- enum.RULE string asserts its own outcome ("so it is sold"), so pairing
    --- the sell claimant's rule with a heading another claimant decided prints
    --- a sentence that contradicts the line above it. When something outranked
    --- the sell path, what decided is the claim, and the claim is what is
    --- named -- one key per disposition that can outrank it.
    local function AddVerdict(tooltip, report)
        local isSell = report.verdict == enum.DECISION.SELL
        local color = isSell and enum.COLOR.SELL or enum.COLOR.KEEP
        local heading = isSell and locale["verdict:sell"] or locale["verdict:keep"]

        tooltip:AddLine(" ")
        tooltip:AddLine(heading, color:GetRGB())
        tooltip:AddLine(report.claimedBy
            and locale["claimed:" .. report.claimedBy]
            or locale["reason:" .. report.rule], color:GetRGB())
    end

    local function OnItemTooltip(tooltip)
        if tooltip ~= GameTooltip then return end

        local isMerchantOpen = control.IsMerchantOpen()
        local isDebug = model.IsDebug()
        if not isMerchantOpen and not isDebug then return end

        local bagIndex, slotIndex = OwnerBagSlot(tooltip:GetOwner())
        if not IsScannedBag(bagIndex) then return end

        local report = control.sellScanner.Explain(bagIndex, slotIndex)
        if not report then return end

        if isMerchantOpen then
            AddVerdict(tooltip, report)
        end
        local debugLines = view.debugLines
        if isDebug and debugLines then
            debugLines.AddSellReport(tooltip, report)
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

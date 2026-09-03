---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs
local huge = math.huge

local C_Container = C_Container

local model = ns.model

---@class BitForge.Dispatch.Control
local control = ns.control
local sellScanner = control.sellScanner

---@class BitForge.Dispatch.Control.Seller
local seller = {}

--- Vendors the manifest, up to the merchant's per-batch limit when enabled.
function seller.SellBatch()
    if not model.IsSellEnabled() then return end

    local manifest = model.GetManifest()
    local limit = model.GetLimitBatchTo12() and 12 or huge
    local count = 0

    for _, facts in ipairs(manifest) do
        if count >= limit then break end
        if sellScanner.Refresh(facts) and not facts.isLocked then
            C_Container.UseContainerItem(facts.bagIndex, facts.slotIndex)
            count = count + 1
        end
    end
end

control.seller = seller

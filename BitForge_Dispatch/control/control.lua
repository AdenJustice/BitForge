---@type string, BitForge.Dispatch
local ADDON_NAME, ns = ...

local ipairs = ipairs
local pairs = pairs
local format = string.format
local concat = table.concat

-- BatchSell's own carried schema step 12 (see BATCHSELL_STEPS below).
local bor, lshift = bit.bor, bit.lshift

local ClearCursor = ClearCursor
local GetCursorInfo = GetCursorInfo

local C_AddOns = C_AddOns
local C_Container = C_Container
local C_EquipmentSet = C_EquipmentSet
local C_Item = C_Item
local C_MerchantFrame = C_MerchantFrame
local C_SpellBook = C_SpellBook
local C_TooltipInfo = C_TooltipInfo
local C_TradeSkillUI = C_TradeSkillUI

local enum = ns.enum
local model = ns.model
local view = ns.view
local locale = ns.locale
local events = BitForge.Events

-- The sub-key files publish onto this table but must not widen it, so the
-- fields they add are declared here, on the file that owns the key.
---@class BitForge.Dispatch.Control
---@field detector BitForge.Dispatch.Control.Detector
---@field openScanner BitForge.Dispatch.Control.OpenScanner
---@field inventory BitForge.Dispatch.Control.Inventory
---@field recipes BitForge.Dispatch.Control.Recipes
---@field deposit BitForge.Dispatch.Control.Deposit
---@field adapters BitForge.Dispatch.Control.Adapters
---@field sellScanner BitForge.Dispatch.Control.SellScanner
---@field seller BitForge.Dispatch.Control.Seller
---@field disenchantProbe BitForge.Dispatch.Control.DisenchantProbe
-- debug/allowListAudit.lua, so absent from a release build -- and still not
-- nilable: its one caller is debug/dumps.lua, absent from the same builds.
---@field allowListAudit BitForge.Dispatch.Control.AllowListAudit
-- Nilable: a release build ships no debug/lines.lua at all.
---@field debugNotices BitForge.Dispatch.Control.DebugNotices|nil
-- Nilable for the same reason: debug/curationReview.lua, whose one call
-- site is control/openScanner.lua's scan.
---@field curationReview BitForge.Dispatch.Control.CurationReview|nil
local control = ns.control
local detector = control.detector
local openScanner = control.openScanner
local recipes = control.recipes
local deposit = control.deposit
local sellScanner = control.sellScanner
local disenchantProbe = control.disenchantProbe

function ns:Subscribe(event, callback)
    BitForge.Subscribe(event, callback, self)
end

function ns:Unsubscribe(event)
    BitForge.Unsubscribe(event, self)
end

--- Subscribes to one of core's two command events. Separate from ns:Subscribe
--- because core also has to be told which addon is answering: the bus knows
--- only an owner table, and /bitforge's roster names modules.
---@param isDiagnostic boolean|nil  see BitForge.SubscribeCommand
function ns:SubscribeCommand(event, callback, isDiagnostic)
    BitForge.SubscribeCommand(ADDON_NAME, event, callback, self, isDiagnostic)
end

-- The three addons this one replaces. A manual installer who copies
-- BitForge_Dispatch in without deleting them leaves two live copies of every
-- feature, which scan the bags twice and act on them twice. Their saved data is
-- not touched by refusing -- the adoption simply happens at the next login,
-- once the folders are gone.
local REPLACED = { "BitForge_Openables", "BitForge_BatchSell", "BitForge_UPS" }

--- Names of the replaced addons still loaded, or nil when none are.
---@return string[]|nil
local function StillInstalled()
    local found
    for _, name in ipairs(REPLACED) do
        if C_AddOns.IsAddOnLoaded(name) then
            found = found or {}
            found[#found + 1] = name
        end
    end
    return found
end

-- The retired modules' storage keys. Core needs them: a container created this
-- session is otherwise taken as nothing to convert, and this module is new for
-- every player alive, so naming them is what stops that short-circuit skipping
-- the adoption steps below (BitForge/model.lua's UpgradeModuleDB).
local ADOPTS = { "Openables", "UPS", "BatchSell" }

local function onBagUpdate()
    openScanner.RequestScan()
end

-- An interrupted cast unlocks its slot without changing what is in any bag, so
-- BAG_UPDATE_DELAYED never fires for it and the hold in openScanner.Scan would
-- otherwise sit until some unrelated event happened to rescan.
local function onItemLockChanged()
    openScanner.RequestScan()
end

-- ITEM_DATA_LOAD_RESULT payload is (itemID, success).
local function onItemDataLoaded(itemID, success)
    if not openScanner.ConsumePendingItem(itemID) then return end
    if success then
        openScanner.RequestScan()
    end

    if view.blacklistFrame and view.blacklistFrame.Refresh then
        view.blacklistFrame.Refresh()
    end
end

-- Item data and tooltip data resolve through two separate caches, and
-- collectCandidates only waits on the first: an item past the
-- IsItemDataCachedByID guard can still hand Classify a sparse tooltip, which
-- the ladder abstains on as NO_TOOLTIP rather than judging the item on lines
-- it has not been shown (#378). ITEM_DATA_LOAD_RESULT cannot cover that -- the
-- item data was already cached -- so the button stays stale until an unrelated
-- bag change happens to fire BAG_UPDATE_DELAYED.
--
-- The payload's dataInstanceID is ignored: the scan retains no instance IDs to
-- match it against, and a nil means "every tooltip" in any case. RequestScan
-- debounces to one scan per frame, so a burst of resolutions costs one pass --
-- the invalidation below is not debounced with it, but it only wipes two
-- tables, and the walk it forces is paid once by the single queued scan.
--
-- Invalidating is what makes the rescan mean anything: record.tooltipData is
-- memoized for the generation, so without this the second scan re-reads the
-- sparse tooltip the first one cached and reaches the same NO_TOOLTIP, which
-- is the very staleness this handler exists to heal.
local function onTooltipDataUpdate()
    model.facts.Invalidate()
    openScanner.RequestScan()
end

local function onCooldownUpdate()
    view.button.RefreshCooldown()
end

local function onRegenEnabled()
    -- Retries everything view/button.lua defers under InCombatLockdown: a
    -- mid-combat /reload leaves Init() unrun, and a settings change leaves
    -- ApplySize and RestorePosition un-applied. Init() is idempotent and the
    -- rest re-apply current model state, so calling them on every regen is
    -- harmless.
    view.button.Init()
    view.button.FlushPending()
    view.button.ApplyClickRegistration()
    view.button.ApplySize()
    view.button.RestorePosition()
    openScanner.RequestScan()
end

-- Invalidates model.facts: questTaken reads the quest log for whichever
-- questID a record resolved, and a quest can be accepted, turned in or
-- abandoned by a means that touches no bag, lock or equipment slot at all --
-- an NPC dialog turning in a quest some other item merely started, say. A
-- rescan the bags have not otherwise moved for would then reuse a cached
-- record's stale answer, exactly the staleness this fires to catch.
local function onQuestChanged()
    model.facts.Invalidate()
    openScanner.RequestScan()
end

local function onLevelUp()
    openScanner.RequestScan()
end

-- Two memos go stale on a transition, not one. model.zone.Here() holds the
-- reading a scan takes once per candidate, and model/arbiter.lua's Resolve
-- rawsets its verdict onto the record model.facts.Get caches for the
-- generation -- so dropping only the first leaves the rescan re-reading the
-- verdict reached where the player used to be, and the button unchanged.
--
-- Both ahead of the request rather than after it. openScanner.RequestScan only
-- queues, so today either order drops them before the scan runs; writing them
-- first is what keeps that true if the request ever stops being deferred.
local function onZoneChanged()
    model.zone.Invalidate()
    model.facts.Invalidate()
    openScanner.RequestScan()
end

-- Refresh, invalidate, rescan, and the order is the whole point: a verdict is
-- memoised on the record (model/arbiter.lua's Resolve), and the profession
-- names model/openRules.lua's ladder matches a usage requirement against are
-- player state model/facts.lua deliberately does not cache, so the generation
-- has to turn over -- but only once RefreshProfessions has rewritten them, or
-- the rescan memoises against the mask that just stopped being true.
local function onSkillLinesChanged()
    detector.RefreshProfessions()
    model.facts.Invalidate()
    openScanner.RequestScan()
end

-- Every expansion's line of the open profession, each at its own rank.
--
-- This is the only call that states them. GetProfessionInfo names the newest
-- line the character holds and nothing else, so a requirement gated on an older
-- expansion has no live answer at all -- and GetChildProfessionInfos answers
-- only for the profession whose window is open. So the ranks are harvested
-- whenever the player happens to open one and kept in the saved variables
-- between times. Blizzard's own rank bar reads the same call
-- (Blizzard_ProfessionsRankBar.lua).
--
-- The window test is not a formality: the call answers for whatever window was
-- last open, so without it any raise of this event would re-file a stale answer
-- under whichever profession it happened to belong to.
local function harvestOpenProfession()
    local current = C_TradeSkillUI.GetChildProfessionInfo()
    if not (current and (current.professionID or 0) ~= 0) then return end

    local children = C_TradeSkillUI.GetChildProfessionInfos()
    if not children then return end

    local parent, lines = nil, {}
    for _, info in ipairs(children) do
        if info.professionName and info.skillLevel then
            parent = parent or info.parentProfessionName
            lines[info.professionName] = info.skillLevel
        end
    end
    if not parent then return end

    model.SetProfessionRanks(parent, lines)
    -- The cache is what the match reads, and the button may be showing a
    -- verdict taken before this harvest -- the same trio onSkillLinesChanged
    -- runs above, in the same order and for the same reasons.
    detector.RefreshProfessions()
    model.facts.Invalidate()
    openScanner.RequestScan()
end

--- Harvests whatever skill line the profession window currently shows.
---
--- Only what the player is looking at. This cannot open the window itself --
--- C_TradeSkillUI.OpenTradeSkill is protected, and calling it from addon code
--- raises ADDON_ACTION_BLOCKED -- and it will not walk the player's expansion
--- tabs to collect data they did not ask for. A scan is therefore always
--- partial, which is why the prompt is gated on the character having no scans
--- at all rather than on this line.
local function harvestOpenWindow()
    local current = C_TradeSkillUI.GetChildProfessionInfo()
    if not current then return end

    recipes.HarvestSkillLine(current.professionID)
end

local function onNewRecipeLearned(recipeID, recipeLevel, baseRecipeID)
    recipes.OnNewRecipeLearned(recipeID, recipeLevel, baseRecipeID)
end

--- Confirms an outstanding deposit move. The second of three separately named
--- BAG_UPDATE_DELAYED handlers; the subscription below says why they are not
--- three subscriptions.
local function onDepositBagUpdateDelayed()
    deposit.OnBagUpdateDelayed()
end

local function onBankOpened()
    view.bankButton.OnBankOpened()

    -- The built-in source's container list is gated on the bank being open
    -- (inventory.GetCurationContainers), so an open curation window is showing a
    -- different account the moment the bank frame appears or disappears.
    view.curationWindow.Reload()
end

local function onBankClosed()
    -- Abort here rather than letting the next BAG_UPDATE_DELAYED walk into
    -- CanMove and discover it: a move issued against a bank that just closed may
    -- never report back at all, and the run would hang with the item held.
    deposit.Abort("msg:blockedBankClosed")

    view.bankButton.OnBankClosed()
    view.previewDialog.Hide()
    view.curationWindow.Reload()
end

-- CVAR_UPDATE payload is (cvarName, value).
local function onCVarUpdate(name)
    if name == "ActionButtonUseKeyDown" then
        view.button.ApplyClickRegistration()
    end
end

local function onUpdateBindings()
    view.button.RefreshHotKey()
end

local function buildEquipmentSetCache()
    ---@type table<string, true>
    local cache = {}
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        for _, location in ipairs(C_EquipmentSet.GetItemLocations(setID) or {}) do
            local data = EquipmentManager_GetLocationData(location)
            if data.isBags then
                cache[data.bag .. ":" .. data.slot] = true
            end
        end
    end
    model.SetEquipmentSetCache(cache)
end

--- GetProfessions returns spellbook skill-line INDICES, not skill line IDs, so
--- the ID has to be converted before it can be compared -- the same conversion
--- Blizzard's own WorldMapFrame does. Comparing the two directly never matches,
--- which reads as "nobody is an enchanter" rather than as an error.
---
--- GetSkillLineIndexByID answers nil for a line the player does not have, so
--- the prof1/prof2 test is what confirms it is one of the two primary slots
--- rather than some other tracked line.
local function detectEnchanting()
    local lineID = C_TradeSkillUI.GetProfessionSkillLineID(Enum.Profession.Enchanting)
    local index = lineID and C_SpellBook.GetSkillLineIndexByID(lineID)
    local prof1, prof2 = GetProfessions()
    model.SetIsEnchanter(index ~= nil and (index == prof1 or index == prof2))
end

local merchantOpen = false

local function onMerchantShow()
    merchantOpen = true
    -- A fresh visit gets a fresh memo: what this caches -- the pet and recipe
    -- tooltip answers -- is a property of this visit, not of the item, and the
    -- player may have learned either since the last one.
    sellScanner.ClearVisitMemo()
    -- And a fresh generation with it, or clearing that memo buys nothing. The
    -- open path resolves every slot on every bag update now, so by the time a
    -- vendor opens the verdict is already memoised on the record
    -- (model/arbiter.lua's Resolve) -- and Gather re-reading a fresh
    -- recipeKnown or petCollected onto that record changes no verdict at all.
    -- Learning a recipe fires no bag event, so without this the manifest opens
    -- with the answer from before it was learned, which is exactly the
    -- staleness ClearVisitMemo above exists to prevent.
    model.facts.Invalidate()
    -- Deliberately outside the arbiter, and left that way (plan #356 Task 5).
    -- This is Blizzard's own sweep: it takes every Poor-quality item in one
    -- call, before any claimant is heard, so a grey container with a Use: line
    -- the open path would claim is gone before model.arbiter.Resolve could
    -- award it. Routing it would mean rebuilding the sweep out of individual
    -- sales and losing the one thing it is here for. Not a hole in the
    -- arbiter -- a decision, and the junk rule is the switch that governs it.
    if model.IsSellEnabled() and model.GetRule("junk").sell
        and C_MerchantFrame.IsSellAllJunkEnabled() then
        C_MerchantFrame.SellAllJunkItems()
    end
    -- Unconditional, and not an alternative to the sweep above. Leaving the
    -- scan to the BAG_UPDATE_DELAYED the sweep provokes assumed the sweep
    -- always moves something: it does not when the bags hold no junk, which is
    -- every visit after the first has cleared them. No bag update, no scan, and
    -- onMerchantClosed had already emptied the manifest -- so the panel opened
    -- blank until the player pressed Refresh.
    --
    -- When the sweep does sell something the scan simply runs twice: this one
    -- against bags that still hold the junk, then the bag update's against bags
    -- that do not. The second is the one the player sees, and seller.SellBatch
    -- re-reads every slot before acting, so a manifest entry outlived by its
    -- item cannot mis-sell in between.
    --
    -- Run whether or not selling is enabled: away from the vendor's own junk
    -- sweep, the scan is what feeds the tooltip's verdict and the merchant
    -- panel's manifest, neither of which the switch gates -- see seller.lua's
    -- own gate for where the switch actually stops an item leaving the bags.
    sellScanner.Scan()
    view.merchantPanel.Show()
end

local function onMerchantClosed()
    merchantOpen = false
    -- Cleared here too, not only on the next MERCHANT_SHOW: view/itemTooltip.lua's
    -- debug tooltip calls sellScanner.Explain away from a vendor, and without
    -- this a recipe learned right after closing would still read the stale
    -- answer memoized during the visit, until the player opened a vendor again.
    sellScanner.ClearVisitMemo()
    -- Explicit, exactly as onMerchantShow's is, and not because nothing else
    -- would do it: ClearTempExcludes and ClearTempIncludes below each
    -- invalidate on their own, so this line changes nothing today. It is here
    -- so that stays a coincidence rather than the mechanism -- clearing the
    -- visit memo without turning the generation over buys nothing at all now
    -- that a verdict outlives the read behind it, and someone removing the
    -- invalidation from those two setters on the grounds that the merchant
    -- close already covers them would otherwise break this silently.
    model.facts.Invalidate()
    model.ClearTempExcludes()
    model.ClearTempIncludes()
    -- The manifest is this visit's decisions, not a durable record: leaving it
    -- in place let a temporary include re-sell an item on a later visit after
    -- its one-visit-only inclusion had already been cleared above, and let a
    -- blacklist entry added between visits go unnoticed by that first Sell.
    model.SetManifest({})
    view.merchantPanel.Hide()
end

--- Whether the merchant window is open right now. The item tooltip's
--- player-facing verdict reads this live to decide whether to render at all --
--- gating on the module's own tracked state rather than MerchantFrame:IsShown(),
--- since MerchantFrame does not exist in the test harness.
function control.IsMerchantOpen()
    return merchantOpen
end

--- The third BAG_UPDATE_DELAYED handler; see the subscription below.
local function onSellBagUpdateDelayed()
    if merchantOpen then
        sellScanner.Scan()
    end
end

local function onEquipmentSetsChanged()
    buildEquipmentSetCache()
    if merchantOpen then
        sellScanner.Scan()
    end
end

--- The second ITEM_DATA_LOAD_RESULT handler, alongside onItemDataLoaded.
--- Payload is (itemID, success).
---
--- Invalidates, unlike the open path's handler beside it. An unresolved record
--- is never cached (model/facts.lua's Get says why), so the item this event
--- names heals itself -- but equippedItems is a lazy field on records that DID
--- resolve, and it reads what the character is WEARING. A /reload at a vendor
--- scans before the equipped slots have loaded, every gear candidate memoizes
--- { unreadable = true } for the generation, and without turning it over the
--- rescan reads the same sentinel: model.CompareToEquipped abstains throughout
--- and gear that should be offered is silently absent from the manifest.
---
--- Behind ResolveLoad rather than in front of it: the event fires for every
--- item any part of the UI asks the server about, and one this module never
--- waited on has nothing to heal.
local function onSellItemDataLoaded(itemID, success)
    if not sellScanner.ResolveLoad(itemID) then return end
    if success and merchantOpen then
        model.facts.Invalidate()
        sellScanner.Scan()
    end
end

-- The player put a spell on the cursor, or took it off. Harvest declines the
-- latter, and declines a raise that is not a disenchant, so nothing here needs
-- to know which of the two just happened.
--
-- Invalidates after the harvest, for the reason onMerchantShow above does:
-- what Harvest files is db.global.disenchantTruth, which the sell claimant
-- reads live through model.IsDisenchantable and which no record holds, and
-- putting Disenchant on the cursor carries no bag change -- so the verdict is
-- already memoised by the time the client answers. The harmful direction is an
-- item the crawled table wrongly lists as undisenchantable: the client says it
-- CAN be, Harvest files that, and the manifest goes on offering it for sale
-- for the rest of the generation. The probe exists to catch exactly that wrong
-- prediction, so ignoring what it just learned defeats the whole point of it.
--
-- Here rather than in model.LearnDisenchantable, which is called once per
-- eligible slot: a single harvest would turn the generation over dozens of
-- times, and each turn would throw away the records the harvest is still
-- walking.
local function onCurrentSpellCastChanged()
    disenchantProbe.Harvest()
    model.facts.Invalidate()
end

--- The second SKILL_LINES_CHANGED handler: learning or unlearning Enchanting
--- changes what counts as disenchantable.
--- Invalidates for the reason onSkillLinesChanged above does, and needs it
--- more: settings.isEnchanter prices a disenchantable item in model.Decide,
--- and this scan is SYNCHRONOUS where the open path's is debounced to the next
--- frame -- so an invalidation left to the subscription below would land after
--- this scan had already memoised a verdict on the old answer.
local function onSellSkillLinesChanged()
    detectEnchanting()
    model.facts.Invalidate()
    if merchantOpen then
        sellScanner.Scan()
    end
end

-- Dragging a bag item onto the manifest includes it in this merchant visit's
-- sale, overriding rules that merely did not select it. The item never moves:
-- the cursor is cleared immediately, before anything else can fail, so the
-- item always lands back in the slot it came from and a refusal never
-- strands it on the cursor.

--- Accepts an item dropped onto the manifest.
---
--- Matches the cursor's item to a bag slot primarily by itemID -- a
--- hyperlink read off the cursor may be a secret value and is not guaranteed
--- to compare equal to the container's own hyperlink for the same item --
--- but prefers a candidate whose own hyperlink equals the cursor's link when
--- one is found, falling back to the first itemID match otherwise. Without
--- that preference, two bag slots sharing an itemID with different links
--- (different bonus IDs, two upgrade tracks of the same piece) could
--- force-sell the wrong variant: AddTempInclude is link-keyed, and Gather
--- recomputes isTempIncluded per slot from its own resolved link.
---
--- Everything below keys on facts.itemLink -- the value Gather actually
--- produced for the matched slot -- rather than the cursor's own link, for
--- the same secret-value reason.
---
--- model.CanTempInclude is checked before anything is mutated. It is
--- deliberately silent about a temporary exclusion, so an item that is both
--- excluded and blacklisted keeps its exclusion rather than losing it to a
--- drop that gets refused anyway.
function control.AcceptManifestDrop()
    local cursorType, cursorItemID, cursorItemLink = GetCursorInfo()
    if cursorType ~= "item" then return end
    ClearCursor()

    -- Reads model.facts.Walk's shared entries rather than the bags directly.
    -- This only ever fires from a merchant-panel drag, so the only context it
    -- is reachable from is a merchant window being open -- which is exactly
    -- when sellScanner.Scan (MERCHANT_SHOW, or the last BAG_UPDATE_DELAYED
    -- while merchantOpen) has very likely already walked this generation, so
    -- the search below costs nothing beyond that scan's own walk.
    local bagIndex, slotIndex, slotInfo
    local fallbackBag, fallbackSlot, fallbackInfo
    for _, entry in ipairs(model.facts.Walk()) do
        if entry.itemID == cursorItemID then
            if cursorItemLink and entry.slotInfo.hyperlink == cursorItemLink then
                bagIndex, slotIndex, slotInfo = entry.bagIndex, entry.slotIndex, entry.slotInfo
                break
            elseif not fallbackBag then
                fallbackBag, fallbackSlot, fallbackInfo = entry.bagIndex, entry.slotIndex, entry.slotInfo
            end
        end
    end
    bagIndex = bagIndex or fallbackBag
    slotIndex = slotIndex or fallbackSlot
    slotInfo = slotInfo or fallbackInfo
    if not bagIndex then return end

    local facts, pendingItemID = sellScanner.Gather(bagIndex, slotIndex, slotInfo)
    if not facts then
        -- Item data has not arrived yet. sellScanner.Scan handles the same
        -- signal by requesting the load; a silent no-op here would leave the
        -- drop unexplained on a slot that would resolve moments later.
        if pendingItemID then sellScanner.RequestLoad(pendingItemID) end
        return
    end
    local itemLink = facts.itemLink

    local blockingRule = model.CanTempInclude(facts)
    if blockingRule then
        BitForge:Print(format(locale["msg:dropRefused"], itemLink, locale["reason:" .. blockingRule]))
        return
    end

    if model.IsTempExcluded(itemLink) then
        model.RemoveTempExclude(itemLink)
        BitForge:Print(format(locale["msg:dropUnexcluded"], itemLink))
    end

    model.AddTempInclude(itemLink)
    sellScanner.Scan()
end

local function startModule()
    -- The tooltip hook goes in first, deliberately: it is what explains a
    -- module whose later startup misbehaves, so it must not be downstream of
    -- anything that can fail.
    view.itemTooltip.Init()

    view.settingsPanel.Init()

    -- The reverse index is memory only and starts empty, which reads as
    -- "nothing spared" -- so it is built here, before anything scans, rather
    -- than at file-read time: db is not allocated when model/sparedRecipes.lua
    -- is read, and onReady is the first point the flag set can be read at all.
    model.sparedRecipes.Rebuild()

    -- After the rebuild above, and once only: Menu.ModifyMenu appends a
    -- callback per call rather than replacing one, so a second Init would put
    -- two identical entries on every recipe row.
    view.recipeMenu.Init()

    -- Unconditional on purpose, matching Openables: the switch gates the scan
    -- itself (openScanner.Scan checks model.IsOpenEnabled) and the settings
    -- checkbox, not the button's setup. Gating setup here would leave a
    -- player who flips the switch on mid-session with no button until their
    -- next reload, since nothing would ever call view.button.Init() again.
    detector.RefreshProfessions()
    view.button.Init()
    openScanner.RequestScan()

    BitForge.RegisterMinimapButton({
        label    = locale["curation:open"],
        icon     = "Interface\\Icons\\INV_Misc_Bag_10_Blue",
        onToggle = view.curationWindow.Toggle,
    })

    -- Professions are core's now, recorded there at login and again whenever
    -- SKILL_LINES_CHANGED fires. Recipes are not free the same way -- this
    -- module cannot open a profession window itself, so PromptForScans asks the
    -- player to open theirs.
    recipes.PromptForScans()

    local classFilename = UnitClassBase("player")
    model.SetPlayerClass(classFilename)
    buildEquipmentSetCache()
    detectEnchanting()
end

-- Each retired module's own shipped scalar defaults -- read from its
-- DB_DEFAULTS in git (BitForge_Openables/model.lua, BitForge_UPS/model.lua,
-- BitForge_BatchSell/model/model.lua, at the last commit before they were
-- deleted), not from memory. Core's logout prune deletes a stored key once it
-- matches its module's registered default, and a retired module has no live
-- module left to re-seed the gap on the next login -- so a key absent from a
-- retired table means the player left it at THIS value, not that it was
-- unset.
--
-- Collection keys (blacklist, list, overrides, knownRecipes, recipeScans,
-- disenchantTruth, professionRanks) all defaulted to an empty table, which the
-- prune only removes once it is already empty -- so their absence genuinely
-- means "nothing stored" and needs no entry here.
-- global.rules and global.button.point are the nested exception, handled by
-- Overlay below rather than by a hand-written nested default table.
local RETIRED_DEFAULTS = {
    Openables = {
        global = {
            enabled      = true,
            locked       = false,
            buttonSize   = 42,
            showCount    = true,
            showCooldown = true,
        },
    },
    UPS = {
        char = {
            enabled            = true,
            previewMoves       = true,
            onlyWantedReagents = true,
        },
    },
    BatchSell = {
        global = { limitBatchTo12 = true },
    },
}

--- value, or default when value is nil. Not `value or default`: a stored
--- `false` must survive, and `false or default` would silently replace it.
---@generic T
---@param value T|nil
---@param default T
---@return T
local function OrDefault(value, default)
    if value == nil then return default end
    return value
end

--- Overlays every key `source` declares onto `target`, recursing into nested
--- tables. The one tool this step needs for the two shapes in Dispatch's own
--- DB_DEFAULTS that nest a scalar more than one level deep --
--- global.rules and global.button.point -- where the logout prune can delete
--- an individual leaf without deleting the table around it, so "the whole
--- key is absent" is not a safe test at any depth below the top.
---
--- target is always Dispatch's own freshly-seeded default for that address:
--- SeedDefaults already deep-copied DB_DEFAULTS into moduleDB.global before
--- this step runs, since Dispatch is new for every profile. BatchSell's
--- global.rules and Openables' global.point agree with Dispatch's own at
--- every address those two themselves declared, bar the deliberate exceptions
--- tests/test_dispatch_adopt.lua names one by one -- rules.reagents.expansions
--- is the only one so far, where moving the adopter to Dispatch's new default
--- IS the decision (spec #379). So a key absent from source at any depth is
--- one the player left at the retired module's own shipped default, one
--- Dispatch has grown since, or one of those exceptions -- and target already
--- holds the right value for all three.
---@param target table
---@param source table|nil
local function Overlay(target, source)
    if type(source) ~= "table" then return end
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then
            Overlay(target[key], value)
        else
            target[key] = value
        end
    end
end

--- Fills every key `source` declares that `target` does not already have,
--- recursing into nested tables -- core's own SeedDefaults (BitForge/model.lua),
--- reimplemented here because a retired module stopped being seeded the
--- session it retired. A live module's carried step never had to guard a
--- nested read: SeedDefaults ran every login, against whatever DB_DEFAULTS
--- shape the CURRENTLY installed build declared, so global.rules was already
--- structurally complete before any step of BATCHSELL_STEPS below ever ran,
--- however far behind schemaVersion itself was left. A retired table has had
--- no login to do that since, so a profile frozen at a schema old enough to
--- predate global.rules entirely (introduced alongside step 6) would crash
--- step 7's first read into it without this.
---@param target table
---@param source table
local function SeedMissing(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = type(value) == "table" and CopyTable(value) or value
        elseif type(value) == "table" and type(target[key]) == "table" then
            SeedMissing(target[key], value)
        end
    end
end

--- One character's own slot in this module's own stored table, reached
--- through core's BitForge:GetModuleCharSlot rather than moduleDB's own char
--- proxy -- which, like every module's, only ever exposes the character
--- currently logging in (docs/conventions/database.md). A retired module's
--- char table can carry a dozen alts' worth of settings, and this is the
--- only way to receive every one of them in this one pass, rather than one
--- every future login. Core creates and seeds the slot from this module's
--- own registered defaults if it does not already exist, and never
--- re-seeds one that does -- see the function's own doc comment
--- (BitForge/model.lua) for why a module must never reach for it outside
--- adoption.
---
--- Narrowed to table, not core's own table|nil: core answers nil only for a
--- module that has not allocated a database, and UpgradeModuleDB already
--- refused to call this step at all if THIS module had not -- so by the time
--- any of the three call sites below run, Dispatch's own allocation is
--- guaranteed to exist.
---@param charKey string
---@return table
local function DispatchCharSlot(charKey)
    ---@type table
    local slot = BitForge:GetModuleCharSlot(ADDON_NAME, charKey)
    return slot
end

--- Brings one retired module's stored table forward through its own schema
--- steps, from whatever version it was last stamped at up to finalVersion,
--- and returns the raw table -- or nil if nothing was ever stored.
---
--- Every step runs once per charKey found in the raw table's char, because a
--- char-scoped step was written against a live module's own proxy, which
--- only ever touched the character logging in at the moment ITS OWN version
--- was stamped -- the module is retired, so every other character never got
--- a turn. Running the whole chain again per real charKey reaches every one
--- of them; a step with no char-scoped content re-runs harmlessly each time
--- (a migration step is already required to be safe to re-run from scratch,
--- see docs/conventions/database.md). A table with no char slots at all
--- still runs the chain once, against a throwaway table, so global-scoped
--- step content is not skipped for a profile with nothing char-scoped
--- stored.
---@param key string  a storage key, e.g. "Openables"
---@param steps table<number, fun(moduleDB: table)>
---@param finalVersion number
---@param seedGlobal table|nil  filled into raw.global before any step runs;
---   see SeedMissing above
---@return table|nil
local function Bring(key, steps, finalVersion, seedGlobal)
    local raw = BitForge:GetRetiredModuleDB(key)
    if not raw then return nil end

    raw.global = raw.global or {}
    if seedGlobal then SeedMissing(raw.global, seedGlobal) end
    local stored = raw.global.schemaVersion or 0

    local function runAgainst(charData)
        for version = stored + 1, finalVersion do
            local step = steps[version]
            if step then step({ global = raw.global, char = charData }) end
        end
    end

    local ranAny = false
    for _, charData in pairs(raw.char or {}) do
        ranAny = true
        runAgainst(charData)
    end
    if not ranAny then
        runAgainst({})
    end

    return raw
end

local OPENABLES_VERSION = 1
local OPENABLES_STEPS = {
    -- Data written before this module was versioned already matches the
    -- version-1 shape, so adopting the version is the whole migration.
    [1] = function() end,
}

local UPS_VERSION = 2
local UPS_STEPS = {
    -- Data written before this module was versioned already matches the
    -- version-1 shape, so adopting the version is the whole migration.
    [1] = function() end,

    -- The profession registry moved to core, where BatchSell can reach
    -- it too. Carrying the stored one over rather than letting core
    -- re-accumulate matters: core only learns a character's professions
    -- when that character logs in, so without this every alt would stop
    -- counting until visited, and WantedByAlt would quietly stop
    -- wanting their recipes.
    [2] = function(moduleDB)
        local stored = moduleDB.global.professions
        if type(stored) ~= "table" then return end

        for charKey, professions in pairs(stored) do
            -- Core records the character logging in right now, and that
            -- reading is fresher than anything stored here. Only the
            -- others are carried over.
            if not BitForge:GetCharacterProfessions(charKey) then
                BitForge:RecordCharacterProfessions(charKey, professions)
            end
        end

        moduleDB.global.professions = nil
    end,
}

local BATCHSELL_VERSION = 12
local BATCHSELL_STEPS = {
    -- Data written before this module was versioned already matches the
    -- version-1 shape, so adopting the version is the whole migration.
    [1] = function() end,
    -- The classification rework retired four settings. Nothing reads
    -- them afterwards, and the logout prune only visits keys present in
    -- DB_DEFAULTS, so one left behind would sit in the saved variables
    -- forever. Assigning nil unconditionally is idempotent, which
    -- matters because a step that throws is re-invoked from the top.
    --
    -- Values are not carried forward. keepEquippable's two states map
    -- onto the item level margin, whose default reproduces its
    -- on-state; the other three have no successor. This
    -- step is char-scoped, so it reaches only the character logging in
    -- when the account-wide version is stamped -- every other character
    -- keeps its stale entries, which is why nothing is migrated rather
    -- than migrated partially.
    [2] = function(moduleDB)
        moduleDB.char.keepEquippable = nil
        moduleDB.char.qualityThreshold = nil
        moduleDB.char.sellPastExpansion = nil
        moduleDB.char.expansionThreshold = nil
    end,
    -- The item level margin became a proportion of the equipped item
    -- rather than a flat number of levels, and changed sign with it: the
    -- old -20 meant "twenty levels below", the new 0.9 means "nine
    -- tenths of the slot". A stored -20 read as the new setting is not
    -- merely wrong, it is off the slider entirely, so the old key is
    -- dropped and the new default seeded rather than converted -- twenty
    -- levels is 3% of a 620 slot and 33% of a 60 one, so there is no one
    -- proportion the old number translates to.
    --
    -- Detects the OLD key rather than the absence of the new one: the
    -- defaults have already been seeded by the time a step runs, so
    -- ilvlMarginRatio is always present here. Assigning nil is
    -- idempotent, which matters because a step that throws is re-invoked
    -- from the top.
    [3] = function(moduleDB)
        moduleDB.char.ilvlThreshold = nil
    end,
    -- The three per-direction margin toggles are retired. The margin
    -- now reaches every quality gap through a single exponent, and
    -- granting it to one direction while withholding it from another
    -- is precisely what made the comparison non-monotonic: with the
    -- margin on same quality and off below it, an Uncommon outlived
    -- the Rare beside it at the same item level.
    --
    -- Nothing carries forward, because nothing succeeds them -- there
    -- is no setting left for an off-state to mean. The margin they
    -- governed is untouched, so a player who had tuned it keeps it.
    [4] = function(moduleDB)
        moduleDB.char.marginOnHigherQuality = nil
        moduleDB.char.marginOnSameQuality = nil
        moduleDB.char.marginOnLowerQuality = nil
    end,
    -- The margin went back to a flat number of item levels. Midnight
    -- squished the scale, so the span one number has to cover is narrow
    -- enough for a flat margin to mean something across it -- which is
    -- what a proportion was introduced to solve and no longer needs to.
    --
    -- Not carried across, for the same reason step 3 could not carry the
    -- other direction: 0.9 is 29 levels against an equipped 290 and 6
    -- against an equipped 60, so there is no single number it becomes.
    -- The old key is dropped and the seeded default stands.
    [5] = function(moduleDB)
        moduleDB.char.ilvlMarginRatio = nil
    end,
    -- The rule tree is warband-wide, and the whole of the old
    -- char-scoped block is retired with the three-bucket
    -- classification it configured.
    --
    -- Nothing is carried forward, and that is deliberate rather than
    -- lazy. Promoting one character's tuning to govern the account has
    -- no correct source: this step is char-scoped, so the answer would
    -- be whoever happened to log in when the version was stamped.
    -- Seeding the defaults is honest; promoting an arbitrary character
    -- silently is not. limitBatchTo12 keeps its old default of true in
    -- its new home, so the batch stays capped either way.
    [6] = function(moduleDB)
        moduleDB.char.limitBatchTo12 = nil
        moduleDB.char.sellJunk = nil
        moduleDB.char.sellEquipment = nil
        moduleDB.char.materialsMode = nil
        moduleDB.char.materialsExpansion = nil
        moduleDB.char.otherMode = nil
        moduleDB.char.ilvlMargin = nil
        moduleDB.char.emphasizeQuality = nil
        moduleDB.char.keepBindOnAccount = nil
        moduleDB.char.keepBindOnAccountPastExpac = nil
        moduleDB.char.keepDisenchantables = nil
        moduleDB.char.keepUsedReagents = nil
        moduleDB.char.keepDisenchantablesPastExpac = nil
    end,
    -- Two rule-tree keys retire together.
    --
    -- housing.sellLearnedDyes governed a branch that could never fire:
    -- a dye is a one-time consumable, so nothing is ever collected or
    -- learned for one. Its successor, housing.keepTradeableDyes, asks
    -- whether the copy still has somewhere to go, which is a question
    -- about a consumable.
    --
    -- armor.keepUncollectedCosmetic moves to a rules.cosmetics of its
    -- own, because the rule it governs stopped being an armor rule: a
    -- cosmetic is not a class or a subclass, and the two items in #32
    -- are weapons. The protection now reaches them.
    --
    -- Neither value is carried across. Both successors ship on, which
    -- is where anyone who left the defaults alone already was. The step
    -- exists only because the logout prune visits the keys DB_DEFAULTS
    -- declares, so a retired one left behind would sit in the saved
    -- variables forever. Assigning nil unconditionally is idempotent,
    -- which matters because a step that throws is re-invoked from the
    -- top.
    [7] = function(moduleDB)
        local rules = moduleDB.global.rules
        rules.housing.sellLearnedDyes = nil
        rules.armor.keepUncollectedCosmetic = nil
    end,
    -- The decor rule ships off. Nothing ever chose the old default --
    -- no control reaches it -- so a stored true is a seed rather than
    -- a preference, and rewriting it is the only way the new default
    -- reaches a database that already carries the key. Idempotent for
    -- the same reason step 7 is.
    [8] = function(moduleDB)
        moduleDB.global.rules.housing.sellCollectedDecor = false
    end,
    -- ilvlMargin never was an item level margin: it priced a quality
    -- tier, and emphasizeQuality doubled it while granting a tolerance
    -- of the same size. The two effects are now two keys, and the one
    -- whose meaning changed takes a new name so no stored value is
    -- silently reinterpreted.
    --
    -- Unlike steps 3, 4 and 5, this one COULD have carried the tuning
    -- across exactly -- emphasis off maps to qualityMargin = ilvlMargin
    -- with margin 0, emphasis on to double and equal. That was declined
    -- rather than unavailable, and the neighbouring comments would
    -- otherwise read as though it had been unavailable here too. The
    -- seeded defaults reproduce the shipped comparison, so a player who
    -- never touched these two notices nothing.
    [9] = function(moduleDB)
        local gear = moduleDB.global.rules.gear
        gear.ilvlMargin = nil
        gear.emphasizeQuality = nil
    end,

    -- The two gear toggles are retired, and neither transition is
    -- lossless, which is why no value is carried forward. A player who
    -- had compareItemLevel off was having no item level comparison at
    -- all, and no tolerance reproduces that -- the widest is 30 -- so
    -- they get the ladder's answer now. A player who had compareQuality
    -- on gets what qualityMargin charges a tier instead of an absolute
    -- veto. The defaults are unchanged, so a player who touched neither
    -- notices nothing. Idempotent for the same reason step 9 is.
    [10] = function(moduleDB)
        local gear = moduleDB.global.rules.gear
        gear.compareItemLevel = nil
        gear.compareQuality = nil
    end,

    -- keepForDisenchant was a boolean with no age limit at all, so a
    -- stored true maps to ALL rather than to the new default -- every
    -- existing player goes on keeping exactly what they kept. A fresh
    -- profile gets CURRENT instead, so the migration and the default
    -- deliberately disagree: narrowing someone's stored setting would
    -- start selling gear they were keeping, and they never asked.
    --
    -- Typed rather than truthy: the old value is a boolean and the new
    -- one a string, so re-running this against a migrated profile has
    -- to be a no-op, which is what makes it idempotent.
    [11] = function(moduleDB)
        local gear = moduleDB.global.rules.gear
        if type(gear.keepForDisenchant) == "boolean" then
            gear.keepForDisenchant = gear.keepForDisenchant and "ALL" or "NONE"
        end
    end,

    -- The five expansion settings became one bitmask each. Each old key
    -- is detected by its own presence -- the defaults are seeded before
    -- any step runs, so `expansions` is always there already -- and set
    -- to nil once converted, because the logout prune only visits keys
    -- DB_DEFAULTS declares and one left behind would outlive the design
    -- it belonged to.
    --
    -- "ALL" becomes the role bit rather than a mask of every shipped
    -- expansion. It means "any expansion, forever"; frozen into a fixed
    -- mask it would start selling last expansion's gear on the day a new
    -- one ships, which is the opposite of what the player asked for.
    --
    -- lastExpansion resolves against today's GetExpansionLevel. It was
    -- a relative phrase, and converting it is exactly the moment it has
    -- to become one concrete expansion.
    [12] = function(moduleDB)
        local rules = moduleDB.global and moduleDB.global.rules
        if not rules then return end

        local FROM_SPARE = {
            NONE    = 0,
            CURRENT = enum.EXPANSION_CURRENT,
            ALL     = enum.EXPANSION_ALL,
        }
        local lastExpansionBit = lshift(1, GetExpansionLevel() - 1)

        --- The two booleans every non-gear setting stored, as a mask.
        local function maskFor(keepsCurrent, keepsLast)
            local mask = keepsCurrent and enum.EXPANSION_CURRENT or 0
            if keepsLast then mask = bor(mask, lastExpansionBit) end
            return mask
        end

        if rules.gear then
            for _, key in ipairs({ "spareBindOnAccount", "spareBindOnEquip",
                                   "keepForDisenchant" }) do
                local stored = rules.gear[key]
                if type(stored) == "string" then
                    rules.gear[key] = FROM_SPARE[stored] or enum.EXPANSION_CURRENT
                end
            end
        end

        if rules.gems and rules.gems.current ~= nil then
            rules.gems.expansions = maskFor(rules.gems.current, false)
            rules.gems.current = nil
        end

        if rules.reagents and rules.reagents.currentExpansionOnly ~= nil then
            rules.reagents.expansions = rules.reagents.currentExpansionOnly
                and enum.EXPANSION_CURRENT or enum.EXPANSION_ALL
            rules.reagents.currentExpansionOnly = nil
        end

        if rules.enhancements and rules.enhancements.keepLastExpansion ~= nil then
            -- Current was kept unconditionally by the old criterion, so
            -- CURRENT is always part of the mask this converts to --
            -- which is also what makes the shipped default unchanged.
            rules.enhancements.expansions =
                maskFor(true, rules.enhancements.keepLastExpansion)
            rules.enhancements.keepLastExpansion = nil
        end

        for _, row in pairs(rules.consumables or {}) do
            if row.current ~= nil or row.lastExpansion ~= nil then
                -- current defaulted to true, so the logout prune drops it from
                -- exactly the rows that ticked lastExpansion and left current
                -- alone -- which is the only reason those four rows carry the
                -- column. Reading a missing current as anything but true would
                -- discard the setting of every player who used it.
                row.expansions = maskFor(row.current ~= false, row.lastExpansion)
                row.current = nil
                row.lastExpansion = nil
            end
        end
    end,
}

--- Writes one field of one item's merged override record, creating the record
--- on the first field that lands in it.
---
--- Overwrites rather than fills. Every value it is handed is read straight out
--- of one of the three source stores, which this step does not touch, so a
--- replay -- a step that threw halfway, a version stamp that did not stick --
--- rewrites the same record instead of compounding a half-built one. A nil
--- writes nothing, which is what keeps an absent source key meaning "no
--- opinion" rather than an opinion of nil.
---@param store  table   itemID -> record, one scope's itemOverrides
---@param itemID number
---@param key    string  "open"|"sell"|"bank"|"owners"|"target"
---@param value  any     nil writes nothing
local function MergeOverride(store, itemID, key, value)
    if value == nil then return end

    local record = store[itemID]
    if not record then
        record = {}
        store[itemID] = record
    end
    record[key] = value
end

local function onPlayerReady()
    local stillInstalled = StillInstalled()
    if stillInstalled then
        BitForge:Print(format(locale["msg:replacedInstalled"], concat(stillInstalled, ", ")))
        BitForge:Print(locale["msg:replacedInstalledFix"])
        return
    end

    BitForge:UpgradeModuleDB(ADDON_NAME, {
        version = enum.SCHEMA_VERSION,
        adopts  = ADOPTS,
        steps   = {
            -- Brings each of the three retired tables forward through its own
            -- schema steps (they are not at their final version for a profile
            -- that has not played in a while), then maps its settings onto
            -- this module's own address 1:1 by name. The override stores
            -- (blacklist/list/overrides) are carried across under their old
            -- names and NOT unified here -- step 2 below is what merges them,
            -- and step 3 what drops them.
            --
            -- Bring answers nil, and the matching DropRetiredModuleDB below is
            -- never reached, for a retired container holding only a hand-set
            -- debug flag -- deliberately: that is GetRetiredModuleDB's own
            -- read of "not adoptable data", and a container nothing ever
            -- wrote real settings into is left exactly where a developer put
            -- it rather than deleted out from under them.
            [1] = function(moduleDB)
                local openables = Bring("Openables", OPENABLES_STEPS, OPENABLES_VERSION)
                if openables then
                    local storedGlobal = openables.global or {}
                    local defaults = RETIRED_DEFAULTS.Openables.global

                    moduleDB.global.openEnabled = OrDefault(storedGlobal.enabled, defaults.enabled)

                    local button = moduleDB.global.button
                    button.locked       = OrDefault(storedGlobal.locked, defaults.locked)
                    button.size         = OrDefault(storedGlobal.buttonSize, defaults.buttonSize)
                    button.showCount    = OrDefault(storedGlobal.showCount, defaults.showCount)
                    button.showCooldown = OrDefault(storedGlobal.showCooldown, defaults.showCooldown)
                    Overlay(button.point, storedGlobal.point)

                    if storedGlobal.blacklist then moduleDB.global.blacklist = storedGlobal.blacklist end

                    for charKey, charData in pairs(openables.char or {}) do
                        if charData.professionRanks then
                            DispatchCharSlot(charKey).professionRanks = charData.professionRanks
                        end
                    end

                    BitForge:DropRetiredModuleDB("Openables")
                end

                local ups = Bring("UPS", UPS_STEPS, UPS_VERSION)
                if ups then
                    local storedGlobal = ups.global or {}
                    if storedGlobal.overrides then moduleDB.global.overrides = storedGlobal.overrides end
                    if storedGlobal.knownRecipes then
                        moduleDB.global.knownRecipes = storedGlobal.knownRecipes
                    end
                    if storedGlobal.recipeScans then moduleDB.global.recipeScans = storedGlobal.recipeScans end

                    local defaults = RETIRED_DEFAULTS.UPS.char
                    for charKey, charData in pairs(ups.char or {}) do
                        local slot = DispatchCharSlot(charKey)
                        slot.bankEnabled = OrDefault(charData.enabled, defaults.enabled)
                        slot.previewMoves = OrDefault(charData.previewMoves, defaults.previewMoves)
                        slot.onlyWantedReagents =
                            OrDefault(charData.onlyWantedReagents, defaults.onlyWantedReagents)
                    end

                    -- UPS's own RETIRED_GLOBAL/RETIRED_CHAR cleanup
                    -- (dropRetiredKeys, BitForge_UPS/model.lua) does not come
                    -- across: it cleared keys written by the module UPS
                    -- itself replaced, on UPS's own container. Once UPS is
                    -- retired that container is only ever read here, which
                    -- maps the keys this module wants and drops the whole
                    -- table -- so those six stale keys leave with it. Not an
                    -- oversight; there is nothing left in the dropped table
                    -- for a successor cleanup to run against.
                    BitForge:DropRetiredModuleDB("UPS")
                end

                -- Seeded with this module's own already-current global.rules:
                -- BATCHSELL_STEPS 7-11 index straight into rules.gear/.armor/
                -- .housing, and only a live module's own SeedDefaults ever
                -- guaranteed those existed first (see SeedMissing above).
                local batchSell = Bring("BatchSell", BATCHSELL_STEPS, BATCHSELL_VERSION,
                    { rules = moduleDB.global.rules })
                if batchSell then
                    local storedGlobal = batchSell.global or {}
                    local defaults = RETIRED_DEFAULTS.BatchSell.global

                    if storedGlobal.list then moduleDB.global.list = storedGlobal.list end
                    if storedGlobal.disenchantTruth then
                        moduleDB.global.disenchantTruth = storedGlobal.disenchantTruth
                    end
                    moduleDB.global.limitBatchTo12 =
                        OrDefault(storedGlobal.limitBatchTo12, defaults.limitBatchTo12)
                    Overlay(moduleDB.global.rules, storedGlobal.rules)

                    for charKey, charData in pairs(batchSell.char or {}) do
                        if charData.list then
                            DispatchCharSlot(charKey).list = charData.list
                        end
                    end

                    BitForge:DropRetiredModuleDB("BatchSell")
                end
            end,

            -- Copies the three separate override stores step 1 carried across
            -- address-for-address -- Openables' blacklist, BatchSell's two
            -- sell lists, UPS's bank destinations -- into one record per item
            -- at db.itemOverrides, and LEAVES ALL THREE WHERE THEY ARE. Step
            -- 3 below is what removes them, once every reader has moved. A
            -- step that moved rather than copied would break every reader
            -- that had not moved yet, and leave nothing to check a mistaken
            -- one against.
            --
            -- No RETIRED_DEFAULTS equivalent, and none is needed: all three
            -- sources are collection keys, so the logout prune only ever
            -- removed the whole table once it was already empty. An absent
            -- key here genuinely means "nothing stored", unlike the flat
            -- scalars step 1 has to read through a frozen default.
            --
            -- Which is why every source is read through `or {}`. Step 3 took
            -- these three out of DB_DEFAULTS, so nothing re-seeds a table the
            -- prune emptied: a profile stored at version 1 that never
            -- blacklisted anything arrives here with no `blacklist` key at
            -- all, and pairs(nil) would throw the step -- and a step that
            -- throws is a module that never starts.
            [2] = function(moduleDB)
                local dispatchGlobal = moduleDB.global
                local merged = dispatchGlobal.itemOverrides

                -- The one inversion in this step, and the only place it can go
                -- wrong: the blacklist stores true for "never offer this
                -- item", and the merged record spells that open = false.
                -- Carrying the boolean across unchanged would turn every item
                -- a player hid into one they asked to always be offered --
                -- silently, and for every profile that has ever blacklisted
                -- anything. `== true` rather than a truth test, because that
                -- is the predicate Openables' own reader used for the whole
                -- life of the store: a truthy-but-not-true value was never
                -- hidden, and must not start being hidden on the way across.
                for itemID, blacklisted in pairs(dispatchGlobal.blacklist or {}) do
                    if blacklisted == true then
                        MergeOverride(merged, itemID, "open", false)
                    end
                end

                for itemID, status in pairs(dispatchGlobal.list or {}) do
                    MergeOverride(merged, itemID, "sell", status)
                end

                -- Two stored shapes, both from bankRules.SetDestination: a
                -- bare enum.DESTINATION string, or the private record
                -- { dest, owners, target }. Both put the destination in
                -- `bank`; only the second carries the other two.
                --
                -- owners is copied, not shared. The old store keeps its own
                -- readers until the task that moves them, and one owner set
                -- reachable through both addresses would let a write through
                -- either look like a change nobody made through the other.
                for itemID, override in pairs(dispatchGlobal.overrides or {}) do
                    if type(override) == "table" then
                        MergeOverride(merged, itemID, "bank", override.dest)
                        MergeOverride(merged, itemID, "owners",
                            override.owners and CopyTable(override.owners))
                        MergeOverride(merged, itemID, "target", override.target)
                    else
                        MergeOverride(merged, itemID, "bank", override)
                    end
                end

                -- Every character with a slot, not only the one logging in.
                -- The char proxy reaches exactly one, and the version stamped
                -- after this step is account-wide, so an alt skipped here is
                -- an alt whose sell overrides are gone the day the source
                -- table is dropped -- with nothing to report it.
                -- GetModuleCharKeys names the slots this module already
                -- stores, which is the set that can hold a list at all. Not
                -- BitForge:GetKnownCharacters(): that names every character
                -- who has logged in with BitForge loaded, and asking
                -- DispatchCharSlot for one of those would create a Dispatch
                -- slot for a character that never had one.
                for _, charKey in ipairs(BitForge:GetModuleCharKeys(ADDON_NAME)) do
                    local slot = DispatchCharSlot(charKey)
                    for itemID, status in pairs(slot.list or {}) do
                        MergeOverride(slot.itemOverrides, itemID, "sell", status)
                    end
                end
            end,

            -- Drops the three stores step 2 copied out of, and their entries
            -- in DB_DEFAULTS with them. From here a player's opinion about an
            -- item is stored once.
            --
            -- Why this is its own step rather than the tail of step 2: a step
            -- that both wrote the new store and dropped the old would leave a
            -- profile that had run it with nothing to fall back to, and
            -- between step 2 and this one FIVE separate changes moved readers
            -- onto the merged store one at a time. Two of them were wrong in
            -- ways review caught -- and the old data was still there to
            -- notice it against. That is not a hypothetical, and it is the
            -- reason to keep a drop step separate from the copy step next
            -- time as well.
            --
            -- What it costs, stated rather than discovered: a profile this
            -- step has run cannot be read by any earlier build of this
            -- module. That is the ordinary bargain of a schema step here --
            -- version 1's adoption made the same one -- and there is nothing
            -- to fall back to by design, because the fallback was the
            -- duplication this step ends.
            --
            -- Idempotent by construction: every write is a nil assignment to
            -- a key nothing re-seeds, so a replay after a throw finds the
            -- work already done and does it again to no effect.
            [3] = function(moduleDB)
                local dispatchGlobal = moduleDB.global
                dispatchGlobal.blacklist = nil
                dispatchGlobal.list = nil
                dispatchGlobal.overrides = nil

                -- Every character with a slot, for the reason step 2's own
                -- per-character pass gives: the char proxy reaches only the
                -- one logging in, and the version stamped after this step is
                -- account-wide, so a list left on an alt here is one nothing
                -- ever comes back to remove.
                for _, charKey in ipairs(BitForge:GetModuleCharKeys(ADDON_NAME)) do
                    DispatchCharSlot(charKey).list = nil
                end
            end,

            -- Drops the curation review store. It accumulated on every
            -- player's saved variables whatever the debug flag said, and
            -- nothing in game ever read it back -- its only reader was a
            -- test. The writer lives in debug/curationReview.lua now and files into
            -- db.debug.dump, which core empties at the start of a play
            -- session and no step here touches.
            --
            -- Deleted rather than emptied, and out of DB_DEFAULTS in the same
            -- commit: an empty table left in the defaults is re-seeded on the
            -- next login and dropped again by the logout prune, oscillating in
            -- and out of the saved file forever. The itemOverrides comment in
            -- DB_DEFAULTS (model/model.lua) describes that failure at length.
            --
            -- Warband-wide, so unlike step 3 there is no per-character pass to
            -- make: the store only ever hung off global.
            --
            -- Idempotent by construction: a nil assignment to a key nothing
            -- re-seeds finds the work done on a replay and does it again to no
            -- effect.
            [4] = function(moduleDB)
                moduleDB.global.curationReview = nil
            end,
        },
    }, startModule)
end

-- BAG_UPDATE_DELAYED carries three independent handlers, and
-- ITEM_DATA_LOAD_RESULT, SKILL_LINES_CHANGED and TRADE_SKILL_LIST_UPDATE two
-- each -- one owner may register only one callback per event
-- (CallbackRegistryMixin:RegisterCallback), so every one of them runs from a
-- single subscription rather than several, which would silently drop all but
-- the last.
-- model.facts.Invalidate() runs first on every one of these: each turns the
-- generation over because it changes something a cached record holds --
-- which item (if any) occupies the slot, whether it is locked, or which
-- slots equipmentSetCache answers for -- and every handler behind it that
-- reads a record must see the new generation, not the one built for what
-- used to be true.
ns:Subscribe(events.BAG_UPDATE_DELAYED, function()
    model.facts.Invalidate()
    onBagUpdate()
    onDepositBagUpdateDelayed()
    onSellBagUpdateDelayed()
end)
ns:Subscribe(events.ITEM_LOCK_CHANGED, function()
    model.facts.Invalidate()
    onItemLockChanged()
end)
ns:Subscribe(events.ITEM_DATA_LOAD_RESULT, function(itemID, success)
    onItemDataLoaded(itemID, success)
    onSellItemDataLoaded(itemID, success)
end)
ns:Subscribe(events.TOOLTIP_DATA_UPDATE, onTooltipDataUpdate)
ns:Subscribe(events.ACTIONBAR_UPDATE_COOLDOWN, onCooldownUpdate)
ns:Subscribe(events.PLAYER_REGEN_ENABLED, onRegenEnabled)
ns:Subscribe(events.QUEST_ACCEPTED, onQuestChanged)
ns:Subscribe(events.QUEST_TURNED_IN, onQuestChanged)
ns:Subscribe(events.QUEST_REMOVED, onQuestChanged)
ns:Subscribe(events.ZONE_CHANGED, onZoneChanged)
ns:Subscribe(events.ZONE_CHANGED_INDOORS, onZoneChanged)
ns:Subscribe(events.ZONE_CHANGED_NEW_AREA, onZoneChanged)
-- Invalidates model.facts: a heirloom's level is a live function of the
-- character's level, and this is the only signal that it changed with no
-- bag, lock or equipment event alongside it.
ns:Subscribe(events.PLAYER_LEVEL_UP, function()
    model.facts.Invalidate()
    onLevelUp()
end)
-- No model.facts.Invalidate() here, unlike the subscriptions above, and that
-- is deliberate rather than an omission: what goes stale on these two events is
-- the profession and enchanter state each handler REWRITES on its way past, so
-- the invalidation has to sit between that rewrite and the handler's own
-- rescan. Each of them does it there. Hoisting it here would put it either in
-- front of the refresh (memoising the mask that just stopped being true) or
-- behind onSellSkillLinesChanged's synchronous scan (too late to matter).
ns:Subscribe(events.SKILL_LINES_CHANGED, function()
    onSkillLinesChanged()
    onSellSkillLinesChanged()
end)
ns:Subscribe(events.TRADE_SKILL_LIST_UPDATE, function()
    harvestOpenProfession()
    harvestOpenWindow()
end)
ns:Subscribe(events.NEW_RECIPE_LEARNED, onNewRecipeLearned)
ns:Subscribe(events.BANKFRAME_OPENED, onBankOpened)
ns:Subscribe(events.BANKFRAME_CLOSED, onBankClosed)
ns:Subscribe(events.CVAR_UPDATE, onCVarUpdate)
ns:Subscribe(events.UPDATE_BINDINGS, onUpdateBindings)
ns:Subscribe(events.MERCHANT_SHOW, onMerchantShow)
ns:Subscribe(events.MERCHANT_CLOSED, onMerchantClosed)
ns:Subscribe(events.EQUIPMENT_SETS_CHANGED, function()
    model.facts.Invalidate()
    onEquipmentSetsChanged()
end)
-- Invalidates model.facts: equippedItems reads what is currently equipped,
-- and a swap between two equipped slots -- ring one to ring two, say --
-- fires neither BAG_UPDATE_DELAYED nor EQUIPMENT_SETS_CHANGED. Nothing else
-- in this module reacts to the swap itself, so there is no handler here
-- beyond the invalidation.
ns:Subscribe(events.PLAYER_EQUIPMENT_CHANGED, function()
    model.facts.Invalidate()
end)
-- Invalidates model.facts: isUnlearnedToy and isUncollectedAppearance are
-- read off PlayerHasToy/PlayerHasTransmogItemModifiedAppearance, and both can
-- flip true while the item that grants them stays in the bags -- most toys and
-- appearance items are consumed on learn, which is a bag event already covered,
-- but not every one of them is (isUnlearnedToy's own comment: "an item still in
-- the bags after the toy is collected"). Turning the generation over is what
-- keeps the answer as fresh as it was when Classify read those two calls on
-- every pass. Neither requests a rescan of its own -- nothing else in this
-- module reacts to the collection event itself, the same shape
-- PLAYER_EQUIPMENT_CHANGED above already takes -- so the button repaints on
-- whatever event next rescans it, reading the current collection state.
ns:Subscribe(events.NEW_TOY_ADDED, function()
    model.facts.Invalidate()
end)
ns:Subscribe(events.TRANSMOG_COLLECTION_UPDATED, function()
    model.facts.Invalidate()
end)
ns:Subscribe(events.CURRENT_SPELL_CAST_CHANGED, onCurrentSpellCastChanged)
ns:Subscribe(events.PLAYER_READY, onPlayerReady)

-- The open path's own answer as the player pastes it: everything
-- detector.Classify read about one item, rendered as text that can be selected
-- and sent. view/button.lua's Shift+Alt+right-click is the gesture that shows
-- it, and debug/dumps.lua's /bfdump dispatch open renders through the same
-- control.OpenReportText -- the two differ only in how they resolve the item,
-- which is what stops a developer reading a report no player could have sent.
--
-- detector.Classify asks model.openRules.Claim alone, not the arbiter, so this
-- can disagree with the button and has no visibility into whether another
-- claimant would outrank or suppress the open one. A plain Use: line the
-- arbiter demotes below a positive SELL claim (model/arbiter.lua's
-- DEMOTED_USE_ORDER) still shows here as accepted at its ordinary tier, and any
-- promoting override on bank or sell outranks every OPEN tier outright (rank()
-- ranks `promoted` first, model/arbiter.lua). Left that way rather than routed
-- through the arbiter: that would change the pinned "accepted
-- priority=.../rejected reason=..." shape every existing dump test asserts, for
-- cases none of them exercises. The note line control.OpenReportText prints
-- below every report is the mitigation a player actually sees. /bfdump
-- dispatch <itemID> answers the same question through the arbiter and is the
-- accurate one when the two disagree, and the note deliberately does not send
-- anyone there -- see its own comment for why.
do

    -- The names a usage requirement is matched against, each at the rank that
    -- answers for it. This is detector.GetKnownProfessions() itself rather than
    -- a re-read of the API: the two now differ, and the one that decides is
    -- this one. "Midnight Mining = 62, Mining = 0, Dragon Isles Mining = 40"
    -- says immediately which line answered and why.
    local function KnownProfessions()
        local names = {}
        for name, skillLevel in pairs(detector.GetKnownProfessions()) do
            names[#names + 1] = ("%s = %d"):format(name, skillLevel)
        end
        -- Sorted so two reports can be diffed; pairs order is not stable.
        table.sort(names)
        return #names > 0 and table.concat(names, ", ") or "none"
    end

    -- What the pipeline would decide if this item were not allow-listed. A
    -- listed item otherwise hides whether its entry still earns its place, since
    -- ALLOW_LIST answers first.
    --
    -- Nothing here writes to enum.ALLOW_LIST: model.openRules.Claim has an
    -- opt-out of its own rung. The pcall stays for the other half of what it
    -- was always doing -- a raise inside the ladder would take the whole report
    -- down with it -- rather than for an entry to restore.
    --
    -- The verdict is model/allowAudit.lua's bucket, which is what
    -- /bfdump dispatch allowlist reports too: two commands asking the same
    -- question must not answer it in two vocabularies, and no file but that one
    -- decides a bucket.
    ---@param classID number|nil  from C_Item.GetItemInfoInstant, which is what
    ---   the class policy branches on. BuildDump has already read it.
    local function ClassifyIgnoringAllowList(bag, slot, itemID, classID)
        local listed = enum.ALLOW_LIST[itemID]
        if listed == nil then return "n/a, not allow-listed" end

        -- Positional names: accepted returns priority, locked, reason, detail;
        -- rejected returns nil, reason, detail.
        local ok, priority, second, third =
            pcall(detector.Classify, bag, slot, itemID, nil, { allowList = true })
        if not ok then return "errored: " .. tostring(priority) end

        local reason = priority and third or second
        -- bagless = false: this is an item the player is holding, so every
        -- bag-only rung is a legitimate verdict rather than the fault it would
        -- be on debug/allowListAudit.lua's record. Getting it the wrong way
        -- round turns real verdicts into ANOMALY rows and says nothing.
        local bucket = model.allowAudit.Bucket(
            priority and enum.CLAIM.OPEN or nil, reason, priority, {
                bagless = false,
                classID = classID,
                listedPriority = listed,
            })

        -- The bucket alone is not a report. What a person weighs is the rung
        -- that answered and, for an accept, its rank against the entry's own.
        if priority then
            return ("%s -- the ladder accepts it without the entry:"
                .. " priority=%s reason=%s listed=%s"):format(bucket,
                tostring(priority), tostring(reason), tostring(listed))
        end
        return ("%s -- the ladder refuses it without the entry: reason=%s detail=%s")
            :format(bucket, tostring(reason), tostring(third))
    end

    -- Every field is flattened with tostring: tooltip data can carry secret
    -- values in 12.0, and the report is pasted verbatim.
    local function BuildDump(bag, slot, itemID)
        local _, itemType, itemSubType, _, _, classID, subClassID =
            C_Item.GetItemInfoInstant(itemID)
        local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
        local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
        -- Positional again: accepted is priority, locked, reason, detail;
        -- rejected is nil, reason, detail. Reading one shape as the other put
        -- the rejection reason under "locked".
        local priority, second, third, fourth = detector.Classify(bag, slot, itemID)
        local verdict
        if priority then
            verdict = ("accepted priority=%s locked=%s reason=%s detail=%s"):format(
                tostring(priority), tostring(second), tostring(third), tostring(fourth))
        else
            verdict = ("rejected reason=%s detail=%s"):format(
                tostring(second), tostring(third))
        end

        local dump = {
            itemID      = itemID,
            name        = tostring(C_Item.GetItemNameByID(itemID)),
            where       = ("bag %d slot %d"):format(bag, slot),
            -- The slot's own lock, read live. Distinct from verdict's
            -- "locked" above, which is detector.IsLockedBox -- a lockbox
            -- needing a key -- and from the ranked-field dump's slotLocked,
            -- which only ever shows the pre-hold state; see openScanner.Scan.
            isLocked    = tostring(containerInfo and containerInfo.isLocked),
            class       = ("%s / %s (%s/%s)"):format(tostring(itemType),
                tostring(itemSubType), tostring(classID), tostring(subClassID)),
            isQuestItem = tostring(questInfo and questInfo.isQuestItem),
            questID     = tostring(questInfo and questInfo.questID),
            isActive    = tostring(questInfo and questInfo.isActive),
            hasSpell    = tostring(C_Item.GetItemSpell(itemID) ~= nil),
            isUsable    = tostring(C_Item.IsUsableItem(itemID)),
            professions = KnownProfessions(),
            verdict     = verdict,
            allowList   = ClassifyIgnoringAllowList(bag, slot, itemID, classID),
            lines       = {},
        }

        local data = C_TooltipInfo.GetBagItem(bag, slot)
        if data and data.lines then
            for index, line in ipairs(data.lines) do
                dump.lines[index] = ("type=%s | left=%s | right=%s"):format(
                    tostring(line.type), tostring(line.leftText), tostring(line.rightText))
            end
        end

        return dump
    end

    -- The scalar keys BuildDump's table literal writes, excluding "lines" (that
    -- one is rendered separately, as tooltip[n] rather than a field=value line).
    -- Fixed here rather than read with pairs: a table literal's pairs() order is
    -- unspecified, and a report has to render identically for every player who
    -- copies one out, not reshuffle from one /reload to the next.
    local DUMP_FIELDS = {
        "itemID",
        "name",
        "where",
        "isLocked",
        "class",
        "isQuestItem",
        "questID",
        "isActive",
        "hasSpell",
        "isUsable",
        "professions",
        "verdict",
        "allowList",
    }

    --- One item's classification as text a player can select and paste.
    ---
    --- Published rather than file-local because both entry points render the
    --- same way and must go on doing so: view/button.lua's report gesture and
    --- debug/dumps.lua's /bfdump dispatch open differ only in how they resolve
    --- the item, and a second renderer is how the player's report and the
    --- developer's drift apart.
    ---@param bag number
    ---@param slot number
    ---@param itemID number
    ---@return string
    function control.OpenReportText(bag, slot, itemID)
        local dump = BuildDump(bag, slot, itemID)
        local lines = {
            "BitForge Dispatch -- classification report",
            BitForge:ReportHeader(ADDON_NAME),
            "",
        }

        for _, field in ipairs(DUMP_FIELDS) do
            lines[#lines + 1] = format("%s = %s", field, tostring(dump[field]))
        end

        -- This is the open claimant's answer in isolation, and the arbiter
        -- can let another claimant outrank or suppress it -- which is what
        -- actually decides the button. A source comment saying so is not
        -- enough; the player reading this pasted report has to be told it too.
        --
        -- Never end it by naming a command to run. It used to point at
        -- /bfdump dispatch <itemID>, which does answer this through the
        -- arbiter -- but only debug/dumps.lua answers that command and a
        -- release build ships no such file, so every player following the
        -- pointer got the "no such command" refusal, and an instruction that
        -- fails is worse than none. Printing it only when the file is present
        -- is the other thing not to do: the player's report reads identically
        -- in every build, which is what spec #405 section 5 protects.
        lines[#lines + 1] = ""
        lines[#lines + 1] = "note = this is the open path's own answer only -- the arbiter can let"
            .. " another claimant outrank or suppress it, which is what actually decides"
            .. " the button"

        if #dump.lines > 0 then
            lines[#lines + 1] = ""
            for index, line in ipairs(dump.lines) do
                lines[#lines + 1] = format("tooltip[%d] = %s", index, line)
            end
        end

        return concat(lines, "\n")
    end

end

-- The sell path's own verdict as the player pastes it: the item, what is
-- equipped in the slot it would fill, the settings that judged the pair, and
-- the rule that decided. view/merchantPanel.lua's Report This Verdict is the
-- gesture that shows it, and debug/dumps.lua's /bfdump dispatch sell renders
-- through the same control.RenderSellReport -- that one resolves the item from
-- an ID rather than from a bag slot, which is the whole of the difference.
do
    -- Every field is flattened with tostring. Item data can carry secret values
    -- in 12.0, and the report is meant to be pasted into an issue verbatim.
    local function Flatten(value)
        return tostring(value)
    end

    -- The paired half. equippedItems feeds the pure comparison and carries only
    -- what that reads, so the slot and link are gathered again here -- a record
    -- naming neither cannot be checked against the character it came from.
    --
    -- The two gaps are computed rather than left implicit: they are what the
    -- comparison actually branches on, and a reader should not have to subtract
    -- to find out why a verdict landed.
    local function EquippedPairs(facts)
        local slots = enum.SLOT_LOOKUP[facts.equipLoc]
        if not slots then return nil end

        local paired = {}
        for _, slotID in ipairs(slots) do
            local link = GetInventoryItemLink("player", slotID)
            if link then
                local level = C_Item.GetDetailedItemLevelInfo(link)
                local quality = select(3, C_Item.GetItemInfo(link))
                paired[#paired + 1] = {
                    slot       = Flatten(slotID),
                    link       = Flatten(link),
                    level      = Flatten(level),
                    quality    = Flatten(quality),
                    qualityGap = level and quality
                        and Flatten(facts.quality - quality) or "unreadable",
                    itemGap    = level and quality
                        and Flatten(facts.level - level) or "unreadable",
                }
            end
        end
        return paired
    end

    -- Only the settings the gear comparison consults. The whole snapshot would
    -- bury them, and these are the ones that explain a surprising verdict.
    local function DecidingSettings(settings)
        local gear = settings.rules and settings.rules.gear or {}
        -- The top position is a word on the slider for a reason: pasted into an
        -- issue as a bare 32 it reads as thirty-two item levels, the exact
        -- misreading the word exists to prevent.
        local qualityMargin = gear.qualityMargin >= enum.QUALITY_MARGIN_ALWAYS
            and "ALWAYS" or Flatten(gear.qualityMargin)
        return {
            margin             = Flatten(gear.margin),
            qualityMargin      = qualityMargin,
            spareBindOnAccount = Flatten(gear.spareBindOnAccount),
            keepForDisenchant  = Flatten(gear.keepForDisenchant),
            playerClass        = Flatten(settings.playerClass),
            isEnchanter        = Flatten(settings.isEnchanter),
        }
    end

    local function BuildDump(report)
        local facts = report.facts
        return {
            itemID     = Flatten(facts.itemID),
            name       = Flatten(facts.name),
            link       = Flatten(facts.itemLink),
            quality    = Flatten(facts.quality),
            level      = Flatten(facts.level),
            equipLoc   = Flatten(facts.equipLoc),
            class      = ("%s/%s"):format(Flatten(facts.classID), Flatten(facts.subclassID)),
            bindType   = Flatten(facts.bindType),
            expacID    = Flatten(facts.expacID),
            sellPrice  = Flatten(facts.sellPrice),
            listStatus = ("blacklisted=%s whitelisted=%s"):format(Flatten(facts.isProhibited), Flatten(facts.isEnforced)),
            equipped   = EquippedPairs(facts),
            verdict    = Flatten(report.verdict),
            rule       = Flatten(report.rule),
            settings   = DecidingSettings(report.settings),
        }
    end

    -- Fixed here rather than taken from pairs: a report whose lines shuffle
    -- between two players is a report nobody can diff.
    local DUMP_FIELDS = {
        "itemID", "name", "link", "quality", "level", "equipLoc", "class",
        "bindType", "expacID", "sellPrice", "listStatus", "verdict", "rule",
    }

    local EQUIPPED_FIELDS = { "slot", "link", "level", "quality", "qualityGap", "itemGap" }

    local SETTING_FIELDS = {
        "margin", "qualityMargin", "spareBindOnAccount", "keepForDisenchant",
        "playerClass", "isEnchanter",
    }

    --- One already-resolved report as text.
    ---
    --- Published rather than file-local because both entry points render the
    --- same way and must go on doing so: control.SellReportText below takes a
    --- bag slot, for view/merchantPanel.lua's Report This Verdict, and
    --- debug/dumps.lua's /bfdump dispatch sell takes an item ID. BuildDump has
    --- already flattened every value with tostring, which is what makes an
    --- item's secret values safe to put in front of a player in 12.0.
    ---@param report table  sellScanner.Explain's or ExplainByID's own return
    ---@return string
    function control.RenderSellReport(report)
        local dump = BuildDump(report)
        local lines = {
            "BitForge Dispatch -- sell verdict report",
            BitForge:ReportHeader(ADDON_NAME),
            "",
        }

        for _, field in ipairs(DUMP_FIELDS) do
            lines[#lines + 1] = format("%s = %s", field, dump[field])
        end

        -- Absent for an item that fills no slot, which is most of them.
        if dump.equipped then
            lines[#lines + 1] = ""
            for index, entry in ipairs(dump.equipped) do
                for _, field in ipairs(EQUIPPED_FIELDS) do
                    lines[#lines + 1] = format("equipped[%d] %s = %s", index, field, entry[field])
                end
            end
        end

        lines[#lines + 1] = ""
        for _, field in ipairs(SETTING_FIELDS) do
            lines[#lines + 1] = format("settings.%s = %s", field, dump.settings[field])
        end

        return concat(lines, "\n")
    end

    --- One item's whole verdict as text a player can select and paste, for
    --- the item currently under the tooltip's cursor.
    ---@param bagIndex number
    ---@param slotIndex number
    ---@return string|nil  nil when the slot is empty or its item data has not arrived
    function control.SellReportText(bagIndex, slotIndex)
        local report = sellScanner.Explain(bagIndex, slotIndex)
        if not report then return nil end

        return control.RenderSellReport(report)
    end
end

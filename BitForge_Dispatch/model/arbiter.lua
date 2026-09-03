---@class BitForge.Dispatch
local ns = select(2, ...)

local ipairs = ipairs
local pcall = pcall
local rawget = rawget
local rawset = rawset
local tostring = tostring
local format = string.format
local huge = math.huge

---@class BitForge.Dispatch.Model
local model = ns.model
---@type BitForge.Dispatch.Enum
local enum = ns.enum

local CLAIM = enum.CLAIM

--- Registered claimants, in registration order. Order decides nothing about
--- who wins -- see FIXED_ORDER below -- only the order `claims` lists them in.
local REGISTRY = {}

--- One entry per claimant name AND error message once it has raised, so a
--- broken claimant is reported once per session rather than once per Resolve
--- call. Mirrors bankRules.lua's reportedSpells for the same reason: the
--- player needs to know, but not on every scan.
---
--- Keyed on the cause as well as the name because a claimant is not one bug: a
--- key of the name alone folded every LATER, differently caused failure from
--- that claimant into the first one and reported none of them, which is worse
--- than the storm it was folding. A raise carries its file:line, so one bug is
--- one key however many items it fires for, which is what still folds the
--- storm. What it cannot fold is a message that varies per item; nothing here
--- produces one today, and a claimant that formatted an itemID into its error
--- would report once per item again.
local printedFailures = {}

--- The fixed precedence among non-promoted claims, spec #331 section 4.
--- DEPOSIT_WARBAND and DEPOSIT_PRIVATE share a tier: bankRules never claims
--- both for the same item, so nothing here arbitrates between them.
local FIXED_ORDER = {
    [CLAIM.OPEN]            = 1,
    [CLAIM.DEPOSIT_WARBAND] = 2,
    [CLAIM.DEPOSIT_PRIVATE] = 2,
    [CLAIM.SELL]            = 3,
}

-- One tier worse than SELL, assigned only to a non-promoted OPEN claim at
-- enum.PRIORITY.USE when a positive SELL claim exists. USE means no more
-- than "the client says this does something" (Init.lua's PRIORITY comment),
-- and left at OPEN's normal rank it would keep a grey vendor-trash item with
-- a Use: line from ever being sold. The other four OPEN tiers are untouched,
-- and a *promoted* USE claim is untouched too -- see rank() below.
local DEMOTED_USE_ORDER = FIXED_ORDER[CLAIM.SELL] + 1

---@class BitForge.Dispatch.Model.Arbiter
local arbiter = {}

--- name -> the REGISTRY row registered under it. A duplicate is refused rather
--- than appended: the name is the only thing that identifies a claimant in a
--- claims entry, so a second registration under one name would make /bfdump
--- attribute a win to whichever row it matched first. Holds the row rather
--- than a bare true so arbiter.Claim below can reach one claimant by name.
local registeredNames = {}

--- Registers one claimant. Called once at file scope by each of the three
--- rule sets (spec #331 Tasks 2-4), never from inside Resolve.
---@param name string  identifies this claimant in every claims entry and dump
---@param fn fun(facts: table): string|nil, number|nil, string|nil, boolean|nil, any
---   claim, strength, reason, overridden, detail -- the five callClaimant
---   destructures. A claimant may return more (model.openRules returns seven);
---   everything past the fifth is dropped, and callClaimant's own comment is
---   where widening is argued.
function arbiter.Register(name, fn)
    assert(not registeredNames[name], "arbiter: claimant already registered: " .. tostring(name))
    local entry = { name = name, fn = fn }
    registeredNames[name] = entry
    REGISTRY[#REGISTRY + 1] = entry
end

--- Calls one claimant, guarded against it throwing.
---
--- A thrown error is recorded as an ordinary abstention (claim = nil) rather
--- than propagated -- spec #331 section 8: today an exception in one module
--- leaves the other two working, and this is what keeps that true once a
--- single resolver stands in front of all three. The player still has to
--- find out, so the failure prints once per claimant per session; every
--- Resolve after the first stays silent about it, which is what makes "once"
--- true instead of "once per item".
---
--- Two channels, one guard. The print names WHICH claimant broke, which a raw
--- error never did; CallErrorHandler is what puts the failure in front of the
--- client's own handler, and therefore BugGrabber, which is where this addon's
--- bug reports come from.
---
--- What reaches it is pcall's message, carrying the raising file and line, and
--- a stack rooted HERE rather than at the raise: pcall has already unwound by
--- the time this runs. xpcall would keep the real one, but Lua 5.1's takes no
--- arguments past the handler, so every claimant call would allocate a closure
--- for every item in the bags to pass `facts` through -- too much to pay on
--- this path for a traceback whose top frame the message already names.
---
--- Both sit behind printedFailures rather than only the print: a claimant that
--- raises does so for every item in the bags, and the open path now resolves
--- on every bag change, so an ungated report would be dozens of captures per
--- bag event instead of one.
---@param entry table  a REGISTRY row
---@param facts table
---@return table  a claims entry
local function callClaimant(entry, facts)
    -- Five returns, and everything past them is dropped here. `detail` is the
    -- fifth because control/openScanner.lua reads it back off the verdict: it
    -- is the one open-path diagnostic no record can answer for -- the tooltip
    -- line type that accepted the item -- and once the arbiter decides which
    -- item reaches the button, calling the open claimant a second time to
    -- recover it would break the one-resolution-per-record rule. The two
    -- claimants that are not model.openRules return exactly four values, so
    -- the fifth is nil for them by construction rather than by agreement.
    --
    -- Returns 6 and 7 (isLocked, startsQuest) stay dropped, and widening to
    -- them is what still needs an audit: both are open-path facts a record
    -- already answers, and binding them here would give a future claimant's
    -- unrelated sixth return a meaning with no type error to show for it.
    local ok, claim, strength, reason, overridden, detail = pcall(entry.fn, facts)

    if not ok then
        local cause = tostring(claim)
        local seen = entry.name .. "\0" .. cause
        if not printedFailures[seen] then
            printedFailures[seen] = true
            BitForge:Print(format("Dispatch: the %s claimant failed -- %s", entry.name, cause))
            CallErrorHandler(claim)
        end
        return { claimant = entry.name, claim = nil, failed = true, reason = cause }
    end

    return {
        claimant   = entry.name,
        claim      = claim,
        strength   = strength,
        reason     = reason,
        overridden = overridden,
        detail     = detail,
    }
end

--- One claim entry's rank for winner selection: `promoted` decides first
--- (any promoting override outranks the whole fixed order, spec #331
--- section 4), `order` breaks a tie within the same `promoted` value --
--- "then the fixed order decides", including between two *different*
--- claimants that both happen to carry a promoting override. A promoted
--- USE-tier OPEN claim keeps its ordinary FIXED_ORDER place rather than the
--- demotion below: that demotion exists only to protect the *ordinary*,
--- unpromoted USE tier from outranking a real sell decision, not to
--- second-guess a claimant that already told Resolve this claim came from
--- an explicit "always" (see arbiter.Resolve's own comment for why Resolve
--- trusts that flag rather than re-deriving it).
---@param claimEntry table
---@param hasSell boolean  whether some claimant returned a positive SELL claim
---@return boolean promoted
---@return number order  break ties within the same `promoted` value
local function rank(claimEntry, hasSell)
    local promoted = claimEntry.overridden == true

    if not promoted and claimEntry.claim == CLAIM.OPEN
        and claimEntry.strength == enum.PRIORITY.USE and hasSell
    then
        return false, DEMOTED_USE_ORDER
    end

    return promoted, FIXED_ORDER[claimEntry.claim] or huge
end

--- The single winning claim, or nil when every claimant abstained.
---
--- A suppressing override -- Openables' blacklist, DESTINATION.IGNORE -- never
--- reaches here as a distinct case: the claimant that read it already turned
--- it into claim = nil, which this function treats exactly like any other
--- abstention. "A suppressing override... lifts nobody" is therefore not a
--- rule this function implements -- it is what NOT having one looks like.
---@param claims table  array of claims entries
---@return table|nil
local function pickWinner(claims)
    local hasSell = false
    for _, entry in ipairs(claims) do
        if entry.claim == CLAIM.SELL then hasSell = true end
    end

    local best, bestPromoted, bestOrder
    for _, entry in ipairs(claims) do
        if entry.claim then
            local promoted, order = rank(entry, hasSell)
            local better = not best
                or (promoted and not bestPromoted)
                or (promoted == bestPromoted and order < bestOrder)
            if better then
                best, bestPromoted, bestOrder = entry, promoted, order
            end
        end
    end

    return best
end

--- Where a record carries the claims entries already collected for it, keyed
--- by claimant name, and where it carries the verdict those produced. Both
--- live on the record for the same reason and with the same lifetime; see
--- arbiter.Resolve below.
local CLAIMS_KEY = "__claims"

--- One claimant's entry for this record, asked once and remembered for the
--- rest of the record's life.
---
--- Exposed rather than private because control/openScanner.lua asks the open
--- claimant on its own: it runs for every occupied slot on every bag update,
--- and an item the open claimant abstains on cannot be awarded OPEN whatever
--- the other two answer -- so resolving it in full buys nothing and costs a
--- GetContainerItemPurchaseInfo per slot and a live tooltip scan per
--- equippable, on a path with no merchant open. Asking through here rather
--- than calling model.openRules.Claim directly is what keeps that first ask
--- and Resolve's own from being two: Resolve below collects every entry the
--- same way, so one already taken is reused rather than recomputed.
---@param facts table  a model.facts record
---@param name string  a registered claimant's name
---@return table  a claims entry
function arbiter.Claim(facts, name)
    local entry = registeredNames[name]
    assert(entry, "arbiter: no claimant registered as " .. tostring(name))

    local collected = rawget(facts, CLAIMS_KEY)
    if not collected then
        collected = {}
        rawset(facts, CLAIMS_KEY, collected)
    end

    local claimed = collected[name]
    if not claimed then
        claimed = callClaimant(entry, facts)
        collected[name] = claimed
    end
    return claimed
end

--- Where a record carries the verdict already awarded for it.
---
--- Hung on the record itself rather than kept in a table here, so the memo's
--- lifetime IS the record's: model.facts.Invalidate wipes the record cache, so
--- the next generation's Get builds a fresh table and a stale verdict has
--- nothing left to sit on. Nothing here needs invalidating and nothing here can
--- leak. A caller-built plain table -- sellScanner.GatherByID's own facts, a
--- test's stub -- is memoised the same way and discarded with the table.
---
--- What a record does NOT hold is the evidence a claimant reads from somewhere
--- else: the player's `open` opinion and the session skips beside it, the rule
--- tree, a bank destination, the profession names control/detector.lua
--- rebuilds. Each of those turns the generation over where it is changed,
--- which is the discipline model/overrides.lua's SetField states for the
--- merged store -- the setter invalidates, so no caller has to remember to.
local VERDICT_KEY = "__verdict"

--- Awards one item exactly one disposition. Spec #331 sections 3-4.
---
--- The claimant contract carries a fourth return, `overridden`, beyond the
--- spec's three (#357, "the contract has four returns, not three"):
--- model.Decide already reads the sell lists internally to short-circuit at
--- RULE.WHITELISTED / RULE.BLACKLISTED, so having Resolve *also* read
--- model.facts.EffectiveSell -- or model.overrides.GetOpen and GetBank for
--- the other two opinions -- would judge the same user action twice, and a
--- "never" entry could be read as grounds to suppress a claim that was never
--- made. `overridden` is how a claimant that already consulted its own store
--- tells Resolve the claim in front of it *is* that override, so promotion
--- never needs a second, independent read of a store this function does not
--- own.
---
--- Which scope produced a promoting override is likewise left to the
--- claimant. Only the sell opinion has two (db.char.itemOverrides beats
--- db.global.itemOverrides, which model.facts.EffectiveSell implements): by
--- the time a claim reaches Resolve, character has already been chosen over
--- warband, and `overridden` carries that resolved answer as a single boolean
--- rather than Resolve inventing a scope concept the other two opinions do
--- not have.
---
--- Awarded once per record, not once per consumer. The open path and the sell
--- path both resolve the same slot in a generation, and each claimant must be
--- asked exactly once between them -- two answers to one question is the
--- disagreement this whole plan exists to end, and asking the ladder twice
--- would pay for it twice besides.
---@param facts table  a model.facts record
---@return table verdict  disposition, claimant, strength, reason, detail,
---   promoted, claims
function arbiter.Resolve(facts)
    local memoised = rawget(facts, VERDICT_KEY)
    if memoised then return memoised end

    local claims = {}
    for _, entry in ipairs(REGISTRY) do
        claims[#claims + 1] = arbiter.Claim(facts, entry.name)
    end

    local winner = pickWinner(claims)
    local verdict
    if not winner then
        verdict = {
            disposition = CLAIM.KEEP,
            claimant    = nil,
            strength    = nil,
            reason      = nil,
            detail      = nil,
            promoted    = false,
            claims      = claims,
        }
    else
        verdict = {
            disposition = winner.claim,
            claimant    = winner.claimant,
            strength    = winner.strength,
            reason      = winner.reason,
            detail      = winner.detail,
            promoted    = winner.overridden == true,
            claims      = claims,
        }
    end

    rawset(facts, VERDICT_KEY, verdict)
    return verdict
end

model.arbiter = arbiter

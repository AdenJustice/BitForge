local _, ns = ...

ns.DB_DEFAULTS = {
    global = {
        -- Warband-wide lists
        blacklist = {},
        whitelist = {},
    },
    char = {
        -- Sell behaviour
        limitBatchTo12               = true,
        sellJunk                     = true,
        -- Keep rules
        keepEquippable               = true,
        keepBindOnAccount            = true,
        keepBindOnAccountPastExpac   = false,
        keepDisenchantables          = false,
        keepDisenchantablesPastExpac = false,
        -- Quality / ilvl filters
        qualityThreshold             = 2, -- Uncommon
        ilvlThreshold                = -20,
        -- Expansion filter
        sellPastExpansion            = false,
        expansionThreshold           = 0, -- 0 = disabled (all expansions)
        -- Character-specific lists
        charBlacklist                = {},
        charWhitelist                = {},
    },
}

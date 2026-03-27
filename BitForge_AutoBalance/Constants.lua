local _, ns = ...

ns.BALANCE_OPTIONS = { 1000, 5000, 10000, 20000, 50000, 100000 }

ns.COPPER_PER_GOLD = 10000

ns.DB_DEFAULTS = {
    global = {
        collectorName = "",
        marginalRatio = 0.1,
        desiredBalance = 10000,
    },
    char = {},
}

local AbbreviateNumbers = AbbreviateNumbers

function BitForge:Print(...)
    print("|cff00ccff[BitForge]|r ", ...)
end

function BitForge:Debug(...)
    if BitForge.DEBUG then
        print("|cff888888[BitForge:Debug]|r", ...)
    end
end

function BitForge:ShortValue(n)
    return AbbreviateNumbers(n)
end

-- Distribute children width as evenly as possible
---@param n number total length
---@param k number number of entity
---@param g number spacing
---@return number[] width table
function BitForge:DistributeEvenly(n, k, g)
    assert(k > 0, "k must be positive")
    assert(n >= (k - 1) * g + k, "Not enough total length")

    local S = n - (k - 1) * g
    local q = math.floor(S / k)
    local r = S % k

    -- distribute base value
    local lengths = {}
    for i = 1, k do
        lengths[i] = q
    end

    -- distribute risiduals
    local left = 1
    local right = k
    local count = 0

    while count < r do
        if left <= right then
            lengths[left] = lengths[left] + 1
            count = count + 1
            left = left + 1
        end

        if count < r and left <= right then
            lengths[right] = lengths[right] + 1
            count = count + 1
            right = right - 1
        end
    end

    return lengths
end

-- Returns interpolated RGB between two color tables at position t (0→1).
-- Color tables are indexed as { r, g, b } (WoW color table convention).
function BitForge:LerpColor(cA, cB, t)
    return
        cA[1] + t * (cB[1] - cA[1]),
        cA[2] + t * (cB[2] - cA[2]),
        cA[3] + t * (cB[3] - cA[3])
end

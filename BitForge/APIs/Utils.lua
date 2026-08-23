local AbbreviateNumbers = AbbreviateNumbers

function BitForge:Print(...)
    print("|cff00ccff[BitForge]|r ", ...)
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

--- The ColorMixin for the class a character plays, or nil.
---
--- Two nil paths, independent of each other and neither a fault. Core learns a
--- class only when that character logs in, so on an account played for years
--- every alt reads classless until it is next played; and
--- C_ClassColor.GetClassColor MayReturnNothing for a class file the client does
--- not recognise. A caller renders the character unadorned in either case.
---
--- The colour comes back bare rather than wrapped around a string, because the
--- callers want different things done with it -- TaskTome dims it for a
--- finished row before wrapping the character name, RepRank paints a bar and
--- wraps nothing. A helper that returned markup would serve only one of them.
---@param charKey string  as returned by BitForge:GetCurrentCharacter()
---@return ColorMixin|nil
function BitForge:GetCharacterClassColor(charKey)
    local classFile = self:GetCharacterClass(charKey)
    if not classFile then return nil end

    -- Called for its single return rather than tail-called: MayReturnNothing
    -- means no values at all, and this promises exactly one.
    local color = C_ClassColor.GetClassColor(classFile)
    return color
end

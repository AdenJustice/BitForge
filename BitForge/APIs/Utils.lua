local AbbreviateNumbers = AbbreviateNumbers
local format = string.format
local C_AddOns = C_AddOns
local GetBuildInfo = GetBuildInfo
local GetLocale = GetLocale

-- Every chat line the suite prints carries this tag, so it is wrapped once at
-- file-read time rather than per call. CreateColor is SharedXMLBase and stands
-- long before any addon loads.
local PREFIX = CreateColor(0, 0.8, 1):WrapTextInColorCode("[BitForge]")

function BitForge:Print(...)
    print(PREFIX, ...)
end

function BitForge:ShortValue(n)
    return AbbreviateNumbers(n)
end

--- The four lines every report opens with, so no module writes them twice.
---
--- The version is whatever the .toc carries. In a development checkout that is
--- the literal @project-version@, which is correct information for a report
--- rather than something to hide -- a report from an unreleased build should
--- say so.
---@param addonName string
---@return string
function BitForge:ReportHeader(addonName)
    return format("addon = %s\nversion = %s\ninterface = %s\nlocale = %s",
        addonName,
        tostring(C_AddOns.GetAddOnMetadata(addonName, "Version")),
        tostring(select(4, GetBuildInfo())),
        GetLocale())
end

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

    local lengths = {}
    for i = 1, k do
        lengths[i] = q
    end

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

-- cA and cB are { r, g, b } arrays, not ColorMixins; t runs 0 to 1.
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
--- The colour comes back bare rather than as markup: TaskTome dims it for a
--- finished row before wrapping the character name, RepRank paints a bar and
--- wraps nothing.
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

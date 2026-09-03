-- Above this many rendered bytes a report is encoded rather than shown as text.
-- Measured, not taste: every single-item dump in the suite is under 2 KB and
-- every multi-item walk is above 4, so the split falls between a report a
-- player might actually read and one they never would.
local COMPRESS_THRESHOLD = 4096

--- Text as a printable string a player can paste into an issue.
---
--- Raw deflate, then LibDeflate's own 6-bit alphabet -- NOT base64, and the
--- decoder in Scripts/ has to match it exactly. Encoding costs 25% over the
--- compressed bytes and buys a payload with no newlines, no quoting and nothing
--- a forum or an issue tracker will reflow.
---
--- LibDeflate registers with LibStub and never assigns _G.LibDeflate, so it is
--- reachable only through LibStub's registry.
---
--- Returns nil when the library is missing rather than raising: a diagnostic
--- that errors is worse than one that falls back to plain text.
---@param text string
---@return string|nil
function BitForge:EncodeForPaste(text)
    local lib = LibStub and LibStub:GetLibrary("LibDeflate", true)
    if not lib then return nil end
    local compressed = lib:CompressDeflate(text)
    if not compressed then return nil end
    return lib:EncodeForPrint(compressed)
end

BitForge.COMPRESS_THRESHOLD = COMPRESS_THRESHOLD

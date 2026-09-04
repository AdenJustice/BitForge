---@type BitForge.Core
local ns = select(2, ...)
---@class BitForge.Core.View
local view = ns.view
---@type BitForge.Core.Locale
local locale = ns.locale
---@type BitForge.Core.Model
local model = ns.model

local UI = BitForge.UI

local ipairs = ipairs

local cos = math.cos
local sin = math.sin
local rad = math.rad
local deg = math.deg
local sqrt = math.sqrt
local max = math.max
local min = math.min

-- math.atan2 is the client's Lua 5.1 spelling; Lua removed it in 5.3 in favour
-- of two-argument math.atan, and the headless test runner is 5.5. Binding both
-- keeps one implementation correct in the game and in the suite.
local atan2 = math.atan2 or math.atan

local Settings = Settings
local C_AddOns = C_AddOns
local CreateFrame = CreateFrame
local Minimap = Minimap
local GameTooltip = GameTooltip
local GetCursorPosition = GetCursorPosition
local UIParent = UIParent

---@param modules { name: string, title: string, enabled: boolean }[]
---@param callbacks table<string, { getValue: fun(), setValue: fun(value: boolean) }>
function view:Register(modules, callbacks)
    local category = Settings.RegisterVerticalLayoutCategory("BitForge")
    Settings.RegisterAddOnCategory(category)
    BitForge.settingsCategory = category

    for _, mod in ipairs(modules) do
        local name, title = mod.name, mod.title
        local cb = callbacks[name]

        local setting = Settings.RegisterProxySetting(
            category, name,
            Settings.VarType.Boolean, title,
            mod.enabled,
            cb.getValue,
            cb.setValue
        )
        Settings.CreateCheckbox(category, setting, title)
    end
end

---@class BitForge.Core.View.MinimapButton
local minimapButton = {}

-- How far past the minimap's edge the button's centre sits.
local EDGE_RADIUS = 5

-- A square corner reaches further from the centre than the circle does, so a
-- button in a square quadrant is projected along the diagonal and pulled back
-- by this much before being clamped.
local CORNER_INSET = 10

-- Minimap outlines that UI addons publish through the community GetMinimapShape
-- global. Each entry says, per quadrant, whether that corner is rounded, indexed
-- { bottom-right, bottom-left, top-right, top-left }.
local MINIMAP_SHAPES = {
    ["ROUND"]                 = { true, true, true, true },
    ["SQUARE"]                = { false, false, false, false },
    ["CORNER-TOPLEFT"]        = { false, false, false, true },
    ["CORNER-TOPRIGHT"]       = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"]     = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"]    = { true, false, false, false },
    ["SIDE-LEFT"]             = { false, true, false, true },
    ["SIDE-RIGHT"]            = { true, false, true, false },
    ["SIDE-TOP"]              = { false, false, true, true },
    ["SIDE-BOTTOM"]           = { true, true, false, false },
    ["TRICORNER-TOPLEFT"]     = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"]    = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"]  = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

--- Where the button sits on the minimap's ring for a given angle. Pure: every
--- dimension arrives as an argument so the shape table can be tested headlessly.
---@param angle number degrees, 0 = due east, counter-clockwise
---@param width number the minimap's width
---@param height number the minimap's height
---@param radius number how far past the edge the button's centre sits
---@param shape string|nil a MINIMAP_SHAPES key; nil or unknown falls back to ROUND
---@return number x, number y offsets from the minimap's centre
function minimapButton.ComputeOffset(angle, width, height, radius, shape)
    local radians = rad(angle)
    local x, y = cos(radians), sin(radians)

    local quadrant = 1
    if x < 0 then quadrant = quadrant + 1 end
    if y > 0 then quadrant = quadrant + 2 end

    local quadrants = MINIMAP_SHAPES[shape] or MINIMAP_SHAPES["ROUND"]
    local halfWidth = (width / 2) + radius
    local halfHeight = (height / 2) + radius

    if quadrants[quadrant] then
        return x * halfWidth, y * halfHeight
    end

    local diagonalWidth = sqrt(2 * halfWidth ^ 2) - CORNER_INSET
    local diagonalHeight = sqrt(2 * halfHeight ^ 2) - CORNER_INSET
    return max(-halfWidth, min(x * diagonalWidth, halfWidth)),
        max(-halfHeight, min(y * diagonalHeight, halfHeight))
end

--- The angle the cursor sits at relative to the minimap's centre. Pure.
---@param cursorX number cursor position in screen pixels
---@param cursorY number cursor position in screen pixels
---@param centerX number the minimap's centre
---@param centerY number the minimap's centre
---@param scale number the minimap's effective scale
---@return number angle degrees in [0, 360)
function minimapButton.AngleFromCursor(cursorX, cursorY, centerX, centerY, scale)
    return deg(atan2(cursorY / scale - centerY, cursorX / scale - centerX)) % 360
end

local BUTTON_SIZE = 32
local ICON_SIZE = 18
local BACKGROUND_SIZE = 24
local BORDER_SIZE = 50

-- How far the icon's visible area pulls in while the button is held, so a
-- draggable control acknowledges the grab.
local PRESS_INSET = 0.05

-- Cropping PRESS_INSET off each edge and refilling the same area magnifies by
-- 1 / (1 - 2 * inset). The mask is held at ICON_SIZE, so growing the icon to
-- this size is that same zoom -- expressed the only way a masked texture
-- allows, since SetTexCoord is rejected once a texture carries a mask.
local PRESS_SIZE = ICON_SIZE / (1 - 2 * PRESS_INSET)

local SUITE_ICON = "Interface\\AddOns\\BitForge\\Media\\icon"

local button

--- Builds and shows the shared "BitForge" tooltip, anchored to the given frame,
--- with one AddLine per hint key. The single construction point for both the
--- minimap button itself and the addon-compartment entry, so the control layer
--- never has to touch GameTooltip.
---@param anchor Frame
---@param ... string locale keys, added as tooltip lines in order
function minimapButton.ShowTooltip(anchor, ...)
    GameTooltip:SetOwner(anchor, "ANCHOR_LEFT")
    GameTooltip:SetText("BitForge", 1, 1, 1, 1)
    for index = 1, select("#", ...) do
        GameTooltip:AddLine(locale[(select(index, ...))], 1, 1, 1)
    end
    GameTooltip:Show()
end

--- Builds the button. Deferred rather than run at file-read time: the frame
--- needs the minimap's real dimensions, and view.lua has to stay loadable in the
--- headless harness, which stubs no CreateFrame.
---@param onClick fun(button: Button)
---@param onPositionChanged fun(angle: number)
function minimapButton.Create(onClick, onPositionChanged)
    if button then return end

    button = CreateFrame("Button", "BitForgeMinimapButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFixedFrameStrata(true)
    button:SetFrameLevel(8)
    button:SetFixedFrameLevel(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("CENTER")
    icon:SetTexture(SUITE_ICON)

    -- Anchored to the button rather than applied with SetMask, so the circle
    -- stays put while the icon resizes underneath it. SetMask binds the mask to
    -- the icon's own rectangle, which would scale the crop along with the press
    -- instead of zooming within it. The wrap modes are what SetMask supplied
    -- implicitly and have to be named when the mask is built by hand.
    local iconMask = button:CreateMaskTexture()
    iconMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask",
        "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetSize(ICON_SIZE, ICON_SIZE)
    iconMask:SetPoint("CENTER")
    icon:AddMaskTexture(iconMask)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local draggedAngle

    local function ResetPressState()
        icon:SetSize(ICON_SIZE, ICON_SIZE)
    end

    local function OnUpdate()
        local centerX, centerY = Minimap:GetCenter()
        if not centerX then return end

        local cursorX, cursorY = GetCursorPosition()
        draggedAngle = minimapButton.AngleFromCursor(
            cursorX, cursorY, centerX, centerY, Minimap:GetEffectiveScale())
        minimapButton.SetPosition(draggedAngle)
    end

    button:SetScript("OnDragStart", function(self)
        draggedAngle = nil
        self:LockHighlight()
        self:SetScript("OnUpdate", OnUpdate)
        GameTooltip:Hide()
    end)

    -- The angle is written once, when the drag settles. LibDBIcon writes it on
    -- every OnUpdate frame; there is no reason to touch the saved table 60
    -- times a second when only the resting position matters.
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
        -- A drag-ending release is not guaranteed to also deliver OnMouseUp,
        -- so the press inset has to be undone here too, not only there.
        ResetPressState()
        if draggedAngle then
            onPositionChanged(draggedAngle)
        end
    end)

    button:SetScript("OnMouseDown", function()
        icon:SetSize(PRESS_SIZE, PRESS_SIZE)
    end)

    button:SetScript("OnMouseUp", ResetPressState)

    -- The client suppresses OnClick on a frame that handled a drag, so no
    -- click-versus-drag guard is needed here.
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            onClick(self)
        end
    end)

    button:SetScript("OnEnter", function(self)
        minimapButton.ShowTooltip(self, "minimap:hintClick", "minimap:hintDrag")
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Moves the button to an angle on the ring. Safe to call before Create.
---@param angle number degrees
function minimapButton.SetPosition(angle)
    if not button then return end

    -- GetMinimapShape is a convention other UI addons publish, not a Blizzard
    -- API -- it appears nowhere in wow-ui-source -- so it is read off _G with a
    -- guard rather than as a bare global: whichever addon defines it may not be
    -- installed at all.
    local shape = _G.GetMinimapShape and _G.GetMinimapShape() or "ROUND"
    local x, y = minimapButton.ComputeOffset(
        angle, Minimap:GetWidth(), Minimap:GetHeight(), EDGE_RADIUS, shape)

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

view.minimapButton = minimapButton

-- One window, reused. Two modules open this, and a second instance would leave
-- the first on screen carrying another module's item.
local reportWindow

--- The report window's title for a diagnostic dump (/bfdump), as opposed to
--- the item-report default ShowReport falls back to. An element's frame
--- geometry or a bag's whole ranked field is not "an item," so the window
--- should not claim it is one.
---@return string
function BitForge:DiagnosticReportTitle()
    return locale["report:windowTitleDiagnostic"]
end

--- Shows a module's report, focused and selected, ready for the player's Ctrl+C.
---
--- Core owns the window because modules never call siblings, and owns nothing
--- else: the payload, the sentence about what it discloses and the title all
--- arrive from the caller. What is disclosed varies -- AzerothPrime's sell verdict
--- sends an item link, which states the character's level and specialization in
--- its own fields, while its open-item report sends no link at all -- and an
--- item report and a diagnostic dump are not describing the same thing.
---@param body  string  the report text
---@param blurb string  the calling module's own sentence about what it discloses
---@param title string?  defaults to locale["report:windowTitle"]; a diagnostic
---                       dump passes BitForge:DiagnosticReportTitle() instead
function BitForge:ShowReport(body, blurb, title)
    title = title or locale["report:windowTitle"]

    -- Long reports are encoded rather than shown. Not a size limit -- nothing
    -- in this window truncates -- but a report a player was never going to
    -- read is a wall to select, and a printable blob is one line to copy.
    -- The footnote is load-bearing: an unreadable payload with no
    -- explanation reads as a bug.
    --
    -- EncodeForPaste answering nil -- the library missing -- falls through to
    -- plain text by construction. This is the branch nobody will exercise in
    -- game: BitForge.toc loads LibDeflate unconditionally.
    local encoded = #body > self.COMPRESS_THRESHOLD and self:EncodeForPaste(body)
    if encoded then
        body = encoded
        blurb = blurb .. " " .. locale["report:encoded"]
    end

    if not reportWindow then
        reportWindow = UI.CreateTextWindow({
            title         = title,
            lead          = locale["report:howTo"],
            link          = ns.enum.REPORT_URL,
            footnote      = blurb,
            name          = "BitForgeReportWindow",
            selectOnOpen  = true,
            buttons       = {
                {
                    text = locale["report:selectAll"],
                    onClick = function(self) self:SelectAll() end,
                },
            },
        })

        -- Applied at creation and never again on a later Open(): the window is
        -- reused for the rest of the session, so restoring on every open would
        -- undo a drag made earlier while it stayed up. A falsy record (never
        -- dragged) leaves it on the CENTER anchor CreateTextWindow gave it.
        --
        -- All four fields are checked, not just the record. Nothing this addon
        -- writes is ever partial -- UpdateDatabase stores the table in one shot
        -- and core's own db.global is not walked by PruneMatchingDefaults -- but
        -- SetPoint raises on a nil anchor and the saved variables are a file a
        -- player can edit. A half-written record would break the window, and
        -- with it every /bfdump, until they cleared the value by hand.
        local storedPoint = model.ReadDatabase("reportWindowPoint")
        if storedPoint and storedPoint.point and storedPoint.relPoint
            and storedPoint.x and storedPoint.y then
            reportWindow:ClearAllPoints()
            reportWindow:SetPoint(storedPoint.point, UIParent, storedPoint.relPoint,
                storedPoint.x, storedPoint.y)
        end

        -- Hooked on the frame rather than added as a TextWindow onMoved option:
        -- this is the one window issue #312 asked for -- What's New is opened
        -- once after an update and read, not dragged around during use -- so a
        -- reusable option nothing else would supply is speculative. HookScript
        -- chains after CreateTextWindow's own OnDragStop, which already called
        -- StopMovingOrSizing, so the point read here is the one the drag settled
        -- on. Stored on drag stop rather than on close, so a window dismissed
        -- with Escape still remembers where it was.
        reportWindow:HookScript("OnDragStop", function(self)
            local point, _, relPoint, x, y = self:GetPoint()
            model.UpdateDatabase("reportWindowPoint",
                { point = point, relPoint = relPoint, x = x, y = y })
        end)
    end

    -- Retitled on every call, not only at creation: the window is reused
    -- across modules and across the item-report/diagnostic-dump split, so a
    -- stale title from whichever call came before would linger otherwise.
    reportWindow:SetTitle(title)
    reportWindow:SetText(body)
    reportWindow:SetFootnote(blurb)
    reportWindow:Open()
end

---@class BitForge.Core.View.ReleaseNotes
local releaseNotes = {}

local notesWindow

-- How each separator the changelog can write between a bold lead and the rest
-- of a bullet is rendered. build_release_notes.py consumes the character out of
-- the text and records it as the item's `sep`, so this is a lookup of what the
-- source said and never an inference: "**BatchSell** — now asks" and
-- "**BatchSell** now asks" reach here as identical lead/text pairs, and the
-- second wants no dash at all.
local SEPARATOR_RENDERINGS = {
    ["—"] = " — ",
    [":"] = ": ",
}

--- What to put between a bullet's lead and its text.
---@param item table  one entry of a release section's `items`
---@return string
local function leadSeparator(item)
    local rendered = item.sep and SEPARATOR_RENDERINGS[item.sep]
    if rendered then return rendered end
    -- No separator in the source. Punctuation the generator left glued to
    -- `text` (a leading comma, deliberately kept -- see
    -- build_release_notes.py's LEAD_SEPARATORS comment) attaches to the lead
    -- with no space of its own; a leading quote is not punctuation of that
    -- kind and is deliberately not in the set.
    if item.text:match("^[,;:.]") then return "" end
    return " "
end

--- The notes as one string: each release's heading, then each section's, then
--- each bullet.
---
--- A bullet's bold prefix is coloured here rather than in the data, because the
--- generated table is plain text and colour belongs to the view. WoW edit boxes
--- render colour escapes, so the leads stay scannable without the widget
--- knowing anything about where they came from.
---@param releases table
---@return string
local function renderNotes(releases)
    local lines = {}
    for releaseIndex, release in ipairs(releases) do
        if releaseIndex > 1 then
            lines[#lines + 1] = ""
        end
        lines[#lines + 1] = locale["whatsNew:version"]:format(release.version, release.date)
        for _, section in ipairs(release.sections) do
            -- Before EVERY section, not only the first: a Changed or Fixed
            -- heading flush against the last bullet of the section above it
            -- reads as one more bullet.
            lines[#lines + 1] = ""
            lines[#lines + 1] = section.heading
            for _, item in ipairs(section.items) do
                if item.lead then
                    lines[#lines + 1] = "- " .. UI.Colors.point:WrapTextInColorCode(item.lead)
                        .. leadSeparator(item) .. item.text
                else
                    lines[#lines + 1] = "- " .. item.text
                end
            end
        end
    end
    return table.concat(lines, "\n")
end

-- Below DIALOG: a release that also resets a module's schema queues
-- BITFORGE_SCHEMA_RESET from PLAYER_READY, ahead of PLAYER_ENTERING_WORLD, and
-- that acknowledge-only popup has to stay on top of this window, not behind it.
local WINDOW_STRATA = "MEDIUM"

--- Builds the window on first use and shows `releases` in it.
---@param releases table
local function openWindow(releases)
    if not notesWindow then
        notesWindow = UI.CreateTextWindow({
            title   = locale["whatsNew:windowTitle"],
            name    = "BitForgeReleaseNotesWindow",
            buttons = {
                {
                    text = locale["whatsNew:close"],
                    onClick = function(self) self:Hide() end,
                },
            },
        })
        notesWindow:SetFrameStrata(WINDOW_STRATA)
    end

    notesWindow:SetText(renderNotes(releases))
    notesWindow:Open()
end

-- The span ShowIfNew last raised, for this session only. Writing
-- lastSeenVersion on show is deliberate, and it means ReleaseNotesSince
-- answers {} from the moment the window appears -- so without this, a player
-- shown three releases at login and reopening them from the slash command
-- would get the newest one alone, which is precisely the case the command
-- exists for. Session-scoped rather than stored: next login it is history.
local raisedThisSession

--- Raises the notes for everything the player has not seen, and records that
--- they have now seen it.
---
--- Recorded on show rather than on close: someone who logs out from the window
--- has seen it, and /bitforge core whatsnew is how they get it back.
function releaseNotes.ShowIfNew()
    local running = model.GetAddonVersion()
    local unseen = model.ReleaseNotesSince(model.ReadDatabase("lastSeenVersion"), running)
    if #unseen == 0 then return end

    raisedThisSession = unseen
    openWindow(unseen)
    model.UpdateDatabase("lastSeenVersion", running)
end

--- Raises the notes unconditionally, for the slash command.
---
--- Re-renders whatever ShowIfNew raised this session, so a player who
--- dismissed several releases unread gets all of them back rather than the
--- newest of them.
---
--- Falls back to the newest release when nothing was raised -- a reload, or a
--- running version that is unreadable, which is the case in every development
--- checkout and is how this is seen in-game before it is ever released.
function releaseNotes.Show()
    openWindow(raisedThisSession or { model.NewestRelease() })
end

view.releaseNotes = releaseNotes

---@class BitForge.Core.View.UpgradeNotice
local upgradeNotice = {}

-- The folders a BitForge download used to carry and no longer does. Each is its
-- own CurseForge project now, and the client removes nothing when a project
-- stops shipping a folder -- so an existing install goes on loading these from
-- a copy nothing updates, which is the whole reason this notice exists.
--
-- BitForge_Dispatch is held apart from the four because it was renamed rather
-- than merely split off: BitForge_AzerothPrime replaces it, adopts its saved
-- profile, and switches it off on sight. A player meets that as an addon
-- disabling itself, so the notice has to say why.
local SPLIT_OFF = {
    "BitForge_AutoBalance",
    "BitForge_EUI",
    "BitForge_RepRank",
    "BitForge_TaskTome",
}
local RENAMED = ns.enum.RENAMED_MODULE

local noticeWindow

--- The project name a player types into an addon manager, from the folder name
--- on disk. Derived rather than read from the .toc's Title, which carries the
--- suite's colour escapes and a dash no search box wants.
---@param folder string
---@return string
local function projectName(folder)
    return (folder:gsub("_", " "))
end

--- The notice as one string: what changed, then the retired folders it changed
--- things for.
---
--- Both lists can be empty -- ShowIfUnseen refuses to raise the window when
--- both are -- so each block is conditional rather than always rendered with
--- nothing under it.
---@param separate string[]  project names, already display-formatted
---@param renamed boolean    whether the renamed folder is still on disk
---@return string
local function renderNotice(separate, renamed)
    local lines = { locale["upgrade:lead"] }
    if #separate > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = locale["upgrade:separate"]
        for _, name in ipairs(separate) do
            lines[#lines + 1] = "- " .. UI.Colors.point:WrapTextInColorCode(name)
        end
    end
    if renamed then
        lines[#lines + 1] = ""
        lines[#lines + 1] = locale["upgrade:renamed"]
    end
    return table.concat(lines, "\n")
end

--- Builds the window on first use and shows `body` in it.
---@param body string
local function openNoticeWindow(body)
    if not noticeWindow then
        noticeWindow = UI.CreateTextWindow({
            title   = locale["upgrade:windowTitle"],
            name    = "BitForgeUpgradeNoticeWindow",
            buttons = {
                {
                    text = locale["upgrade:close"],
                    onClick = function(self) self:Hide() end,
                },
            },
        })
        -- Same strata and the same reason as the release-notes window above:
        -- BITFORGE_SCHEMA_RESET can be queued for this same login and its
        -- acknowledge-only popup has to stay on top of this.
        noticeWindow:SetFrameStrata(WINDOW_STRATA)
    end

    noticeWindow:SetText(body)
    noticeWindow:Open()
end

--- Raises the one-time notice that the suite is six downloads now, and records
--- that it has been raised.
---
--- Gated on a retired folder actually being on disk, so somebody installing
--- BitForge for the first time is not told about a split they never lived
--- through. The gate is one-sided and deliberately so: core cannot tell a stale
--- folder from one installed this morning, so anyone installing core and a
--- module together -- which is what a first install looks like -- sees it once,
--- reading about a split they were never on the wrong side of. That is the cost
--- taken knowingly: the reverse error, a notice missed by somebody who needs
--- it, leaves five folders nothing updates and no way to find out.
---
--- Recorded on show rather than on close, the same way ShowIfNew records
--- lastSeenVersion: somebody who logs out from the window has seen it.
---@return boolean  true when the window was raised, so the caller can hold
--- another window back for this login
function upgradeNotice.ShowIfUnseen()
    if model.ReadDatabase("upgradeNoticeSeen") then return false end

    local separate = {}
    for _, folder in ipairs(SPLIT_OFF) do
        if C_AddOns.DoesAddOnExist(folder) then
            separate[#separate + 1] = projectName(folder)
        end
    end
    local renamed = C_AddOns.DoesAddOnExist(RENAMED)
    if #separate == 0 and not renamed then return false end

    openNoticeWindow(renderNotice(separate, renamed))
    model.UpdateDatabase("upgradeNoticeSeen", true)
    return true
end

view.upgradeNotice = upgradeNotice

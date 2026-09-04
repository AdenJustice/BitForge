---@type string, BitForge.EUI
local ADDON_NAME, ns = ...

---@class BitForge.EUI.View
local view = ns.view
---@type BitForge.EUI.Control
local control = ns.control
---@type BitForge.EUI.Model
local model = ns.model
---@type BitForge.EUI.Locale
local locale = ns.locale
---@type BitForge.EUI.Enum
local enum = ns.enum

local UI = BitForge.UI
local colors = UI.Colors

local format = string.format
local tinsert = table.insert

-- The editor's shell: the window, the footer, and nothing else. Ports the
-- standalone addon's Core/UI/Window.lua.
--
-- Everything in view/ is widgets. Every decision the editor makes was made in
-- control/editor.lua, where a spec can reach it.

local WIDTH, HEIGHT = 720, 520

local PADDING = 16
local FOOTER_HEIGHT = 28
local BUTTON_HEIGHT = 24

-- A global name, because UISpecialFrames is a list of NAMES -- Escape-to-close
-- has no other way to find the frame (UIParentPanelManager.lua).
local FRAME_NAME = ADDON_NAME .. enum.EDITOR_FRAME_SUFFIX

---@class BitForge.EUI.View.Editor
local editor = {}

local frame

--- The window, or nil until it has been opened once.
---@return table|nil
function editor.Frame()
    return frame
end

--- Repaint every pane. A no-op until the window has been built: a pane that
--- does not exist cannot be out of date.
function editor.Refresh()
    if not frame then return end
    view.Repaint()
end

local function onRevertClick()
    control.editor.Revert()
    editor.Refresh()
end

local function onSaveClick()
    if InCombatLockdown() then
        -- Editing stays available in combat and only the reload is withheld.
        -- ReloadUI resolves to C_UI.Reload() and the reference does not say
        -- whether it is combat-restricted; writing our own SavedVariable is
        -- always safe, so the conservative split costs nothing. Checked here as
        -- well as in the footer's repaint, because combat can start between the
        -- two and the button would still be live.
        BitForge:Print(locale["ui:saveCombat"])
        editor.Refresh()
        return
    end

    local count, problems = control.editor.Commit()
    if not count then
        BitForge:Print(format(locale["ui:invalid"], #problems))
        for _, problem in ipairs(problems) do
            BitForge:Print(control.editor.FormatProblem(problem))
        end
        editor.Refresh()
        return
    end

    -- The saved layout is written. The login pass pushes it into EllesmereUI,
    -- which is what the reload is for.
    ReloadUI()
end

--- The footer's repaint: what is unsaved, and whether it can be saved.
local function refreshFooter()
    local count = control.editor.PendingCount()
    local problems = control.editor.Validate()
    local combat = InCombatLockdown()

    if #problems > 0 then
        frame.status:SetText(format(locale["ui:invalid"], #problems))
        frame.status:SetTextColor(colors.danger:GetRGB())
    elseif count > 0 then
        frame.status:SetText(format(locale["ui:pending"], count))
        frame.status:SetTextColor(colors.point:GetRGB())
    else
        frame.status:SetText(locale["ui:pendingNone"])
        frame.status:SetTextColor(colors.text:GetRGB())
    end

    frame.save:SetEnabled(count > 0 and #problems == 0 and not combat)
    frame.revert:SetEnabled(count > 0)

    -- Say why the button is dead -- but only when combat is the REASON it is
    -- dead. A problem list outranks it: combat passes on its own, an invalid
    -- anchor does not, and overwriting the actionable message with the
    -- temporary one hides the thing the player has to fix.
    if combat and count > 0 and #problems == 0 then
        frame.status:SetText(locale["ui:saveCombat"])
        frame.status:SetTextColor(colors.danger:GetRGB())
    end
end

--- Hand the window to the host UI's theme, if one is offering. Registered from
--- here rather than at file scope because the window is built lazily: a handler
--- that arrives after the host has already handed its facade over runs
--- immediately, which is exactly this case.
---
--- Through control.adapters.OnSkin, never EllesmereUI.RegisterSkin directly --
--- that call belongs to adapters.lua, and reaching for it here would put the
--- host addon's name outside it.
---
--- The shell and the footer are this file's own; the two panes paint what they
--- built. Every widget of the window is covered, because one that is not reads
--- as a different addon inside the same frame.
local function applyExternalSkin(facade)
    facade.Shell(frame)
    facade.CloseButton(frame.closeButton)
    facade.Button(frame.save)
    facade.Button(frame.revert)

    view.list.ApplySkin(facade)
    view.detail.ApplySkin(facade)
end

local function build()
    frame = UI.CreateFrame(UIParent, locale["ui:title"])
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")

    -- Before SetMovable, and not optional: a frame that takes no mouse input
    -- never fires OnDragStart, and FrameMixin:OnLoad does not enable it.
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    _G[FRAME_NAME] = frame
    tinsert(UISpecialFrames, FRAME_NAME)

    -- Not redundant with ESC: the search box swallows the first press.
    local closeButton = UI.CreateCloseButton(frame)
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    closeButton:SetScript("OnClick", function() frame:Hide() end)
    frame.closeButton = closeButton

    -- Built before the panes so they can anchor above it.
    local footer = CreateFrame("Frame", nil, frame)
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PADDING, PADDING)
    footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING, PADDING)
    footer:SetHeight(FOOTER_HEIGHT)
    frame.footer = footer

    local status = footer:CreateFontString(nil, "OVERLAY", "BitForgeFontSmall")
    status:SetPoint("LEFT", footer, "LEFT", 0, 0)
    status:SetJustifyH("LEFT")
    frame.status = status

    local save = UI.CreateButton(nil, footer, nil, locale["ui:save"])
    save:SetHeight(BUTTON_HEIGHT)
    save:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
    save:SetScript("OnClick", onSaveClick)
    frame.save = save

    local revert = UI.CreateButton(nil, footer, nil, locale["ui:revert"])
    revert:SetHeight(BUTTON_HEIGHT)
    revert:SetPoint("RIGHT", save, "LEFT", -PADDING / 2, 0)
    revert:SetScript("OnClick", onRevertClick)
    frame.revert = revert

    view.list.Create(frame)
    view.detail.Create(frame)

    view.AddRefresher(refreshFooter)
    control.adapters.OnSkin(applyExternalSkin)

    frame:Hide()
end

function editor.Toggle()
    if not control.adapters.IsPresent() then
        BitForge:Print(locale["error:noRegistry"])
        return
    end

    -- The window edits the saved layout, so there has to be one. Committing
    -- before the login pass has seeded would save a layout of one entry and
    -- leave every other element unmanaged.
    if not model.IsSeeded() then
        BitForge:Print(locale["ui:notReady"])
        return
    end

    if frame and frame:IsShown() then
        frame:Hide()
        return
    end

    if not frame then build() end
    editor.Refresh()
    frame:Show()
end

view.editor = editor

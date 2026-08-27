---@class BitForge.EUI
---@field view BitForge.EUI.View

---@class BitForge.EUI
local ns = select(2, ...)

-- The editor is three panes over one buffer: the list's markers, the form's
-- values and the footer's count all describe the same pending edits, so any one
-- of them changing repaints all three. Each pane registers its own repaint as
-- it is created and never reaches into another's widgets.
--
-- Ports the standalone addon's Core/UI/Window.lua:24-37.

-- The sub-key files publish onto this table but must not widen it, so the
-- fields they add are declared here, on the file that owns the key. That keeps
-- their own aliases at ---@type -- consumers rather than owners -- without
-- tripping inject-field on the one assignment each of them makes.
---@class BitForge.EUI.View
---@field editor BitForge.EUI.View.Editor
---@field list   BitForge.EUI.View.List
---@field detail BitForge.EUI.View.Detail
local view = ns.view

local refreshers = {}

--- Register a pane's repaint. Called once per pane, as it is created.
---@param refresher function
function view.AddRefresher(refresher)
    refreshers[#refreshers + 1] = refresher
end

--- One pane raising must not leave the others unpainted, and the raise still
--- has to reach BugGrabber with its stack intact -- xpcall rather than pcall,
--- so the handler runs at the raise where the pane's locals are still live.
function view.Repaint()
    for _, refresher in ipairs(refreshers) do
        xpcall(refresher, CallErrorHandler)
    end
end

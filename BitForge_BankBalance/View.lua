--- @type string, ns_BB
local ADDON_NAME, ns = ...
local L = ns.locale
--- @class BB_View: BF_BaseView
local view = ns.view

-- =========================================================
-- Display Messages
-- =========================================================

function view:ShowWithdraw(amount)
    self:Print(L["message:withdraw"], amount)
end

function view:ShowDeposit(amount)
    self:Print(L["message:deposit"], amount)
end

function view:ShowError(msg)
    self:Print(msg)
end

--- @type string, ns_BB
local ADDON_NAME, ns = ...
local L = ns.locale
--- @class BB_View: BF_BaseView
local view = ns.view

local _format = string.format
local _GetMoneyString = GetMoneyString

--- =========================================================
--- Display Messages
--- =========================================================

function view:ShowWithdraw(amount)
    self:Print(_format(L["message:withdraw"], _GetMoneyString(amount, true)))
end

function view:ShowDeposit(amount)
    self:Print(_format(L["message:deposit"], _GetMoneyString(amount, true)))
end

function view:ShowError(msg)
    self:Print(msg)
end

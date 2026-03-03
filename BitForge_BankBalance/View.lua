--- @type ns.BankBalance
local ns = select(2, ...)
local L = ns.locale
--- @class BitForge.Views.BankBalance: BitForge.Views.Base
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

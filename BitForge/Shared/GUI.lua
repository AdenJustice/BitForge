--- @type ns.Core
local ns           = select(2, ...)
--- @class BitForge.GUI
local gui          = ns.gui

--- =========================================================
--- Caches
--- =========================================================

local _CreateFrame = CreateFrame
local _Mixin       = Mixin
local _ipairs      = ipairs
local _unpack      = unpack

--- =========================================================
--- Internal helpers
--- =========================================================

local function applySize(frame, opts)
    if opts.width or opts.height then
        frame:SetSize(opts.width or frame:GetWidth(), opts.height or frame:GetHeight())
    end
end

local function applyPoint(frame, opts)
    if opts.point then
        frame:SetPoint(_unpack(opts.point))
    end
end

local function base(frame, opts)
    applySize(frame, opts)
    applyPoint(frame, opts)
end

--- =========================================================
--- Frame  (BitForgeFrameTemplate)
--- =========================================================

--- @class BitForge.GUI.FrameMixin : LibBitForgeUI.FrameMixin
local frameMixin = CreateFromMixins(LibBitForgeUI.FrameMixin)

function frameMixin:OnLoad()
    LibBitForgeUI.FrameMixin.OnLoad(self)
end

--- @class BitForge.GUI.TitledFrameMixin : LibBitForgeUI.TitledFrameMixin
local titledFrameMixin = CreateFromMixins(LibBitForgeUI.TitledFrameMixin)

function titledFrameMixin:OnLoad()
    LibBitForgeUI.TitledFrameMixin.OnLoad(self)
end

--- Creates an MD card-style movable frame (BitForgeFrameTemplate).
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, title: string? }
---@return Frame
function gui:CreateFrame(parent, opts)
    opts           = opts or {}
    local template = opts.title and "BitForgeFrameWithTitleTemplate" or "BitForgeFrameTemplate"
    local mixin    = opts.title and titledFrameMixin or frameMixin
    local frame    = _CreateFrame("Frame", opts.name, parent, template)
    _Mixin(frame, mixin)
    frame:OnLoad()
    base(frame, opts)
    if opts.title then frame:SetTitle(opts.title) end
    return frame --[[@as Frame]]
end

--- =========================================================
--- Button  (BitForgeButtonTemplate)
--- =========================================================

--- @class BitForge.GUI.ButtonMixin : LibBitForgeUI.ButtonMixin
local buttonMixin = CreateFromMixins(LibBitForgeUI.ButtonMixin)

function buttonMixin:OnLoad()
    LibBitForgeUI.ButtonMixin.OnLoad(self)
end

--- Creates an MD contained (filled) button.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, text: string?, onClick: function? }
---@return Button
function gui:CreateButton(parent, opts)
    opts = opts or {}
    local btn = _CreateFrame("Button", opts.name, parent, "BitForgeButtonTemplate")
    _Mixin(btn, buttonMixin)
    btn:OnLoad()
    base(btn, opts)
    if opts.text then btn:SetText(opts.text) end
    if opts.onClick then btn:SetScript("OnClick", opts.onClick) end
    return btn --[[@as Button]]
end

--- =========================================================
--- Checkbox  (BitForgeCheckboxTemplate)
--- =========================================================

--- @class BitForge.GUI.CheckboxMixin : LibBitForgeUI.CheckboxMixin
local checkboxMixin = CreateFromMixins(LibBitForgeUI.CheckboxMixin)

function checkboxMixin:OnLoad()
    LibBitForgeUI.CheckboxMixin.OnLoad(self)
end

--- Creates an MD-style checkbox with an inline label.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, text: string?, checked: boolean?, onClick: function? }
---@return CheckButton
function gui:CreateCheckbox(parent, opts)
    opts = opts or {}
    local cb = _CreateFrame("CheckButton", opts.name, parent, "BitForgeCheckboxTemplate")
    _Mixin(cb, checkboxMixin)
    cb:OnLoad()
    base(cb, opts)
    if opts.text then cb:SetText(opts.text) end
    if opts.checked ~= nil then cb:SetChecked(opts.checked) end
    if opts.onClick then cb:SetScript("OnClick", opts.onClick) end
    return cb --[[@as CheckButton]]
end

--- =========================================================
--- Dropdown  (BitForgeDropdownTemplate)
--- =========================================================

--- @class BitForge.GUI.DropdownMixin : LibBitForgeUI.DropdownMixin
local dropdownMixin = CreateFromMixins(LibBitForgeUI.DropdownMixin)

function dropdownMixin:OnLoad()
    LibBitForgeUI.DropdownMixin.OnLoad(self)
end

--- Creates an MD single-select dropdown.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, placeholder: string?, items: { value: any, label: string }[]?, onChange: fun(value: any)? }
---@return Frame
function gui:CreateDropdown(parent, opts)
    opts = opts or {}
    local dd = _CreateFrame("Frame", opts.name, parent, "BitForgeDropdownTemplate")
    _Mixin(dd, dropdownMixin)
    dd:OnLoad()
    base(dd, opts)
    if opts.placeholder then dd:SetPlaceholder(opts.placeholder) end
    if opts.items then dd:SetItems(opts.items) end
    if opts.onChange then dd:SetOnChange(opts.onChange) end
    return dd --[[@as Frame]]
end

--- =========================================================
--- Slider  (BitForgeSliderTemplate)
--- =========================================================

--- @class BitForge.GUI.SliderMixin : LibBitForgeUI.SliderMixin
local sliderMixin = CreateFromMixins(LibBitForgeUI.SliderMixin)

function sliderMixin:OnLoad()
    LibBitForgeUI.SliderMixin.OnLoad(self)
end

--- Creates an MD horizontal slider.
---@param parent Frame
---@param opts { name: string?, width: number?, point: table?, min: number?, max: number?, value: number?, step: number?, onChange: fun(value: number)? }
---@return Slider
function gui:CreateSlider(parent, opts)
    opts = opts or {}
    local s = _CreateFrame("Slider", opts.name, parent, "BitForgeSliderTemplate")
    _Mixin(s, sliderMixin)
    s:OnLoad()
    if opts.width then s:SetWidth(opts.width) end
    applyPoint(s, opts)
    if opts.min ~= nil and opts.max ~= nil then s:SetMinMaxValues(opts.min, opts.max) end
    if opts.value ~= nil then s:SetValue(opts.value) end
    if opts.step ~= nil then s:SetValueStep(opts.step) end
    if opts.onChange then s:SetOnChange(opts.onChange) end
    return s --[[@as Slider]]
end

--- =========================================================
--- EditBox  (BitForgeEditBoxTemplate)
--- =========================================================

--- @class BitForge.GUI.EditBoxMixin : LibBitForgeUI.EditBoxMixin
local editBoxMixin = CreateFromMixins(LibBitForgeUI.EditBoxMixin)

function editBoxMixin:OnLoad()
    LibBitForgeUI.EditBoxMixin.OnLoad(self)
end

--- Creates an MD single-line text field.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, onChange: fun(text: string)? }
---@return EditBox
function gui:CreateEditBox(parent, opts)
    opts = opts or {}
    local eb = _CreateFrame("EditBox", opts.name, parent, "BitForgeEditBoxTemplate")
    _Mixin(eb, editBoxMixin)
    eb:OnLoad()
    base(eb, opts)
    if opts.onChange then
        eb:HookScript("OnTextChanged", function(self, userInput)
            if userInput then opts.onChange(self:GetText()) end
        end)
    end
    return eb --[[@as EditBox]]
end

--- =========================================================
--- MultiLineEditBox  (BitForgeMultiLineEditBoxTemplate)
--- =========================================================

--- @class BitForge.GUI.MultiLineEditBoxMixin : LibBitForgeUI.MultiLineEditBoxMixin
local multiLineEditBoxMixin = CreateFromMixins(LibBitForgeUI.MultiLineEditBoxMixin)

function multiLineEditBoxMixin:OnLoad()
    LibBitForgeUI.MultiLineEditBoxMixin.OnLoad(self)
end

--- Creates an MD multi-line scrollable text field.
--- The inner EditBox is accessible via frame.EditBox.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, onChange: fun(text: string)? }
---@return Frame
function gui:CreateMultiLineEditBox(parent, opts)
    opts = opts or {}
    local frame = _CreateFrame("Frame", opts.name, parent, "BitForgeMultiLineEditBoxTemplate")
    _Mixin(frame, multiLineEditBoxMixin)
    frame:OnLoad()
    base(frame, opts)
    if opts.onChange then
        frame.EditBox:HookScript("OnTextChanged", function(self, userInput)
            if userInput then opts.onChange(self:GetText()) end
        end)
    end
    return frame --[[@as Frame]]
end

--- =========================================================
--- TabBar  (BitForgeTabBarTemplate)
--- =========================================================

--- @class BitForge.GUI.TabBarMixin : LibBitForgeUI.TabBarMixin
local tabBarMixin = CreateFromMixins(LibBitForgeUI.TabBarMixin)

function tabBarMixin:OnLoad()
    LibBitForgeUI.TabBarMixin.OnLoad(self)
end

--- Creates an MD tab bar.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, position: "bottom"|"top"|"left"|"right"?, tabSize: number[]?, tabs: { id: any, label: string }[]?, onChange: fun(id: any)? }
---@return Frame
function gui:CreateTabBar(parent, opts)
    opts = opts or {}
    local bar = _CreateFrame("Frame", opts.name, parent, "BitForgeTabBarTemplate")
    _Mixin(bar, tabBarMixin)
    bar:OnLoad()
    base(bar, opts)
    if opts.position then bar:SetPosition(opts.position) end
    if opts.tabSize then bar:SetTabSize(opts.tabSize[1], opts.tabSize[2]) end
    if opts.onChange then bar:SetOnChange(opts.onChange) end
    if opts.tabs then
        for _, tab in _ipairs(opts.tabs) do
            bar:AddTab(tab.id, tab.label)
        end
    end
    return bar --[[@as Frame]]
end

--- =========================================================
--- ScrollBox elements
--- =========================================================

--- @class BitForge.GUI.ScrollElementAsButtonMixin : LibBitForgeUI.ScrollElementAsButtonMixin
local scrollButtonMixin = CreateFromMixins(LibBitForgeUI.ScrollElementAsButtonMixin)

function scrollButtonMixin:OnLoad()
    LibBitForgeUI.ScrollElementAsButtonMixin.OnLoad(self)
end

--- @class BitForge.GUI.ScrollElementAsCheckMixin : LibBitForgeUI.ScrollElementAsCheckMixin
local scrollCheckMixin = CreateFromMixins(LibBitForgeUI.ScrollElementAsCheckMixin)

function scrollCheckMixin:OnLoad()
    LibBitForgeUI.ScrollElementAsCheckMixin.OnLoad(self)
end

--- Creates a Button for use as a ScrollBox list element (BitForgeScrollElementAsButtonTemplate).
--- Wire Init(data) by Mixin-ing a second mixin onto the returned frame.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, text: string? }
---@return Button
function gui:CreateScrollButton(parent, opts)
    opts = opts or {}
    local btn = _CreateFrame("Button", opts.name, parent, "BitForgeScrollElementAsButtonTemplate")
    _Mixin(btn, scrollButtonMixin)
    btn:OnLoad()
    base(btn, opts)
    if opts.text then btn:SetText(opts.text) end
    return btn --[[@as Button]]
end

--- Creates a CheckButton for use as a ScrollBox list element (BitForgeScrollElementAsCheckTemplate).
--- Wire Init(data) by Mixin-ing a second mixin onto the returned frame.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, text: string? }
---@return CheckButton
function gui:CreateScrollCheck(parent, opts)
    opts = opts or {}
    local cb = _CreateFrame("CheckButton", opts.name, parent, "BitForgeScrollElementAsCheckTemplate")
    _Mixin(cb, scrollCheckMixin)
    cb:OnLoad()
    base(cb, opts)
    if opts.text then cb:SetText(opts.text) end
    return cb --[[@as CheckButton]]
end

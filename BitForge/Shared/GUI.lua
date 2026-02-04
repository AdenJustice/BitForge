--- @type ns_core
local ns           = select(2, ...)
--- @class BF_GUI
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

local frameMethods = {
    --- Sets the text of the title label ($parentTitle).
    ---@param text string
    SetTitle = function(self, text)
        local name = self:GetName()
        local fs   = name and _G[name .. "Title"]
        if not fs then
            -- Anonymous frame: iterate OVERLAY regions to find the FontString.
            for _, region in next, { self:GetRegions() } do
                if region.GetText then
                    fs = region; break
                end
            end
        end
        if fs then fs:SetText(text) end
    end,
}

--- Creates an MD card-style movable frame (BitForgeFrameTemplate).
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, title: string? }
---@return Frame
function gui:CreateFrame(parent, opts)
    opts = opts or {}
    local frame = _CreateFrame("Frame", opts.name, parent, "BitForgeFrameTemplate")
    _Mixin(frame, frameMethods)
    base(frame, opts)
    if opts.title then frame:SetTitle(opts.title) end
    return frame --[[@as Frame]]
end

--- =========================================================
--- Button  (BitForgeButtonTemplate)
--- =========================================================

--- Creates an MD contained (filled) button.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, text: string?, onClick: function? }
---@return Button
function gui:CreateButton(parent, opts)
    opts = opts or {}
    local btn = _CreateFrame("Button", opts.name, parent, "BitForgeButtonTemplate")
    base(btn, opts)
    if opts.text then btn:SetText(opts.text) end
    if opts.onClick then btn:SetScript("OnClick", opts.onClick) end
    return btn --[[@as Button]]
end

--- =========================================================
--- Checkbox  (BitForgeCheckboxTemplate)
--- =========================================================

--- Creates an MD-style checkbox with an inline label.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, text: string?, checked: boolean?, onClick: function? }
---@return CheckButton
function gui:CreateCheckbox(parent, opts)
    opts = opts or {}
    local cb = _CreateFrame("CheckButton", opts.name, parent, "BitForgeCheckboxTemplate")
    base(cb, opts)
    if opts.text then cb:SetText(opts.text) end
    if opts.checked ~= nil then cb:SetChecked(opts.checked) end
    if opts.onClick then cb:SetScript("OnClick", opts.onClick) end
    return cb --[[@as CheckButton]]
end

--- =========================================================
--- Dropdown  (BitForgeDropdownTemplate)
--- =========================================================

--- Creates an MD single-select dropdown.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, placeholder: string?, items: { value: any, label: string }[]?, onChange: fun(value: any)? }
---@return Frame
function gui:CreateDropdown(parent, opts)
    opts = opts or {}
    local dd = _CreateFrame("Frame", opts.name, parent, "BitForgeDropdownTemplate")
    base(dd, opts)
    if opts.placeholder then dd:SetPlaceholder(opts.placeholder) end
    if opts.items then dd:SetItems(opts.items) end
    if opts.onChange then dd:SetOnChange(opts.onChange) end
    return dd --[[@as Frame]]
end

--- =========================================================
--- Slider  (BitForgeSliderTemplate)
--- =========================================================

--- Creates an MD horizontal slider.
---@param parent Frame
---@param opts { name: string?, width: number?, point: table?, min: number?, max: number?, value: number?, step: number?, onChange: fun(value: number)? }
---@return Slider
function gui:CreateSlider(parent, opts)
    opts = opts or {}
    local s = _CreateFrame("Slider", opts.name, parent, "BitForgeSliderTemplate")
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

--- Creates an MD single-line text field.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, onChange: fun(text: string)? }
---@return EditBox
function gui:CreateEditBox(parent, opts)
    opts = opts or {}
    local eb = _CreateFrame("EditBox", opts.name, parent, "BitForgeEditBoxTemplate")
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

--- Creates an MD multi-line scrollable text field.
--- The inner EditBox is accessible via frame.EditBox.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, onChange: fun(text: string)? }
---@return Frame
function gui:CreateMultiLineEditBox(parent, opts)
    opts = opts or {}
    local frame = _CreateFrame("Frame", opts.name, parent, "BitForgeMultiLineEditBoxTemplate")
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

--- Creates an MD tab bar.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, position: "bottom"|"top"|"left"|"right"?, tabSize: number[]?, tabs: { id: any, label: string }[]?, onChange: fun(id: any)? }
---@return Frame
function gui:CreateTabBar(parent, opts)
    opts = opts or {}
    local bar = _CreateFrame("Frame", opts.name, parent, "BitForgeTabBarTemplate")
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

--- Creates a Button for use as a ScrollBox list element (BitForgeScrollElementAsButtonTemplate).
--- Wire Init(data) by Mixin-ing a second mixin onto the returned frame.
---@param parent Frame
---@param opts { name: string?, width: number?, height: number?, point: table?, text: string? }
---@return Button
function gui:CreateScrollButton(parent, opts)
    opts = opts or {}
    local btn = _CreateFrame("Button", opts.name, parent, "BitForgeScrollElementAsButtonTemplate")
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
    base(cb, opts)
    if opts.text then cb:SetText(opts.text) end
    return cb --[[@as CheckButton]]
end

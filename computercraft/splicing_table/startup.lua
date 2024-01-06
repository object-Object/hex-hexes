local gridmanager = require("utils.gridmanager")
local touchpoint = require("vendor.touchpoint")
local deepcopy = require("vendor.deepcopy")
local deepequals = require("vendor.deepequals")

-- peripherals

local mainPort = peripheral.wrap("top")
local clipboardPort = peripheral.wrap("bottom")
local link = peripheral.wrap("right")
local monitor = peripheral.wrap("left")
local t = touchpoint.new("left")

assert(mainPort ~= nil and clipboardPort ~= nil and link ~= nil and monitor ~= nil)
---@cast mainPort FocalPort
---@cast clipboardPort FocalPort
---@cast link FocalLink
---@cast monitor Monitor

monitor.setTextScale(0.5)

-- state

local data = mainPort.readIota()
assert(type(data) == "table")

local clipboard
if clipboardPort.hasFocus() then
    clipboard = clipboardPort.readIota()
end

local viewIndex = 1

---@class Selection
---@field left integer
---@field right integer

---@type Selection?
local selection = nil

local isShiftHeld = false
local isCtrlHeld = false

local buttonNames = {}

---@class UndoState
---@field viewIndex integer
---@field data Iota
---@field clipboard Iota?
---@field selection Selection?

local undoDepth = 0 -- from the top of the stack
---@type UndoState[]
local undoStack = {}

-- utils

local function save()
    mainPort.writeIota(data)
    if clipboardPort:hasFocus() and clipboard then
        clipboardPort.writeIota(clipboard)
    end
end

local function pushUndoState()
    -- if we're down in the stack, pop everything above us
    if undoDepth > 0 then
        for _=1, undoDepth do
            table.remove(undoStack)
        end
        undoDepth = 0
    end

    ---@type UndoState
    local newState = {
        viewIndex=viewIndex,
        data=deepcopy(data),
        clipboard=deepcopy(clipboard),
        selection=deepcopy(selection),
    }

    if not deepequals(newState, undoStack[#undoStack]) then
        table.insert(undoStack, newState)
    end
end

local function applyUndoState()
    local undoState = undoStack[#undoStack - undoDepth]
    viewIndex = undoState.viewIndex
    data = deepcopy(undoState.data)
    clipboard = deepcopy(undoState.clipboard)
    selection = deepcopy(undoState.selection)
end

local function drawPatterns()
    local iotas = {}
    for i=0, 8 do
        local iotaIndex = viewIndex + i

        local name = buttonNames[i]
        local button = t.buttonList[name]

        if iotaIndex <= #data then
            t:setLabel(name, tostring(iotaIndex - 1))

            local iota = data[iotaIndex]
            if selection and iotaIndex >= selection.left and iotaIndex <= selection.right then
                iotas[i + 1] = {iota}
                button.active = true
            else
                iotas[i + 1] = iota
                button.active = false
            end
        else
            t:setLabel(name, "")
            button.active = false
        end
    end
    link.sendIota(0, iotas)
    t:draw()
end

local function draw()
    t:draw()
    drawPatterns()
end

local function pushAndSave()
    pushUndoState()
    draw()
    save()
    return true
end

local function applyAndSave()
    applyUndoState()
    draw()
    save()
    return true
end

---@param sign 1 | -1
---@param minmax fun(number, number): number
---@param limit number
---@return boolean
local function moveView(sign, minmax, limit)
    local oldViewIndex = viewIndex

    if isCtrlHeld then
        viewIndex = limit
    else
        local offset = (isShiftHeld and 9 or 1) * sign
        viewIndex = minmax(viewIndex + offset, limit)
    end

    if oldViewIndex ~= viewIndex then
        draw()
        return true
    end
    return false
end

local function isListIota(iota)
    if type(iota) ~= "table" or iota.type ~= nil then
        return false
    end

    for k, _ in pairs(iota) do
        if type(k) ~= "number" then
            return false
        end
    end

    return true
end

-- control panel setup

local patternGrid = gridmanager.new(t, 11, 4, {padding=1, margin={top=1, bottom=-2}})
local buttonGrid = gridmanager.new(t, 6, 3, {padding=1, margin={x=1}})

-- buttons!

-- pattern row

for i=0, 8 do
    buttonNames[i] = patternGrid:add(tostring(i), i + 2, 1, {}, function()
        local newSelect = viewIndex + i
        if newSelect < 1 or newSelect > #data then
            return false
        end

        if selection and newSelect >= selection.left and newSelect <= selection.right then
            selection = nil
        elseif selection == nil or selection.left ~= selection.right then
            selection = { left=newSelect, right=newSelect }
        elseif newSelect < selection.left then
            selection = { left=newSelect, right=selection.left }
        else
            selection.right = newSelect
        end

        draw()
        return false
    end)
end

patternGrid:add("left", 1, 1, {scaleX=0.6, scaleY=0.5}, function()
    return moveView(-1, math.max, 1)
end)

patternGrid:add("right", 11, 1, {scaleX=0.6, scaleY=0.5}, function()
    return moveView(1, math.min, #data - 8)
end)

-- data row

buttonGrid:add("select none", 1, 2, {}, function()
    selection = nil
    draw()
    return true
end)

buttonGrid:add("select all", 2, 2, {}, function()
    selection = { left=1, right=#data }
    draw()
    return true
end)

buttonGrid:add("nudge left", 3, 2, {}, function()
    if selection == nil or selection.left <= 1 then return false end

    local tmp = data[selection.left - 1]

    for i=selection.left, selection.right do
        data[i - 1] = data[i]
    end

    selection.left = selection.left - 1
    selection.right = selection.right - 1

    data[selection.right + 1] = tmp

    return pushAndSave()
end)

buttonGrid:add("nudge right", 4, 2, {}, function()
    if selection == nil or selection.right >= #data then return false end

    local tmp = data[selection.right + 1]

    for i=selection.right, selection.left, -1 do
        data[i + 1] = data[i]
    end

    selection.left = selection.left + 1
    selection.right = selection.right + 1

    data[selection.left - 1] = tmp

    return pushAndSave()
end)

buttonGrid:add("duplicate", 5, 2, {}, function()
    if selection == nil then return false end

    for i=selection.right, selection.left, -1 do
        table.insert(data, selection.right + 1, data[i])
    end

    return pushAndSave()
end)

buttonGrid:add("delete", 6, 2, {}, function()
    if selection == nil then return false end

    for _=selection.left, selection.right do
        table.remove(data, selection.left)
    end

    selection = nil

    return pushAndSave()
end)

-- clipboard row

local shift, ctrl

shift = buttonGrid:add("shift", 1, 3, {scaleY=0.4, alignY="top"}, function()
    isShiftHeld = not isShiftHeld
    isCtrlHeld = false
    t.buttonList[shift].active = isShiftHeld
    t.buttonList[ctrl].active = isCtrlHeld
    t:draw()
    return false
end)

ctrl = buttonGrid:add("ctrl", 1, 3, {scaleY=0.4, alignY="bottom"}, function()
    isShiftHeld = false
    isCtrlHeld = not isCtrlHeld
    t.buttonList[shift].active = isShiftHeld
    t.buttonList[ctrl].active = isCtrlHeld
    t:draw()
    return false
end)

buttonGrid:add("cut", 2, 3, {}, function()
    if selection == nil or clipboard == nil then return false end

    clipboard = {}

    for _=selection.left, selection.right do
        local iota = table.remove(data, selection.left)
        table.insert(clipboard, iota)
    end

    selection = nil

    return pushAndSave()
end)

buttonGrid:add("copy", 3, 3, {}, function()
    if selection == nil or clipboard == nil then return false end

    clipboard = {}

    for i=selection.left, selection.right do
        table.insert(clipboard, data[i])
    end

    return pushAndSave()
end)

buttonGrid:add("paste", 4, 3, {}, function()
    if selection == nil or clipboard == nil then return false end

    if isShiftHeld then
        selection.left = selection.right + 1
    else
        -- overwrite selection
        for _=selection.left, selection.right do
            table.remove(data, selection.left)
        end
    end

    if not isCtrlHeld and isListIota(clipboard) then
        -- flatten list
        for i=#clipboard, 1, -1 do
            table.insert(data, selection.left, clipboard[i])
        end
        selection.right = selection.left + #clipboard - 1
    else
        -- insert verbatim
        table.insert(data, selection.left, clipboard)
        selection.right = selection.left
    end

    return pushAndSave()
end)

buttonGrid:add("undo", 5, 3, {}, function()
    if undoDepth >= #undoStack - 1 then return false end
    undoDepth = undoDepth + 1
    return applyAndSave()
end)

buttonGrid:add("redo", 6, 3, {}, function()
    if undoDepth <= 0 then return false end
    undoDepth = undoDepth - 1
    return applyAndSave()
end)

-- main loop

pushUndoState()
draw()

while true do
    local event, name = t:handleEvents(os.pullEvent())
    if event == "button_click" then
        t:clickButton(name)
    elseif event == "focus_inserted" or event == "new_iota" then
        if name == "top" then
            data = mainPort.readIota()
            viewIndex = 1
            selection = nil
            draw()
        else
            clipboard = clipboardPort.readIota()
        end
        pushUndoState()
    elseif event == "focus_removed" then
        if name == "top" then
            data = {}
            viewIndex = 1
            selection = nil
            draw()
        else
            clipboard = nil
        end
    end
end

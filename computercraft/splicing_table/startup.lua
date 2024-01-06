local touchpoint = require("vendor.touchpoint")
local gridmanager = require("utils.gridmanager")

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

local clipboard = clipboardPort.readIota()

local viewIndex = 1

local selectStart = 0
local selectEnd = 0

local isShiftHeld = false
local isCtrlHeld = false

local buttonNames = {}

---@class UndoState
---@field data Iota
---@field clipboard Iota?

local undoDepth = 0 -- from the top of the stack
---@type UndoState[]
local undoStack = {}

-- utils

local function pushUndoState()
    -- if we're down in the stack, pop everything above us
    if undoDepth > 0 then
        for _=1, undoDepth do
            table.remove(undoStack)
        end
    end

    table.insert(undoStack, {
        data=data,
        clipboard=clipboard,
    })
end

local function applyUndoState()
    local undoState = undoStack[#undoStack - undoDepth]
    data = undoState.data
    clipboard = undoState.clipboard
end

local function drawPatterns()
    local iotas = {}
    for i=0, 8 do
        local iotaIndex = viewIndex + i

        local name = buttonNames[i]
        t:setLabel(name, tostring(iotaIndex - 1))

        local button = t.buttonList[name]
        if iotaIndex <= #data then
            local iota = data[iotaIndex]
            if iotaIndex >= selectStart and iotaIndex <= selectEnd then
                iotas[i + 1] = {iota}
                button.active = true
            else
                iotas[i + 1] = iota
                button.active = false
            end
        end
    end
    link.sendIota(0, iotas)
    t:draw()
end

local function draw()
    t:draw()
    drawPatterns()
end

---@param sign 1 | -1
---@param minmax fun(number, number): number
---@param limit number
local function moveView(sign, minmax, limit)
    local oldViewIndex = viewIndex

    if isCtrlHeld then
        viewIndex = 1
    else
        local offset = (isShiftHeld and 9 or 1) * sign
        viewIndex = minmax(viewIndex + offset, limit)
    end

    if oldViewIndex ~= viewIndex then
        draw()
    end
end

-- control panel setup

local patternGrid = gridmanager.new(t, 11, 4, {padding=1, margin={top=1, bottom=-2}})
local buttonGrid = gridmanager.new(t, 6, 3, {padding=1, margin={x=1}})

-- buttons!

for i=0, 8 do
    buttonNames[i] = patternGrid:add(tostring(i), i + 2, 1, {}, function()
        local newSelect = viewIndex + i
        if newSelect >= selectStart and newSelect <= selectEnd then
            selectStart = 0
            selectEnd = 0
        elseif selectStart == 0 or selectStart ~= selectEnd then
            selectStart = newSelect
            selectEnd = selectStart
        elseif newSelect < selectStart then
            local tmp = selectStart
            selectStart = newSelect
            selectEnd = tmp
        else
            selectEnd = newSelect
        end
        draw()
    end)
end

patternGrid:add("left", 1, 1, {scaleX=0.6, scaleY=0.5}, function()
    moveView(-1, math.max, 1)
end)

patternGrid:add("right", 11, 1, {scaleX=0.6, scaleY=0.5}, function()
    moveView(1, math.min, #data - 8)
end)

buttonGrid:add("nudge left", 1, 2, {}, nil)

buttonGrid:add("nudge right", 2, 2, {}, nil)

buttonGrid:add("delete", 3, 2, {}, nil)

buttonGrid:add("duplicate", 4, 2, {}, nil)

buttonGrid:add("select none", 5, 2, {}, function()
    selectStart = 0
    selectEnd = 0
    draw()
end)

buttonGrid:add("select all", 6, 2, {}, function()
    selectStart = 1
    selectEnd = #data
    draw()
end)

local shift, ctrl

shift = buttonGrid:add("shift", 1, 3, {scaleY=0.4, alignY="top"}, function()
    isShiftHeld = not isShiftHeld
    isCtrlHeld = false
    t.buttonList[shift].active = isShiftHeld
    t.buttonList[ctrl].active = isCtrlHeld
    t:draw()
end)

ctrl = buttonGrid:add("ctrl", 1, 3, {scaleY=0.4, alignY="bottom"}, function()
    isShiftHeld = false
    isCtrlHeld = not isCtrlHeld
    t.buttonList[shift].active = isShiftHeld
    t.buttonList[ctrl].active = isCtrlHeld
    t:draw()
end)

buttonGrid:add("cut", 2, 3, {}, nil)

buttonGrid:add("copy", 3, 3, {}, nil)

buttonGrid:add("paste", 4, 3, {}, nil)

buttonGrid:add("undo", 5, 3, {}, function()
    if undoDepth < #undoStack - 1 then
        undoDepth = undoDepth + 1
        applyUndoState()
    end
end)

buttonGrid:add("redo", 6, 3, {}, function()
    if undoDepth > 0 then
        undoDepth = undoDepth - 1
        applyUndoState()
    end
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

            undoStack = {}
            pushUndoState()

            viewIndex = 1
            selectStart = 0
            selectEnd = 0

            draw()
        else
            clipboard = clipboardPort.readIota()
            pushUndoState()
        end
    end
end

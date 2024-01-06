local touchpoint = require("vendor.touchpoint")
local gridmanager = require("utils.gridmanager")

-- peripherals

local mainPort = peripheral.wrap("top") ---@cast mainPort FocalPort
local clipboardPort = peripheral.wrap("bottom") ---@cast clipboardPort FocalPort
local link = peripheral.wrap("right")
local t = touchpoint.new("left")

local monitor = peripheral.wrap("left")
monitor.setTextScale(0.5)

assert(mainPort ~= nil and clipboardPort ~= nil and link ~= nil)

-- state

local data = mainPort.readIota()
assert(type(data) == "table")

local viewIndex = 1

local selectStart = 0
local selectEnd = 0

local buttonNames = {}

local function drawPatterns()
    local iotas = {}
    for i=0, 6 do
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

-- control panel setup

local patternGrid = gridmanager.new(t, 9, 4, {padding=1, margin={top=1, bottom=-2, left=2}})
local buttonGrid  = gridmanager.new(t, 6, 3, {padding=1, margin={x=1}})

-- buttons!

for i=0, 6 do
    buttonNames[i] = patternGrid:add(tostring(i), i + 2, 1, {}, function()
        local newSelect = viewIndex + i
        if selectStart == 0 or selectStart ~= selectEnd then
            selectStart = newSelect
            selectEnd = selectStart
        elseif newSelect == selectStart then
            selectStart = 0
            selectEnd = 0
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

local left = patternGrid:add("left", 1, 1, {scaleX=0.6, scaleY=0.5}, function()
    if viewIndex > 1 then
        viewIndex = viewIndex - 1
        draw()
    end
end)

local right = patternGrid:add("right", 9, 1, {scaleX=0.6, scaleY=0.5}, function()
    if viewIndex < #data - 6 then
        viewIndex = viewIndex + 1
        draw()
    end
end)

local nudgeLeft  = buttonGrid:add("nudge left",  1, 2, {}, nil)
local nudgeRight = buttonGrid:add("nudge right", 2, 2, {}, nil)
local delete     = buttonGrid:add("delete",      3, 2, {}, nil)
local duplicate  = buttonGrid:add("duplicate",   4, 2, {}, nil)
local selectNone = buttonGrid:add("select none", 5, 2, {}, nil)
local selectAll  = buttonGrid:add("select all",  6, 2, {}, nil)

local shift = buttonGrid:add("shift", 1, 3, {scaleY=0.4, alignY="top"}, nil)
local ctrl  = buttonGrid:add("ctrl",  1, 3, {scaleY=0.4, alignY="bottom"}, nil)

local cut   = buttonGrid:add("cut",   2, 3, {}, nil)
local copy  = buttonGrid:add("copy",  3, 3, {}, nil)
local paste = buttonGrid:add("paste", 4, 3, {}, nil)
local undo  = buttonGrid:add("undo",  5, 3, {}, nil)
local redo  = buttonGrid:add("redo",  6, 3, {}, nil)

-- main loop

draw()
while true do
    local event, name = t:handleEvents(os.pullEvent())
    if event == "button_click" then
        t:clickButton(name)
    elseif event == "focus_inserted" or event == "new_iota" then
        if name == "top" then
            data = mainPort.readIota()
            viewIndex = 1
            selectStart = 0
            selectEnd = 0
            draw()
        end
    end
end

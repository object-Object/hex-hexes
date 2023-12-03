local touchpoint = require("vendor.touchpoint")
local gridmanager = require("utils.gridmanager")

local t = touchpoint.new("left")
local grid = gridmanager.new("left", 2, 2, { padding=1 })

t:add("top left", nil, grid:at(1, 1))
t:add("top right", nil, grid:at(2, 1))
t:add("bottom left", nil, grid:at(1, 2))
t:add("bottom right", nil, grid:at(2, 2))

t:draw()

while true do
    local event, value = t:handleEvents(os.pullEvent())
    if event == "button_click" then
        t:toggleButton(value)
    end
end

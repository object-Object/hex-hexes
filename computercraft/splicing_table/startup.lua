local touchpoint = require("vendor.touchpoint")
local gridmanager = require("utils.gridmanager")

local t = touchpoint.new("left")

local patternGrid = gridmanager.new(t, 9, 4, {padding=1, margin={top=3, bottom=-2}})
local buttonGrid  = gridmanager.new(t, 6, 3, {padding=1, margin={x=1}})

patternGrid:add("left",  nil, 1, 1, {scaleX=0.6, scaleY=0.5})
patternGrid:add("right", nil, 9, 1, {scaleX=0.6, scaleY=0.5})

for i=2, 8 do
    patternGrid:add(tostring(i), nil, i, 1)
end

buttonGrid:add("nudge left",  nil, 1, 2)
buttonGrid:add("nudge right", nil, 2, 2)
buttonGrid:add("delete",      nil, 3, 2)
buttonGrid:add("duplicate",   nil, 4, 2)
buttonGrid:add("select none", nil, 5, 2)
buttonGrid:add("select all",  nil, 6, 2)

buttonGrid:add("shift", nil, 1, 3, {scaleY=0.4, alignY="top"})
buttonGrid:add("ctrl",  nil, 1, 3, {scaleY=0.4, alignY="bottom"})

buttonGrid:add("cut",   nil, 2, 3)
buttonGrid:add("copy",  nil, 3, 3)
buttonGrid:add("paste", nil, 4, 3)
buttonGrid:add("undo",  nil, 5, 3)
buttonGrid:add("redo",  nil, 6, 3)


t:draw()
-- while true do
--     local event, name = t:handleEvents(os.pullEvent())
--     if event == "button_click" then
--         t:flash(name)
--     end
-- end

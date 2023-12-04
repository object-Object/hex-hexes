local touchpoint = require("vendor.touchpoint")
local gridmanager = require("utils.gridmanager")

local t = touchpoint.new("left")

local patternGrid      = gridmanager.new(t, 9, 4, {padding=1, margin={top=3, bottom=-2}})
local buttonGridTop    = gridmanager.new(t, 6, 3, {padding=1, margin={x=1}})
local buttonGridBottom = gridmanager.new(t, 6, 3, {padding=1, margin={x=1}})

patternGrid:add("left", nil, 1, 1, {scaleX=0.6, scaleY=0.5})
patternGrid:add("right", nil, 9, 1, {scaleX=0.6, scaleY=0.5})

for i=2, 8 do
    patternGrid:add(tostring(i), nil, i, 1)
end

buttonGridTop:add("nudge left",  nil, 1, 2)
buttonGridTop:add("nudge right", nil, 2, 2)
buttonGridTop:add("delete",      nil, 3, 2)
buttonGridTop:add("duplicate",   nil, 4, 2)
buttonGridTop:add("select none", nil, 5, 2)
buttonGridTop:add("select all",  nil, 6, 2)

buttonGridBottom:add("shift", nil, 1, 3, {scaleY=0.4, alignY="top"})
buttonGridBottom:add("ctrl",  nil, 1, 3, {scaleY=0.4, alignY="bottom"})

buttonGridBottom:add("cut",   nil, 2, 3)
buttonGridBottom:add("copy",  nil, 3, 3)
buttonGridBottom:add("paste", nil, 4, 3)
buttonGridBottom:add("undo",  nil, 5, 3)
buttonGridBottom:add("redo",  nil, 6, 3)


t:draw()
-- while true do
--     local event, name = t:handleEvents(os.pullEvent())
--     if event == "button_click" then
--         t:flash(name)
--     end
-- end

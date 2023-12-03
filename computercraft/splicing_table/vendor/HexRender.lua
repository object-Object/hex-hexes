---Originally written by Chloe
---https://pastebin.com/2deuP92f

local pprint = require("cc.pretty").pretty_print

local focalPort = peripheral.find("focal_port") ---@type FocalPort
local monitor = peripheral.find("monitor") ---@type Monitor
term.redirect(monitor)

local HexPatterns = {}

NORMALIZE_ROTATION = false

ANGLE_DIRS = {
    w = 60*0* math.pi / 180,
    e = 60*1* math.pi / 180,
    d = 60*2* math.pi / 180,
    s = 60*3* math.pi / 180,
    a = 60*4* math.pi / 180,
    q = 60*5* math.pi / 180,
    j = 90*1* math.pi / 180,
}

START_ANGLE_DIRS = {
    EAST       = 60*0* math.pi / 180,
    SOUTH_EAST = 60*1* math.pi / 180,
    SOUTH_WEST = 60*2* math.pi / 180,
    WEST       = 60*3* math.pi / 180,
    NORTH_WEST = 60*4* math.pi / 180,
    NORTH_EAST = 60*5* math.pi / 180,
}

---@class BufferedString
---@field [1] number
---@field [2] number
---@field [3] string

---@type BufferedString[]
local stringBuffer = {}

---@class PatternLocation
---@field [1] number
---@field [2] number
---@field [3] TypedPatternIota

---@type PatternLocation[]
local patternLocations = {}

---@type { [integer]: integer }
local brailleBuffer = {}

---@type integer, integer, integer
local w, h, size

---@type number
local monitorShape

---@param pattern PatternIota|TypedPatternIota
---@return integer height
---@return integer width
local function getPatternSize(pattern)
    local currentPoint = {0, 0} ---@type Point
    local currentAngle = START_ANGLE_DIRS[pattern.startDir] + 90 * math.pi / 180
    local points = {{0, 0}} ---@type Point[]
    local angles = "w" .. pattern.angles
    for i = 1, #angles do
        local a = angles:sub(i, i)
        currentAngle = (currentAngle + ANGLE_DIRS[a]) % 360
        local angleOffset = {math.sin(currentAngle), -math.cos(currentAngle)}
        currentPoint = {currentPoint[1] + angleOffset[1], currentPoint[2] + angleOffset[2]}
        table.insert(points, currentPoint)
    end

    local farLeft = 0
    local farRight = 0
    local farTop = 0
    local farBottom = 0

    for _, point in pairs(points) do
        if point[2] < farLeft then farLeft = point[2] end
        if point[2] > farRight then farRight = point[2] end
        if point[1] > farTop then farTop = point[1] end
        if point[1] < farBottom then farBottom = point[1] end
    end

    return math.abs(farTop-farBottom), math.abs(farLeft-farRight)
end

---@param startX number
---@param startY number
---@param endX number
---@param endY number
---@param color number
local function drawLine(startX, startY, endX, endY, color)
    startX = math.floor(startX+.5)
    startY = math.floor(startY+.5)
    endX = math.floor(endX+.5)
    endY = math.floor(endY+.5)

    if startX == endX and startY == endY then
        local offset = math.floor((math.floor(startX)-1) + ((math.floor(startY)-1) * w*2) + 1)
        brailleBuffer[offset] = 1
        return
    end

    local minX = math.min(startX, endX)
    local maxX, minY, maxY
    if minX == startX then
        minY = startY
        maxX = endX
        maxY = endY
    else
        minY = endY
        maxX = startX
        maxY = startY
    end

    local xDiff = maxX - minX
    local yDiff = maxY - minY

    if xDiff > math.abs(yDiff) then
        local y = minY
        local dy = yDiff / xDiff
        for x = minX, maxX do
            local offset = math.floor((math.floor(x+.5)-1) + ((math.floor(y+.5)-1) * w*2) + 1)
            brailleBuffer[offset] = color
            y = y + dy
        end
    else
        local x = minX
        local dx = xDiff / yDiff
        if maxY >= minY then
            for y = minY, maxY do
                local offset = math.floor((math.floor(x+.5)-1) + ((math.floor(y+.5)-1) * w*2) + 1)
                brailleBuffer[offset] = color
                x = x + dx
            end
        else
            for y = minY, maxY, -1 do
                local offset = math.floor((math.floor(x+.5)-1) + ((math.floor(y+.5)-1) * w*2) + 1)
                brailleBuffer[offset] = color
                x = x - dx
            end
        end
    end
end

---@class Point
---@field [1] number
---@field [2] number

---@param pattern TypedPatternIota
---@param location Point
---@param scale number
---@param colorOverride number?
---@return integer farLeft
---@return integer farRight
---@return integer farTop
---@return integer farBottom
local function drawPattern(pattern, location, scale, colorOverride)
    scale = (scale / math.max(getPatternSize(pattern))) * .75

    local currentPoint = {0, 0}
    local currentAngle = START_ANGLE_DIRS[pattern.startDir] + 90 * math.pi / 180
    local points = {{0, 0}}
    local angles = "w" .. pattern.angles
    for i = 1, #angles do
        local a = angles:sub(i, i)
        currentAngle = (currentAngle + ANGLE_DIRS[a])
        local angleOffset = {math.sin(currentAngle)*scale, -math.cos(currentAngle)*scale}
        currentPoint = {currentPoint[1] + angleOffset[1], currentPoint[2] + angleOffset[2]}
        table.insert(points, currentPoint)
    end

    local farLeft = 0
    local farRight = 0
    local farTop = 0
    local farBottom = 0

    for _, point in pairs(points) do
        if point[2] < farLeft then farLeft = point[2] end
        if point[2] > farRight then farRight = point[2] end
        if point[1] > farTop then farTop = point[1] end
        if point[1] < farBottom then farBottom = point[1] end
    end

    local middleX = ((farLeft + farRight) / 2)
    local middleY = ((farTop + farBottom) / 2)
    local offset = {middleY*-1 + location[1],  middleX*-1 + location[2]}

    for _, point in pairs(points) do
        point[1] = (point[1] + offset[1])
        point[2] = (point[2] + offset[2])
    end

    for index, point in pairs(points) do
        if index < #points then
            local color ---@type integer
            if colorOverride then
                color = colorOverride
            else
                color = 2^((index-1)%15)
            end
            drawLine(point[1], point[2], points[index+1][1], points[index+1][2], color)
            if redstone.getInput("right") then
                drawLine(point[1]+1, point[2], points[index+1][1]+1, points[index+1][2], color)
                drawLine(point[1]-1, point[2], points[index+1][1]-1, points[index+1][2], color)
                drawLine(point[1], point[2]+1, points[index+1][1], points[index+1][2]+1, color)
                drawLine(point[1], point[2]-1, points[index+1][1], points[index+1][2]-1, color)
            end
        end
    end
    return farLeft, farRight, farTop, farBottom
end

---@param h number
---@param s number
---@param l number
---@return number r
---@return number g
---@return number b
---@return number a
local function hslToRgb(h, s, l)
    h = h / 360
    s = s / 100
    l = l / 100

    local r, g, b;

    if s == 0 then
        r, g, b = l, l, l; -- achromatic
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 / 2 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p;
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s;
        local p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    end

    return r, g, b, 1
end

---@param s number
---@return "0"|"1"
local function toClampedString(s)
    if s > 0 then return "1" else return "0" end
end

---@param colorlist integer[]
---@return integer
local function findColor(colorlist)
    local commonColors = {}
    for _, color in pairs(colorlist) do
        if color ~= colors.black and color ~= 0 then
            if commonColors[color] == nil then commonColors[color] = 0 end
            commonColors[color] = commonColors[color] + 1
        end
    end
    local maxfreq = 0
    local maxcolor = colors.black
    for color, freq in pairs(commonColors) do
        if freq > maxfreq then
            maxcolor = color
            maxfreq = freq
        end
    end
    return maxcolor
end

---@class CharTable
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number
---@field [5] number
---@field [6] number

---@param x number
---@param y number
---@param charTable CharTable
---@param colorB integer
local function drawBraille(x, y, charTable, colorB)
    term.setCursorPos(x, y)
    local a, b, c, d, e, f = unpack(charTable)
    local charBitString = toClampedString(a) .. toClampedString(b) .. toClampedString(c) .. toClampedString(d) .. toClampedString(e) .. toClampedString(f)
    local colorF = findColor({a, b, c, d, e, f})
    charBitString = string.reverse(charBitString)
    local charID = tonumber(charBitString, 2)
    if charID < 32 then
        term.setBackgroundColor(colorB)
        term.setTextColor(colorF)
        term.write(string.char(128+charID))
    else
        term.setBackgroundColor(colorF)
        term.setTextColor(colorB)
        term.write(string.char(128+63-charID))
    end
end

local function drawBuffer()
    for i=1, 15 do
        local r, g, b = hslToRgb(i/16*360, 50, 50)
        term.setPaletteColor(2^(i-1), r, g, b)
    end
    for i = 1, (size/6) do
        i = i - 1
        local realX = math.floor(i%w)+1
        local realY = math.floor(i/w)+1

        local pixBase = ((realX-1)*2 + (realY-1)*w*6)
        local charTable = {
            brailleBuffer[pixBase+1],
            brailleBuffer[pixBase+2],
            brailleBuffer[pixBase+w*2+1],
            brailleBuffer[pixBase+w*2+2],
            brailleBuffer[pixBase+w*4+1],
            brailleBuffer[pixBase+w*4+2]
        }
        drawBraille(realX, realY, charTable, colors.black)
    end
    term.setTextColor(colors.white)
    for _, i in pairs(stringBuffer) do
        term.setCursorPos(i[1], i[2])
        print(i[3])
    end
    stringBuffer = {}
end

---@class IotaColor
---@field color integer
---@field type string

---@type { [string]: IotaColor }
IOTA_TYPES = {
    matrix = {color = colors.lightBlue, type = "matrix"},
    moteUuid = {color = colors.yellow, type = "mote"},
    isPlayer = {color = colors.lightBlue, type = "player entity"},
    name = {color = colors.lightBlue, type = "entity"},
    entityType = {color = colors.purple, type = "entity type"},
    iotaType = {color = colors.purple, type = "iota type"},
    itemType = {color = colors.orange, type = "item type"},
    y = {color = colors.red, type = "vector", },
    null = {color = colors.gray, type = "null"},
    garbage = {color = colors.gray, type = "garbage"},
    gate = {color = colors.purple, type = "drifting gate"},
    location = {color = colors.purple, type = "location gate"}
}

---@class TypedPatternIota
---@field angles string
---@field startDir startDir
---@field color integer
---@field type flattenedIotaType
---@field data Iota
---@field index integer[]?

---@alias flattenedIotaType
---| "pattern"
---| "listStart"
---| "Unreadable Iota"
---| "listEnd"
---| "number"
---| "string"
---| "boolean"
---| "boolean"

---@param iota Iota
---@return TypedPatternIota[]
local function flattenIotas(iota)
    local keyType = nil

    if type(iota) == "table" then
        for k, v in pairs(iota) do
            if k ~= "data" and k ~= "type" and k ~= "color" then
                keyType = k
                break
            end
        end
        local iotaType = IOTA_TYPES[keyType]
        if iotaType ~= nil then
            local typedIota = {}
            typedIota.data = iota
            typedIota.color = iotaType.color
            typedIota.type = iotaType.type
            typedIota.angles = "jjjj"
            typedIota.startDir = "EAST"
            return {typedIota}
        end
        if keyType == "startDir" then
            local pattern = {{angles = iota.angles, startDir = iota.startDir, color = colors.yellow, type = "pattern", data = iota}}
            if NORMALIZE_ROTATION then
                if HexPatterns[iota.angles] ~= nil then
                    pattern[1].startDir = HexPatterns[iota.angles][2]
                end
            end
            return pattern
        elseif keyType == 1 or keyType == nil then -- list
            local outputIotas = {}
            local nildetector = 0

            table.insert(outputIotas, {angles = "jwj", startDir = "WEST", color = colors.purple, type = "listStart", data = iota})
            for _1, v in pairs(iota) do
                for _3 = 1, _1 - nildetector - 1 do
                    table.insert(outputIotas, {angles = "jjjj", startDir = "EAST", color = colors.gray, type = "Unreadable Iota", data = "Unreadable Iota", index = _1-1})
                end
                nildetector = _1

                local t = flattenIotas(v)
                if not t then t = {} end
                for _2, i in pairs(t) do
                    if i.index == nil then
                        i.index = {_1-1}
                    else
                        table.insert(i.index, _1-1)
                    end
                    table.insert(outputIotas, i)
                end
            end
            table.insert(outputIotas, {angles = "jwj", startDir = "EAST", color = colors.purple, type = "listEnd", data = iota})
            return(outputIotas)
        end
    elseif type(iota) == "number" then
        return {{angles = "jjjj", startDir = "EAST", color = colors.lime, type = "number", data = iota}}
    elseif type(iota) == "string" then
        return {{angles = "jjjj", startDir = "EAST", color = colors.pink, type = "string", data = iota}}
    elseif type(iota) == "boolean" then
        if iota then
            return {{angles = "jjjj", startDir = "EAST", color = colors.green, type = "boolean", data = iota}}
        else
            return {{angles = "jjjj", startDir = "EAST", color = colors.red, type = "boolean", data = iota}}
        end
    end

    error("Unhandled iota: "..pprint(iota))
end

---@param focus Iota
---@param drawScale number?
---@param patternsPerLine integer?
local function RenderList(focus, drawScale, patternsPerLine)
    local flattenedIotas = flattenIotas(focus)

    if drawScale == nil then drawScale = 5 end
    if patternsPerLine == nil then patternsPerLine = math.floor(math.sqrt(#flattenedIotas/monitorShape)) end

    local lines = math.ceil((#flattenedIotas / patternsPerLine))

    if #flattenedIotas == 1 then
        lines = 1
        patternsPerLine = 1
    end
    if #flattenedIotas == 3 then
        lines = 1
        patternsPerLine = 3
    end

    if lines * patternsPerLine < #flattenedIotas then error("Not enough room to show all patterns") end

    local w, h = term.getSize()

    if h*3 > w*2 then
        drawScale = w*2/patternsPerLine
    else
        drawScale = h*3/lines
    end
    for i, pattern in pairs(flattenedIotas) do
        i = i - 1
        local locationX = math.floor(i % patternsPerLine)
        local locationY = math.floor(i / patternsPerLine)
        local drawX = locationX*(w/patternsPerLine)*2+w/patternsPerLine
        local drawY = locationY*(h/lines*2.5)+(h/lines*1.5)
        if type(pattern) == "table" then
            if pattern.angles then
                if pattern.type == "pattern" then
                    drawPattern(pattern, {drawX, drawY}, drawScale, nil)
                else
                    drawPattern(pattern, {drawX, drawY}, drawScale, pattern.color)
                end
                table.insert(patternLocations, {drawX/2+.5, drawY/3+.5, pattern})
            else
                table.insert(stringBuffer, {drawX/2+.5, drawY/3+2+.5, pattern})
            end
        else
            table.insert(stringBuffer, {drawX/2 - #pattern/2+.5, drawY/3+2+.5, pattern})
        end
    end
    drawBuffer()
end

---@param pattern TypedPatternIota|PatternIota
---@return string
local function getPatternName(pattern)
    local patternName = HexPatterns[pattern.angles]
    if patternName == nil then patternName = "Unknown Pattern" else patternName = patternName[1] end
    local isNumString = string.sub(pattern.angles, 1, 4)
    if isNumString == "aqaa" or isNumString == "dedd" then
        NumString = string.sub(pattern.angles, 5, 1000)
        Number = 0
        for i = 1, #NumString do
            local c = NumString:sub(i, i)
            if     c == "a" then Number = Number * 2
            elseif c == "q" then Number = Number + 5
            elseif c == "w" then Number = Number + 1
            elseif c == "e" then Number = Number + 10
            elseif c == "d" then Number = Number / 2
            end
        end
        if isNumString == "dedd" then Number = Number * -1 end
        return "Numerical Reflection: " .. tostring(Number)
    end
    return patternName
end

---@param focus Iota?
---@param noStringClear boolean?
---@param drawScale number?
local function drawFullHex(focus, noStringClear, drawScale)
    if noStringClear == nil then noStringClear = false end
    if drawScale == nil then drawScale = .5 end
    monitor.setTextScale(drawScale)
    brailleBuffer = {}

    patternLocations = {}
    w, h = term.getSize()
    monitorShape = (h*3)/(w*2)

    size = w*h*6
    for i = 1, size do
        brailleBuffer[i] = 0
    end

    if focus == nil then
        RenderList({null = true}, size)
    else
        RenderList(focus, size)
    end
end

term.clear()
local focus = focalPort.readIota()
drawFullHex(focus)

local function wait_for_redstone()
    os.pullEvent("redstone")
    drawFullHex(focus)
end

local function wait_for_focus()
    os.pullEvent("focus_inserted")

    focus = focalPort.readIota()
    drawFullHex(focus)
end

local function wait_for_iota()
    os.pullEvent("new_iota")

    focus = focalPort.readIota()
    drawFullHex(focus)
end

local function wait_for_touch()
    local _, _, touch_x, touch_y = os.pullEvent("monitor_touch")
    local closestPattern = {}
    local closestDistance = 10000000
    for _, pattern in pairs(patternLocations) do
        local pattern_x = pattern[1]
        local pattern_y = pattern[2]
        local pattern_iota = pattern[3]
        local distance = (pattern_x - touch_x)^2 + (pattern_y - touch_y)^2
        if distance < closestDistance then
            closestPattern = pattern_iota
            closestDistance = distance
        end
    end

    local indexString ---@type string
    if closestPattern.index then
        indexString = ""
        for i = #closestPattern.index, 1, -1 do
            indexString = indexString .. closestPattern.index[i] .. ":"
        end
        indexString = indexString:sub(1, -2)
    else
        indexString = "nil"
    end

    if closestPattern.type == "pattern" then
        if closestPattern.index then
            table.insert(stringBuffer, {1, 1, "Showing pattern at index: " .. indexString})
            table.insert(stringBuffer, {1, 2, getPatternName(closestPattern)})
        else
            table.insert(stringBuffer, {1, 1, getPatternName(closestPattern)})
        end

        drawFullHex(closestPattern.data, true, 1)
    elseif closestPattern.type == "listStart" or closestPattern.type == "listEnd" then
        table.insert(stringBuffer, {1, 1, "Showing list at index: " .. indexString})
        drawFullHex(closestPattern.data, true)
    else
        monitor.setTextScale(2)
        -- term.clear()
        term.setCursorPos(1, 1)
        print("Showing "..closestPattern.type.." at index: " .. indexString)
        pprint(closestPattern.data)
    end

    while true do
        local e = {os.pullEvent()}
        if e[1] == "monitor_touch" then
            break
        end
    end
    term.clear()
    drawFullHex(focus)
end

while true do
    parallel.waitForAny(wait_for_focus, wait_for_iota, wait_for_touch, wait_for_redstone)
end

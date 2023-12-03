-- constants

local FILE = "day1.txt"

-- fetch and aggregate the input data

local f = fs.open(FILE, "r")
assert(f ~= nil, "Failed to open file")

---@type string[]
local iotas = {}
local accumulator = ""

while true do
    local line = f.readLine()
    if line == nil then break end

    if #accumulator + #line + 1 > 1728 then
        table.insert(iotas, accumulator)
        accumulator = line
    else
        if #accumulator > 0 then
            accumulator = accumulator.."\n"
        end
        accumulator = accumulator..line
    end
end

f.close()

if #accumulator > 0 then
    table.insert(iotas, accumulator)
end

-- send it to the focus !

local focalPort = peripheral.wrap("top")
assert(focalPort ~= nil, "No peripheral found on top of computer")
---@cast focalPort FocalPort

focalPort.writeIota(iotas)

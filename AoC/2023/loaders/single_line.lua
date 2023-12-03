-- constants

local FILE = "day3.txt"

-- fetch and aggregate the input data

local f = fs.open(FILE, "r")
assert(f ~= nil, "Failed to open file")

local lines = {}

while true do
    local line = f.readLine()
    if line == nil then break end

    table.insert(lines, line)
end

f.close()

-- send it to the focus !

local focalPort = peripheral.wrap("top")
---@cast focalPort +FocalPort
assert(focalPort ~= nil, "No peripheral found on top of computer")

focalPort.writeIota(lines)

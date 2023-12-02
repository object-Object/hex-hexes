-- constants

local FILE = "day1.txt"

-- type defs

---@class FocalPort
---@field readIota fun(): any
---@field writeIota fun(value: any)
---@field canWriteIota fun(): boolean
---@field getIotaType fun(): string
---@field hasFocus fun(): boolean

-- fetch and aggregate the input data

local f = fs.open(FILE, "r")
assert(f ~= nil, "Failed to open file")

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
---@cast focalPort +FocalPort
assert(focalPort ~= nil, "No peripheral found on top of computer")

focalPort.writeIota(iotas)

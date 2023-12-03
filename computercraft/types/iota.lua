---@meta

---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Lua-Iota-Mappings)
---@alias Iota
---| HexIota
---| HexalIota
---| MoreIotasIota

-- Hex Casting

---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Lua-Iota-Mappings#base-hex-iotas)
---@alias HexIota
---| NullIota
---| GarbageIota
---| DoubleIota
---| BooleanIota
---| VectorIota
---| ListIota
---| EntityIota
---| PatternIota

---@class NullIota
---@field null true

---@class GarbageIota
---@field garbage true

---@alias DoubleIota number

---@alias BooleanIota boolean

---@class VectorIota
---@field x number
---@field y number
---@field z number

---@alias ListIota Iota[]

---@class EntityIota
---@field uuid string
---@field name string? Always provided when reading from a focal port.

---@class PatternIota
---@field startDir startDir
---@field angles string Should only include the characters `aqweds`.

---@alias startDir
---| "EAST"
---| "SOUTH_EAST"
---| "SOUTH_WEST"
---| "WEST"
---| "NORTH_WEST"
---| "NORTH_EAST"

-- Hexal

---Some Hexal iotas are represented as arbitrary UUIDs to prevent arbitrary iota writing. For these you'll get a UUID when you read that iota into Lua, and you can only write that iota back from lua using that UUID.
---
------
---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Lua-Iota-Mappings#hexal-iotas)
---@alias HexalIota
---| IotaTypeIota
---| EntityTypeIota
---| GateIota
---| MoteIota

---@class IotaTypeIota
---@field iotaType string

---@class EntityTypeIota
---@field entityType string

---@class GateIota
---@field gate string Arbitrary UUID.

---@class MoteIota
---@field moteUuid string
---@field itemID string
---@field nexusUuid string? Always provided when reading from a focal port.

-- MoreIotas

---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Lua-Iota-Mappings#more-iotas-iotas)
---@alias MoreIotasIota
---| StringIota
---| MatrixIota

---@alias StringIota string

---@class MatrixIota
---@field col integer Number of columns.
---@field row integer Number of rows.
---@field matrix number[] Linear indexing (top to bottom then left to right).

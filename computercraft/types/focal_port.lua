---@meta

---This peripheral lets you read and write between Hex Casting and ComputerCraft.
---
---On the Hex Casting side this will act just like a focus in an item frame. On the ComputerCraft side you can use `readIota()` and `writeIota()` to work with the data.
---
---See [Lua <-> Iota Mappings](https://github.com/SamsTheNerd/ducky-periphs/wiki/Lua-Iota-Mappings) for details on Lua representations of iotas.
---
---This block requires Hex Casting to be installed. It will not show up without it.
---
------
---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Focal-Port)
---@class FocalPort
---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Focal-Port)
---@field readIota fun(): Iota
---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Focal-Port)
---@field writeIota fun(value: Iota)
---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Focal-Port)
---@field canWriteIota fun(): boolean
---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Focal-Port)
---@field getIotaType fun(): string
---[Official Documentation](https://github.com/SamsTheNerd/ducky-periphs/wiki/Focal-Port)
---@field hasFocus fun(): boolean

---@alias focalPortType '"focal_port"'

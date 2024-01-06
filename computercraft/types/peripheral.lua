---@meta

---@alias duckyPeripheralType
---| focalLinkType
---| focalPortType

---@alias duckyPeripheral
---| FocalLink
---| FocalPort

---@param peripheral duckyPeripheral
---@return duckyPeripheralType ...
function peripheral.getType(peripheral) end
---@param peripheral FocalPort
---@return focalPortType ...
function peripheral.getType(peripheral) end

---@param peripheral duckyPeripheral
---@param peripheralType duckyPeripheralType
---@return boolean|nil hasType
function peripheral.hasType(peripheral, peripheralType) end

---@param peripheral FocalPort
---@param peripheralType focalPortType
---@return true hasType
function peripheral.hasType(peripheral, peripheralType) end

---@param peripheral duckyPeripheral
---@return string name
function peripheral.getName(peripheral) end

---@param name string|computerSide
---@return duckyPeripheral|nil
function peripheral.wrap(name) end

---@param peripheralType duckyPeripheralType
---@param filter? fun(name: string, wrapped: duckyPeripheral): boolean
---@return duckyPeripheral[] wrappedPeripherals
function peripheral.find(peripheralType, filter) end
---@param peripheralType focalPortType
---@param filter? fun(name: string, wrapped: FocalPort): boolean
---@return FocalPort[] wrappedPeripherals
function peripheral.find(peripheralType, filter) end

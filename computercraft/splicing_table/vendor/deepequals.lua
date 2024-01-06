-- http://www.computercraft.info/forums2/index.php?/topic/6055-comparing-tables-and-variables-and-tables-in-function-parameters/

---@param tableOne any
---@param tableTwo any
---@return boolean
local function deepequals(tableOne, tableTwo)
    if tableOne and tableTwo and type(tableOne) == "table" and type(tableTwo) == "table" then
        for k, v in pairs(tableOne) do
            if tableTwo[k] then
                if type(v) == "table" then
                    if not deepequals(v, tableTwo[k]) then return false end
                elseif type(v) ~= type(tableTwo[k]) then
                    return false
                else
                    if v ~= tableTwo[k] then return false end
                end
            else
                return false
            end
        end
        for k, v in pairs(tableTwo) do
            if not tableOne[k] then
                return false
            end
        end
        return true
    else
        return tableOne == tableTwo
    end
end

return deepequals

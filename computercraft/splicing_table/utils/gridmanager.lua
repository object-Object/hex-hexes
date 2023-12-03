---@alias padding integer|AxisPadding|XYPadding

---@class AxisPadding
---@field x integer?
---@field y integer?

---@class XYPadding
---@field left integer?
---@field right integer?
---@field top integer?
---@field bottom integer?

---@class FullPadding
---@field left integer
---@field right integer
---@field top integer
---@field bottom integer

---@param padding padding?
---@return FullPadding
local function getFullPadding(padding)
    padding = padding or 0

    if type(padding) == "number" then
        return { ---@type FullPadding
            left=padding,
            right=padding,
            top=padding,
            bottom=padding,
        }
    elseif padding.x ~= nil then
        return { ---@type FullPadding
            left=padding.x or 0,
            right=padding.x or 0,
            top=padding.y or 0,
            bottom=padding.y or 0,
        }
    else
        return { ---@type FullPadding
            left=padding.left or 0,
            right=padding.right or 0,
            top=padding.top or 0,
            bottom=padding.bottom or 0,
        }
    end
end

---@package
---@class PartialGridManager
---@field package mon Redirect
---@field package columns integer
---@field package rows integer
---@field package padding FullPadding
---@field package margin FullPadding

---@class GridManager: PartialGridManager
---@field package termX integer
---@field package termY integer
---@field package buttonX integer
---@field package buttonY integer
---@field package fullButtonX integer
---@field package fullButtonY integer
local GridManager = {
    ---@param self GridManager
    ---@param x integer
    ---@param y integer
    ---@return integer xMin
	---@return integer yMin
	---@return integer xMax
	---@return integer yMax
    at = function (self, x, y)
        assert(x >= 1, "Out of bounds (expected x>=1, got "..x..")")
        assert(y >= 1, "Out of bounds (expected y>=1, got "..y..")")
        assert(x <= self.columns, "Out of bounds (expected x<="..self.columns..", got "..x..")")
        assert(y <= self.rows, "Out of bounds (expected y<="..self.rows..", got "..y..")")

        local xMin = self.margin.left + (x - 1)*self.fullButtonX + self.padding.left + 1
        local yMin = self.margin.top + (y - 1)*self.fullButtonY + self.padding.top + 1

        local xMax = xMin + self.buttonX - 1
        local yMax = yMin + self.buttonY - 1

        return xMin, yMin, xMax, yMax
    end,

    ---@param self GridManager
    refresh = function(self)
        self.termX, self.termY = self.mon.getSize()

        local usableX = self.termX - self.margin.left - self.margin.right
        local usableY = self.termY - self.margin.top - self.margin.bottom

        self.fullButtonX = math.floor(usableX / self.columns)
        self.fullButtonY = math.floor(usableY / self.rows)

        self.buttonX = self.fullButtonX - self.padding.left - self.padding.right
        self.buttonY = self.fullButtonY - self.padding.top - self.padding.bottom
    end,
}

local gridmanager = {}

---@class GridManagerOptions
---@field padding padding?
---@field margin padding?

---@param monSide monSide
---@param columns integer
---@param rows integer
---@param options GridManagerOptions
---@return GridManager
function gridmanager.new(monSide, columns, rows, options)
    local mon = monSide and peripheral.wrap(monSide) or term.current()
    ---@cast mon Redirect

	local instance = { ---@type PartialGridManager
        mon=mon,
        columns=columns,
        rows=rows,
        padding=getFullPadding(options.padding),
        margin=getFullPadding(options.margin),
    }

	setmetatable(instance, {__index = GridManager})
    ---@cast instance GridManager

    instance:refresh()
	return instance
end

return gridmanager

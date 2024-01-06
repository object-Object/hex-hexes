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
    elseif padding.x ~= nil or padding.y ~= nil then
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

---@class AlignmentOptions
---@field scaleX number?
---@field scaleY number?
---@field alignX "left" | "right"?
---@field alignY "top" | "bottom"?

---@class GridButtonOptions: ButtonOptions, AlignmentOptions

---@package
---@class PartialGridManager
---@field package t TouchPoint
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
    ---@param options AlignmentOptions
    ---@return integer xMin
	---@return integer yMin
	---@return integer xMax
	---@return integer yMax
    pos = function (self, x, y, options)
        assert(x >= 1, "Out of bounds (expected x>=1, got "..x..")")
        assert(y >= 1, "Out of bounds (expected y>=1, got "..y..")")
        assert(x <= self.columns, "Out of bounds (expected x<="..self.columns..", got "..x..")")
        assert(y <= self.rows, "Out of bounds (expected y<="..self.rows..", got "..y..")")

        local xMin = self.margin.left + (x - 1)*self.fullButtonX + self.padding.left + 1
        local yMin = self.margin.top + (y - 1)*self.fullButtonY + self.padding.top + 1

        local xMax = xMin + self.buttonX - 1
        local yMax = yMin + self.buttonY - 1

        if options.scaleX ~= nil then
            local deltaX = self.buttonX * (1 - options.scaleX)

            if options.alignX == "left" then
                xMax = xMax - deltaX
            elseif options.alignX == "right" then
                xMin = xMin + deltaX
            else
                deltaX = math.floor(deltaX / 2)
                xMin = xMin + deltaX
                xMax = xMax - deltaX
            end
        end

        if options.scaleY ~= nil then
            local deltaY = self.buttonY * (1 - options.scaleY)

            if options.alignY == "top" then
                yMax = yMax - deltaY
            elseif options.alignY == "bottom" then
                yMin = yMin + deltaY
            else
                deltaY = math.floor(deltaY / 2)
                yMin = yMin + deltaY
                yMax = yMax - deltaY
            end
        end

        return xMin, yMin, xMax, yMax
    end,

    ---@param self GridManager
	---@param name buttonName
    ---@param x integer
    ---@param y integer
	---@param func (fun(): boolean)?
	---@param options GridButtonOptions?
	add = function(self, name, x, y, options, func)
        options = options or {}
        local xMin, yMin, xMax, yMax = self:pos(x, y, options)
        return self.t:add(name, func, xMin, yMin, xMax, yMax, options)
    end,

    ---@param self GridManager
    refresh = function(self)
        self.termX, self.termY = self.t:getMonitor().getSize()

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

---@param t TouchPoint
---@param columns integer
---@param rows integer
---@param options GridManagerOptions?
---@return GridManager
function gridmanager.new(t, columns, rows, options)
    options = options or {}

    local instance = { ---@type PartialGridManager
        t=t,
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

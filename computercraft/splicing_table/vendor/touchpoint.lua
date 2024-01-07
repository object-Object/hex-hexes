--[[
The MIT License (MIT)
 
Copyright (c) 2013 Lyqyd
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

---@class ButtonLabel: string[]
---@field label string

---@alias buttonName string|ButtonLabel

---@param buttonLen integer
---@param minY integer
---@param maxY integer
---@param name buttonName
---@return string[]
---@return buttonName
local function setupLabel(buttonLen, minY, maxY, name)
	local labelTable = {}
	if type(name) == "table" then
		for i = 1, #name do
			labelTable[i] = name[i]
		end
		name = name.label
	elseif type(name) == "string" then
		local buttonText = string.sub(name, 1, buttonLen - 2)
		if #buttonText < #name then
			buttonText = " "..buttonText.." "
		else
			local labelLine = string.rep(" ", math.floor((buttonLen - #buttonText) / 2))..buttonText
			buttonText = labelLine..string.rep(" ", buttonLen - #labelLine)
		end
		for i = 1, maxY - minY + 1 do
			if maxY == minY or i == math.floor((maxY - minY) / 2) + 1 then
				labelTable[i] = buttonText
			else
				labelTable[i] = string.rep(" ", buttonLen)
			end
		end
	end
	return labelTable, name
end

---@alias monSide computerSide|"term"

---@class ButtonOptions
---@field inactiveColor integer?
---@field activeColor integer?
---@field inactiveText integer?
---@field activeText integer?

---@class Button: ButtonOptions
---@field func (fun(): boolean)?
---@field xMin integer
---@field yMin integer
---@field xMax integer
---@field yMax integer
---@field active boolean
---@field label string[]

---@class TouchPoint
---@field side monSide
---@field mon Redirect
---@field buttonList { [string]: Button }
---@field clickMap any
---@field defaultOptions ButtonOptions
local TouchPoint = {
	---@param self TouchPoint
	draw = function(self)
		local old = term.redirect(self.mon)
		term.setTextColor(colors.white)
		term.setBackgroundColor(colors.black)
		term.clear()
		for name, buttonData in pairs(self.buttonList) do
			if buttonData.active then
				term.setBackgroundColor(buttonData.activeColor)
				term.setTextColor(buttonData.activeText)
			else
				term.setBackgroundColor(buttonData.inactiveColor)
				term.setTextColor(buttonData.inactiveText)
			end
			for i = buttonData.yMin, buttonData.yMax do
				term.setCursorPos(buttonData.xMin, i)
				term.write(buttonData.label[i - buttonData.yMin + 1])
			end
		end
		term.redirect(old)
	end,

	---@param self TouchPoint
	---@param name buttonName
	---@param func fun(boolean)?
	---@param xMin integer
	---@param yMin integer
	---@param xMax integer
	---@param yMax integer
	---@param options ButtonOptions?
	add = function(self, name, func, xMin, yMin, xMax, yMax, options)
		options = options or {}
		local label, name = setupLabel(xMax - xMin + 1, yMin, yMax, name)
		if self.buttonList[name] then error("button already exists", 2) end
		local x, y = self.mon.getSize()
		if xMin < 1 or yMin < 1 or xMax > x or yMax > y then error("button out of bounds", 2) end
		self.buttonList[name] = {
			func = func,
			xMin = xMin,
			yMin = yMin,
			xMax = xMax,
			yMax = yMax,
			active = false,
			inactiveColor = options.inactiveColor or self.defaultOptions.inactiveColor,
			activeColor = options.activeColor or self.defaultOptions.activeColor,
			inactiveText = options.inactiveText or self.defaultOptions.inactiveText,
			activeText = options.activeText or self.defaultOptions.activeText,
			label = label,
		}
		for i = xMin, xMax do
			for j = yMin, yMax do
				if self.clickMap[i][j] ~= nil then
					--undo changes
					for k = xMin, xMax do
						for l = yMin, yMax do
							if self.clickMap[k][l] == name then
								self.clickMap[k][l] = nil
							end
						end
					end
					self.buttonList[name] = nil
					error("overlapping button", 2)
				end
				self.clickMap[i][j] = name
			end
		end
		return name
	end,

	---@param self TouchPoint
	---@param name buttonName
	remove = function(self, name)
		if self.buttonList[name] then
			local button = self.buttonList[name]
			for i = button.xMin, button.xMax do
				for j = button.yMin, button.yMax do
					self.clickMap[i][j] = nil
				end
			end
			self.buttonList[name] = nil
		end
	end,

	---@param self TouchPoint
	run = function(self)
		while true do
			self:draw()
			local event = {self:handleEvents(os.pullEvent(self.side == "term" and "mouse_click" or "monitor_touch"))}
			if event[1] == "button_click" then
				self.buttonList[event[2]].func()
			end
		end
	end,

	---@param self TouchPoint
	---@param name buttonName
	clickButton = function(self, name)
		local button = self.buttonList[name]
		if button.func == nil or button.func() then
			self:flash(name)
		end
	end,

	---@param self TouchPoint
	---@param ... event|string
	---@return event|string ...
	handleEvents = function(self, ...)
		local event = {...}
		if #event == 0 then event = {os.pullEvent()} end
		if (self.side == "term" and event[1] == "mouse_click") or (self.side ~= "term" and event[1] == "monitor_touch" and event[2] == self.side) then
			local clicked = self.clickMap[event[3]][event[4]]
			if clicked and self.buttonList[clicked] then
				return "button_click", clicked
			end
		end
		return unpack(event)
	end,

	---@param self TouchPoint
	---@param name buttonName
	---@param noDraw boolean?
	toggleButton = function(self, name, noDraw)
		self.buttonList[name].active = not self.buttonList[name].active
		if not noDraw then self:draw() end
	end,

	---@param self TouchPoint
	---@param name buttonName
	---@param duration number?
	flash = function(self, name, duration)
		self:toggleButton(name)
		sleep(tonumber(duration) or 0.15)
		self:toggleButton(name)
	end,

	---@param self TouchPoint
	---@param name buttonName
	---@param newName buttonName
	rename = function(self, name, newName)
		self.buttonList[name].label, newName = setupLabel(self.buttonList[name].xMax - self.buttonList[name].xMin + 1, self.buttonList[name].yMin, self.buttonList[name].yMax, newName)
		if not self.buttonList[name] then error("no such button", 2) end
		if name ~= newName then
			self.buttonList[newName] = self.buttonList[name]
			self.buttonList[name] = nil
			for i = self.buttonList[newName].xMin, self.buttonList[newName].xMax do
				for j = self.buttonList[newName].yMin, self.buttonList[newName].yMax do
					self.clickMap[i][j] = newName
				end
			end
		end
		self:draw()
	end,

	---@param self TouchPoint
	---@param name buttonName
	---@param newName buttonName
	setLabel = function(self, name, newName)
		local button = self.buttonList[name]
		button.label, _ = setupLabel(button.xMax - button.xMin + 1, button.yMin, button.yMax, newName)
		self:draw()
	end,

	---@param self TouchPoint
	---@return Redirect
	getMonitor = function(self)
		return self.mon
	end,
}

local touchpoint = {}

---@param monSide monSide
---@param defaultOptions ButtonOptions?
---@return TouchPoint
function touchpoint.new(monSide, defaultOptions)
	defaultOptions = defaultOptions or {}
	local mon = monSide and peripheral.wrap(monSide) or term.current() ---@cast mon Redirect

	---@type TouchPoint
	local buttonInstance = {
		side = monSide or "term",
		mon = mon,
		buttonList = {},
		clickMap = {},
		defaultOptions = {
			inactiveColor = defaultOptions.inactiveColor or colors.red,
			activeColor = defaultOptions.activeColor or colors.lime,
			inactiveText = defaultOptions.inactiveText or colors.black,
			activeText = defaultOptions.activeText or colors.black,
		},
	}
	local x, y = buttonInstance.mon.getSize()
	for i = 1, x do
		buttonInstance.clickMap[i] = {}
	end
	setmetatable(buttonInstance, {__index = TouchPoint})
	return buttonInstance
end

return touchpoint

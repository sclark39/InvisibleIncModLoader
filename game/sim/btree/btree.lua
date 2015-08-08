require("class")
local simdefs = include( "sim/simdefs" )

local IndentString = "   "
local RunningString = ">"
local ExpandComposites = false
------------------------------------------------------------------------------------------------
local Behaviour = class(function(self, name)
	self.status = simdefs.BSTATE_INVALID
	self.name = name
end)

--THESE SHOULD BE DEFINED IN CHILD BEHAVIOURS
-- function Behaviour:onInitialise()
-- end

-- function Behaviour:onTerminate()
-- end

-- function Behaviour:update()
-- end

function Behaviour:isRunning()
	return self.status == simdefs.BSTATE_RUNNING
	 or self.status == simdefs.BSTATE_WAITINGFORCORPTURN
	 or self.status == simdefs.BSTATE_WAITING
	 or self.status == simdefs.BSTATE_WAITINGFORPCTURN
end

function Behaviour:getDebugString(indent)
	indent = indent or ""
	local runningString = self.status == simdefs.BSTATE_RUNNING and RunningString or string.rep(" ", string.len(RunningString) )
	local colorString = "888888"
	if self.status == simdefs.BSTATE_RUNNING then
		colorString = "ffff00"
	elseif self.status == simdefs.BSTATE_WAITING then
		colorString = "ff7700"
	elseif self.status == simdefs.BSTATE_COMPLETE then
		colorString = "00ff00"
	elseif self.status == simdefs.BSTATE_FAILED then
		colorString = "ff0000"
	elseif self.status == simdefs.BSTATE_WAITINGFORCORPTURN then
		colorString = "0000ff"
    elseif self.status == simdefs.BSTATE_WAITINGFORPCTURN then
        colorString = "770000"
	end
	return string.format("%s%s<c:%s>%s</>", indent, runningString, colorString, self.name)
end

--helper function to deal with updating a behaviour. Should not be overridden
function Behaviour:tick()
	if not self:isRunning() and self.onInitialise then
		self:onInitialise()
	end

	assert(self.update)
	self.status = self:update()

	if not self:isRunning() and self.onTerminate then
		self:onTerminate()
	end
	return self.status
end

function Behaviour:reset()
	if self:isRunning() and self.onTerminate then
		self:onTerminate()
	end
	self.status = simdefs.BSTATE_INVALID
end
------------------------------------------------------------------------------------------------
-- Base class for Sequences and Selectors
local CompositeBehaviour = class(Behaviour, function(self, name, children)
	if type(name) == "table" and not children then
		children = name
		name = "Composite"
	end
	Behaviour.init(self, name)
	self.children = children or {}
end)

function CompositeBehaviour:onInitialise()
	self.currentChild = 1
end

function CompositeBehaviour:onTerminate()
	self.currentChild = #self.children
end

function CompositeBehaviour:getDebugString(indent)
	indent = indent or ""
	local debugString = Behaviour.getDebugString(self, indent)
	if self.status ~= simdefs.BSTATE_INVALID or ExpandComposites then
		for i,child in ipairs(self.children) do
				debugString = debugString.."\n"
				debugString = debugString..child:getDebugString(indent..IndentString)
		end
	end
	return debugString
end

function CompositeBehaviour:reset()
	for i,child in ipairs(self.children) do
		child:reset()
	end

	Behaviour.reset(self)
end

------------------------------------------------------------------------------------------------
-- Runs behaviours in succession until one fails
local Sequence = class(CompositeBehaviour, function(self, name, children)
	if type(name) == "table" and not children then
		children = name
		name = "Sequence"
	else
		name = name.."[SQ]"
	end
	CompositeBehaviour.init(self, name, children)
end)

function Sequence:update()
	self.status = simdefs.BSTATE_RUNNING
	while self.currentChild and self:isRunning() do
		local child = self.children[self.currentChild]
		if child then
			local status = child:tick()
			if status ~= simdefs.BSTATE_COMPLETE then
				self.status = status
				return self.status
			end
		end
		self.currentChild = self.currentChild < #self.children and self.currentChild+1
	end
	self.status = simdefs.BSTATE_COMPLETE
	return self.status
end
------------------------------------------------------------------------------------------------
-- Runs behaviours in succession until one succeeds
local Selector = class(CompositeBehaviour, function(self, name, children)
	if type(name) == "table" and not children then
		children = name
		name = "Selector"
	else
		name = name.."[SL]"
	end
	CompositeBehaviour.init(self, name, children)
end)

function Selector:update()
	self.status = simdefs.BSTATE_RUNNING
	while self.currentChild and self:isRunning() do
		local child = self.children[self.currentChild]
		if child then
			local status = child:tick()
			if status ~= simdefs.BSTATE_FAILED then
				self.status = status
				return self.status
			end
		end
		self.currentChild = self.currentChild < #self.children and self.currentChild+1
	end
	self.status = simdefs.BSTATE_FAILED
	return self.status
end
------------------------------------------------------------------------------------------------
-- Runs behaviours simultaneously until one completes
local Parallel = class(CompositeBehaviour, function(self, name, children)
	if type(name) == "table" and not children then
		children = name
		name = "Parallel"
	else
		name = name.."[PL]"
	end
	CompositeBehaviour.init(self, name, children)
end)

function Parallel:update()
	self.status = simdefs.BSTATE_RUNNING
	while self:isRunning() do
		for k,child in ipairs(self.children) do
			local status = child:tick()
			if status ~= simdefs.BSTATE_RUNNING then
				self.status = status
				return self.status
			end
		end
	end
	return self.status
end
------------------------------------------------------------------------------------------------
-- Adds functionality to a behaviour
local Decorator = class(Behaviour, function(self, name, child)
	if type(name) == "table" and not child then
		child = name
		name = "Decorator"
	end
	Behaviour.init(self, name)
	self.child = child
end)

function Decorator:getDebugString(indent)
	return Behaviour.getDebugString(self, indent).."(\n"..self.child:getDebugString(indent..IndentString)..")"
end

function Decorator:reset()
	self.child:reset()
	Behaviour.reset(self)
end

------------------------------------------------------------------------------------------------
-- Repeat a behaviour multiple times
local Repeat = class(Decorator, function(self, name, limit, child)
	if not child then
		if type(limit) == "table" then
			child = limit
		elseif type(name) == "table" then
			child = name
		end
	end
	if not limit or type(limit) ~= "number" then
		limit = 2
	end
	if type(name) ~= "string" then
		limit = name
		name = "Repeat x"..limit
	end
	Decorator.init(self, name, child)
	self.limit = limit
end)

function Repeat:onInitialise()
	self.counter = 0
end

function Repeat:update()
	self.status = simdefs.BSTATE_RUNNING
	while self.counter < self.limit and self:isRunning() do
		local status = self.child:tick()
		if status ~= simdefs.BSTATE_COMPLETE then
			self.status = status
			return self.status
		end
		self.counter = self.counter + 1
	end
	self.status = simdefs.BSTATE_COMPLETE
	return self.status
end

------------------------------------------------------------------------------------------------
-- Always succeed a behaviour
local Always = class(Decorator, function(self, name, child)
	if type(name) == "table" and not child then
		child = name
		name = "Always"
	end
	Decorator.init(self, name, child)
end)

function Always:update()
	self.status = simdefs.BSTATE_RUNNING
	self.status = self.child:tick()
	self.status = simdefs.BSTATE_COMPLETE
	return self.status
end
------------------------------------------------------------------------------------------------
-- Invert the result of a behaviour
local Not = class(Decorator, function(self, name, child)
	if type(name) == "table" and not child then
		child = name
		name = "Not"
	end
	Decorator.init(self, name, child)
end)

function Not:update()
	self.status = simdefs.BSTATE_RUNNING
	self.status = self.child:tick()
	if self.status == simdefs.BSTATE_COMPLETE then
		self.status = simdefs.BSTATE_FAILED
	elseif self.status == simdefs.BSTATE_FAILED then
		self.status = simdefs.BSTATE_COMPLETE
	end
	return self.status
end
------------------------------------------------------------------------------------------------
-- Base class for Behaviours that can check or affect the world
local BaseAction = class(Behaviour, function(self, name)
	Behaviour.init(self, name or "Leaf")
	self.sim = nil
	self.unit = nil
end)

function BaseAction:setup(sim, unit)
	self.sim = sim
	self.unit = unit
end
------------------------------------------------------------------------------------------------
local SimpleAction = class(BaseAction, function(self, name, func)
	if type(name) == "function" and not func then
		func = name
		name = "SimpleAction"
	end
	BaseAction.init(self, name)
	local actions = include("sim/btree/actions")
	local conditions = include("sim/btree/conditions")
	self.name = self:findNameFromTables(func, actions, conditions)
	self[self.name] = func
end)

function SimpleAction:update()
	self.status = simdefs.BSTATE_RUNNING
	assert(self[self.name])
	local result = self[self.name](self.sim, self.unit)
	self.status = result or simdefs.BSTATE_FAILED
	return self.status
end

function SimpleAction:findNameFromTables(testFunc, ...)
	--look through the parameters for names
	for i,funcs in ipairs(arg) do
		for name,func in pairs(funcs) do
			if func == testFunc then
				return name
			end
		end
	end
end
-----------------------------------------------------------------------------------------
local Condition = class(SimpleAction, function(self, name, func)
	if type(name) == "function" and not func then
		func = name
		name = "Condition"
	end
	SimpleAction.init(self, name, func)
end)

function Condition:update()
	assert(self[self.name])
	self.status = simdefs.BSTATE_RUNNING
	if self[self.name](self.sim, self.unit) then
		self.status = simdefs.BSTATE_COMPLETE
	else
		self.status = simdefs.BSTATE_FAILED
	end
	return self.status
end
-----------------------------------------------------------------------------------------

return
{
	Behaviour = Behaviour,
	CompositeBehaviour = CompositeBehaviour,
	Sequence = Sequence,
	Selector = Selector,
	Decorator = Decorator,
	Repeat = Repeat,
	Always = Always,
	Not = Not,
	BaseAction = BaseAction,
	Action = SimpleAction,
	Condition = Condition,
}

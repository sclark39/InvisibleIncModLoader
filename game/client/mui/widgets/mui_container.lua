-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local mui_component = require( "mui/widgets/mui_component" )

local mui_container = class( mui_component )

function mui_container:init( def )
	mui_component.init( self, MOAIProp2D.new(), def )
	self._children = {}
end

function mui_container:updatePriority( priority )
	mui_component.updatePriority( self, priority )
	
	for i,component in ipairs(self._children) do
		priority = component:updatePriority( priority + 1 )
	end
	return priority
end

function mui_container:calculateTotalBounds()
	local x, y, w, h = self:calculateBounds()
	if #self._children == 0 then
		return x, y, w, h
	end

	local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
	for i,component in ipairs(self._children) do
		local x, y, w, h = component:calculateBounds()
		minx = math.min( minx, x - w/2 )
		maxx = math.max( maxx, x + w/2 )
		miny = math.min( miny, y - h/2 )
		maxy = math.max( maxy, y + h/2 )
	end

	return (minx + maxx) / 2 + x, (miny + maxy) / 2 + y, (maxx - minx), (maxy - miny)
end

function mui_container:recurse( fn, ... )
	mui_component.recurse( self, fn, ... )

	for i,component in ipairs(self._children) do
		component:recurse( fn, ... )
	end
end

function mui_container:addComponent( component, index )
	assert( not array.find( self._children, component ))
	assert( component._parent == nil )

	component._parent = self

	if index == nil then
		table.insert( self._children, component )
	elseif index < 0 then
		table.insert( self._children, #self._children + 1 + index + 1, component )
	else
		table.insert( self._children, index, component )
	end
	component:link( self )
end

function mui_container:removeComponent( component )
	assert( array.find( self._children, component ))
	assert( component._parent == self )

	component:unlink( self )
	array.removeElement( self._children, component )
	component._parent = nil	
end

return mui_container


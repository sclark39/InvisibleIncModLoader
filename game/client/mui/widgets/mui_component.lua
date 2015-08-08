-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require("modules/util")
local mui_defs = require("mui/mui_defs")
local mui_util = require("mui/mui_util")

local AnchorCentre = 0
local AnchorBottomLeft = 1
local AnchorLeft = 2
local AnchorTopLeft = 3
local AnchorTop = 4
local AnchorTopRight = 5
local AnchorRight = 6
local AnchorBottomRight = 7
local AnchorBottom = 8

---------------------------------------------------------------------------------
--

local mui_component = class()

function mui_component:init( prop, def )
	prop:setDepthMask( false )

	self._def = def
	self._x, self._y, self._xpx, self._ypx = def.x, def.y, def.xpx, def.ypx
	self._w, self._h, self._wpx, self._hpx = def.w, def.h, def.wpx, def.hpx
	assert(self._w or self._wpx, def.name)
	assert(self._h or self._hpx, def.name)
	self._sx, self._sy = def.sx or 1, def.sy or 1
	self._anchor = def.anchor
	self._prop = prop
	self._prop:setDebugName( def.name or "?ui?" )
	self._handlers = nil
	self._parent = nil
	self._isVisible = true

	if def.noInput then
		self._noInput = true
	end
end

function mui_component:destroy( screen )
	assert( self._prop )
	assert( self._parent == nil )
	
	screen:unregisterProp( self._prop )
	self._prop = nil
end

function mui_component:link( cont )
	self._prop:setAttrLink( MOAIProp.INHERIT_TRANSFORM, cont._prop, MOAIProp.TRANSFORM_TRAIT)
	self._prop:setAttrLink( MOAIProp.ATTR_VISIBLE, cont._prop, MOAIProp.ATTR_VISIBLE)
	self._prop:setAttrLink( MOAIProp.ATTR_SHADER, cont._prop, MOAIProp.ATTR_SHADER)
	self._prop:setAttrLink( MOAIProp.ATTR_SHADER_UNIFORMS, cont._prop, MOAIProp.ATTR_SHADER_UNIFORMS)
end

function mui_component:unlink( cont )
	self._prop:clearAttrLink( MOAIProp.INHERIT_TRANSFORM )
	self._prop:clearAttrLink( MOAIProp.ATTR_VISIBLE )
	self._prop:clearAttrLink( MOAIProp.ATTR_SHADER )
	self._prop:clearAttrLink( MOAIProp.ATTR_SHADER_UNIFORMS )
end

function mui_component:getPosition()
	return self._x, self._y
end


function mui_component:setPosition( x, y )
    assert( self._boundsHandler == nil )
	if x then
		self._x = x
	end
	if y then
		self._y = y
	end
	self:refreshProp()
end

function mui_component:getSize()
	return self._w, self._h
end

function mui_component:setSize( w, h )
	if w ~= nil then
		self._w = w
	end
	if h ~= nil then
		self._h = h
	end

	self:refreshProp()
end

function mui_component:getWidth()
	return self._w
end

function mui_component:getHeight()
	return self._h
end

function mui_component:setScale( sx, sy )
	self._sx, self._sy = sx, sy
	self:refreshProp()
end


function mui_component:readSkinnedProperty( key )
	local skin = self._screen:getSkin()
	local t = self._def.skin_properties
	if type(t) == "table" then
		local prop = t[ key ]
		if prop then
			if skin == nil or not prop[ skin ] then
				return prop.default
			else
				return prop[ skin ]
			end
		end
	end
end

function mui_component:applySkinnedProperties()
	local position = self:readSkinnedProperty( "position" )
	if position then
		self._x, self._y, self._xpx, self._ypx = position.x, position.y, position.xpx, position.ypx
	end

	local size = self:readSkinnedProperty( "size" )
	if size then
		self._w, self._h, self._wpx, self._hpx = size.w, size.h, size.wpx, size.hpx
	end
end

function mui_component:calculateBounds()
    if self._boundsHandler then
        self._boundsHandler( self )
    else
        self:applySkinnedProperties()
    end

	local W, H = self._screen:getResolution()
	-- Get precise pixel coords.
	local px, py = self._x, self._y
	if not self._xpx then
		px = px * W
	end
	if not self._ypx then
		py = py * H
	end
	local pw, ph = self._w * self._sx, self._h * self._sy
	if not self._wpx then
		pw = pw * W
	end
	if not self._hpx then
		ph = ph * H
	end
	if self._parent == nil then
		if self._anchor == AnchorCentre then
			px = px + 0.5 * W
			py = py + 0.5 * H
		elseif self._anchor == AnchorLeft then
			py = py + 0.5 * H
		elseif self._anchor == AnchorTopLeft then
			py = H - py
		elseif self._anchor == AnchorTop then
			px, py = px + 0.5 * W, H - py
		elseif self._anchor == AnchorTopRight then
			px, py = W - px, H - py
		elseif self._anchor == AnchorRight then
			px, py = W - px, py + 0.5 * H
		elseif self._anchor == AnchorBottomRight then
			px = W - px
		elseif self._anchor == AnchorBottom then
			px = px + 0.5 * W
		end
	end

	-- Now transform to normalized.
	local x, y, w, h = math.floor(px) / W, math.floor(py) / H, math.floor(pw) / W, math.floor(ph) / H
	return x, y, w, h
end

function mui_component:refreshProp()
	if self._screen then
		local x, y, w, h = self:calculateBounds()
		self._prop:setLoc( x, y )
		self._prop:setScl( self._sx, self._sy )
		self._prop:setBounds( -w/2, -h/2, 0, w/2, h/2, 0 )
		self._prop:forceUpdate()
	end
end

function mui_component:getPriority()
	return self._prop:getPriority()
end

function mui_component:updatePriority( priority )
	self._prop:setPriority( priority )
	return priority
end


function mui_component:getProp()
	return self._prop
end

function mui_component:setVisible( isVisible )
	self._isVisible = isVisible
	self._prop:setVisible( isVisible )
end

function mui_component:isVisible()
	local component = self
	while component do
		if component._isVisible == false then
			return false
		end
		component = component._parent
	end

	return self._prop:shouldDraw()
end

function mui_component:recurse( fn, ... )
	fn( self, ... )
end

function mui_component:onActivate( screen, widget )
	screen:registerProp( self._prop, self )
	screen:addEventHandler( self, mui_defs.EVENT_OnResize )
	self._screen = screen
	self._widget = widget
	self:refreshProp()
end

function mui_component:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_OnResize then
		self:refreshProp()
	end
end


function mui_component:onDeactivate( screen )
    self:clearTransition()
	screen:unregisterProp( self._prop )
	screen:removeEventHandler( self )
	screen:unlockInput( self._widget )

	self._screen, self._widget = nil, nil
end

function mui_component:handleInputEvent( ev )
	if self._noInput then
		return false
	end

	-- Sink mouse events by default
	return mui_util.isMouseEvent( ev )
end

function mui_component:addEventHandler( handler, evType )
	if not self._handlers then
		self._handlers = {}
	end

	if not self._handlers[evType] then
		self._handlers[evType] = {}
	end
	
	assert( not array.find( self._handlers[evType], handler ))
	table.insert( self._handlers[evType], handler )
end

function mui_component:removeEventHandler( handler )
	assert( self._handlers )

	for i,handlers in ipairs( self._handlers ) do
		array.remove( handlers, handler )
	end
end

function mui_component:dispatchEvent( ev )
	assert( ev.eventType )
	
	if self._handlers then
		if self._handlers[mui_defs.EVENT_ALL] then
			for i,handler in ipairs( self._handlers[mui_defs.EVENT_ALL] ) do
				if handler:handleEvent( ev ) then
					return true
				end
			end
		end

		if self._handlers[ev.eventType] then
			for i,handler in ipairs( self._handlers[ev.eventType] ) do
				if handler:handleEvent( ev ) then
					return true
				end
			end
		end
	end
end


function mui_component:reverseTransition()
	assert( self._transition )
	if self._transition.mode == MOAITimer.REVERSE then
		self._transition.easer:setMode( MOAITimer.NORMAL )
		self._transition.mode = MOAITimer.NORMAL
	else
		self._transition.easer:setMode( MOAITimer.REVERSE )
		self._transition.mode = MOAITimer.REVERSE
	end
end

function mui_component:createTransition( def, fn )
	assert( self._transition == nil )
	local x0, y0 = self._prop:getLoc()

	self._prop:setLoc( x0 + def.dx0, y0 + def.dy0 )
	-- Need to clear shader link or we'll just inherit from our parent.
	self._prop:clearAttrLink( MOAIProp.ATTR_SHADER )
	self._prop:clearAttrLink( MOAIProp.ATTR_SHADER_UNIFORMS )
	local shader = MOAIShaderMgr.getShader( MOAIShaderMgr.KLEI_SHUTTER )
	self._prop:setShader( shader, true )
	local shader_uniforms = KLEIShaderUniforms.new()
	self._prop:setShaderUniforms( shader_uniforms )
	

	local easeDriver = self._prop:seekLoc( x0 + def.dx1, y0 + def.dy1, def.duration )
	easeDriver:setListener ( MOAITimer.EVENT_TIMER_END_SPAN,
		function( timer )
			local transition = self._transition
			self:clearTransition()
			if transition.fn then
				transition.fn( transition )
			end
		end )

	shader_uniforms:setUniformFloat( "shutter_distance", 10 )
	shader_uniforms:setUniformDriver(
		function( uniforms )
			if def.easeOut then
				uniforms:setUniformFloat( "ease", 1 - easeDriver:getTime() / easeDriver:getPeriod() )
			else
				uniforms:setUniformFloat( "ease", easeDriver:getTime() / easeDriver:getPeriod() )
			end
		end
		)

	self._transition =
	{
		prop = self._prop,
		x0 = x0,
		y0 = y0,
		easer = easeDriver,
		mode = MOAITimer.NORMAL,
		def = def,
		fn = fn,
	}
end

function mui_component:clearTransition()
	if self._transition then
		local transition = self._transition
		self._transition = nil

		transition.prop:setLoc( transition.x0, transition.y0 )
		transition.prop:setShader( nil, true )
		transition.prop:setShaderUniforms( nil )
		-- Restore link to parent.. which is whoever we're ATTR_VISIBLE linked to!
		local parent = transition.prop:getAttrLink( MOAIProp.ATTR_VISIBLE )
		if parent then -- NOTE: parent is nil if self == screen._root
			transition.prop:setAttrLink( MOAIProp.ATTR_SHADER, parent, MOAIProp.ATTR_SHADER)
			transition.prop:setAttrLink( MOAIProp.ATTR_SHADER_UNIFORMS, parent, MOAIProp.ATTR_SHADER_UNIFORMS )
		end

		if transition.easer then
			transition.easer:stop()
		end
	end
end

function mui_component:hasTransition( name, mode )
	if self._transition == nil then	
		return false
	end
    -- if name is nil, assume we are matching for any
	if name and name ~= self._transition.def.name then
		return false
	end
    -- if mode is nil, assume we are matching for any
	if mode and mode ~= self._transition.mode then
		return false
	end
	return true
end

return mui_component


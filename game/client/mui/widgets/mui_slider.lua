-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local util = require( "modules/util" )
local array = require( "modules/array" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_texture = require( "mui/widgets/mui_texture" )
local mui_container = require( "mui/widgets/mui_container" )
local mui_trackbutton = require( "mui/widgets/mui_trackbutton" )
local mui_button = require( "mui/widgets/mui_button" )
local mui_defs = require( "mui/mui_defs" )

--------------------------------------------------------------------------
--
local IMAGE_Inactive = 1
local IMAGE_Hover = 2
local IMAGE_Active = 3

local function valueToPosition( slider )
	local t = 0
	if slider._max > slider._min then
		t = (slider._value - slider._min) / (slider._max - slider._min)
	end

	return t * slider._w - slider._w / 2, 0
end

local function updateKnob( slider )
	local x, y = valueToPosition( slider )

	slider._knobImg:setPosition( x, y )
	slider._knobBtn:setPosition( x, y )

	if slider._knobBtn:getState() == mui_trackbutton.BUTTON_Inactive then
		slider._knobImg:setImageIndex( IMAGE_Inactive )
		slider._knobImg:setScale( 1, 1 )
		slider._knobImg:setShader()
	elseif slider._knobBtn:getState() == mui_trackbutton.BUTTON_Active then
		slider._knobImg:setImageIndex( IMAGE_Active )
		slider._knobImg:setScale( 0.9, 0.9 )
		slider._knobImg:setShader()
	elseif slider._knobBtn:getState() == mui_trackbutton.BUTTON_Hover then
		slider._knobImg:setImageIndex( IMAGE_Hover )
		slider._knobImg:setScale( 1.1, 1.1 )
		slider._knobImg:setShader()
	elseif slider._knobBtn:getState() == mui_trackbutton.BUTTON_Disabled then
		slider._knobImg:setImageIndex( IMAGE_Inactive )
		slider._knobImg:setScale( 1, 1 )
		slider._knobImg:setShader( MOAIShaderMgr.DESATURATION_SHADER )
	end
end

-- Validates and updates the slider to the new value, updating the knob if necessary.
-- Returns if the value was updated.
local function updateValue( slider, value )
	if slider._step then
		value = value - math.mod( value, slider._step )
	end

	value = math.min( slider._max, math.max( slider._min, value ))

	if value ~= slider._value then
		slider._value = value
		updateKnob( slider )
		return true
	end
end

--------------------------------------------------------------------------
--

local mui_slider = class( mui_widget )

function mui_slider:init( screen, def )
	mui_widget.init( self, def )

	self._w, self._h = def.w, def.h
	self._min, self._max = def.min, def.max
	self._step = def.step
	self._value = self._min
	
	self._trackImg = mui_texture( screen, { x = 0, y = 0, w = def.w, h = def.h, wpx = def.wpx, hpx = def.hpx, images = def.bg_image })
	self._trackBtn = mui_button( { x = 0, y = 0, w = def.w, h = def.h, wpx = def.wpx, hpx = def.hpx  })
	self._trackBtn:addEventHandler( self, mui_defs.EVENT_ALL )
	
	self._knobImg = mui_texture( screen, { x = 0, y = 0, xpx = def.wpx, ypx = def.hpx, w = def.knobw, h = def.knobh, wpx = def.wpx, hpx = def.hpx, images = def.images })
	self._knobBtn = mui_trackbutton( { x = 0, y = 0, xpx = def.wpx, ypx = def.hpx, w = def.knobw, h = def.knobh, wpx = def.wpx, hpx = def.hpx })
	self._knobBtn:addEventHandler( self, mui_defs.EVENT_ALL )
	self._knobBtn:setTrackHandler(
		function( dx, dy, ev )
			local dv = 0
			if self._max > self._min then
				dv = (dx / self._w) * (self._max - self._min)
			end

			if self._step then
				if dv >= self._step or dv <= -self._step then
					self:setValue( self._value + dv - math.mod( dv, self._step ) )
					return true
				else
					return false
				end
			else
				self:setValue( self._value + dv )
				return true
			end
		end )

	self._cont = mui_container( def )
	self._cont:addComponent( self._trackImg )
	self._cont:addComponent( self._trackBtn )
	self._cont:addComponent( self._knobImg )
	self._cont:addComponent( self._knobBtn )
end

function mui_slider:setRange( min, max )
	assert( max >= min )

	self._min, self._max = min, max
	self:setValue( self._value )
end

function mui_slider:getValue()
	return self._value
end

function mui_slider:setValue( value )
	if updateValue( self, value ) and self.onValueChanged then
		util.callDelegate( self.onValueChanged, self, self._value )
	end
end

function mui_slider:setStep( step )
	self._step = step
end

function mui_slider:isSliding()
	return self._sliding ~= nil
end

function mui_slider:handleEvent( ev )
	updateKnob( self )

	if ev.eventType == mui_defs.EVENT_TrackStart then
		self._sliding = true
		if self.onSliderStart then
			util.callDelegate( self.onSliderStart, self, self._value )
		end
	elseif ev.eventType == mui_defs.EVENT_TrackEnd then
		self._sliding = nil
		if self.onSliderStop then
			util.callDelegate( self.onSliderStop, self, self._value )
		end
	elseif ev.widget == self._trackBtn then
		if ev.eventType == mui_defs.EVENT_ButtonClick then
			local x, y = self._trackBtn._prop:worldToModel( ev.ie.x, ev.ie.y )
			-- TODO: assumed horizontal slider
			local t = x / self._w + 0.5
			self:setValue( t * (self._max - self._min) + self._min )
			return true
		end
	end

	return mui_widget.handleEvent( self, ev )
end


return mui_slider


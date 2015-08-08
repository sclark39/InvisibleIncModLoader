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
local mui_util = require( "mui/mui_util" )
local mui_defs = require( "mui/mui_defs" )

--------------------------------------------------------------------------
--

local MIN_KNOBSIZE = 12

local IMAGE_Inactive = 1
local IMAGE_Hover = 2
local IMAGE_Active = 3

local ORIENT_H = 1
local ORIENT_V = 2

local function getTrackImageLength( scrollbar )
	if scrollbar:getOrientation() == ORIENT_H then
		local w = scrollbar._w - scrollbar._upBtn:getWidth() - scrollbar._downBtn:getWidth()
		return w
	elseif scrollbar:getOrientation() == ORIENT_V then
		local h = scrollbar._h - scrollbar._upBtn:getHeight() - scrollbar._downBtn:getHeight()
		return h
	end
end

local function getTrackLength( scrollbar )
	local knobw, knobh = 0, 0
	if scrollbar._knobBtn then
		knobw, knobh = scrollbar._knobBtn:getWidth(), scrollbar._knobBtn:getHeight()
	end
	if scrollbar:getOrientation() == ORIENT_H then
		return getTrackImageLength( scrollbar ) - knobw
	elseif scrollbar:getOrientation() == ORIENT_V then
		return getTrackImageLength( scrollbar ) - knobh
	end
end


local function valueToPosition( scrollbar )
	local t = 0
	if scrollbar._max > scrollbar._min then
		t = scrollbar._value / (scrollbar._max - scrollbar._min)
	end
	
	local len = getTrackLength( scrollbar )
	if scrollbar:getOrientation() == ORIENT_H then
		return t * len - len / 2, 0
	else
		return 0, (1 - t) * len - len/ 2
	end
end

local function updateImageState( btn, img )
	if btn:getState() == mui_button.BUTTON_Inactive then
		img:setImageIndex( IMAGE_Inactive )
		img:setShader()
	elseif btn:getState() == mui_button.BUTTON_Active then
		img:setImageIndex( IMAGE_Active )
		img:setShader()
	elseif btn:getState() == mui_button.BUTTON_Hover then
		img:setImageIndex( IMAGE_Hover )
		img:setShader()
	elseif btn:getState() == mui_button.BUTTON_Disabled then
		img:setImageIndex( IMAGE_Inactive )
		img:setShader( MOAIShaderMgr.DESATURATION_SHADER )
	end
end

local function updateKnob( scrollbar )
	if scrollbar._knobBtn and scrollbar._knobImg then
		local x, y = valueToPosition( scrollbar )
		scrollbar._knobImg:setPosition( x, y )
		scrollbar._knobBtn:setPosition( x, y )
		updateImageState( scrollbar._knobBtn, scrollbar._knobImg )

	else
		local progress = scrollbar._value / (scrollbar._max - scrollbar._min)
		scrollbar._trackImg:setUVRect( 0, 0, progress, 1 )
		local len = getTrackImageLength( scrollbar )
		if scrollbar:getOrientation() == ORIENT_H then
			local w = len * progress
			scrollbar._trackImg:setSize( w )
			scrollbar._trackImg:setPosition( -len/2 + w/2 )
		elseif scrollbar:getOrientation() == ORIENT_V then
			local h = len * progress
			scrollbar._trackImg:setSize( nil, h )
			scrollbar._trackImg:setPosition( nil, len/2 - h/2 )
		end
	end
end

-- Validates and updates the scrollbar to the new value, updating the knob if necessary.
-- Returns if the value was updated.
local function updateValue( scrollbar, value )
	value = math.min( scrollbar._max, math.max( scrollbar._min, math.floor( value + 0.5 )))

	if value ~= scrollbar._value then
		scrollbar._value = value
		updateKnob( scrollbar )
		return true
	end
end

local function updateLayout( scrollbar )
	if scrollbar:getOrientation() == ORIENT_H then
		scrollbar._upBtn:setPosition( (scrollbar._w - scrollbar._upBtn:getWidth()) / 2, 0 )
		scrollbar._upImg:setPosition( (scrollbar._w - scrollbar._upImg:getWidth()) / 2, 0 )
		scrollbar._downBtn:setPosition( (-scrollbar._w + scrollbar._downBtn:getWidth()) / 2, 0 )
		scrollbar._downImg:setPosition( (-scrollbar._w + scrollbar._downImg:getWidth()) / 2, 0 )
		scrollbar._trackImg:setSize( getTrackImageLength( scrollbar ), nil )
		scrollbar._trackBtn:setSize( getTrackImageLength( scrollbar ), nil )  
	else
		scrollbar._upBtn:setPosition( 0, (scrollbar._h - scrollbar._upBtn:getHeight()) / 2, 0 )
		scrollbar._upImg:setPosition( 0, (scrollbar._h - scrollbar._upImg:getHeight()) / 2, 0 )
		scrollbar._downBtn:setPosition( 0, (-scrollbar._h + scrollbar._downBtn:getHeight()) / 2 )
		scrollbar._downImg:setPosition( 0, (-scrollbar._h + scrollbar._downImg:getHeight()) / 2 )
		scrollbar._trackImg:setSize( nil, getTrackImageLength( scrollbar ) )
		scrollbar._trackBtn:setSize( nil, getTrackImageLength( scrollbar ) )
	end

	scrollbar._cont:setSize( scrollbar._w, scrollbar._h )
	updateKnob( scrollbar )
end

local function trackHandler( scrollbar, ie )
	local x, y = scrollbar._trackBtn:getProp():worldToModel( ie.x, ie.y )
	local W, H = scrollbar:getScreen():getResolution()
	if scrollbar._max > scrollbar._min then
		if scrollbar._orientation == ORIENT_H then
			local t = x * W / getTrackImageLength( scrollbar ) + 0.5
			scrollbar:setValue( t * (scrollbar._max - scrollbar._min) + scrollbar._min )
		else
			local t = y * H / getTrackImageLength( scrollbar ) + 0.5
			scrollbar:setValue( (1 - t) * (scrollbar._max - scrollbar._min) + scrollbar._min )
		end
        return true
	end

    return false
end

--------------------------------------------------------------------------
--

local mui_scrollbar = class( mui_widget )

mui_scrollbar.ORIENT_H = ORIENT_H
mui_scrollbar.ORIENT_V = ORIENT_V

function mui_scrollbar:init( screen, def )
	mui_widget.init( self, def )

	self._w, self._h = def.w, def.h
	self._min, self._max = 0, 100
	self._step = def.step or 1
	self._value = 0
	self._screen = screen

	self._orientation = def.orientation or ORIENT_V
	
	if self._orientation == ORIENT_H then
		self._upBtn = mui_button( util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, skin_properties = 0 } )
		self._upImg = mui_texture( screen, util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, images = def.up_images, skin_properties = 0 } )
		self._downBtn = mui_button( util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, skin_properties = 0 } )
		self._downImg = mui_texture( screen, util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, images = def.down_images, skin_properties = 0 } )
		self._trackImg = mui_texture( screen, util.inherit( def ){ x = 0, y = 0, w = def.w, images = def.bg_images, noInput = true, skin_properties = 0 })
	else
		self._downBtn = mui_button( util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, skin_properties = 0 } )
		self._downImg = mui_texture( screen, util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, images = def.down_images, skin_properties = 0 } )
		self._upBtn = mui_button( util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, skin_properties = 0 } )
		self._upImg = mui_texture( screen, util.inherit( def.btn_size ){ x = 0, y = 0, xpx = true, ypx = true, images = def.up_images, skin_properties = 0 } )
		self._trackImg = mui_texture( screen, util.inherit( def ){ x = 0, y = 0, images = def.bg_images, noInput = true, skin_properties = 0 })
	end
	
	self._upBtn:addEventHandler( self, mui_defs.EVENT_ALL )
	self._downBtn:addEventHandler( self, mui_defs.EVENT_ALL )

	if def.knobh >0 and def.knobw > 0 then
        self._trackBtn = mui_button( util.inherit( def ){ x = 0, y = 0, skin_properties = 0 })
	    self._trackBtn:addEventHandler( self, mui_defs.EVENT_ALL )

		self._knobImg = mui_texture( screen, util.inherit( def ){ x = 0, y = 0, w = def.knobw, h = def.knobh, images = def.knob_images, skin_properties = 0 })
		self._knobBtn = mui_trackbutton( util.inherit( def ){ x = 0, y = 0, w = def.knobw, h = def.knobh, skin_properties = 0 })
		self._knobBtn:addEventHandler( self, mui_defs.EVENT_ALL )
		self._knobBtn:setTrackHandler( function( dx, dy, ie ) return trackHandler( self, ie ) end )

    else
		self._trackBtn = mui_trackbutton( util.inherit( def ){ x = 0, y = 0, skin_properties = 0 })
        self._trackBtn:setTrackHandler( function( dx, dy, ie ) return trackHandler( self, ie ) end )
	end

	self._cont = mui_container( def )
	self._cont:addComponent( self._trackImg )
	self._cont:addComponent( self._downImg )
	self._cont:addComponent( self._upImg )
	self._cont:addComponent( self._trackBtn )
	self._cont:addComponent( self._upBtn )
	self._cont:addComponent( self._downBtn )
	if self._knobImg then
		self._cont:addComponent( self._knobImg )
	end
	if self._knobBtn then
		self._cont:addComponent( self._knobBtn )
	end
end

function mui_scrollbar:onActivate( screen )
	mui_widget.onActivate( self, screen )
	updateLayout( self )
end

function mui_scrollbar:getOrientation()
	return self._orientation
end

function mui_scrollbar:setSize( w, h )
	if w ~= nil then
		self._w = w
	end
	if h ~= nil then
		self._h = h
	end
	updateLayout( self )
end

function mui_scrollbar:setRange( min, max )
	assert( max >= min )

	self._min, self._max = min, max
	self:setValue( self._value )

	-- Update knob size based on range and scrollbar size.
	if self._knobImg and self._knobBtn then
		if self._orientation == ORIENT_H then
			self._knobImg._w = math.max( MIN_KNOBSIZE, self._w / (max - min + 1))
			self._knobImg._h = self._h
			self._knobImg:refreshProp()
			self._knobBtn._w = math.max( MIN_KNOBSIZE, self._w / (max - min + 1))
			self._knobBtn._h = self._h
			self._knobBtn:refreshProp()
		elseif self._orientation == ORIENT_V then
			self._knobImg._h = math.max( MIN_KNOBSIZE, self._h / (max - min + 1))
			self._knobImg:refreshProp()
			self._knobBtn._h = math.max( MIN_KNOBSIZE, self._h / (max - min + 1))
			self._knobBtn:refreshProp()
		end
	end

	updateKnob( self ) -- Force knob update since it's size changed, but the scrollbar value hasn't.
end

function mui_scrollbar:getValue()
	return self._value
end

function mui_scrollbar:setValue( value )
	if updateValue( self, value ) and self.onValueChanged then
		util.callDelegate( self.onValueChanged, self, self._value )
	end
end

function mui_scrollbar:handleEvent( ev )
	updateKnob( self )

	if ev.widget == self._upBtn then
		updateImageState( self._upBtn, self._upImg )
		if ev.eventType == mui_defs.EVENT_ButtonClick then
			if self._orientation == ORIENT_H then				
				self:setValue( self._value + self._step )
			elseif self._orientation == ORIENT_V then			
				self:setValue( self._value - self._step )
			end	
		end
		return true

	elseif ev.widget == self._downBtn then
		updateImageState( self._downBtn, self._downImg )
		if ev.eventType == mui_defs.EVENT_ButtonClick then
			if self._orientation == ORIENT_H then				
				self:setValue( self._value - self._step )
			elseif self._orientation == ORIENT_V then			
				self:setValue( self._value + self._step )
			end				
			
		end
		return true

	elseif ev.widget == self._trackBtn then
		updateImageState( self._trackBtn, self._trackImg )
		if ev.eventType == mui_defs.EVENT_ButtonActive then --EVENT_ButtonClick
			local x, y = ev.widget:getProp():worldToModel( ev.ie.x, ev.ie.y )
			local W, H = self:getScreen():getResolution()
			if self._orientation == ORIENT_H then
				local t = x * W / getTrackImageLength( self ) + 0.5
				self:setValue( t * (self._max - self._min) + self._min )
			elseif self._orientation == ORIENT_V then
				local t = y * H / getTrackImageLength( self ) + 0.5
				self:setValue( (1 - t) * (self._max - self._min) + self._min )
			end
		end
		return true
	end

	return mui_widget.handleEvent( self, ev )
end


return mui_scrollbar


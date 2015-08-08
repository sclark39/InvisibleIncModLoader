-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_util = require("mui/mui_util")
local mui_defs = require( "mui/mui_defs" )
local mui_component = require( "mui/widgets/mui_component" )

--------------------------------------------------------
-- Local Functions
--------------------------------------------------------

local mui_trackbutton = class( mui_component )

mui_trackbutton.BUTTON_Inactive = 0
mui_trackbutton.BUTTON_Active = 1
mui_trackbutton.BUTTON_Hover = 2
mui_trackbutton.BUTTON_Disabled = 3

function mui_trackbutton:init( def )
	mui_component.init( self, MOAIProp2D.new(), def)
	
	self._prop:setBounds( -def.w/2, -def.h/2, 0, def.w/2, def.h/2, 0 )
	self._buttonState = mui_trackbutton.BUTTON_Inactive
end

function mui_trackbutton:setTrackHandler( handler )
	self._trackHandler = handler
end

function mui_trackbutton:getState()
	return self._buttonState
end

function mui_trackbutton:onActivate( screen, widget )
	mui_component.onActivate( self, screen, widget )
	screen:addEventHandler( self, mui_defs.EVENT_FocusChanged )
end

function mui_trackbutton:onDeactivate( screen )
	screen:removeEventHandler( self )
	self._buttonState = mui_trackbutton.BUTTON_Inactive
	mui_component.onDeactivate( self, screen )
end

function mui_trackbutton:setDisabled( isDisabled )
	if isDisabled == false and self._buttonState == mui_trackbutton.BUTTON_Disabled then
		self._buttonState = mui_trackbutton.BUTTON_Inactive
		screen:addEventHandler( self, mui_defs.EVENT_FocusChanged )

	elseif isDisabled ~= false and self._buttonState ~= mui_trackbutton.BUTTON_Disabled then
		if screen then
			screen:removeEventHandler( self )
			screen:unlockInput( self )
		end
		self._buttonState = mui_trackbutton.BUTTON_Disabled
	end
end

function mui_trackbutton:handleInputEvent( ev )

	if self._buttonState == mui_trackbutton.BUTTON_Disabled then
		return true -- disabled, just sink it.
	end

	if ev.eventType == mui_defs.EVENT_MouseDown and ev.button == mui_defs.MB_Left then
		assert( self._prop )
		if ( self._prop:inside( ev.x, ev.y )) then
			self._originx, self._originy = ev.x, ev.y
			self._buttonState = mui_trackbutton.BUTTON_Active
			ev.screen:lockInput( self )
			ev.widget = self
			self:dispatchEvent( { eventType = mui_defs.EVENT_TrackStart, ie = ev } )
		end
		return true

	elseif ev.eventType == mui_defs.EVENT_MouseUp and ev.button == mui_defs.MB_Left then
		ev.widget = self
		self:dispatchEvent( ev )
		if self._buttonState == mui_trackbutton.BUTTON_Active then
			ev.screen:unlockInput( self )
			self._originx, self._originy = nil, nil

			if self._prop:inside( ev.x, ev.y ) then
				self._buttonState = mui_trackbutton.BUTTON_Hover
			else
				self._buttonState = mui_trackbutton.BUTTON_Inactive
			end

			self:dispatchEvent( { eventType = mui_defs.EVENT_TrackEnd, ie = ev } )
		end
		return true

	elseif self._buttonState == mui_trackbutton.BUTTON_Active then
		-- Drag ourselves.
		local W, H = ev.screen:getResolution()
		local dx, dy = ev.x - self._originx, ev.y - self._originy
		if self._wpx then
			dx = dx * W
		end
		if self._hpx then
			dy = dy * H
		end
		if self._trackHandler and self._trackHandler( dx, dy, ev ) then
			self._originx, self._originy = ev.x, ev.y
		end
		return true -- Sink any input as long as we're active.

	else
		return mui_component.handleInputEvent( self, ev )
	end
end

function mui_trackbutton:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_FocusChanged then
		if ev.oldFocus == self then
			assert( self._buttonState == mui_trackbutton.BUTTON_Hover or self._buttonState == mui_trackbutton.BUTTON_Inactive )
			self._buttonState = mui_trackbutton.BUTTON_Inactive
			self:dispatchEvent( { eventType = mui_defs.EVENT_ButtonLeave, widget = self, ie = ev } )

		elseif ev.newFocus == self then
			assert( self._buttonState == mui_trackbutton.BUTTON_Inactive )
			self._buttonState = mui_trackbutton.BUTTON_Hover
			self:dispatchEvent( { eventType = mui_defs.EVENT_ButtonEnter, widget = self, ie = ev } )
		end

	else
		return mui_component.handleEvent( self, ev )
	end
end


return mui_trackbutton

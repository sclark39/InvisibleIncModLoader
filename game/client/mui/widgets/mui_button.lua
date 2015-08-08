-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "client_util" )
local mathutil = require( "modules/mathutil" )
local mui_util = require("mui/mui_util")
local mui_defs = require( "mui/mui_defs" )
local mui_component = require( "mui/widgets/mui_component" )

--------------------------------------------------------
-- Hit zones
--------------------------------------------------------

local hitzone_prop = class()

function hitzone_prop:inside( prop, x0, y0 )
	return prop:inside( x0, y0 )
end

local hitzone_rect = class()

function hitzone_rect:init( x0, y0, x1, y1 )
	self._x0, self._y0 = x0, y0
	self._x1, self._y1 = x1, y1
end

function hitzone_rect:inside( prop, x0, y0 )
	local x, y = prop:worldToModel( x0, y0 )

	if x < self._x0 or x > self._x1 or y < self._y0 or y > self._y1 then
		return false
	end

	return true
end


local hitzone_wedge = class()

function hitzone_wedge:init( r0, r1, th0, th1, w, h )
	self._r0, self._r1 = r0, r1
	self._w, self._h = w, h
	self._th0, self._th1 = th0, th1
end

function hitzone_wedge:inside( prop, x0, y0 )
	local x, y = prop:worldToModel( x0, y0 )

	-- Check within angle bounds
	local a = mathutil.atan2t( x, y )
	if a < self._th0 or a > self._th1 then
		return false
	end

	-- Check within distance bounds.
	local r2 = self._w * self._w * self._h * self._h / (self._h * self._h * math.cos(a) * math.cos(a) + self._w * self._w * math.sin(a) * math.sin(a))
	local r = mathutil.distSqr2d( 0, 0, x, y ) / r2
	if r < self._r0 * self._r0 or r > self._r1 * self._r1 then
		return false
	end

	return true
end


--------------------------------------------------------
-- Local Functions
--------------------------------------------------------

local mui_button = class( mui_component )

mui_button.BUTTON_Inactive = 0
mui_button.BUTTON_Active = 1
mui_button.BUTTON_Hover = 2
mui_button.BUTTON_Disabled = 3

function mui_button:init( def )
	mui_component.init( self, MOAIProp2D.new(), def)
	
	self._buttonState = mui_button.BUTTON_Inactive
	self._hotkey = def.hotkey
	self._clickEvent = def.clickEvent

	if def.r0 then
		self._hitzone = hitzone_wedge( def.r0, def.r1, def.a0, def.a1, def.w/2, def.h/2 )
	elseif def.hitx0 then
		self._hitzone = hitzone_rect( def.hitx0, def.hity0, def.hitx1, def.hity1 )
	else
		self._hitzone = hitzone_prop()
	end

	if def.draggable then
		self._drag = true
	end
end

function mui_button:getState()
	return self._buttonState
end

function mui_button:setState( state, clickButton )
	if self._buttonState ~= state then
		if self._buttonState == mui_button.BUTTON_Active then
			self._screen:unlockInput( self )
		end

		self._buttonState = state
		self._clickButton = clickButton

		if self._buttonState == mui_button.BUTTON_Active then
			self._screen:lockInput( self )
		end
	end
end

function mui_button:setDisabled( isDisabled )
	if isDisabled then
		self:setState( mui_button.BUTTON_Disabled )
	else
		self:setState( mui_button.BUTTON_Inactive )
	end
end

function mui_button:setHotkey( hotkey )
	if self._screen then
		if not self._hotkey and hotkey then
			self._screen:addEventHandler( self, mui_defs.EVENT_KeyDown )
		elseif self._hotkey and not hotkey then
			self._screen:removeEventHandler( self, mui_defs.EVENT_KeyDown )
		end
	end

	self._hotkey = hotkey
end

function mui_button:onActivate( screen, widget )
	mui_component.onActivate( self, screen, widget )

	if self._hotkey then
		screen:addEventHandler( self, mui_defs.EVENT_KeyDown )
	end
	screen:addEventHandler( self, mui_defs.EVENT_FocusChanged )
end

function mui_button:onDeactivate( screen )
    if self._buttonState == mui_button.BUTTON_Active or self._buttonState == mui_button.BUTTON_Hover then
    	self:setState( mui_button.BUTTON_Inactive )
    end
	screen:removeEventHandler( self )

	mui_component.onDeactivate( self, screen )
end

function mui_button:isClickButton( button )
	if self._clickButton then
		return button == self._clickButton
	else
		return button == mui_defs.MB_Left
	end
end

function mui_button:handleDragging( ev )
	assert( self._drag )

	if ev.screen:getDragDrop() then
		if ev.eventType == mui_defs.EVENT_MouseUp and self:isClickButton( ev.button ) then
			ev.screen:unlockInput( self )
			self:dispatchEvent( { eventType = mui_defs.EVENT_DragLeave, widget = self, ie = ev } )
			return self:dispatchEvent( { eventType = mui_defs.EVENT_DragDrop, widget = self, ie = ev } )

		elseif ev.eventType == mui_defs.EVENT_MouseMove then
			if ev.screen:getInputLock() ~= self then
				if self:dispatchEvent( { eventType = mui_defs.EVENT_DragEnter, widget = self, ie = ev } ) then
					ev.screen:lockInput( self )
					return true
				end
			elseif not self._prop:inside( ev.x, ev.y ) then
				ev.screen:unlockInput( self )
				self:dispatchEvent( { eventType = mui_defs.EVENT_DragLeave, widget = self, ie = ev } )
				return true
			end
		end

	else
		if ev.eventType == mui_defs.EVENT_MouseDown and self:isClickButton( ev.button ) then
			assert( self:inside( ev.x, ev.y ))
			return self:dispatchEvent( { eventType = mui_defs.EVENT_DragStart, widget = self, ie = ev } )
		end
	end

	return false	
end

function mui_button:handleInputEvent( ev )
    if not self:isVisible() then
        return false
    end
	if self._buttonState == mui_button.BUTTON_Disabled then
		return self:inside( ev.x, ev.y ) 
	end

	if self._drag then
		return self:handleDragging( ev )

	elseif ev.screen:getDragDrop() == nil then
		if ev.eventType == (self._clickEvent or mui_defs.EVENT_MouseUp) and self:isClickButton( ev.button ) then
			if self:inside( ev.x, ev.y ) then
                if self._buttonState == mui_button.BUTTON_Active or ev.eventType ~= mui_defs.EVENT_MouseUp then
				    self:setState( mui_button.BUTTON_Hover )
				    self:dispatchEvent( { eventType = mui_defs.EVENT_ButtonClick, widget = self, ie = ev } )
                end
			else
				self:setState( mui_button.BUTTON_Inactive )
				self:dispatchEvent( { eventType = mui_defs.EVENT_ButtonLeave, widget = self, ie = ev } )
			end
			return true
		
		elseif ev.eventType == mui_defs.EVENT_MouseDown and self:isClickButton( ev.button ) then
            -- ccc: this assert is great, except it's entirely possible for button presses to NOT come in pairs.  If the user
            -- presses down, tab-switches and releases the button with another process active, then a consecutive
            -- mouse down can easily occur while this button has locked input..  Obviously this 'double press'
            -- is not guaranteed to be inside this button at all.
			--assert( self:inside( ev.x, ev.y ), tostring(self._widget and self._widget:getPath()) )
			self:setState( mui_button.BUTTON_Active, ev.button )
            self:dispatchEvent( { eventType = mui_defs.EVENT_ButtonActive, widget = self, ie = ev } )
            self.clickx, self.clicky = ev.x, ev.y
			return true

		elseif self._buttonState == mui_button.BUTTON_Active then
            if ev.eventType == mui_defs.EVENT_MouseMove then
                if self.clickx and self.clicky and mathutil.dist2d( self.clickx, self.clicky, ev.x, ev.y ) > 0.02 then
        			self:dispatchEvent( { eventType = mui_defs.EVENT_DragStart, widget = self, ie = ev } )
                    self.clickx, self.clicky = nil, nil
                end
            end
			return true -- Sink any input as long as we're active.

		else
			return self:inside( ev.x, ev.y )
		end
	end
end

function mui_button:inside( x, y )
	-- x and y are screen coordinates
	return self._hitzone:inside( self._prop, x, y )
end

function mui_button:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_KeyDown and self._hotkey ~= nil and self:isVisible() then
        -- Lookup dynamically bound hotkeys.
        local binding = self._hotkey
        if type(self._hotkey) == "string" then
            binding = util.getKeyBinding( self._hotkey )
        end
        if mui_util.isBinding( ev, binding ) then
			self:dispatchEvent( {
                eventType = mui_defs.EVENT_ButtonHotkey,
                widget = self,
                disabled = (self._buttonState == mui_button.BUTTON_Disabled),
                ie = ev } )
			return true
        end
	
	elseif ev.eventType == mui_defs.EVENT_OnLostLock then
		assert( self._buttonState == mui_button.BUTTON_Active )
		self:setState( mui_button.BUTTON_Inactive )

	elseif ev.eventType == mui_defs.EVENT_FocusChanged then
		if ev.oldFocus == self then
			if self._buttonState ~= mui_button.BUTTON_Disabled then
				self:setState( mui_button.BUTTON_Inactive )
			end
			self:dispatchEvent( { eventType = mui_defs.EVENT_ButtonLeave, widget = self, ie = ev } )

		elseif ev.newFocus == self then
			if self._buttonState ~= mui_button.BUTTON_Disabled then
				if self._buttonState ~= mui_button.BUTTON_Active then
					self:setState( mui_button.BUTTON_Hover )
				end
			end
			self:dispatchEvent( { eventType = mui_defs.EVENT_ButtonEnter, widget = self, ie = ev } )
		end

	else
		return mui_component.handleEvent( self, ev )
	end
end


return mui_button

-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_button = require( "mui/widgets/mui_button" )
local mui_texture = require( "mui/widgets/mui_texture" )
local mui_text = require( "mui/widgets/mui_text" )
local mui_container = require( "mui/widgets/mui_container" )
require( "class" )

--------------------------------------------------------
-- Local Functions

local IMAGE_Inactive = 1
local IMAGE_Hover = 2
local IMAGE_Active = 3

local DEFAULT_HOVER_SCALE = 1.1

--------------------------------------------------------

local mui_imagebutton = class( mui_widget )

function mui_imagebutton:init( screen, def )
	mui_widget.init( self, def )

	self._clickSound = def.clickSound
	self._hoverSound = def.hoverSound
	self._hoverScale = def.hoverScale or DEFAULT_HOVER_SCALE

	local skinProperties = def.skin_properties and util.tcopy( def.skin_properties )
	if skinProperties and skinProperties.position then
		skinProperties.position = nil
	end

	assert(def.w and def.h, def.name)
	self._image = mui_texture( screen, util.inherit( def ){ x = 0, y = 0, sx = 1, sy = 1, noInput = true, skin_properties = skinProperties })
	
	self._button = mui_button( util.inherit( def ){ x = 0, y = 0, sx = 1, sy = 1, skin_properties = 0 })
	self._button:addEventHandler( self, mui_defs.EVENT_ALL )

	self._cont = mui_container( def )
	self._cont:addComponent( self._image )
	if def.text_style and #def.text_style > 0 then
		local textDefs = { name = def.name, w = def.w, h = def.h, wpx = def.wpx, hpx = def.hpx, line_spacing = def.line_spacing, text_style = def.text_style, halign = def.halign, valign = def.valign, rawstr = def.rawstr, str = def.str, color = def.color }
		if def.offset then
			textDefs.x, textDefs.y, textDefs.xpx, textDefs.ypx = def.offset.x, def.offset.y, def.offset.xpx, def.offset.ypx
		else
			textDefs.x, textDefs.y = 0, 0
		end
		self._label = mui_text( screen, textDefs )

		if def.color then
            self._txtColorInActive = util.color( unpack(def.color) )
        else
            self._txtColorInActive = util.color.WHITE
        end
        if def.active_color then
            self._txtColorActive = util.color( unpack(def.active_color) )
        else
            self._txtColorActive = util.color.WHITE
            -- By default, derive active color from the 'inactive' color of the image.
            local activeClr = self._image:getColorAtIndex( IMAGE_Active )
            if activeClr then
                self._txtColorActive = util.color( activeClr[1]/4, activeClr[2]/4, activeClr[2]/4 )
            end
        end

		self._cont:addComponent( self._label )
	end
	self._cont:addComponent( self._button )

	self:updateImageState( self )
end

function mui_imagebutton:setColor( r, g, b, a )	
	self._image:setColor( r, g, b, a )
end

function mui_imagebutton:setColorInactive( r, g, b, a )
    self._image:setColorAtIndex( {r, g, b, a}, IMAGE_Inactive )
end

function mui_imagebutton:setColorActive( r, g, b, a )
    self._image:setColorAtIndex( {r, g, b, a}, IMAGE_Active )
end

function mui_imagebutton:setColorHover( r, g, b, a )
    self._image:setColorAtIndex( {r, g, b, a}, IMAGE_Hover )
end


function mui_imagebutton:getText()
	return self._label:getText()
end

function mui_imagebutton:getLabel()
	return self._label
end

function mui_imagebutton:setText( str )
	self._label:setText( str )
end

function mui_imagebutton:spoolText( str, speed )
	self._label:spoolText( str, speed )
end

function mui_imagebutton:setTextColor( r, g, b, a )
	self._label:setColor( r, g, b, a )
end

function mui_imagebutton:setTextColorInactive( r, g, b, a )
	self._txtColorInActive = util.color( r, g, b, a )
end

function mui_imagebutton:setTextColorActive( r, g, b, a )
	self._txtColorActive = util.color( r, g, b, a )
end

function mui_imagebutton:setDisabled( isDisabled )
    if (self._button:getState() == mui_button.BUTTON_Disabled) ~= isDisabled then
	    self._button:setDisabled( isDisabled )
	    self:updateImageState( self )
    end
end

function mui_imagebutton:setInactiveImage( str )
	self._image:setImageAtIndex( str, IMAGE_Inactive )
	self:updateImageState(self)
end

function mui_imagebutton:setActiveImage( str )
	self._image:setImageAtIndex( str, IMAGE_Active )
	self:updateImageState(self)
end

function mui_imagebutton:setHoverImage( str )
	self._image:setImageAtIndex( str, IMAGE_Hover )
	self:updateImageState(self)
end

function mui_imagebutton:setImage( str )
	self:setImages( str )
end

function mui_imagebutton:setImages( str )
	self:setInactiveImage( str )
	self:setActiveImage( str )
	self:setHoverImage( str )
end

function mui_imagebutton:setVisible( isVisible )
	mui_widget.setVisible( self, isVisible )
    if not isVisible then
        self._button:setState( mui_button.BUTTON_Inactive )
    end
end

function mui_imagebutton:setClickSound(sound)
	self._clickSound = sound
end

function mui_imagebutton:blink( period, blinkCountPerPeriod, periodInterval, blinkTxtColor )
	if period == nil or period <= 0 then
        
        if self.blinking then
            self.blinking = false

    		if self._blinkTimer then
    			self._blinkTimer:stop()
    		end
    		if self._blinkIntervalTimer then
    			self._blinkIntervalTimer:stop()
    		end
    		self._blinkTimer = nil
    		self._blinkIndex = nil
    		self._blinkCount = nil
    		self._blinkIntervalTimer = nil
    		self._blinkPeriodCount = nil
    		self._blinkTxtColor = nil

    		self:setStateInactive()
        end
	else
        self.blinking = true
		local blinkfn = function()
			if self._blinkTimer then
				self._blinkTimer:stop()
			end
			
			local timer = MOAITimer.new()
			timer:setSpan ( period )
			timer:setMode ( MOAITimer.LOOP )
			timer:setListener ( MOAITimer.EVENT_TIMER_LOOP,
				function()
					self._blinkIndex = self._blinkIndex + 1
					self:updateImageState()
				end )
			timer:start()

			self._blinkTimer = timer
			self._blinkCount = 0
			self._blinkIndex = 0
		end

		if periodInterval > 0 then
			--jcheng: if 0, don't repeat at all
			local intervalTimer = MOAITimer.new ()
			intervalTimer:setSpan ( periodInterval )
			intervalTimer:setMode ( MOAITimer.LOOP )
			intervalTimer:setListener ( MOAITimer.EVENT_TIMER_LOOP, blinkfn)
			intervalTimer:start()

			self._blinkIntervalTimer = intervalTimer
		end

		self._blinkTxtColor = blinkTxtColor
		blinkfn()
		self._blinkCountPerPeriod = blinkCountPerPeriod

	end
end

function mui_imagebutton:stop()
    mui_widget.stop( self )
    self:blink( nil )
end

function mui_imagebutton:handleTooltip( x, y )
	if self._button:inside( x, y ) then
		return mui_widget.handleTooltip( self, x, y )
	end
end

function mui_imagebutton:setHotkey( hotkey )
	self._button:setHotkey( hotkey )
end

function mui_imagebutton:handleClick( ev )
	if self._clickSound then
		MOAIFmodDesigner.playSound( self._clickSound )
	end
	if self.onClick then
		util.coDelegate( self.onClick, self, ev.ie )
	elseif self.onClickImmediate then
		util.callDelegate( self.onClickImmediate, self, ev.ie )
	end
end

function mui_imagebutton:handleEvent( ev )

	if ev.widget == self._button then
		self:updateImageState( self )

		if ev.eventType == mui_defs.EVENT_ButtonClick then
            self:handleClick( ev )
			return true

        elseif ev.eventType == mui_defs.EVENT_ButtonHotkey then
            if self.onHotkey then
                util.callDelegate( self.onHotkey, self, ev.disabled )
            elseif not ev.disabled then
                self:handleClick( ev ) -- behaves as if click.
                return true
            end

		elseif ev.eventType == mui_defs.EVENT_ButtonLeave then
			if self.onLeave then
				util.callDelegate( self.onLeave, self, ev.ie )
			end
			return true

		elseif ev.eventType == mui_defs.EVENT_ButtonEnter then
			if self._hoverSound then
				MOAIFmodDesigner.playSound( self._hoverSound )
			end
			if self.onEnter then
				util.callDelegate( self.onEnter, self, ev.ie )
			end
			return true

        elseif ev.eventType == mui_defs.EVENT_DragStart and self.onDragStart then
		    return util.callDelegate( self.onDragStart, self )
		end		

	end

	return mui_widget.handleEvent( self, ev )
end

function mui_imagebutton:updateImageState()
	if self._button:getState() == mui_button.BUTTON_Inactive then

		--turn off blinking if we're done blinking
		if self._blinkTimer and self._blinkCount >= self._blinkCountPerPeriod and self._blinkIntervalTimer == nil then
			self._blinkTimer:stop()
		end

		if self._blinkIndex and self._blinkIndex % 2 == 0 and self._blinkCount < self._blinkCountPerPeriod then
			self:setStateActive()
			MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/button_flash" )
			self._blinkCount = self._blinkCount + 1
		else
			self:setStateInactive()
		end

	elseif self._button:getState() == mui_button.BUTTON_Active then

		self:setStateActive()

	elseif self._button:getState() == mui_button.BUTTON_Hover then
		
		self:setStateHover()

	elseif self._button:getState() == mui_button.BUTTON_Disabled then
		self._image:setImageIndex( IMAGE_Inactive )
		self._image:setShader( MOAIShaderMgr.DESATURATION_SHADER )
	end
end

function mui_imagebutton:isActive()
    return self._button:getState() == mui_button.BUTTON_Active
end

function mui_imagebutton:setStateInactive()
	self._image:setImageIndex( IMAGE_Inactive )

	if self._label then
        local clr = self._txtColorInActive
        if clr then
		    self._label:setColor( clr:unpack() )
        end
	end

	self._image:setShader()
end

function mui_imagebutton:setStateActive()
	self._image:setImageIndex( IMAGE_Active )

	if self._label then
        local clr = self._txtColorActive
        if clr then
		    self._label:setColor( clr:unpack() )
        end
	end

	if self._label and self._blinkTxtColor then
		self._label:setColor( self._blinkTxtColor.r, self._blinkTxtColor.g, self._blinkTxtColor.b, self._blinkTxtColor.a )
	end

	self._image:setShader()		
end

function mui_imagebutton:setStateHover()
	self._image:setImageIndex( IMAGE_Hover )

	if self._label then
        local clr = self._txtColorActive
        if clr then
		    self._label:setColor( clr:unpack() )
        end
	end

	self._image:setShader()		
end

return mui_imagebutton

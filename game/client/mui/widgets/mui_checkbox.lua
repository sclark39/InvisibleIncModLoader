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

local CHECKBOX_No = 1
local CHECKBOX_Yes = 2
local CHECKBOX_Maybe = 3

local function updateImageState( self )
	if self._button:getState() == mui_button.BUTTON_Disabled then
		self._image:setShader( MOAIShaderMgr.DESATURATION_SHADER )
    else
		self._image:setShader( nil )
    end
   	self._image:setImageIndex( self._checked )
end

local function updateLayout( self, screen )
	self._image:setPosition( self._w / 2 - self._checkSize )
	self._image:setSize( self._checkSize, self._checkSize )
end



--------------------------------------------------------

local mui_checkbox = class( mui_widget )

function mui_checkbox:init( screen, def )
	mui_widget.init( self, def )

	self._w, self._h = def.w, def.h
	
	self._checked = CHECKBOX_No
	self._checkSize = def.check_size
	self._clickSound = def.clickSound
	
	self._image = mui_texture( screen, { x = 0, y = 0, xpx = def.wpx, ypx = def.hpx, w = def.h, h = def.h, wpx = def.wpx, hpx = def.hpx, images = def.images })
	
	self._label = mui_text( screen, { x = 0, y = 0, w = def.w, h = def.h, hpx = def.hpx, wpx = def.wpx, text_style = def.text_style, rawstr = def.rawstr, str = def.str, color = def.color, halign = MOAITextBox.LEFT_JUSTIFY, valign = MOAITextBox.CENTER_JUSTIFY })
	
	self._button = mui_button( util.inherit( def ){ x = 0, y = 0, skin_properties = 0 })
	self._button:addEventHandler( self, mui_defs.EVENT_ALL )

	self._cont = mui_container( def )
	self._cont:addComponent( self._image )
	self._cont:addComponent( self._label )
	self._cont:addComponent( self._button )

	updateImageState( self )
end

function mui_checkbox:setClickSound(sound)
	self._clickSound = sound
end


function mui_checkbox:setChecked( isChecked )
	local state
	if isChecked then
		state = CHECKBOX_Yes
	else
		state = CHECKBOX_No
	end

	if state ~= self._checked then
		self._checked = state
		
		if self.onClick then
			util.callDelegate( self.onClick, self )
		end

		updateImageState( self )
	end
	if self._clickSound then
		MOAIFmodDesigner.playSound( self._clickSound )
	end
end

function mui_checkbox:setValue( value )
    assert( type(value) == "boolean", type(value) )
    self:setChecked( value )
end

function mui_checkbox:getValue( value )
    return self:isChecked()
end

function mui_checkbox:isChecked()
	return self._checked == CHECKBOX_Yes
end

function mui_checkbox:setDisabled( isDisabled )
   	self._button:setDisabled( isDisabled )
	updateImageState( self )
end

function mui_checkbox:setVisible( isVisible )
	mui_widget.setVisible( self, isVisible )
    if not isVisible then
        self._button:setState( mui_button.BUTTON_Inactive )
    end
end

function mui_checkbox:onActivate( screen )
	mui_widget.onActivate( self, screen )
	updateLayout( self, screen )
	screen:addEventHandler( self, mui_defs.EVENT_OnResize )
end

function mui_checkbox:onDeactivate( screen )
	mui_widget.onDeactivate( self, screen )
	screen:removeEventHandler( self )
end

function mui_checkbox:setText( str )
	self._label:setText( str )
end

function mui_checkbox:handleEvent( ev )

	if ev.eventType == mui_defs.EVENT_OnResize then
		updateLayout( self, ev.screen )
		
	elseif ev.widget == self._button then
		if ev.eventType == mui_defs.EVENT_ButtonClick then
			self:setChecked( not self:isChecked() )
			return true

        elseif ev.eventType == mui_defs.EVENT_ButtonHotkey then
			self:setChecked( not self:isChecked() )
			return true
		end
	end
end


return mui_checkbox

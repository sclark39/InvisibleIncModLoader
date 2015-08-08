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
local mui_listbox = require( "mui/widgets/mui_listbox" )
require( "class" )

--------------------------------------------------------
-- Local Functions

local DEFAULT_COMBOBOX_SKIN = "combobox_listbox"
local BUTTON_TO_TEXT_OFFSET = 1.5


local function updateImageState( self )
	if self._btn:getState() == mui_button.BUTTON_Active then
		self._arrowImg:setColor( 1, 1, 0 )
		self._arrowImg:setShader( nil )
	elseif self._btn:getState() == mui_button.BUTTON_Hover then
		self._arrowImg:setColor( 0.5, 0.5, 0 )
		self._arrowImg:setShader( nil )
	elseif self._btn:getState() == mui_button.BUTTON_Disabled then
		self._arrowImg:setShader( MOAIShaderMgr.DESATURATION_SHADER )
	else
		self._arrowImg:setShader( nil )
		self._arrowImg:setColor( 1, 1, 1 )
	end
end

local function updateLayout( self, screen )
	local arrowWidth, arrowHeight = self._arrowSize, self._arrowSize
	if not self._wpx then
		arrowWidth, arrowHeight = screen:uiToWndSize( self._arrowSize, self._arrowSize )
		arrowWidth, arrowHeight = screen:wndToUISize( arrowHeight, arrowHeight )
	end



	self._arrowImg:setPosition( (self._w - arrowWidth) / 2, 0 )
	self._arrowImg:setSize( arrowWidth, arrowHeight )
	self._btn:setPosition( (self._w - arrowWidth) / 2, 0 )
	self._btn:setSize( arrowWidth, arrowHeight )
	self._editBox:setPosition( -arrowWidth * BUTTON_TO_TEXT_OFFSET / 2 )
	self._editBox:setSize( self._w - arrowWidth * BUTTON_TO_TEXT_OFFSET )
end

local function destroyDropDown( combobox )
	if combobox._listbox then
		combobox:getScreen():unlockInput( combobox )
		combobox._listbox:detach( combobox._cont )
		combobox._listbox = nil
	end
end

local function onItemSelected( combobox, old_idx, new_idx )
	combobox:selectIndex( new_idx )
	destroyDropDown( combobox )
end

local function createDropDown( combobox )
	if #combobox._items > 0 then
		combobox._listbox = combobox._screen:createFromSkin( combobox._comboSkin or DEFAULT_COMBOBOX_SKIN )

		local lb = combobox._listbox:findWidget("combo")
		lb.onItemSelected = util.makeDelegate( nil, onItemSelected, combobox )
		for i, str in ipairs( combobox._items ) do
			local item = combobox._listbox:findWidget("combo"):addItem( str )
			item:findWidget("txt"):setText( str )
		end
		-- Want to align the right end of the listbox's scrollbar with the right end of this combo box.
		local cw, ch = combobox:getSize()
		local lw, lh = lb:getSize()
		local scw, sch = lb:getScrollbar():getSize()
		combobox._listbox:setPosition( (cw - lw) / 2 - scw, -lb._h / 2 - combobox._h / 2 )
        combobox._listbox:setTopmost( true )
		combobox._listbox:attach( combobox, combobox._cont )
    	combobox._screen:refreshPriority()
		combobox._screen:lockInput( combobox )
	end
end

--------------------------------------------------------

local mui_combobox = class( mui_widget )

function mui_combobox:init( screen, def )
	mui_widget.init( self, def )

	self._screen = screen
	self._w, self._h = def.w, def.h
	self._wpx, self._hpx = def.wpx, def.hpx
	self._items = {}
    self._userData = {}
	self._arrowSize = def.arrow_size
    self._comboSkin = def.combo_skin
	
	self._bgImage = mui_texture( screen, { x = 0, y = 0, w = def.w, h = def.h, wpx = def.wpx, hpx = def.hpx, images = def.bg_image })
	if def.bg_color then
		self._bgImage:setColor( unpack( def.bg_color ))
	end

	self._arrowImg = mui_texture( screen, { x = 0, y = 0, xpx = def.wpx, ypx = def.ypx, w = def.w, h = def.h, wpx = def.wpx, hpx = def.hpx, noInput = true, images = def.arrow_image })
	
	-- xpx == wpx because we offset editBox based on proportions of the arrowImg size (which is in wpx coordinates)
	self._editBox = mui_text( screen, { x = 0, y = 0, xpx = def.wpx, ypx = def.hpx, w = def.w, h = def.h, wpx = def.wpx, hpx = def.hpx, text_style = def.text_style, canEdit = def.can_edit, halign = MOAITextBox.RIGHT_JUSTIFY, valign = MOAITextBox.CENTER_JUSTIFY } )
	
	self._btn = mui_button( { x = def.w/4, y = 0, w = def.w/2, xpx = def.wpx, ypx = def.ypx, h = def.h, wpx = def.wpx, hpx = def.hpx })
	self._btn:addEventHandler( self, mui_defs.EVENT_ALL )

	self._cont = mui_container( def )
	self._cont:addComponent( self._bgImage )
	self._cont:addComponent( self._arrowImg )
	self._cont:addComponent( self._editBox )
	self._cont:addComponent( self._btn )

	self._items = {}
end

function mui_combobox:setDisabled( isDisabled )
	self._btn:setDisabled( isDisabled )
	updateImageState( self )
	destroyDropDown( self )
end

function mui_combobox:getItemCount()
	return #self._items
end

function mui_combobox:clearItems()
	self._items, self._userData = {}, {}
	destroyDropDown( self )
end

function mui_combobox:selectIndex( idx )
	if idx and self._items[ idx ] then
		self:setText( self._items[ idx ] )
	end
end

function mui_combobox:addItem( text, userData )
	table.insert( self._items, tostring(text) )
    if userData then
        self._userData[ text ] = userData
    end
end

function mui_combobox:sortItems( fn )
    table.sort( self._items, fn )
end

function mui_combobox:getText()
	return self._editBox:getText()
end

function mui_combobox:getItem( idx )
	if idx and self._items[ idx ] then
		return self._items[ idx ]
	end
end

function mui_combobox:getUserData( text )
    text = text or self._editBox:getText()
    return self._userData[ text ]
end

function mui_combobox:getIndex()
	local text = self._editBox:getText()
	for i,v in ipairs( self._items ) do
		if v == text then
			return i
		end
	end
end

function mui_combobox:setText( str )
	if self._editBox:getText() ~= str then
		self._editBox:setText( str )
		if self.onTextChanged then
			util.callDelegate( self.onTextChanged, str, self )
		end
	end
end

function mui_combobox:setValue( value )
    self:setText( value )
end

function mui_combobox:getValue()
    return self:getText()
end

function mui_combobox:onActivate( screen )
	mui_widget.onActivate( self, screen )
	updateLayout( self, screen )
	updateImageState( self )

	if self._listbox then
		self._listbox:onActivate( screen )
	end
end

function mui_combobox:onDeactivate( screen )
	mui_widget.onDeactivate( self, screen )

	if self._listbox then
        destroyDropDown( self )
	end
end

function mui_combobox:updatePriority( priority )
	priority = mui_widget.updatePriority( self, priority )

	if self._listbox then
		priority = self._listbox:updatePriority( priority )
	end

	return priority
end

function mui_combobox:handleInputEvent( ev )
	local lb = self._listbox:findWidget("combo")
	-- ccc: TODO: if anyone sees this shitty if condition ive failed my refactoring duty.
	if not lb:inside( ev.x, ev.y ) then
		-- Outside combobox!
		if ev.eventType == mui_defs.EVENT_MouseDown then
			destroyDropDown( self )
		end
		return true
	else
		-- Inside
		return false
	end
end

function mui_combobox:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_OnLostLock then
		destroyDropDown( self )

	elseif ev.widget == self._btn then
		if ev.eventType == mui_defs.EVENT_ButtonClick then
			destroyDropDown( self )
			createDropDown( self )
			return true
		else
			updateImageState( self )
		end
	end
end


return mui_combobox

-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_text = require( "mui/widgets/mui_text" )
local mui_widget = require( "mui/widgets/mui_widget" )

--------------------------------------------------------

local mui_editbox = class( mui_widget )

function mui_editbox:init( screen, def )
	mui_widget.init( self, def )

	self._cont = mui_text( screen, def )
	self._cont:addEventHandler( self, mui_defs.EVENT_EditComplete )
end

function mui_editbox:setColor( r, g, b, a )
	self._cont:setColor( r, g, b, a )
end

function mui_editbox:setDisabled( isDisabled )
	if isDisabled and not self._isDisabled then
		self._isDisabled = true

		if self._cont:isEditing() then
			self._cont:finishEditing( self:getScreen() )
		end

	elseif not isDisabled and self._isDisabled then
		self._isDisabled = nil
	end
end

function mui_editbox:getText()
	return self._cont:getText()
end

function mui_editbox:setText( str )
	self._cont:setText( str )
end

function mui_editbox:startEditing( mode )
	self._cont:startEditing( self:getScreen(), mode )
end

function mui_editbox:finishEditing()
	self._cont:finishEditing( self:getScreen() )
end

function mui_editbox:setCursorRange( startIdx, endIdx )
	self._cont:setCursorRange( startIdx, endIdx )
end

function mui_editbox:setPasswordChar( pwchar )
	self._cont:setPasswordChar( pwchar )
end

function mui_editbox:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_EditComplete then
		if self.onEditComplete then
			util.callDelegate( self.onEditComplete, self._cont:getText(), ev.input )
		end
	end
end

return mui_editbox


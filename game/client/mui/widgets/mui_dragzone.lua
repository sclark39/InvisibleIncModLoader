-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_button = require( "mui/widgets/mui_button" )
local mui_container = require( "mui/widgets/mui_container" )
require( "class" )

--------------------------------------------------------
-- Local Functions

local mui_dragzone = class( mui_widget )

function mui_dragzone:init( screen, def )
	mui_widget.init( self, def )

	self._button = mui_button( util.inherit( def ){ x = 0, y = 0, draggable = true, skin_properties = 0 })
	self._button:addEventHandler( self, mui_defs.EVENT_ALL )

	self._cont = mui_container( def )
	self._cont:addComponent( self._button )
end

function mui_dragzone:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_DragStart and self.onDragStart then
		return util.callDelegate( self.onDragStart, self )
	elseif ev.eventType == mui_defs.EVENT_DragEnter and self.onDragEnter then
		return util.callDelegate( self.onDragEnter, ev.ie.screen:getDragDrop(), self )
	elseif ev.eventType == mui_defs.EVENT_DragLeave and self.onDragLeave then
		return util.callDelegate( self.onDragLeave, ev.ie.screen:getDragDrop(), self )
	elseif ev.eventType == mui_defs.EVENT_DragDrop and self.onDragDrop then
		return util.callDelegate( self.onDragDrop, ev.ie.screen:getDragDrop(), self )
	end
end

return mui_dragzone

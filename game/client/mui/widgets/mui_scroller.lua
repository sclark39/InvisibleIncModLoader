
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local mui_component = require( "mui/widgets/mui_component" )
local mui_defs = require( "mui/mui_defs" )

local mui_scroller = class( mui_component )

function mui_scroller:init( def )
	mui_component.init( self, MOAIProp2D.new(), def )
	self._prop:setBounds( -def.w/2, -def.h/2, 0, def.w/2, def.h/2, 0 )
end

function mui_scroller:handleInputEvent( ev )
	if ev.eventType == mui_defs.EVENT_MouseWheel then
		if ev.delta ~= 0 then
			self:dispatchEvent( { eventType = mui_defs.EVENT_Scroll, delta = ev.delta } )
		end
		return true
	end

	return false
end

return mui_scroller


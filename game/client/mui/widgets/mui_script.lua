-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_defs = require( "mui/mui_defs" )
local mui_component = require( "mui/widgets/mui_component" )
local mui_widget = require( "mui/widgets/mui_widget" )

--------------------------------------------------------

local mui_scriptcomponent = class( mui_component )

function mui_scriptcomponent:init( screen, def )
	local deck = MOAIScriptDeck.new()
	deck:setRect( -def.w/2, -def.h/2, def.w/2, def.h/2 )
	deck:setDrawCallback(
		function()
			local xmin, ymin, zmin, xmax, ymax, zmax = self._prop:getBounds()
			MOAIGfxDevice.setPenColor( 1, 0, 0, 1 )
			MOAIDraw.drawLine( xmin, ymin, xmax, ymax )
			MOAIDraw.drawLine( xmin, ymax, xmax, ymin )
		end )
	self._deck = deck

	local prop = MOAIProp2D.new()
	prop:setDeck( deck )
	
	mui_component.init( self, prop, def)
end

function mui_scriptcomponent:refreshProp()
	local x, y, w, h = self:calculateBounds()

	if self._deck then
		self._prop:setLoc( x, y )
		self._deck:setRect( -w/2, -h/2, w/2, h/2 )
	end
end

function mui_scriptcomponent:setDraw( fn )
	if fn then
		self._deck:setDrawCallback( fn )
	end
end
--------------------------------------------------------

local mui_script = class( mui_widget )

function mui_script:init( screen, def )
	mui_widget.init( self, def )
	self._cont = mui_scriptcomponent( screen, def )
end

function mui_script:setDraw( fn )
	self._cont:setDraw( fn )
end

return mui_script



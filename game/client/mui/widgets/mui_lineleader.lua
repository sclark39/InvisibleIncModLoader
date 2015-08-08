-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mathutil = require( "modules/mathutil" )
local mui_defs = require( "mui/mui_defs" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_texture = require( "mui/widgets/mui_texture" )
local mui_component = require( "mui/widgets/mui_component" )
local mui_container = require( "mui/widgets/mui_container" )

--------------------------------------------------------
--

local mui_leader_script = class( mui_component )

function mui_leader_script:init( screen, def )
	local deck = MOAIScriptDeck.new()
	deck:setDrawCallback(
		function( index, xOff, yOff, xFlip, yFlip )
			local t = 1.0
			if self._timer then
				t = self._timer:getTime() / self._timer:getPeriod()
			end
			MOAIGfxDevice.setPenColor( 0.8, 0.8, 0.8, 0.5 )
			local x0, y0 = mathutil.lerp( 0, self._x0, t/0.5 ), mathutil.lerp( 0, self._y0, t/0.5 )
			MOAIDraw.drawLine( 0, 0, x0, y0 )
			if t > 0.5 then
				local x1, y1 = mathutil.lerp( self._x0, self._x1, (t-0.5)/0.5 ), mathutil.lerp( self._y0, self._y1, (t-0.5)/0.5 )
				MOAIDraw.drawLine( self._x0, self._y0, x1, y1 )
			end
		end )
	self._deck = deck

	local prop = MOAIProp2D.new()
	prop:setDeck( deck )
	
	mui_component.init( self, prop, def)

	self._x0, self._y0 = 0.1, 0.1
	self._x1, self._y1 = 0.3, 0.1
end

function mui_leader_script:setTarget( x0, y0, x1, y1 )
	self._x0, self._y0 = x0, y0
	self._x1, self._y1 = x1, y1
end

function mui_leader_script:animate( duration, mode )
	if self._timer then
		self._timer:stop()
		self._timer = nil
	end

	if duration and mode then
		local timer = MOAITimer.new()
		timer:setSpan ( 0, duration )
		timer:setMode( mode )
		timer:start()
		self._timer = timer
	end
end

--------------------------------------------------------

local mui_lineleader = class( mui_widget )

function mui_lineleader:init( screen, def )
	mui_widget.init( self, def )

	self._targetImage = mui_texture( screen, util.inherit( def ) { x = 0, y = 0, noInput = true } )
	self._targetImage:setImageState( "target" )
	self._script = mui_leader_script( screen, { x = 0, y = 0, w = 0, h = 0, noInput = true } )

	self._cont = mui_container( def )
	self._cont:addComponent( self._script )
	self._cont:addComponent( self._targetImage )
end

function mui_lineleader:setTarget( x0, y0, x1, y1 )
	self._script:setTarget( x0, y0, x1, y1 )
end

function mui_lineleader:appear( duration )
	self._script:animate( duration, MOAITimer.NORMAL )
end

function mui_lineleader:disappear( duration )
	self._script:animate( duration, MOAITimer.REVERSE )
end

return mui_lineleader


-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_texture = require( "mui/widgets/mui_texture" )
local mui_container = require( "mui/widgets/mui_container" )
require( "class" )

--------------------------------------------------------

local mui_progressbar = class( mui_widget )

function mui_progressbar:init( screen, def )
	mui_widget.init( self, def )

	self._progress = def.value
	self._maxWidth = def.w - 2 * def.inset_size.w

	self._bgImg = mui_texture( screen, { x = 0, y = 0, w = def.w, wpx = def.wpx, h = def.h, hpx = def.hpx, images = def.bg_images })
	self._progressImg = mui_texture( screen, { x = 0, y = 0,
		xpx = def.wpx, ypx = def.hpx, wpx = def.wpx, hpx = def.hpx,
		w = def.w - 2 * def.inset_size.w, h = def.h - 2 * def.inset_size.h, images = def.progress_images } )

	self._cont = mui_container( def )
	self._cont:addComponent( self._bgImg )
	self._cont:addComponent( self._progressImg )

	self:setProgress( self._progress )
end

function mui_progressbar:setProgressColor( r, g, b, a )
	self._progressImg:setColor( r, g, b, a )
end

function mui_progressbar:setBGColor( r, g, b, a )
	self._bgImg:setColor( r, g, b, a )
end

function mui_progressbar:setProgress( val )
	self._progress = math.max( 0, math.min( 1.0, val ))
	self._progressImg:setUVRect( 0, 0, self._progress, 1 )
	self._progressImg:setSize( self._progress * self._maxWidth )
	local x, y = self._progressImg:getPosition()
	self._progressImg:setPosition( (-self._maxWidth + (self._progress * self._maxWidth)) / 2, y )
end

return mui_progressbar

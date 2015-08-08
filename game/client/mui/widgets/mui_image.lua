-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local array = require( "modules/array" )
local util = require( "modules/util" )
local cdefs = include( "client_defs" )
local mathutil = require( "modules/mathutil" )
local mui_widget = require( "mui/widgets/mui_widget" )
local mui_texture = require( "mui/widgets/mui_texture" )
require( "class" )

--------------------------------------------------------

local mui_image = class( mui_widget )

function mui_image:init( mui, def )
	mui_widget.init( self, def )

	self._cont = mui_texture( mui, def )

	if def.color then
		self:setColor( unpack( def.color ))
		self._color = { r = def.color[1], g = def.color[2], b = def.color[3], a = def.color[4] }
	else
		self._color = { r = 1, g = 1, b = 1, a = 1 }
	end
end

function mui_image:setSize( w, h )
	self._cont:setSize( w, h )
end

function mui_image:blinkWhiteTransition()
	self:setColor(1,1,1,1)
	self._thread = MOAICoroutine.new()
	self._thread:run( function() 
		local i = 0
		local t = 0
		local transitionTime = 0.6*cdefs.SECONDS
		while t <= 1 do
			i = i + 1
			t = i / transitionTime
			local c = {
				mathutil.inQuad(1, self._color.r,t), 
				mathutil.inQuad(1, self._color.g,t), 
				mathutil.inQuad(1, self._color.b,t), 
				mathutil.inQuad(1, self._color.a,t)
			}
			self:setColor( unpack(c) )
			coroutine.yield()
		end
	end )
	self._thread:resume()	
end

function mui_image:setColor( r, g, b, a )
	self._cont:setColor( r, g, b, a )
end

function mui_image:setDesat()
	self._cont:setShader( MOAIShaderMgr.DESATURATION_SHADER )
end

function mui_image:setScale( sx, sy )
	self._cont:setScale( sx, sy )
end

function mui_image:setRotation( angle )
    self._cont:setRotation( angle )
end


function mui_image:setImage( imgFilename )
	self._cont:setImage( imgFilename )
end

function mui_image:setImageIndex( idx )
	self._cont:setImageIndex( idx )
end

function mui_image:setImageAtIndex( imgFilename, idx )
	self._cont:setImageAtIndex( imgFilename, idx )
end

function mui_image:setImageState( name )
	self._cont:setImageState( name )
end

function mui_image:setTiles( ... )
	self._cont:setTiles( ... )
end

function mui_image:setScissor( ... )
	self._cont:setScissor( ... )
end

function mui_image:pixelate( blockSize )
	if blockSize then
		self._cont:setShader( MOAIShaderMgr.PIXELATE_SHADER )
		local uniforms = self._cont:getProp():getShaderUniforms()
		local x, h, w, h = self._cont:calculateBounds()
		local W, H = self:getScreen():getResolution()
		uniforms:setUniformVector2( "Size", w * W / blockSize, h * H / blockSize )
	else
		self._cont:setShader( nil )
	end
end

function mui_image:handleTooltip( ... )
    local tt = mui_widget.handleTooltip( self, ... )
    if not tt and not self._cont._noInput then
        return false -- if no tt, sink it here.
    end
    return tt
end

return mui_image


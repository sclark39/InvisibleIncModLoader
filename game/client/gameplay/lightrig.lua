----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local animmgr = include( "anim-manager" )
local geo_util = include( "geo_util" )
local cdefs = include( "client_defs" )

local MAX_RADIUS = cdefs.BOARD_TILE_SIZE

local function clamp( x, a, b )
	return (x <= a and a) or (x >= b and b) or x -- clamp between 0 and 1
end

local function FindSamples( samples, time )
	time = math.max( time, samples[2].time ) --we always want to return two samples, so we make sure that time is at least samples[2].time in scale
	for i,sample in ipairs(samples) do
		if time <= sample.time then
			return samples[i-1], sample
		end
	end
end
local function CatmullRomSampler( samples, time )
	local sa, sb = FindSamples( samples, time )
	local dt = sb.time - sa.time
	local t = ( time - sa.time ) / dt

	local h00 = 2*t^3 - 3*t^2 + 1
	local h10 = t^3 - 2*t^2 + t
	local h01 = -2*t^3 + 3*t^2
	local h11 = t^3 - t^2

	return {
		h00*sa.value[1] + h10*dt*sa.tangent[1] + h01*sb.value[1] + h11*dt*sb.tangent[1],
		h00*sa.value[2] + h10*dt*sa.tangent[2] + h01*sb.value[2] + h11*dt*sb.tangent[2],
		h00*sa.value[3] + h10*dt*sa.tangent[3] + h01*sb.value[3] + h11*dt*sb.tangent[3],
		h00*sa.value[4] + h10*dt*sa.tangent[4] + h01*sb.value[4] + h11*dt*sb.tangent[4]
	}
end
local function ColorSampler( samples, time )
	time = clamp( time, 0, 1 )
	local v = CatmullRomSampler( samples, time )
	v[1] = clamp( v[1], 0, 1 )
	v[2] = clamp( v[2], 0, 1 )
	v[3] = clamp( v[3], 0, 1 )
	v[4] = clamp( v[4], 0, 1 )
	return v
end

--------------------------------------------------------------- --]]

local lightrig = class()

function lightrig:init( boardRig, lightInfo )
	if lightInfo.vlen > 0 then
		self._layer = boardRig:getLayer("ceiling")
	else
		self._layer = boardRig:getLayer()
	end

	local function sampler(phi, r, p)
		local phi_c = ColorSampler( lightInfo.rotational_colours, phi/math.pi/2 )
		local rad_c = ColorSampler( lightInfo.radial_colours, r )
		return { r = phi_c[1] * rad_c[1], g = phi_c[2] * rad_c[2], b = phi_c[3] * rad_c[3], a = phi_c[4] * rad_c[4] }
	end

	--convert units from cell to world
	local radius = lightInfo.radius * cdefs.BOARD_TILE_SIZE
	local vlen = lightInfo.vlen * cdefs.BOARD_TILE_SIZE
	local voff = lightInfo.voff * cdefs.BOARD_TILE_SIZE - 0.001

	local msh = geo_util.generateConeMesh( radius, sampler, lightInfo.segcount, lightInfo.radcount, 0, vlen, voff )
	local prop = MOAIProp.new()
	prop:setDeck( msh )
	prop:setShader( MOAIShaderMgr.getShader( MOAIShaderMgr.KLEI_LIGHT_SHADER ) )
	prop:setLoc( boardRig:cellToWorld( lightInfo.x, lightInfo.y ) )
	prop:setPiv( 0, 0, voff )
	prop:setRot( lightInfo.phi, 0, lightInfo.theta )
	prop:setDepthTest( false )
	prop:setCullMode( MOAIProp.CULL_NONE )
	
	self._layer:insertProp ( prop )
	self._prop = prop
end

function lightrig:destroy()
	self._layer:removeProp( self._prop )
	self._prop = nil
end

-----------------------------------------------------
-- Interface functions

return lightrig

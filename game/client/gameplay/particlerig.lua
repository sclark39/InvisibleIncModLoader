----------------------------------------------------------------
-- Copyright (c) 2013 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local cdefs = include( "client_defs" )
include("class")

----------------------------------------------------------------
-- Example usage

--[[
makeParticleEffect( rig, 35, 37, 'smoke' )
local function makeParticleEffect( boardRig, x, y, effect )
	local effect = particlerig( boardRig, 'particles/' .. effect, x, y, 1, 1 )
	return effect
end
--]]

-----------------------------------------------------------------
--

local rig = class()

function rig:init( boardRig, effect_file, x, y, bounds_x, bounds_y )
	self._boardRig = boardRig
	self._effectFile = effect_file .. '/particle.pex'
	self._x = x
	self._y = y

	local plugin = MOAIParticlePexPlugin.load( self._effectFile )

	local maxParticles = plugin:getMaxParticles ()
	local blendsrc, blenddst = plugin:getBlendMode ()
	local minLifespan, maxLifespan = plugin:getLifespan ()
	local duration = plugin:getDuration ()
	local xMin, yMin, xMax, yMax = plugin:getRect ()

	local system = MOAIParticleSystem.new()
	system._duration = duration
	system._lifespan = maxLifespan
	system:reserveParticles( maxParticles, plugin:getSize() )
	system:reserveSprites( maxParticles )
	system:reserveStates( 1 )
	system:setBlendMode( blendsrc, blenddst )
	self._system = system

	local state = MOAIParticleState.new()
	state:setTerm( minLifespan, maxLifespan )
	state:setPlugin( plugin )
	self._state = state

	local emitter = MOAIParticleTimedEmitter.new()
	emitter:setLoc( 0, 0 )
	emitter:setSystem( system )
	emitter:setEmission( plugin:getEmission() )
	emitter:setFrequency( plugin:getFrequency() )
	emitter:setRect( xMin, yMin, xMax, yMax )
	self._emitter = emitter

	local deck = MOAIGfxQuad2D.new()
	deck:setTexture( plugin:getTextureName() )
	deck:setRect( -0.5, -0.5, 0.5, 0.5)

	local iso_dim = cdefs.BOARD_TILE_SIZE

	bounds_x = bounds_x or 1
	bounds_y = bounds_y or 1
	local bounds = { -bounds_x*iso_dim/2, -bounds_y*iso_dim/2, 0, bounds_x*iso_dim/2, bounds_y*iso_dim/2, -iso_dim }

	system:setDeck( deck )
	system:setState( 1, state )
	system:setBillboard( true )
	system:setLoc( boardRig:cellToWorld( x, y ) )
	system:setBounds( unpack( bounds ) )
	system:start()
	emitter:start()

	local layer = boardRig:getLayer( "main" )
	layer:insertProp( system )
	self._layer = layer
end

function rig:destroy()
	self._layer.removeProp( self._system )
end

function rig:getLocation( )
	return self._x, self._y
end

function rig:setLocation( x, y )
	if self._x ~= x or self._y ~= y then
		self._x = x
		self._y = y
		system:setLoc( self._boardRig:cellToWorld( x, y ) )
	end
end

return rig
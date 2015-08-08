----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local viz_thread = include( "gameplay/viz_thread" )
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

---------------------------------------------------------------

local blackout = class( viz_thread )

function blackout:init( boardrig, viz, duration, ... )
    viz_thread.init( self, viz, self.onResume )
	viz:registerHandler( simdefs.EV_FRAME_UPDATE, self )
    self.boardrig = boardrig
    self.duration = duration
    self.rigs = {...}

    local main = boardrig._layers["main"]
    local ceiling = boardrig._layers["ceiling"]

    for i, rig in ipairs( self.rigs ) do
        local rigProp = rig:getProp()
        main:removeProp( rigProp )
        ceiling:insertProp( rigProp )
        rigProp:setPriority( i + 10000 )
    end

    local timer = MOAITimer.new()
	timer:setSpan( duration / (60*2) )
	timer:setMode( MOAITimer.PING_PONG )
	timer:start()
	local uniformDriver = function( uniforms )
		local t = timer:getTime() / (duration / (60*2) )
		t = math.min(0.7,t*3)
		uniforms:setUniformFloat( "ease", t )
	end

    local uniforms = KLEIShaderUniforms.new()
    uniforms:setUniformDriver( uniformDriver )
        
    local dimmerProp = KLEIFullscreenProp.new()
    dimmerProp:setShader(  MOAIShaderMgr.getShader( MOAIShaderMgr.KLEI_POST_PROCESS_PASS_THROUGH_EASE ) )
    dimmerProp:setShaderUniforms( uniforms )
    dimmerProp:setTexture( "data/images/the_darkness.png" )
    dimmerProp:setBlendMode( MOAIProp.BLEND_NORMAL )
    dimmerProp:setPriority( 10000 )

    ceiling:insertProp( dimmerProp )

    self.dimmerProp = dimmerProp
end

function blackout:onStop()
    local main = self.boardrig._layers["main"]
    local ceiling = self.boardrig._layers["ceiling"]

    for i, rig in ipairs( self.rigs ) do
        local rigProp = rig:getProp()
        ceiling:removeProp( rigProp )
        main:insertProp( rigProp )
    end

    assert( self.dimmerProp )
    ceiling:removeProp( self.dimmerProp )
    self.dimmerProp = nil
end

function blackout:onResume( ev )
    while self.duration > 0 do
        self.duration = self.duration - 1
        coroutine.yield()
    end
end

return blackout

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

local flash_units = class( viz_thread )

function flash_units:init( boardrig, viz, rig, duration )
    viz_thread.init( self, viz, self.onResume )
	viz:registerHandler( simdefs.EV_FRAME_UPDATE, self )
    self.boardrig = boardrig
    self.rig = rig
    self.duration = duration

    --move rig from layers["main"] to layers["ceiling"]
    --increment usage_count and enable fullscreen darkening overlay if 1
    
    local rigProp = rig:getProp()
    local main = boardrig._layers["main"]
    local ceiling = boardrig._layers["ceiling"]

    main:removeProp( rigProp )
    ceiling:insertProp( rigProp )

    rigProp:setPriority( 110000 )

    if not boardrig._flashThreadCount or boardrig._flashThreadCount == 0 then
        boardrig._flashThreadCount = 1

        --print( "inserting dimmer" )

        --local bSoundPlayed = false
        local timer = MOAITimer.new()
	    timer:setSpan( duration / (60*2) )
	    timer:setMode( MOAITimer.PING_PONG )
	    timer:start()
	    local uniformDriver = function( uniforms )
		    local t = timer:getTime() / (duration / (60*2) )

		    t = math.min(0.7,t*3)
		    uniforms:setUniformFloat( "ease", t )
            --print('dimmer ease', t )
	    end

        local uniforms = KLEIShaderUniforms.new()
        uniforms:setUniformDriver( uniformDriver )
        
        local dimmerProp = KLEIFullscreenProp.new()
        dimmerProp:setShader(  MOAIShaderMgr.getShader( MOAIShaderMgr.KLEI_POST_PROCESS_PASS_THROUGH_EASE ) )
        dimmerProp:setShaderUniforms( uniforms )
        dimmerProp:setTexture( "data/images/the_darkness.png" )
        dimmerProp:setBlendMode( MOAIProp.BLEND_NORMAL )
        dimmerProp:setPriority( 100000 )

        ceiling:insertProp( dimmerProp )

        boardrig._dimmerProp = dimmerProp
    else
        boardrig._flashThreadCount = boardrig._flashThreadCount + 1
    end
end

function flash_units:onStop()
    self.rig:refreshRenderFilter()

    --move rig from layers["ceiling"] to layers["main"]
    --decrement usage_count and disable fullscreen darkening overlay if 0

    local rigProp = self.rig:getProp()
    local main = self.boardrig._layers["main"]
    local ceiling = self.boardrig._layers["ceiling"]

    ceiling:removeProp( rigProp )
    main:insertProp( rigProp )

    local count = self.boardrig._flashThreadCount - 1
    self.boardrig._flashThreadCount = count
    if count <= 0 then
        --print( "deleting dimmer" )
        local dimmerProp = self.boardrig._dimmerProp
        ceiling:removeProp( dimmerProp )
        self.boardrig._dimmerProp = nil
    end
end

function flash_units:onResume( ev )
    while self.duration > 0 do
	    if self.duration % 20 == 0 then
	        self.rig:getProp():setRenderFilter( cdefs.RENDER_FILTERS["focus_highlite"] )
	    elseif self.duration % 10 == 0 then
	        self.rig:refreshRenderFilter()
	    end
        self.duration = self.duration - 1
        coroutine.yield()
    end
end

return flash_units

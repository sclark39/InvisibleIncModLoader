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

--------------------------------------------------------------------------
-- Agent teleport, used when entering the level and leaving the level.

local teleport = class( viz_thread )

function teleport:init( boardRig, ev )
    self.boardRig = boardRig
    self.ev = ev
    self.fx = {}

   if not self.ev.eventData.warpOut then
    	for i, unit in ipairs(self.ev.eventData.units) do
    	    local rig =  self.boardRig:getUnitRig(unit:getID())
            rig:setHidden( true )
    	end
   end 

    viz_thread.init( self, ev.viz, self.onResume )
	ev.viz:registerHandler( simdefs.EV_FRAME_UPDATE, self )
end

function teleport:onStop()
    local fxmgr = self.boardRig._game.fxmgr
    for i, fx in ipairs(self.fx) do
        fxmgr:removeFx( fx )
    end
    for index, unit in ipairs( self.ev.eventData.units ) do
        MOAIFmodDesigner.stopSound( "teleport_loop"..index )
        self.boardRig:getUnitRig( unit:getID() ):setHidden( false )
    end
end

function teleport:onResume( ev )

    local sounds = {}
    if self.ev.eventData.warpOut then
      sounds.loop = "SpySociety/Actions/Teleport_sparks"
      sounds.strike = "SpySociety/Actions/Teleport_strike"
    else
      sounds.loop = "SpySociety/Actions/Teleport_sparks_inbound"
      sounds.strike = "SpySociety/Actions/Teleport_strike_inbound"      
    end

    local i, index = 30, 0
    local fxmgr = self.boardRig._game.fxmgr
    while #self.ev.eventData.units ~= index do
        if i == 30 then
            i, index = 0, index + 1
            local unit = self.ev.eventData.units[index]
            local x0, y0 = unit:getLocation()
            local wx, wy = self.boardRig:cellToWorld( unit:getLocation() )
            local rig =  self.boardRig:getUnitRig(unit:getID())

            MOAIFmodDesigner.playSound( sounds.loop, "teleport_loop"..index, nil, {x0, y0, 0}, nil )

	        local fx = fxmgr:addAnimFx( { kanim = "fx/teleport_fx", symbol = "effect", anim = "in", x = wx, y = wy, facingMask = KLEIAnim.FACING_W } )
            fx.onFinished = function( anim )
                array.removeElement( self.fx, fx )
                MOAIFmodDesigner.playSound( sounds.strike, nil, nil, {x0, y0, 0}, nil )
  			    rig:setHidden( self.ev.eventData.warpOut )
                fxmgr:addAnimFx( { kanim = "fx/teleport_fx", symbol = "effect", anim = "out", x = wx, y = wy, facingMask = KLEIAnim.FACING_W } )
            end
            table.insert( self.fx, fx )
	   end
    if i % 2 == 0 then
        coroutine.yield()
    end
    i = i + 1
	end	
	self:waitFrames( 90 )
end


return teleport
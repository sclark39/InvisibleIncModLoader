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

local blink_rewind = class( viz_thread )

function blink_rewind:init( hud, viz )

    self.hud = hud
    viz_thread.init( self, viz, self.onResume )
    viz:registerHandler( simdefs.EV_FRAME_UPDATE, self )
end

function blink_rewind:onStop()
    if self.widget then
        self.widget:blink()
    end
end

function blink_rewind:onResume( ev )
    self.widget = self.hud._screen:findWidget("rewindBtn")
    self.widget:setVisible( true )
    self.widget:blink(0.2, 2, 2)

    self:waitFrames( 6*cdefs.SECONDS ) 

    self.widget:blink()
end


return blink_rewind
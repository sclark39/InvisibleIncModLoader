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

-----------------------------------------------------
-- Path viz non-blocking reveal viz thread.
-- Reveals path over time when it gets observed.

local reveal_path = class( viz_thread )

function reveal_path:init( boardRig, unitID, ev )
    self.boardRig = boardRig
    self.pathRig = boardRig:getPathRig()
    self.ev = ev
    self.unitID = unitID
    self.maxMP = 12

    viz_thread.init( self, ev.viz, self.onResume )
	ev.viz:registerHandler( simdefs.EV_FRAME_UPDATE, self )
    self:unblock()
end

function reveal_path:onStop()
    -- Stoppin: instantly reveal the rest of the path
    self.boardRig:getPathRig():regeneratePath(self.unitID)
    local unitRig = self.boardRig:getUnitRig(self.unitID)
    if unitRig then
        unitRig:refreshInterest()
    end
end

function reveal_path:onResume( ev )
    for i = 0, self.maxMP do
	    self.boardRig:getPathRig():regeneratePath(self.unitID, i)
        coroutine.yield()
		self:waitFrames( 10 )
	end
    local unitRig = self.boardRig:getUnitRig(self.unitID)
    if unitRig then
        unitRig:refreshInterest()
    end
end

return reveal_path

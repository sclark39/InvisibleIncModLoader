----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local animmgr = include( "anim-manager" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local unitrig = include( "gameplay/unitrig" )

-----------------------------------------------------------------------------------
-- Local

local simdefs = nil -- Lazy initialized after the sim is mounted.
local simquery = nil -- Lazy initialized after the sim is mounted.

-------------------------------------------------------------

local corpserig = class( unitrig.rig )

function corpserig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )
	self:setCurrentAnim( "dead" )
	self:setPlayMode( KLEIAnim.ONCE )
	self._prop:setFrame( self._prop:getFrameCount() - 1 )	
end

return
{
	rig = corpserig,
}


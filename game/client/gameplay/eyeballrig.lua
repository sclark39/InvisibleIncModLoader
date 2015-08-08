----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

-----------------------------------------------------------------------------------
-- Local
-------------------------------------------------------------

local eyeballrig = class()

function eyeballrig:init( boardRig, unit )
	self._boardRig = boardRig
	self._unitID = unit:getID()
end

function eyeballrig:getUnit()
	return self._boardRig:getLastKnownUnit( self._unitID )
end

function eyeballrig:onSimEvent( ev, eventType, eventData )
end

function eyeballrig:destroy()
	self._boardRig:refreshLOSCaster( self._unitID )
end

function eyeballrig:refresh()
	self._boardRig:refreshLOSCaster( self._unitID )
end

return
{
	rig = eyeballrig,
}


----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local animmgr = include( "anim-manager" )
local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local binops = include( "modules/binary_ops" )
local unitrig = include( "gameplay/unitrig" )
include("class")

-----------------------------------------------------------------------------------
-- Local

local simdefs = nil -- Lazy initialized after the sim is mounted.
local simquery = nil -- Lazy initialized after the sim is mounted.

-------------------------------------------------------------

local idle_state = class( unitrig.base_state )

function idle_state:init( rig )
	unitrig.base_state.init( self, rig, "idle_state" )
end

function idle_state:onEnter()
	local unit = self._rig:getUnit()
	local state = "untie_idle"

	self._rig:setCurrentAnim( state )
end



local untie_state = class( unitrig.base_state )

function untie_state:init( rig )
	unitrig.base_state.init( self, rig, "untie_state" )
end

function untie_state:onEnter()
	local sounds = {
		{sound="SpySociety/Movement/foley_suit/getup",soundFrames=1},
		{sound="SpySociety/Actions/hostage/chair_move",soundFrames=2},
	}

	self:waitForAnim( "untie", nil, nil, sounds )
end



local hostagerig = class( unitrig.rig )

function hostagerig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )

	self._simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	self._idleState = idle_state( self )
	self:transitionUnitState( self._idleState )	
end

function hostagerig:onSimEvent( ev, eventType, eventData )

	self:_base().onSimEvent( self, ev, eventType, eventData )

	if eventType == self._simdefs.EV_UNIT_UNTIE then		
		self:transitionUnitState( self._untieState )
	end
end

function hostagerig:refresh()
	self:transitionUnitState( nil )

	self._idleState = idle_state( self )	
	self._untieState = untie_state( self )	
	self:transitionUnitState( self._idleState )
	self:_base().refresh( self )


end

return
{
	rig = hostagerig,
}


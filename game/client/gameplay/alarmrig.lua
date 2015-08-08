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
	unitrig.base_state.init( self, rig, "idle" )
end

function idle_state:onEnter()
	self._rig._prop:setCurrentAnim( "idle" )
end

local alarmrig = class( unitrig.rig )

function alarmrig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )

	simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	self._idleState = idle_state( self )
	self:transitionUnitState( self._idleState )

	self._prop:setSymbolVisibility( "light", true )		
	self._prop:setSymbolVisibility( "alarm", false )	
	
end

function alarmrig:onSimEvent( ev, eventType, eventData )
	self:_base().onSimEvent( self, ev, eventType, eventData )
	
	if eventType == simdefs.EV_UNIT_REFRESH or eventType == simdefs.EV_UNIT_WARPED then
		self:refresh()
	end
end

function alarmrig:refresh()
	local unit = self:getUnit()
	unitrig.rig.refresh(self)

	if unit:getTraits().alarmOn == true then
		self._prop:setSymbolVisibility( "alarm", true )	
	else
		self._prop:setSymbolVisibility( "alarm", false )
	end		

end


return
{
	rig = alarmrig,
}


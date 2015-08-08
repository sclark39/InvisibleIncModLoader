----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local unitrig = include( "gameplay/unitrig" )
include("class")


local simdefs = nil -- Lazy initialized after the sim is mounted.
local simquery = nil -- Lazy initialized after the sim is mounted.

-----------------------------------------------------------------------------------
-- Local

local idle_state = class( unitrig.base_state )

function idle_state:init( rig )
	unitrig.base_state.init( self, rig, "idle" )

end


function idle_state:onEnter()		

	self._rig:setCurrentAnim( "idle" )
end

function idle_state:onExit()

end

-------------------------------------------------------------

local traprig = class( unitrig.rig )

function traprig:init( boardRig, unit )

	simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	self:_base().init( self, boardRig, unit )
	self._idleState = idle_state( self )
	self:transitionUnitState( self._idleState )
end

function traprig:onUnitAlerted( viz, eventData )
	local unit = self:getUnit()
	local facing = self:getFacing()
	local x0,y0 = unit:getLocation()
	local wx, wy = self._boardRig:cellToWorld( x0, y0 )
	local orientation = self._boardRig._game:getCamera():getOrientation()
	self:setHidden(true)

	local linkedTrapRig = self._boardRig:getUnitRig(unit:getTraits().linkedTrap)
	if linkedTrapRig then
		linkedTrapRig:setHidden(true)
	end

	facing = (facing + orientation) % simdefs.DIR_MAX

	local setFacing = KLEIAnim.FACING_W
	if facing == 2 then
		setFacing = KLEIAnim.FACING_N
	elseif facing == 0 then
		setFacing = KLEIAnim.FACING_E
	elseif facing == 6 then
		setFacing = KLEIAnim.FACING_S
	end
		
	self._boardRig._game.fxmgr:addAnimFx( { kanim = "fx/door_shock_trap", symbol = "sock_trap", anim = "explode", x = wx, y = wy, facingMask = setFacing} ) 
end

function traprig:refresh()
	self:_base().refresh( self )	
end

return
{
	rig = traprig,
}


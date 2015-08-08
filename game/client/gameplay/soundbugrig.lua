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
local rig_util = include( "gameplay/rig_util" )
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
	local unit = self._rig:getUnit()

	local state = "idle"

	if unit:getTraits().mainframe_status =="off" then
		state = "idle_off"
	end

	self._rig:setCurrentAnim( state )
end

-------------------------------------------------------------

local soundbugrig = class( unitrig.rig )

function soundbugrig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )

	simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	self._idleState = idle_state( self )	
	self:transitionUnitState( self._idleState )

	self._HUDalarm = self:createHUDProp("kanim_soundbug_overlay_alarm", "character", "alarm", boardRig:getLayer("ceiling"), self._prop )
	self._HUDalarm:setSymbolModulate("cicrcle_wave",1, 0, 0, 1 )
	self._HUDalarm:setSymbolModulate("line_1",1, 0, 0, 1 )
	self._HUDalarm:setSymbolModulate("ring",1, 0, 0, 1 )
	self._HUDalarm:setSymbolModulate("attention_ring",1, 0, 0, 1 )
	
	self._prop:setSymbolVisibility( "red", "teal", "waves_red", false )

	self._HUDalarm:setVisible(false)
end

function soundbugrig:destroy()
	self:_base().destroy( self )
	self._boardRig:getLayer("ceiling"):removeProp(self._HUDalarm )
end

function soundbugrig:onUnitAlerted( viz, eventData )
	viz:spawnViz( function( thread )
		thread:unblock()
		self:refresh()
		local unit = self:getUnit()
		self._HUDalarm:setVisible(true)
		rig_util.waitForAnim( self._HUDalarm, "alarm" )
		self._HUDalarm:setPlayMode( KLEIAnim.LOOP )
		self._HUDalarm:setCurrentAnim( "alarm_loop" )
	end )
end


function soundbugrig:refresh()
	self:transitionUnitState( nil )
	self:transitionUnitState( self._idleState )
	self:_base().refresh( self )

	if self._boardRig:getSim():getUnit(self._unitID)._triggered then
		self._HUDalarm:setVisible(false)
	end
	

	local unit = self._boardRig:getLastKnownUnit( self._unitID )
	local playerOwner = unit:getPlayerOwner()

	if unit:getTraits().mainframe_status == "off" then
		if self._HUDIce then
			self._HUDIce:setVisible(false)
		end
		self._prop:setSymbolVisibility( "red", "waves_red", "ring_red", "ambientfx", "teal", "waves_teal", "1_teal", "ring", false )
	else
		if playerOwner == nil or playerOwner:isNPC() then		
			self._prop:setSymbolVisibility( "red", "waves_red", "ring_red", true );
			self._prop:setSymbolVisibility( "teal", "waves_teal", "1_teal", "ring", false )
		else
			self._prop:setSymbolVisibility( "red", "waves_red", "ring_red", false );
			self._prop:setSymbolVisibility( "teal", "waves_teal", "1_teal", "ring", true )
		end	
	end	
end

return
{
	rig = soundbugrig,
}


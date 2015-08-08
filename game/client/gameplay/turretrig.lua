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
	if self._rig:getUnit():getTraits().dead then
		self._rig:setCurrentAnim( "dead" )
	else
		self._rig:setCurrentAnim( "idle" )
	end
end

function idle_state:onSimEvent( ev, eventType, eventData )
	if eventType == simdefs.EV_UNIT_START_SHOOTING then
		local x0,y0 = self._rig:getUnit():getLocation()
		self._rig:playSound( "SpySociety/Objects/turret/gunturret_arm" )
		self:waitForAnim( "shoot_pre")

	elseif eventType == simdefs.EV_UNIT_SHOT then

		local oldFacing = self._rig:getFacing()
		if self._rig._boardRig:canPlayerSeeUnit( self._rig:getUnit() ) then
			local targetFacing = simquery.getDirectionFromDelta( eventData.x1 - eventData.x0, eventData.y1 - eventData.y0 )
			self._rig:refreshLocation( targetFacing )
		end

		local branch = nil
		if eventData.dmgt.shots > 1 then
			branch = 2
		end
		local shotAnim = 1

		for shotNum = 1, eventData.dmgt.shots do
			self._rig:playSound( eventData.dmgt.sound )
 		
			if shotNum > 1 then
				shotAnim = math.ceil( math.random() *3) 
			end

			self._rig:setCurrentAnim( "shoot", self._rig:getFacing() )
			self._rig._prop:setFrame( 0 )
			self:waitForAnim( "shoot", nil, branch)
		end

		if self._rig._boardRig:canPlayerSeeUnit( self._rig:getUnit() ) then
			self._rig:refreshLocation( oldFacing )
		end
 		
	elseif eventType == simdefs.EV_UNIT_DEATH then
 		self:waitForAnim( "death")
		self._rig:transitionUnitState( self._deadState )

	elseif eventType == simdefs.EV_UNIT_STOP_SHOOTING then
		self._rig:setCurrentAnim( "idle" )
	end	
end

-------------------------------------------------------------

local closed_state = class( unitrig.base_state )

function closed_state:init( rig )
	unitrig.base_state.init( self, rig, "idle" )
end

function closed_state:onEnter()
	self._rig:setCurrentAnim( "idle" )
end

-------------------------------------------------------------

local dead_state = class( unitrig.base_state )

function dead_state:init( rig )
	unitrig.base_state.init( self, rig, "dead" )
end

function dead_state:onEnter()	
	self._rig:setCurrentAnim( "dead" )
end


-------------------------------------------------------------

local turretrig = class( unitrig.rig )

function turretrig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )

	simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	self._idleState = idle_state( self )
	self._closedState = closed_state( self )
	self._deadState = dead_state( self )
	self:transitionUnitState( self._idleState )
	self._prop:setSymbolVisibility( "teal", false )	
	self._prop:setSymbolVisibility( "red", false )	


	self._HUDscan = self:createHUDProp("kanim_hud_turret_ol", "turret_ol", "idle_2", boardRig:getLayer("ceiling"), self._prop )
	self._HUDscan:setVisible(false)	
end

function turretrig:destroy()
	self:_base().destroy( self )
	self._boardRig:getLayer("ceiling"):removeProp( self._HUDscan )
end

function turretrig:refresh()
	self:transitionUnitState( nil )
	
	self:_base().refresh( self )

	local unit = self._boardRig:getLastKnownUnit( self._unitID )
	local playerOwner = unit:getPlayerOwner()

	self:refreshSpotSound()


		local gfxOptions = self._boardRig._game:getGfxOptions()
		
		local render_filter = 'default'
		if gfxOptions.bMainframeMode or gfxOptions.bTacticalView then
			local unit = self:getUnit()
			local playerOwner = unit:getPlayerOwner()

			if unit:getTraits().mainframe_status ~= "active" then
				render_filter = 'mainframe_fused'
			elseif playerOwner == nil or playerOwner:isNPC() then
				render_filter = 'mainframe_npc'
			end
		end

		self._prop:setRenderFilter( cdefs.RENDER_FILTERS[render_filter] )


	if unit:getTraits().mainframe_status ~= "active" then
		self._prop:setSymbolVisibility( "red", false )
		self._prop:setSymbolVisibility( "teal", false )
	elseif playerOwner == nil or playerOwner:isNPC() then		
		self._prop:setSymbolVisibility( "red", true )
		self._prop:setSymbolVisibility( "teal", false )
	else
		self._prop:setSymbolVisibility( "red", false )
		self._prop:setSymbolVisibility( "teal", true )
	end			

	self:transitionUnitState( self._idleState )


	if  unit:isAiming() then

		if playerOwner == nil or playerOwner:isNPC() then		
			self._HUDscan:setSymbolModulate("camera_ol1",1, 0.5, 0.5, 1 )
			self._HUDscan:setSymbolModulate("camera_ol_line",1, 0, 0, 1 ) 
		else
			self._HUDscan:setSymbolModulate("camera_ol1",0.5, 1, 1, 1 )
			self._HUDscan:setSymbolModulate("camera_ol_line",0, 1, 1, 1 )
		end	

		local orientation = self._boardRig._game:getCamera():getOrientation()* 2
		local facing = unit:getFacing() - orientation 
		if facing < 0 then 
			facing = facing - 8
		end
		self._HUDscan:setVisible(true)

		self._HUDscan:setCurrentAnim("idle_"..facing)
	else 

		if self._spotSound then
			self:refreshSpotSound(true)
		end
		self._HUDscan:setVisible(false)
	end

end


return
{
	rig = turretrig,
}


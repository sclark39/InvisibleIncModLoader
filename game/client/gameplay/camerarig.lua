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
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )

-----------------------------------------------------------------------------------
-- Rig for security cams.

local camerarig = class( unitrig.rig )

function camerarig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )

	simdefs = boardRig:getSim():getDefs()
	simquery = boardRig:getSim():getQuery()

	self._HUDscan = self:createHUDProp("kanim_hud_fx", "camera_ol", "idle_2", boardRig:getLayer("ceiling"), self._prop )
	self._HUDalarm = self:createHUDProp("kanim_camera_overlay_alarm", "alarm_light", "alarm", boardRig:getLayer("ceiling"), self._prop )
	self._HUDalarm:setSymbolModulate("alarm_light_1",1, 0, 0, 1 )
	self._HUDalarm:setSymbolModulate("alarm_light_cone",1, 0, 0, 1 )
	self._HUDalarm:setVisible(false)
	self._HUDscan:setVisible(true)

	self._HUDthought = self:createHUDProp("kanim_hud_agent_hud", "record", "recording", boardRig:getLayer("ceiling"), self._prop )	
end

function camerarig:destroy()
	self:_base().destroy( self )
	self._boardRig:getLayer("ceiling"):removeProp(self._HUDthought )
	self._boardRig:getLayer("ceiling"):removeProp(self._HUDalarm )
	self._boardRig:getLayer("ceiling"):removeProp(self._HUDscan )
end

function camerarig:onUnitAlerted( viz, eventData )
	viz:spawnViz( function( thread, eventData )
		thread:unblock()
		local unit = self:getUnit()
		self._boardRig._game:cameraPanToCell( unit:getLocation() )

		self._HUDthought:setCurrentAnim("alert")

		self._HUDthought:setListener( KLEIAnim.EVENT_ANIM_END,			
			function( anim, animname )
				if animname == "alert" then
					anim:setCurrentAnim("recording")
				end
			end )			
		
		self._HUDalarm:setVisible(true)
		self._boardRig:wait( 60 )
		self._HUDalarm:setVisible(false)
	end )
end

function camerarig:onSimEvent( ev, eventType, eventData )
	unitrig.rig.onSimEvent( self, ev, eventType, eventData )
	
	if eventType == simdefs.EV_UNIT_DEATH then
		ev.thread:unblock()
		self:waitForAnim( "death" )
		self:refresh()
	end
end

function camerarig:refresh()
	self:_base().refresh( self )

	local unit = self:getUnit()
	local playerOwner = unit:getPlayerOwner()

 	if unit:getTraits().dead then
 		self:setCurrentAnim( "dead" )
 	else
		if unit:getTraits().mainframe_status == "off" then
	    	self:setCurrentAnim( "idle_off" )
	    else
	    	self:setCurrentAnim( "idle" )
		end
 	end

	self._HUDthought:setVisible(false)
	self._HUDalarm:setVisible(false)

	if unit:getTraits().mainframe_status ~= "active" then
		if self._HUDIce then
			self._HUDIce:setVisible(false)
		end			
		self._prop:setSymbolVisibility( "red", "teal", false )
		self._HUDscan:setVisible( false )

		if (unit:getTraits().mainframe_booting or 0) > 0 then
			self._HUDalarm:setVisible(true)
			if playerOwner and not playerOwner:isNPC() then		
				self._HUDalarm:setSymbolModulate("alarm_light_cone",0.5, 1, 1, 1 )
			else
				self._HUDalarm:setSymbolModulate("alarm_light_cone",1, 0, 0, 1 )
			end
		end

	else
		if playerOwner == nil or playerOwner:isNPC() then		
			self._prop:setSymbolVisibility( "red", true )
			self._prop:setSymbolVisibility( "teal", false )
			self._HUDscan:setSymbolModulate("camera_ol1",1, 0.5, 0.5, 1 )
			self._HUDscan:setSymbolModulate("camera_ol_line",1, 0, 0, 1 )
		else
			self._prop:setSymbolVisibility( "red", false )
			self._prop:setSymbolVisibility( "teal", true )
			self._HUDscan:setSymbolModulate("camera_ol1",0.5, 1, 1, 1 )
			self._HUDscan:setSymbolModulate("camera_ol_line",0, 1, 1, 1 )
		end	

        local orientation = self._boardRig._game:getCamera():getOrientation()* 2
		self._HUDscan:setVisible(true)
		self._HUDscan:setCurrentAnim("idle_".. (unit:getFacing() - orientation) % simdefs.DIR_MAX )

		if  unit:getTraits().tracker_alert == true then		
			self._HUDthought:setVisible(true)
		end		
	end	
end

return
{
	rig = camerarig,
}


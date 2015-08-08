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
local agentrig = include( "gameplay/agentrig" )
local coverrig = include( "gameplay/coverrig" )
local world_hud = include( "hud/hud-inworld" )
local flagui = include( "hud/flag_ui" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local rig_util = include( "gameplay/rig_util" )

-- dronerig
--------------------------------------------------------------------

local dronerig = class( agentrig.rig )

function dronerig:init( boardRig, unit )
	agentrig.rig.init( self, boardRig, unit )

	self._HUDscan = self:createHUDProp("kanim_hud_drone_scan", "character", "idle_0", boardRig:getLayer("ceiling"), self._prop )	
	self._HUDscan:setVisible(false)	
end

function dronerig:destroy()
	agentrig.rig.destroy( self )
	self._boardRig:getLayer("ceiling"):removeProp( self._HUDscan )
end

function dronerig:onSimEvent( ev, eventType, eventData )
	if eventType == simdefs.EV_UNIT_RELOADED then
		return true -- Drones don't do a reload sequence.
	elseif eventType == simdefs.EV_UNIT_LOOKAROUND then
		local x0, y0 = self._boardRig:cellToWorld(self:getUnit():getLocation() )
		if eventData.part == "scan" then
			if self:getUnit():getUnitData().sounds.scan then
				self:playSound(self:getUnit():getUnitData().sounds.scan)
			end

			self._boardRig._game.fxmgr:addAnimFx( { kanim="gui/hud_fx", symbol="wireless", anim="idle", x=x0, y=y0 } )
			
			local x1,y1 = self:getUnit():getLocation()
			self._boardRig:queFloatText( x1, y1,  STRINGS.UI.FLY_TXT.SCANNING )

			if eventData.cells then
				local color = {0.3,0.0,0.0,0.3}
				self._boardRig:hiliteCells(eventData.cells, color, 60)
			end
			rig_util.wait(30)
		end
		return true -- Drones don't do a lookaround.
	elseif eventType == simdefs.EV_UNIT_PEEK then
		return true -- Drones don't do a peek sequence.
	elseif eventType == simdefs.EV_UNIT_STOP_WALKING and self:getUnit():getTraits().camera_drone then
	
		if self:getUnit():getSounds().move_loop_param then
			MOAIFmodDesigner.setSoundProperty(self._spotSound, self:getUnit():getSounds().move_loop_param,0 )
		end			
		
		self:transitionUnitState( self._idleState )
		return true -- Caemera drones don`t stop walking
	elseif eventType == simdefs.EV_PULSE_SCAN then

            local cx, cy = self:getUnit():getLocation()
    		local x0, y0 = self._boardRig:cellToWorld( cx, cy )
			self._boardRig._game.fxmgr:addAnimFx( { kanim="gui/hud_fx", symbol="wireless", anim="idle", x=x0, y=y0 } )

			self._boardRig:queFloatText( cx, cy,  STRINGS.UI.FLY_TXT.PULSE_SCAN )

            local hilite_radius = include( "gameplay/hilite_radius" )
            local hilite = hilite_radius( cx, cy,  self:getUnit():getTraits().range )
            hilite:setRate(  0.1 * cdefs.SECONDS, 0.2 * cdefs.SECONDS )
            hilite:setCells( eventData.cells )
            hilite:setColor( { 0.75, 0.75, 0.75, 0.5 } )
            self._boardRig:hiliteRadius( hilite )
            --rig_util.wait(2 * cdefs.SECONDS)
            self:waitForAnim("scanning")
			ev.thread:unblock()

			
			
	
            self:refresh()

		return true
	end

	agentrig.rig.onSimEvent( self, ev, eventType, eventData )
end

function dronerig:refresh()
	agentrig.rig.refresh( self )

	local unit = self:getUnit()


	if unit:getTraits().scanSweeps then
		if not unit:getPlayerOwner():isPC()  then		
			self._prop:setSymbolModulate("scan",1, 0.5, 0.5, 1 )
			self._prop:setSymbolModulate("camera_ol_line",1, 0, 0, 1 )
			
		else
			self._prop:setSymbolModulate("scan",0.5, 1, 1, 1 )
			self._prop:setSymbolModulate("camera_ol_line",0, 1, 1, 1 )
		end			
	else
		self._prop:setSymbolModulate("scan",0.5, 1, 1, 0 )
		self._prop:setSymbolModulate("camera_ol_line",0, 1, 1, 0 )
	end

	if unit:isAiming() and not unit:getTraits().no_drone_scan_fx then 
		if  not unit:getPlayerOwner():isPC()  then				 
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
		self._HUDscan:setVisible(false)
	end

end

return
{
	rig = dronerig,
}


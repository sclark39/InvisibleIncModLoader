----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local mathutil = include( "modules/mathutil" )
local unitrig = include( "gameplay/unitrig" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local rig_util = include( "gameplay/rig_util" )

-----------------------------------------------------------------------------------
-- Local

local function checkForUnits(unit,cell)
	local units = {}
		for i,checkUnit in ipairs(cell.units) do
			if checkUnit ~= unit and checkUnit:getTraits().isAgent then
				return true
			end
		end
	return false
end


-------------------------------------------------------------

local grenaderig = class( unitrig.rig )

function grenaderig:init( boardRig, unit )
	self:_base().init( self, boardRig, unit )
end

function grenaderig:refresh()
    unitrig.rig.refresh( self )

	local unit = self:getUnit()
	if unit:getTraits().camera and unit:getTraits().deployed then
		self:setCurrentAnim("cam_idle")
	elseif unit:getTraits().cryBaby and unit:getTraits().deployed then
		self:setCurrentAnim("crybaby_idle")	
	elseif unit:getTraits().transporterBeacon and unit:getTraits().deployed then
		self:setCurrentAnim("beacon_idle")	
		self:setPlayMode( KLEIAnim.LOOP )
	elseif unit:getTraits().holoProjector and unit:getTraits().deployed then
		local sim = unit:getSim()
		local cell = sim:getCell( unit:getLocation() )
		if checkForUnits(unit,cell) then
			self:setCurrentAnim( "distrupt_loop" )		
		else
			self:setCurrentAnim( "idle_hologram" )		
		end
		self:setPlayMode( KLEIAnim.LOOP )
	elseif unit:getTraits().scan and unit:getTraits().deployed then
		self:setCurrentAnim("scanner_idle")
		self:setPlayMode( KLEIAnim.LOOP )
	elseif unit:getTraits().explodes and unit:getTraits().explodes > 0 and unit:getTraits().deployed then
		local sounds = {{event="beep", sound="SpySociety/Grenades/grenade_beep"} }
	  	self:setCurrentAnim("blink_red", nil, sounds)
	else
		self:setCurrentAnim( "idle" )
	end
end

function grenaderig:hiliteCells(cells)
	local unit = self:getUnit()
	local color = {0.3,0.0,0.0,0.3}
	if unit:isPC() then
		color = {0.0,0.0,0.3,0.3}
	end
	self._boardRig:hiliteCells(cells, color, 60)
end

function grenaderig:onSimEvent( ev, eventType, eventData )
	unitrig.rig.onSimEvent( self, ev, eventType, eventData )

	local unit = self:getUnit()
	if eventType == simdefs.EV_GRENADE_EXPLODE then

		if unit:getTraits().explodes and unit:getTraits().explodes > 0 then
			local sounds = {{event="beep", sound="SpySociety/Grenades/grenade_beep"}}
			self:setCurrentAnim("steady_red", nil, sounds)
			rig_util.wait(30)
		end

		if unit:getUnitData().sounds.explode then
			self:playSound(unit:getUnitData().sounds.explode)
		end

        if unit:getTraits().scan then
            local cx, cy = unit:getLocation()
    		local x0, y0 = self._boardRig:cellToWorld( cx, cy )
			self._boardRig._game.fxmgr:addAnimFx( { kanim="gui/hud_fx", symbol="wireless", anim="idle", x=x0, y=y0 } )

			self._boardRig:queFloatText( cx, cy,  STRINGS.UI.FLY_TXT.SCANNING )

            local hilite_radius = include( "gameplay/hilite_radius" )
            local hilite = hilite_radius( cx, cy, unit:getTraits().range )
            hilite:setRate(  0.1 * cdefs.SECONDS, 0.2 * cdefs.SECONDS )
            hilite:setCells( eventData.cells )
            hilite:setColor( { 0.75, 0.75, 0.75, 0.5 } )
            self._boardRig:hiliteRadius( hilite )
			ev.thread:unblock()

			self:waitForAnim("scanner_loop")
			self:waitForAnim("scanner_pst")
            self:refresh()
            
        else
    		local x0, y0 = self._boardRig:cellToWorld(unit:getLocation() )
			self._boardRig._game.fxmgr:addAnimFx( { kanim="fx/flashbang", symbol="effect", anim="idle", x=x0, y=y0 } )
			self:setHidden(true)
			self:transitionUnitState( self._idleState )
		end

	elseif eventType == simdefs.EV_UNIT_THROWN then
		self:setCurrentAnim( "thrown" )

		if self._HUDlocated then
			self._HUDlocated:setVisible(false)
		end

		local x1, y1 = self._boardRig:cellToWorld(eventData.x, eventData.y)
		rig_util.throwToLocation(self, x1, y1)
		local unit = self:getUnit()
		if unit:getSounds() and unit:getSounds().bounce then
			self:playSound(unit:getSounds().bounce)
		end

	elseif eventType == simdefs.EV_UNIT_REFRESH then
		if unit:getTraits().holoProjector and unit:getTraits().deployed then
			self:refresh()
		end

    elseif eventType == simdefs.EV_UNIT_ACTIVATE then
    	self:refresh(ev)
	    if unit:getSounds().activate then
            local x0, y0 = unit:getLocation()
    		MOAIFmodDesigner.playSound( unit:getSounds().activate, nil, nil, {x0, y0, 0}, nil )
	    end
	    if unit:getTraits().camera then
		    self:waitForAnim( "cam_deploy" )
	    elseif unit:getTraits().cryBaby then
		    self:waitForAnim( "crybaby_deploy" )		    
	    elseif unit:getTraits().transporterBeacon then
		    self:waitForAnim( "beacon_deploy" )		  
		    self:refresh()
	    elseif unit:getTraits().holoProjector then
		    self:waitForAnim( "deploy" )
	    elseif unit:getTraits().scan then
		    self:waitForAnim("scanner_deploy")
		else
  		  	self:setCurrentAnim("idle")
	    end

	    if unit:getTraits().explodes and unit:getTraits().explodes > 0 then
			self:hiliteCells(eventData.cells)
		end

	elseif eventType == simdefs.EV_UNIT_DEACTIVATE then
		self:setCurrentAnim("idle")
	    if unit:getSounds().deactivate then
            local x0, y0 = unit:getLocation()
    		MOAIFmodDesigner.playSound( unit:getSounds().deactivate, nil, nil, {x0, y0, 0}, nil )
	    end
	end
end

return
{
	rig = grenaderig,
}


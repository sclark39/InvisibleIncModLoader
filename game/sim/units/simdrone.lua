----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local unitdefs = include( "sim/unitdefs" )
local simunit = include( "sim/simunit" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local modifiers = include( "sim/modifiers" )
local mainframe = include( "sim/mainframe" )

-----------------------------------------------------
-- Interface functions

local simdrone = { ClassType = "simdrone" }

function simdrone:deactivate( sim )
	if not self:isDead() then
		self:setKO( sim, 2 )

		--Refresh drone ICE. No more free shut downs! 
		self:getTraits().mainframe_ice = self:getTraits().mainframe_iceMax

		local x1,y1 = self:getLocation()
		sim:dispatchEvent(simdefs.EV_UNIT_FLOAT_TXT, { unit = self , txt=STRINGS.UI.FLY_TXT.REBOOTING, sound = "SpySociety/Objects/drone/drone_mainfraimeshutdown", x=x1,y=y1,color={r=255/255,g=178/255,b=102/255,a=1}  } )	-- 
	end
end

function simdrone:processEMP(empTime, noEmpFX, noAttack)
	local EMP_FIREWALL_BREAK_STRENGTH = 2
	if self:getTraits().magnetic_reinforcement and self:getTraits().mainframe_ice > EMP_FIREWALL_BREAK_STRENGTH then
		
		empResisted = true
		local x1,y1 = self:getLocation()
		local sim = self._sim 
		mainframe.breakIce( sim, self, EMP_FIREWALL_BREAK_STRENGTH )
		self._sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.TOOLTIPS.MAGNETIC_REINFOREMENTS,x=x1,y=y1,color={r=255/255,g=255/255,b=255/255,a=1}} )

	elseif self:getTraits().empDeath and not noAttack then
		self._sim:dispatchEvent( simdefs.EV_UNIT_HIT, {unit = self, result = 0, crit = false, fx = "emp"} )			
		self:killUnit( self._sim )

	elseif self:getTraits().empKO or (self:getTraits().empDeath and noAttack) then
		--self._sim:dispatchEvent( simdefs.EV_UNIT_HIT, {unit = self, result = 0, crit = false, fx = "emp"} )
		local x0,y0 = self:getLocation()
		self._sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/HitResponse/hitby_distrupter_flesh", x=x0,y=y0} )
        self:setKO( self._sim, empTime, "emp" )
	end
end

function simdrone:takeControl( player )
    simunit.takeControl( self, player )

	if self:getBrain() then
		self:getBrain():onDespawned()
		self._brain = nil
	end
	self:getTraits().mp = self:getMPMax()
	self:getTraits().controlTimer = self:getTraits().controlTimerMax + (player:getTraits().controlTicks or 0)

    self:getModifiers():add( "LOSrange", "control", modifiers.SET, nil )
    self:getModifiers():add( "LOSarc", "control", modifiers.SET, math.pi * 2 )
    self:getModifiers():add( "LOSperipheralRange", "control", modifiers.SET, nil )
    self:getModifiers():add( "LOSperipheralArc", "control", modifiers.SET, nil )

    self:setAiming(false)
	self:getTraits().takenDrone = true
	self:getTraits().sneaking = true
	self:getTraits().walk = true
	self._sim:refreshUnitLOS( self )


	if self:getTraits().mainframe_suppress_rangeMax then
		if player:isPC() then
			self:getTraits().mainframe_suppress_range = 0
		else
			self:getTraits().mainframe_suppress_range = self:getTraits().mainframe_suppress_rangeMax
		end
	end

	self._sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )
end

function simdrone:loseControl( sim )
	if self:getPlayerOwner() == sim:getPC() then 
		local player = sim:getNPC()
		self:setPlayerOwner( player )
		if not self:getBrain() then
			self._brain = simfactory.createBrain(self:getUnitData().brain, sim, self)
			self:getBrain():onSpawned(sim, self)
		end
		player:returnToIdleSituation(self)

        self:getModifiers():remove( "control" )

		sim:refreshUnitLOS( self )
		self:getTraits().takenDrone = nil
		self:getTraits().sneaking = nil
		self:getTraits().walk = nil
		self:getTraits().mainframe_ice = self:getTraits().mainframe_iceMax

		self:deactivate( sim )

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )

	end
end

-----------------------------------------------------
-- Interface functions

local function createDrone( unitData, sim )
	return simunit.createUnit( unitData, sim, simdrone )
end

simfactory.register( createDrone )

return simdrone

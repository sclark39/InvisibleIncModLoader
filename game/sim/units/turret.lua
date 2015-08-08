----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local inventory = include( "sim/inventory" )
local simability = include( "sim/simability" )

-----------------------------------------------------
-- Local functions

local turret = { ClassType = "simturret" }

function turret:deactivate( sim )
	-- Deactivate the turret.  This should be safe to call even if the turret is already deactivated.
    if self:getTraits().mainframe_status == "active" then
	    self:getTraits().on = false
	    self:getTraits().mainframe_status = "inactive"
	    self:setAiming(false)
	    self:getTraits().isArmed = nil
	    self:getTraits().hasSight = nil
	    self:getSounds().spot = nil
	    sim:refreshUnitLOS(self)
	    sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self })

	    sim:removeTrigger( simdefs.TRG_START_TURN, self )
	    sim:removeTrigger( simdefs.TRG_OVERWATCH, self)
    end
end

function turret:activate( sim )
	-- activate the turret.  This should be safe to call even if the turret is already activated, or disabled.
	if self:getTraits().mainframe_status == "inactive" and not self:getTraits().dead then
		self:getTraits().on = true
		self:getTraits().mainframe_status = "active"	
		self:getTraits().isArmed = nil -- Must first trigger an overwatch to arm, once active.
		self:getTraits().hasSight = true
		sim:refreshUnitLOS( self )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self })

		sim:addTrigger( simdefs.TRG_START_TURN, self )
		sim:addTrigger( simdefs.TRG_OVERWATCH, self )
	end
end

function turret:armTurret( sim )
	assert( self:getTraits().on and self:getTraits().mainframe_status == "active" )

	local x0,y0 = self:getLocation()
	self:getTraits().isArmed = true
	self:getSounds().spot = simdefs.SOUNDPATH_TURRET_SCAN
	sim:emitSound( simdefs.SOUND_TURRET_LOAD, x0, y0, self)

	sim:dispatchEvent( simdefs.EV_UNIT_START_SHOOTING, {unitID= self:getID()} )
	sim:dispatchEvent( simdefs.EV_UNIT_STOP_SHOOTING, {unitID= self:getID()} )

	self:enterOverwatch( sim )
end

function turret:enterOverwatch( sim )
	assert( self:getTraits().on and self:getTraits().mainframe_status == "active" )
	assert( self:getTraits().isArmed )

	if not self:isAiming() and not self:getTraits().dead then
		local x0,y0 = self:getLocation()
		self:setAiming( true )
		sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt= STRINGS.UI.FLY_TXT.TURRET_OVERWATCH,x=x0,y=y0,color={r=1,g=1,b=1,a=1},sound="SpySociety/Objects/turret/gunturret_arm"} )
		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self })
	end
end

function turret:triggerOverwatch( sim, targetUnit )
	assert( self:getTraits().on and self:getTraits().mainframe_status == "active" )

	local userPlayer = self:getPlayerOwner()
	if(userPlayer == sim:getCurrentPlayer() or not simquery.isEnemyAgent( userPlayer, targetUnit )) then
		return -- Overwatch only triggers vs. enemy players while NOT on our turn.
	end
				
	if not sim:canUnitSeeUnit( self, targetUnit ) then	
		return -- Obviously the target must be in sight.
	end

	if not self:getTraits().isArmed then
		-- Not yet tripped -- we are now ARMED!
		targetUnit:interruptMove( sim )
		if targetUnit:getPlayerOwner() then
			targetUnit:getPlayerOwner():glimpseUnit( sim, self:getID() )
		end

		self:armTurret( sim )
	end
end

function turret:onWarp( sim, oldCell, cell )
	if cell and not oldCell then
		if self:getTraits().startOn then
			self:activate( sim )
		else
			self:deactivate( sim )
		end

	elseif oldCell and not cell then
		self:deactivate( sim ) -- Warping out.  Always deactivate.
	end
end 

function turret:killUnit( sim )
	self:deactivate( sim )
	self:getTraits().dead = true
	self:getTraits().mainframe_item = false
	self:getTraits().mainframe_ice = nil
	self:getTraits().magnetic_reinforcement = nil
	self:getTraits().mainframe_iceMax = nil
	local x1,y1 = self:getLocation()
	sim:emitSound( simdefs.SOUND_TURRET_DESTROYED, x1, y1, self )
	sim:dispatchEvent( simdefs.EV_UNIT_DEATH, { unit = self } )


end

function turret:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_START_TURN then
		if self:getTraits().isArmed and evData ~= self:getPlayerOwner() then
			self:enterOverwatch( sim )
		end

	elseif evType == simdefs.TRG_OVERWATCH then
		if evData then
			self:triggerOverwatch( sim, evData )
		end
	end
end

-----------------------------------------------------
-- Interface functions

local function createTurret( unitData, sim )
	return util.tmerge( simunit.createUnit( unitData, sim ), turret )
end

simfactory.register( createTurret )

return
{
	createTurret = createTurret,
}

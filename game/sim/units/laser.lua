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
local npc_abilities = include( "sim/abilities/npc_abilities" )

-----------------------------------------------------
-- Local functions

local function canTripLaser( unit )
    return simquery.isAgent( unit ) or unit:getTraits().iscorpse
end

-----------------------------------------------------
-- Laserbeam functions

local laserbeam = { ClassType = "laserbeam" }

function laserbeam:tripLaser( sim, x0, y0, unit )
	--simlog( "%s [%d] tripped by %s [%d] at <%d, %d>", self:getName(), self:getID(), unit:getName(), unit:getID(), x0, y0 )
	--print("TEST OWNER",unit:getPlayerOwner():isPC())

	local emitterUnit = sim:getUnit( self:getTraits().emitterID )

	if self:getTraits().koDamage and unit:getWounds() then
		sim:emitSound( simdefs.SOUND_HIT_LASERS_FLESH, x0, y0, unit)
		sim:damageUnit(unit, 0, self:getTraits().koDamage )
	end			

	if emitterUnit:getPlayerOwner() and emitterUnit:getPlayerOwner():isPC() then
		emitterUnit:getPlayerOwner():glimpseUnit( sim, unit:getID() )
	else

		if self:getTraits().tripsDaemon then
			sim:emitSound( simdefs.SOUND_HIT_LASERS_FLESH, x0, y0, unit)
	        local wt = util.weighted_list()
	        for abilityID, ability in pairs(npc_abilities) do
	            if ability.standardDaemon then
	                wt:addChoice( abilityID, 1 )
	            end
	        end
	        local daemon = wt:removeChoice( sim:nextRand( 1, wt:getTotalWeight() ))
	        sim:getNPC():addMainframeAbility(sim, daemon )
		end		

		if self:getTraits().isAlarm then
			sim:trackerAdvance( 1, STRINGS.UI.ALARM_LASER_SCAN )
		end
	end

	if self:getTraits().damage and unit:getWounds() then
		sim:emitSound( simdefs.SOUND_HIT_LASERS_FLESH, x0, y0, unit)
        sim:damageUnit( unit, self:getTraits().damage, nil, nil, self )
	end
end

function laserbeam:canControl( unit )
    local emitterUnit = self:getSim():getUnit( self:getTraits().emitterID )
    if emitterUnit then
        return emitterUnit:canControl( unit )
    end
    return false
end

function laserbeam:deactivate( sim )
    local emitterUnit = sim:getUnit( self:getTraits().emitterID )
    if emitterUnit then
        emitterUnit:deactivate( sim )
        -- laserbeam now despawned, do nothing else!
    end
end

-----------------------------------------------------
-- Local functions

-- like pairs() but returns k,v in order of lexographically sorted k for determinism
local function lasercells( sim, unit )
	local function iteratorFn( startCell, cell )
		if cell == nil then
			return startCell
		else
			local exit = cell.exits[ unit:getFacing() ]
			if simquery.isOpenExit( exit ) then
				return exit.cell
			else
				return nil
			end
		end
	end
	
	return iteratorFn, sim:getCell( unit:getLocation() ), nil
end

local function findLaserBeam( sim, cell, emitterID )
	if cell ~= nil then
		for _, cellUnit in ipairs( cell.units ) do
			if cellUnit:getTraits().emitterID == emitterID then
				return cellUnit
			end
		end
	end
	return nil
end

local laser_emitter = { ClassType = "laser_emitter" }


function laser_emitter:spawnPartnerEmitter( sim,cell )
	local newcell = nil
	local testcell = cell

	while not newcell do
		if testcell.exits[self:getFacing()] then
			testcell = testcell.exits[self:getFacing()].cell		
		else
			newcell = testcell			
		end
	end

	local spawnprop = self:getTraits().mainframe_spawnpartner
	

	local template = unitdefs.lookupTemplate( spawnprop )
	assert( template )
	local facing = self:getFacing()
	facing = facing+4
	if facing > 7 then 
		facing = facing - 8
	end
	local unitData = util.extend( template ) { facing = facing  }
	local partner = simfactory.createUnit( unitData, sim )

	partner:getTraits().hostID = self:getID()
	self:getTraits().partnerID = partner:getID()

	sim:spawnUnit( partner )
	sim:warpUnit( partner, newcell )
end

function laser_emitter:canActivate( sim )
	for cell in lasercells( sim, self ) do
		for _, cellUnit in ipairs( cell.units ) do
			if self:canControl( cellUnit ) then
				--simlog( "%d Not reactivating at <%d, %d> (%d, %d) due to %s", self:getID(), cell.x, cell.y, evData.from_cell.x, evData.from_cell.y, cellUnit:getName() )
                return false
			end
		end
	end
    
    return simunit.canActivate( self, sim )
end

function laser_emitter:isActive()
	return self:getTraits().mainframe_status == "active"
end

function laser_emitter:activate( sim )
	if  self:getTraits().mainframe_status == "inactive" then
		self:getTraits().mainframe_status = "active"
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_on" )
		           
		if self:getTraits().mainframe_spawnprop then
			local spawnprop = self:getTraits().mainframe_spawnprop 
            local tripUnits = {}

			for cell in lasercells( sim, self ) do
				local template = unitdefs.lookupTemplate( spawnprop )
				assert( template )
				local unitData = util.extend( template ) { facing = self:getFacing() }
				local laserbeam = simfactory.createUnit( unitData, sim )		

				table.insert( self._lasers, laserbeam )
				laserbeam:getTraits().emitterID = self:getID()
				sim:spawnUnit( laserbeam )
				sim:warpUnit( laserbeam, cell )


				-- See if this laser trips immediately.  Careful on iterating over cell units, as tripping a laser
				-- could do ANYTHING -- make sure we fully iterate the original set of units by managing a table copy.
				local cellUnits = util.tdupe(cell.units)
				while #cellUnits > 0 do
					local cellUnit = table.remove( cellUnits )
					if cellUnit ~= laserbeam and simquery.isAgent(cellUnit) then
                        table.insert( tripUnits, laserbeam )
                        table.insert( tripUnits, cellUnit )
					end
				end
			end

            if #tripUnits > 0 then
                while #tripUnits > 0 do
                    local cellUnit = table.remove( tripUnits )
                    local laserbeam = table.remove( tripUnits )
                    local cx, cy = cellUnit:getLocation()
                    assert( cx and cy and laserbeam , cellUnit:getName() )
                    laserbeam:tripLaser( sim, cx, cy, cellUnit )
                end

                if self:getTraits().empWhenTripped then
                    self:processEMP( self:getTraits().empWhenTripped )
                end
            end
		end

        local partner = sim:getUnit( self:getTraits().partnerID )
        if partner then
            partner:activate( sim )
        end
	end
end

function laser_emitter:deactivate( sim )
	if self:getTraits().mainframe_status == "active" then
		self:getTraits().mainframe_status = "inactive"
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_off" )

		local x, y = self:getLocation()

		for i,laser in ipairs(self._lasers) do
			local unitID = laser:getID()
			sim:warpUnit( laser, nil )
			sim:despawnUnit( laser )
		end

        local partner = sim:getUnit( self:getTraits().partnerID )
        if partner then
            partner:deactivate( sim )
        end

		self._lasers = {}
	end
end

function laser_emitter:onWarp( sim, oldcell, cell )
	if not oldcell and cell then
		sim:addTrigger( simdefs.TRG_UNIT_WARP, self )

		if self:getTraits().mainframe_spawnpartner then
			self:spawnPartnerEmitter(sim,cell)
		end

	elseif not cell and oldcell then
		sim:removeTrigger( simdefs.TRG_UNIT_WARP, self )
	end	

	if oldcell then
		self:deactivate( sim )
	end

	if cell and self:getTraits().startOn == true then
		self:activate( sim )
	end
end

function laser_emitter:canControl( unit )
    if canTripLaser( unit ) then
    	-- if you are not an enemy because of disguise, it doesn't work.
        if not simquery.isEnemyAgent( self:getPlayerOwner(), unit, true) then        	
           	return true
        end
        if unit:getTraits().movingBody and self:canControl( unit:getTraits().movingBody ) then
            return true
        end
    end
    return false
end

function laser_emitter:takeControl( player )
    simunit.takeControl( self, player )
    self:getTraits().empWhenTripped = 6
end

function laser_emitter:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_UNIT_WARP and evData.from_cell ~= evData.to_cell then
		if self:getTraits().mainframe_status == "active" then
			local laserBeam = findLaserBeam( sim, evData.to_cell, self:getID() )
			if laserBeam and canTripLaser( evData.unit ) then
				-- If it's an enemy warping into the laser, trip the laser effect.
				-- Otherwise, we shoudl deactivate ourselves if it's a friendly.
				if not laserBeam:canControl( evData.unit ) then
					laserBeam:tripLaser( sim, evData.to_cell.x, evData.to_cell.y, evData.unit )
                    if self:getTraits().empWhenTripped then
                        self:processEMP( self:getTraits().empWhenTripped )
                    end
                else
					self:deactivate( sim )
				end
			end

		elseif self:getTraits().mainframe_status == "inactive" and self:getPlayerOwner() == nil and self:canControl( evData.unit ) then
			-- If it's a friendly warping out of the laser range, may have to re-activate ourselves.
			local found = false
			for cell in lasercells( sim, self ) do
				if cell == evData.from_cell then
					found = true
				end
			end
			if found and self:canActivate( sim ) then
				self:activate( sim )
			end
		end
	end
end

-----------------------------------------------------
-- Interface functions

local function createLaserBeam( unitData, sim )
	local t = simunit.createUnit( unitData, sim )
	return util.tmerge( t, laserbeam )
end

local function createLaserEmitter( unitData, sim )
	local t = simunit.createUnit( unitData, sim )
	t._lasers = {}
	return util.tmerge( t, laser_emitter )
end

simfactory.register( createLaserEmitter )
simfactory.register( createLaserBeam )

return
{
	createLaserEmitter = createLaserEmitter
}

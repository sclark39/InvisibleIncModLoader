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

-----------------------------------------------------
-- Local functions

local simtrap = { ClassType = "simtrap" }

function simtrap:onWarp( sim, oldcell, cell )
	if oldcell == nil and cell ~= nil then
		sim:addTrigger( simdefs.TRG_UNIT_USEDOOR, self )

	elseif oldcell ~= nil and cell == nil then
        local exit = oldcell.exits[ self:getFacing() ]
        assert( exit.trapped )
        exit.trapped = nil

		sim:removeTrigger( simdefs.TRG_UNIT_USEDOOR, self )		
	end
end

function simtrap:performTrap( sim, cell, unit )
	-- Remove this trap and its partner.
	sim:emitSound( simdefs.SOUND_SHOCKTRAP, cell.x, cell.y, nil )	
    sim:dispatchEvent( simdefs.EV_CAM_PAN, { cell.x, cell.y } )	

	sim:startTrackerQueue(true)				
	sim:startDaemonQueue()			
	local x1, y1 = self:getLocation()
	sim:dispatchEvent( simdefs.EV_UNIT_ALERTED, { unitID = self:getID() } )

	local dmgt = {ko = true, damage = self:getTraits().stun}


	if self:getTraits().range then
		sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = x1, y = y1, range = self:getTraits().range} )
		local cells = simquery.fillCircle( sim, x1, y1, self:getTraits().range, 0)
        sim:dispatchEvent( simdefs.EV_KO_GROUP, true )

		for i, cell in ipairs(cells) do
			for i, cellUnit in ipairs( cell.units ) do
				if simquery.isEnemyAgent(self:getPlayerOwner(), cellUnit) and not cellUnit:isKO() then
					if cellUnit:getTraits().canKO then
				    	if sim:isVersion("0.17.5") then
							dmgt.damage = unit:processKOresist( dmgt.damage )
				    	end						
						sim:hitUnit( self, cellUnit, dmgt )
					elseif cellUnit:getTraits().isDrone and cellUnit.deactivate then
						cellUnit:deactivate(sim)
					end
				end
			end
		end

        if unit then
		    if unit:getTraits().canKO then

		    	-- Changes the way shocktraps do damage. No KO resistance will affect them.
		    	if sim:isVersion("0.17.5") then
					dmgt.damage = unit:processKOresist( dmgt.damage )
		    	end


			    sim:hitUnit( self, unit, dmgt )
		    elseif unit:getTraits().isDrone and unit.deactivate then
			    unit:deactivate(sim)
		    end
        end

        sim:dispatchEvent( simdefs.EV_KO_GROUP, false )

	elseif unit then
		if unit:getTraits().canKO then

		    	-- Changes the way shocktraps do damage. No KO resistance will affect them.
		    	if sim:isVersion("0.17.5") then
			    	dmgt.damage = unit:processKOresist( dmgt.damage )
		    	end

			sim:hitUnit( self, unit, dmgt )
		elseif unit:getTraits().empKO then
			unit:processEMP(dmgt.damage)
		end
	end

	local linkedTrap = sim:getUnit( self:getTraits().linkedTrap )
	local unitID, linkedUnitID = self:getID()
	sim:warpUnit( self, nil )
	if linkedTrap then
		linkedUnitID = linkedTrap:getID()
		sim:warpUnit( linkedTrap, nil )
	end

	if linkedTrap then
		sim:despawnUnit( linkedTrap )
	end
	sim:despawnUnit( self )

	--make sure all players glimpse to remove the ghosts
	for i,player in ipairs(sim:getPlayers()) do			
		player:glimpseUnit(sim, unitID)
		if linkedUnitID then
			player:glimpseUnit(sim, linkedUnitID)
		end
	end

	sim:startTrackerQueue(false)				
	sim:processDaemonQueue()			
end

function simtrap:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_UNIT_USEDOOR then
		local cell = sim:getCell( self:getLocation() )
		if evData.cell == cell or evData.tocell == cell then
			self:performTrap( sim, cell, evData.unit )
		end
	end
end

-----------------------------------------------------
-- Interface functions

local function applyToDoor( sim, cell, direction, unit, userUnit )
	assert( simquery.isDoorExit( cell.exits[ direction ] ))

    local player = userUnit:getPlayerOwner()
    local damage = unit:getTraits().stun
    local range = unit:getTraits().range
    local toCell = cell.exits[ direction ].cell
    local rdir = simquery.getReverseDirection( direction )

	-- Spawn trap on both sides of the door.
	local trap1 = simfactory.createUnit( unitdefs.prop_templates.trap_shock_door, sim )
	trap1:getTraits().stun = damage 
	trap1:getTraits().range = range 
	trap1:setFacing( direction )
	sim:spawnUnit( trap1 )
	sim:warpUnit( trap1, cell)
	trap1:setPlayerOwner(player)
	
	local trap2 = simfactory.createUnit( unitdefs.prop_templates.trap_shock_door, sim )
	trap2:getTraits().stun = damage 
	trap2:getTraits().range = range 
	trap2:setFacing( rdir )
	sim:spawnUnit( trap2 )
	sim:warpUnit( trap2, toCell )
	trap2:setPlayerOwner(player)

	trap1:getTraits().linkedTrap = trap2:getID()
	trap2:getTraits().linkedTrap = trap1:getID()

    cell.exits[ direction ].trapped = true
    toCell.exits[ rdir ].trapped = true
end


local function createTrap( unitData, sim )
	local t = simunit.createUnit( unitData, sim )
	return util.tmerge( t, simtrap )
end

simfactory.register( createTrap )

return
{
	applyToDoor = applyToDoor,
}



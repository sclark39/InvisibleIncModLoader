----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local mathutil = include( "modules/mathutil" )

-----------------------------------------------------
-- Local functions

local emp = { ClassType = "simemppack" }

function emp:detonate( sim )
	local x0,y0 = self:getLocation()

	if self:getTraits().flash_pack then
		local sim, player = self:getSim(), self:getPlayerOwner()

		sim:startTrackerQueue(true)				
		sim:startDaemonQueue()			
	    sim:dispatchEvent( simdefs.EV_KO_GROUP, true )
	    local cells = self:getExplodeCells()

		sim:dispatchEvent( simdefs.EV_FLASH_VIZ, {x = x0, y = y0, units = nil, range = self:getTraits().range} )

		for i, cell in ipairs(cells) do
			for i, cellUnit in ipairs( cell.units ) do
				if self:getTraits().baseDamage and simquery.isEnemyAgent( player, cellUnit) and not cellUnit:getTraits().isDrone then
					if self:getTraits().canSleep then

						local damage = self:getTraits().baseDamage
						damage = cellUnit:processKOresist( damage )
				   			
						cellUnit:setKO(sim, damage)
					else
						sim:damageUnit(cellUnit, self:getTraits().baseDamage)
					end
				end
			end
		end

	    sim:dispatchEvent( simdefs.EV_KO_GROUP, false )
		sim:startTrackerQueue(false)				
		sim:processDaemonQueue()	
		
	else
		
	    local units = self:getTargets( x0, y0 )

		sim:dispatchEvent( simdefs.EV_OVERLOAD_VIZ, {x = x0, y = y0, units = units, range = self:getTraits().range } )

	    for i, unit in ipairs(units) do
	        unit:processEMP( self:getTraits().emp_duration, true )
	    end
	end

	-- Destroy the DEVICE.
	sim:warpUnit( self, nil )
	sim:despawnUnit( self )
	sim:emitSound( simdefs.SOUND_SMALL, x0, y0, nil )			
end

function emp:onWarp(sim)
	if not self:getTraits().trigger_mainframe then
		if self:getLocation() then
			sim:addTrigger( simdefs.TRG_END_TURN, self )
		else
			sim:removeTrigger( simdefs.TRG_END_TURN, self )		
		end
	end
end 

function emp:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_END_TURN then
		if self:getTraits().primed then
			self:detonate( sim )	
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self} ) 		
		end
		
	end
end

function emp:getTargets( x0, y0 )
    local cells = simquery.rasterCircle( self._sim, x0, y0, self:getTraits().range )
    local units = {}
    for i, x, y in util.xypairs( cells ) do
        local cell = self._sim:getCell( x, y )
        if cell then
            for _, cellUnit in ipairs(cell.units) do
                if cellUnit ~= self and (cellUnit:getTraits().mainframe_status or cellUnit:getTraits().heartMonitor) then
                    table.insert( units, cellUnit )
                end
            end
		end
	end

    return units
end

-- get cells for FLASH PACK
function emp:getExplodeCells()
    local x0, y0 = self:getLocation()
	local currentCell = self:getSim():getCell( x0, y0 )
	local cells = {currentCell}
	if self:getTraits().range then
		local fillCells = simquery.fillCircle( self._sim, x0, y0, self:getTraits().range, 0)

		for i, cell in ipairs(fillCells) do
			if cell ~= currentCell then
				local raycastX, raycastY = self._sim:getLOS():raycast(x0, y0, cell.x, cell.y)
				if raycastX == cell.x and raycastY == cell.y then
					table.insert(cells, cell)
				end
			end
		end
	end
    return cells
end

-- for FLASH PACK
function emp:toggle( sim )
	self:detonate( sim )
end

-----------------------------------------------------
-- Interface functions

local function createEMPPack( unitData, sim )
	return simunit.createUnit( unitData, sim, emp )
end

simfactory.register( createEMPPack )

return
{
	createEMPPack = createEMPPack,
}


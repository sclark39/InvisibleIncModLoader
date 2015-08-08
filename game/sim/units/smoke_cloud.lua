----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local prop_templates = include( "sim/unitdefs/propdefs" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )

-----------------------------------------------------
-- Local functions

local function isInterestSource( unit )
    return unit:getTraits().smokeEdge
end

local smoke_cloud = { ClassType = "smoke_cloud" }

local function createSmokeEdge( sim, cell )
	local unit = simunit.createUnit( prop_templates.smoke_edge, sim )
    sim:spawnUnit( unit )
    sim:warpUnit( unit, cell )
    return unit
end

local function occludeSight( sim, targetCell, smokeRadius )
	local cells = simquery.floodFill( sim, nil, targetCell, smokeRadius, simquery.getManhattanMoveCost, simquery.canPathBetween )
    local segments, interestUnits = {}, {}
    local los = sim:getLOS()
	for _, cell in ipairs(cells) do
        for _, dir in ipairs( simdefs.DIR_SIDES ) do
            local dx, dy = simquery.getDeltaFromDirection( dir )
            local tocell = sim:getCell( cell.x + dx, cell.y + dy )
            if tocell and array.find( cells, tocell ) == nil then
                table.insert( segments, tocell )
                table.insert( segments, simquery.getReverseDirection( dir ) )
                if not simquery.findUnit( tocell.units, isInterestSource ) and simquery.isOpenExit( cell.exits[ dir ] ) then
                    -- Spawn an interest point here.
                    local interestUnit = createSmokeEdge( sim, tocell )
                    table.insert( interestUnits, interestUnit:getID() )
                end
            end
            table.insert( segments, cell )
            table.insert( segments, dir )
        end
    end

    sim:getLOS():insertSegments( unpack( segments ))

    -- Not sure if there's a way around this, must refresh sight for everyone.
    for i, unit in pairs(sim:getAllUnits()) do
        sim:refreshUnitLOS( unit )
    end
    sim:dispatchEvent( simdefs.EV_EXIT_MODIFIED ) -- Update shadow map.

    return cells, segments, interestUnits
end

-----------------------------------------------------
-- Interface functions

function smoke_cloud:onWarp(sim, oldcell, cell)
    if self._segments then
        sim:getLOS():removeSegments( unpack( self._segments ))
        self._segments, self._cells = nil, nil
        for i, unit in pairs(sim:getAllUnits()) do
            sim:refreshUnitLOS( unit )
        end
        sim:dispatchEvent( simdefs.EV_EXIT_MODIFIED ) -- Update shadow map.
    end
    if self._interestUnits then
        for i, unitID in ipairs( self._interestUnits) do
            local unit = sim:getUnit( unitID )
            if unit then
                sim:warpUnit( unit, nil )
                sim:despawnUnit( unit )
            end
        end
        self._interestUnits = nil
    end
    if cell then
        self._cells, self._segments, self._interestUnits = occludeSight( sim, cell, self:getTraits().radius )
        for i, cell in ipairs(self._cells) do
            for i, unit in ipairs(cell.units) do
                if unit:getBrain() and unit:getTraits().hasSight then
                    unit:getBrain():getSenses():addInterest(cell.x, cell.y, simdefs.SENSE_SIGHT, simdefs.REASON_SMOKE)
                end
            end
        end
        sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = self } )     
    end
end

function smoke_cloud:onEndTurn( sim )
    -- There is no simunit base behaviour we desire at this time.
    self:getTraits().lifetime = self:getTraits().lifetime - 1
    if self:getTraits().lifetime <= 0 then
        sim:warpUnit( self, nil )
        sim:despawnUnit( self )
    end
end

function smoke_cloud:getSmokeCells()
    return self._cells
end

function smoke_cloud:getSmokeEdge()
    return self._interestUnits
end
-----------------------------------------------------
-- Interface functions

local function createSmokePlume( unitData, sim )
	return simunit.createUnit( unitData, sim, smoke_cloud )
end

simfactory.register( createSmokePlume )

return smoke_cloud

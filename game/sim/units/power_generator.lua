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
local abilitydefs = include( "sim/abilitydefs" )

-----------------------------------------------------
-- Local functions

local function generateGridName( sim )
	local gridName
	while gridName == nil do
		gridName = string.char( sim:nextRand( 0, 25 ) + string.byte('A') ) .. string.char( sim:nextRand( 0, 9 ) + string.byte('0') )
		for _, unit in pairs(sim:getAllUnits()) do
			if unit:getTraits().powerGridName == gridName then
				gridName = nil
				break
			end
		end
	end
	return gridName
end

local power_generator = { ClassType = "power_generator" }

function power_generator:propagatePower( sim, state )
    local powerGrid = self:getTraits().powerGrid
    assert( powerGrid )

    local units = {}
    
    for unitID, unit in pairs( sim:getAllUnits() ) do

        if unit ~= self and unit:getTraits().powerGrid == powerGrid and unit:getLocation() then
            table.insert(units, unit)
		end
	end

    if #units > 0 then
        sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 30 )
    end

    for k, unit in ipairs(units) do
        
        sim:dispatchEvent( simdefs.EV_CAM_PAN, { unit:getLocation() } )   
        sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 30 )
        self:powerUnit( sim, unit, state )
    end

    if #units > 0 then
        sim:dispatchEvent( simdefs.EV_WAIT_DELAY, 30 )
    end

    sim:dispatchEvent( simdefs.EV_CAM_PAN, { self:getLocation() } )   
end

function power_generator:assignPowerGrid( sim, powerGrid, powerGridName )
    self:getTraits().powerGrid = powerGrid
    self:getTraits().powerGridName = powerGridName or generateGridName( sim )
end

function power_generator:onWarp( sim, oldcell, cell )
	if oldcell then
		self:deactivate( sim )
	end

	if cell and self:getTraits().startOn == true then
        self:activate( sim )
	end

    sim:addTrigger( simdefs.TRG_START_TURN, self )
end

function power_generator:onTrigger( sim, evType, evData )
	if evType == simdefs.TRG_START_TURN then
        self:calculatePowerGrid( sim )
        sim:removeTrigger( simdefs.TRG_START_TURN, self )
    end
end

function power_generator:activate( sim )
	if  self:getTraits().mainframe_status == "inactive" then
		self:getTraits().mainframe_status = "active"
        sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_on" )
		self:propagatePower( sim, true )
	end
end

function power_generator:deactivate( sim )

	if self:getTraits().mainframe_status == "active" then

		self:getTraits().mainframe_status = "inactive"
		sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_object_off" )
        self:propagatePower( sim, false )
	end
end

function power_generator:toggle( sim )

    local txt = ""
	if self:getTraits().mainframe_status == "active" then
        txt = STRINGS.UI.FLY_TXT.POWER_OFF
	else
        txt = STRINGS.UI.FLY_TXT.POWER_ON
	end
    local x0,y0 = self:getLocation()
    local color = {r=1,g=1,b=41/255,a=1}
    sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=txt,x=x0,y=y0,color=color,alwaysShow=true} )    

    if self:getTraits().mainframe_status == "active" then
        self:deactivate( sim )
    else
        self:activate( sim )
    end    
end

function power_generator:powerUnit( sim, unit, state )
	if state and unit.activate then
		unit:activate( sim )
	elseif not state and unit.deactivate then
		unit:deactivate( sim )
	end
    sim:getCurrentPlayer():glimpseUnit( sim, unit:getID() )
end

-----------------------------------------------------
-- Interface functions

local turret_generator = { ClassType = "turret_generator" }

function turret_generator:calculatePowerGrid( sim )
    if self:getTraits().powerGrid == nil then
        -- Name our powergrid after ourselves.
        self:getTraits().powerGrid = self:getID()
        -- Assign nearby turrets to same power grid.
	    local cell = sim:getCell( self:getLocation() )
	    if cell then
		    for dir,exit in pairs(cell.exits) do
			    for i,unit in ipairs(exit.cell.units) do
				    if unit:getTraits().mainframe_turret then
                        self:assignPowerGrid( sim, self:getID(), "TURRET" )
                        unit:getTraits().powerGrid = self:getTraits().powerGrid
                        unit:getTraits().powerGridName = self:getTraits().powerGridName
                    end
			    end
		    end
	    end
    end
end

local laser_generator = { ClassType = "laser_generator" }

function laser_generator:calculatePowerGrid( sim )
    if self:getTraits().powerGrid == nil then
        -- Note: this assigns powerGrids to ALL grid-less laser generators and emitters on the level.
        local units, generators = {}, {}
        for _, unit in pairs( sim:getAllUnits() ) do
            if unit:getTraits().powerGrid == nil then
                if unit:getTraits().mainframe_laser then
                    table.insert( units, unit )
                elseif unit:getUnitData().type == "laser_generator" then
                    table.insert( generators, unit )
                end
            end
	    end

        --print( #units, " emitters ", #generators, " generators" )
        for _, generator in ipairs(generators) do
            generator:assignPowerGrid( sim, generator:getID() )
        end
        local i = 0
        while #units > 0 do
            local generator = generators[(i % #generators) + 1]
            local unit = table.remove( units )
            unit:getTraits().powerGrid = generator:getTraits().powerGrid
            unit:getTraits().powerGridName = generator:getTraits().powerGridName
            i = i + 1
        end
    else
         for _, unit in pairs( sim:getAllUnits() ) do
            if unit:getTraits().mainframe_laser and unit:getTraits().powerGrid == self:getTraits().powerGrid then
                unit:getTraits().powerGrid = self:getID()
            end
        end
        self:getTraits().powerGrid = self:getID()
    end
    return self:getTraits().powerGrid
end

function laser_generator:powerUnit( sim, unit, state )
	if state and unit.activate then
		unit:activate( sim )
	elseif not state and self:getPlayerOwner() then
        -- Deactivating power to this unit actually means taking control.  Sure!
        unit:takeControl( self:getPlayerOwner() )
    elseif not state and unit.deactivate then
        unit:deactivate( sim )
	end
    sim:getCurrentPlayer():glimpseUnit( sim, unit:getID() )
end

-----------------------------------------------------
-- Interface functions

local function createTurretGenerator( unitData, sim )
	return simunit.createUnit( unitData, sim, power_generator, turret_generator )
end

local function createLaserGenerator( unitData, sim )
	return simunit.createUnit( unitData, sim, power_generator, laser_generator )
end

simfactory.register( createTurretGenerator )
simfactory.register( createLaserGenerator )

return
{
	createTurretGenerator = createTurretGenerator,
    createLaserGenerator = createLaserGenerator,
}

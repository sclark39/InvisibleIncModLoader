----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simguard = include( "modules/simguard" )
local simengine = include( "sim/engine" )

--==============================================================
-- Main module header for core simulation engine.

local function createUnitData( unitDef )
	local unitdefs = include( "sim/unitdefs" )
	return unitdefs.createUnitData( unitDef )
end

local function constructSim( params, levelData )
	local level = include( "sim/level" )
    local simengine = include( "sim/engine" )

	simguard.start()
	if levelData == nil then
		levelData = params.levelData or level.loadLevel( params )
	end
	local sim = simengine( params, levelData )
	simguard.finish()

	return sim, levelData
end

return
{
	createUnitData = createUnitData,
	constructSim = constructSim,
}



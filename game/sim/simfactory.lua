----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local ClassFactory = include('modules/class_factory')

--------------------------------------------------------------------------------------

local function register( fn )
	assert(type(fn) == "function")
	ClassFactory.AddClass( fn )
end

local function createUnit( unitData, ... )
	assert( unitData.type, tostring(unitData) )

	return ClassFactory.Construct( unitData.type, unitData, ... )
end

local function createAction( className, ... )
	return ClassFactory.Construct( className, ... )
end

local function createBrain(brainName, sim, unit)
	return ClassFactory.Construct(brainName, sim, unit)
end

local function createSituation(situationType, ...)
	return ClassFactory.Construct(situationType, ...)
end

return
{
	register = register,
	createUnit = createUnit,
	createAction = createAction,
	createBrain = createBrain,
	createSituation = createSituation,
}

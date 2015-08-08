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

-----------------------------------------------------
-- Local functions

local eyeball = { ClassType = "eyeball" }
local eyeball360 = { ClassType = "eyeball" }

-----------------------------------------------------
-- Interface functions

local function createEyeball( sim )
	local prop_templates = include( "sim/unitdefs/propdefs" )
	return util.tmerge( simunit.createUnit( prop_templates.eyeball, sim ), eyeball )
end

local function createEyeball360( sim )
	local prop_templates = include( "sim/unitdefs/propdefs" )
	return util.tmerge( simunit.createUnit( prop_templates.eyeball360, sim ), eyeball360 )
end

return
{
	createEyeball = createEyeball,
	createEyeball360 = createEyeball360, 
}

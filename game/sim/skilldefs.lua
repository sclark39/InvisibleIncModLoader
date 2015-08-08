----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Ability definitions
-- These do NOT get serialized as part of sim state!  They define 'static' information
-- that fully qualifies how an ability affects the simulation state.  The only state
-- modified by the functions contained in the ability definitions below is the simulation
-- and ability instance that are passed in as arguments.
--
-- These ability definition tables are looked up by name when they are needed; references
-- to these from within the sim are therefore simply strings (to avoid serialization connectivity)

local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

-----------------------------------------------------------------
--

local _skills =
{

	stealth = 
	{
		name = STRINGS.SKILLS.STEALTH_NAME,
		levels = 5, 
		description = STRINGS.SKILLS.STEALTH_DESC,

		[1] = 
		{
			tooltip = STRINGS.SKILLS.STEALTH1_TOOLTIP, 
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.SKILLS.STEALTH3_TOOLTIP, 
			cost = 500, 
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
			end,
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			end,			
		},

		[3] = 
		{
			tooltip = STRINGS.SKILLS.STEALTH3_TOOLTIP, 
			cost = 600, 
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
			end, 
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			end, 			
		},

		[4] = 
		{
			tooltip = STRINGS.SKILLS.STEALTH3_TOOLTIP, 
			cost = 700, 
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
			end,
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			end,			 
		},

		[5] = 
		{
			tooltip = STRINGS.SKILLS.STEALTH5_TOOLTIP, 
			cost = 1000, 
			onLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax + 1
			    unit:getTraits().mp = unit:getTraits().mp + 1
			    unit:getTraits().sprintBonus = (unit:getTraits().hacking_bonus or 0) + 1
			end, 
			onUnLearn = function(sim, unit)
			    unit:getTraits().mpMax = unit:getTraits().mpMax - 1
			    unit:getTraits().mp = unit:getTraits().mp - 1
			    unit:getTraits().sprintBonus = unit:getTraits().sprintBonus -1
			end, 			
		}

	},

	hacking = 
	{
		name = STRINGS.SKILLS.HACKING_NAME,
		levels = 5, 
		description = STRINGS.SKILLS.HACKING_DESC,

		[1] = 
		{
			tooltip = STRINGS.SKILLS.HACKING1_TOOLTIP,
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.SKILLS.HACKING2_TOOLTIP,
			cost = 500, 
			onLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 1
			end,
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 1
			end,			
		},

		[3] = 
		{
			tooltip = STRINGS.SKILLS.HACKING2_TOOLTIP,
			cost = 600, 
			onLearn = function(sim, unit)
    			unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 1
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 1
			end,			
		},

		[4] = 
		{
			tooltip = STRINGS.SKILLS.HACKING2_TOOLTIP,
			cost = 700, 
			onLearn = function(sim, unit)
    			unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 1
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 1
			end,			
		},

		[5] = 
		{
			tooltip = STRINGS.SKILLS.HACKING5_TOOLTIP,
			cost = 1000, 
			onLearn = function(sim, unit)
    			unit:getTraits().hacking_bonus = (unit:getTraits().hacking_bonus or 0) + 2
			end, 
			onUnLearn = function(sim, unit)
                unit:getTraits().hacking_bonus = unit:getTraits().hacking_bonus - 2
			end,			
		}		
	},

	inventory = 
	{
		name = STRINGS.SKILLS.INVENTORY_NAME,
		levels = 5, 
		description = STRINGS.SKILLS.INVENTORY_DESC,

		[1] = 
		{
			tooltip = STRINGS.SKILLS.INVENTORY1_TOOLTIP,
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.SKILLS.INVENTORY2_TOOLTIP,
			cost = 300, 
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
    			unit:getTraits().dragCostMod = unit:getTraits().dragCostMod +0.5
			end,
		},

		[3] = 
		{
			tooltip = STRINGS.SKILLS.INVENTORY3_TOOLTIP,
			cost = 500, 
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
			end,
		},

		[4] = 
		{
			tooltip = STRINGS.SKILLS.INVENTORY4_TOOLTIP,
			cost = 500, 
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
    			unit:getTraits().dragCostMod = unit:getTraits().dragCostMod +0.5
			end,
		},

		[5] = 
		{
			tooltip = STRINGS.SKILLS.INVENTORY5_TOOLTIP,
			cost = 900, 
			onLearn = function(sim, unit) 	
    			unit:getTraits().inventoryMaxSize = unit:getTraits().inventoryMaxSize + 1
    			unit:getTraits().meleeDamage = unit:getTraits().meleeDamage +1
			end,
		},
	},

	anarchy = 
	{
		name = STRINGS.SKILLS.ANARCHY_NAME,
		levels = 5, 
		description = STRINGS.SKILLS.ANARCHY_DESC,

		[1] = 
		{
			tooltip = STRINGS.SKILLS.ANARCHY1_TOOLTIP,
			cost = 0,
		},

		[2] = 
		{
			tooltip = STRINGS.SKILLS.ANARCHY2_TOOLTIP,
			cost = 400, 
		},

		[3] = 
		{
			tooltip = STRINGS.SKILLS.ANARCHY3_TOOLTIP,
			cost = 500, 
			onLearn = function(sim, unit) 	
    			unit:getTraits().stealBonus = (unit:getTraits().stealBonus or 0) + 0.15
			end, 
		},

		[4] = 
		{
			tooltip = STRINGS.SKILLS.ANARCHY4_TOOLTIP, 
			cost = 600, 
			onLearn = function(sim, unit) 	
    			unit:getTraits().stealBonus = (unit:getTraits().stealBonus or 0) + 0.20
			end, 
		},

		[5] = 
		{
			tooltip = STRINGS.SKILLS.ANARCHY5_TOOLTIP,
			cost = 800, 
			onLearn = function(sim, unit) 	
			    unit:getTraits().anarchyItemBonus = true
            end, 
		},		
	
	},
}

local function lookupSkill( skillID )
	assert( skillID )
	return _skills[skillID]
end


return
{
	lookupSkill = lookupSkill,
}


local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local readable =
	{
		name = STRINGS.ABILITIES.READABLE,
		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.READABLE, STRINGS.ABILITIES.READABLE_DESC, 0 )
		end,

		proxy = true,
		profile_icon = "gui/items/icon-action_peek.png",

		getName = function( self, sim, unit, userUnit )
			return STRINGS.ABILITIES.READABLE
		end,

		canUseAbility = function( self, sim, unit, userUnit )
			return simquery.canUnitReach( sim, userUnit, unit:getLocation() )
		end,
		
		executeAbility = function( self, sim, unit, userUnit )
			
		end,
	}
return readable
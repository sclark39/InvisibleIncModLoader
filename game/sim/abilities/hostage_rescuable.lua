local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local hostage_rescuable =
	{
		name = STRINGS.ABILITIES.RESCUE,

		getName = function( self, sim )
			return self.name
		end,

		createToolTip = function( self, sim )
			return abilityutil.formatToolTip( self.name, STRINGS.ABILITIES.RESCUE_DESC, simdefs.DEFAULT_COST )
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		proxy = true,
		
		canUseAbility = function ( self, sim, unit, userUnit )
			if userUnit:getPlayerOwner() == nil or userUnit:getTraits().isDrone then
				return false
			end

			return simquery.canUnitReach( sim, userUnit, unit:getLocation() )
		end,

		executeAbility = function ( self, sim, unit, userUnit )
			local cell = sim:getCell( unit:getLocation() )

			local newUnit = userUnit:getPlayerOwner():rescueHostage( sim, unit, cell, unit:getFacing(), userUnit  )
			if newUnit then
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = newUnit } )

				if unit:getTraits().rescue_incident ~= nil then
					sim:triggerEvent( unit:getTraits().rescue_incident, unit )
					return
				end

			end
		end,
	}
return hostage_rescuable
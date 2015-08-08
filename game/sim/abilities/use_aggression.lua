local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local use_injection = include( "sim/abilities/use_injection" )
local inventory = include("sim/inventory")

local use_aggression = util.extend( use_injection )
	{
		name = STRINGS.ABILITIES.USE_AGGRESSION,
		createToolTip = function( self )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.USE_AGGRESSION, STRINGS.ABILITIES.USE_AGGRESSION_DESC, simdefs.DEFAULT_COST)
		end,

		profile_icon = "gui/icons/item_icons/items_icon_small/icon-item_defibulator_small.png",

		isTarget = function( self, sim, userUnit, targetUnit )					
			local canUse = targetUnit:getPlayerOwner() == userUnit:getPlayerOwner()
			canUse = canUse and not targetUnit:isDead()
			canUse = canUse and simquery.isAgent(targetUnit)
			return canUse
		end,
		
		doInjection = function( self, sim, unit, userUnit, target )
			local x1,y1 = target:getLocation()

			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.VENTRICULAR_PIERCING,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )
			
			inventory.useItem( sim, userUnit, unit )

			target:getTraits().genericPiercing = (target:getTraits().genericPiercing or 0) + 1 

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )
		end,
	}
return use_aggression
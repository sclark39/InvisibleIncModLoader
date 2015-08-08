local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local equippable =
	{
		name = STRINGS.ABILITIES.EQUIPPABLE,
		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip( STRINGS.ABILITIES.EQUIPPABLE,  STRINGS.ABILITIES.EQUIPPABLE_DESC, 0)
		end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_equip_small.png",

		getName = function( self, sim, abilityOwner, abilityUser )
			return self.name
		end,
		
		canUseAbility = function( self, sim, abilityOwner, abilityUser )
			if abilityOwner:getUnitOwner() == nil then
				return false
			end
			if abilityOwner:getTraits().equipped then
				return false, STRINGS.UI.REASON.ALREADY_EQUIPPED
			end
			return true
		end,
		
		executeAbility = function( self, sim, unit, userUnit )
			local x1,y1 = userUnit:getLocation()
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/equip", x=x1,y=y1} )
			inventory.equipItem( userUnit, unit )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )
		end,
	}
return equippable
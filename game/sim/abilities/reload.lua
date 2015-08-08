local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local reload =
	{
		name = STRINGS.ABILITIES.RELOAD,
		createToolTip = function( self,sim,unit,targetCell)
			return abilityutil.formatToolTip(STRINGS.ABILITIES.RELOAD, STRINGS.ABILITIES.RELOAD_DESC, 1 )
		end,

		--profile_icon = "gui/items/icon-item_ammo.png",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_reload_small.png",

		alwaysShow = true,

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.RELOAD
		end,

		canUseAbility = function( self, sim, weaponUnit, unit )

			-- Unit must have ammo in need of reloading.
			if weaponUnit:getTraits().ammo >= weaponUnit:getTraits().maxAmmo then
				return false, STRINGS.UI.REASON.AMMO_FULL
			end

			if weaponUnit:getTraits().noReload then 
				return false, STRINGS.UI.REASON.CANT_RELOAD
			end 

			-- Unit must have an ammo clip, or be flagged infinite-ammo.
			local hasAmmo = array.findIf( unit:getChildren(), function( u ) return u:getTraits().ammo_clip ~= nil end )
			if not hasAmmo then 
				return false, STRINGS.UI.REASON.NO_MAGAZINE
			end

			return true
		end,
		
		executeAbility = function( self, sim, weaponUnit, unit )
			abilityutil.doReload( sim, weaponUnit )
		end
	}
return reload
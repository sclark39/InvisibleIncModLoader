local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local recharge =
	{
		name = STRINGS.ABILITIES.RECHARGE,
		createToolTip = function( self,sim,unit,targetCell)
		print(unit:getName())
			if unit:getTraits().usesCharges then
				return abilityutil.formatToolTip( STRINGS.ABILITIES.RECHARGE,  STRINGS.ABILITIES.RECHARGE_CHARGES_DESC, 1 )
			else
				return abilityutil.formatToolTip( STRINGS.ABILITIES.RECHARGE,  STRINGS.ABILITIES.RECHARGE_DESC, 1 )
			end
		end,

		--profile_icon = "gui/items/icon-item_ammo.png",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_chargeweapon_small.png",

		alwaysShow = true,

		getName = function( self, sim, unit )
			return  STRINGS.ABILITIES.RECHARGE
		end,

		canUseAbility = function( self, sim, itemUnit, unit )

			if itemUnit:getTraits().usesCharges then
				if itemUnit:getTraits().charges == itemUnit:getTraits().chargesMax then
					return false, STRINGS.UI.REASON.CHARGE_FULL
				end
			else
				-- Unit must have ammo in need of reloading.			
				if not itemUnit:getTraits().cooldown or itemUnit:getTraits().cooldown <= 0 then
					return false, STRINGS.UI.REASON.CHARGE_FULL
				end
			end

			-- Unit must have an ammo clip, or be flagged infinite-ammo.
			local hasAmmo = array.findIf( unit:getChildren(), function( u ) return u:getTraits().ammo_clip ~= nil end )
			if not hasAmmo then 
				return false, STRINGS.UI.REASON.NO_POWER_PACK
			end

			return true
		end,
		
		executeAbility = function( self, sim, itemUnit, unit )
			abilityutil.doRecharge( sim, itemUnit )
		end
	}
return recharge
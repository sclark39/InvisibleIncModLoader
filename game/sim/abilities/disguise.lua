local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )
local guarddefs = include("sim/unitdefs/guarddefs")

local disguise_tooltip = class( abilityutil.hotkey_tooltip )

function disguise_tooltip:init( hud, unit, range, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
end

function disguise_tooltip:activate( screen )
	abilityutil.hotkey_tooltip.activate( self, screen )

end

function disguise_tooltip:deactivate()
	abilityutil.hotkey_tooltip.deactivate( self )
end

local disguise = 
	{
		name = STRINGS.ABILITIES.DISGUISE,
		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return disguise_tooltip( hud, abilityUser, abilityOwner:getTraits().range, self, sim, abilityOwner, STRINGS.ABILITIES.DISGUISE_DESC )
		end,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		alwaysShow = true,
		getName = function( self, sim, unit )
			if unit:getUnitOwner() and unit:getUnitOwner():getTraits().disguiseOn then
				return STRINGS.ABILITIES.DISGUISE_DEACTIVATE
			else
				return STRINGS.ABILITIES.DISGUISE
			end
		end,

		canUseAbility = function( self, sim, unit )
			-- Must have a user owner.
			local userUnit = unit:getUnitOwner()
			if not userUnit then
				return false
			end

			if unit:getTraits().restrictedUse then

				local userUnitAgentID = userUnit:getUnitData().agentID
				local canUse =false
				for i,set in pairs(unit:getTraits().restrictedUse )do
					if set.agentID == userUnitAgentID then
						canUse=true
					end
				end


				if not canUse then
					return false,  STRINGS.UI.REASON.RESTRUCTED_USE
				end				
			end


			if not userUnit:getTraits().disguiseOn then
				if unit:getTraits().pwrCost and unit:getPlayerOwner():getCpus() < unit:getTraits().pwrCost then
					return false,  STRINGS.UI.REASON.NOT_ENOUGH_PWR
				end				
			end
					
			return abilityutil.checkRequirements( unit, userUnit )
		end,

		executeAbility = function( self, sim, unit )
			local userUnit = unit:getUnitOwner()

			if userUnit:getTraits().disguiseOn then
				userUnit:setDisguise(false)
			else

				local kanim = "kanim_guard_male_ftm"
				local wt = util.weighted_list( sim._patrolGuard )	

				for i = 2, #wt, 2 do
					local template = guarddefs[wt[i]]
					if not template.traits.isDrone then
						kanim = template.kanim							
					end

				end
 				
				userUnit:setDisguise(true, kanim)
			
				if sim:canPlayerSeeUnit( sim:getNPC(), userUnit ) then 
					userUnit:setDisguise(false)
				end

				userUnit:resetAllAiming()
	
				inventory.useItem( sim, userUnit, unit )
			end
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )

		--	sim:processReactions(userUnit)			

		end,
	}
return disguise





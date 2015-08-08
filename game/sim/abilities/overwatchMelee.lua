local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local overwatchMelee =
	{
		name = STRINGS.ABILITIES.OVERWATCH_MELEE,
		hotkey = "abilityReaction",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_overwatch_melee_small.png",

		getProfileIcon =  function( self, sim, unit )
			if unit:getTraits().isMeleeAiming then
				return "gui/icons/action_icons/Action_icon_Small/actionicon__meleeOW_on.png"
			else
				return "gui/icons/action_icons/Action_icon_Small/actionicon__meleeOW_off.png"
			end
		end,

		alwaysShow = true,
		HUDpriority = 1,
		usesAction = true,

		getName = function( self, sim, unit )
			local txt = STRINGS.ABILITIES.OVERWATCH_MELEE
			if unit:getTraits().isMeleeAiming then
				txt = txt .. STRINGS.ABILITIES.OVERWATCH_ON
			end
			return txt
		end,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return abilityutil.overwatch_tooltip( hud, self, sim, abilityOwner, STRINGS.ABILITIES.OVERWATCH_MELEE_DESC )
		end,

		canUseAbility = function( self, sim, unit )

			if unit:getAP() < 1 then 
				return false, STRINGS.UI.HUD_ATTACK_USED
			end

			if unit:isKO() then
				return false, STRINGS.UI.REASON.UNIT_IS_KO
			end		

			if simquery.isUnitPinning( sim, unit ) then
				return false, STRINGS.UI.REASON.ENEMY_PINNED 
			end

			if not unit:getPlayerOwner():isNPC() then
				--User must have a tazer
				local tazerUnit = simquery.getEquippedMelee( unit )
				if not tazerUnit then
					return false, STRINGS.UI.REASON.NO_MELEE_WEAPON
				elseif tazerUnit:getTraits().usesCharges and tazerUnit:getTraits().charges < 1 then 
					return false, string.format(STRINGS.UI.REASON.CHARGES)
				elseif tazerUnit:getTraits().cooldown and tazerUnit:getTraits().cooldown > 0 then
					return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,tazerUnit:getTraits().cooldown)
				elseif tazerUnit:getTraits().pwrCost and unit:getPlayerOwner():getCpus() < tazerUnit:getTraits().pwrCost then 
					return false, string.format(STRINGS.UI.REASON.NOT_ENOUGH_PWR)

				end

			end

			return true
		end,
		
		executeAbility = function( self, sim, unit )

			if unit:isValid() then
				local x0,y0 = unit:getLocation()
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/overwatch_tazer", x=x0,y=y0} )
				if unit:getTraits().isMeleeAiming then
					unit:getTraits().isMeleeAiming = false					
					sim:dispatchEvent( simdefs.EV_UNIT_OVERWATCH_MELEE, { unit = unit, cancel=true})
				else
					unit:getTraits().isMeleeAiming = true
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.AMBUSH_READY,x=x0,y=y0,color={r=1,g=1,b=1,a=1}} )
					sim:dispatchEvent( simdefs.EV_UNIT_OVERWATCH_MELEE, { unit = unit })
				end
				unit:setAiming(false)			
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit })
			end	
		end,
	}

return overwatchMelee
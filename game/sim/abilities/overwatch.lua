local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )


local overwatch =
	{
		name = STRINGS.ABILITIES.OVERWATCH,
		hotkey =  "abilityOverwatch",
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_overwatch_small.png",

		getProfileIcon =  function( self, sim, unit )
			if unit:isAiming() then				        
				return "gui/icons/action_icons/Action_icon_Small/actionicon_shootOW_on.png"
			else
				return "gui/icons/action_icons/Action_icon_Small/actionicon_shootOW_off.png"
			end
		end,

		alwaysShow = true,
		HUDpriority = 1,
		usesAction = true,

		getName = function( self, sim, unit )
			local txt = STRINGS.ABILITIES.OVERWATCH
			if unit:isAiming() then
				txt = txt .. STRINGS.ABILITIES.OVERWATCH_ON
			end
			return txt
		end,

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			return abilityutil.overwatch_tooltip( hud, self, sim, abilityOwner, STRINGS.ABILITIES.OVERWATCH_DESC )
		end,

		canUseAbility = function( self, sim, unit )

			if unit:getTraits().takenDrone then 
				return false, STRINGS.UI.REASON.HACKED_DRONES_CANT_OVERWATCH
			end

			if unit:getAP() < 1 then 
				return false, STRINGS.UI.REASON.ATTACK_USED
			end

			if unit:isKO() then
				return false, STRINGS.UI.REASON.UNIT_IS_KO
			end		

			local weaponUnit = simquery.getEquippedGun( unit )
			if not weaponUnit then
				return false, STRINGS.UI.REASON.NO_GUN
            end

            local ok, reason = abilityutil.canConsumeAmmo( sim, weaponUnit )
            if not ok then
                return false, reason
			end

			return true
		end,
		
		executeAbility = function( self, sim, unit, ownerUnit, targetID )
			if unit:isValid() then
				if unit:isPC() then
					local x0, y0 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Actions/overwatch_tazer", x=x0,y=y0} )
				end
				if unit:isAiming() then 
					unit:setAiming(false)
					sim:dispatchEvent( simdefs.EV_UNIT_OVERWATCH, { unit = unit, cancel=true })
				else
					unit:setAiming(true)
					sim:dispatchEvent( simdefs.EV_UNIT_OVERWATCH, { unit = unit, targetID = targetID })
					sim:triggerEvent( simdefs.TRG_SET_OVERWATCH, { unit=unit } )

					local x0, y0 = unit:getLocation()
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.OVERWATCH_READY,x=x0,y=y0,color={r=1,g=1,b=1,a=1}} )		
				end

				unit:getTraits().isMeleeAiming = false

				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit })


				if unit:isNPC() and unit:getTraits().isGuard and not sim:getTags().isTutorial
				 and not (unit:getBrain():getTarget() and unit:getBrain():getTarget():getTraits().mainframe_turret)
				 and not (unit:getBrain():getTarget() and unit:getBrain():getTarget():getTraits().takenDrone) then 
					sim:dispatchEvent( simdefs.EV_SHOW_DIALOG,
                        { showOnce = "spottedDialog", dialogParams = { "modal-spotted.lua" } } )
				end 
			end	
		end,
	}
return overwatch

local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local SPRINT_BONUS = 3

local sprint_tooltip = class( abilityutil.hotkey_tooltip )

function sprint_tooltip:init( hud, unit, ... )
	abilityutil.hotkey_tooltip.init( self, ... )
	self._game = hud._game
	self._unit = unit
end

function sprint_tooltip:activate( screen )
	local sprintBonus = SPRINT_BONUS
	if self._unit:hasTrait("sprintBonus") then
		sprintBonus = sprintBonus + self._unit:getTraits().sprintBonus
	end

	abilityutil.hotkey_tooltip.activate( self, screen )
    if (self._unit:getTraits().mpUsed or 0) > 0 then
    	self._game.hud:previewAbilityAP( self._unit, 0 )
    elseif self._unit:getTraits().sneaking then
   	    self._game.hud:previewAbilityAP( self._unit, -sprintBonus )
    else
   	    self._game.hud:previewAbilityAP( self._unit, sprintBonus )
    end
end

function sprint_tooltip:deactivate()
	abilityutil.hotkey_tooltip.deactivate( self )
	self._game.hud:previewAbilityAP( self._unit, 0 )
end

local sprint = 
	{
		name = STRINGS.ABILITIES.SPRINT,
        canUseWhileDragging = true,

		hotkey = "abilitySprint",

		onTooltip = function( self, hud, sim, abilityOwner, abilityUser )
			local sprintBonus = SPRINT_BONUS
			if abilityUser:hasTrait("sprintBonus") then
				sprintBonus = sprintBonus + abilityUser:getTraits().sprintBonus
			end

			local SPRINT_TOOLTIP = util.sformat( STRINGS.ABILITIES.SPRINT_DESC, sprintBonus )
            return sprint_tooltip( hud, abilityUser, self, sim, abilityOwner, SPRINT_TOOLTIP )
		end,

		usesMP = true,

		alwaysShow = true,
		HUDpriority = 4,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/actionicon__sprint_off.png",

		getProfileIcon =  function( self, sim, unit )
			if unit:getTraits().sneaking then
				return "gui/icons/action_icons/Action_icon_Small/actionicon__sprint_off.png"
			else
				return "gui/icons/action_icons/Action_icon_Small/actionicon__sprint_on.png"
			end
		end,

		--profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_sneak_small.png",

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.SPRINT_TOGGLE
		end,

		canUseAbility = function( self, sim, unit )
			if unit:getTraits().mp < unit:getTraits().mpMax then
				return false, STRINGS.UI.REASON.MUST_TOGGLE_BEFORE_MP
			end

			return true 
		end,
		
		executeAbility = function( self, sim, unit )
	
			if unit:getTraits().sneaking then
                unit:getTraits().sneaking = false
				unit:getTraits().mp = unit:getTraits().mp + SPRINT_BONUS
				if unit:hasTrait("sprintBonus") then
					unit:getTraits().mp = unit:getTraits().mp + unit:getTraits().sprintBonus
				end

				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
    			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.SPRINTING, unit = unit, color= cdefs.MOVECLR_DEFAULT })

    			 
				if unit:isValid() and unit:getTraits().kinetic_capacitor_alert then
					sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, { txt=unit:getTraits().kinetic_capacitor_alert, unit = unit, color=cdefs.AUGMENT_TXT_COLOR })
				end    	

            else
                unit:getTraits().sneaking = true
				unit:getTraits().mp = unit:getTraits().mp - SPRINT_BONUS
				if sim:isVersion("0.17.1") then
					if unit:hasTrait("sprintBonus") then
						unit:getTraits().mp = unit:getTraits().mp - unit:getTraits().sprintBonus
					end				
				end
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
    			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.SNEAKING, unit = unit, color=cdefs.MOVECLR_SNEAK })
			end

		end,
	}

return sprint
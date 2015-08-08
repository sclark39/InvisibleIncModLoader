local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local unitdefs = include("sim/unitdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local installAugment = 
	{
		name = STRINGS.ABILITIES.INSTALL_AUGMENT,
		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.INSTALL_AUGMENT,STRINGS.ABILITIES.INSTALL_AUGMENT_DESC )
		end, 		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		
		alwaysShow = true,

		getName = function( self, sim, unit, userUnit )
			return STRINGS.ABILITIES.INSTALL_AUGMENT
		end,

		canUseAbility = function( self, sim, unit, userUnit )

			if not userUnit:canAct() then
				return false, STRINGS.ABILITIES.TOOLTIPS.CANT_ACT
			end		

			if not unit:getTraits().augment then
				return false, STRINGS.ABILITIES.TOOLTIPS.NOT_AUGMENT
			end 

			if userUnit:getAugmentCount() >= (userUnit:getTraits().augmentMaxSize or 0) then				
                return false, STRINGS.ABILITIES.TOOLTIPS.NO_AUGMENT_SLOTS_AVAILABLE
            end

			if not unit:getTraits().stackable and userUnit:countAugments( unit:getUnitData().id ) > 0 then				
                return false, STRINGS.ABILITIES.TOOLTIPS.AUGMENT_ALREADY_INSTALLED
            end

			return true
		end,

		executeAbility = function( self, sim, unit, userUnit )
			local x1, y1 = userUnit:getLocation()
			sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=STRINGS.UI.FLY_TXT.AUGMENT_INSTALLED,x=x1,y=y1,color={r=1,g=1,b=1,a=1}} )

            local unitDef = unitdefs.lookupTemplate( unit:getUnitData().id )
            sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/VoiceOver/Incognita/Pickups/Augment_Installed" )		
            sim:dispatchEvent( simdefs.EV_LOOT_ACQUIRED, { unit = userUnit, lootUnit = unit, icon = unitDef.profile_icon_100 } )

			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_INSTALL )		
			sim:dispatchEvent( simdefs.EV_UNIT_INSTALL_AUGMENT, { unit = userUnit } )
            userUnit:doAugmentUpgrade( unit )
			
			
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )			
		end,
	}
return installAugment
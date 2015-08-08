local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local simfactory = include( "sim/simfactory" )
local inventory = include("sim/inventory")
local unitdefs = include( "sim/unitdefs" )
local mission_util = include( "sim/missions/mission_util" )

local useAugmentMachine =
	{
		name = STRINGS.UI.ACTIONS.INSTALL_AUGMENT.NAME,

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		onTooltip = abilityutil.onAbilityTooltip,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-action_augment.png",
		proxy = true,
		alwaysShow = true,
		ghostable = true,

		canUseAbility = function( self, sim, unit, userUnit )
				   
			if not simquery.canUnitReach( sim, userUnit, unit:getLocation() ) then
				return false
			end

			if userUnit:getTraits().isDrone then
				return false -- Drones have no hands to loot with
			end

            if userUnit:getTraits().augmentMaxSize == nil then
                return false, STRINGS.UI.REASON.CANNOT_AUGMENT_THIS_UNIT
            end

			if unit:getTraits().mainframe_status == "off" then
				return false, STRINGS.UI.REASON.MACHINE_INACTIVE

			end

			if unit:getPlayerOwner() ~= userUnit:getPlayerOwner() and unit:getTraits().mainframe_status == "active" then 
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

			if unit:getTraits().used then 
				return false, STRINGS.UI.REASON.MACHINE_USED
			end

			return true
		end,

		executeAbility = function ( self, sim, unit, userUnit)
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unit:getLocation()	
			local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = userUnit:getID(), facing = facing } )
			
			-- Loot items within
			if #unit:getChildren() > 0 then
				sim:dispatchEvent( simdefs.EV_ITEMS_PANEL, { targetUnit = unit, unit = userUnit } )
			end

			if not self._augmentID then
			    local augmentList = util.weighted_list({
				    { "augment_net_downlink", 10 },
				    { "augment_anatomy_analysis", 10 },
				    { "augment_distributed_processing", 10 },
				    { "augment_torque_injectors", 10 },
				    { "augment_titanium_rods", 10 },
				    { "augment_holocircuit_overloaders", 10 },
				    { "augment_predictive_brawling", 10 },
				    { "augment_subdermal_cloak", 5 },
                    { "augment_microslam_apparatus", 4 },
				    { "augment_chameleon_movement", 10 },
				    { "augment_piercing_scanner", 10 },
				    { "augment_penetration_scanner", 10 },
			    })

				self._augmentID = augmentList:getChoice( sim:nextRand(1, augmentList:getTotalWeight()))
			end

        	local unitDef = unitdefs.lookupTemplate( self._augmentID ) 
			local choice = mission_util.showGrafterDialog( sim, unitDef, userUnit, unit:getTraits().drill )
			if choice == 3 then

				if userUnit:getAugmentCount() >= userUnit:getTraits().augmentMaxSize then				
					mission_util.showDialog( sim, "", STRINGS.ABILITIES.TOOLTIPS.NO_AUGMENT_SLOTS_AVAILABLE )
					sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = facing } )
				elseif not unitDef.traits.stackable and userUnit:countAugments(  self._augmentID ) > 0 then	
              		mission_util.showDialog( sim, "", STRINGS.ABILITIES.TOOLTIPS.AUGMENT_ALREADY_INSTALLED )
					sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = facing } )
				else
	                local newUnit = simfactory.createUnit( unitDef, sim )
	                sim:spawnUnit( newUnit )
	                userUnit:addChild( newUnit )

	    			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/VoiceOver/Incognita/Pickups/Augment_Installed" )		
	    			sim:dispatchEvent( simdefs.EV_LOOT_ACQUIRED, { unit = userUnit, lootUnit = newUnit, icon = unitDef.profile_icon_100 } )

					sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_INSTALL )		
	    			sim:dispatchEvent( simdefs.EV_UNIT_INSTALL_AUGMENT, { unit = userUnit } )
                    userUnit:doAugmentUpgrade( newUnit )
					
					sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = facing } )
					unit:getTraits().used = true	
					unit:getTraits().mainframe_status = "off"
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
					sim:getStats():incStat("safes_looted")	

					sim:triggerEvent(simdefs.TRG_USE_AUGMENT_MACHINE, { unit=userUnit, shop = unit, lootUnit = newUnit } )
				end			

			elseif choice == 2 then
				if userUnit:getTraits().augmentMaxSize >= (userUnit:getTraits().augmentMaxCapacity or simdefs.DEFAULT_AUGMENT_CAPACITY) then				
					mission_util.showDialog( sim, "", STRINGS.UI.DIALOGS.AUGMENT_MACHINE_MAXED )
					sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = facing } )
				else
					sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Objects/AugmentInstallMachine", x=x0,y=y0} )

					userUnit:getTraits().augmentMaxSize = userUnit:getTraits().augmentMaxSize + 1				
					userUnit:setKO( sim, 2 )	
					unit:getTraits().used = true	
					unit:getTraits().mainframe_status = "off"
					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
					sim:getStats():incStat("safes_looted")	
					sim:triggerEvent(simdefs.TRG_USE_AUGMENT_MACHINE, { unit=userUnit, shop = unit, newslot = true } )
				end
			elseif choice > 3 then
				local augment = choice - 3
				local augments = userUnit:getAugments()

				inventory.trashItem( sim, userUnit, augments[augment] )
    						
				sim:dispatchEvent( simdefs.EV_PLAY_SOUND, {sound="SpySociety/Objects/AugmentInstallMachine", x=x0,y=y0} )

				userUnit:setKO( sim, 2 )	
				unit:getTraits().used = true	
				unit:getTraits().mainframe_status = "off"				
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
				sim:getStats():incStat("safes_looted")	

				sim:triggerEvent(simdefs.TRG_USE_AUGMENT_MACHINE, { unit=userUnit, shop = unit, newslot = true } )
			else
				sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = facing } )
			end

			if unit:getTraits().used then
				sim:triggerEvent(simdefs.TRG_CLOSE_AUGMENT_MACHINE, { unit=unit, user=userUnit } )
			end
		
		end,
	}
return useAugmentMachine
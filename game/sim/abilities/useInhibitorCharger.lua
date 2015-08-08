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

local useInhibitorCharger =
	{
		name = STRINGS.UI.ACTIONS.CHARGE_INHIBITOR.NAME,

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,

		onTooltip = abilityutil.onAbilityTooltip,

		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_loot_small.png",
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

			local inhibitor = array.findIf( userUnit:getChildren(), function( u ) return u:getTraits().daemon_blocker ~= nil end )

            if inhibitor == nil or inhibitor == false then 
            	return false, STRINGS.UI.REASON.NO_ARCHDAEMON_INHIBITOR
            end 

            if inhibitor then 
            	if inhibitor:getTraits().maxAmmo <= inhibitor:getTraits().ammo then 
            		return false, STRINGS.UI.REASON.ARCHDAEMON_CHARGED
            	end
            end

			if unit:getTraits().mainframe_status == "off" then
				return false, STRINGS.UI.REASON.MACHINE_USED
			end

			if unit:getPlayerOwner() ~= userUnit:getPlayerOwner() and unit:getTraits().mainframe_status == "active" then 
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

			return true
		end,

		executeAbility = function ( self, sim, unit, userUnit)
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unit:getLocation()	
			local facing = simquery.getDirectionFromDelta(x1-x0,y1-y0)
			local inhibitor = array.findIf( userUnit:getChildren(), function( u ) return u:getTraits().daemon_blocker ~= nil end )

			inhibitor:getTraits().ammo = inhibitor:getTraits().ammo + 1 

			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = userUnit:getID(), facing = facing } )					
			sim:dispatchEvent( simdefs.EV_PLAY_SOUND, cdefs.SOUND_HUD_INSTALL )		
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = userUnit:getID(), facing = facing } )
			unit:getTraits().used = true	
			unit:getTraits().mainframe_status = "off"	
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )
			
			
		end,
	}
return useInhibitorCharger
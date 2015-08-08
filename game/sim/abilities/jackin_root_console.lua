local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local jackin_root_console = 
	{
		name = STRINGS.ABILITIES.JACKIN,

		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.JACKIN,STRINGS.ABILITIES.JACKIN_DESC)
		end,

		proxy = true,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			return self.name
		end,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",

		isTarget = function( self, abilityOwner, unit, targetUnit )
		
			if targetUnit:getTraits().mainframe_status ~= "active" then
				return false
			end
			
			return true
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
			local units = {}
			
			if sim:getTags().monster_finished_hacking then
				return targets.unitTarget( game, units, self, abilityOwner, unit )
			end 

			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 and self:isTarget( abilityOwner, unit, targetUnit ) and simquery.canUnitReach( sim, unit, x1, y1 ) then
					table.insert( units, targetUnit )
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )
			local userUnit = abilityOwner:getUnitOwner()

			if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
				return false,  util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	
			if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
				return false, util.sformat(STRINGS.UI.REASON.CHARGES)
			end				

			if unit:getTraits().monster_hacking == true then 
				return false, STRINGS.UI.REASON.ALREADY_HACKING 
			end 

			if unit:getTraits().monst3rUnit ~= true then 
				return false, STRINGS.UI.REASON.ONLY_MONSTER
			end 

			if abilityOwner:getTraits().mainframe_ice > 0 then 
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

			return abilityutil.checkRequirements( abilityOwner, userUnit )
		end,

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			local targetUnit = sim:getUnit( targetUnitID )

			local x0,y0 = unit:getLocation()
			local x1,y1 = targetUnit:getLocation()			
			local tempfacing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )
			unit:setFacing(tempfacing)	
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), facing = tempfacing, sound = "SpySociety/Actions/monst3r_jackin" , soundFrame = 16, useTinkerMonst3r=true } )
			sim:triggerEvent( "ending_jackin" )

			unit:getTraits().monster_hacking = true 
			unit:getSounds().spot = "SpySociety/Actions/monst3r_hacking"
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit })
		end,

	}

return jackin_root_console
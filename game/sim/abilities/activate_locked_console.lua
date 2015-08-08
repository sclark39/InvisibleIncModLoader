local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local activate_locked_console = 
	{
		name = STRINGS.ABILITIES.DEACTIVATE_LOCK,

		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.DEACTIVATE_LOCK, STRINGS.ABILITIES.DEACTIVATE_LOCK_DESC )
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

			if sim:getTags().monster_unlocked_final then
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
				return false, util.sformat( STRINGS.ABILITIES.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
			end	

			local keybits = false 
			for i,item in ipairs( unit:getChildren() ) do
 				if item:getTraits().keybits then 
					if item:getTraits().keybits == abilityOwner:getTraits().keybits then 
						keybits = true 
					end  
				end
			end 

			if keybits == false then 
				return false, STRINGS.UI.REASON.MONST3R_REQUIRED
			end

			if abilityOwner:getTraits().mainframe_ice > 0 then 
				return false, STRINGS.ABILITIES.TOOLTIPS.UNLOCK_WITH_INCOGNITA
			end

			return abilityutil.checkRequirements( abilityOwner, userUnit )
		end,

		-- Mainframe system.

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )

			local targetUnit = sim:getUnit( targetUnitID )
			assert( targetUnit, "No target : "..tostring(targetUnitID))
			local x1, y1 = targetUnit:getLocation()
			local x0,y0 = unit:getLocation()
			local facing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )
			sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), targetID= targetUnit:getID(), facing = facing, sound=simdefs.SOUNDPATH_USE_CONSOLE, soundFrame=10 } )
			
			sim:getTags().monster_unlocked_final = true
			sim:triggerEvent( "final_unlock" )
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = abilityOwner } )
		end,

	}
return activate_locked_console
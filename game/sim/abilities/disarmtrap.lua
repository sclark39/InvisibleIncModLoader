local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local disarmtrap = 
	{
		name = STRINGS.ABILITIES.DISARM_TRAP,

		createToolTip = function( self,sim,unit,targetCell)
			return abilityutil.formatToolTip(STRINGS.ABILITIES.DISARM_TRAP, STRINGS.ABILITIES.DISARM_TRAP_DESC, simdefs.DEFAULT_COST )
		end,
		usesAction = true,
		
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_hijack_small.png",
		alwaysShow = true,

		getName = function( self, sim, unit )
			return STRINGS.ABILITIES.DISARM_TRAP
		end,

		acquireTargets = function( self, targets, game, sim, abilityOwner, unit )
			local x0, y0 = unit:getLocation()
			local units = {}
			for _, targetUnit in pairs(sim:getAllUnits()) do
				local x1, y1 = targetUnit:getLocation()
				if x1 == x0 and y1 ==y0 and targetUnit:getTraits().trap then
					table.insert( units, targetUnit )				
				end
			end

			return targets.unitTarget( game, units, self, abilityOwner, unit )
		end,

		canUseAbility = function( self, sim, abilityOwner, abilityUser )
			-- Must have a user owner.
			
			-- user must be in front of trap
			local cell = sim:getCell( abilityOwner:getLocation() )
			local units = {}
			for i, unit in pairs(cell.units) do
				if unit:getTraits().trap then
					table.insert(units,unit)
				end
			end
			if #units == 0 then
				return false, STRINGS.UI.REASON.NO_TRAP
			end

			return true
		end,

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )


			local oldFacing = abilityOwner:getFacing()
			abilityOwner:resetAllAiming()

			local cell = sim:getCell( abilityOwner:getLocation() )			

			local target = sim:getUnit(targetUnitID)
			
			local newFacing = target:getFacing()

			abilityOwner:setFacing( newFacing )		
			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR, { unitID = abilityOwner:getID() } )		
		
			local target2 = sim:getUnit(target:getTraits().linkedTrap)

			
			sim:warpUnit( target, nil )	
			sim:despawnUnit( target )
			sim:warpUnit( target2, nil )	
			sim:despawnUnit( target2 )

			sim:dispatchEvent( simdefs.EV_UNIT_USEDOOR_PST, { unitID = abilityOwner:getID() } )	
		

			sim:processReactions( abilityOwner )

			if abilityOwner:isValid() then
				abilityOwner:setFacing( oldFacing )		
				sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = abilityOwner } )
			end
		end,
	}
return disarmtrap
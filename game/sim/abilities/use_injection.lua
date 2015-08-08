local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local use_injection =
{
	name = STRINGS.ABILITIES.INJECTION,
	--profile_icon = "gui/items/icon-item_needle.png",

	alwaysShow = true,

	getName = function( self, sim, unit )
		return string.format(STRINGS.ABILITIES.INJECTION_APPLY,self.name)
	end,

	findTargets = function( self, sim, abilityOwner, userUnit )
		local cell = sim:getCell( userUnit:getLocation() )
		local units = {}

		for i, cellUnit in ipairs( cell.units ) do
			if self:isTarget( sim, userUnit, cellUnit ) then
				table.insert( units, cellUnit )
			end
		end

		for dir, exit in pairs( cell.exits ) do
			if simquery.isOpenExit( exit ) then
				for i,cellUnit in ipairs(exit.cell.units) do
					if self:isTarget( sim, userUnit, cellUnit ) then
						table.insert( units, cellUnit )
					end
				end
			end
		end
			
		return units
	end,

	acquireTargets = function( self, targets, game, sim, abilityOwner, userUnit )
		local units = self:findTargets( sim, abilityOwner, userUnit )
		return targets.unitTarget( game, units, self, abilityOwner, userUnit )
	end,

	canUseAbility = function( self, sim, abilityOwner, userUnit, targetUnitID )

		if not simquery.isAgent( userUnit ) then
			return false
		end
		if abilityOwner:getUnitOwner() ~= userUnit then
			return false
		end
		if targetUnitID then
			if not self:isTarget( sim, userUnit, sim:getUnit( targetUnitID ) ) then
				return false
			end

		else
			local units = self:findTargets( sim, abilityOwner, userUnit )
			if #units == 0 then
				return false, STRINGS.UI.REASON.NO_INJURED_TARGETS
			end
		end

		if abilityOwner:getTraits().cooldown and abilityOwner:getTraits().cooldown > 0 then
			return false,  util.sformat(STRINGS.UI.REASON.COOLDOWN,abilityOwner:getTraits().cooldown)
		end
		if abilityOwner:getTraits().usesCharges and abilityOwner:getTraits().charges < 1 then
			return false, util.sformat(STRINGS.UI.REASON.CHARGES)
		end			

		return abilityutil.checkRequirements( abilityOwner, userUnit )
	end,

	executeAbility = function( self, sim, unit, userUnit, target )
		local oldFacing = userUnit:getFacing()
		local target = sim:getUnit(target)	
  		local newFacing = userUnit:getFacing()
  		local revive = false


  		if target ~= userUnit then
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = target:getLocation()
			newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 
			if target:isKO() then
				revive = true
			end
		end

		sim:dispatchEvent( simdefs.EV_UNIT_HEAL, { unit = userUnit, target = target, revive = revive, facing = newFacing } )
		
		self:doInjection( sim, unit, userUnit, target )

		sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit =target  } )

		if unit:getTraits().disposable then 
			inventory.trashItem( sim, userUnit, unit )
		else
			inventory.useItem( sim, userUnit, unit )
		end
	end,
}

return use_injection
local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local abilityutil = include( "sim/abilities/abilityutil" )

local manualHack =
{
	name = STRINGS.ABILITIES.MANUAL_SHUTDOWN,
	profile_icon = "gui/icons/skills_icons/skills_icon_small/icon-item_augment_tony_small.png",
	usesAction = true,
	createToolTip = function( self,sim, abilityOwner, abilityUser, targetID )
		local targetUnit = sim:getUnit( targetID )
		return util.sformat( STRINGS.ABILITIES.MANUAL_SHUTDOWN_DESC, util.toupper( targetUnit:getName() ),1)
	end,
		
	getName = function( self, sim, unit )
		return STRINGS.ABILITIES.MANUAL_SHUTDOWN
	end,

    isTarget = function( self, sim, userUnit, targetUnit )
        if targetUnit:getTraits().heartMonitor == "enabled" then
            return true
        end
        
        if (targetUnit:getTraits().mainframe_ice or 0) > 0 and targetUnit:getTraits().mainframe_status ~= "off" then
            if sim:canUnitSeeUnit( userUnit, targetUnit ) then
                return true
            end
        end

        return false
    end,

	acquireTargets = function( self, targets, game, sim, unit, userUnit )
		local cell = sim:getCell( userUnit:getLocation() )
		local units = {}
		for dir, exit in pairs(cell.exits) do
			for _, cellUnit in ipairs( exit.cell.units ) do
                if self:isTarget( sim, userUnit, cellUnit ) then
                    if not sim:isVersion( "0.17.4" ) or simquery.canUnitReach( sim, userUnit, exit.cell.x, exit.cell.y ) then
    					table.insert( units, cellUnit )
                    end
				end
			end
		end

		return targets.unitTarget( game, units, self, unit, userUnit )
	end,
		
	canUseAbility = function( self, sim, unit, userUnit )
		-- has a target in range
		local cell = sim:getCell( userUnit:getLocation() )
		local count = 0
		for dir, exit in pairs(cell.exits) do
			local unit = array.findIf( exit.cell.units, function( u ) return self:isTarget( sim, userUnit, u ) end )
			if unit then
				count = count + 1
			end					
		end

		if unit:getAP() < 1 then 
			return false, STRINGS.UI.REASON.ATTACK_USED
		end 

		if unit:getTraits().cooldown and unit:getTraits().cooldown > 0 then
			return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,unit:getTraits().cooldown)
		end

		if unit:getTraits().usesCharges and unit:getTraits().charges < 1 then
			return false, util.sformat(STRINGS.UI.REASON.CHARGES)
		end	

		if count == 0 then
			return false, STRINGS.UI.REASON.NO_ICE
		end

		return abilityutil.checkRequirements( unit, userUnit)
	end,
		
	executeAbility = function( self, sim, unit, userUnit, target )
		local mainframe = include( "sim/mainframe" )
		local target = sim:getUnit(target)			
		local x0,y0 = userUnit:getLocation()
		local x1,y1 = target:getLocation()
  		local newFacing = simquery.getDirectionFromDelta(x1-x0,y1-y0) 
		userUnit:setInvisible(false)
		userUnit:setDisguise(false)
		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = unit:getID(), facing = newFacing, sound="SpySociety/Actions/use_scanchip", soundFrame=10 } )
					
        target:processEMP( 1 )

		if unit:getTraits().disposable then
			inventory.trashItem( sim, userUnit, unit )
		else
			inventory.useItem( sim, userUnit, unit )
		end

		unit:useAP( sim )
	end,
}
return manualHack
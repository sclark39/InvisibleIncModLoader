local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

---------------------------------------------------------
-- Local functions

local function createObserveTab( unit )
	local subtext = ""
	local brainClassType = unit:getBrain():getSituation().ClassType
	local x0, y0 = unit:getLocation()

	if brainClassType == simdefs.SITUATION_INVESTIGATE then
		if unit:getBrain():getInterest().x == x0 and unit:getBrain():getInterest().y == y0 then
			subtext = STRINGS.GUARD_STATUS.START_INVESTIGATING
		else
			subtext = STRINGS.GUARD_STATUS.INVESTIGATING
		end
	elseif brainClassType == simdefs.SITUATION_HUNT then
		local interest = unit:getBrain():getInterest()
		if interest and interest.reason == simdefs.REASON_KO and interest.x == x0 and interest.y == y0 then
			subtext = STRINGS.GUARD_STATUS.START_HUNTING
		else
			subtext = STRINGS.GUARD_STATUS.HUNTING
		end
	elseif brainClassType == simdefs.SITUATION_FLEE then
		subtext = STRINGS.GUARD_STATUS.FLEEING
	elseif brainClassType == simdefs.SITUATION_COMBAT then
		if unit:getTraits().vip then
			subtext = STRINGS.GUARD_STATUS.FLEEING
		else
			subtext = STRINGS.GUARD_STATUS.COMBAT
		end
	elseif brainClassType == simdefs.SITUATION_IDLE then
		if not unit:getTraits().patrolPath
			or (#unit:getTraits().patrolPath == 1 and unit:getTraits().patrolPath[1].x == x0 and unit:getTraits().patrolPath[1].y == y0) then
			subtext = STRINGS.GUARD_STATUS.IDLE
		else
			subtext = STRINGS.GUARD_STATUS.PATROLLING
		end
	else
		subtext = "UNKNOWN"
	end

    unit:createTab( STRINGS.GUARD_STATUS.STATUS, subtext )
end


local observePath = 
	{
		name = STRINGS.ABILITIES.OBSERVE, 

		createToolTip = function( self, sim, abilityOwner, abilityUser, targetID )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.OBSERVE, STRINGS.ABILITIES.OBSERVE_DESC)
		end,

		profile_icon = "gui/items/icon-action_peek.png",
		getName = function( self, sim, unit )
			return self.name
		end,

        canUseWhileDragging = true,

        isTarget = function( self, userUnit, targetUnit )
        	if targetUnit:getTraits().noObserve then
				return false
			end 
			if not targetUnit:getPather() then
				return false
			end 
			if targetUnit:getTraits().patrolObserved then 
				return false
			end 
			if not simquery.isEnemyTarget( userUnit:getPlayerOwner(), targetUnit ) then 
				return false 
			end
			if targetUnit:isKO() or targetUnit:isDead() then
				return false
			end

            return true
        end,

		acquireTargets = function( self, targets, game, sim, unit, userUnit )
			if config.RECORD_MODE then
				return nil
			end

			local units = {}
			local x0, y0 = userUnit:getLocation()
			for _, targetUnit in pairs(sim:getAllUnits()) do
				if self:isTarget( userUnit, targetUnit ) then
					if sim:canUnitSeeUnit( userUnit, targetUnit ) then
						table.insert( units, targetUnit )
					else
						for _, cameraUnit in pairs(sim:getAllUnits()) do 
							if (cameraUnit:getTraits().mainframe_camera or cameraUnit:getTraits().isDrone) and cameraUnit:getPlayerOwner() == sim:getCurrentPlayer() then 
								if sim:canUnitSeeUnit(cameraUnit, targetUnit) then 
									table.insert( units, targetUnit )
                                    break
								end
                            elseif cameraUnit:getTraits().peekID == userUnit:getID() and sim:canUnitSeeUnit( cameraUnit, targetUnit ) then
								table.insert( units, targetUnit )
                                break
							end
						end
					end
				end
			end 

			return targets.unitTarget( game, units, self, unit, userUnit )
		end,

		usesMP = true,

		canUseAbility = function( self, sim, unit, userUnit, targetID )
			if targetID then 
				local targetUnit = sim:getUnit( targetID )
                if not self:isTarget( userUnit, targetUnit ) then
                    return false
                end

				if unit:getMP() < 1 then
					return false, string.format(STRINGS.UI.REASON.REQUIRES_AP,1)
				end
			end

			return true 
		end, 

		executeAbility = function( self, sim, unit, userUnit, target )
			local target = sim:getUnit(target)

			unit:useMP(1, sim)
			target:getTraits().patrolObserved = true
            createObserveTab( target )
			sim:dispatchEvent( simdefs.EV_UNIT_OBSERVED, target )
		end
	}
return observePath
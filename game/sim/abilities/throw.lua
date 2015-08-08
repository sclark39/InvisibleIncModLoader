local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local inventory = include("sim/inventory")
local speechdefs = include("sim/speechdefs")
local abilityutil = include( "sim/abilities/abilityutil" )
local mathutil = include( "modules/mathutil" )
local unitdefs = include("sim/unitdefs")
local simfactory = include( "sim/simfactory" )

local throw =
	{
		name = STRINGS.ABILITIES.THROW,

		getName = function( self, sim, unit, userUnit )
			return self.name
		end,
	
		createToolTip = function( self,sim,unit,targetCell)
			return abilityutil.formatToolTip( STRINGS.ABILITIES.THROW,  STRINGS.ABILITIES.THROW_DESC, 1 )
		end,
	
		profile_icon = "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png",
		usesAction = true,

		acquireTargets = function( self, targets, game, sim, grenadeUnit, unit)
			if not self:canUseAbility( sim, grenadeUnit, unit ) then
				return nil
			end
			return targets.throwTarget( game, grenadeUnit:getTraits().range or 0, sim, unit, unit:getTraits().maxThrow, grenadeUnit:getTraits().targeting_ignoreLOS)
		end, 


		canUseAbility = function( self, sim, grenadeUnit, unit, targetCell )
            if unit:getTraits().movingBody then
                return false, STRINGS.UI.REASON.DROP_BODY_TO_USE
            end

			if grenadeUnit:getTraits().pwrCost and (ownerUnit:getPlayerOwner():isPC() and ownerUnit:getPlayerOwner():getCpus() < grenadeUnit:getTraits().pwrCost) then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if grenadeUnit:getTraits().cooldown and grenadeUnit:getTraits().cooldown > 0 then
				return false, util.sformat(STRINGS.UI.REASON.COOLDOWN,grenadeUnit:getTraits().cooldown)
			end

			if targetCell then
				local targetX,targetY = unpack(targetCell)
				local unitX, unitY = unit:getLocation()
	    		local raycastX, raycastY = sim:getLOS():raycast(unitX, unitY, targetX, targetY)
				if raycastX ~= targetX or raycastY ~= targetY then
					return false
				end
			end

			return true
		end,

		executeAbility = function( self, sim, grenadeUnit, userUnit, targetCell )
			local sim = grenadeUnit:getSim()
			local x0,y0 = userUnit:getLocation()
			local x1,y1 = unpack(targetCell)
			userUnit:getTraits().throwing = true
		
			local facing = simquery.getDirectionFromDelta(x1-x0, y1-y0)
			simquery.suggestAgentFacing(userUnit, facing)
			if userUnit:getBrain() then	
				if grenadeUnit:getTraits().baseDamage then
					sim:emitSpeech(userUnit, speechdefs.HUNT_GRENADE)
				end
				sim:refreshUnitLOS( userUnit )
				sim:processReactions( userUnit )
			end

			if userUnit:isValid() and not userUnit:getTraits().interrupted then
				sim:dispatchEvent( simdefs.EV_UNIT_THROW, { unit = userUnit, x1=x1, y1=y1, facing=facing } )
				
				if grenadeUnit:getTraits().throwUnit then
					--npcs throw grenades without using them up
					local template = unitdefs.lookupTemplate( grenadeUnit:getTraits().throwUnit )
					assert( template, string.format("Could not find template '%s'", grenadeUnit:getTraits().throwUnit) )
					local unitData = util.extend( template )( {} )
					local unit = simfactory.createUnit( unitData, sim )
					sim:spawnUnit( unit )
					local cell = sim:getCell(x0, y0)
					sim:warpUnit( unit, cell )
					grenadeUnit = unit
				else
					inventory.dropItem( sim, userUnit, grenadeUnit )
				end
			
				
				if grenadeUnit:getTraits().shouldNpcThrow and userUnit:getBrain() then
					local interest = userUnit:getBrain():getInterest()
					if interest then
						interest.grenadeHit = true
						if grenadeUnit:getTraits().scan then
							interest.scanned = true
						end
					end
				end
	
				if grenadeUnit.throw then
					grenadeUnit:throw(userUnit, sim:getCell(x1, y1) )
				end

				sim:dispatchEvent( simdefs.EV_UNIT_STOP_THROW, { unitID = userUnit:getID(), x1=x1, y1=y1, facing=facing } )


				sim:processReactions( userUnit )
			end
			userUnit:getTraits().throwing = nil
			if userUnit:isValid() and not userUnit:getTraits().interrupted then
				simquery.suggestAgentFacing(userUnit, facing)
			end
		end
	}

return throw

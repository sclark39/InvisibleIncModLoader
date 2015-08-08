local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local mathutil = include( "modules/mathutil" )

local meleeOverwatch =
	{
		name = STRINGS.ABILITIES.MELEE_OVERWATCH,
		createToolTip = function( self )
			return abilityutil.formatToolTip( STRINGS.ABILITIES.MELEE_OVERWATCH,  STRINGS.ABILITIES.MELEE_OVERWATCH_DESC, 1 )
		end,

		getName = function( self, sim, unit )
			return self.name
		end,

		onSpawnAbility = function( self, sim, unit )
			sim:addTrigger( simdefs.TRG_OVERWATCH, self, unit )			
		end,

		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_OVERWATCH, self )
		end,
		
		onTrigger = function( self, sim, evType, evData, userUnit )

			if evType == simdefs.TRG_OVERWATCH and userUnit and userUnit:getTraits().isMeleeAiming and not simquery.isUnitPinning( sim, userUnit ) then
				local targetUnit = evData
				local userPlayer = userUnit:getPlayerOwner()

				if targetUnit and targetUnit:isValid() and not targetUnit:isKO() then
					local doOverwatch = false
					if	(userPlayer ~= sim:getCurrentPlayer() and simquery.isEnemyAgent( userPlayer, targetUnit )) or userUnit:getTraits().shootIndiscriminate  then
						doOverwatch = true
					end
					
					local canUse, reason1,reason2, floatTxt =  self:canUseAbility( sim, userUnit, targetUnit, true ) 

					if floatTxt then
						local x0,y0 = userUnit:getLocation()
						sim:dispatchEvent( simdefs.EV_UNIT_FLOAT_TXT, {txt=floatTxt,x=x0,y=y0,color={r=1,g=1,b=41/255,a=1}, skipQue=true} )
					end

					if doOverwatch and canUse and sim:canUnitSeeUnit( userUnit, targetUnit ) then											
						self:executeAbility( sim, userUnit, targetUnit )
					end
				end
			end
		end,

		canUseAbility = function( self, sim, userUnit, targetUnit ) 
			local meleeAbility = userUnit:hasAbility("melee")
			if meleeAbility == nil then
				return false
			end
			return meleeAbility:canUseAbility( sim, userUnit, userUnit, targetUnit:getID() )
		end,

		executeAbility = function( self, sim, userUnit, targetUnit)
			userUnit:setInvisible(false)
			userUnit:setDisguise(false)

			if targetUnit:getPlayerOwner() then
				targetUnit:getPlayerOwner():glimpseUnit( sim, userUnit:getID() )
			end			
			
			userUnit:resetAllAiming()
			userUnit:hasAbility("melee"):getDef():executeAbility( sim, userUnit, userUnit, targetUnit:getID() )
			
			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit  } )
		end
		
	}

return meleeOverwatch
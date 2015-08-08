local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local console_lvl = 
	{
		name = STRINGS.ABILITIES.NT, 
		createTooltip = function( self, sim, unit )
			return abilityutil.formatToolTip(STRINGS.ABILITIES.NT, STRINGS.ABILITIES.NT, 0)
		end, 

		getName = function( self, sim, unit, userUnit )
			return STRINGS.ABILITIES.NT
		end, 

		canUseAbility = function( self, sim, unit, userUnit )
			return true 
		end, 

		onSpawnAbility = function( self, sim, unit )
			sim:addTrigger( simdefs.TRG_START_TURN, self, unit )			
		end,

		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_START_TURN, self )
		end,
		
		onTrigger = function( self, sim, evType, evData, userUnit )

			if userUnit:getTraits().hijacked == true then 
				-- Do nothing 
			elseif evType == simdefs.TRG_START_TURN and not evData:isNPC() then
				userUnit:getTraits().lvlTurns = userUnit:getTraits().lvlTurns - 1 
				if userUnit:getTraits().lvlTurns <= 0 then 
					userUnit:getTraits().cpus = userUnit:getTraits().cpus + 1 
					userUnit:getTraits().lvlTurns = userUnit:getTraits().maxLvlTurns
				end
			end

		end,
	}
return console_lvl
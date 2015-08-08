local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local 	generateCPU =
	{
		name = STRINGS.ABILITIES.GENERATE_PWR,

		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip( STRINGS.ABILITIES.GENERATE_PWR, util.sformat(STRINGS.ABILITIES.GENERATE_PWR_DESC, unit:getTraits().cpus),1)
		end,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			return self.name
		end,
		
		profile_icon = nil,

		automatic = true,

		canUseAbility = function( self, sim, abilityOwner, unit )
			return true
		end,

		-- Mainframe system.

		executeAbility = function( self, sim, abilityOwner, unit, targetUnitID )
			local x0,y0 = unit:getLocation()
			if x0 and y0 then
				unit:getTraits().cpuTurn = unit:getTraits().cpuTurn - 1
				if unit:getTraits().cpuTurn <= 0 then 
					unit:getPlayerOwner():addCPUs( unit:getTraits().cpus )
					unit:getTraits().cpuTurn = unit:getTraits().cpuTurnMax
					sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.PLUS_PWR, unit:getTraits().cpus), x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
				end
			end
		end,

	}
return generateCPU
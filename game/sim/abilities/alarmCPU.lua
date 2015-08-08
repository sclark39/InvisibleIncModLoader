local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local abilityutil = include( "sim/abilities/abilityutil" )

local generateCPU =
	{
		name = STRINGS.ABILITIES.GENERATE_PWR,

		createToolTip = function( self, sim, unit )
			return abilityutil.formatToolTip( STRINGS.ABILITIES.GENERATE_PWR, util.sformat(STRINGS.ABILITIES.GENERATE_PWR_DESC, unit:getTraits().cpus),1)
		end,

		getName = function( self, sim, abilityOwner, abilityUser, targetUnitID )
			return self.name
		end,

		onSpawnAbility = function( self, sim, unit )
			sim:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
			self.abilityOwner = unit
		end, 

		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )
		end,
		
		profile_icon = nil,

		canUseAbility = function( self, sim, abilityOwner, unit )
			return true
		end,

		-- Mainframe system.

		onTrigger = function( self, sim, evType, evData, userUnit )
			local x0,y0 = self.abilityOwner:getLocation()
			if x0 and y0 then
				local cpus = sim:getTrackerStage() * 2
	            if self.abilityOwner:getPlayerOwner() then
				    self.abilityOwner:getPlayerOwner():addCPUs( cpus )
	            end
				sim:dispatchEvent( simdefs.EV_UNIT_FLY_TXT, {txt=util.sformat(STRINGS.UI.FLY_TXT.PLUS_PWR, cpus), x=x0,y=y0, color={r=163/255,g=243/255,b=248/255,a=1},} )
			end
		end,

	}
return generateCPU
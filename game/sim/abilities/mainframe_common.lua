local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "client_util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")
local cdefs = include( "client_defs" )
local mainframe = include( "sim/mainframe" )
local modifiers = include( "sim/modifiers" )
local mission_util = include( "sim/missions/mission_util" )
local serverdefs = include("modules/serverdefs")

local SEED_DISCOUNT = 4


local DEFAULT_ABILITY_DAEMON =
{

	getDuration = function(self, sim, duration)
		local player = sim:getPC()
		print("duration",duration,"MODD",player:getTraits().daemonDurationModd)
		return math.max(duration + (player:getTraits().daemonDurationModd or 0),1)
	end,

	canUseAbility = function( self, sim, player )
		-- Even though these are NPC abilities, only the PC can "use them" (eg. break the ice)
		return sim:getPC():getCpus() > 0
	end,

	onTooltip = function( self, hud, sim, player )
		local tooltip = util.tooltip( hud._screen )
		local section = tooltip:addSection()

		section:addLine( self.name )
		section:addAbility( self.shortdesc, self.desc, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )

		return tooltip
	end,

	onTrigger = function( self, sim, evType, evData, userUnit )
		if evType == simdefs.TRG_END_TURN then
			local player = evData
			if player == sim:getCurrentPlayer() and player:isNPC() then
				if self.turns then
					self.turns = self.turns - 1
				
					if (self.turns or 0) == 0 then
						self:executeTimedAbility( sim, player )
					end					
				end
				if self.duration then
					self.duration = self.duration - 1
					if (self.duration or 0) == 0 then
						self:executeTimedAbility( sim, player )
					end
				end
				if self.perpetual then
					self:executeTimedAbility( sim, player )
				end
			end
		end
	
	end,
}


local common = 
{
	DEFAULT_ABILITY =
	{
		name = nil, -- Override
		desc = nil, -- Override
		cpu_cost = 0, -- Override
		credit_cost = 0, -- Override
	    value = 0, -- Override
		program_strength = 0, --Override 
		break_firewalls = 0, --Override
		equip_program = false, 
		program = true, 


		getCpuCost = function( self )
			local cpuCost = self.cpu_cost
			local zeroCpu = false

			if cpuCost == 0 then 
				zeroCpu = true 
			end

	        if self._sim then

	        	local pwrModd = 0
				for i, ability in ipairs( self._sim:getPC():getAbilities())do
					if ability.pwrMod then
						pwrModd = pwrModd + ability.pwrMod
					end
				end

	            -- Player cost modifier is min-capped at 1, but this doesn't apply to SEED.
	            if zeroCpu then 
	            	cpuCost = math.max(0, cpuCost + (self._sim:getPC():getTraits().program_cost_modifier or 0))
	            else 
	            	cpuCost = math.max(1, cpuCost + (self._sim:getPC():getTraits().program_cost_modifier or 0))
	            end 
				cpuCost = cpuCost  + (pwrModd or 0)

	            if (self._sim:getTags().nextProgFree or 0) > 0 then
	        	    cpuCost = cpuCost - SEED_DISCOUNT
	            end
	        end

	   		return math.max(0, cpuCost)
		end,

		onTooltip = function( self, screen, sim, player )
			local tooltip = util.tooltip( screen )
			local section = tooltip:addSection()

			local sub = ""


			if self:getCpuCost() > 0 then 
				sub = util.sformat( STRINGS.PROGRAMS.POWER, self:getCpuCost() )							
			end 

			section:addLine( "<ttheader>"..self.name.."</>",sub)
			
			if self.maxCooldown and self.maxCooldown > 0  then
				section:addLine( util.sformat( STRINGS.PROGRAMS.COOLDOWN, self.maxCooldown )  )
			end

			if self.equipped then
				section:addLine( STRINGS.PROGRAMS.EQUIPPED, string.format( "" ))
			end

	   		section:addAbility( self.shortdesc, self.desc, "gui/icons/action_icons/Action_icon_Small/icon-item_shoot_small.png" )

	        if sim then
			    local canUse, reason = self:canUseAbility( sim, player )
			    if not canUse and reason then
				    section:addRequirement( reason )
			    end
	        end

			return tooltip
		end,

		canUseAbility = function( self, sim, abilityOwner, targetUnit )
			local player = sim:getCurrentPlayer()
			if player == nil or player ~= abilityOwner then
				return false
			end

			if (self.cooldown or 0) > 0 then 
				return false, STRINGS.UI.REASON.EQUIPPED_ON_COOLDOWN
			end

			if player:getCpus() < self:getCpuCost() then 
				return false, STRINGS.UI.REASON.NOT_ENOUGH_PWR
			end

			if player:getCredits() < self.credit_cost then
				return false, STRINGS.UI.REASON.NOT_ENOUGH_CREDITS
			end

			if sim:getMainframeLockout() then 
				return false, STRINGS.UI.REASON.INCOGNITA_LOCKED_DOWN
			end 

			for i, x in ipairs(player:getAbilities()) do 
				if x == self then 
					for j, y in ipairs(player:getLockedAbilities()) do 
						if y == i then 
							return false, STRINGS.ABILITIES.TEMPORARY_LOSS 
						end 
					end 
				end 
			end 

			return true 
		end,

	   	setEquipped = function( self, isEquipped )
			self.equipped = isEquipped
		end,

		setCooldown = function(self,sim)
				local hasCooldown = false
				local coolDownMod = 0
				
				self.cooldown = 0

				if self.maxCooldown and self.maxCooldown > 0 then 
					hasCooldown = true
					self.cooldown = self.maxCooldown
				end
				for i, ability in ipairs(sim:getPC():getAbilities())do
					if ability.coolDownMod then
						if ability.coolDownMod > 0 then
							hasCooldown = true
						end
						coolDownMod = coolDownMod + ability.coolDownMod
					end
				end

				if coolDownMod ~= 0 or hasCooldown then
					local min = 0
					if hasCooldown then
						min = 1
					end
					self.cooldown = math.max(self.cooldown + coolDownMod,min) 					
				end	
		end,

	    useCPUs = function( self, sim )
	        local cdefs = include("client_defs")
	        local cpus = self:getCpuCost()
	        if (sim:getTags().nextProgFree or 0) > 0 then
	            -- Find a seed program with no cooldown.
	            for i, ability in ipairs(sim:getCurrentPlayer():getAbilities()) do
	                if ability:getID() == "seed" and (ability.cooldown or 0) <= 0 then
	                    ability:executeAbility( sim )
	                    break
	                end
	            end
	        end

	        sim:getCurrentPlayer():addCPUs( -cpus, sim )
	    end,

		onTrigger = function( self, sim, evType, evData )
			if evType == simdefs.TRG_START_TURN then		
				if self.cooldown and self.cooldown > 0 and evData:isPC() then 
					self.cooldown = self.cooldown - 1
				end	
			end
		end,

		onSpawnAbility = function( self, sim )
			sim:addTrigger( simdefs.TRG_START_TURN, self )		
		end, 

	    onDespawnAbility = function( self, sim )
	        if sim:isVersion( "0.17.3" ) then
	            sim:removeTrigger( simdefs.TRG_START_TURN, self )
	        end
	    end,

		executeAbility = function( self, sim, targetUnit )
	        self:useCPUs( sim )

	        local firewallsToBreak = self.break_firewalls

	        if sim:getPC():getTraits().firewallBreakPenalty and firewallsToBreak > 0 then
	        	firewallsToBreak = math.max(firewallsToBreak-sim:getPC():getTraits().firewallBreakPenalty,1)
	        end

	        if targetUnit and (firewallsToBreak or 0) > 0 then
	            mainframe.breakIce( sim, targetUnit, firewallsToBreak )
	        end
	       	self:setCooldown( sim )
		end,		
	},

	DEFAULT_ABILITY_DAEMON = DEFAULT_ABILITY_DAEMON,

	createDaemon = function( stringTbl )
		return util.extend( DEFAULT_ABILITY_DAEMON )
		{
			name = stringTbl.NAME,
			desc = stringTbl.DESC,
			shortdesc = stringTbl.SHORT_DESC,
			activedesc = stringTbl.ACTIVE_DESC,
			standardDaemon = true,
		}
	end,

	createReverseDaemon = function( stringTbl )
		return util.extend( DEFAULT_ABILITY_DAEMON )
		{
			name = stringTbl.NAME,
			desc = stringTbl.DESC,
			shortdesc = stringTbl.SHORT_DESC,
			activedesc = stringTbl.ACTIVE_DESC,
			reverseDaemon = true,
		}
	end,

	createCountermeasureInterest = function( daemon, sim, agent )
		if agent then
			local x2,y2 = agent:getLocation()
			local guard = sim:getNPC():spawnInterestWithReturn(x2,y2, simdefs.SENSE_RADIO, simdefs.REASON_CAMERA, agent, daemon._guardsTagged)
			if guard and guard:isValid() and agent then
				table.insert( daemon._guardsTagged, guard:getID() ) 
				agent:getSim():dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "locationDetectedDialog", dialogParams = { agent }} )
			end		
		end
	end, 

}
return common

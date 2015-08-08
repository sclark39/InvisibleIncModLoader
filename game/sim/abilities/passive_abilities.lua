local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include("sim/simdefs")
local simquery = include("sim/simquery")

-------------------------------------------------------------------------------
-- These are passive abilities (no executeAbility function)

local function formatToolTip( header, body )
	return string.format( "<ttheader>%s\n<ttbody>%s</>", util.toupper(header), body )
end

local DEFAULT_PASSIVE =
{
	getName = function( self, sim, unit )
		return self.name
	end,
		
	createToolTip = function( self,sim,unit,targetUnit)
		return formatToolTip( self.name, string.format("PASSIVE\n%s", self.desc ) )
	end,

	canUseAbility = function( self, sim, unit )
		return false -- Passives are never 'usd'
	end,

	executeAbility = nil, -- Passives by definition have no execute.
}

local DEFAULT_DEBUFF =
{
	debuffAbility = true, 

	getName = function( self, sim, unit )
		return self.name
	end,
		
	createToolTip = function( self,sim,unit,targetUnit)
		return formatToolTip( self.name, string.format("DEBUFF\n%s", self.desc ) )
	end,

	canUseAbility = function( self, sim, unit )
		return false -- Passives are never 'used'
	end,

	executeAbility = nil, -- Passives by definition have no execute.
}

local DEFAULT_BUFF =
{
	buffAbility = true, 

	getName = function( self, sim, unit )
		return self.name
	end,
		
	createToolTip = function( self,sim,unit,targetUnit)
		return formatToolTip( self.name, string.format("BUFF\n%s", self.desc ) )
	end,

	canUseAbility = function( self, sim, unit )
		return false -- Passives are never 'used'
	end,

	executeAbility = nil, -- Passives by definition have no execute.
}

local passive_abilities =
{

	--PERMANENT CYBORG BUFFS (final level)
	neural_implants_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.NEURAL_IMPLANTS.NAME, 
		buffDesc = STRINGS.RESEARCH.NEURAL_IMPLANTS.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().canKO = false 	
		end, 
	},

	ultrasonic_echolocation_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.ULTRASONIC_ECHOLOCATION.NAME, 
		buffDesc = STRINGS.RESEARCH.ULTRASONIC_ECHOLOCATION.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().seesHidden = true 
		end, 
	},

	sprint_pads_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.SPRINT_PADS.NAME, 
		buffDesc = STRINGS.RESEARCH.SPRINT_PADS.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().mpMax = unit:getTraits().mpMax + 6
		end, 
	},

	regenerative_nanocells_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.REGENERATIVE_NANOCELLS.NAME, 
		buffDesc = STRINGS.RESEARCH.REGENERATIVE_NANOCELLS.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().regenerative_nanocells = true 
		end, 
	},

	improved_heart_monitor_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.IMPROVED_HEART_MONITOR.NAME, 
		buffDesc = STRINGS.RESEARCH.IMPROVED_HEART_MONITOR.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().improved_heart_monitor = true 
		end, 
	},

	consciousness_monitor_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.CONSCIOUSNESS_MONITOR.NAME, 
		buffDesc = STRINGS.RESEARCH.CONSCIOUSNESS_MONITOR.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().consciousness_monitor = true 
		end, 
	},

	peripheral_expansion_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.PERIPHERAL_EXPANSION.NAME, 
		buffDesc = STRINGS.RESEARCH.PERIPHERAL_EXPANSION.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().LOSarc = math.pi*2
		end, 
	},

	peripheral_improvement_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.PERIPHERAL_IMPROVEMENT.NAME, 
		buffDesc = STRINGS.RESEARCH.PERIPHERAL_IMPROVEMENT.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().LOSperipheralArc = math.pi
		end, 
	},

	overtuned_reflexes_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.OVERTUNED_REFLEXES.NAME, 
		buffDesc = STRINGS.RESEARCH.OVERTUNED_REFLEXES.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().skipOverwatch = true 
		end, 
	},

	ultraviolet_spectrometer_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.ULTRAVIOLET_SPECTROMETER.NAME, 
		buffDesc = STRINGS.RESEARCH.ULTRAVIOLET_SPECTROMETER.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().detect_cloak = true 
		end, 
	},

	mainframe_attunement_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.MAINFRAME_ATTUNEMENT.NAME, 
		buffDesc = STRINGS.RESEARCH.MAINFRAME_ATTUNEMENT.UNIT_DESC, 

		onSpawnAbility = function( self, sim, unit )
			sim:addTrigger( simdefs.TRG_ICE_BROKEN, self, unit )
			local ice = unit:getTraits().mainframe_ice
			local ap = 6 + ice
 

			unit:getTraits().mpMax = ap 
			if unit:getTraits().mp > ap then 
				unit:getTraits().mp = ap 
			end 

			sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = unit } )			
		end,

		onDespawnAbility = function( self, sim, unit )
			sim:removeTrigger( simdefs.TRG_ICE_BROKEN, self )
		end,

		onTrigger = function( self, sim, evType, evData, userUnit )
			if evType == simdefs.TRG_ICE_BROKEN then 
				if evData.unit == userUnit then 

					-- 90 Degrees at 0, 360 at 8
					-- 6 AP at 0, 14 at 8. 
					local ice = userUnit:getTraits().mainframe_ice
					local ap = 6 + ice 

					userUnit:getTraits().mpMax = ap 
					if userUnit:getTraits().mp > ap then 
						userUnit:getTraits().mp = ap 
					end 

					sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = userUnit } )
				end 
			end 
		end, 
	},

	recon_protocol_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.RECON_PROTOCOL.NAME, 
		buffDesc = STRINGS.RESEARCH.RECON_PROTOCOL.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().reconPatrol = true 
		end, 
	},

	enhanced_armor_passive = util.extend( DEFAULT_BUFF )
	{
		name = STRINGS.RESEARCH.ENHANCED_ARMOR.NAME, 
		buffDesc = STRINGS.RESEARCH.ENHANCED_ARMOR.UNIT_DESC, 
		onSpawnAbility = function( self, sim, unit )
			unit:getTraits().armor = unit:getTraits().armor + 1 
		end, 
	},
}

return passive_abilities

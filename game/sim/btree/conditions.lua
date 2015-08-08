local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

--[[
Conditions are most commonly used to gate the start of a sequence of actions.
A condition can check values in the sim or current unit and returns
true or false. If no value is returned, the condition returns false by default.
]]--

local Conditions = {}

function Conditions.HasCombat(sim, unit)
	return unit:getBrain():getSituation().ClassType == simdefs.SITUATION_COMBAT
end

function Conditions.HasHunt(sim, unit)
	return unit:getBrain():getSituation().ClassType == simdefs.SITUATION_HUNT
end

function Conditions.NewInterest(sim, unit)
	return unit:getBrain():getSenses():getCurrentInterest() ~= unit:getBrain():getInterest()
end

function Conditions.HasIdle(sim, unit)
	return unit:getBrain():getSituation().ClassType == simdefs.SITUATION_IDLE
end

function Conditions.TargetIsConscious(sim, unit)
	return unit:getBrain():getTarget() and not unit:getBrain():getTarget():isKO()
end

function Conditions.CanShootTarget(sim, unit)
	return unit:getBrain():getTarget() and simquery.isShootable(unit, unit:getBrain():getTarget() )
end

function Conditions.HasTarget(sim, unit)
	return unit:getBrain():getTarget() ~= nil
end

function Conditions.HasInterest(sim, unit)
	return unit:getBrain():getInterest() ~= nil
end

function Conditions.AwareOfAgent(sim, unit)
	if unit:getBrain():getTarget() ~= nil then
		return true
	end

	if unit:getBrain():getInterest() and unit:getBrain():getInterest().reason == simdefs.REASON_LOSTTARGET and not unit:getBrain():getInterest().investigated then
		return true
	end
end

function Conditions.IsAlerted(sim, unit)
	return unit:isAlerted() == true
end

function Conditions.IsUnitPinning(sim, unit)
	return simquery.isUnitPinning(sim, unit)
end
return Conditions

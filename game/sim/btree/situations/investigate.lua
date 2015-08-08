local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local astar = include( "modules/astar" )
local speechdefs = include( "sim/speechdefs" )
local Situation = include( "sim/btree/situation" )

local InvestigateSituation = class(Situation, function(self, unit, interest)
	self.ClassType = simdefs.SITUATION_INVESTIGATE
	Situation.init(self)
	self.interest = interest
	self.roles = {}
end)

function InvestigateSituation:findDetective()
	for k,v in pairs(self.roles) do
		if v == simdefs.INVESTIGATE_DETECTIVE then
			return v
		end
	end
end

function InvestigateSituation:findSentry()
	for k,v in pairs(self.roles) do
		if v == simdefs.INVESTIGATE_SENTRY then
			return v
		end
	end
end

function InvestigateSituation:getRole(unit)
	return self.roles[unit:getID()]
end

function InvestigateSituation:getInterest()
	return self.interest
end

function InvestigateSituation:addUnit(unit)
	Situation.addUnit(self, unit)

	if unit._sim._resultTable.guards[unit:getID()] then
		unit._sim._resultTable.guards[unit:getID()].distracted = true
	end

	unit:getTraits().thoughtVis = "investigating"
	unit:getTraits().walk = not unit:getTraits().enforcer
	if not self:findDetective() then
		self.roles[unit:getID()] = simdefs.INVESTIGATE_DETECTIVE
	elseif not self:findSentry() then
		self.roles[unit:getID()] = simdefs.INVESTIGATE_SENTRY
	else
		self.roles[unit:getID()] = simdefs.INVESTIGATE_BYSTANDER
	end
end

function InvestigateSituation:removeUnit(unit)
	Situation.removeUnit(self, unit)

	unit:getTraits().thoughtVis = nil

	if self:getRole(unit) == simdefs.INVESTIGATE_DETECTIVE then
		local sentry = self:findSentry()
		if sentry then
			self.roles[unit:getID()] = simdefs.INVESTIGATE_DETECTIVE
		end
	elseif self:getRole(unit) == simdefs.INVESTIGATE_SENTRY then
		local newSentry = nil
		for k,v in pairs(self.roles) do
			if not newSentry and v == simdefs.INVESTIGATE_BYSTANDER then
				v = simdefs.INVESTIGATE_SENTRY
				newSentry = k
			end
		end
	end
end

function InvestigateSituation:markInterestInvestigated(unit)
	if self.interest then
		self.interest.investigated = true
		unit:getBrain():getSenses():markInterestsInvestigated(self.interest.x, self.interest.y)
		if self.interest.sourceUnit then
			self.interest.sourceUnit:setInvestigated(unit)
		end
	end
end

return InvestigateSituation

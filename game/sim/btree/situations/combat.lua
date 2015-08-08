local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local astar = include( "modules/astar" )
local speechdefs = include( "sim/speechdefs" )
local Situation = include( "sim/btree/situation" )


local CombatSituation = class(Situation, function(self)
	self.ClassType = simdefs.SITUATION_COMBAT
	self.targets = {}
	self.assignedTargets = {}
	Situation.init(self)
end)

function CombatSituation:isValid()
	if not Situation.isValid(self) then
		return false
	end
	for k,v in pairs(self.targets) do
		if self:isTargetValid(v) then
			return true
		end
	end
	return false
end

function CombatSituation:addUnit(unit)
	Situation.addUnit(self, unit)

	if unit:getTraits().camera_drone then
		unit:getTraits().thoughtVis = "hunting"
	elseif unit:getTraits().vip then
		unit:getTraits().thoughtVis = "fleeing"
	else
		unit:getTraits().thoughtVis = "combat"
	end
	unit:getTraits().walk = false
	unit:getTraits().noKO = (unit:getTraits().noKO or 0) + 1
end

function CombatSituation:removeUnit(unit)
	Situation.removeUnit(self, unit)

	unit:getTraits().thoughtVis = nil
	unit:getBrain():setDestination(nil)
end

function CombatSituation:isTargetValid(target)
	return target:isValid() and not target:isDead() and not target:isKO()
end

function CombatSituation:hasTarget(target)
	return self.targets[target:getID()] ~= nil
end

function CombatSituation:addTarget(target, unit)
	assert(target)
	if not self:hasTarget(target) then
		log:write(simdefs.LOG_SIT, "adding target [%s] to CombatSituation %s", tostring(target:getID() ), tostring(self) )
		self.targets[target:getID()] = target
	end
	if unit and self.assignedTargets[unit:getID() ] ~= target then
		log:write(simdefs.LOG_SIT, "assigning target [%s] to unit [%s]", tostring(target:getID() ), tostring(unit:getID() ) )
		self.assignedTargets[unit:getID() ] = target
	end
end

function CombatSituation:getAssignedTarget(unit)
	return self.assignedTargets[unit:getID()]
end


function CombatSituation:assignTarget(unit)
	local weapon = simquery.getEquippedGun( unit )
	local x0, y0 = unit:getLocation()
	local candidates = {}

	local currentTarget = self.assignedTargets[unit:getID()]
	if currentTarget and weapon
	 and not currentTarget:isKO()
	 and not currentTarget:isDead() then
		local dist = mathutil.distSqr2d( x0, y0, currentTarget:getLocation() )
		local damage = nil
	 	if weapon then
			local shot = simquery.calculateShotSuccess( unit:getSim(), unit, currentTarget, weapon )
			damage = shot.damage
		else
			damage = simquery.calculateMeleeDamage(unit:getSim(), weapon, currentTarget)
		end
		table.insert(candidates, {unit=currentTarget, dist=dist, damage=damage})
	end

	for unitID, targetUnit in pairs(self.targets) do
		if unit:getSim():canUnitSeeUnit( unit, targetUnit )
		 and not targetUnit:isKO()
		 and not targetUnit:isDead() then
			local dist = mathutil.distSqr2d( x0, y0, targetUnit:getLocation() )
			local damage = nil
		 	if weapon then
				local shot = simquery.calculateShotSuccess( unit:getSim(), unit, targetUnit, weapon )
				damage=shot.damage
			else
				damage = simquery.calculateMeleeDamage(unit:getSim(), weapon, targetUnit)
			end
			table.insert( candidates, {unit=targetUnit, dist=dist, damage=damage} )
		end
	end

	table.sort( candidates,
		function( a, b )
			if a.damage == b.damage then
				return a.dist < b.dist
			else
				return a.damage < b.damage
			end
		end)

	if #candidates > 0 then
		self.assignedTargets[unit:getID()] = candidates[1].unit
		return self:getAssignedTarget(unit)
	end
end

return CombatSituation

local simdefs = include( "sim/simdefs" )

local Situation = class(function(self)
	self.units = {}
end)

function Situation:hasUnit(unit)
	return self.units[unit:getID()] ~= nil
end

function Situation:isUnitValid(unit)
	return unit:isValid() and not unit:isDead() and not unit:isKO()
end

function Situation:isValid()
	return next(self.units) ~= nil
end

function Situation:addUnit(unit)
	log:write(simdefs.LOG_SIT, "adding [%s] to %s situation", tostring(unit and unit:getID() ), self.ClassType)
	assert(self.units[unit:getID()] == nil )
	self.units[unit:getID()] = unit
end

function Situation:removeUnit(unit)
	log:write(simdefs.LOG_SIT, "removing [%s] from %s situation", tostring(unit and unit:getID() ), self.ClassType)
	assert( self.units[ unit:getID() ] ~= nil )
	self.units[unit:getID()] = nil
end

return Situation
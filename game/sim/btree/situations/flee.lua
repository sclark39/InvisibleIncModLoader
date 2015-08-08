local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local astar = include( "modules/astar" )
local speechdefs = include( "sim/speechdefs" )
local Situation = include( "sim/btree/situation" )

local FleeSituation = class(Situation, function(self, unit)
	self.ClassType = simdefs.SITUATION_FLEE
	Situation.init(self, self.startingRoom)
end)

function FleeSituation:addUnit(unit)
	Situation.addUnit(self, unit)

	unit:getTraits().thoughtVis = "fleeing"
	unit:getTraits().walk = false
	unit:setAlerted(true)
end

return FleeSituation

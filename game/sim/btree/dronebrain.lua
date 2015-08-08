local Brain = include("sim/btree/brain")
local btree = include("sim/btree/btree")
local actions = include("sim/btree/actions")
local conditions = include("sim/btree/conditions")
local simfactory = include( "sim/simfactory" )
local simdefs = include( "sim/simdefs" )
local speechdefs = include( "sim/speechdefs" )
local mathutil = include( "modules/mathutil" )
local simquery = include( "sim/simquery" )
local CommonBrain = include( "sim/btree/commonbrain" )

require("class")

local DroneBrain = class(Brain, function(self)
	Brain.init(self, "DroneBrain",
		btree.Selector(
		{
			CommonBrain.RangedCombat(),
			CommonBrain.Investigate(),
			CommonBrain.Patrol(),
		}))
end)
    
local function createBrain()
	return DroneBrain()
end

simfactory.register(createBrain)

return
{
	createBrain = createBrain,	
}

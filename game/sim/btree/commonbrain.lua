local Brain = include("sim/btree/brain")
local btree = include("sim/btree/btree")
local actions = include("sim/btree/actions")
local conditions = include("sim/btree/conditions")
local simfactory = include( "sim/simfactory" )
local simdefs = include( "sim/simdefs" )
local speechdefs = include( "sim/speechdefs" )
local mathutil = include( "modules/mathutil" )
local simquery = include( "sim/simquery" )

local CommonBrain = {}

CommonBrain.Patrol = function()
return
	btree.Sequence("Idle",
	{
		btree.Condition(conditions.HasIdle),
		actions.MoveToNextPatrolPoint(),
	})
end

CommonBrain.Investigate = function()
return
	btree.Sequence("Investigate/Hunt",
	{
		btree.Condition(conditions.HasInterest),
		btree.Action(actions.ReactToInterest),
		actions.MoveToInterest(),
		btree.Action(actions.MarkInterestInvestigated),
		btree.Action(actions.DoLookAround),
		btree.Sequence("Finish",
		{
			btree.Not(btree.Condition(conditions.IsUnitPinning) ),
			btree.Action(actions.RemoveInterest),
			btree.Selector("MoveOn",
			{
				btree.Sequence("Hunt",
				{
					btree.Condition(conditions.IsAlerted),
					btree.Action(actions.RequestNewHuntTarget),
				}),
				btree.Sequence("Investigate",
				{
					btree.Action(actions.FinishSearch),
				}),
			}),
		}),
	})
end

CommonBrain.Flee = function()
return
	btree.Sequence("Flee",
	{
		btree.Condition(conditions.IsAlerted),
		btree.Action(actions.Panic),
		actions.MoveToNearestExit(),
		btree.Action(actions.ExitLevel),
	})
end

CommonBrain.RangedCombat = function ()
return
	btree.Sequence("Combat",
	{
		btree.Condition(conditions.HasTarget),
		btree.Action(actions.ReactToTarget),
		btree.Condition(conditions.CanShootTarget),
		btree.Action(actions.ShootAtTarget),
	})
end

CommonBrain.MeleeCombat = function ()
return
	btree.Sequence("Combat",
	{
		btree.Condition(conditions.HasTarget),
		btree.Action(actions.ReactToTarget),
		btree.Always(btree.Sequence(
		{
			btree.Condition(conditions.TargetIsConscious),
			actions.MoveBesideTarget(),
			btree.Action(actions.MeleeTarget),
		})),
		actions.MoveToTarget(),
	})
end

CommonBrain.NoCombat = function ()
return
	btree.Sequence("NoCombat",
	{
		btree.Condition(conditions.HasTarget),
		btree.Action(actions.ReactToTarget),
		btree.Action(actions.WatchTarget),
	})
end

return CommonBrain

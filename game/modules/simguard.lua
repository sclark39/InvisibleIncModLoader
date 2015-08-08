----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

-----------------------------------------------------
-- Local

local _M =
{
	pairs = pairs,
	random = math.random,
	MOAIFmodDesigner = MOAIFmodDesigner,
    active = false
}

local function simRandom()
	assert( false, "Usage of math.random is illegal within the sim." )
end

local simMOAIFmodDesigner =
{
	__index = function( t, k )
		assert( false, "Usage of MOAIFmodDesigner is illegal within the sim.  Dispatch a sim-event to handle sound" )
	end
}
setmetatable( simMOAIFmodDesigner, simMOAIFmodDesigner )


local function simPairs( t, sortFun )
	local sorted_t = {}
	for k,v in _M.pairs(t) do
		assert(type(k) ~= "userdata" and type(k) ~= "function" and type(k) ~= "table", "Invalid sim table key type.")
		table.insert(sorted_t, {k, v})
	end
	table.sort( sorted_t, function( a, b ) return tostring(a[1]) < tostring(b[1]) end )
	
	local function iteratorFn( tt, i )
		
		local e = table.remove( tt, 1 )
		if not e then return nil end
		
		return e[1], e[2]
	end
	
	return iteratorFn, sorted_t, 0
	--return _M.pairs( t )
end

local function startGuard()
	math.random = simRandom
	--pairs = simPairs
	MOAIFmodDesigner = simMOAIFmodDesigner
    _M.active = true
end

local function finishGuard()
	math.random = _M.random
	--pairs = _M.pairs
	MOAIFmodDesigner = _M.MOAIFmodDesigner
    _M.active = false
end

local function isGuarded()
    return _M.active
end

return
{
	start = startGuard,
	finish = finishGuard,
    isGuarded = isGuarded
}
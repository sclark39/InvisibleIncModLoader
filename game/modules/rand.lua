----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local function next( self )
	-- http://remus.rutgers.edu/~rhoads/Code/random.c
	-- LUA:
	-- Our assumption is that double-precision is encoded with 64 bits (according to IEEE 754)
	-- We have enough precision to handle all 32 bit unsigned integer representations, and calculate
	-- modulo 2^32 to generate single-point precision random values.
	local a, m, q, r = 1588635695, 4294967291, 2, 1117695901
	self._seed = a*(self._seed % q) - (r*(math.floor(self._seed / q)))
	self._seed = self._seed % (2^32)
	return self._seed / m
end

local function nextInt( self, min, max )
	assert( min <= max, string.format( "%d > %d", min, max ))

	local range = max - min + 1
	return math.floor(self:next() * range) + min
end

local function nextChoice( self, t )
	if #t > 0 then
		return t[ self:nextInt( 1, #t ) ]
	end
end

local function nextNrm( self, mean, stddev )
	local x1, x2, w

	repeat
		x1 = 2 * self:next() - 1
		x2 = 2 * self:next() - 1
		w = x1 * x1 + x2 * x2
	until w < 1.0

	w = math.sqrt( (-2 * math.log( w ) ) / w )
	return (x1 * w)*stddev + mean
end

local function createGenerator( seed )
	return
	{
		_seed = math.max( 1, seed ), -- _seed of 0 will always return 0 as a result.

		next = next,
		nextInt = nextInt,
		nextNrm = nextNrm,
		nextChoice = nextChoice
	}
end

return
{
	createGenerator = createGenerator
}


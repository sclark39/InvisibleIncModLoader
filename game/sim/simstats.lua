----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

-----------------------------------------------------
--

local simstats = class()

function simstats:incStat( stat )
	self:sumStat( stat, 1 )
end

function simstats:sumStat( stat, add )
	self[ stat ] = (self[ stat ] or 0) + add
end

function simstats:maxStat( stat, value )
    if self[ stat ] then
        self[ stat ] = math.max( self[ stat ], value )
    else
        self[ stat ] = value
    end
end

function simstats:setStat( stat, value )
	self.stat = value
end

return simstats

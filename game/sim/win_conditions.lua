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

--------------------------------------------------------------
-- Win condition functions.  These return one of three values:
-- PASS -> the win condition is satisfied
-- FAIL -> the win condition failed
-- nil -> the win condition is neither WIN/LOSS and should continue to be evaluated
--
-- The game is won if ALL win conditions return PASS.
-- The game is lost if ANY of the win conditions return FAIL.
-- If neither of these is true, the game is not yet over.

local FAIL = 0
local PASS = 1

-----------------------------------------------------
-- Default win condition
-- PC won if (1) there were deployed agents that escaped (2) no more agents are left in the game

local function pcHasEscaped( sim )
	local pc = sim:getPC()
	if pc:isNeutralized( sim ) then
		local escapeCount = 0
		for agentID, deployData in pairs(pc:getDeployed()) do
			if deployData.escapedUnit then
				escapeCount = escapeCount + 1
			end
		end

		if escapeCount == 0 then
			return FAIL
		else
			return PASS
		end
	end
end

local function neverLose( sim )
	local pc = sim:getPC()
	if pc:isNeutralized( sim ) then
		local escapeCount = 0
		for agentID, deployData in pairs(pc:getDeployed()) do
			if deployData.escapedUnit then
				escapeCount = escapeCount + 1
			end
		end

		if escapeCount > 0 then
			return PASS
		end
	end
end

local function escapedWithDisk( sim )
	local pc = sim:getPC()
	if pc:getEscapedWithDisk() then 
		return PASS 
	else 
		return nil 
	end 
end

local function pcResigned( sim )
    return FAIL
end

-----------------------------------------------------
-- Local functions

return
{
	FAIL = FAIL,
	PASS = PASS,
	pcHasEscaped = pcHasEscaped,
    neverLose = neverLose,
	escapedWithDisk = escapedWithDisk, 
    pcResigned = pcResigned,
}

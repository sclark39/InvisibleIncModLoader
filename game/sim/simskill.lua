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
local skilldefs = include( "sim/skilldefs" )

-----------------------------------------------------
-- Local functions

local simskill = class()

function simskill:init( skillID, level, sim, unit )
	local skillDef = skilldefs.lookupSkill( skillID )
	assert( skillDef, skillID )
	self._skillID = skillID
	self._currentLevel = 1
	for i = 1, level-1 do
		self:levelUp( sim, unit )
	end
end

function simskill:getID( )
	return self._skillID
end

function simskill:getDef( )
	local skillDef = skilldefs.lookupSkill( self._skillID )
	return skillDef
end

function simskill:getCurrentLevel( )
	return self._currentLevel 
end

function simskill:getLevel( level )
	local skillDef = self:getDef()
	return skillDef[level]
end

function simskill:getNumLevels( )
	local skillDef = self:getDef()
	return skillDef.levels
end

function simskill:levelUp( sim, unit )
	local levelsMax = self:getNumLevels()
	if self._currentLevel < levelsMax then 
		self._currentLevel = self._currentLevel + 1 

		unit:increaseSkillCost()

		local skillLevel = self:getLevel( self:getCurrentLevel() )

		if skillLevel.onLearn then 
			skillLevel.onLearn( sim, unit )
		end 
	end
end

function simskill:levelDown( sim, unit )
	if self._currentLevel <= 1 then 
		return 
	else		
		local skillLevel = self:getLevel( self:getCurrentLevel() )
		if skillLevel.onUnLearn then 
			skillLevel.onUnLearn( sim, unit )
		end 		
		self._currentLevel = self._currentLevel - 1 
	end	
end

return simskill

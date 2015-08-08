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
local simfactory = include( "sim/simfactory" )
local abilitydefs = include( "sim/abilitydefs" )

-----------------------------------------------------
-- Local functions

local function getID( self )
	return self._abilityID
end

local function getDef( self )
	return self
end

local function spawnAbility( self, sim, owner, hostUnit )
    self._sim = sim
    if self.onSpawnAbility then
        self:onSpawnAbility( sim, owner, hostUnit )
    end
end

local function despawnAbility( self, sim, owner )
    self._sim = nil
    if self.onDespawnAbility then
        self:onDespawnAbility( sim, owner )
    end
end

-----------------------------------------------------
-- Interface functions

local _M = { }

function _M.create( abilityID )
	local abilityDef = abilitydefs.lookupAbility( abilityID )
    if abilityDef == nil then
        simlog( "Missing abilityID: %s", tostring(abilityID) )
        return nil
    end

	assert( abilityDef, abilityID )
	local t = util.tcopy( abilityDef )
	t._abilityID = abilityID
	t.getID = getID
	t.getDef = getDef
	t.spawnAbility = spawnAbility
	t.despawnAbility = despawnAbility

	return t
end

return _M

----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local array = include( "modules/array" )
local simunit = include( "sim/simunit" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simplayer = include( "sim/simplayer" )
local simfactory = include( "sim/simfactory" )
local unitdefs = include( "sim/unitdefs" )
local mathutil = include( "modules/mathutil" )
local unitghost = include( "sim/unitghost" )
local inventory = include( "sim/inventory" )

------------------------------------------------------------------
-- Local functions

local function doReserveAction( sim, player, agency )
	for _, abilityID in ipairs(agency.abilities) do
		player:addMainframeAbility(sim, abilityID )
	end
	for i,ability in ipairs( player:getAbilities() ) do
		if ability:getDef().equip_program then 
    		player:equipProgram( sim, ability:getID() )
			break
		end
	end

	player:reserveUnits( agency.unitDefs )
	player:reserveUnits( agency.unitDefsPotential )
    player:deployUnits( sim, agency.unitDefs )
end

-----------------------------------------------------
-- Interface functions

local pcplayer = class( simplayer )

function pcplayer:init( sim, agency )
	simplayer.init( self, sim, agency )

	self._credits = agency.cash
	self._cpus = agency.cpus
    self._seenBefore = {} -- Keeps track of what units have been seen before.
    doReserveAction( sim, self, agency )

	-- Create initial vision.
	sim:forEachCell(
		function( c )
            if c.sightRadius or c.deployID == simdefs.DEFAULT_EXITID then
                local cells = simquery.floodFill( sim, nil, c, math.max( c.sightRadius or 0, 6 ), simquery.getManhattanMoveCost, simquery.canPathBetween )
			    for _, cell in ipairs(cells) do
				    self:markSeen( sim, cell.x, cell.y )
				end
			end
		end )
end


function pcplayer:isNPC( )
	return false
end

function pcplayer:isPC( )
	return true
end

function pcplayer:reserveUnits( agentDefs )
	for i,agentDef in ipairs( agentDefs ) do
        assert( self._deployed[ agentDef.id ] == nil )
		self._deployed[ agentDef.id ] = { agentDef = agentDef }
	end
end

function pcplayer:findAgentDefByID( unitID )

	local agentDef = nil
	for i,agentID in pairs(self._deployed) do
		if agentID.id == unitID then
			agentDef = agentID.agentDef
		end
	end
	return agentDef
end

function pcplayer:getAgents()
    local agents = {}
	for agentID, deployData in pairs(self._deployed) do
        local unit = self._sim:getUnit( deployData.id )
        if unit then
            table.insert( agents, unit )
		end
	end

	return agents
end

function pcplayer:hireUnit( sim, unit, cell, facing )
	if #self:getAgents() >= simdefs.AGENT_LIMIT then
		sim:dispatchEvent( simdefs.EV_AGENT_LIMIT )
		return nil
	end

	local agentID = unit:getTraits().rescueID
	if agentID == nil then
		-- This should only be nil for non-procgen levels
		for deployID, deployData in pairs(self._deployed) do
			if deployData.id == nil then
				agentID = deployID
				break
			end
		end
	end
	local agentDef = self._deployed[ agentID ].agentDef

	-- Despawn the captured placeholder.
	sim:warpUnit( unit, nil )
	sim:despawnUnit( unit )

	local unitData = unitdefs.createUnitData( agentDef )
	local unit = simfactory.createUnit( unitData, sim )
	unit:setPlayerOwner( self )
    unit:getTraits().rescued = true

	-- Spawn and warp the unit
	sim:spawnUnit( unit )
	sim:warpUnit( unit, cell, facing )
	self._deployed[ agentID ].id = unit:getID()

	sim:triggerEvent( simdefs.TRG_UNIT_RESCUED, unit )

	return unit
end

function pcplayer:rescueHostage( sim, unit, cell, facing, userUnit )
	local x0,y0 = userUnit:getLocation()
	local x1,y1 = unit:getLocation()			
	local tempfacing = simquery.getDirectionFromDelta( x1 - x0, y1 - y0 )

	local template = unit:getTraits().template
	if unit:getTraits().untie_anim then
		userUnit:setFacing(tempfacing)	
		sim:dispatchEvent( simdefs.EV_UNIT_USECOMP, { unitID = userUnit:getID(), facing = tempfacing, sound = "SpySociety/Actions/hostage/free_hostage" , soundFrame = 16 } )
		sim:dispatchEvent( simdefs.EV_UNIT_UNTIE, { unit = unit } )	
	end

	-- Despawn the captured placeholder.	
	sim:warpUnit( unit, nil )
	sim:despawnUnit( unit )

	local unit = simfactory.createUnit( unitdefs.agent_templates[template], sim )
	unit:setPlayerOwner( self )

	-- Spawn and warp the unit
	sim:spawnUnit( unit )
	sim:warpUnit( unit, cell, facing )

	return unit
end

function pcplayer:onStartTurn( sim )
    simplayer.onStartTurn( self, sim )

    if sim:getTags().blinkAtStartTurn then
    	self._sim:dispatchEvent( simdefs.EV_BLINK_REWIND )
    	sim:getTags().blinkAtStartTurn = nil
    end

	if sim._elevator_inuse and sim._elevator_inuse > 0 then
		sim._elevator_inuse = sim._elevator_inuse -1
		if sim._elevator_inuse == 0 then
			sim:openElevator()
		end
	end
end

function pcplayer:addSeenUnit( unit )
    simplayer.addSeenUnit( self, unit )

    if not self._seenBefore[ unit:getID() ] then
        self._seenBefore[ unit:getID() ] = self._sim:getActionCount()
    end
end

function pcplayer:hasSeen( unit )
    return self._seenBefore[ unit:getID() ] ~= nil
end

function pcplayer:justSeenUnit( unit )
    return self._seenBefore[ unit:getID() ] == self._sim:getActionCount()
end

return pcplayer




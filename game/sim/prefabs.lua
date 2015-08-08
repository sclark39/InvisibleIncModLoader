----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local astar = include( "modules/astar" )
local binops = include( "modules/binary_ops" )

--------------------------------------------------------------------------

-- Finds all prefabs with the given tag.
-- returns: a table of prefabs that contain the given tag, as well as the total weighting of all discovered prefabs
local function findPrefabs( cxt, tag )
	local prefabs = {}
	local totalWeight = 0

	for i = 1, #cxt.PREFABT do
		if array.find( cxt.PREFABT[i].tags, tag ) then
			totalWeight = totalWeight + cxt.PREFABT[i].weight
			table.insert( prefabs, cxt.PREFABT[i] )
		end
	end
	
	prefabs.totalWeight = totalWeight
	return prefabs
end

-- Selects a single weighted prefab from a list of prefabs.
-- returns: The selected prefab
local function selectPrefab( cxt, prefabs )
	-- NOTE: allow weight to be 0, these represent prefabs that are only selected as a last resort (after all
	-- other weighted prefabs have been chosen and fail)
	local w = cxt.rnd:nextInt( math.min( 1, prefabs.totalWeight ), prefabs.totalWeight )

	for i = 1, #prefabs do
		if w <= prefabs[i].weight then
			prefabs[i].selectCount = (prefabs[i].selectCount or 0) + 1
			return prefabs[i]
		else
			w = w - prefabs[i].weight
		end
	end

	return nil
end


local AStarHandler = class()

function AStarHandler:init( cxt, graph )
	self.cxt = cxt
	self.cgraph = graph
	self.result = {}
end

function AStarHandler:getNode( cellID, parentNode )
	assert( cellID )
	return astar.Node:new( cellID, 0, cellID, parentNode )
end

function AStarHandler:getAdjacentNodes( cur_node, goal_cell, closed )
	util.tclear(self.result)

	local x0, y0 = simquery.fromCellID( cur_node.location )
	local fromZone = self.cxt:roomContaining( x0, y0 ).zoneID

	-- The idea is that adjacent zones should remain adjacent (connected directly).  So, a pathfind from one cell to
	-- another can only use cells that satisfy this requirement.  Legal adjacent cells are:
	--  (1) within the same zone
	--  (2) within an adjacent zone that is also connected to the starting zone (self.zoneID).

	if not self.cgraph:isImpass( x0, y0, simdefs.DIR_N ) then
		local room = self.cxt:roomContaining( x0, y0 + 1 )
		if (fromZone == room.zoneID) or (fromZone == self.zoneID and self.cxt.m0:isAdjacent( room.zoneID, self.zoneID )) then
			table.insert( self.result, self:_handleNode( simquery.toCellID( x0, y0 + 1 ), cur_node, goal_cell ))
		end
	end
	if not self.cgraph:isImpass( x0, y0, simdefs.DIR_E ) then
		local room = self.cxt:roomContaining( x0 + 1, y0 )
		if (fromZone == room.zoneID) or (fromZone == self.zoneID and self.cxt.m0:isAdjacent( room.zoneID, self.zoneID )) then
			table.insert( self.result, self:_handleNode( simquery.toCellID( x0 + 1, y0 ), cur_node, goal_cell ))
		end
	end
	if not self.cgraph:isImpass( x0, y0, simdefs.DIR_W ) then
		local room = self.cxt:roomContaining( x0 - 1, y0 )
		if (fromZone == room.zoneID) or (fromZone == self.zoneID and self.cxt.m0:isAdjacent( room.zoneID, self.zoneID )) then
			table.insert( self.result, self:_handleNode( simquery.toCellID( x0 - 1, y0 ), cur_node, goal_cell ))
		end
	end
	if not self.cgraph:isImpass( x0, y0, simdefs.DIR_S ) then
		local room = self.cxt:roomContaining( x0, y0 - 1 )
		if (fromZone == room.zoneID) or (fromZone == self.zoneID and self.cxt.m0:isAdjacent( room.zoneID, self.zoneID )) then
			table.insert( self.result, self:_handleNode( simquery.toCellID( x0, y0 - 1 ), cur_node, goal_cell ))
		end
	end

	return self.result
end

function AStarHandler:isGoal(node, goal)
	return node.location == goal
end

function AStarHandler:_handleNode(to_cell, from_node, goal_cell)
	local x0, y0 = simquery.fromCellID( to_cell )
	local xt, yt = simquery.fromCellID( goal_cell )
	local emCost = mathutil.dist2d( x0, y0, xt, yt )
	local dc = 1

	-- Fetch a Node for the given location and set its parameters
	local n = self:getNode(to_cell, from_node)
	n.mCost = from_node.mCost + dc
	n.score = n.mCost + emCost
	return n
end

local CGraph = class()

function CGraph:init( cxt, cgraph, prefabData )
	self.cxt = cxt
	self.oldImpass = {}
	self.checks = {}
	self.cgraph = util.tcopy( cgraph )
	-- Convert the node coordinates from prefab to map space.
	for _, edge in ipairs( self.cgraph.edges ) do
		local x, y = simquery.rotateFacing( prefabData.facing, edge.x0 - 1, edge.y0 - 1 )
		edge.x0, edge.y0 = x + prefabData.prefab.tx + prefabData.tx, y + prefabData.prefab.ty + prefabData.ty

		local x, y = simquery.rotateFacing( prefabData.facing, edge.x1 - 1, edge.y1 - 1 )
		edge.x1, edge.y1 = x + prefabData.prefab.tx + prefabData.tx, y + prefabData.prefab.ty + prefabData.ty
	end
end

function CGraph:isMarkedImpass( x, y, dir )
	local rdir = simquery.getReverseDirection( dir )
	local dx, dy = simquery.getDeltaFromDirection( dir )
	for i = 1, #self.oldImpass, 3 do
		if (self.oldImpass[i] == x and self.oldImpass[i+1] == y and self.oldImpass[i+2] == dir) or
			(self.oldImpass[i] == x + dx and self.oldImpass[i+1] == y + dy and self.oldImpass[i+2] == rdir) then
			return true
		end
	end

	return false
end

function CGraph:isImpass( x, y, dir )
	if self.cxt.LVL_PATTERN:isImpass( x, y, dir ) then
		return true
	end

	if self:isMarkedImpass( x, y, dir ) then
		return true
	end

	return false
end

function CGraph:addEdge( x, y, dir )
	-- did we already add this edge?  Don't double-mark impass.
	if self:isMarkedImpass( x, y, dir ) then
		return
	end

	if self.cxt.LVL_PATTERN:isImpass( x, y, dir ) then
		local dx, dy = simquery.getDeltaFromDirection( dir )
		-- Already impassable, no need to check this edge.  Remove it from the list.
		for i, edge in ipairs( self.cgraph.edges ) do
			if (edge.x0 == x and edge.y0 == y and edge.x1 == x + dx and edge.y1 == y + dy) or
				(edge.x1 == x and edge.y1 == y and edge.x0 == x + dx and edge.y0 == y + dy) then
				table.remove( self.cgraph.edges, i )
				break
			end
		end
	else
		-- Track temporary impassability for connectivity check.
		table.insert( self.oldImpass, x )
		table.insert( self.oldImpass, y )
		table.insert( self.oldImpass, dir )
	end
end

function CGraph:addCheck( x0, y0, x1, y1 )
	local found = false
	for i = 1, #self.checks, 4 do
		if (self.checks[i] == x0 and self.checks[i+1] == y0 and self.checks[i+2] == x1 and self.checks[i+3] == y1) or
			(self.checks[i] == x1 and self.checks[i+1] == y1 and self.checks[i+2] == x0 and self.checks[i+3] == y0) then
			found = true
			break -- Already exists.
		end
	end
	if not found then
		table.insert( self.checks, x0 )
		table.insert( self.checks, y0 )
		table.insert( self.checks, x1 )
		table.insert( self.checks, y1 )
	end
end

function CGraph:getLocation( sourceID )
	for _, edge in ipairs( self.cgraph.edges ) do
		if edge.id0 == sourceID then
			return edge.x0, edge.y0
		elseif edge.id1 == sourceID then
			return edge.x1, edge.y1
		end
	end
end

function CGraph:validateConnection( sourceID, destID )
	if sourceID >= 100 then
		-- source is unreacahble, no validation necessary.
	elseif destID >= 100 then
		-- unreacahble!  connect to its connections.
		for _, edge in ipairs( self.cgraph.edges ) do
			if edge.id0 == destID and edge.id1 ~= sourceID then
				assert( edge.id1 < 100, destID..","..edge.id1 )
				self:validateConnection( sourceID, edge.id1 )
			elseif edge.id1 == destID and edge.id0 ~= sourceID then
				assert( edge.id0 < 100 )
				self:validateConnection( sourceID, edge.id0 )
			end
		end
	else
		local found = false
		for i = 1, #self.checks, 2 do
			if (self.checks[i] == sourceID and self.checks[i+1] == destID) or
				(self.checks[i] == destID and self.checks[i+1] == sourceID) then
				found = true
				break -- Already exists.
			end
		end
		if not found then
			table.insert( self.checks, sourceID )
			table.insert( self.checks, destID )
		end
	end
end

function CGraph:validateConnections( prefabData )
	-- Generate the pairwise cells for which we need to check connectivity.
	for i, edge in ipairs( self.cgraph.edges ) do
		self:validateConnection( edge.id0, edge.id1 )
	end

	local handler = AStarHandler( self.cxt, self )
	local pather = astar.AStar:new( handler )

	-- Check connectivity; just use the first coordinate as a representative target of the partition.
	log:write( simdefs.LOG_PROCGEN, "VALIDATE %s : %d pairwise checks", prefabData.filename, #self.checks / 2 )
	for i = 1, #self.checks, 2 do
		local sourceID, destID = self.checks[i], self.checks[i+1]

		local x0, y0 = self:getLocation( sourceID )
		local cellID0 = simquery.toCellID( x0, y0 )
		local r0 = self.cxt:roomContaining( x0, y0 )
	
		local x1, y1 = self:getLocation( destID )
		local cellID1 = simquery.toCellID( x1, y1 )
		local r1 = self.cxt:roomContaining( x1, y1 )

		-- Find path.
		handler.zoneID = r0 and r0.zoneID or -1
		local path, connected, wasConnected
		if r0 and r1 then
			path = pather:findPath( cellID0, cellID1 )
			connected = path ~= nil
			wasConnected = self.cxt.m0:isAdjacent( r0.zoneID, r1.zoneID )
		else
			connected, wasConnected = false, false
		end
		log:write( simdefs.LOG_PROCGEN, "\t<%d, %d>[%d] -> <%d, %d>[%d] [%s] =?= [%s]", x0, y0, r0 and r0.zoneID or -1, x1, y1, r1 and r1.zoneID or -1, tostring(connected), tostring(wasConnected) )

		if connected ~= wasConnected then
			return false
		end
	end

	return true
end


-- Verifies that the selected candidate doesn't bork the map's connectivity.
local function validateFit( cxt, prefabData )
	local WALL_TYPES = include( "sim/walltypes" )
	local prefabFilename = string.format( "%s", prefabData.filename )
	local prefab = include( prefabFilename )

	if prefab.cgraph == nil or #prefab.cgraph.edges == 0 then
		--log:write( "VALIDATE %s: No cgraph information.  Skipping.", prefabData.filename )
		return true
	end

	local cgraph = CGraph( cxt, prefab.cgraph, prefabData )

	for i, wall in ipairs(prefab.walls) do
		if (wall.dir == simdefs.DIR_E or wall.dir == simdefs.DIR_N) and (not WALL_TYPES[ wall.wallIndex ].door or WALL_TYPES[ wall.wallIndex ].locked) then
			local x, y = simquery.rotateFacing( prefabData.facing, wall.x - 1, wall.y - 1 )
			local dir = (wall.dir + prefabData.facing - 2) % simdefs.DIR_MAX
			x, y = x + prefabData.prefab.tx + prefabData.tx, y + prefabData.prefab.ty + prefabData.ty
			cgraph:addEdge( x, y, dir )
		end
	end

	for i, tile in ipairs(prefab.tiles) do
		if tile.impass or tile.dynamic_impass then
			local x, y = simquery.rotateFacing( prefabData.facing, tile.x - 1, tile.y - 1 )
			x, y = x + prefabData.prefab.tx + prefabData.tx, y + prefabData.prefab.ty + prefabData.ty
			cgraph:addEdge( x, y, simdefs.DIR_E )
			cgraph:addEdge( x, y, simdefs.DIR_N )
			cgraph:addEdge( x, y, simdefs.DIR_W )
			cgraph:addEdge( x, y, simdefs.DIR_S )
		end
	end
	
	return cgraph:validateConnections( prefabData )
end

-- Finds a prefab that matches the given context pattern from the list of possible choices.
-- First selects a candidate from the list, then attempts to match it to the level pattern.
-- If it doesn't match, it is removed from the prefabs list and another candidate is selected.
-- If it does match, its location is randomly selected from the list of match locations.
-- returns: The selected matching prefab, or nil if no matches are found.

-- Selection tyeps -- determines how the candidates should be selected based on their fitness weighting.
local SELECT_WEIGHTED = 0
local SELECT_HIGHEST = 1

local function matchPrefabs( cxt, prefabs, fitnessFn, fitnessSelect )
	local prefab = selectPrefab( cxt, prefabs )
	local pattern = prefab.match_pattern
	local matches = cxt.LVL_PATTERN:matchElements( cxt, prefab, fitnessFn )
	local candidate = nil

	while candidate == nil do
		while matches:getTotalWeight() == 0 do
			log:write( simdefs.LOG_PROCGEN, "NO MATCH for piece %d/%d [%s.%d] (FAILS: %d)", array.find( prefabs, prefab ), #prefabs, prefab.filename, prefab.facing, cxt.FAILCOUNT or 0 )
			cxt.FAILCOUNT = (cxt.FAILCOUNT or 0) + 1
			prefabs.totalWeight = prefabs.totalWeight - prefab.weight
			array.removeElement( prefabs, prefab )
			if #prefabs == 0 then
				return nil
			end

			prefab = selectPrefab( cxt, prefabs )
			matches = cxt.LVL_PATTERN:matchElements( cxt, prefab, fitnessFn )
		end

		local m, wt
        if fitnessSelect == SELECT_HIGHEST then
            m, wt = matches:removeHighest( )
        else
            m, wt = matches:removeChoice( cxt.rnd:nextInt( 1, matches:getTotalWeight() ))
        end
		candidate =
		{
			prefab = prefab,
			filename = prefab.filename,
			facing = prefab.facing,
			burn_pattern = prefab.burn_pattern,
			tx = m[ 1 ],
			ty = m[ 2 ],
		}
		prefab.matchCount = (prefab.matchCount or 0) + 1

		if not validateFit( cxt, candidate ) then
			log:write( simdefs.LOG_PROCGEN, "\tFIT FAILED for prefab [%s.%d] among %d matches at <%d, %d>", prefab.filename, prefab.facing, matches:getCount(), candidate.tx, candidate.ty )
			candidate = nil
		end
		if candidate then
			log:write( simdefs.LOG_PROCGEN, "MATCH %s.%d (wt. %d) among %d matches at <%d, %d>", candidate.filename, candidate.facing, wt, matches:getCount(), candidate.tx, candidate.ty )
		end
	end	
	return candidate
end

local function generatePrefabs( cxt, candidates, tag, maxCount, fitnessFn, fitnessSelect )
	local pattern = cxt.LVL_PATTERN
	assert( pattern )

	local setPieces = findPrefabs( cxt, tag )
	if #setPieces == 0 then
		log:write( simdefs.LOG_PROCGEN, "PROCGEN -- No prefabs with tag '%s'", tag )
		return 0
	end

	local count = 0
	while (maxCount or 1000) > count do
		local candidate = matchPrefabs( cxt, setPieces, fitnessFn, fitnessSelect )
		if not candidate then
			break
		end

		if cxt.SEARCH_PREFAB == candidate.filename then
			cxt.SEARCH_PREFAB = true
		end

		pattern:burnElements( candidate.tx, candidate.ty, candidate.prefab.burn_elements )

		table.insert( candidates, candidate )

		count = count + 1
	end

	if maxCount and count < maxCount then
		log:write( "PROCGEN - Spawned only %d/%d prefabs tagged '%s'", count, maxCount, tag )
	end

	return count
end


return
{
    SELECT_WEIGHTED = SELECT_WEIGHTED,
    SELECT_HIGHEST = SELECT_HIGHEST,

	findPrefabs = findPrefabs,
	generatePrefabs = generatePrefabs,
}



----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local astar = include("modules/astar")
local simdefs = include( "sim/simdefs" )

local AStarHandler_Unit = {}

function AStarHandler_Unit:new( sim, unit, maxMP, goalFn, softPath )
	local instance = util.tcopy( self )
	instance._sim = sim
	instance._softPath = softPath
	instance._unit = unit
	instance._maxMP = maxMP
	instance._boardw = sim:getBoardSize() -- only need width.
	instance._goalFn = goalFn
	return instance
end

function AStarHandler_Unit:getNodeLid( x, y )
	return y * self._boardw + x
end

function AStarHandler_Unit:getNode( cell, parentNode )
	if cell then
		self.nc = (self.nc or 0) + 1
		return astar.Node:new(cell, 0, self:getNodeLid( cell.x, cell.y ), parentNode )
	end
end


function AStarHandler_Unit:getAdjacentNodes( cur_node, goal_cell, closed )
	-- Given a node, return a table containing all adjacent nodes
	local result = {}	
	local cell = cur_node.location
	local simquery = self._sim:getQuery()
	local cellquery = self._sim
	if self._unit and self._unit:getPlayerOwner() then
		cellquery = self._unit:getPlayerOwner()
	end

	local n = nil

	-- TODO: ideally, iterate over cell.exits.  But this doesn't consider diagonal movement
	-- at the moment.  Therefore, hijack the assumption that the map is a grid and use x,y coordinates.
	-- for i,exit in pairs( cell.exits ) do
	for dx = -1,1 do
		for dy = -1,1 do
			local target_cell = cellquery:getCell( cell.x + dx, cell.y + dy )
			local target_lid = self:getNodeLid( cell.x + dx, cell.y + dy )
			if target_cell and not (dx == 0 and dy == 0) and not closed[ target_lid ] then
				local canPath
				if self._softPath then
					canPath = simquery.canStaticPath( cellquery, self._unit, cell, target_cell )
				else
					canPath = simquery.canPath( cellquery, self._unit, cell, target_cell )
				end
				if canPath then
					n = self:_handleNode( target_cell, cur_node, goal_cell )
					if n then
						table.insert(result, n)
					end
				end
			end
		end
	end

	return result
end

function AStarHandler_Unit:isGoal(node, goal)
	-- Cannot compare a == b directly, as this will fail when comparing ghost cells
	if self._goalFn then
		return self._goalFn( node, goal )
	else
		return node.location.x == goal.x and node.location.y == goal.y
	end
end

function AStarHandler_Unit:_handleNode(to_cell, from_node, goal_cell)
	local simquery = self._sim:getQuery()
	local emCost = mathutil.dist2d( to_cell.x, to_cell.y, goal_cell.x, goal_cell.y )
	local dc = simquery.getMoveCost( from_node.location, to_cell )

	if self._maxMP == nil or self._maxMP >= from_node.mCost + dc then
		-- Fetch a Node for the given location and set its parameters
		local n = self:getNode(to_cell, from_node)
		n.mCost = from_node.mCost + dc
		n.score = n.mCost + emCost
    
		return n
	end
end

------------------------------------------------------------------------------
-- Sound occlusion search

local AStarHandler_Sound = {}

function AStarHandler_Sound:new( sim, maxMP )
	local instance = util.tcopy( self )
	instance._sim = sim
	instance._maxMP = maxMP
	instance._boardw = sim:getBoardSize() -- only need width.
	return instance
end

function AStarHandler_Sound:setMaxDist( dist )
	self._maxMP = dist
end

function AStarHandler_Sound:getNodeLid( x, y )
	return y * self._boardw + x
end

function AStarHandler_Sound:getNode( cell, parentNode )
	if cell then
		self.nc = (self.nc or 0) + 1
		return astar.Node:new(cell, 0, self:getNodeLid( cell.x, cell.y ), parentNode )
	end
end


function AStarHandler_Sound:getAdjacentNodes( cur_node, goal_cell, closed )
	-- Given a node, return a table containing all adjacent nodes
	local result = {}	
	local cell = cur_node.location
	local n = nil

	for dir,exit in pairs( cell.exits ) do
		local target_cell = exit.cell
		local target_lid = self:getNodeLid( target_cell.x, target_cell.y )
		if target_cell and not closed[ target_lid ] then
			n = self:_handleNode( target_cell, cur_node, goal_cell )
			if n then
				table.insert(result, n)
			end
		end
	end

	return result
end

function AStarHandler_Sound:isGoal(node, goal)
	-- Cannot compare a == b directly, as this will fail when comparing ghost cells
	return node.location.x == goal.x and node.location.y == goal.y
end

function AStarHandler_Sound:_handleNode(to_cell, from_node, goal_cell)
	local simquery = self._sim:getQuery()
	local emCost = mathutil.dist2d( to_cell.x, to_cell.y, goal_cell.x, goal_cell.y )
	local dc = simquery.getMoveCost( from_node.location, to_cell )
	for dir, exit in pairs( from_node.location.exits ) do
		if exit.cell == to_cell and exit.door and exit.closed then
			dc = dc + 4 -- Doors cost 4.
			break
		end
	end

	if self._maxMP >= from_node.mCost + dc then
		-- Fetch a Node for the given location and set its parameters
		local n = self:getNode(to_cell, from_node)
		n.mCost = from_node.mCost + dc
		n.score = n.mCost + emCost
		return n
	end
end

------------------------------------------------------------------------------
-- AI search

local AStarHandler_AI = {}

function AStarHandler_AI:new( unit )
	local instance = util.tcopy( self )
	instance._unit = unit
	instance._boardw = unit:getSim():getBoardSize() -- only need width.
	return instance
end

function AStarHandler_AI:getNodeLid( x, y )
	return y * self._boardw + x
end

function AStarHandler_AI:getNode( cell, parentNode )
	if cell then
		self.nc = (self.nc or 0) + 1
		return astar.Node:new(cell, 0, self:getNodeLid( cell.x, cell.y ), parentNode )
	end
end


function AStarHandler_AI:getAdjacentNodes( cur_node, goal_cell, closed )
	local result = {}	
	local cell = cur_node.location
    local sim = self._unit:getSim()
	local simquery = sim:getQuery()
	local n = nil

	for dx = -1,1 do
		for dy = -1,1 do
			local target_cell = sim:getCell( cell.x + dx, cell.y + dy )
			local target_lid = self:getNodeLid( cell.x + dx, cell.y + dy )
			if target_cell and not (dx == 0 and dy == 0) and not closed[ target_lid ] then
				local canPath = simquery.canSoftPath( sim, self._unit, cell, target_cell )
				if canPath then
					n = self:_handleNode( target_cell, cur_node, goal_cell )
					if n then
						table.insert(result, n)
					end
				end
			end
		end
	end

	return result
end

function AStarHandler_AI:isGoal( node, goal )
	-- Cannot compare a == b directly, as this will fail when comparing ghost cells
	return node.location.x == goal.x and node.location.y == goal.y
end

function AStarHandler_AI:_handleNode(to_cell, from_node, goal_cell)
	local simquery = self._unit:getSim():getQuery()
	local emCost = mathutil.dist2d( to_cell.x, to_cell.y, goal_cell.x, goal_cell.y )
	local dc = simquery.getMoveCost( from_node.location, to_cell )

	-- Since we are soft-pathing, we may have dynamic impass in the way.  Handle this by
	-- adding a fixed cost per obstacle.
	for i,unit in ipairs(to_cell.units) do
		if unit ~= self._unit and unit:getPlayerOwner() == self._unit:getPlayerOwner() and unit:hasTrait("dynamicImpass") then
			dc = dc + 2
			break
		end
	end

	-- Fetch a Node for the given location and set its parameters
	local n = self:getNode(to_cell, from_node)
	n.mCost = from_node.mCost + dc
	n.score = n.mCost + emCost
    
	return n
end

------------------------------------------------------------------------------
-- AI "planned path" search (for planning patrol paths in the WorldGen stage)

local AStarHandler_AI_Plan = util.tcopy(AStarHandler_AI)

function AStarHandler_AI_Plan:new(context, pathFn)
	local instance = util.tcopy( self )
	instance._context = context
	local xmin, ymin, xmax, ymax = context:getBounds()
	instance._boardw = xmax - xmin

	return instance
end

function AStarHandler_AI_Plan:getCell(x, y)
	return self._context.board[y] and self._context.board[y][x]
end

function AStarHandler_AI_Plan:isGoal( node, goal )
	return node.location.x == goal.x and node.location.y == goal.y
end

function AStarHandler_AI_Plan:getAdjacentNodes( cur_node, goal_cell, closed )
	local result = {}	
	local cell = cur_node.location
	local n = nil

	for dx = -1,1 do
		for dy = -1,1 do
			local targetX, targetY = cell.x + dx, cell.y + dy
			local target_lid = self:getNodeLid(targetX, targetY)
			if self:getCell(targetX, targetY) and self._context:canPath(cell.x, cell.y, targetX, targetY) and not closed[ target_lid ] then
				n = self:_handleNode( {x=targetX, y=targetY}, cur_node, goal_cell )
				if n then
					table.insert(result, n)
				end
			end
		end
	end

	return result
end

function AStarHandler_AI_Plan:_handleNode(to_cell, from_node, goal_cell)
	local emCost = mathutil.dist2d( to_cell.x, to_cell.y, goal_cell.x, goal_cell.y )
	local dc = mathutil.dist2d( from_node.location.x, from_node.location.y, to_cell.x, to_cell.y )

	-- Fetch a Node for the given location and set its parameters
	local n = self:getNode(to_cell, from_node)
	n.mCost = from_node.mCost + dc
	n.score = n.mCost + emCost
    
	return n
end

------------------------------------------------------------------------------
-- Cooperative multi-agent search

local MAX_SEARCH_DEPTH = 12

local AStarHandler_Coop = {}

function AStarHandler_Coop:new(unit, heuristicFn)
	local instance = util.tcopy( self )
	instance._unit = unit
	instance._heuristicFn = heuristicFn
	instance._boardw = unit:getSim():getBoardSize() -- only need width.
	instance._searchDepth = 12 --this is the highest mp a guard has * sqrt(2) to allow for a completely diagonal movement
	return instance
end

function AStarHandler_Coop:getNodeLid( x, y, t )
	return self._unit:getPather():getNodeLid(x, y, t)
end

function AStarHandler_Coop:getNode( cell, t, parentNode )
	if cell then
		self.nc = (self.nc or 0) + 1
		t = t or 0
		local lid = self:getNodeLid( cell.x, cell.y, t )
		local node = astar.Node:new( cell, 0, lid, parentNode )
		node.t = t
		return node
	end
end


function AStarHandler_Coop:getAdjacentNodes( cur_node, goal_cell, closed )
	-- Given a node, return a table containing all adjacent nodes
	local result = {}	
	local cell = cur_node.location
    local sim = self._unit:getSim()
	local simquery = sim:getQuery()
	local n = nil

	-- Can also 'pause': eg. stay at same place with advanced t.
	n = self:_handleNode( cell, cur_node, goal_cell )
	table.insert( result, n )

	for dx = -1,1 do
		for dy = -1,1 do
			local target_cell = sim:getCell( cell.x + dx, cell.y + dy )
			local target_lid = self:getNodeLid( cell.x + dx, cell.y + dy, cur_node.t + 1 )
			if target_cell and not (dx == 0 and dy == 0) and not closed[ target_lid ] then
				local canPath = simquery.canSoftPath( sim, self._unit, cell, target_cell )
				if canPath then
                    n = self:_handleNode( target_cell, cur_node, goal_cell )
					if n then
						table.insert(result, n)
					end
				end
			end
		end
	end

	return result
end

function AStarHandler_Coop:isGoal( node, goal )
	return node.t == self._searchDepth
	--return node.location.x == goal.x and node.location.y == goal.y and node.t == MAX_SEARCH_DEPTH
end

function AStarHandler_Coop:_handleNode(to_cell, from_node, goal_cell)
	if from_node.t >= self._searchDepth then
		return nil
	end

	local n = self:getNode(to_cell, from_node.t + 1, from_node)
	if self._unit:getPather():checkPathReservation( n.lid ) then
		--log:write( "RESERVED at (%d, %d, t = %d), %d", n.location.x, n.location.y, n.t, n.lid )
		return nil
	elseif self._unit:getPather():checkPathReservation( from_node.lid + 1 ) and self._unit:getPather():checkPathReservation(n.lid - 1) then
		--log:write( "HEAD-ON MOVE, ILLEGAL at (%d, %d, t = %d)", from_node.location.x, from_node.location.y, from_node.t + 1 )
		return nil
	end

	local simquery = self._unit:getSim():getQuery()
	-- Estimated cost
	local ec = self._heuristicFn( to_cell, from_node, goal_cell )
	if ec == nil then
		return nil -- Missing heuristic implies that this node is not pathable.
	end
	-- Direct cost.
	local dc
	if to_cell.x == goal_cell.x and to_cell.y == goal_cell.y then
		dc = 0
	elseif to_cell.x == from_node.location.x and to_cell.y == from_node.location.y then
		--cost a little less to stay in the same place
		dc = 0.5
	else
		 -- Cost is 1 for all actions except pausing on the goal cell.
		 -- Otherwise, if pausing on the goal cell takes cost 1, then as our search depth increases in t,
		 -- the cost for sitting on the goal cell will eventually overtake nodes at earlier t, resulting in flooding.
		dc = 1
	end

	-- Fetch a Node for the given location and set its parameters
	n.mCost = from_node.mCost + dc
	n.score = n.mCost + ec

	return n
end


return
{
	handler = AStarHandler_Unit,
	sound_handler = AStarHandler_Sound,
	aihandler = AStarHandler_AI,
	plan_handler = AStarHandler_AI_Plan,
	coop_handler = AStarHandler_Coop,
}

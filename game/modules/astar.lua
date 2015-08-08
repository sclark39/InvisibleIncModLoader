-- 
--  astar.lua
--  lua-astar
--  
--  Based on John Eriksson's Python A* implementation.
--  http://www.pygame.org/project-AStar-195-.html
--
--  Created by Jay Roberts on 2011-01-08.
--  Copyright 2011 Jay Roberts All rights reserved.
-- 
--  Licensed under the MIT License
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--  
--  The above copyright notice and this permission notice shall be included in
--  all copies or substantial portions of the Software.
--  
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--  THE SOFTWARE.

local util = include( "modules/util" )

-------------------------------------------------------------------------------
-- Represents a path found by the AStar pather.

local Path = {}

function Path:new(nodes, totalCost, startNode)
	local instance = util.tcopy(self)
	instance.nodes = nodes  -- An array of nodes in order of path traversal
	instance.totalCost = totalCost -- The total cost of the discovered path over all nodes
	instance.startNode = startNode
	return instance
end

function Path:getNodes()
  return self.nodes
end

function Path:getStartNode()
	return self.startNode
end

function Path:getTotalMoveCost()
  return self.totalCost
end

-----------------------------------------------------------------------------------
-- A generic search node for the AStar pather.  Included in the Path search result.

local Node = {}

function Node:new(location, mCost, lid, parent)
	local instance = util.tcopy(self)
	instance.location = location -- Where is the node located
	instance.mCost = mCost -- Total move cost to reach this node
	instance.parent = parent -- Parent node
	instance.score = 0 -- Calculated score for this node
	instance.depth = parent and (parent.depth + 1) or 0
	instance.lid = lid -- set the location id - unique for each location in the map
	return instance
end

function Node:isEqual(a, b)
  return a.lid == b.lid
end

-------------------------------------------------------------------------------
--

local AStar = {}

function AStar:new( maphandler )
	local instance = util.tcopy( self )
	instance.mh = maphandler
	return instance
end

function AStar:_getBestOpenNode()
  local bestNode = nil
  for lid, n in pairs(self.open) do
    if bestNode == nil then
      bestNode = n
    else
      if n.score < bestNode.score then
        bestNode = n
	  elseif n.score == bestNode.score then
		if type(n.location) == "number" then
			if n.location < bestNode.location then
				bestNode = n
			end
		elseif (n.location.y < bestNode.location.y or (n.location.y == bestNode.location.y and n.location.x < bestNode.location.x) ) then
			bestNode = n
		end
      end
    end
  end
  
  return bestNode
end

function AStar:_tracePath(n)
  local nodes = {}
  local totalCost = n.mCost
  local p = n.parent
  
  table.insert(nodes, 1, n)
  
  while true do
    if p.parent == nil then
      break
    end
    table.insert(nodes, 1, p)
    p = p.parent
  end
  
  return Path:new(nodes, totalCost, p)
end

function AStar:_handleNode(node, goal, ignoreGoal)
  self.open[node.lid] = nil
  self.closed[node.lid] = node.mCost
  
  assert(node.location ~= nil, 'About to pass a node with nil location to getAdjacentNodes')
  
  local nodes = self.mh:getAdjacentNodes(node, goal, self.closed)

  for lid, n in ipairs(nodes) do
	if not ignoreGoal and self.mh:isGoal(n, goal) then
		return n
	elseif self.closed[n.lid] ~= nil then -- Alread in close, skip this
	elseif self.open[n.lid] ~= nil then -- Already in open, check if better score   
		local on = self.open[n.lid]
    
		if n.mCost < on.mCost then
		self.open[n.lid] = nil
		self.open[n.lid] = n
		end
	else -- New node, append to open list
		self.open[n.lid] =  n
	end
  end
  
  return nil
end

function AStar:findPath(fromlocation, tolocation)
  self.open = {}
  self.closed = {}
  
  local goal = tolocation
  local fnode = self.mh:getNode(fromlocation)
  local nextNode = nil

  if fnode ~= nil then
    self.open[fnode.lid] = fnode
    nextNode = fnode
  end  
  
  while nextNode ~= nil do
    local finish = self:_handleNode(nextNode, goal)

    if finish then
      return self:_tracePath(finish)
    end

    nextNode = self:_getBestOpenNode()
  end
  
  return nil
end

function AStar:findNodeCost(fromlocation, tolocation, testLocation)
	-- return the node cost for 'testLocation'.
	-- This function can be called iteratively (self.closed is cached for future queries)
	if self.closed == nil then
		self.closed = {}
	end

	local testNode = self.mh:getNode(testLocation)
	if self.closed[testNode.lid] then
		--log:write("TRUECOST (%d, %d) -> (%d, %d) for cell (%d, %d) is %.2f (%d closed)",
		--	fromlocation.x, fromlocation.y, tolocation.x, tolocation.y, testLocation.x, testLocation.y, self.closed[testNode.lid], util.tcount(self.closed))
		return self.closed[testNode.lid]
	end

	local nextNode = nil
	if self.open == nil then
		nextNode = self.mh:getNode(fromlocation)
		self.open = {}
	else
		nextNode = self:_getBestOpenNode()
	end

	while nextNode ~= nil do
		self:_handleNode( nextNode, tolocation, true )

		if self.closed[testNode.lid] then
			--log:write("TRUECOST (%d, %d) -> (%d, %d) for cell (%d, %d) is %d (%d closed)",
			--	fromlocation.x, fromlocation.y, tolocation.x, tolocation.y, testLocation.x, testLocation.y, self.closed[testNode.lid], util.tcount(self.closed))
			return self.closed[testNode.lid]
		end

		nextNode = self:_getBestOpenNode()
	end

	--log:write("No true-cost heuristic for (%d, %d) (%d closed)", testLocation.x, testLocation.y, util.tcount(self.closed))
	-- Cache this unreachable node in the closed list.
	self.closed[testNode.lid] = nil

	return nil
end

return
{
	AStar = AStar,
	Path = Path,
	Node = Node,
}

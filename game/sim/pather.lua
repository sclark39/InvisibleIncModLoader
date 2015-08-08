local util = include( "modules/util" )
local simunit = include( "sim/simunit" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simplayer = include( "sim/simplayer" )
local mathutil = include( "modules/mathutil" )

local Pather = class()

function Pather:init( sim )
	self._paths = {}
	self.nextPathID = 1
	self._pathReserves = {}
	self._lastPathStart = 1
	self._prioritisedPaths = {}
	self._boardw = sim:getBoardSize()
	self._sim = sim

	--sim:addTrigger( simdefs.TRG_START_TURN, self )
end

function Pather:checkPathReservation(x, y, t)
	if x and y and t then
		return self:checkPathReservation(self:getNodeLid(x, y, t) )
	end
	local lid = x
	return self._pathReserves[lid]
end

function Pather:getNodeLid(x, y, t)
	return 1000 * (y * self._boardw + x) + t
end

function Pather:checkPathStart(x, y)
	return self:checkPathReservation(x, y, 0)
end

function Pather:checkPathEnd(x, y)
	for k, path in pairs(self._paths) do
		if path.path and #path.path:getNodes() > 0 then
			local lastNode = path.path:getNodes()[#path.path:getNodes()]
			if lastNode.location.x == x and lastNode.location.y == y then
				local reservation = self:checkPathReservation(lastNode.lid)
				if reservation then
					return reservation
				end
			end
		end
	end
end

function Pather:calculatePath(unit)
	local astar = include ("modules/astar" )
	local astar_handlers = include("sim/astar_handlers")
	local path = self:getPath(unit)
	if not path then
		return
	end
	local sim = unit:getSim()
	if path.result ~= nil then
		simlog( simdefs.LOG_PATH, "(%d) - PATH already has a result (%s)", path.unit:getID(), path.result )
	elseif not unit or unit:isKO() or not unit:getLocation() then
		simlog( simdefs.LOG_PATH, "(%d) - KILLED PATH due to invalid unit", path.unit:getID() )
		path.result = simdefs.CANMOVE_FAILED
	else
		local fromlocation = sim:getCell( unit:getLocation() )
		local goalx, goaly = path.goalx, path.goaly
		if path.targetUnit and path.targetUnit:isValid() then
			goalx, goaly = path.targetUnit:getLocation()
		end
		local tolocation = sim:getCell( goalx, goaly )
		if fromlocation and tolocation then
			local trueCost = astar.AStar:new( astar_handlers.aihandler:new(unit) )
			local handler = astar_handlers.coop_handler:new(unit, 
				function( to_cell, from_node, goal_cell )
					return trueCost:findNodeCost( tolocation, fromlocation, to_cell )
				end )

			local pather = astar.AStar:new( handler )
			simlog(simdefs.LOG_PATH, "(%d) - Calculating Path (%d, %d) -> (%d, %d)", path.unit:getID(), fromlocation.x, fromlocation.y, tolocation.x, tolocation.y )
			path.path = pather:findPath( fromlocation, tolocation )
			if path.path then
				path.result = nil
				unit:getPather():addDoorBreakActions(path)
				unit:getPather():addThrowGrenadeActions(path)
				unit:getPather():addPinningActions(path)

				path.iter = 0
				path.currentNode = path.path:getStartNode()
			else
				simlog(simdefs.LOG_PATH, "(%d) - NO PATH FOUND to (%d, %d)", path.unit:getID(), path.goalx, path.goaly )
				path.result = simdefs.CANMOVE_NOPATH
			end
		else
			--can't path to or from nowhere
			path.result = simdefs.CANMOVE_NOPATH
		end
	end
	return path.result
end

function Pather:reserveNode(node, prevNode, path)
	local reservation = {node=prevNode, path=path}
	--simlog( simdefs.LOG_PATH, "\tRESERVE %d (%d,%d,t=%d)", node.lid, prevNode.location.x, prevNode.location.y, node.t )
	self._pathReserves[ node.lid ] = reservation
end

function Pather:unreserveNode(path, node)
	if self._pathReserves[ node.lid ] and self._pathReserves[ node.lid ].path == path then
		--simlog( simdefs.LOG_PATH, "\tUNRESERVE %d (%d,%d,t=%d)", node.lid, node.location.x, node.location.y, node.t )
		self._pathReserves[ node.lid ] = nil
	end
end


function Pather:reservePath(path)
	local prevNode = path.path:getStartNode()
	-- Reserve starting location (t = 0) so that other units needing to path through this location at (t = 1) know
	-- that they must wait for this unit to execute its path first.
	self:reserveNode(prevNode, prevNode, path)

	for i, node in ipairs(path.path:getNodes()) do
		assert( self._pathReserves[ node.lid ] == nil )
		self:reserveNode(node, prevNode, path)
		prevNode = node
	end
end

function Pather:calculatePathPriority(path)
	priority = 0
	if path.path then
		if path.result == simdefs.CANMOVE_INVALIDATED then
			priority = priority + 1000
		end
		for i, node in ipairs(path.path:getNodes()) do
			local pathStart = self:checkPathStart(node.location.x, node.location.y)
			if pathStart and pathStart.path.unit ~= path.unit then
				priority = priority + 100
			end
			local pathEnd = self:checkPathEnd(node.location.x, node.location.y)
			if pathEnd and pathEnd.path.unit ~= path.unit then
				priority = priority - 100
			end
			for i = 0, node.t-1 do
				local waitPoint = self:checkPathReservation(node.location.x, node.location.y, i)
				if waitPoint and waitPoint.path.unit ~= path.unit then
					priority = priority + 1
				end
			end
		end
	end
	return priority
end

function Pather:prioritisePaths()
	local prioritisedPaths = {}

	for k, path in pairs(self._paths) do
		path.priority = self:calculatePathPriority(path)
		table.insert(prioritisedPaths, path)
	end
	table.sort(prioritisedPaths, function(a, b) if a.priority == b.priority then return a.id < b.id else return a.priority < b.priority end end)

	for i, path in ipairs(prioritisedPaths) do
		if path.order and path.order ~= i then
			simlog(simdefs.LOG_PATH, "(%d) - RECALCULATING PATH AFTER PRIORITY CHANGE (%d -> %d)", path.unit:getID(), path.order, i )
			self:unreservePath(path)
			path.result = nil
			self:calculatePath(path.unit)
			if path.path and path.unit:getTraits().dynamicImpass then
				self:reservePath(path)
			end
		end
		path.order = i
	end

	self._prioritisedPaths = prioritisedPaths
end


function Pather:unreservePath(path)
	if path.currentNode then
		self:unreserveNode(path, path.currentNode)
		path.currentNode = nil
	end
	if path.path then
		local nodes = path.path:getNodes()
		while #nodes > 0 do
			path.currentNode = table.remove( nodes, 1 )
			self:unreserveNode(path, path.currentNode)
		end
		path.actions = {}
	end
end

function Pather:requestPath(unit, dest)
	assert( unit:getPather() == self )
	assert( dest and dest.x and dest.y )

	if self._paths[ unit:getID() ] ~= nil then
		self:removePath( unit ) -- Yikes, remove existing path first!
	end

	local path =
	{
		id = self.nextPathID,
		unit = unit,
		goalx = dest.x,
		goaly = dest.y,
		goaldir = dest.facing,
		targetUnit = dest.unit,
		iter = 0,
		path = nil,
		actions = {},
		priority = 0,
		result = nil,
		steps = 0,
	}
	self.nextPathID = self.nextPathID + 1

	self._paths[ unit:getID() ] = path
end

function Pather:removePath( unit )
	local path = self._paths[ unit:getID() ]
	if path ~= nil then
		--simlog( simdefs.LOG_PATH, "[%d] removing path", unit:getID() )
		self:unreservePath(path)
		self._paths[ unit:getID() ] = nil
		unit:getSim():dispatchEvent( simdefs.EV_UNIT_GOALS_UPDATED, {unitID = unit:getID()} )		
	end
end

function Pather:invalidatePath(unit)
	simlog( simdefs.LOG_PATH, "(%d) invalidating path", unit:getID() )
	local path = self._paths[ unit:getID() ]
	if path then
		path.result = simdefs.CANMOVE_INVALIDATED
		self:unreservePath(path)
	end
end

function Pather:addActionToPath(path, node, action)
	path.actions[node.lid] = action
	if action.keepPathing == false then
		--all the rest of our nodes need to be right here!
		self:invalidatePathsCrossingCell(node.location.x, node.location.y, node.t, path.unit)
		local newLid
		for i, nextNode in ipairs(path.path:getNodes() ) do
			local nextNodeLocation = util.tdupe(nextNode.location)
			if nextNode.t > node.t and (nextNodeLocation.x ~= node.location.x or nextNodeLocation.y ~= node.location.y) then
				newLid = self:getNodeLid(node.location.x, node.location.y, nextNode.t)
				nextNode.location = util.tdupe(node.location)
				nextNode.lid = newLid
				--invalidate paths that cross the rest of this path, in case they were moving out of the way for us. Commented out because not super needed and currently invalidates this path too
				--self:invalidatePathsCrossingCell(nextNodeLocation.x, nextNodeLocation.y, nextNode.t, path.unit)
			end
		end
	end
end

function Pather:getActionForNode(path, node)
	return path.actions and path.actions[node.lid]
end

function Pather:invalidatePathsCrossingCell(x, y, t, unit)
	for k,path in pairs(self._paths) do
		if path.path then
            local startNode = path.currentNode
            if not startNode or not self._sim:isVersion( "0.17.2" ) then
                startNode = path.path:getStartNode()
            end

			if #path.path:getNodes() == 0 and path.currentNode and path.currentNode.location.x == x and path.currentNode.location.y == y then
				--fix special case where active path needs to be invalidated
                -- Note: this block is not needed after 0.17.2, due to startNode being assigned to currentNode. 
				self:invalidatePath(path.unit)
			else
				local node = startNode
				local i = 1
				repeat 
					if x == node.location.x and y == node.location.y and (not t or node.t > t) and path.unit ~= unit then
						self:invalidatePath(path.unit)
						break
					end
					node = path.path:getNodes()[i]
					i = i + 1
				until not node
			end
		end
	end
end

function Pather:invalidatePathsWithThrows()
	for k,path in pairs(self._paths) do
		for kk, action in pairs(path.actions) do
			if action.ability == "throw" then
				self:invalidatePath(path.unit)
				break
			end
		end
	end
end

function Pather:getPath( unit )
	return self._paths[ unit:getID() ]
end

function Pather:getPaths()
    -- If this could be const, I would make it so!  DONT FIDDLE WITH PATHS.
	return self._paths
end

function Pather:addDoorBreakActions(path)

	local abilityDef = path.unit:ownsAbility("breakDoor")
	if not abilityDef then
		return
	end

	if not path.unit:isAlerted() then
		return
	end

	local interest = path.unit:getBrain():getInterest()
	if path.unit:getBrain():getDestination() ~= interest then
		return
	end

	--don't kick doors down for these reasons
	if interest.reason == simdefs.REASON_HUNTING or
	 interest.reason == simdefs.REASON_PATROLCHANGED then
		return
	end


	local finalNode = path.path:getNodes()[#path.path:getNodes()]
	local finalCell = self._sim:getCell(finalNode.location.x, finalNode.location.y)

	--don't kick doors down if our interest doesn't lie on the other side of it
	if finalCell.x ~= interest.x or finalCell.y ~= interest.y then
		return
	end

	local secondLastNode = path.path:getStartNode()
	if #path.path:getNodes() > 1 then
		--step back through the path trying to find a node that isn't the finish
		for i = #path.path:getNodes(), 1, -1 do
			local node = path.path:getNodes()[i]
			if node.location ~= finalNode.location then
				secondLastNode = node
				break
			end
		end
	end
	if not secondLastNode then
		simlog( simdefs.LOG_PATH, "(%d) path not long enough to break door", path.unit:getID())
		return
	end
	local secondLastCell = self._sim:getCell(secondLastNode.location.x, secondLastNode.location.y)
	local doorDir = simquery.getDirectionFromDelta(finalCell.x-secondLastCell.x, finalCell.y-secondLastCell.y)
	if simquery.checkIsDoor(self._sim, secondLastCell, doorDir) and abilityDef:canUseAbility(self._sim, path.unit, path.unit, secondLastCell, doorDir) then
		--add a breakDoor action to the path
		simlog( simdefs.LOG_PATH, "(%d) path adding breakDoor action at (%d, %d) %s", path.unit:getID(), secondLastCell.x, secondLastCell.y, simdefs:stringForDir(doorDir))
		self:addActionToPath(path, secondLastNode, {ability="breakDoor", owner=path.unit, user=path.unit, params={}, keepPathing=true } ) 
	end
end

function Pather:addThrowGrenadeActions(path)

	local abilityDef, grenadeUnit = path.unit:ownsAbility("throw")
	if not abilityDef or not grenadeUnit then
		return
	end

	if not grenadeUnit:getTraits().shouldNpcThrow then
		return
	end

	local interest = path.unit:getBrain():getInterest()
	if not interest then
		return
	end

	local x0, y0 = path.unit:getLocation()
	local destination = path.unit:getBrain():getDestination()
	if destination ~= interest then
		return
	end

	if destination.x == x0 and destination.y == y0 then
		return
	end

	if interest.grenadeHit then
		return
	end

	--don't throw at interests we could see
	local dir = simquery.getDirectionFromDelta(interest.x - x0, interest.y - y0)
	if simquery.couldUnitSeeCell(self._sim, path.unit, self._sim:getCell(interest.x, interest.y) ) then
		return
	end

	--find the first part of the path that gives us LOS to the interest
	local throwRange = path.unit:getTraits().maxThrow or 0
	local minThrowRange = path.unit:getTraits().minThrow or 0
	local targetCell = self._sim:getCell(path.goalx, path.goaly)

	minThrowRange = math.max(minThrowRange, grenadeUnit:getTraits().range)	--don't throw if we'll be inside the grenade radius

	local cellsInRange = {}
	table.insert(cellsInRange, targetCell)
	local aimRange = grenadeUnit:getTraits().aimRange or grenadeUnit:getTraits().range
	if aimRange and aimRange > 0 then
		--only cells in range with LOS to the targetcell should be considered
		for i,testCell in ipairs(simquery.fillCircle( self._sim, targetCell.x, targetCell.y, aimRange, 0) ) do
			if testCell ~= targetCell then
				local raycastX, raycastY = self._sim:getLOS():raycast(testCell.x, testCell.y, targetCell.x, targetCell.y)
				if raycastX == targetCell.x and raycastY == targetCell.y then
					table.insert(cellsInRange, testCell)
				end
			end
		end
	end
	local possibleNodes = {}
	local node = path.path:getStartNode()
	local i = 1
	repeat
		local startCell = self._sim:getCell(node.location.x, node.location.y)
		local closestCell, closestDist, closestThrowDist
		if startCell ~= targetCell then
			for k, endCell in ipairs(cellsInRange) do
				local throwDist = mathutil.dist2d(startCell.x, startCell.y, endCell.x, endCell.y)
				if throwDist < throwRange and throwDist > minThrowRange then
					local raycastX, raycastY = self._sim:getLOS():raycast(startCell.x, startCell.y, endCell.x, endCell.y)
					if raycastX == endCell.x and raycastY == endCell.y then
						--it's a valid cell to throw to
						local distSqFromTarget = mathutil.distSqr2d(endCell.x, endCell.y, targetCell.x, targetCell.y)
						if not closestCell or distSqFromTarget < closestDist then 
							closestCell = endCell
							closestDist = distSqFromTarget
							closestThrowDist = throwDist
						end
					end
				end
			end
		end
		if closestCell then
			table.insert(possibleNodes, {node=node, cell=closestCell, dist=closestDist, throwDist=closestThrowDist})
		end

		node = path.path:getNodes()[i]
		i = i + 1
	until not node

	--pick the best possible node
	if next(possibleNodes) then
		table.sort(possibleNodes, function(a, b)
			if a.dist == b.dist then
				return a.throwDist > b.throwDist
			else
				return a.dist < b.dist
			end
		end)
		local node, cell = possibleNodes[1].node, possibleNodes[1].cell
		--add a ThrowGrenade action to the path
		local target = {cell.x, cell.y}
		simlog( simdefs.LOG_PATH, "(%d) path adding throw action from (%d, %d) to (%d, %d)", path.unit:getID(), node.location.x, node.location.y, cell.x, cell.y) 
		self:addActionToPath(path, node, {ability="throw", owner=grenadeUnit, user=path.unit, params={target}, keepPathing = grenadeUnit:getTraits().keepPathing } ) 
	end

end

function Pather:addPinningActions(path)
	local x0, y0 = path.unit:getLocation()
	local interest = path.unit:getBrain():getInterest()
	if not interest or not interest.sourceUnit then
		return
	end

	if not simquery.isEnemyAgent(path.unit:getPlayerOwner(), interest.sourceUnit) then
		return
	end

	local destination = path.unit:getBrain():getDestination()
	if destination ~= interest then
		return
	end

	local destCell = self._sim:getCell(destination.x, destination.y)
	if not destCell then
		return
	end

	if not interest.sourceUnit:isKO() then
		return
	end

	if interest.sourceUnit:isDead() or interest.sourceUnit:getTraits().iscorpse then
		return
	end

	if simquery.isUnitPinned(self._sim, interest.sourceUnit) then
		return
	end

	local node = path.path:getStartNode()
	local i = 1
	repeat
		if node.location.x == destination.x and node.location.y == destination.y then
			self:addActionToPath(path, node, {ability="pin", keepPathing=false} )
			break
		end
		node = path.path:getNodes()[i]
		i = i + 1
	until not node
end

return Pather

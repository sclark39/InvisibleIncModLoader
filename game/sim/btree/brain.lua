require("class")

local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local mathutil = include( "modules/mathutil" )
local simquery = include( "sim/simquery" )

local Senses = include("sim/btree/senses")

-- Base class for a component that owns and manages a behaviour tree
local Brain = class(function(self, brainName, tree)
	self.ClassType = brainName
	self.rootNode = tree
	self.situation = nil
	self.shouldReset = false
	self.senses = nil
	self.target = nil
	self.interest = nil
end)

--Used to intiailise the leaf nodes of the tree with the data they need
function Brain:setupNode(node)
	assert(node ~= nil, "Trying to setup nil node in btree")
	if node.children then
		for k, v in pairs(node.children) do
			self:setupNode(v)
		end
	elseif node.child then
		self:setupNode(node.child)
	elseif node.setup then
		node:setup(self.sim, self.unit)
	end
end

function Brain:cancelNode(node)
	if node.children then
		for k, v in pairs(node.children) do
			self:cancelNode(v)
		end
	end
	if node.child then
		self:cancelNode(node.child)
	end
	if node.cancel then
		node:cancel()
	end
	node.status = simdefs.BSTATE_FAILED
end

--these are called when the brain's owner is spawned or despawned
function Brain:onSpawned(sim, unit)
	self.sim = sim
	self.unit = unit
	self.senses = Senses()
	self.senses:onSpawned(sim, unit)
	self:setupNode(self.rootNode)
	if self.setUp then
		self:setUp()
	end
end

function Brain:onDespawned()
	self:setSituation(nil)
	self:setDestination(nil)

	self:reset()
	if self.tearDown then
		self:tearDown()
	end
	self.senses:onDespawned()
	self.sim = nil
	self.unit = nil
	self.senses = nil
	self.target = nil
	self.interest = nil
end

-- performs a tick of thinking. The brain should return "COMPLETE", "FAILED" or "SUSPENDED" to finish thinking for that unit.
-- If the tree returns "RUNNING" then the unit gets to think again next tick
function Brain:think()
	if self.rootNode then
		if self.shouldReset or not self.rootNode:isRunning() then
			simlog( simdefs.LOG_AI, "Resetting brain for [%s]: %s", tostring(self.unit:getID() ), self.shouldReset and "ShouldReset" or self.rootNode.status )
			self.rootNode:reset()
			self.shouldReset = false
		end
		self.thinking = true
		local status = self.rootNode:tick()
		self.thinking = nil
		if self.shouldReset then
			return simdefs.BSTATE_RUNNING
		end
		return status
	end
end

function Brain:shouldTick()
	if self.thinking then
		return false
	end

	if self.shouldReset then
		return true
	end

	if self.unit:getPather() then
		local path = self.unit:getPather():getPath(self.unit)
		if path then
			if path.result and path.result == simdefs.CANMOVE_INVALIDATED then
				return true
			end
			if path.path then
				local x,y = self.unit:getLocation()
				local startNode = path.path:getStartNode()
				if startNode.location.x ~= x or startNode.location.y ~= y then
					return true
				end
			end
		end
	end

	if self.unit:getSim():getCurrentPlayer() == self.unit:getPlayerOwner() then
		if self.rootNode.status == simdefs.BSTATE_WAITINGFORPCTURN
		 or self.rootNode.status == simdefs.BSTATE_COMPLETE then
		    return false
		end
	else
		if self.unit:getSim():getTurnState() == simdefs.TURN_STARTING then
			return true
		else
			if self.rootNode.status == simdefs.BSTATE_WAITINGFORCORPTURN
			 or self.rootNode.status == simdefs.BSTATE_RUNNING
			 or self.rootNode.status == simdefs.BSTATE_WAITING then
			    return false
			end
		end
	end

	return true
end

function Brain:setSituation(situation)
	if situation ~= self.situation then
		if self.situation then
			if self.onLeaveSituation then
				self:onLeaveSituation(self.situation)
			end

			self.situation:removeUnit(self.unit)
		end

		self.situation = situation
		if self.situation then
			self.situation:addUnit(self.unit)

			if self.onEnterSituation then
				self:onEnterSituation(self.situation)
			end

			if self.sim then
				self.sim:triggerEvent(simdefs.TRG_SITUATION_CHANGE, { unit=self.unit } )
		    	self.sim:dispatchEvent( simdefs.EV_UNIT_REFRESH_SITUATION, { unit = self.unit, situation = situation })
	    	end
		end
        self.unit:destroyTab() -- Shutdown the observed, or indeed any, tab.
	end
end

function Brain:getSituation()
	return self.situation
end

function Brain:setTarget(target)
	if target then
		if self.unit:setAlerted(true) then
            self.unit:getTraits().trackerAlert = { 1, STRINGS.UI.ALARM_SPOTTED, self.unit:getLocation() }
        end
	end
	if target ~= self.target then
		simlog( simdefs.LOG_AI, "Changing target for [%s] from %s to %s",
			tostring(self.unit:getID() ),
			self.target and self.target:isValid() and "["..tostring(self.target:getID()).."]" or "none",
			target and target:isValid() and "["..tostring(target:getID()).."]" or "none")
		self:reset()
		if target then
			self.unit:interruptMove( self.sim )
			self.sim:triggerEvent(simdefs.TRG_UNIT_NEWTARGET, {unit=self.unit, target=target})

		    if self.unit:getTraits().AOEFirewallsBuff then
		    	local x1,y1 = self.unit:getLocation()
		    	local range = self.unit:getTraits().AOEFirewallsBuffRange
		    	local buff = self.unit:getTraits().AOEFirewallsBuff
		    	self.sim:AOEbuffFirewalls(x1,y1,range,buff)
		    end			

		     if self.unit:getTraits().buffArmorOnKO then
		     	self.unit:buffArmor( self.sim, self.unit:getTraits().buffArmorOnKO )
		     end
		end
	end
	self.target = target
end

function Brain:getTarget()
	return self.target
end

function Brain:getPatrolPoint()
	local waypoints = self.unit:getTraits().patrolPath
	if waypoints then
        if not self.unit:getTraits().nextWaypoint then
            self.unit:getTraits().nextWaypoint = self.unit:getBrain():getNextPatrolPoint()
		end
        local unitX, unitY = self.unit:getLocation()
		local waypoint = waypoints[self.unit:getTraits().nextWaypoint]
		local mode

		if not waypoint or (unitX == waypoint.x and unitY == waypoint.y) then
			waypoint, mode = self.unit:getBrain():getNextPatrolPoint()
			self.unit:getTraits().nextWaypoint, self.unit:getTraits().patrolmode = waypoint, mode
		end

		return waypoints[ self.unit:getTraits().nextWaypoint ]
	end
end

function Brain:getNextPatrolPoint()
	local waypoints = self.unit:getTraits().patrolPath
	if not waypoints then
		return
	end

	local unitX, unitY = self.unit:getLocation()
	if not unitX then
		unitX, unitY = waypoints[1].x, waypoints[1].y
	end
	local maxWaypoint = #waypoints

	if not self.unit:getTraits().nextWaypoint or not self.unit:getTraits().patrolmode then
		--pick the closest waypoint
		local closestWaypoint, closestDist
		for k,v in ipairs(waypoints) do
			local distance = mathutil.dist2d(unitX, unitY, v.x, v.y)
			--don't pick a waypoint we're standing on unless there literally is only one waypoint.
			if distance > 0 or #waypoints == 1 then
				if not closestWaypoint or distance < closestDist then
					closestWaypoint = k
					closestDist = distance
				end
			end
		end
		return closestWaypoint, simdefs.PATROL_FORWARD
	end

	if self.unit:getTraits().patrolmode == simdefs.PATROL_LOOPING or maxWaypoint <= 2 then
		return (self.unit:getTraits().nextWaypoint % maxWaypoint) + 1, simdefs.PATROL_LOOPING
	elseif self.unit:getTraits().patrolmode == simdefs.PATROL_FORWARD then
		if self.unit:getTraits().nextWaypoint >= maxWaypoint then
			return maxWaypoint - 1, simdefs.PATROL_BACK
		else
			return self.unit:getTraits().nextWaypoint + 1, simdefs.PATROL_BACK
		end
	elseif self.unit:getTraits().patrolmode == simdefs.PATROL_BACK then
		if self.unit:getTraits().nextWaypoint <= 1 then
			return 2, simdefs.PATROL_FORWARD
		else
			return self.unit:getTraits().nextWaypoint - 1, simdefs.PATROL_FORWARD
		end
	end
end

function Brain:spawnInterest(x, y, sense, reason, sourceUnit)
	local interest = self:getSenses():addInterest(x, y, sense, reason, sourceUnit)
	if interest then
		interest.remember = true
	end
	self.unit:getSim():processReactions(self.unit)
end

function Brain:setInterest(interest)
	if interest and self.interest and self.senses:isSameInterest(interest, self.interest) then
		self.interest = interest
		self.sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_INTEREST, { unit = self.unit } )
		return
	elseif interest or self.interest then
		if self.interest then
			self.sim:dispatchEvent( simdefs.EV_UNIT_DEL_INTEREST, {unit = self.unit, interest = self.interest} )
		end
		if interest then
			self.unit:interruptMove( self.sim )
			self:reset()
			self.sim:dispatchEvent( simdefs.EV_UNIT_ADD_INTEREST, { unit = self.unit, interest = interest} )
			self.sim:triggerEvent(simdefs.TRG_UNIT_NEWINTEREST, {unit=self.unit, interest=interest})
		end
		self.interest = interest
	end
end

function Brain:getInterest()
	return self.interest
end

function Brain:getSenses()
	return self.senses
end

function Brain:setDestination(dest)
	if dest then
		if dest.getID then
			dest = {x=dest._x, y=dest._y, unit=dest}	--and override dest with a table with x and y values
		end
		assert(dest.x ~= nil and dest.y ~= nil)
		self.unit:getPather():requestPath(self.unit, dest)
	else
		self.unit:getPather():removePath(self.unit)
	end
	self.destination = dest
end

function Brain:getDestination()
	return self.destination
end

function Brain:reset()
	self.shouldReset = true
	if self.rootNode:isRunning() then
		self:cancelNode(self.rootNode)
	end
end

function Brain:onStartTurn( sim )
end

function Brain:getBTreeString()
	local debugText = string.format("%s - %s\n---------------\n%s", self.ClassType, tostring(self.rootNode.status),  self.rootNode:getDebugString() )
	return debugText
end

return Brain

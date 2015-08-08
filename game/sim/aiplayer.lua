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
local cdefs = include( "client_defs" )

local IdleSituation = include("sim/btree/situations/idle")
local InvestigateSituation = include("sim/btree/situations/investigate")
local CombatSituation = include("sim/btree/situations/combat")
local HuntSituation = include("sim/btree/situations/hunt")
local FleeSituation = include("sim/btree/situations/flee")

local Pather = include("sim/pather")


-----------------------------------------------------
-- Interface functions

local aiplayer = class( simplayer )

function aiplayer:init( sim )
	simplayer.init( self, sim )

	self.pather = Pather(sim)

	self.situations = {}
	self.situations[simdefs.SITUATION_IDLE] = IdleSituation()
	self.situations[simdefs.SITUATION_INVESTIGATE] = {}
	self.situations[simdefs.SITUATION_HUNT] = {}
	self.situations[simdefs.SITUATION_COMBAT] = {}
	self.situations[simdefs.SITUATION_FLEE] = {}

	self.prioritisedUnits = {}
	self.processedUnits = {}

	--we don't need to bother about removing these triggers, because the sim is removed when the player is
	sim:addTrigger( simdefs.TRG_START_TURN, self )
	sim:addTrigger( simdefs.TRG_ALARM_STATE_CHANGE, self )

	sim:forEachCell( function( c ) self:glimpseCell( sim, c ) end )
end


function aiplayer:createGuard(sim,unitType)
	local unitData = unitdefs.lookupTemplate( unitType )
	local newUnit = simfactory.createUnit( unitData, sim )
	newUnit:setPlayerOwner( self )	
	newUnit:setPather(self.pather)
	sim:spawnUnit( newUnit )
    newUnit:getTraits().cashOnHand = 0 
    if newUnit:getTraits().PWROnHand then
     	newUnit:getTraits().PWROnHand = 0 
    end	
    if newUnit:getTraits().mainframe_ice and not newUnit:getTraits().omni then
        local firewallMultiplier = sim:getParams().difficultyOptions.firewallMultiplier
        newUnit:getTraits().mainframe_ice = newUnit:getTraits().mainframe_ice + math.ceil( newUnit:getTraits().mainframe_ice * firewallMultiplier )
        newUnit:getTraits().mainframe_iceMax = newUnit:getTraits().mainframe_iceMax + math.ceil( newUnit:getTraits().mainframe_iceMax * firewallMultiplier )
    end
	return newUnit
end

function aiplayer:spawnGuards(sim, unitType, numGuards)
	local cells = sim:getCells( "guard_spawn" )
    if cells then
        cells = util.tdupe( cells )
	    local i = 1
	    while i <= #cells do
		    if not simquery.canStaticPath( sim, nil, nil, cells[i]) or simquery.checkDynamicImpass(sim, cells[i]) then
			    table.remove( cells, i )
		    else
			    i = i + 1
		    end
	    end
    end
    
    numGuards = math.min(numGuards, #cells)
 	local units = {}

    if numGuards > 0 then
		for i = 1, numGuards do
			table.insert(units, self:createGuard(sim, unitType ))
		end

	   for i,unit in ipairs(units)do
		    if cells and #cells > 0 then
			    local cell = table.remove( cells, sim:nextRand( 1, #cells ))		   
			    sim:warpUnit(unit, cell)
			    self:returnToIdleSituation(unit)
		    end
		end

	    if #units == 1 then
	 	    sim:dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "threatDialog", dialogParams = { units[1] }} )
	    end

	 	for i,unit in ipairs(units)do
	  		sim:dispatchEvent( simdefs.EV_UNIT_APPEARED, { unitID = unit:getID() } )		
		 	sim:dispatchEvent( simdefs.EV_TELEPORT, { units = { unit }, warpOut = false } )
		    sim:getPC():glimpseUnit( sim, unit:getID() )
		end
	end

    return units
end

function aiplayer:doTrackerSpawn( sim, numGuards, unitType, newPatrol )
	local units = self:spawnGuards(sim, unitType, numGuards )

	for i,unit in ipairs(units) do
		if unit and unit:isValid() then
			if sim:getCurrentPlayer() == self then
				unit:useMP(unit:getMP(), sim)
			end
			if newPatrol then
                self:getIdleSituation():generatePatrolPath( unit )
                if unit:getTraits().patrolPath and #unit:getTraits().patrolPath > 1 then
					local firstPoint = unit:getTraits().patrolPath[1]
					unit:getBrain():getSenses():addInterest(firstPoint.x, firstPoint.y, simdefs.SENSE_RADIO, simdefs.REASON_PATROLCHANGED, unit)
				end
			else
				unit:setAlerted(true)
				self:createOrJoinHuntSituation(unit)
			end
			sim:processReactions(unit)
		end		
	end
end

function aiplayer:updateTracker(sim )

	if sim:getEnforcersToSpawn() > 0 then 
		if sim._params.difficulty < 3 then
			for i=1,sim:getEnforcersToSpawn() do 
				self:doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER )
			end
		else
			for i=1,sim:getEnforcersToSpawn() do 
				self:doTrackerSpawn(sim, 1, simdefs.TRACKER_SPAWN_UNIT_ENFORCER_2 )
			end
		end
		sim:resetEnforcersToSpawn()
	end
end

function aiplayer:huntAgents(count)
	local hunters = {}
	for _,agent in ipairs(self._sim:getPC():getUnits() ) do
		if count > 0 and simquery.isAgent(agent) and not agent:isDown() and not agent:getTraits().takenDrone and not self:isAgentHunted(agent) then
			--find the closest hunter
			local closestHunter, closestDist
			for _, hunt in ipairs(self.situations[simdefs.SITUATION_HUNT]) do
				for _, hunter in pairs(hunt.units) do
					if hunter:isValid() and not hunter:isDown() and not hunters[hunter:getID()] then
						local x,y = hunter:getLocation()
						local straightDist = mathutil.dist2d(x, y, agent:getLocation() )
						if not closestHunter or straightDist < closestDist then
							closestHunter = hunter
							unit = agent
							closestDist = straightDist
						end
					end
				end
			end

			if closestHunter then
				hunters[closestHunter:getID()] = agent
				local x,y = agent:getLocation()
				agent:getSim():dispatchEvent( simdefs.EV_SHOW_DIALOG, { dialog = "locationDetectedDialog", dialogParams = { agent }} )
				closestHunter:getBrain():spawnInterest(x, y, simdefs.SENSE_RADIO, simdefs.REASON_HUNTING, agent)
				count = count - 1
			end
		end		
	end
end

function aiplayer:isAgentHunted(unit)
	for k, situation in pairs(self.situations[simdefs.SITUATION_HUNT]) do
		for kk,huntTarget in pairs(situation.huntTargets) do
			if situation:isValid() and huntTarget.targetUnit and huntTarget.targetUnit == unit then
				return true
			end
		end
	end

	return false
end

local function hasBrainAndNotKO( unit )
    return unit:getBrain() ~= nil and not unit:isKO() 
end

local function shouldNoticeInterests( unit )
    return unit:getBrain() ~= nil and not unit:isKO() and not unit:getTraits().camera_drone
end

function aiplayer:spawnInterest(x1,y1, sense, reason, sourceUnit)
	local closestGuard = simquery.findClosestUnit( self:getUnits(), x1, y1, shouldNoticeInterests )
	if closestGuard then
		closestGuard:getBrain():spawnInterest(x1, y1, sense, reason, sourceUnit)				
    end
end

function aiplayer:spawnInterestWithReturn(x1,y1, sense, reason, sourceUnit, guardsNotToCheck)
	local guardTable = {}
	for i, unit in pairs( self:getUnits() ) do 
		local found = false
		for _, unitID in ipairs( guardsNotToCheck ) do 
			if unit:getID() == unitID then 
				found = true
			end 
		end 
		if found == false then 
			table.insert( guardTable, unit )
		end 
	end 
	local closestGuard = simquery.findClosestUnit( guardTable, x1, y1, shouldNoticeInterests )
	if closestGuard then
		closestGuard:getBrain():spawnInterest(x1, y1, sense, reason, sourceUnit)		
		return closestGuard
    end
end


function aiplayer:isNPC()
	return true
end

function aiplayer:isPC()
	return false
end

function aiplayer:cleanUpSituations()
	for sitType,sits in pairs(self.situations) do
		if sitType ~= simdefs.SITUATION_IDLE then
			for i=#sits,1,-1 do --back to front
				local situation = sits[i]
				--remove any units from the situation that aren't valid
				for id,unit in pairs(situation.units) do
					if not situation:isUnitValid(unit) then
						if unit:isValid() then
							self:returnToIdleSituation(unit)
						else
							situation.units[id] = nil
						end
					end
				end
				--remove any situations that are no longer valid
				if not situation:isValid() then
					for id,unit in pairs(situation.units) do
						self:returnToIdleSituation(unit)
					end
					table.remove(sits, i)
				end
			end
		end
	end
end

function aiplayer:updateSenses(unit)
	local senses = unit:getBrain():getSenses()

	senses:update()

	local target = senses:getCurrentTarget()	--refresh target after the update
	unit:getBrain():setTarget(target)
	if target then
		self:createOrJoinCombatSituation(unit, target)
	end

	local interest = nil
	if not target and senses:getCurrentInterest() then
		interest = senses:getCurrentInterest()
		if interest and interest ~= unit:getBrain():getInterest() then
			if interest.alerts then
                if unit:setAlerted(true) and interest.reason == simdefs.REASON_FOUNDCORPSE then
                    unit:getTraits().trackerAlert = { 1, STRINGS.UI.ALARM_GUARD_BODY, unit:getLocation() }
                end
			end
			if unit:isAlerted() then
				if unit:getTraits().vip then
					self:createOrJoinFleeSituation(unit)
				elseif not (unit:getBrain():getSituation().ClassType == simdefs.SITUATION_HUNT and interest.reason == simdefs.REASON_HUNTING) then
					self:createOrJoinHuntSituation(unit, interest)
				end
			else
				self:createOrJoinInvestigateSituation(unit, interest)
			end
		end
	end
	unit:getBrain():setInterest(interest)

	if not target and not interest then
		self:returnToIdleSituation(unit)
	end
end

function aiplayer:tickBrain(unit)
    local thought = nil
	if unit:getBrain() and unit:isValid() then

		self:updateSenses(unit)

		if unit:isKO() or unit:isDead() then
			unit:getBrain():reset()
		elseif unit:getBrain():shouldTick() then
			thought = unit:getBrain():think()
		end

	end
    return thought
end

function aiplayer:onUnitAdded(unit)
	simplayer.onUnitAdded(self, unit)
	self:prioritiseUnits()
end

function aiplayer:onUnitRemoved(unit)
	simplayer.onUnitRemoved(self, unit)
	self:prioritiseUnits()
end

function aiplayer:tickAllBrains()
	for _,unit in pairs(self:getPrioritisedUnits() ) do
		self:tickBrain(unit)
	end

	--reactions
	for _,unit in pairs(self:getPrioritisedUnits() ) do
		if unit:getBrain() and unit:getBrain():getSenses():shouldUpdate() then

			simlog( simdefs.LOG_AI, "[%s] Reaction Double-Thinking", tostring(unit:getID() ))
			self:tickBrain(unit)
		end
	end

	if not self:getCurrentAgent() then
		self:prioritiseUnits()
	end
end

function aiplayer:prioritiseUnits()
	self.pather:prioritisePaths()

	-- Setup processing for path execution
	local bunits = {}
	for k,unit in ipairs(self:getUnits() ) do
		if unit:isValid() and unit:getBrain() then
			table.insert(bunits, unit)
		end
	end
	table.sort(bunits, function(a, b)
		local pathA, pathB = self.pather:getPath(a), self.pather:getPath(b)
		if pathA and pathB then
			if pathA.order and pathB.order then
				return pathA.order < pathB.order
			elseif pathA.order then
				return true
			elseif pathB.order then
				return false
			elseif pathA.priority == pathB.priority then
				return pathA.id < pathB.id
			else
				return pathA.priority < pathB.priority
			end
		elseif pathA then
			return false
		elseif pathB then
			return true
		else
			return a:getID() < b:getID()
		end
	end)

	self.prioritisedUnits = bunits
	self.processedUnits = {}
end

function aiplayer:getPrioritisedUnits()
	return self.prioritisedUnits
end

function aiplayer:thinkHard( sim )
	local st = os.clock()
	local steps = 0
	local pcPlayer = sim:getPC()


	self.bunits = util.tdupe(self.prioritisedUnits)
	local maxSteps = 50
	while #self.bunits > 0 and not pcPlayer:isNeutralized( sim ) and steps < maxSteps do

		-- Process behaviours once for each outstanding unit.
		local unit = table.remove(self.bunits, 1)
		self:setCurrentAgent(unit)
		if unit:isValid() then
			simlog( simdefs.LOG_AI, "[%s] Thinking", tostring(unit:getID() ))
		end
		local thought = self:tickBrain(unit)
		if thought and unit:isValid() then
			if thought == simdefs.BSTATE_RUNNING then
				--we got interrupted!
				simlog( simdefs.LOG_AI, "[%s] Thinking again immediately", tostring(unit:getID() ))
				table.insert(self.bunits, 1, unit)
			elseif thought == simdefs.BSTATE_WAITING then
				simlog( simdefs.LOG_AI, "[%s] Thinking again later: %s", tostring(unit:getID() ), unit:getBrain().rootNode.status )
				table.insert(self.bunits, unit)
			else
				table.insert(self.processedUnits, unit)
			end
		end
		self:setCurrentAgent(nil)


		steps = steps + 1
	end

	if steps > maxSteps then
		simlog("thinkhard() BAILING -- took %.1f ms", (os.clock() - st) * 1000 )
		for i, bunit in ipairs(bunits) do
			simlog("%s [%s]", bunit:getName(), bunit:isValid() and tostring(bunit:getID()) or "killed" )
		end
		bunits = {}
		steps = 0
		st = os.clock()
	end

	self:cleanUpSituations()
		
    sim:endTurn()
end

function aiplayer:getIdleSituation()
	return self.situations[simdefs.SITUATION_IDLE]
end

function aiplayer:returnToIdleSituation(unit)
	if unit:getTraits().enforcer or unit:isAlerted() then
		--try to rejoin the hunt situation they started in
		self:createOrJoinHuntSituation(unit, unit:getTraits().entryCell)
	elseif unit:getSim():getTracker() >= simdefs.TRACKER_MAXCOUNT then
		self:joinEnforcerHuntSituation(unit)
	else
		unit:getBrain():setSituation(self:getIdleSituation() )
	end
end

function aiplayer:findExistingInvestigateSituation(interest)
	for i,v in ipairs(self.situations[simdefs.SITUATION_INVESTIGATE]) do
		if v.interest == interest or (v.interest.sense == interest.sense and v.sourceUnit == interest.sourceUnit) then
			return v
		end
	end
end

function aiplayer:createOrJoinInvestigateSituation(unit, interest)
	--does a situation with this interest already exist?
	local situation = self:findExistingInvestigateSituation(interest)
	if not situation then
		situation = InvestigateSituation(unit, interest)
		table.insert(self.situations[simdefs.SITUATION_INVESTIGATE], situation)
	end

	if unit:getBrain() then
		unit:getBrain():setSituation(situation)
	end
	return situation
end


function aiplayer:findExistingCombatSituation(target)
	for i,v in ipairs(self.situations[simdefs.SITUATION_COMBAT]) do
		if v:hasTarget(target) then
			return v
		end
	end
end

function aiplayer:findExistingCombatSituationInRange(unit, range)
	local x0, y0 = unit:getLocation()
	for i,v in ipairs(self.situations[simdefs.SITUATION_COMBAT]) do
		for k, otherUnit in pairs(v.units) do
			local x1, y1 = otherUnit:getLocation()
			if mathutil.distSqr2d(x0, y0, x1, y1) <= range*range then
				return v
			end
		end
	end
end

function aiplayer:createOrJoinCombatSituation(unit, target)
	local situation = unit:getBrain():getSituation().ClassType == simdefs.SITUATION_COMBAT and unit:getBrain():getSituation()
	if not situation then
		situation = self:findExistingCombatSituation(target)
	end
	if not situation then
		situation = self:findExistingCombatSituationInRange(unit, simdefs.SOUND_RANGE_2)
	end
	if not situation then
		situation = CombatSituation()
		table.insert(self.situations[simdefs.SITUATION_COMBAT], situation)
	end
	situation:addTarget(target, unit)

	if unit:getBrain() then
		unit:getBrain():setSituation(situation)
	end

	return situation
end

function aiplayer:findExistingHuntSituation(targetCell)

	if targetCell and targetCell.procgenRoom then
		for i,v in ipairs(self.situations[simdefs.SITUATION_HUNT]) do
			if v.startingRoom.roomIndex == targetCell.procgenRoom.roomIndex then
				return v
			end
		end
	end
end

function aiplayer:createOrJoinHuntSituation(unit, target)
	local startingCell = target and self._sim:getCell(target.x, target.y)
	if not startingCell then
		startingCell = self._sim:getCell(unit:getLocation() )
	end
	local situation = self:findExistingHuntSituation(startingCell)
	if not situation then
		situation = HuntSituation(unit, startingCell)
		table.insert(self.situations[simdefs.SITUATION_HUNT], situation)
	end

	if unit:getBrain() then
		unit:getBrain():setSituation(situation)
	end

	if target and target.sense and target.reason then
		situation:overrideHuntTarget(unit, target)
	elseif startingCell ~= unit:getTraits().entryCell then
		situation:overrideHuntTarget(unit, {x=startingCell.x, y=startingCell.y})
	else
		situation:requestNewHuntTarget(unit)
	end
	
	return situation
end

function aiplayer:findExistingFleeSituation(unit)
	for i,v in ipairs(self.situations[simdefs.SITUATION_FLEE]) do
		if v:hasUnit(unit) then
			return v
		end
	end
end

function aiplayer:createOrJoinFleeSituation(unit)
	local situation = self:findExistingFleeSituation(unit)
	if not situation then
		situation = FleeSituation(unit)
		table.insert(self.situations[simdefs.SITUATION_FLEE], situation)
	end

	if unit:getBrain() then
		unit:getBrain():setSituation(situation)
	end
	
	return situation
end

function aiplayer:joinEnforcerHuntSituation(unit, target)
	local closestEnforcer, closestDist
	for _, v in ipairs(self:getUnits() ) do
		if v:getTraits().enforcer and v:getBrain():getSituation().ClassType == simdefs.SITUATION_HUNT then
			local x1, y1 = v:getLocation()
			local straightDist = mathutil.dist2d(x1, y1, unit:getLocation() )
			if not closestEnforcer or straightDist < closestDist then
				closestEnforcer = v
				closestDist = straightDist
			end
		end
	end

	if closestEnforcer then
		local situation = closestEnforcer:getBrain():getSituation()
		if situation then
			if unit:getBrain() then
				unit:getBrain():setSituation(situation)
			end

			local unitCell = unit:getSim():getCell(unit:getLocation() )
			local enforcerCell = unit:getSim():getCell(closestEnforcer:getLocation() )
			if target and target.sense and target.reason then
				situation:overrideHuntTarget(unit, target)
			elseif unitCell and unitCell.procgenRoom and enforcerCell.procgenRoom and unitCell.procgenRoom.roomIndex ~= enforcerCell.procgenRoom.roomIndex then
				situation:overrideHuntTarget(unit, {x=unitCell.x, y=unitCell.y})
			else
				situation:requestNewHuntTarget(unit)
			end
		end
	else
		self:createOrJoinHuntSituation(unit)
	end
end

function aiplayer:processReactions(unit)
	if unit and unit:getBrain() and unit:getPlayerOwner() == self then
		simlog( simdefs.LOG_AI, "Processing Reactions for [%s]", tostring(unit:getID() ) )
		self:updateSenses(unit)
		if unit:isValid() and unit:getBrain():shouldTick() then
			simlog( simdefs.LOG_AI, "[%s] Reaction Thinking", tostring(unit:getID() ))
			self:tickBrain(unit)
			if not self:getCurrentAgent() then
				self:prioritiseUnits()
			end
		end
	else
		simlog( simdefs.LOG_AI, "Processing All Reactions")
		self:tickAllBrains()
	end
end

function aiplayer:onEndTurn(sim)
	simplayer.onEndTurn(self, sim)
	if self._sim:getCurrentPlayer() == self then
		if sim:getParams().difficultyOptions.autoAlarm then
			sim:trackerAdvance(1, STRINGS.UI.ALARM_INCREASE )
		end
		self:updateTracker(sim)
	end
end

function aiplayer:onTrigger(sim, evType, evData)
	if evType == simdefs.TRG_START_TURN then
		simlog( simdefs.LOG_AI, "Processing and Clearing All Brains")
		for _,unit in pairs(self:getUnits() ) do
			if unit:getBrain() then
				unit:getBrain():getSenses():clearIgnoredInterests()
				unit:getBrain():getSenses():clearLostTargets()
				if self._sim:getCurrentPlayer() == self then
					if not unit:getBrain():getTarget() then
						unit:setAiming(false)
					end
				else
					self:tickBrain(unit)
				end
			end
		end
		if self._sim:getCurrentPlayer() ~= self then
			self:prioritiseUnits()
		end
	elseif evType == simdefs.TRG_ALARM_STATE_CHANGE then
		self:tickAllBrains()
	end
end

return aiplayer



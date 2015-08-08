local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local mathutil = include( "modules/mathutil" )

local SensePriorities = 
{
	[simdefs.SENSE_DEBUG] = 99,
	[simdefs.SENSE_SIGHT] = 99,
	[simdefs.SENSE_PERIPHERAL] = 99,
	[simdefs.SENSE_HEARING] = 99,
	[simdefs.SENSE_HIT] = 99,
	[simdefs.SENSE_RADIO] = 99,
}

local Senses = class()

function Senses:init(sim, unit)
	self.targets = {}
	self.currentTarget = nil
	self.interests = {}
	self.currentInterest = nil
	self.unit = nil
	self.knownInterests = 0
end

function Senses:onSpawned(sim, unit)
	self.unit = unit

	sim:addTrigger( simdefs.TRG_NEW_INTEREST, self )
	sim:addTrigger( simdefs.TRG_DEL_INTEREST, self )
	sim:addTrigger( simdefs.TRG_SOUND_EMITTED, self )
	sim:addTrigger( simdefs.TRG_UNIT_APPEARED, self )
	sim:addTrigger( simdefs.TRG_UNIT_DISAPPEARED, self )
	sim:addTrigger( simdefs.TRG_UNIT_USEDOOR_PRE, self )
	sim:addTrigger( simdefs.TRG_UNIT_HIT, self )
	sim:addTrigger( simdefs.TRG_UNIT_MISSED, self )
	sim:addTrigger( simdefs.TRG_UNIT_KO, self )
	sim:addTrigger( simdefs.TRG_UNIT_WARP, self )
	sim:addTrigger( simdefs.TRG_UNIT_DEPLOYED, self )
end

function Senses:onDespawned()
	self:clearTargets()
	self.unit:getSim():removeTrigger( simdefs.TRG_NEW_INTEREST, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_DEL_INTEREST, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_SOUND_EMITTED, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_APPEARED, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_DISAPPEARED, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_USEDOOR_PRE, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_HIT, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_MISSED, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_KO, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_WARP, self )
	self.unit:getSim():removeTrigger( simdefs.TRG_UNIT_DEPLOYED, self )
	self.unit = nil
end

function Senses:onTrigger(sim, evType, evData)
	if self:checkDisabled() then
		return
	end

	if evType == simdefs.TRG_NEW_INTEREST then
		self:processInterestShared(sim, evData)
	elseif evType == simdefs.TRG_DEL_INTEREST then
		self:processInterestRemoved(sim, evData)
	elseif evType == simdefs.TRG_SOUND_EMITTED then
		self:processSoundTrigger(sim, evData)
	elseif evType == simdefs.TRG_UNIT_APPEARED then		
		self:processAppearedTrigger(sim, evData)		
	elseif evType == simdefs.TRG_UNIT_DISAPPEARED then
		self:processDisappearedTrigger(sim, evData)
  	elseif evType == simdefs.TRG_UNIT_USEDOOR_PRE then
		self:processDoorTrigger(sim, evData)
	elseif evType == simdefs.TRG_UNIT_HIT then
		self:processAttackedTrigger(sim, evData)
	elseif evType == simdefs.TRG_UNIT_MISSED then
		self:processAttackedTrigger(sim, evData)
	elseif evType == simdefs.TRG_UNIT_KO then
		self:processKOTrigger(sim, evData)
	elseif evType == simdefs.TRG_UNIT_WARP then
		self:processWarpTrigger(sim, evData)
	elseif evType == simdefs.TRG_UNIT_DEPLOYED then
		self:processDeployedTrigger(sim, evData)		
	end
end

function Senses:update()
	if self:checkDisabled() then
		self.currentTarget = nil
		self.currentInterest = nil
		self:clearTargets()
		self.interests = {}
		self.knownInterests = 0
	else
		for k,target in pairs(self.targets) do
			if target.missing then
				self:removeTarget(target.unit)
				self:addInterest(target.x, target.y, simdefs.SENSE_SIGHT, simdefs.REASON_LOSTTARGET, target.unit)
			end
		end
		self:pickBestTarget()
		if not self.currentTarget then
			self:pickBestInterest()
			self.knownInterests = #self.interests
		end
	end
end

function Senses:shouldUpdate()
	if self:checkDisabled() then
		return false
	end

	if self.currentTarget then
		if not next(self.targets) then
			return true
		end
		if #self.targets > 1 then
			return true
		end
	else
		if next(self.targets) then
			return true
		end
		if self.unit:getSim():getCurrentPlayer() ~= self.unit:getPlayerOwner() and not self.currentInterest and next(self.interests) then
			return true
		end
		if self.knownInterests < #self.interests then
			return true
		end
		if #self.interests == 1 and self.interests[1] ~= self.currentInterest then
			return true
		end
	end
	return false
end

function Senses:checkDisabled()
	if self.unit:isKO() or self.unit:isDead() then
		return true
	end
	return false
end

function Senses:addTarget(target)
	local x,y = target:getLocation()
	local targetInfo = {unit=target, x=x, y=y}

	if self:hasLostTarget(target) then
		targetInfo.lost = true
	end

	--remove any interests related to this target
	for i = #self.interests, 1, -1 do
		local interest = self.interests[i]
		if interest.sourceUnit == target then
			table.remove(self.interests, i)
		end
	end

	self.targets[target:getID()] = targetInfo
end

function Senses:removeTarget(target)
	if target:isValid() then
        if self.targets[ target:getID() ] then
		    self.targets[target:getID()] = nil
        end
	else
		for k,v in pairs(self.targets) do
			if v.unit == target then
				self.targets[k] = nil
			end
		end
	end
end

function Senses:hasTarget(target)
	return self.targets[target:getID()] ~= nil
end

function Senses:hasLostTarget(target)
	if self.targets[target:getID()] and self.targets[target:getID()].lost then
		return true
	end
	for k,v in ipairs(self.interests) do
		if v.reason == simdefs.REASON_LOSTTARGET and v.sourceUnit == target and not v.selected then
			return true
		end
	end
	return false
end

function Senses:pickBestTarget()
	local candidates = {}
	for unitID, target in pairs(self.targets) do
		if (simquery.isEnemyTarget(self.unit:getPlayerOwner(), target.unit) or simquery.isKnownTraitor(target.unit, self.unit) )
		 and not target.unit:isKO()
		 and not target.unit:isDead() then
			table.insert( candidates, target )
		else
			self.targets[unitID] = nil
		end
	end

	local weapon = simquery.getEquippedGun(self.unit)
	if weapon then 
		table.sort( candidates,
			function( lu, ru )
				local x0, y0 = self.unit:getLocation()
				local lp1 = simquery.calculateShotSuccess(self.unit:getSim(), self.unit, lu.unit, weapon)
				local rp1 = simquery.calculateShotSuccess(self.unit:getSim(), self.unit, ru.unit, weapon)
				if lp1.damage == rp1.damage then
					-- If damage is the same, prioritize on distance
					return mathutil.distSqr2d(x0, y0, lu.unit:getLocation() ) < mathutil.distSqr2d(x0, y0, ru.unit:getLocation() )
				else
					return lp1.damage < rp1.damage
				end
			end )
	else 
		table.sort( candidates,
			function( lu, ru )
				local x0, y0 = self.unit:getLocation()
				return mathutil.distSqr2d( x0, y0, lu.unit:getLocation() ) < mathutil.distSqr2d( x0, y0, ru.unit:getLocation() )
			end )
	end 

	if #candidates > 0 then
		self.currentTarget = candidates[1]
	else
		self.currentTarget = nil
	end
end

function Senses:getCurrentTarget()
	return self.currentTarget and self.currentTarget.unit or nil
end

function Senses:getCurrentInterest()
	return self.currentInterest
end

function Senses:getRememberedInterest()
	for k, interest in ipairs(self.interests) do
		if interest.remember then
			return interest
		end
	end 
end

function Senses:isSameInterest(interest, other)
	local sim = self.unit:getSim()
	return interest.sense == other.sense
	 and interest.reason == other.reason
	 and interest.investigated == other.investigated
	 and interest.sourceUnit == other.sourceUnit
	 and ( (interest.x == other.x and interest.y == other.y)
	 	or (simquery.canPathBetween(sim, self.unit, sim:getCell(interest.x,interest.y), sim:getCell(other.x, other.y) ) )
	 	or (interest.reason == simdefs.REASON_SENSEDTARGET and interest.selected == other.selected) --if we're sensing the same target in the same turn, it doesn't have to have pathing (because cover could break that)
	 	or (interest.reason == simdefs.REASON_SMOKE) )	--any smoke should be considered the same interest	
end

function Senses:addInterest(x, y, sense, reason, sourceUnit)
    assert( sense and reason ) -- By the gods, there must be sense and reason! (hehehe)

	local interest = nil

	--[[
	print("================================================================")
	print("===---------            ADDING INTEREST            --------=====")
	print("FOR:",self.unit:getName())
	print("SENSE",sense)
	print("RESON",reason)
	print("sourceUnit",sourceUnit)
	]]
	if not self.unit:getTraits().noInterestDistraction or ( (sense == simdefs.SENSE_RADIO and reason == simdefs.REASON_HUNTING))then

		interest = {x=x, y=y, sense=sense, reason=reason, sourceUnit=sourceUnit}
		for i = #self.interests, 1, -1 do
			local existing = self.interests[i]
			if self:isSameInterest(interest, existing) then
				if existing.x ~= interest.x or existing.y ~= interest.y then
					if reason == simdefs.REASON_SMOKE and sense == simdefs.SENSE_SIGHT then
						--only closer smoke clouds should be preferred
						local x0, y0 = self.unit:getLocation()
						if mathutil.distSqr2d(x0, y0, interest.x, interest.y) < mathutil.distSqr2d(x0, y0, existing.x, existing.y) then
							existing.x = interest.x
							existing.y = interest.y
						end
					else
						existing.x = interest.x
						existing.y = interest.y
					end
					interest = table.remove(self.interests, i)	--remove and return the existing interest so it gets noticed as a newer event
				else
					return existing
				end
			end
		end

		if interest.sourceUnit and interest.sourceUnit:isValid() and self:hasTarget(interest.sourceUnit) then
			--we already know about this agent, don't notice the interest
			interest.noticed = true
		end

		if interest.sourceUnit == self.unit and interest.sense == simdefs.SENSE_RADIO then
			--it's a hunt interest, don't react
			interest.noticed = true
		end

		if interest.reason == simdefs.REASON_FOUNDCORPSE or
		 interest.reason == simdefs.REASON_FOUNDOBJECT or
		 interest.reason == simdefs.REASON_HUNTING or
		 interest.reason == simdefs.REASON_WITNESS or
		 interest.reason == simdefs.REASON_SMOKE or
		 interest.reason == simdefs.REASON_SHARED or
		 interest.reason == simdefs.REASON_KO or
		 interest.reason == simdefs.REASON_REINFORCEMENTS then
			--this is an interest that alerts guards
			interest.alerts = true
		end


		if interest.sense == simdefs.SENSE_SIGHT
		 or interest.reason == simdefs.REASON_FOUNDCORPSE
		 or interest.reason == simdefs.REASON_FOUNDDRONE
		 or interest.reason == simdefs.REASON_PATROLCHANGED
		 or interest.reason == simdefs.REASON_SCANNED then
			--don't throw grenades at these interests
			interest.grenadeHit = true
		end

		if interest.sense == simdefs.SENSE_HEARING
		 or (interest.sourceUnit and simquery.isEnemyAgent(self.unit:getPlayerOwner(), interest.sourceUnit) )
		 or interest.reason == simdefs.REASON_CAMERA
		 or (interest.alerts and interest.reason ~= simdefs.REASON_HUNTING) then
			interest.alwaysDraw = true
		end

		table.insert(self.interests, interest)
	end
	return interest
end

function Senses:removeInterest(interest)
	for i = #self.interests, 1, -1 do
		local existing = self.interests[i]
		if self:isSameInterest(interest, existing) then
			table.remove(self.interests, i)
		end
	end
end

function Senses:pickBestInterest()
	local candidates = {}
	for i,interest in ipairs(self.interests) do
		local candidate = {index=i}
		for k,v in pairs(interest) do
			candidate[k] = v
		end
		table.insert(candidates, candidate)
	end
	if #candidates > 1 then
		simlog(simdefs.LOG_SENSE, "Sorting interests for [%s]", tostring(self.unit:getID() ) )
	end
	table.sort(candidates, function(a, b)
		local result, preference
		if (result == nil) and self.unit:getTraits().lookingAround then
			--we're looking around, new interests need to take priority, otherwise hang onto our current interest
			if a.sensed ~= b.sensed then
				preference = "preferring unsensed"
				if a.sensed then
					result = false
				elseif b.sensed then
					result = true
				end
			elseif self.unit:getBrain() and self.unit:getBrain():getInterest() then
				preference = "preferring current interest"
				if self.interests[a.index] == self.currentInterest then
					result = true
				elseif self.interests[b.index] == self.currentInterest then
					result = false
				end
			end
		end
		if (result == nil) and a.alerts ~= b.alerts and not self.unit:isAlerted() then
			preference = "preferring alerting interest"
			if a.alerts then
				result = true
			elseif b.alerts then
				result = false
			end
		end
		if (result == nil) and a.scanned ~= b.scanned then
			preference = "preferring unscanned interest"
			if a.scanned then
				result = false
			elseif b.scanned then
				result = true
			end
		end
		if (result == nil) and a.investigated ~= b.investigated then
			preference = "preferring uninvestigated interest"
			if a.investigated then
				result = false
			elseif b.investigated then
				result = true
			end
		end
		if (result == nil) and a.sourceUnit and b.sourceUnit then
			if a.sourceUnit:isPC() and b.sourceUnit:isNPC() then
				if b.sourceUnit:isDown() and a.selected then
					preference = "preferring downed NPC"
					result = false
				end
			elseif a.sourceUnit:isNPC() and b.sourceUnit:isPC() then
				if b.selected and a.sourceUnit:isDown() then
					preference = "preferring downed NPC"
					result = true
				end
			end
		end

		if (result == nil) and SensePriorities[a.sense] ~= SensePriorities[b.sense] then
			preference = "preferring prioritised sense"
			result = SensePriorities[a.sense] < SensePriorities[b.sense]
		end

		if (result == nil) then
			preference = "preferring latest interest"
			result = a.index > b.index
		end

		if result then
			a.preference = preference
		else
			b.preference = preference
		end
		assert(result ~= nil)
		return result
	end)
	if #candidates > 0 then
		local preferredInterest = self.interests[candidates[1].index]
		if self.currentInterest ~= preferredInterest then
			if #candidates > 1 then
				simlog(simdefs.LOG_SENSE, "Sorted interests for [%s]: %s", tostring(self.unit:getID() ), tostring(candidates[1].preference) )
			end
			self.currentInterest = preferredInterest
		end
	else
		self.currentInterest = nil
	end

	for i,interest in ipairs(self.interests) do
		interest.sensed = true
	end
end

function Senses:markInterestsInvestigated(x, y)
	for i,interest in ipairs(self.interests) do
		if x == interest.x and y == interest.y then
			interest.investigated = true
		end
	end
end

function Senses:clearIgnoredInterests()
	local rememberedInterest
	for i=#self.interests, 1, -1 do
		local interest = self.interests[i]
		if self.currentTarget or interest.sensed then
			if not self.currentTarget and interest == self.currentInterest then
				interest.selected = true
			elseif interest.remember and not interest.investigated and not rememberedInterest then
				rememberedInterest = interest
			else
				table.remove(self.interests, i)
			end
		end
	end
end

function Senses:clearLostTargets()
	for k,target in pairs(self.targets) do
		target.lost = nil
	end
end

function Senses:clearTargets()
	for k,target in pairs(self.targets) do
		self:removeTarget(target.unit)
	end
	self.targets = {}
end

function Senses:processInterestShared(sim, evData)
	if evData.range and mathutil.dist2d(evData.x, evData.y, self.unit:getLocation() ) > evData.range then
		return
	end

	if evData.interest.sourceUnit == self.unit then
		return
	end

	if evData.target then
		if self:hasTarget(evData.target) or self.currentTarget then
			return
		end

		if simquery.couldUnitSee(sim, self.unit, evData.target) then
			local x0, y0 = self.unit:getLocation()
			local raycastX, raycastY = sim:getLOS():raycast( x0, y0, evData.interest.x, evData.interest.y)
			if raycastX == evData.interest.x and raycastY == evData.interest.y then
				self:addTarget(evData.target)
				return
			end
		end
	end
	self:addInterest(evData.interest.x, evData.interest.y, simdefs.SENSE_RADIO, evData.interest.reason or simdefs.REASON_SHARED, evData.interest.sourceUnit)
end

function Senses:processSoundTrigger(sim, evData)
	if evData.sourceUnit and evData.sourceUnit:getPlayerOwner() == self.unit:getPlayerOwner() then
		return
	end

	if not self.unit:getTraits().hasHearing then 
		return
	end

	if evData.sourceUnit and sim:canUnitSeeUnit(self.unit, evData.sourceUnit) then
		return
	end

	if sim:canUnitSee(self.unit, evData.x, evData.y) and evData.ignoreSight == nil then
		if self.unit:getTraits().seesHidden or not simquery.checkCover(sim, self.unit, evData.x, evData.y) then
			return
		end
	end

	if mathutil.dist2d(evData.x, evData.y, self.unit:getLocation() ) > evData.range then
		return
	end

	self:addInterest(evData.x, evData.y, simdefs.SENSE_HEARING, simdefs.REASON_NOISE, evData.sourceUnit)
end

function Senses:processDoorTrigger(sim, evData)
	if evData.unit == self.unit then
		self:checkPeripheralVision()
		return
	end

	if not simquery.isEnemyTarget(self.unit:getPlayerOwner(), evData.unit) then
		return
	end

	local canSeeCell, canSenseCell = sim:canUnitSee(self.unit, evData.cell.x, evData.cell.y)
	local canSeeToCell, canSenseToCell = sim:canUnitSee(self.unit, evData.tocell.x, evData.tocell.y)
	if not canSeeCell and not canSenseCell and not canSeeToCell and not canSenseToCell then
		return
	end

	local sense = simdefs.SENSE_PERIPHERAL
	if canSeeCell or canSeeToCell then
		sense = simdefs.SENSE_SIGHT
	end

	self:addInterest(evData.cell.x, evData.cell.y, sense, simdefs.REASON_DOOR, evData.unit)
end

function Senses:processAppearedTrigger(sim, evData)
	local seerUnit = sim:getUnit(evData.seerID)
	if seerUnit ~= self.unit then
		return 	--the seer isn't us
	end

	if self.unit:isKO() or self.unit:isDead() then
		return
	end

	local x,y = evData.unit:getLocation()
	local cell = sim:getCell(x, y)

    if evData.unit:getTraits().smokeEdge then
		self:addInterest(x, y, simdefs.SENSE_SIGHT, simdefs.REASON_SMOKE)
    elseif evData.unit:getTraits().laptop and evData.unit:getTraits().deployed then
		self:addInterest(x, y, simdefs.SENSE_SIGHT, simdefs.REASON_FOUNDOBJECT)
	elseif evData.unit:isDead() or evData.unit:getTraits().interestSource or evData.unit:isKO() then
		local originalUnit = sim:getUnit(evData.unit:getTraits().unitID) or evData.unit
		if self:hasTarget(originalUnit) then
			self:removeTarget(originalUnit)
			evData.unit:setInvestigated(self.unit)
			self:addInterest(x, y, simdefs.SENSE_SIGHT, simdefs.REASON_FOUNDCORPSE, evData.unit)
		elseif not evData.unit:hasBeenInvestigated(self.unit) then
			self:addInterest(x, y, simdefs.SENSE_SIGHT, evData.unit:getTraits().isDrone and simdefs.REASON_FOUNDDRONE or simdefs.REASON_FOUNDCORPSE, evData.unit)
		end
	elseif self:hasTarget(evData.unit) then
		self.targets[evData.unit:getID()].missing = nil
	elseif simquery.isEnemyTarget(self.unit:getPlayerOwner(), evData.unit) or simquery.isKnownTraitor(evData.unit, self.unit) then
		if not simquery.isAgent(evData.unit) and self.unit:getTraits().camera_drone then
			--camera drone saw a turret
			self:addInterest(x, y, simdefs.SENSE_SIGHT, simdefs.REASON_NOTICED, evData.unit)
		else 
			self:addTarget(evData.unit)
		end
	end
end

function Senses:processDisappearedTrigger(sim, evData)
	local seerUnit = sim:getUnit(evData.seerID)
	if seerUnit ~= self.unit then
		return 	--the seer isn't us
	end

	if self:hasTarget(evData.unit) and not self.unit:getTraits().lookingAround then
		self.targets[evData.unit:getID()].missing = true
	end
end

function Senses:processAttackedTrigger(sim, evData)
	local x0, y0 = evData.sourceUnit:getLocation()
	local x1, y1 = evData.targetUnit:getLocation()

	if not evData.noTargetAlert then
		if evData.targetUnit == self.unit then --it's us that's being hit
			self:addTarget(evData.sourceUnit)
		elseif evData.sourceUnit:getTraits().takenDrone and sim:canUnitSeeUnit(self.unit, evData.sourceUnit) then
			if evData.sourceUnit:getTraits().lastAttack then
				evData.sourceUnit:getTraits().lastAttack.witnesses[self.unit:getID()] = self.unit
			end
			self:addTarget(evData.sourceUnit)
		elseif sim:canUnitSeeUnit(self.unit, evData.targetUnit) then
			if simquery.isAgent(evData.targetUnit)
			 and (not evData.targetUnit:isValid() or evData.targetUnit:isDead() or evData.targetUnit:isKO() ) then
				self:addInterest(x1, y1, simdefs.SENSE_SIGHT, simdefs.REASON_FOUNDCORPSE, evData.targetUnit)
				self:removeTarget(evData.targetUnit)
			else
				self:addInterest(x1, y1, simdefs.SENSE_SIGHT, simdefs.REASON_WITNESS, evData.targetUnit)
			end
		elseif sim:canUnitSee(self.unit, evData.x, evData.y) then
			self:addInterest(evData.x, evData.y, simdefs.SENSE_SIGHT, simdefs.REASON_WITNESS, evData.targetUnit)
		end
	end
end

function Senses:processInterestRemoved(sim, evData)
	self:removeInterest(evData.interest)
end

function Senses:processKOTrigger(sim, evData)
	if not evData.unit:getPlayerOwner() then
		return
	end

	local x, y = evData.unit:getLocation()
	if evData.unit == self.unit then
		if not evData.ticks then	--we woke up
			local lastHit = evData.unit:getTraits().lastHit
			if lastHit then
				self:addInterest(lastHit.x, lastHit.y, simdefs.SENSE_HIT, simdefs.REASON_KO, self.unit)
				evData.unit:getTraits().lastHit = nil
			else
				self:addInterest(x, y, simdefs.SENSE_HIT, simdefs.REASON_KO, self.unit)
			end
		end
	else
		if not evData.ticks then	--someone else has woken up
			local canSee, canSense = sim:canUnitSeeUnit(self.unit, evData.unit)
			if canSee and simquery.isEnemyAgent(self.unit:getPlayerOwner(), evData.unit) then
				self:addTarget(evData.unit)
			elseif canSense then
				self:addInterest(x, y, simdefs.SENSE_SIGHT, simdefs.REASON_NOTICED, evData.unit)
			end
		else	--someone else has been knocked out
			if self:hasTarget(evData.unit) then
				self:removeTarget(evData.unit)
				self:addInterest(x, y, simdefs.SENSE_SIGHT, simdefs.REASON_FOUNDCORPSE, evData.unit)
			elseif evData.unit:getPlayerOwner() == self.unit:getPlayerOwner() then
				local canSee, canSense = sim:canUnitSeeUnit(self.unit, evData.unit)
				if canSee or canSense then
					local sense = canSee and simdefs.SENSE_SIGHT or simdefs.SENSE_PERIPHERAL
					local reason = evData.unit:getTraits().isDrone and simdefs.REASON_FOUNDDRONE or simdefs.REASON_WITNESS
					self:addInterest(x, y, sense, reason, evData.unit)
				end
			end
		end
	end
end

function Senses:processDeployedTrigger(sim, evData)
	local canSee, canSense = sim:canUnitSeeUnit( self.unit, evData.unit )
	if (canSee or canSense) and evData.unit:getTraits().holoProjector then
		local x1,y1 = evData.unit:getLocation() 
		self:addInterest(x1, y1, canSee and simdefs.SENSE_SIGHT or simdefs.SENSE_PERIPHERAL, simdefs.REASON_FOUNDOBJECT, evData.unit)
	end
end

function Senses:checkPeripheralVision()
	local losCoords, cells = {}, {}
	local sim = self.unit:getSim()
	sim:getLOS():getPeripheralVizCells( self.unit:getID(), losCoords )
	for i = 1, #losCoords, 2 do
		local x, y = losCoords[i], losCoords[i+1]
		table.insert( cells, sim:getCell( x, y ))
	end
	for i, cell in ipairs(cells) do
		for ii, unit in ipairs(cell.units) do
			local canSee, canSense = sim:canUnitSeeUnit(self.unit, unit)
			if not canSee and canSense then
				if simquery.isEnemyAgent(self.unit:getPlayerOwner(), unit) then
					if unit:isKO() or unit:isDead() then
						if not unit:hasBeenInvestigated() then
							self:addInterest(cell.x, cell.y, simdefs.SENSE_PERIPHERAL, simdefs.REASON_FOUNDCORPSE, unit)
						end
					else
						self:addInterest(cell.x, cell.y, simdefs.SENSE_PERIPHERAL, simdefs.REASON_SENSEDTARGET, unit)
					end
				end
			end
		end
	end
end

function Senses:processWarpTrigger(sim, evData)
    --TODO: special case for anything being dropped/deployed in peripheral but NOT eyeballs
    local to_cell = evData.to_cell or evData.from_cell
    if not evData.unit:isValid() then
        return -- Previous trigger handlers can very well kill this warped unit :(
    end
	if evData.unit == self.unit then
		self:checkPeripheralVision()
    elseif self:hasTarget(evData.unit) and evData.unit:getTraits().movePath then
    	local canSee, canSense = sim:canUnitSee(self.unit, evData.from_cell.x, evData.from_cell.y)
    	if canSee or (canSense and self:getCurrentTarget() == evData.unit) then
	        -- Attempt to reface if the target moved
	   		self.unit:turnToFace( to_cell.x , to_cell.y, STRINGS.UI.TRACKED ) --this could despawn the unit
	   		if self.unit and self.unit:getTraits().vip then
	   			self.unit:getPather():invalidatePath(self.unit)
	   		end
	   	end
        -- Did they in fact vanish entirely?
        if self.unit and not sim:canUnitSeeUnit( self.unit, evData.unit ) then
			self:removeTarget( evData.unit )
			self:addInterest( to_cell.x, to_cell.y, simdefs.SENSE_SIGHT, simdefs.REASON_LOSTTARGET, evData.unit )
	    	if self:getCurrentTarget() == evData.unit then
	            self.currentTarget = nil
	        end
        end
	elseif simquery.isEnemyAgent(self.unit:getPlayerOwner(), evData.unit) then
        -- Enemy agent warped.  This is to check whether or not we should react to peripheral vision.
		local canSee, canSense = sim:canUnitSeeUnit(self.unit, evData.unit)
        local targetX, targetY

        if not canSee and canSense then
            -- Unit warped INTO peripheral vision.
            targetX, targetY = to_cell.x, to_cell.y
        
        elseif not canSee and not canSense and evData.from_cell then
            -- Did unit warp OUT of peripheral vision? (NOTE: warping to nil still counts as leaving peripheral)
            -- NOTE: we really want to query here whether evData.unit *was* visible in peripheral (at evData.from_cell),
            -- based on invisibility, cover, etc. but there exists no such query, since evData.unit has already moved
            -- to a new cell by this time.  The closest we can do is call simquery.couldUnitSee, but it will base cover
            -- visibility on evData.unit's current cell -- leaving this as a small quirk, since the complete fix is quite complicated.
		    if simquery.couldUnitSee(sim, self.unit, evData.unit, false, evData.from_cell ) then
    			canSee, canSense = sim:canUnitSee(self.unit, evData.from_cell.x, evData.from_cell.y)
                if not canSee and canSense then
                    targetX, targetY = evData.from_cell.x, evData.from_cell.y
                end
            end
        end

        if targetX and targetY then            
            -- Unit either IS, or WAS in peripheral vision.  Either is noticeable.
			if self:hasLostTarget(evData.unit) and not simquery.checkCover(sim, self.unit, evData.from_cell.x, evData.from_cell.y) then
           		self.unit:turnToFace( targetX, targetY , STRINGS.UI.TRACKED )
			else
				if evData.unit:isKO() or evData.unit:isDead() then
					if not evData.unit:hasBeenInvestigated() then
						self:addInterest( targetX, targetY, simdefs.SENSE_PERIPHERAL, simdefs.REASON_FOUNDCORPSE, evData.unit)
					end
				else
					self:addInterest( targetX, targetY, simdefs.SENSE_PERIPHERAL, simdefs.REASON_SENSEDTARGET, evData.unit)
				end
			end
        end
	end
end

return Senses


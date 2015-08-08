local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local astar = include( "modules/astar" )
local speechdefs = include( "sim/speechdefs" )
local Situation = include( "sim/btree/situation" )

local HuntSituation = class(Situation, function(self, unit, startingCell)
	self.ClassType = simdefs.SITUATION_HUNT
	Situation.init(self)
	self.huntTargets = {}	--rooms currently being searched
	self.closedRooms = {}	--rooms that have already been searched
	self.openRooms = {} --rooms that need searching
	self.startingRoom = nil
	assert( startingCell )
	self.autoRoomIndex = -1 --auto-indices are all negative
	if unit then
		local sim = unit:getSim()
		local unitCell = sim:getCell(unit:getLocation() )
		if unitCell and startingCell then
			local unitRoom
			if unitCell.procgenRoom then
				unitRoom = unitCell.procgenRoom
			else
				unitRoom = self:createRoomFromCell(sim, unitCell)
			end

			if startingCell.procgenRoom then
				self.startingRoom = startingCell.procgenRoom
			else
				self.startingRoom = self:createRoomFromCell(sim, startingCell)
			end
			if self.startingRoom.roomIndex ~= unitRoom.roomIndex then
				self:openRoom(self.startingRoom)
				self:openRoom(unitRoom)
				self:closeRoom(unitRoom)
			else
				self:openRoom(unitRoom)
				self:openAdjacentRooms(unitRoom)
			end
		end
	end
end)

local function isValidExit(cell, dir)
	return cell.exits[dir] and not cell.exits[dir].closed and not cell.exits[dir].door
end

local function inSameRoom(sim, player, prevCell, testCell)
	local simquery = sim:getQuery()
	local dx, dy = testCell.x - prevCell.x, testCell.y - prevCell.y
	if dx~=0 and dy~=0 then --diagonal, check two directions
		local cell3 = sim:getCell(prevCell.x, testCell.y)
		local cell4 = sim:getCell(testCell.x, prevCell.y)
		if not cell3 or not cell4 then
			return false
		end

		local dir1, dir2 = simquery.getDirectionFromDelta(0, dy), simquery.getDirectionFromDelta(dx, 0)
		local dir3, dir4 = simquery.getDirectionFromDelta(dx, 0), simquery.getDirectionFromDelta(0, dy)

		if isValidExit(prevCell, dir1) and isValidExit(cell3, dir2)
		 and isValidExit(prevCell, dir3) and isValidExit(cell4, dir4) then
			return true
	 	end
	else
		local dir = simquery.getDirectionFromDelta(dx, dy)
		if isValidExit(prevCell, dir) then
			return true
		end
	end
	return false
end

function HuntSituation:createRoomFromCell(sim, startCell)
	local room = {roomIndex = self.autoRoomIndex, rects = {x0=startCell.x, y0=startCell.y, x1=startCell.x, y1=startCell.y}}
    room.xmin, room.xmax = startCell.x, startCell.x
    room.ymin, room.ymax = startCell.y, startCell.y

	self.autoRoomIndex = self.autoRoomIndex - 1


	local simquery = sim:getQuery()
	local cells = simquery.floodFill(sim, nil, startCell, 20, nil, inSameRoom)

	for i,testCell in ipairs(cells) do
        table.insert( room.rects, { x0 = testCell.x, x1 = testCell.x, y0 = testCell.y, y1 = testCell.y } )
        room.xmin, room.xmax = math.min( room.xmin, testCell.x ), math.max( room.xmax, testCell.x )
        room.ymin, room.ymax = math.min( room.ymin, testCell.y ), math.max( room.ymax, testCell.y )
	end
	
    --simlog("Hunt created room %s with %d rects/%d cells", room.roomIndex, #room.rects, #cells )
	return room
end

function HuntSituation:getHuntTarget(unit)
	return self.huntTargets[unit:getID()]
end

function HuntSituation:openAdjacentRooms(room)
	if room.exits then
		for i,v in ipairs(room.exits) do
			if not self.closedRooms[v.room.roomIndex] then
				if not v.barrier then	--don't try to search rooms that we can't easily get to
					self:openRoom(v.room)
				end
			end
		end
	end
end

function HuntSituation:roomHasBeenSearched(room)
	return self.closedRooms[room.roomIndex] ~= nil
end

function HuntSituation:openRoom(room)
	assert( room )
	if self.closedRooms[room.roomIndex] then
		return	--don't re-open closed rooms
	end
	if not self.openRooms[room.roomIndex] then
		log:write(simdefs.LOG_SIT, "[Hunt %s] Opening Room %s", tostring(self.startingRoom.roomIndex), tostring(room.roomIndex))
		self.openRooms[room.roomIndex] = room
	end
end

function HuntSituation:closeRoom(room)
	if self.openRooms[ room.roomIndex ] then
		log:write(simdefs.LOG_SIT, "[Hunt %s] Closing Room %s", tostring(self.startingRoom.roomIndex), tostring(room.roomIndex))
		self.openRooms[room.roomIndex] = nil
		self.closedRooms[room.roomIndex] = room
	else
		-- If room isn't open, then it should already be closed.
		assert( self.closedRooms[ room.roomIndex ] )
	end
end

local HuntTargetWeights = 
{
	existingHunter = 20,
	straightDist = 1,
	pathDist = 1,
}
function HuntSituation:findBestOpenRoom(unit)
	local bestRoom = nil
	local bestScore = 0
	local astar_handlers = include( "sim/astar_handlers" )
	local pather = astar.AStar:new(astar_handlers.aihandler:new(unit) )
	-- log:write(simdefs.LOG_SIT, "Finding Best Room for [%s]", tostring(unit:getID() ) )
	for k,v in pairs(self.openRooms) do
		local straightDist = mathutil.dist2d(0.5 * (v.xmin + v.xmax), 0.5 * (v.ymin + v.ymax), unit:getLocation() )
		local existingHunters = 0
		for kk,vv in pairs(self.huntTargets) do
			if vv.room == v then
				existingHunters = existingHunters + 1
			end
		end

		local score = HuntTargetWeights.straightDist*straightDist
					+ HuntTargetWeights.existingHunter*existingHunters
					-- + HuntTargetWeights.pathDist*pathDist
		-- log:write(simdefs.LOG_SIT, "  Room %s: Dist=%d(%d) Existing=%d(%d) Total=%d", tostring(v.roomIndex),
		-- 	HuntTargetWeights.straightDist*straightDist, straightDist,
		-- 	-- HuntTargetWeights.pathDist*pathDist, pathDist,
		-- 	HuntTargetWeights.existingHunter*existingHunters, existingHunters,
		-- 	score)
		if not bestRoom or score < bestScore then
			bestRoom = v
			bestScore = score
		end
	end
	-- log:write(simdefs.LOG_SIT, "Best Room for [%d] is Room:%s", tostring(unit:getID() ), tostring(bestRoom and bestRoom.roomIndex) )
	return bestRoom
end

function HuntSituation:updateHuntTarget(unit, huntTarget)
	if huntTarget and unit:isValid() then
		local interest = unit:getBrain():getSenses():addInterest(huntTarget.x, huntTarget.y,
			huntTarget.sense, huntTarget.reason, huntTarget.sourceUnit)
		if interest then
			if interest.room and not self.openRooms[interest.room.roomIndex] and not self.closedRooms[interest.room.roomIndex] then
				--fix the room for the interest so it's correct
				local cell = unit:getSim():getCell(interest.x, interest.y)
				interest.room = cell and cell.procgenRoom
			end
			for k, v in pairs(huntTarget) do
				interest[k] = interest[k] or v
			end
			self.huntTargets[unit:getID()] = interest
		end
	else
		self.huntTargets[unit:getID()] = nil
	end
end

function HuntSituation:markHuntTargetSearched(unit)
	local huntTarget = self.huntTargets[unit:getID()]
	if huntTarget then
		huntTarget.investigated = true
		unit:getBrain():getSenses():markInterestsInvestigated(huntTarget.x, huntTarget.y)
		self:closeRoom(huntTarget.room)
		if huntTarget.sourceUnit then
			huntTarget.sourceUnit:setInvestigated(unit)
		end
	end
end

function HuntSituation:overrideHuntTarget(unit, huntTarget)
	assert(huntTarget and huntTarget.x and huntTarget.y)
	local cell = unit:getSim():getCell(huntTarget.x, huntTarget.y)
	if cell then
		if cell.procgenRoom then
			huntTarget.room = cell.procgenRoom
		else
			huntTarget.room = self:createRoomFromCell(unit:getSim(), cell)
		end
		if not huntTarget.reason and not huntTarget.sense then
			huntTarget.reason = simdefs.REASON_HUNTING
			huntTarget.sense = simdefs.SENSE_RADIO
			huntTarget.sourceUnit = unit
		end
		self:openRoom(huntTarget.room)
		self:updateHuntTarget(unit, huntTarget) --could change situation
	end
end

function HuntSituation:requestNewHuntTarget(unit) 
	if not unit:isValid() then
		return
	end
	
	local expandClosedRooms = #self.openRooms < 2
	if expandClosedRooms then
		log:write(simdefs.LOG_SIT, "[Hunt %s] Expanding Hunt", tostring(self.startingRoom.roomIndex) )
		for k,v in pairs(self.closedRooms) do
			self:openAdjacentRooms(v)
		end
	end

	if not next(self.openRooms) then
		log:write(simdefs.LOG_SIT, "[Hunt %s] Resetting from active hunt targets", tostring(self.startingRoom.roomIndex) )
		self.closedRooms = {}
		self.openRooms = {}
		for k,v in pairs(self.huntTargets) do
			self:openRoom(v.room)
		end
	end

	local nextRoom = self:findBestOpenRoom(unit)
	if nextRoom then
		local huntTarget = {reason=simdefs.REASON_HUNTING, sense=simdefs.SENSE_RADIO, sourceUnit=unit}
		local cell
		local attempt = 0
		--try to pick a cell that we can get to
		local function isValidHuntCell(sim, cell)
			return cell and not simquery.cellHasTag(sim, cell, "guard_spawn") and cell.impass == 0
		end

		repeat
            local rect = nextRoom.rects[ unit:getSim():nextRand(1, #nextRoom.rects) ]
			huntTarget.x=unit:getSim():nextRand(rect.x0, rect.x1)
			huntTarget.y=unit:getSim():nextRand(rect.y0, rect.y1)
			cell = unit:getSim():getCell(huntTarget.x, huntTarget.y)
			attempt = attempt + 1
		until isValidHuntCell(unit:getSim(), cell) or attempt > 5
		if isValidHuntCell(unit:getSim(), cell) then
			huntTarget.room = nextRoom
			self:updateHuntTarget(unit, huntTarget)
		else
			log:write(simdefs.LOG_SIT, "[Hunt %s] Couldn't find no-impass cell in [Room:%s] for [%s]", tostring(self.startingRoom.roomIndex), tostring(nextRoom.roomIndex), tostring(unit:isValid() and unit:getID() ) )
			self:updateHuntTarget(unit, nil)
		end
	else
		log:write(simdefs.LOG_SIT, "[Hunt %s] Couldn't find best room for [%s]", tostring(self.startingRoom.roomIndex), tostring(unit:isValid() and unit:getID() ) )
	end
end

function HuntSituation:addUnit(unit)
	Situation.addUnit(self, unit)

	unit:getTraits().thoughtVis = "hunting"
	unit:getTraits().walk = false
	unit:getTraits().noKO = (unit:getTraits().noKO or 0) + 1
end

function HuntSituation:removeUnit(unit)
	Situation.removeUnit(self, unit)

	self:updateHuntTarget(unit, nil)
end

return HuntSituation

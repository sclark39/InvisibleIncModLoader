local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )
local simfactory = include( "sim/simfactory" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local astar = include( "modules/astar" )
local speechdefs = include( "sim/speechdefs" )
local Situation = include( "sim/btree/situation" )

--------------------------------------------------------------------------------
-- Locals

local function canGuardSpawn( sim, unit, x, y )
	local cell = sim:getCell( x, y )
	if cell.tileIndex == nil or cell.tileIndex == cdefs.TILE_SOLID or cell.exitID or cell.cell ~= nil or cell.impass > 0 then
		return false
	end

	if simquery.cellHasTag(sim, cell, "noguard") then        
		return false
	end

    if not simquery.canPath( sim, unit, nil, cell ) then
		return false
	end

	return true
end

local function findGuardSpawn( sim, room, unit )
    local cells = {}
    for _, rect in ipairs(room.rects) do
        for x = rect.x0, rect.x1 do
            for y = rect.y0, rect.y1 do
                if canGuardSpawn( sim, unit, x, y ) then
                    table.insert( cells, x )
                    table.insert( cells, y )
                end
            end
        end
    end

    if #cells > 0 then
        local i = sim:nextRand( 1, #cells / 2 )
        return cells[2 * i - 1], cells[2 * i]
    end
end

local function calculateBestFacing( sim, cell, unit )
	-- Look for stationary patrollers and face them in a direction that allows maximal visibility.
	local maxFacing, maxCells = nil, 0
	for facing = 0, simdefs.DIR_MAX do
		local cells = sim:getLOS():calculateLOS( cell, simquery.getFacingRads( facing ), simquery.getLOSArc( unit ) / 2, unit:getTraits().LOSrange )
		local cellCount = util.tcount( cells )
		if cellCount > maxCells then
			maxCells = cellCount
			maxFacing = facing
		end
	end
    return maxFacing
end


local function markPatrolRoom( sim, room, unit )
    local roomData = sim._mutableRooms[ room.roomIndex ]
    if roomData.patrolUnits == nil then
        roomData.patrolUnits = {}
    end
    table.insert( roomData.patrolUnits, unit:getID() )
end

local function canPatrolRoom( sim, startRoom, room, unit )
    local beginnerPatrols = sim:getParams().difficultyOptions.beginnerPatrols
    if beginnerPatrols then
        -- Beginning patrols MUST start and end in the same 'zone'.
        return startRoom.zoneID == room.zoneID
    else
        if startRoom == room then
            -- Non-beginner patrols must NOT start and end in the same ROOM.
            return false
        end

        if room.tags.entry then
            local roomData = sim._mutableRooms[ room.roomIndex ]
            local currentCount = roomData.patrolUnits and #roomData.patrolUnits or 0
            if currentCount >= 1 then
                return false
            end
        end
    end
    return true
end

--------------------------------------------------------------------------------
-- Idle/patrolling.

local IdleSituation = class(Situation, function(self)
	self.ClassType = simdefs.SITUATION_IDLE
	Situation.init(self)
end)

IdleSituation.findGuardSpawn = findGuardSpawn

function IdleSituation:addUnit(unit)
	Situation.addUnit(self, unit)

	unit:getTraits().thoughtVis = nil
	unit:getTraits().walk = true
	unit:getTraits().noKO = unit:getTraits().noKO or 0
end

function IdleSituation:generatePatrolPath( unit, x0, y0 )
    assert( unit:getBrain():getSituation() == self )
    -- make a patrol!
    local sim = unit:getSim()
    if sim._rooms == nil then -- no patrols for pre-designed levels.
        return
    end
    if x0 == nil or y0 == nil then
        local room = sim._rooms[ sim:nextRand( 1, #sim._rooms ) ]
        x0, y0 = findGuardSpawn( sim, room, unit )
    end
    local cell = sim:getCell( x0, y0 )
    if cell then
        local startRoom = cell.procgenRoom
    	local path = {}
        table.insert( path, { x = x0, y = y0 } )
        markPatrolRoom( sim, startRoom, unit )
        local maxMP, maxRangeOnly = unit:getTraits().mpMax, true
        if sim:getParams().difficultyOptions.beginnerPatrols then
            maxMP = 4, false
        end
        local cells = simquery.floodFill( sim, unit, cell, maxMP, nil, simquery.canSoftPath, maxRangeOnly, sim )
        table.sort( cells, function( c1, c2 ) return mathutil.distSqr2d( x0, y0, c1.x, c1.y ) > mathutil.distSqr2d( x0, y0, c2.x, c2.y ) end )
        for i, cell in ipairs( cells ) do
            if canPatrolRoom( sim, startRoom, cell.procgenRoom, unit ) then
                table.insert( path, { x = cell.x, y = cell.y } )
                markPatrolRoom( sim, cell.procgenRoom, unit )
                break
            end
        end
        unit:getTraits().patrolPath = path
    else
        unit:getTraits().patrolPath = nil
    end
end

function IdleSituation:generateStationaryPath( unit, x0, y0)
    assert( unit:getBrain():getSituation() == self )
    local sim = unit:getSim()
    if sim._rooms == nil then -- no patrols for pre-designed levels.
        return
    end
    if x0 == nil or y0 == nil then
        x0, y0 = findGuardSpawn( sim, sim._rooms[ sim:nextRand( 1, #sim._rooms ) ], unit )
    end
    local cell = sim:getCell( x0, y0 )
    if cell then
        unit:getTraits().patrolPath = { { x = x0, y = y0, facing = calculateBestFacing( sim, cell, unit ) } }
    end
end


function IdleSituation:generateStationaryPathAtRoom( unit, room)
    assert( unit:getBrain():getSituation() == self )
    local sim = unit:getSim()
   
    local x0, y0 = findGuardSpawn( sim, room, unit )
   
    local cell = sim:getCell( x0, y0 )
    if cell then
        unit:getTraits().patrolPath = { { x = x0, y = y0, facing = calculateBestFacing( sim, cell, unit ) } }
    end
end

function IdleSituation:removeUnit(unit)
	Situation.removeUnit( self, unit )
end

return IdleSituation
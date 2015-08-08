----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local rand = include( "modules/rand" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )

local function breadthFirstSearch( cxt, searchRoom, fn )
	local rooms = { searchRoom }
	searchRoom.depth = 0

	while #rooms > 0 do
		local room = table.remove( rooms )
		for i, exit in ipairs( room.exits ) do
			local cost = exit.barrier and 3 or 1
			if (exit.room.depth or math.huge) > room.depth + cost then
				exit.room.depth = room.depth + cost
				table.insert( rooms, 1, exit.room )
			end
		end
	end

    local rooms = util.tdupe( cxt.rooms )
    table.sort( rooms, function( r1, r2 ) return r1.depth < r2.depth end )
	for i = 1, #rooms do
		fn( rooms[i] )
		rooms[i].depth = nil
	end
end

------------------------------------------------
-- Finds pairwise distances between every room.

local function findPairwisePaths( cxt )
	local paths = {}
	for i = 1,#cxt.rooms do
		table.insert( paths, { [i] = 0 } )
	end

	for i = 1, #cxt.rooms do
		breadthFirstSearch( cxt, cxt.rooms[i],
			function( room )
				local k = util.indexOf( cxt.rooms, room )
				paths[i][k] = room.depth
				assert(paths[k][i] == nil or paths[k][i] == room.depth)
			end )
	end

	return paths
end


----------------------------------------------------------------------------------------------
-- Saves a .png of the maze structure illustrating the walls/origin/exit and loot weightings.

local function saveMazePNG( cxt, filename )
	local WALL_WIDTH, CELL_SIZE = 1, 5

	local image = MOAIImage.new ()
	local xmin, ymin, xmax, ymax = cxt:getBounds()
	local w, h = (xmax - xmin) * CELL_SIZE, (ymax - ymin) * CELL_SIZE
	log:write( "saveMapPNG( %s ) - %d x %d", filename, w, h )
	image:init( w, h )
	image:fillRect( 0, 0, w, h, 0, 0.05, 0.2, 1 )

	local rooms = cxt.rooms
	for i, room in ipairs( rooms ) do
		local x0, y0 = (room.x0 - 1) * CELL_SIZE + WALL_WIDTH, (room.y0 - 1) * CELL_SIZE + WALL_WIDTH
		local x1, y1 = room.x1 * CELL_SIZE - WALL_WIDTH, room.y1 * CELL_SIZE - WALL_WIDTH
		local t = 0.5
		-- The room's gooey centre.
		image:fillRect( x0, y0, x1, y1, t, t, t, 1 )
		if room.tags ~= nil and room.tags.entry then
			image:fillRect( x0, y1 - 4, x0 + 4, y1, 1, 0, 0, 1 )
		elseif room.tags ~= nil and room.tags.exit then
			image:fillRect( x0, y1 - 4, x0 + 4, y1, 0, 1, 0, 1 )
		end

		-- The exits
		for i, exit in ipairs( room.exits or {} ) do
			local x0, y0, x1, y1 = exit.x0 * CELL_SIZE, exit.y0 * CELL_SIZE, exit.x1 * CELL_SIZE, exit.y1 * CELL_SIZE
			if exit.dir == simdefs.DIR_E then
				x0, y0 = x0 - WALL_WIDTH, y0 - CELL_SIZE
			elseif exit.dir == simdefs.DIR_N then
				x0, y0 = x0 - CELL_SIZE, y0 - WALL_WIDTH
			elseif exit.dir == simdefs.DIR_W then
				x0, y0, x1 = x0 - CELL_SIZE, y0 - CELL_SIZE, x1 - CELL_SIZE + WALL_WIDTH
			elseif exit.dir == simdefs.DIR_S then
				x0, y0, y1 = x0 - CELL_SIZE, y0 - CELL_SIZE, y1 - CELL_SIZE + WALL_WIDTH
			end

			if exit.barrier then
				image:fillRect( x0, y0, x1, y1, 1, 0, 0, 1 )
			else
				image:fillRect( x0, y0, x1, y1, 0.6, 0.6, 0.6, 1 )
			end
		end
	end	

	image:fillRect( 0, 0, 1, 1, 0, 1, 0, 1 )
	image:writePNG( filename )
end


local function makeExit( cxt, room, wall, isBarrier )
	local toroom = wall.room
	-- This exit should not exist either in this room or toroom
	assert( array.findIf( room.exits, function( e ) return e.x0 == wall.x0 and e.y0 == wall.y0 and e.x1 == wall.x1 and e.y1 == wall.y1 and e.dir == wall.dir end ) == nil )

	local exit = { room = toroom, dir = wall.dir, x0 = wall.x0, y0 = wall.y0, x1 = wall.x1, y1 = wall.y1, barrier = isBarrier }

	-- Non-barrier exits might be doored exits, or open exits ie. with the entire interjacent (that's not a word) wall removed
	if not exit.barrier  then
		local P_OPENEXIT = 0.4
		if math.max( exit.x1 - exit.x0, exit.y1 - exit.y0 ) <= 1 then
			P_OPENEXIT = 0
		elseif room.tags.hall and toroom.tags.hall then
			P_OPENEXIT = 1
		elseif room.tags.contained or toroom.tags.contained then
			P_OPENEXIT = 0
		end

		exit.hasDoor = cxt.rnd:next() > P_OPENEXIT
	end

	table.insert( room.exits, exit )
	wall.exit = exit

	local rwall = array.findIf( toroom.walls, function( w ) return w.room == room and ((w.x0 == wall.x0 and w.x1 == wall.x1) or (w.y0 == wall.y0 and w.y1 == wall.y1)) end )
	assert( array.findIf( toroom.exits, function( e ) return e.x0 == rwall.x0 and e.y0 == rwall.y0 and e.x1 == rwall.x1 and e.y1 == rwall.y1 and e.dir == rwall.dir end ) == nil )
	local rexit = { room = room, dir = rwall.dir, x0 = rwall.x0, y0 = rwall.y0, x1 = rwall.x1, y1 = rwall.y1, hasDoor = exit.hasDoor, barrier = isBarrier }
	table.insert( toroom.exits, rexit )
	rwall.exit = rexit
end

-- Prunes walls for additional open-ness.
--
local function pruneWalls( cxt, factor )
	for i = 1, factor do
		-- Pick a random wall.
		local room = cxt.rnd:nextChoice( cxt.rooms )
		local wall = cxt.rnd:nextChoice( room.walls )

		-- If the wall has no exit already, prune it......
		if wall and not array.findIf( room.exits, function( exit ) return exit.room == wall.room end ) then
			makeExit( cxt, room, wall )
		end
	end
end


-- Create barrier exits for additional "closed open-ness" :)
--
local function makeBarrier( cxt, paths )
	local function isAdjacent( r1, r2 )
		for i, wall in ipairs(r1.walls) do
			if wall.room == r2 then
				return r1, wall
			end
		end
	end

	local function canBarrier( room, wall )
		if room == nil or wall == nil or wall.exit ~= nil then
			return false
		end
		if room.zoneID == wall.room.zoneID then
			return false
		end
        if cxt.m0:isAdjacent( room.zoneID, wall.room.zoneID ) then
            return false
        end
		return true
	end

	-- Find the maximum value for rooms where valid barrierse can be placed. (note that the paths matrix is symmetric)
	local maxDist, maxRoom, maxWall = 1, nil, nil
	for i = 1, #paths do
		for k = 1, i do
			if paths[i][k] and paths[i][k] > maxDist then
				local room, wall = isAdjacent( cxt.rooms[i], cxt.rooms[k] )
				if canBarrier( room, wall ) then
					maxDist = paths[i][k]
					maxRoom, maxWall = room, wall
				end
			end
		end
	end

	if maxRoom then
		log:write( simdefs.LOG_PROCGEN, "\tBARRIER - MAXIST: %d, <%d -> %d, %d -> %d>[%d]", maxDist, maxWall.x0, maxWall.x1, maxWall.y0, maxWall.y1, maxWall.dir )
		makeExit( cxt, maxRoom, maxWall, true )
        cxt.m0:setAdjacent( maxRoom.zoneID, maxWall.room.zoneID )
        return true
	end

    return false
end


local function findBestDoorCell( cxt, exit )
	local cx, cy = math.floor((exit.x0 + exit.x1) / 2), math.floor((exit.y0 + exit.y1) / 2)
    local cells = {}
    for y = exit.y0, exit.y1 do
        for x = exit.x0, exit.x1 do
            -- Lower score = better placement.
            local score = 100 * cxt:countAdjacentDoors( x, y, exit.dir )
            score = score + mathutil.distSqr2d( x, y, cx, cy )
            table.insert( cells, { x, y, score } )
        end
    end
    table.sort( cells, function( c1, c2 ) return c1[3] < c2[3] end )
    return cells[1][1], cells[1][2]
end

local function finalizeExits( cxt )
    -- Exits are decided, now actually burn the exit flags in one pass
    -- This is so that we can decide on proper door locations (ensuring they aren't next to eachother, etc.)
    local allExits = {}
    for i, room in ipairs(cxt.rooms) do
        util.tmerge( allExits, room.exits )        
    end
    -- Process exits in order of least to most choice (eg. the smallest exits first, where we KNOW where a door must be placed)
    table.sort( allExits,
        function( e1, e2 ) return mathutil.distSqr2d( e1.x0, e1.y0, e1.x1, e1.y1 ) < mathutil.distSqr2d( e2.x0, e2.y0, e2.x1, e2.y1 ) end )

    for i, exit in ipairs( allExits ) do
	    -- MAKE the exit.
	    local cx, cy = findBestDoorCell( cxt, exit )
        local dx, dy = simquery.getDeltaFromDirection( exit.dir )
        local rdir = simquery.getReverseDirection( exit.dir )

	    if exit.barrier then
		    cxt.LVL_PATTERN:burnDoor( cx, cy, exit.dir, "secdoor" )
    		cxt.LVL_PATTERN:burnDoor( cx + dx, cy + dy, rdir, "secdoor" )
	    elseif exit.hasDoor then
		    cxt.LVL_PATTERN:burnDoor( cx, cy, exit.dir )
    		cxt.LVL_PATTERN:burnDoor( cx + dx, cy + dy, rdir )
	    else
	        local rexit = array.findIf( exit.room.exits,
                function( e ) return e.dir == rdir and ((e.x0 == exit.x0 and e.x1 == exit.x1) or (e.y0 == exit.y0 and e.y1 == exit.y1)) end )
		    cxt.LVL_PATTERN:clearArea( exit.x0, exit.x1, exit.y0, exit.y1, "wall_"..exit.dir )
    		cxt.LVL_PATTERN:clearArea( rexit.x0, rexit.x1, rexit.y0, rexit.y1, "wall_"..rdir )
	    end
    end
end

-- Generates a maze using randomized Prim's algorithm.
local function generatePrims( cxt )
	local function addCell( room, walls )
		room.maze = true
		for i, wall in ipairs(room.walls) do
			if not wall.room.maze then
				if wall.exit == nil then
					table.insert( walls, { room, wall } )
				else
					addCell( wall.room, walls )
				end
			end
		end
	end

	-- Kick off the algorithm with a randomly selected room (zone).
	local walls = {}
	local room = cxt.rnd:nextChoice( cxt.rooms )
	addCell( room, walls )

	while #walls > 0 do
		local wallEntry = table.remove( walls, cxt.rnd:nextInt( 1, #walls ) )
		local room, wall = wallEntry[1], wallEntry[2]
		if not wall.room.maze then
			makeExit( cxt, room, wall )
			addCell( wall.room, walls )
		end
	end

    pruneWalls( cxt, 0 )
end

local function makeBarriers( cxt )
	-- Create barrier exits
	local NUM_BARRIERS = math.ceil( #cxt.rooms / 6 )
    cxt.NUM_BARRIERS = 0
    log:write( simdefs.LOG_PROCGEN, "BARRIERS: %d (for %d rooms)", NUM_BARRIERS, #cxt.rooms )

	for i = 1, NUM_BARRIERS do
		local pathCosts = findPairwisePaths( cxt )
		if makeBarrier( cxt, pathCosts ) then
            cxt.NUM_BARRIERS = cxt.NUM_BARRIERS + 1
        end
	end
end

-- Procedurally generates a spacial connectivity graph for the rooms.
--
local function finalize( cxt )

    finalizeExits( cxt )

	-- Could analyze maze structure to assign specific features.
	-- Used to do a BFS here, but moved it to later in procgen because we don't yet know where
	-- the origin and exit rooms are until after prefab matching.
end


return
{
	generatePrims = generatePrims,
	makeBarriers = makeBarriers,
	finalize = finalize,
	breadthFirstSearch = breadthFirstSearch,
	saveMazePNG = saveMazePNG,
}

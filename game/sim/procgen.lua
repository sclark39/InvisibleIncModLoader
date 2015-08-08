----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local mazegen = include( "sim/mazegen" )
local roomgen = include( "sim/roomgen" )
local prefabs = include( "sim/prefabs" )
local unitdefs = include( "sim/unitdefs" )
local WALL_TYPES = include( "sim/walltypes" )
local util = include( "modules/util" )
local array = include( "modules/array" )

------------------------------------------------------------------------
-- Local functions

local function analyzeFeatures( cxt )
	for _, room in ipairs( cxt.rooms ) do
		room.tags = room.tags or {}
	end

	-- Discover depths from the entrance room to all the other rooms.
	local originRoom = array.findIf( cxt.rooms, function( r ) return r.tags ~= nil and r.tags.entry end )

	mazegen.breadthFirstSearch( cxt, originRoom,
		function( room )
			room.lootWeight = (room.depth or 0) + 1
		end )
	local exitRoom = array.findIf( cxt.rooms, function( r ) return r.tags ~= nil and r.tags.exit end )
	if exitRoom then
		mazegen.breadthFirstSearch( cxt, exitRoom,
			function( room )
				room.lootWeight = room.lootWeight * ((room.depth or 0) + 1)
			end )
	end

	for i, room in ipairs( cxt.rooms ) do
		cxt.maxLootWeight = math.max( room.lootWeight, cxt.maxLootWeight or 0 )
	end
end

local function setWall( board, x, y, dir, wallIndex )
	local cell = board[y] and board[y][x]
	if cell then
		if cell.sides == nil then
			cell.sides = {}
		end
		cell.sides[ dir ] = WALL_TYPES[ wallIndex ]
	end
end

-- Assigns a default wall to the cell in the given direction.
--
local function generateWall( board, x0, y0, dir, wallIndex )
	local dx, dy = simquery.getDeltaFromDirection( dir )
	local rdir = simquery.getReverseDirection( dir )

	setWall( board, x0, y0, dir, wallIndex )
	setWall( board, x0 + dx, y0 + dy, rdir, wallIndex )
end

-- Converts a cell coordinate in prefab space into map space.
--
local function transformXY( x, y, facing, candidate )
	local x, y = simquery.rotateFacing( candidate.facing, x - 1, y - 1 )
	x, y = x + candidate.prefab.tx + candidate.tx, y + candidate.prefab.ty + candidate.ty
	if facing then
		facing = (facing + candidate.facing - 2) % simdefs.DIR_MAX
	end
	return x, y, facing
end

-- Loads and instantiates a prefab room into the level.
--
local function generatePrefabRoom( cxt, candidate )
	local prefabFilename = string.format( "%s", candidate.filename )
	local prefab = include( prefabFilename )

	for i, tile in ipairs(prefab.tiles) do
		local x, y = transformXY( tile.x, tile.y, nil, candidate )
		local cell = cxt.board[y][x]
		for k, v in pairs(tile) do
			cell[k] = v
		end
		cell.x, cell.y = x, y
		cell.deployID = cell.deployIndex -- same shitz
		if cell.procgenPrefab == nil then
			cell.procgenPrefab = {}
		end
		table.insert( cell.procgenPrefab, candidate.filename ) -- DEBUG PURPOSES
		cxt:generateCell( x, y, tile.zone, tile.variant, candidate )
	end

	for i, wall in ipairs(prefab.walls) do
		local x, y, dir = transformXY( wall.x, wall.y, wall.dir, candidate )
		if cxt.LVL_PATTERN:testFlag( x, y, "door_"..dir ) then
			if cxt.LVL_PATTERN:testFlag( x, y, "secdoor_"..dir ) then
				generateWall( cxt.board, x, y, dir, "security_door" )
			-- It's a door... use the desired door if it IS a door.
			elseif WALL_TYPES[ wall.wallIndex ].door then
				generateWall( cxt.board, x, y, dir, wall.wallIndex )
			else
				generateWall( cxt.board, x, y, dir, "office_door" )
			end
		elseif cxt.LVL_PATTERN:testFlag( x, y, "wall_"..dir ) then
			generateWall( cxt.board, x, y, dir, "default_wall" )
		end
	end

	for i, deco in ipairs(prefab.decos) do
		local x, y, facing = transformXY( deco.x, deco.y, deco.facing, candidate )
		table.insert( cxt.decos, util.extend( deco ){ x = x, y = y, facing = facing })
	end

    for key, unitList in pairs(prefab.units) do
		local n = cxt.rnd:next()
		if n < (unitList.spawnChance or 1) then
            local wt = util.weighted_list( unitList )
            local maxCount = unitList.maxCount
            while wt:getCount() > 0 and maxCount > 0 do
                local unit = wt:removeChoice( cxt.rnd:nextInt( 1, wt:getTotalWeight() ))
                assert( unit )

			    local unitCopy = util.tcopy( unit )
			    unitCopy.x, unitCopy.y = transformXY( unit.x, unit.y, nil, candidate )

			    -- Unfortunately, need to specially handle facing to rotate it according to the prefab rotation.
			    if unitCopy.unitData and unitCopy.unitData.facing then
				    unitCopy.unitData.facing = (unitCopy.unitData.facing + candidate.facing - 2) % simdefs.DIR_MAX
			    end
                -- .. Not to mention patrol paths
                if unitCopy.unitData.patrolPath then
                    for i, coord in ipairs( unitCopy.unitData.patrolPath ) do
                        coord[1], coord[2] = transformXY( coord[1], coord[2], nil, candidate )
                    end
                end

                unitCopy = cxt:generateUnit( unitCopy )
                if unitCopy then
			        table.insert( cxt.units, unitCopy )
                end
                maxCount = maxCount - 1
            end
		else
    		simlog( "SKIPPED spawn group %s (%.2f >= %.2f)", key, n, unitList.spawnChance or 1 )
		end
    end

	for i, sound in ipairs(prefab.sounds) do
		local x, y = transformXY( sound.x, sound.y, nil, candidate )
		table.insert( cxt.sounds, util.extend( sound ){ x = x, y = y } )
	end
end

local function generateStructure( cxt )
	assert( cxt.candidates )

	cxt:generateBoard()
	
	-- Instantiate the chosen prefabs.
	for i, candidate in ipairs( cxt.candidates ) do
		generatePrefabRoom( cxt, candidate )
	end
end

local function generatePass( cxt, params )
	config.PATTERN = cxt.LVL_PATTERN -- saved globally, for debugging

	-- Partition level into grid of 'rooms'
	cxt.rooms = cxt:generateRooms()

	cxt:generateConnectivity( cxt )

	analyzeFeatures( cxt )

	do
		local st = os.clock()
		cxt:generateBlueprint()
		log:write( "\tgenerateBlueprint(): %d ms", (os.clock() - st) * 1000)

		if cxt.SEARCH_PREFAB ~= nil then
			-- Just searching for a prefab, no need to do all the extra processing.
			log:write( "\tBAILING due to search..." )
			return nil
		end
	end

	generateStructure( cxt )

	if config.SAVE_MAP_PNGS then
		mazegen.saveMazePNG( cxt, string.format("lvl%u.png", cxt.params.seed) )
	end

	cxt:generateUnits()

	return cxt:finalize()
end

-- Procedurally generates a level with the given width, height, and seed.
--
local function generateLevel( params )
	local worldgen = include( "sim/worldgen" )
	local pass, MAX_PASS = 0, 10
	local bestMetric, bestPass = -1, -1
	local cxt

	log:write( "LEVELGEN: seed = %u, difficulty = %d, world = %s, ", params.seed, params.difficulty, params.world )

	while pass <= MAX_PASS and bestMetric < 1 do
		-- Create the context and do a levelgen pass.
		pass = pass + 1
		cxt = worldgen.createContext( params, pass )

		local passMetric = generatePass( cxt, params )
		if passMetric > bestMetric then
			bestMetric, bestPass = passMetric, pass
		end
		log:write( "\tPASS #%d == %.2f (best so far #%d == %.2f)", pass, passMetric, bestPass, bestMetric )
	end

	if pass ~= bestPass then
		cxt = worldgen.createContext( params, bestPass )
		generatePass( cxt, params )
	end

	return
	{
		board = cxt.board,
		units = cxt.units,
		decos = cxt.decos,
		sounds = cxt.sounds,
        rooms = cxt.rooms,
		ice_programs = cxt.ice_programs,
		patrolGuard = cxt._patrolGuard,
		walltop_color = cxt.walltop_color,
	}
end

return
{
	generateLevel = generateLevel,
}

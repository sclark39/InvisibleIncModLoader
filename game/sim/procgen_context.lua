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
local astar_handlers = include( "sim/astar_handlers" )
local unitdefs = include( "sim/unitdefs" )
local cdefs = include( "client_defs" )
local astar = include( "modules/astar" )
local util = include( "modules/util" )
local weighted_list = include( "modules/weighted_list" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local rand = include( "modules/rand" )
local serverdefs = include( "modules/serverdefs" )

------------------------------------------------------------------------
-- Local data

-- These are loot tables for the fillLoot() function.  Items are randomly
-- selected without replacement until a certain loot amount is reached.
-- Each item is only chosen if shouldChooseLoot() returns true for that
-- item, given the remaining value to be allocated.
local MAX_ITEMS = 2
local LOOT_TABLES =
{
	lab_safe =
	{
		{ unitdefs.tool_templates.item_icebreaker, 2 },
		{ unitdefs.tool_templates.item_portabledrive, 1 },
		{ unitdefs.tool_templates.item_paralyzer, 2 },
		{ unitdefs.tool_templates.item_adrenaline, 3 },
		{ unitdefs.tool_templates.item_cloakingrig_1, 1 },		
		{ unitdefs.tool_templates.item_clip, 2 },
		{ unitdefs.tool_templates.item_stim, 3 },
		{ unitdefs.tool_templates.item_emp_pack, 2 },
		{ 50, 3 },
		{ 150, 3 },
		{ 400, 3 },
		{ nil, 40 }, -- cash out the rest of the value in credits
	},  	
}

local ICE_LOWS = 
{
	[1] = 1, 
	[2] = 1, 
	[3] = 2, 
	[4] = 2,
	[5] = 2, 
	[6] = 2, 
	[7] = 3,
	[8] = 3, 
	[9] = 3, 
	[10] = 4,  
}

local ICE_HIGHS = 
{
	[1] = 2,
	[2] = 2, 
	[3] = 3, 
	[4] = 4,
	[5] = 4, 
	[6] = 5, 
	[7] = 5, 
	[8] = 6, 
	[9] = 6, 
	[10] = 7, 
}

local NUM_BOOSTED_ICE = 
{
	[1] = 1, 
	[2] = 2, 
	[3] = 3, 
	[4] = 3,
	[5] = 3,
	[6] = 4, 
	[7] = 4, 
	[8] = 5, 
	[9] = 5, 
	[10] = 6,
}

local MAGNETIC_REINFORCEMENTS_CHANCE = 
{
	[1] = 0, 
	[2] = 0, 
	[3] = 0, 
	[4] = 0,
	[5] = 0,
	[6] = 0.5, 
	[7] = 0.5, 
	[8] = 0.75, 
	[9] = 0.75, 
	[10] = 1,
}

------------------------------------------------------------------------
-- Local functions

function isVersion( params, v1 )
    -- Is the mission parameter version at least v1?
    return version.isVersionOrHigher( params.missionVersion or "", v1 )
end


-- Determines whether loot with a particular value (lootValue) should be chosen,
-- given that there is valueLeft remaining to be apportioned in the level.
-- Note that if valueLeft >= lootValue, p = 1.
-- Only if valueLeft < lootValue do we make a choice.
local function shouldChooseLoot( cxt, lootValue, valueLeft )
	if valueLeft <= 0 then
		-- Always bail in this case.
		return false
	end

	-- Chance to pick this item is based on its value and the valueLeft.
	local p = math.min( 1, (valueLeft / lootValue) * (valueLeft / lootValue) )
	return cxt.rnd:next() <= p
end
 
local function assignZoneIDs( cxt, room, openRooms, closedRooms )
	if room.zoneID ~= nil then
		return
	end
	table.insert( openRooms, room )
	for i, exit in ipairs( room.exits ) do
		if exit.hasDoor or exit.barrier then
			if array.find( closedRooms, exit.room ) == nil then
				-- Potential zone change across a barrier.
				table.insert( closedRooms, exit.room )
			end
		else
			if array.find( openRooms, exit.room ) == nil then
				-- Same zone as this room.
				table.insert( openRooms, exit.room )
				assignZoneIDs( cxt, exit.room, openRooms, closedRooms )
			end
		end
	end
end


local function hasCPUs( unit )
	local templateUnitData = unitdefs.lookupTemplate( unit.template )
	assert( templateUnitData, unit.template )
	return templateUnitData.traits.maxcpus ~= nil
end

local function hasICE( unit )
	local templateUnitData = unitdefs.lookupTemplate( unit.template )
	assert( templateUnitData, unit.template )
	if not templateUnitData.traits.mainframe_console and not templateUnitData.traits.mainframe_ice_set_in_def  then
		return templateUnitData.traits.mainframe_iceMax ~= nil
	else 
		return false 
	end 
end

local function fillCPUs( cxt, unit )
	local templateUnitData = unitdefs.lookupTemplate( unit.template )
	local cpus = math.ceil( unit.unitData.traits.lootValue )
	unit.unitData.traits.cpus = cpus
	--log:write( "PWR - <%d, %d> %d/%d", unit.x, unit.y, cpus, unit.unitData.traits.cpus )
end

local function hasLoot( unit )
	local templateUnitData = unitdefs.lookupTemplate( unit.template )
	assert( templateUnitData, unit.template )
	return templateUnitData.lootTable ~= nil
end

local function fillLoot( cxt, unit )
	if unit.unitData.children == nil then
		unit.unitData.children = {}
	end
	local templateUnitData = unitdefs.lookupTemplate( unit.template )
	local lootTable = util.weighted_list( LOOT_TABLES[ templateUnitData.lootTable ])
	local lootValue = 0
	local lootCount = 0
	local unitLootValue = math.ceil(unit.unitData.traits.lootValue / 10) * 10

	while lootTable:getCount() > 0 and lootCount < MAX_ITEMS do
		local j = cxt.rnd:nextInt( 1, lootTable:getTotalWeight() )
		local lootItem = lootTable:removeChoice( j )
		if lootItem == nil then
			break
		end
		if shouldChooseLoot( cxt, type(lootItem) == "number" and lootItem or lootItem.value, unitLootValue - lootValue ) then
			if type(lootItem) == "number" then
				unit.unitData.traits.credits = (unit.unitData.traits.credits or 0) + lootItem
				lootValue = lootValue + lootItem
			else
				table.insert( unit.unitData.children, lootItem )
				lootValue = lootValue + lootItem.value
				--log:write( "%s <%d, %d> - %s (%d total val, %d target)", unit.template, unit.x, unit.y, lootItem.name, lootValue, unitLootValue )
			end
			lootCount = lootCount + 1
		end
	end
	unit.unitData.traits.credits = (unit.unitData.traits.credits or 0) + math.max( 0, unitLootValue - lootValue )
	--log:write( "%s <%d, %d> - %d credits", unit.template, unit.x, unit.y, unit.unitData.traits.credits )
end

local function assignLoot( cxt )
	-- Find total loot value.
	local totalLootWeight = 0
	local lootUnits = {}
	for i, unit in ipairs( cxt.units ) do
		if hasLoot( unit ) then
			local room = cxt:roomContaining( unit.x, unit.y )
			unit.lootWeight = room.lootWeight + (unit.unitData and unit.unitData.lootWeight or 0)
			totalLootWeight = totalLootWeight + unit.lootWeight
			table.insert( lootUnits, unit )
		end
	end

	-- Sort loot from great value to least.
	table.sort( lootUnits, function( lhs, rhs ) return lhs.lootWeight > rhs.lootWeight end )
	local TIER2_IDX = math.ceil( #lootUnits / 5 )
	local TIER2_VALUE = math.floor( 375 * simdefs.MONEY_SCALAR[ cxt.params.difficulty ] * cxt.params.difficultyOptions.creditMultiplier )
	local TIER1_VALUE = math.floor( 150 * simdefs.MONEY_SCALAR[ cxt.params.difficulty ] * cxt.params.difficultyOptions.creditMultiplier )

	-- Generate the actual lootage.
	for i, unit in ipairs( lootUnits ) do



		if unit.unitData == nil then
			unit.unitData = {}
		end
		if unit.unitData.traits == nil then
			unit.unitData.traits = {}
		end
		if i <= TIER2_IDX then
			if unit.template:find("_safe") ~= nil then
                unit.template = unit.template .. "_tier2"
			end
			unit.unitData.traits.lootValue = TIER2_VALUE
		else
			unit.unitData.traits.lootValue = TIER1_VALUE
		end

		fillLoot( cxt, unit )

		-- One intel per mission.. in the most difficult safe.		
		if i==1 then
			if not cxt.params.world == "omni" then
				cxt.numIntel = cxt.numIntel + 1
				table.insert( unit.unitData.children, unitdefs.prop_templates.item_corpIntel )
			end 
		end
	end
end

local function assignICE( cxt, difficulty )
	local iceLow = ICE_LOWS[difficulty]
	local iceHigh = ICE_HIGHS[difficulty]
	local magneticChance = MAGNETIC_REINFORCEMENTS_CHANCE[difficulty]

	local boostedIce = math.floor( NUM_BOOSTED_ICE[difficulty] * cxt.params.difficultyOptions.firewallMultiplier )

	local iceUnits = {}
	for i, unit in ipairs( cxt.units ) do
		if hasICE( unit ) then
			table.insert( iceUnits, unit )
		end
	end

	for i, unit in ipairs( iceUnits ) do

		if unit.unitData == nil then
			unit.unitData = {}
		end
		if unit.unitData.traits == nil then
			unit.unitData.traits = {}
		end

    	local templateUnitData = unitdefs.lookupTemplate( unit.template )
        if templateUnitData.traits.mainframe_ice <= iceLow then
		    if boostedIce > 0 and cxt.rnd:nextInt(1, 3) == 1 then 
			    boostedIce = boostedIce - 1 
			    unit.unitData.traits.mainframe_iceMax = iceHigh 
		    else
			    unit.unitData.traits.mainframe_iceMax = iceLow 
		    end

            if templateUnitData.traits.mainframe_iceBonus then
                unit.unitData.traits.mainframe_iceMax = unit.unitData.traits.mainframe_iceMax + 1
            end

            if cxt.rnd:next() < magneticChance then
            	unit.unitData.traits.magnetic_reinforcement = true
            end

            unit.unitData.traits.mainframe_ice = unit.unitData.traits.mainframe_iceMax 
        end
	end
end

local function assignCPUs( cxt, totalValue )
	-- Find total loot value.
	local totalLootWeight = 0
	local lootUnits = {}
	for i, unit in ipairs( cxt.units ) do
		if hasCPUs( unit ) then
			local room = cxt:roomContaining( unit.x, unit.y )
			unit.lootWeight = room.lootWeight
			totalLootWeight = totalLootWeight + unit.lootWeight
			table.insert( lootUnits, unit )
		end
	end
	
	-- Generate the actual lootage.
	for i, unit in ipairs( lootUnits ) do
		if unit.unitData == nil then
			unit.unitData = {}
		end
		if unit.unitData.traits == nil then
			unit.unitData.traits = {}
		end
		unit.lootWeight = (unit.lootWeight / totalLootWeight)
		unit.unitData.traits.lootValue = (unit.unitData.traits.lootValue or 0) + unit.lootWeight * totalValue

		fillCPUs( cxt, unit )
	end
end


------------------------------------------------------------------------
-- Adjaceny matrix for zone adjacencies.

local AdjMatrix = class()

function AdjMatrix:init()
	self.m = {}
end

function AdjMatrix:isAdjacent( c1, c2 )
	if self.m[c1] and self.m[c1][c2] then
		return true
	elseif self.m[c2] and self.m[c2][c1] then
		return true
	end
	return false
end

function AdjMatrix:setAdjacent( c1, c2 )
	if self.m[c1] == nil then
		self.m[c1] = {}
	end
	self.m[c1][c2] = true
end

-------------------------------------------------------------
-- Pattern-matching map.

local MapPattern = class()

function MapPattern:init( cxt )
	self.cxt = cxt
	self.matrix = KLEIBitMatrix.new()
end

function MapPattern:burnArea( x0, x1, y0, y1, flag )
	for x = x0, x1 do
		for y = y0, y1 do
			self:setFlag( x, y, flag )
		end
	end
end

function MapPattern:clearArea( x0, x1, y0, y1, flag )
	for x = x0, x1 do
		for y = y0, y1 do
			self:clearFlag( x, y, flag )
		end
	end
end

function MapPattern:setFlag( x, y, flag, mask )
	self.matrix:setBits( x, y, flag, mask )
end

function MapPattern:clearFlag( x, y, flag )
	self.matrix:clearBits( x, y, flag )
end

function MapPattern:test( field, flag )
	return self.matrix:test( field, flag )
end

function MapPattern:testFlag( x, y, flag, mask )
	return self.matrix:testBits( x, y, flag, mask )
end

function MapPattern:getFlags( x, y )
	return self.matrix:getBits( x, y )
end

function MapPattern:burnWall( x, y, dir )
	self:clearDoor( x, y, dir )

	local dx, dy = simquery.getDeltaFromDirection( dir )
	local rdir = simquery.getReverseDirection( dir )

	self:setFlag( x, y, "wall_"..dir )
	self:setFlag( x + dx, y + dy, "wall_"..rdir )
end

function MapPattern:burnDoor( x, y, dir, doorName )
	self:clearWall( x, y, dir )

	local dx, dy = simquery.getDeltaFromDirection( dir )
	local rdir = simquery.getReverseDirection( dir )
	self:setFlag( x, y, "door_"..dir )
	self:setFlag( x + dx, y + dy, "door_"..rdir )
	if doorName then
		self:setFlag( x, y, doorName.."_"..dir )
		self:setFlag( x + dx, y + dy, doorName.."_"..rdir )
	end
end

function MapPattern:clearDoor( x, y, dir )
	local dx, dy = simquery.getDeltaFromDirection( dir )
	local rdir = simquery.getReverseDirection( dir )

	self:clearFlag( x, y, "door_"..dir )
	self:clearFlag( x + dx, y + dy, "door_"..rdir )
end

function MapPattern:clearWall( x, y, dir )
	local dx, dy = simquery.getDeltaFromDirection( dir )
	local rdir = simquery.getReverseDirection( dir )

	self:clearFlag( x, y, "wall_"..dir )
	self:clearFlag( x + dx, y + dy, "wall_"..rdir )
end

function MapPattern:isImpass( x, y, dir )
	local dx, dy = simquery.getDeltaFromDirection( dir )

	if self:testFlag( x, y, "wall_" .. dir ) then
		return true
	elseif self:testFlag( x, y, "secdoor_" .. dir ) then
		return true
	elseif self:testFlag( x + dx, y + dy, "impass" ) or not self:testFlag( x + dx, y + dy, "tile" ) then
		return true
	end

	return false
end

function MapPattern:matchElements( cxt, prefab, fitnessFn )
	local matches = self.matrix:matchElements( prefab.match_elements )
		
	-- Created a weighted list of matches to find out where stuff goes.
	local matchList = util.weighted_list()
	for i = 1, #matches, 2 do
		local x, y = matches[i], matches[i+1]
		local weight = fitnessFn and fitnessFn( cxt, prefab, x, y ) or 1
		if weight > 0 then
			matchList:addChoice( { x, y }, weight )
		end
	end

	return matchList
end

function MapPattern:countElements( ... )
	return self.matrix:countElements( ... )
end

function MapPattern:burnElements( ... )
	return self.matrix:burnElements( ... )
end

function MapPattern:offset( dx, dy )
	self.matrix:offset( dx, dy )
end

------------------------------------------------------------------------
-- Procgen base context

local context = class()

function context:init( params, pass )

	local prefabList = util.tmerge( serverdefs.worldPrefabts, mod_manager.modWorldPrefabs)

	local prefabs = prefabList[ params.world ]
	local shared_prefabs = include( "sim/prefabs/shared/prefabt" )

	self.PREFABT = util.tmerge( {}, prefabs.PREFABT0, shared_prefabs.PREFABT0 )

	for i, prefabt in pairs(mod_manager.modPrefabs)do
		util.tmerge( self.PREFABT, prefabt.PREFABT0 )
	end


	--mod_manager:isDLCOptionEnabled(modID,option)
	--local options = params.difficultyOptions.enabledDLC
	--print("==========================================================================")
	--util.tprint(params)

	for i=#self.PREFABT,1,-1 do
		local prefab = self.PREFABT[i]
		if prefab.tags then
			for t,tag in ipairs(prefab.tags) do

				--CHECK FOR VERSION 
				local versionIndex = string.find(tag, "version_")
				if versionIndex then
					local version = string.gsub(tag, "version_", "" )
					
					if not isVersion( params, version ) then
						table.remove(self.PREFABT,i)
						print("REMOVING PREFAB",version)
					end
				end

				-- REMOVE IF OLD VERSION
				versionIndex = string.find(tag, "depricate_")
				if versionIndex then
					local version = string.gsub(tag, "depricate_", "" )
					
					if isVersion( params, version ) then
						table.remove(self.PREFABT,i)
						print("REMOVING PREFAB",version)
					end
				end				

			end
		end
	end

	self.params = params
	self.rnd = rand.createGenerator( (params.seed + (pass-1) * 101 ) % 2^32 )
	self.difficulty = params.difficulty

	self.units = {}
	self.decos = {}
	self.lights = {}
	self.sounds = {}
	self.candidates = {}
	self.rooms = {}
	self.ice_programs = util.weighted_list()
	self.numIntel = 0

    self.NUM_NULL_CONSOLES = 0 --math.max( 0, params.difficulty - 1 )
	self.NUM_CONSOLES = math.max( 0, params.difficultyOptions.consolesPerLevel - self.NUM_NULL_CONSOLES )
	self.NUM_SAFES = params.difficultyOptions.safesPerLevel

	self.LVL_PATTERN = MapPattern( self )
	self.m0 = AdjMatrix()
end

function context:nextID()
	self._nextID = (self._nextID or 0) + 1
	return self._nextID
end

function context:offsetMap( dx, dy )
	for i, room in ipairs(self.rooms) do
        room:offset( dx, dy )
	end

	self.LVL_PATTERN:offset( dx, dy )

	for i, candidate in ipairs(self.candidates) do
		candidate.tx, candidate.ty = candidate.tx + dx, candidate.ty + dy
	end
end

function context:getBounds()
	local xmin, ymin = 1000, 1000
	local xmax, ymax = -1000, -1000
	for i, room in ipairs(self.rooms) do
		xmin, xmax = math.min( xmin, room.xmin ), math.max( xmax, room.xmax )
		ymin, ymax = math.min( ymin, room.ymin ), math.max( ymax, room.ymax )
	end
	return xmin, ymin, xmax, ymax
end

function context:roomContaining( x, y )
	if x == nil or y == nil then
		return nil
	end

	for i, room in ipairs(self.rooms) do
        for j, rect in ipairs(room.rects) do
		    if rect.x0 <= x and rect.x1 >= x and rect.y0 <= y and rect.y1 >= y then
			    return room
		    end
	    end
    end
end

function context:isOOB( room )
	local xmin, ymin, xmax, ymax = self:getBounds()
	if room.xmin < xmin or room.xmax > xmax then
		return true
	end

	if room.ymin < ymin or room.ymax > ymax then
		return true
	end

	return false
end

function context:isValidRoom( room )
    for _, room2 in ipairs( self.rooms ) do
        if room ~= room2 and roomgen.isIntersecting( room, room2 ) then
    		return false, string.format( "Xsect %d - %d", room.roomIndex, room2.roomIndex )
        end
	end

	if room.walls then
		for i = 1, #room.walls do
			for j = i + 1, #room.walls do
				local w1, w2 = room.walls[i], room.walls[j]
				if w1.dir == w2.dir and not (w1.x1 < w2.x0 or w1.x0 > w2.x1 or w1.y1 < w2.y0 or w1.y0 > w2.y1) then
					return false, "Xsect wall"
				end
			end
			if array.find( self.rooms, room.walls[i].room ) == nil then
				return false, "Bad wall"
			end
			if not array.findIf( room.walls[i].room.walls, function(w) return w.room == room end ) then
				return false, "Non-symmetric wall"
			end
		end
	end

	if self:isOOB( room ) then
		return false, "OOB"
	end

	return true
end

local ADJACENT_EXITS =
{
    --                 N
    --   _|_|_        W*E
    --    |^|          S

    -- dx, dy, delta-dir
    0, 0, simdefs.DIR_E,
    0, 0, simdefs.DIR_W,
    0, 1, simdefs.DIR_E,
    0, 1, simdefs.DIR_W,
    -1, 0, simdefs.DIR_N,
    1, 0, simdefs.DIR_N,
}

function context:countAdjacentDoors( cx, cy, dir )
    local count = 0
    for i = 1, #ADJACENT_EXITS, 3 do
        local dx, dy = simquery.rotateFacing( dir, ADJACENT_EXITS[i], ADJACENT_EXITS[i+1] )
        local ddir = (ADJACENT_EXITS[i+2] + dir - simdefs.DIR_N + simdefs.DIR_MAX) % simdefs.DIR_MAX
    	if self.LVL_PATTERN:testFlag( cx + dx, cy + dy, "door_" .. ddir ) then
            count = count + 1
        end
    end
    return count
end

function context:pickUnit( predFn )
	local units = {}
	for i, unit in ipairs(self.units) do
		if predFn == nil or predFn( unit ) then
			table.insert( units, unit )
		end
	end

	if #units == 0 then
		return nil
	end

	local i = self.rnd:nextInt( 1, #units )
	return units[ i ]
end

function context:pickCell( predFn )
	for y = 1, self.board.height do
		for x = 1, self.board.width do
			local cell = self.board[y][x]
			if predFn( self, x, y, cell) then
				return x, y, cell
			end
		end
	end	

	return nil
end

function context:IS_DEPLOY_CELL( x, y, c )
	return c.deployID ~= nil
end

function context:IS_EXIT_CELL( x, y, c )
	-- dont return the exit cell itself (it's behind impassable doors), but the cell adjacent.
	if c.exitID == nil and c.tileIndex ~= nil and c.tileIndex ~= cdefs.TILE_SOLID then
		for _, dir in ipairs( simdefs.DIR_SIDES ) do
			local dx, dy = simquery.getDeltaFromDirection( dir )
			local side = nil
			if c.sides then
				side = c.sides[ dir ]
			end
			local tocell = self.board[ y + dy ] and self.board[ y + dy ][ x + dx ]
			if (side == nil or side.door) and tocell ~= nil and tocell.exitID ~= nil then
				return true
			end
		end
	end
	return false
end

function context:findPath( x0, y0, x1, y1 )
	if self.pather == nil then
		self.pather = astar.AStar:new(astar_handlers.plan_handler:new(self) )
	end

	return self.pather:findPath( {x = x0, y = y0}, {x = x1, y = y1})
end

function context:generateBoard()
	-- Lower shit.
	local xmin, ymin, xmax, ymax = self:getBounds()
	assert( xmin == 1 and ymin == 1 )

	local board = { width = (xmax - xmin) + 1, height = (ymax - ymin) + 1 }
	for y = 1, board.height do
		board[y] = {}
		for x = 1, board.width do
			board[y][x] = {}
		end
	end

	-- Update context with room info.
	self.board = board	
end

function context:generateUnit( unit )
    return unit
end

function context:generateCell( x, y, zone, variant, prefabData )
	local cell = self.board[y][x]
	local room = self:roomContaining( x, y )

	if not room then
		log:write( "generateCell( %d, %d ) -> no zone!", x, y )
	end
	-- nil zone implies use the "default" zone (as specified by the room tag)
	if zone == nil and room then
		zone = room.zone.name
	end

	local tileIndex
	for i, mapTile in ipairs( cdefs.MAPTILES ) do
		if mapTile.zone.name == zone then
			tileIndex = i
			local tileVariant
			if type(mapTile.variant) == "table" then
				tileVariant = mapTile.variant[ prefabData.facing ]
			else
				tileVariant = mapTile.variant
			end
			if tileVariant == variant then
				break
			end
		end
	end
	cell.tileIndex = tileIndex or cdefs.TILE_UNKNOWN
	if tileIndex then
		cell.noiseRadius = cdefs.MAPTILES[ tileIndex ].noiseRadius
	end
	cell.procgenRoom = room

	if prefabData and room then
		room.tags = room.tags or {}
		for _, tag in ipairs( prefabData.prefab.tags ) do
			room.tags[ tag ] = true
		end
	end

	if cell.tileIndex == cdefs.TILE_UNKNOWN then
		log:write( "generateCell( %d, %d ) -> TILE UNKNOWN (zone=%s, variant=%d)", x, y, tostring(zone), variant )
	end
end

function context:cellAt(x, y)
	return self.board[y] and self.board[y][x]
end

function context:canPath(x0, y0, x1, y1)
	local cell1 = self:cellAt(x0, y0)
	local cell2 = self:cellAt(x1, y1)
	if not cell1 or not cell2 then
		return false
	end
	if cell2.tileIndex == nil or cell2.tileIndex == cdefs.TILE_SOLID or cell2.cell ~= nil or cell2.impass or cell2.dynamic_impass then
		return false
	end

	local dx, dy = x1-x0, y1-y0
	if math.abs(dx) > 1 or math.abs(dy) > 1 then
		return false
	end
	if dx ~= 0 and dy ~= 0 then
		return self:canPath(x0, y0, x1, y0) and self:canPath(x1, y0, x1, y1)
		 and self:canPath(x0, y0, x0, y1) and self:canPath(x0, y1, x1, y1)
	else
		--check walls
		local dir1 = simquery.getDirectionFromDelta(dx, dy)
		local side1 = cell1.sides and cell1.sides[dir1]
		if side1 and (not side1.door or side1.locked) then
			return false
		end
		local dir2 = simquery.getDirectionFromDelta(-dx, -dy)
		local side2 = cell2.sides and cell2.sides[dir2]
		if side2 and (not side2.door or side2.locked) then
			return false
		end

		return true
	end
	return false
end

function context:assignZones( zones )
	for _, rooms in ipairs(zones) do
		for i, room in ipairs(rooms) do
            if room.zone == nil then
			    room.zone = self.ZONES[ (room.zoneID % #self.ZONES) + 1 ]
            end
		end
	end
end

function context:generateConnectivity()
	mazegen.generatePrims( self )

	-- Zone the rooms.
	local zones = {}
	for i, room in ipairs( self.rooms ) do
		if room.zoneID == nil then
			local openRooms, closedRooms = nil, { room }
			while #closedRooms > 0 do
				local room = table.remove( closedRooms )
				openRooms = {}
				assignZoneIDs( self, room, openRooms, closedRooms )

				local zoneID = self:nextID()
				for _, room in ipairs( openRooms ) do
					room.zoneID = zoneID
				end

				table.insert( zones, openRooms )
			end
		end
	end
	
	-- Assign zone types
	self:assignZones( zones )
	for i, room in ipairs(self.rooms) do
		assert( room.zone, util.stringize( room, 2 ))
        for _, rect in ipairs(room.rects) do
    		self.LVL_PATTERN:burnArea( rect.x0, rect.x1, rect.y0, rect.y1, room.zone.pattern )
        end
	end

	-- Compute zone adjacency
	for _, room in ipairs(self.rooms) do
		for _, exit in ipairs( room.exits ) do 
			self.m0:setAdjacent( room.zoneID, exit.room.zoneID )
		end
		self.m0:setAdjacent( room.zoneID, room.zoneID )
	end

	mazegen.makeBarriers( self )
	mazegen.finalize( self )
end

function context:invokeScriptGen( funcName, ... )
	-- Mission script generation hooks.
	for _, filename in ipairs(self.params.scripts) do

		local path = "sim/missions/"
		if self.params.scriptPath then 
			path = self.params.scriptPath
		end

		local script = include( path ..filename )
		if type(script[ funcName ]) == "function" then
			return script[ funcName ]( self, ... )
		end
	end
end

function context:generateBlueprint()
	self:invokeScriptGen( "generatePrefabs", self.candidates )

	local candidates = self:generatePrefabs( )
	util.tmerge( self.candidates, candidates )
end

-- Utility function to calculate how many links and tiles are shared by a given
-- placement of a prefab.
function context:calculatePrefabLinkage( prefab, x, y )
    local tileCount = 0
	for i, room in ipairs(prefab.rooms) do
	    local linkCount = self.LVL_PATTERN:countElements( x, y, room.link_probes )
	    tileCount = tileCount + self.LVL_PATTERN:countElements( x, y, room.tile_probes )

	    if linkCount < (prefab.min_rlinks or 1) and #self.candidates > 0 then
		    return 0 -- Doesn't link up
	    end
    	--print( ">>>", prefab.filename.."."..prefab.facing, x, y, linkCount, tileCount )
    end
    return 1 + tileCount
end


local function defaultFitnessFn( cxt, prefab, x, y )
    local tileCount = cxt:calculatePrefabLinkage( prefab, x, y )
    if tileCount == 0 then
        return 0 -- Doesn't link up
    else
        -- This is a *selection weighting*, so boost fitness based on tileCount exponentially.
 	    return 1 + math.pow( tileCount, 3 )
    end
end

function context:generateRooms()
    local tagSet = {}
    self:invokeScriptGen( "pregeneratePrefabs", tagSet )

    for pass, tags in ipairs( tagSet ) do
	    while #tags > 0 do
		    local tag = table.remove( tags, self.rnd:nextInt( 1, #tags ))
            local fitnessFn = defaultFitnessFn
            if type(tag) == "table" then
                tag, fitnessFn = tag[1], tag[2]
                assert( type(tag) == "string" and type(fitnessFn) == "function" )
            end

		    if prefabs.generatePrefabs( self, self.candidates, tag, 1, fitnessFn, tags.fitnessSelect ) == 0 then
			    log:write( simdefs.LOG_PROCGEN, "Cannot fit "..tag )
		    end
	    end
    end

	return roomgen.createRooms( self, self.candidates )
end

function context:finalize()
	self.board.walltop_color = { 0.2, 0.2, 0.2, 1 }

	-- Assign da phat loots.
	assignLoot( self )
	assignCPUs( self, self.params.difficultyOptions.powerPerLevel )
	assignICE( self, self.difficulty )

	return self:invokeScriptGen( "finalizeProcgen" ) or 1 -- 1 is a passing metric
end

return context

----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

----------------------------------------------------------------

local procgen_room = class()

function procgen_room:init( prefabRoom, dx, dy )
    self.rects = util.tcopy( prefabRoom.rects )
    self:offset( dx or 0, dy or 0 )
end

function procgen_room:offset( dx, dy )
    self.xmin, self.ymin = math.huge, math.huge
    self.xmax, self.ymax = -math.huge, -math.huge
    for i, rect in ipairs(self.rects) do
        rect.x0, rect.x1 = rect.x0 + dx, rect.x1 + dx
        rect.y0, rect.y1 = rect.y0 + dy, rect.y1 + dy
        self.xmin, self.ymin = math.min( self.xmin, rect.x0 ), math.min( self.ymin, rect.y0 )
        self.xmax, self.ymax = math.max( self.xmax, rect.x1 ), math.max( self.ymax, rect.y1 )
    end
end
----------------------------------------------------------------

local function isIntersecting( room1, room2 )
    for _, rect1 in ipairs(room1.rects) do
        for _, rect2 in ipairs(room2.rects) do
        	if not (rect1.x0 > rect2.x1 or rect1.x1 < rect2.x0 or rect1.y0 > rect2.y1 or rect1.y1 < rect2.y0) then
                return true
            end
        end
    end
    return false
end

local function connectRooms( cxt, room, rect, rooms )
	for i, room2 in ipairs(rooms) do
		if room ~= room2 then
			for j, rect2 in ipairs( room2.rects ) do
				if rect.x1 + 1 == rect2.x0 and not (rect2.y0 > rect.y1 or rect2.y1 < rect.y0) then
                    local wall = nil
                    local y0, y1 = math.max( rect.y0, rect2.y0 ), math.min( rect.y1, rect2.y1 )
                    for y = y0, y1 + 1 do
                        if y < y1 + 1 and cxt.LVL_PATTERN:testFlag( rect.x1 + 1, y, "rlink_4" ) and cxt.LVL_PATTERN:testFlag( rect.x1, y, "rlink_0" ) then
                            if wall == nil then
                                wall = { room = room2, dir = simdefs.DIR_E, x0 = rect.x1, y0 = y, x1 = rect.x1, y1 = y }
                            else
                                wall.y1 = y -- Extend the wall
                            end
                        elseif wall then
        					table.insert( room.walls, wall )
                            wall = nil
                        end
                    end

				elseif rect.x0 - 1 == rect2.x1 and not (rect2.y0 > rect.y1 or rect2.y1 < rect.y0) then
                    local wall = nil
                    local y0, y1 = math.max( rect.y0, rect2.y0 ), math.min( rect.y1, rect2.y1 )
                    for y = y0, y1 + 1 do
                        if y < y1 + 1 and cxt.LVL_PATTERN:testFlag( rect.x0 - 1, y, "rlink_0" ) and cxt.LVL_PATTERN:testFlag( rect.x0, y, "rlink_4" ) then
                            if wall == nil then
                                wall = { room = room2, dir = simdefs.DIR_W, x0 = rect.x0, y0 = y, x1 = rect.x0, y1 = y }
                            else
                                wall.y1 = y -- Extend the wall
                            end
                        elseif wall then
        					table.insert( room.walls, wall )
                            wall = nil
                        end
                    end

				elseif rect.y1 + 1 == rect2.y0 and not (rect2.x0 > rect.x1 or rect2.x1 < rect.x0) then
                    local wall = nil
                    local x0, x1 = math.max( rect.x0, rect2.x0 ), math.min( rect.x1, rect2.x1 )
                    for x = x0, x1 + 1 do
                        if x < x1 + 1 and cxt.LVL_PATTERN:testFlag( x, rect.y1 + 1, "rlink_6" ) and cxt.LVL_PATTERN:testFlag( x, rect.y1, "rlink_2" ) then
                            if wall == nil then
                                wall = { room = room2, dir = simdefs.DIR_N, x0 = x, y0 = rect.y1, x1 = x, y1 = rect.y1 }
                            else
                                wall.x1 = x -- Extend the wall
                            end
                        elseif wall then
        					table.insert( room.walls, wall )
                            wall = nil
                        end
                    end

				elseif rect.y0 - 1 == rect2.y1 and not (rect2.x0 > rect.x1 or rect2.x1 < rect.x0) then
                    local wall = nil
                    local x0, x1 = math.max( rect.x0, rect2.x0 ), math.min( rect.x1, rect2.x1 )
                    for x = x0, x1 + 1 do
                        if x < x1 + 1 and cxt.LVL_PATTERN:testFlag( x, rect.y0 - 1, "rlink_2" ) and cxt.LVL_PATTERN:testFlag( x, rect.y0, "rlink_6" ) then
                            if wall == nil then
                                wall = { room = room2, dir = simdefs.DIR_S, x0 = x, y0 = rect.y0, x1 = x, y1 = rect.y0 }
                            else
                                wall.x1 = x -- Extend the wall
                            end
                        elseif wall then
        					table.insert( room.walls, wall )
                            wall = nil
                        end
                    end
                end
			end
		end
	end
end

-- Create exit walls between pairwise rooms which are adjacent (share at least part of a wall)
-- NOTE: the <= and >= clauses prohibit rooms which only share wall of 1 tile length of being adjacent.
local function createRoomWalls( cxt, rooms )
	for i, room in ipairs(rooms) do
		assert( room.walls == nil and room.exits == nil )
		room.walls, room.exits = {}, {}
		for j, rect in ipairs( room.rects ) do
			connectRooms( cxt, room, rect, rooms )
		end
        --assert( #room.walls > 0 )
	end
end

local function createRooms( cxt, candidates )
	local xmin, ymin = math.huge, math.huge
	for i, candidate in ipairs(candidates) do
		for j, prefabRoom in ipairs( candidate.prefab.rooms ) do
            local room = procgen_room( prefabRoom, candidate.tx, candidate.ty )
			room.filename = candidate.filename
			room.roomIndex = 1 + #cxt.rooms
			room.tags = {}
			for k, v in pairs( candidate.prefab.tags ) do
				room.tags[ v ] = true
			end
			if room.tags.hall then
				room.zone = cxt.HALL_ZONE
			end

			xmin, ymin = math.min( xmin, room.xmin ), math.min( ymin, room.ymin )

			table.insert( cxt.rooms, room )
		end
	end

	cxt:offsetMap( -xmin + 1, -ymin + 1 )

	createRoomWalls( cxt, cxt.rooms )

	table.sort( cxt.rooms, function( r1, r2 ) return r1.roomIndex < r2.roomIndex end )

	for i, room in ipairs(cxt.rooms) do
		assert( cxt:isValidRoom( room ))
	end
	return cxt.rooms
end

return
{
	isIntersecting = isIntersecting,

	createRooms = createRooms,
}

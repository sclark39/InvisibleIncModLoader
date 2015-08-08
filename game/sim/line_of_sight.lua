----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

local RAYCAST_PERCENT = 0.45

local function floodLOS( sim, start_cell, facing, halfArc, distance, dx, dy )
	local x0, y0 = start_cell.x + (dx or 0), start_cell.y + (dy or 0)
	local open_list = { [start_cell.id ] = start_cell }
	local close_list = { [start_cell.id ] = start_cell }
    local vis_list = { [start_cell.id ] = start_cell }

	while not util.tempty( open_list ) do
		local cellID, cell = next( open_list )
		open_list[ cell.id ] = nil

		for i = 1, #simdefs.OFFSET_NEIGHBOURS, 2 do
			local dx, dy = simdefs.OFFSET_NEIGHBOURS[i], simdefs.OFFSET_NEIGHBOURS[i+1]
			local adj_cell = sim:getCell( cell.x + dx, cell.y + dy )
			local ok = adj_cell ~= nil
			ok = ok and open_list[ adj_cell.id ] == nil
			ok = ok and close_list[ adj_cell.id ] == nil
			--ok = ok and math.abs(mathutil.angleDiff( facing, mathutil.atan2t( adj_cell.x - x0, adj_cell.y - y0 ))) <= halfArc
			if ok then
                local percentSamples = sim:getLOS().losmap:raycastToCell( x0, y0, adj_cell.x, adj_cell.y, facing, halfArc, distance )
                if percentSamples > 0 then
				    open_list[ adj_cell.id ] = adj_cell
                    if percentSamples >= RAYCAST_PERCENT then
                        vis_list[ adj_cell.id ] = adj_cell
                    end
                end
                close_list[ adj_cell.id ] = adj_cell
			end
		end
	end

	return vis_list
end

local function addWall( segments, cell, dir )
	local dx, dy = simquery.getDeltaFromDirection( dir )
	local nx, ny = dy, -dx
	-- Segments are 'left handed' which defines the normal.
	table.insert( segments, cell.x + dx/2 - nx/2 )
	table.insert( segments, cell.y + dy/2 - ny/2 )
	table.insert( segments, cell.x + dx/2 + nx/2 )
	table.insert( segments, cell.y + dy/2 + ny/2 )
end

local function shouldSightblock( sim, cell, dir )
	local dx, dy = simquery.getDeltaFromDirection( dir )
	local tocell = sim:getCell( cell.x + dx, cell.y + dy )
	-- Don't bother adding a sightblock wall if there's aleady a wall in that direction, or it's another sightblocking cell.
	return cell.exits[ dir ] ~= nil and (tocell == nil or not tocell.sightblock)
end
--------------------------------------------------------------------------
-- Line of sight related functionality.

local line_of_sight = class()

function line_of_sight:init( sim )
	local W, H = sim:getBoardSize()
	local staticSegs, dynamicSegs = {}, {}
	for y = 1, H do
		for x = 1, W do
			local cell = sim:getCell( x, y )
			if cell and cell.sightblock then
				if shouldSightblock( sim, cell, simdefs.DIR_N ) then
					addWall( staticSegs, cell, simdefs.DIR_N )
				end
				if shouldSightblock( sim, cell, simdefs.DIR_E ) then
					addWall( staticSegs, cell, simdefs.DIR_E )
				end
				if shouldSightblock( sim, cell, simdefs.DIR_S ) then
					addWall( staticSegs, cell, simdefs.DIR_S )
				end
				if shouldSightblock( sim, cell, simdefs.DIR_W ) then
					addWall( staticSegs, cell, simdefs.DIR_W )
				end
			end
			for i, dir in ipairs( simdefs.DIR_SIDES ) do
				if cell and cell.exits[ dir ] == nil then
					addWall( staticSegs, cell, dir )
				elseif cell and cell.exits[ dir ] and cell.exits[ dir ].door and cell.exits[ dir ].closed then
					addWall( dynamicSegs, cell, dir )
				end
			end
		end
	end

	local losmap = KLEISightMap.new()
	losmap:init( W, H )
	losmap:insertSegments( staticSegs, dynamicSegs )

	self.sim = sim
	self.losmap = losmap
end

function line_of_sight:insertSegments( ... )
	local segments = {}
	for i = 1, select( "#", ... ), 2 do
		addWall( segments, select( i, ... ), select( i + 1, ... ) )
	end
	self.losmap:insertSegments( nil, segments )
end

function line_of_sight:removeSegments( ... )
	local segments = {}
	for i = 1, select( "#", ... ), 2 do
		addWall( segments, select( i, ... ), select( i + 1, ... ) )
	end
	self.losmap:removeSegments( segments )
end

function line_of_sight:getSegments()
	return self.losmap:getSegments()
end

function line_of_sight:registerSeer( unitID )
	self.losmap:registerSeer( unitID )
end

function line_of_sight:unregisterSeer( unitID )
	self.losmap:unregisterSeer( unitID )
end

function line_of_sight:getSeers( ... )
	-- ... is a packed list of x, y cell coordinates.
	return self.losmap:getSeers( ... )
end

function line_of_sight:getVizCells( unitID, vizcells )
	self.losmap:getVizCells( unitID, vizcells )
end

function line_of_sight:getPeripheralVizCells(unitID, vizcells)
	self.losmap:getVizCells(unitID + simdefs.SEERID_PERIPHERAL, vizcells)
end

function line_of_sight:hasSight( unit, x, y )
	return self.losmap:hasSight( unit:getID(), x, y )
end

function line_of_sight:hasPeripheral( unit, x, y )
	if unit:getTraits().LOSperipheralArc then
		return self.losmap:hasSight( unit:getID() + simdefs.SEERID_PERIPHERAL, x, y )
    else
        return false
	end
end

function line_of_sight:clearSight( unitID, ... )
	return self.losmap:clearSight( unitID, ... )
end

function line_of_sight:markSight( unitID, ... )
	return self.losmap:markSight( unitID, ... )
end

function line_of_sight:refreshSight( unitID, losCoords )
	return self.losmap:refreshSight( unitID, losCoords )
end

function line_of_sight:calculateUnitLOS( start_cell, unit )
    local halfArc = simquery.getLOSArc( unit ) / 2
    local distance = unit:getTraits().LOSrange
	local facingRads = unit:getFacingRad()

    local dx, dy
    if self.sim:isVersion( "0.17.2" ) then
        -- Alter camera raycasting to match the viz (corner cameras actually source from the corner of their cell, argh).
        if unit:getTraits().mainframe_camera then
            local facing = unit:getFacing()
            if facing % 2 == 1 then
                dx, dy = simquery.getDeltaFromDirection( facing )
                if self.sim:isVersion( "0.17.3" ) then
                    dx, dy = -dx/2 * 0.9999, -dy/2 * 0.9999
                else
                    dx, dy = -dx/2 + 0.00001, -dy/2 + 0.00001
                end
            end
        end
    end

	local cells = floodLOS( self.sim, start_cell, facingRads, halfArc, distance, dx, dy )

    local facing = unit:getFacing()
    if unit:getTraits().LOSrads == nil and facing % 2 == 1 then
        -- MAGICAL SIGHT.  On a diagonal facing, see the adjacent two cells.
        local exit1 = start_cell.exits[ (facing + 1) % simdefs.DIR_MAX ] 
        if simquery.isOpenExit( exit1 ) then
            cells[ simquery.toCellID( exit1.cell.x, exit1.cell.y ) ] = exit1.cell
        end
        local exit2 = start_cell.exits[ (facing - 1) % simdefs.DIR_MAX ]
        if simquery.isOpenExit( exit2 ) then
            cells[ simquery.toCellID( exit2.cell.x, exit2.cell.y ) ] = exit2.cell
        end

    elseif unit:getTraits().LOSarc and unit:getTraits().LOSarc >= 2 * math.pi then
        for i, dir in ipairs( simdefs.DIR_SIDES ) do
            local exit1 = start_cell.exits[ dir ]
            if simquery.isOpenExit( exit1 ) then
                cells[ simquery.toCellID( exit1.cell.x, exit1.cell.y ) ] = exit1.cell
            end
        end
    end
    return cells
end

function line_of_sight:calculatePeripheralLOS( start_cell, unit )
    local halfArc = unit:getTraits().LOSperipheralArc / 2
    local distance = unit:getTraits().LOSperipheralRange
	local facingRads = unit:getFacingRad()
    return floodLOS( self.sim, start_cell, facingRads, halfArc, distance )
end

function line_of_sight:calculateLOS( start_cell, facingRads, halfArc, distance )
	return floodLOS( self.sim, start_cell, facingRads, halfArc, distance )
end

function line_of_sight:probeLOS( x0, y0, dir, range )
    assert( array.find( simdefs.DIR_SIDES, dir ) ~= nil ) -- Cardinal dirs only.
    range = range or 100
    local dx, dy = simquery.getDeltaFromDirection( dir )
    local x1, y1 = x0 + (dx * range), y0 + (dy * range)
    local xt, yt = self.losmap:raycast( x0, y0, x1, y1 )
    local cells = {}
    local lastCover = 0
    for i = 0, range do
        local x, y = x0 + (dx * i), y0 + (dy * i)
        -- Is this cell valid?
        if math.abs(x - x0) > math.abs(xt - x0) or math.abs(y - y0) > math.abs(yt - y0) then
            break -- beyond raycast obstruction
        end
        local cell = self.sim:getCell( x, y )
        if not cell then
            break
        end
        if (cell.cover or 0) == 0 and lastCover == 0 then
            table.insert( cells, cell )
        else
            lastCover = (cell.cover or 0)
        end
    end
    return cells
end

function line_of_sight:withinLOS( unit, ... )
    local x0, y0 = unit:getLocation()
    local halfArc = simquery.getLOSArc( unit ) / 2
    if self.sim:isVersion( "0.17.1" ) then
        halfArc = math.max( halfArc, (unit:getTraits().LOSperipheralArc or 0) / 2 )
    end
    local distance = unit:getTraits().LOSrange
	local facingRads = unit:getFacingRad()

    return self.losmap:withinLOS( x0, y0, facingRads, halfArc, distance, ... )
end

function line_of_sight:raycast( ... )
	return self.losmap:raycast( ... )
end

function line_of_sight:raycastToCell( x0, y0, x1, y1, facing, halfArc, distance )
    local percentSamples = self.losmap:raycastToCell( x0, y0, x1, y1, facing, halfArc, distance )
    return percentSamples >= RAYCAST_PERCENT, percentSamples
end

return line_of_sight

----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local viz_thread = include( "gameplay/viz_thread" )
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

-----------------------------------------------------
-- LOS non-blocking reveal viz thread.
-- Reveals cells over time when they are seen.

local reveal_los = class( viz_thread )

function reveal_los:init( boardRig, ev )
    self.boardRig = boardRig
    self.ev = ev
	local x0, y0 = ev.eventData.seer:getLocation()

	-- Update the actual viz cells based on LOS info
	local updateCells = {}
	for i = 1, #ev.eventData.cells, 2 do
		local x, y = ev.eventData.cells[i], ev.eventData.cells[i+1]
		local cellviz = self.boardRig:getClientCellXY( x, y )
        if array.find( updateCells, cellviz ) == nil then
		    table.insert( updateCells, cellviz )
            -- Must add adjacents too, because their viz status depends on ours. :(
            for _, dir in ipairs( simdefs.DIR_SIDES ) do
                if cellviz:getSide( dir ) == nil then
                    local dx, dy = simquery.getDeltaFromDirection( dir )
                    local adjviz = self.boardRig:getClientCellXY( x + dx, y + dy )
                    if adjviz and array.find( updateCells, adjviz ) == nil then
                        table.insert( updateCells, adjviz )
                    end
                end
            end
        end
	end

	table.sort( updateCells,
		function( l, r )
			local distl = math.abs( l._x - x0 ) + math.abs( l._y - y0 )
			local distr = math.abs( r._x - x0 ) + math.abs( r._y - y0 )
			return distl > distr
		end )

    self.updateCells = updateCells
    self.updateRigs = {} -- Just to avoid lots of temp tables.

    viz_thread.init( self, ev.viz, self.onResume )
	ev.viz:registerHandler( simdefs.EV_FRAME_UPDATE, self )
    self:unblock()
end

function reveal_los:onStop()
    -- Stoppin: instantly reveal all rigs that remain
    self.boardRig:revealAll( self.updateCells )
end

function reveal_los:onResume( ev )
    local updatedRigs = {}
    local i = 0
    while #self.updateCells > 0 do
        i = i + 1
        self.boardRig:revealCell( table.remove(self.updateCells), updatedRigs )
        if i % 2 == 0 then
            coroutine.yield()
        end
	end
end

return reveal_los

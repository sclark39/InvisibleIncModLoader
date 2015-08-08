----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local animmgr = include( "anim-manager" )
local binops = include( "modules/binary_ops" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local walltypes = include( "sim/walltypes" )

----------------------------------------------------------------
-- Local functions

local function isUnknownCell( boardRig, rawcell )
    if rawcell.tileIndex ~= cdefs.TILE_UNKNOWN then
        for _, dir in ipairs( simdefs.DIR_SIDES ) do
    	    local dx, dy = simquery.getDeltaFromDirection( dir )
		    local tocell = boardRig:getLastKnownCell( rawcell.x + dx, rawcell.y + dy )
		    if tocell and rawcell.exits[ dir ] then
                return true
		    end
	    end
    end
    return false
end

----------------------------------------------------------------
-- Cellrig

local cell_rig = class( )

function cell_rig:init( boardRig, x, y )
	local game = boardRig._game
	local layer = boardRig:getLayer("floor")
	local cell = game.simCore:getCell( x, y )

	self._boardRig = boardRig
	self._layer = layer
	self._game = game
	self._x, self._y = x, y
	self._dependentRigs = {} -- the wall, post, and door rigs inside this cell

	if cell == nil then
		self._sides = {}
		for _, dir in ipairs( simdefs.DIR_SIDES ) do
			local dx, dy = simquery.getDeltaFromDirection( dir )
			local acell = game.simCore:getCell( x + dx, y + dy )
			local rdir = simquery.getReverseDirection( dir )
			if acell then
				self._sides[ dir ] = acell.sides[ rdir ]
			end
		end
	else
		self._sides = cell.sides
	end

	self.tileIndex = cell and cell.tileIndex
end


function cell_rig:destroy( )
end

function cell_rig:getSides()
	return self._sides
end

function cell_rig:getSide( dir )
	return self._sides[ dir ]
end

function cell_rig:refreshDependentRigs( updatedRigs )
	for _, wallRig in ipairs(self._dependentRigs) do
        if updatedRigs[ wallRig ] == nil then
		    updatedRigs[ wallRig ] = wallRig
            wallRig:refresh()
        end
	end
end

function cell_rig:refresh( )
	local scell = self._boardRig:getLastKnownCell( self._x, self._y )
    local rawcell = self._game.simCore:getCell( self._x, self._y )
	if rawcell ~= nil then
		local orientation = self._boardRig._game:getCamera():getOrientation()

		local idx = cdefs.BLACKOUT_CELL
		local flags = MOAIGridSpace.TILE_HIDE

		local gfxOptions = self._game:getGfxOptions()
   		if gfxOptions.bMainframeMode then
			if scell then
				idx, flags = cdefs.MAINFRAME_CELL + orientation, 0
            elseif isUnknownCell( self._boardRig, rawcell ) then
				idx, flags = cdefs.MAINFRAME_UNKNOWN_CELL, 0
   			end

        elseif rawcell.tileIndex ~= cdefs.TILE_UNKNOWN and scell == nil then
            if isUnknownCell( self._boardRig, rawcell ) then
                idx, flags = cdefs.UNKNOWN_CELL, 0
            end

        elseif gfxOptions.bTacticalView then
            local localPlayer = self._game:getLocalPlayer()
			local isWatched = localPlayer and simquery.isCellWatched( self._game.simCore, localPlayer, self._x, self._y )
			if isWatched == simdefs.CELL_WATCHED then
                idx, flags = cdefs.WATCHED_CELL, 0
			elseif isWatched == simdefs.CELL_NOTICED then
                idx, flags = cdefs.NOTICED_CELL, 0
			else
                if self._boardRig:isBlindSpot( self._x, self._y ) then
                    idx, flags = cdefs.COVER_CELL, 0
                else
                    idx, flags = cdefs.SAFE_CELL, 0
                end
			end
                        
        else
			local mapTile = cdefs.MAPTILES[ rawcell.tileIndex ]
			idx = mapTile.tileStart + (self._x-1 + self._y-1) % mapTile.patternLen
            flags = 0
		end
		self._boardRig._grid:getGrid():setTile( self._x, self._y, idx )
		self._boardRig._grid:getGrid():setTileFlags( self._x, self._y, flags )
	end
end

return cell_rig



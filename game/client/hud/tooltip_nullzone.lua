----------------------------------------------------------------
-- Copyright (c) 2015 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local level = include( "sim/level" )
local simdefs = include( "sim/simdefs" )

------------------------------------------------------------------------------
-- Local functions

local nullZoneTooltip = class( util.tooltip )

function nullZoneTooltip:init( hud, unit )
    util.tooltip.init( self, hud._screen )
    self.unit = unit
    self.x, self.y = unit:getLocation()
    self.range = unit:getTraits().mainframe_suppress_range
    self.hud = hud
end

function nullZoneTooltip:activate( screen )
    local simquery = include( "sim/simquery" )
    local mainframe = include( "sim/mainframe" )
    local game = self.hud._game
    self.cells = simquery.rasterCircle( game.simCore, self.x, self.y, self.range )
    self.hiliteID = game.boardRig:hiliteCells( self.cells, { util.color.GRAY:unpack() })
	for i = 1, #self.cells, 2 do
        local cell = game.simCore:getCell( self.cells[i], self.cells[i+1] )
        if cell then
            for j, cellUnit in ipairs(cell.units) do
                if cellUnit ~= self.unit and (cellUnit:getTraits().mainframe_ice or 0) > 0 then
                    game.boardRig:getUnitRig( cellUnit:getID() ):getProp():setRenderFilter( cdefs.RENDER_FILTERS["focus_target"] )
                end
            end
        end
    end
end

function nullZoneTooltip:deactivate()
    local mainframe = include( "sim/mainframe" )
    local game = self.hud._game
    game.boardRig:unhiliteCells( self.hiliteID )
	for i = 1, #self.cells, 2 do
        local cell = game.simCore:getCell( self.cells[i], self.cells[i+1] )
        if cell then
            for j, cellUnit in ipairs(cell.units) do
                if cellUnit ~= self.unit and (cellUnit:getTraits().mainframe_ice or 0) > 0 then
                    game.boardRig:getUnitRig( cellUnit:getID() ):refresh() 
                end
            end
        end
    end
end

return nullZoneTooltip
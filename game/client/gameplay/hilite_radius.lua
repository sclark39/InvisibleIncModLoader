----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local simquery = include( "sim/simquery" )
local simdefs = include( "sim/simdefs" )

----------------------------------------------------------------
local DEFAULT_RING_CLR = { 0.5, 0.5, 0.5, 0.5 }

-- Cache of cell deltas for a given circle of radius.
local RADIUS_CELLS = {}
local function getCircleCells( r )
    if RADIUS_CELLS[ r ] == nil then
        local t = {}
        for dx = -r, r do 
		    for dy = -r, r do
			    local distance = math.floor( mathutil.dist2d( 0, 0, dx, dy ) )
			    if distance == r then
                    table.insert( t, dx )
                    table.insert( t, dy )
			    end
		    end
        end
        RADIUS_CELLS[ r ] = t
    end

    return RADIUS_CELLS[ r ]
end

----------------------------------------------------------------

local hilite_radius = class()

function hilite_radius:init( x, y, radius )
    self.x, self.y, self.radius = x, y, radius
    self.currentTime = 0
    self.startdecaytime = 0
    self.period = 30
    self.lifetime = 30
end

function hilite_radius:setRate( period, lifetime, startdecaytime )
    self.period = period or self.period
    self.lifetime = lifetime or self.lifetime
    self.startdecaytime = startdecaytime or self.startdecaytime
end

function hilite_radius:setColor( clr )
    self.clr = clr or self.clr
end

function hilite_radius:setCells( cells )
    self.cells = {}
    for i,x,y in util.xypairs(cells) do
        self.cells[ simquery.toCellID( x, y ) ] = true
    end
end

function hilite_radius:updateCells( cells )
     -- This is the # of frames between rings. (eg. at self.period, radius=1 has max alpha, at self.period*2, radius=2 has max alpha, etc.)
    -- This is the lifetime for each individual radius. The ring fades in self.period * (radius-1), and lasts RADIUS_LIFETIME frames.
	local TOTAL_PERIOD = self.period * self.radius + self.lifetime
	local EPSILON = 0.3
    
    for radius = 1, self.radius do
        local r, g, b, a = unpack(self.clr or DEFAULT_RING_CLR)
        local minTime = self.period * (radius-1)
        local t = (self.currentTime - minTime) / self.lifetime
		if t > 0 and t <= 1 then
            -- t is in (0, 1].  Remap t to 'fade' to give a specific alpha easing.
            local fade
            if t < EPSILON then
                fade = math.sqrt(t/EPSILON)
			else
				fade = 1 - (t-EPSILON-self.startdecaytime) / (1-EPSILON-self.startdecaytime)
				fade = math.min(1, math.max(0,fade))
            end
            r, g, b, a = r * fade, g * fade, b * fade, a * fade
            local deltas = getCircleCells( radius )
            for i = 1, #deltas, 2 do
                local cellId = simquery.toCellID( self.x + deltas[i], self.y + deltas[i+1] )
                if (cells[ cellId ] == nil or cells[ cellId ][4] < a) and (self.cells == nil or self.cells[ cellId ] ~= nil ) then
                    cells[ cellId ] = { r, g, b, a }
		        end
	        end
        end
    end

    self.currentTime = self.currentTime + 1
    return self.currentTime <= TOTAL_PERIOD
end

return hilite_radius

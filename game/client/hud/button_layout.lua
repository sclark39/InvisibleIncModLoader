----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")
local cdefs = include( "client_defs" )

---------------------------------------------------------
-- Layout tuning. THESE ARE VERY CAREFULLY TUNED. :D

local DEFAULT_TUNING =
{
    -- Radius at which the buttons are initially placed from the selected unit's location
    initRadius = 64,
    -- Magnitude at which buttons/static regions push away at eachother
    repulseMagnitude = 5,
    -- Inverse squared magnitude is capped at this minimum distance.
    repulseDist = 40,
    -- Max iterations to figure out a layout placement
    maxIters = 10,
}

---------------------------------------------------------
-- Layout class 

local button_layout = class()

function button_layout:init( originx, originy )
	self._originx, self._originy = originx, originy
	self._layout = {}
    self._statics = {}
    self._tuning = DEFAULT_TUNING
end

function button_layout:addStaticLayout( wx, wy, wz )
    table.insert( self._statics, { wx, wy, wz } )
end

function button_layout:destroy( screen )
	for layoutID, layout in pairs( self._layout ) do
		screen:removeWidget( layout.leaderWidget )
	end
	self._layout = nil
end

function button_layout:calculateLayout( screen, game, widgets )
	for i, widget in ipairs( widgets ) do
        assert( widget.worldx )
		local layoutID = widget.layoutID or tostring(widget)
		local layout = self._layout[ layoutID ]
		if layout == nil then
			local leaderWidget = screen:createFromSkin( "LineLeader" )
			screen:addWidget( leaderWidget )
			leaderWidget.binder.line:appear( 0.5 )
			layout =
				{
					widgets = { widget },
					leaderWidget = leaderWidget
				}
			self._layout[ layoutID ] = layout
		end

		local idx = array.find( layout.widgets, widget )
		if idx == nil then
			table.insert( layout.widgets, widget )

		elseif idx == 1 then
    		local wx, wy = game:worldToWnd( widget.worldx, widget.worldy, widget.worldz )
			layout.startx, layout.starty = wx, wy
			layout.posx, layout.posy = wx, wy
            local cx, cy = game:worldToWnd( self._originx, self._originy )
            -- Offset the centre by a delta dependent on the widget index so that widgets that originate at the same
            -- world location don't end up being in the exact same position.
            local dcx, dcy = 8 * math.cos( 2*math.pi * (i / #widgets) ), 8 * math.sin( 2*math.pi * (i / #widgets ))
            cx, cy = cx + dcx, cy + dcy
            local dist = mathutil.dist2d( cx, cy, wx, wy )
            if dist > 0 then
                local radius = self._tuning.initRadius
                layout.posx, layout.posy = layout.posx + radius * (wx - cx) / dist, layout.posy + radius * (wy - cy) / dist
            else
                layout.posx = layout.posx + self._tuning.initRadius
            end
		end
	end

    for i, coords in ipairs( self._statics ) do
        coords.posx, coords.posy = game:worldToWnd( coords[1], coords[2], coords[3] )
 	end

	local iters = 0
	while iters < self._tuning.maxIters and self:hasOverlaps( self._layout, self._statics ) do
		self:doPass( self._layout, self._statics )
		iters = iters + 1
	end
end

function button_layout:setPosition( widget )
	local layoutID = widget.layoutID or tostring(widget)
	local layout = self._layout[ layoutID ]
	if layout ~= nil then
		local W, H = widget:getScreen():getResolution()
		local OFFSET_X, OFFSET_Y = (40/W), (22/H)
		local x, y = widget:getScreen():wndToUI( layout.posx, layout.posy )
		local startx, starty = widget:getScreen():wndToUI( layout.startx, layout.starty )
		local idx = util.indexOf( layout.widgets, widget )
		x = x + (idx - 1) * OFFSET_X
		widget:setPosition( x, y )
		if idx == 1 then
			layout.leaderWidget:setPosition( startx, starty )
			local x0, y0 = x - OFFSET_X/2 - startx, y - starty
			local x1, y1 = x + OFFSET_X * #layout.widgets - startx - OFFSET_X/2, y - starty
			if y > starty then
				y0, y1 = y0 - OFFSET_Y, y1 - OFFSET_Y
			else
				y0, y1 = y0 + OFFSET_Y, y1 + OFFSET_Y
			end
			if math.abs( x0 ) < math.abs( x1 ) then
				layout.leaderWidget.binder.line:setTarget( x0, y0, x1, y1 )
			else
				layout.leaderWidget.binder.line:setTarget( x1, y1, x0, y0 )
			end
		end
		return true
	end
end


--------------------------------------------------------------------------------------
-- Dynamically arranges things according to some vague sense of aesthetic sensibility.

function button_layout:updateForce( fx, fy, dx, dy, mag )
    if mag then
        maxDist = self._tuning.repulseDist
	    local d = math.sqrt( dx*dx + dy*dy )
	    if d < 1 then
		    mag = 0
        elseif d > maxDist * 4 then
            mag = 0
	    else
		    mag = mag * math.min( 1, (maxDist * maxDist) / (d*d)) -- inverse sqr mag.
		    dx, dy = dx / d, dy / d
	    end
	
	    fx, fy = fx + mag * dx, fy + mag * dy
    end
	return fx, fy
end
 
function button_layout:getCircle( layoutID, index )
	local OFFSET_X, OFFSET_Y = 40, 48 -- Bounds of the rectangle for a widget.
    local ll = self._layout[ layoutID ]
    return ll.posx + OFFSET_X * (index-1), ll.posy, 42
end

function button_layout:hasOverlaps( layout, statics )
    local overlaps = 0
    for layoutID, l in pairs( layout ) do
        for i = 1, #l.widgets do
            local x0, y0, r0 = self:getCircle( layoutID, i )
	        for w2, ll in pairs(layout) do
		        if w2 ~= layoutID then
                    for j = 1, #ll.widgets do
                        local x1, y1, r1 = self:getCircle( w2, j )
                        if mathutil.dist2d( x0, y0, x1, y1 ) <= r0 then
                            return true
                        end
		            end
                end
	        end
            for i, static in pairs(statics) do
                if mathutil.dist2d( x0, y0, static.posx, static.posy ) <= r0 then
                    return true
                end
            end
        end
    end

    return false
end

function button_layout:calculateForce( layoutID, layout, statics )
	local fx, fy = 0, 0
    local l = layout[ layoutID ]
    for i = 1, #l.widgets do
        local x0, y0, r0 = self:getCircle( layoutID, i )
	    for w2, ll in pairs(layout) do
		    if w2 ~= layoutID then
                for j = 1, #ll.widgets do
                    local x1, y1, r1 = self:getCircle( w2, j )
			        fx, fy = self:updateForce( fx, fy, x0 - x1, y0 - y1, self._tuning.repulseMagnitude )
		        end
            end
	    end
        for i, ll in pairs(statics) do
            local x1, y1 = ll.posx, ll.posy
            fx, fy = self:updateForce( fx, fy, x0 - x1, y0 - y1, self._tuning.repulseMagnitude )
        end
    end

    return fx, fy
end


function button_layout:doPass( layout, statics )
	for layoutID, l in pairs(layout) do
		-- Get the force on this widget.
		l.fx, l.fy = self:calculateForce( layoutID, layout, statics )
	end
	
	-- Apply forces
	for w, l in pairs(layout) do
	    l.posx, l.posy = l.posx + l.fx, l.posy + l.fy
	end
end

return button_layout



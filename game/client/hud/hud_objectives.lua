----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local color = include( "modules/color" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")

------------------------------------------------------------------
-- Objectives UI.

local hud_objectives = class()

function hud_objectives:init( hud )
    self.hud = hud
    self.objectiveWidgets = {}
    self.groupWidget = hud._screen.binder.objectivesTopLabel
    self.cursorY = 0 -- Keeps track of the pixel coordinate of the next added objective widget
end

function hud_objectives:clear()
    while #self.objectiveWidgets > 0 do
		self.groupWidget:removeChild( table.remove( self.objectiveWidgets ) )
	end
    self.cursorY = 0
end

function hud_objectives:addLine( txt )
	local widget = self.hud._screen:createFromSkin( "objectiveLine", { xpx = true, ypx = true } )
    self.groupWidget:addChild( widget )

    widget.binder.txt:setText( txt )

    local xmin, ymin, xmax, ymax = widget.binder.txt:getStringBounds()
    local W, H = self.hud._screen:getResolution()
    local _, maxHeight = widget.binder.txt:getSize()
    local height = 4 + math.floor(((ymax - ymin) * H + 0.5) / 2) * 2
            
    widget:setPosition( nil, self.cursorY + height - maxHeight/2)

    table.insert( self.objectiveWidgets, widget )
    self.cursorY = self.cursorY + height
end

function hud_objectives:addTimer( current, max )
    local TIMED_OBJECTIVE_HEIGHT = 22
	local widget = self.hud._screen:createFromSkin( "objectiveTimed", { xpx = true, ypx = true } )
	self.groupWidget:addChild( widget )
	widget:setPosition( nil, self.cursorY + TIMED_OBJECTIVE_HEIGHT/2 )

	for i, bar in widget.binder:forEach( "bar" ) do 
		if i > max then 
			bar:setVisible( false )
		else 
			bar:setVisible( true )
			if i <= current then 
				bar:setColor( 244/255, 255/255, 120/255, 1 )
			else 
				bar:setColor( 34/255, 34/255, 58/255, 1 )
			end
		end 
	end 

	table.insert( self.objectiveWidgets, widget )
    self.cursorY = self.cursorY + TIMED_OBJECTIVE_HEIGHT
end

function hud_objectives:refreshObjectives()
	if config.RECORD_MODE then
		return
	end
    
    local game = self.hud._game
    local screen = self.hud._screen
	local objectives = game.simCore:getObjectives()
    local isVisible = (game.simCore:getCurrentPlayer() == game:getLocalPlayer()) and #objectives > 0

    self:clear()

    if not isVisible then
	    self.groupWidget:setVisible( false )
        return
    end

	for _, objective in ipairs(objectives) do 
		--If the objective is a normal one-liner or a multi-turn objective
        if objective.objType == "line" then
            self:addLine( objective.txt )

        else
            self:addTimer( objective.current, objective.max )
            self:addLine( objective.txt )
		end
	end

    self.groupWidget.binder.header:setPosition( nil, self.cursorY + 12 )
	self.groupWidget:setVisible( true )
end

return hud_objectives

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

----------------------------------------------------------------
-- This manages "in-world" HUD, which are HUD elements whose location
-- is specified in world space.  The screen-space location of these HUD elements
-- therefore needs to be updated whenever the camera is altered.

local world_hud = class()

world_hud.MAINFRAME = "mf"
world_hud.HUD = "hud"
world_hud.HUD_FLOATERS = "hudf"
world_hud.FLAGS = "flags"

function world_hud:init( game )
	self._game = game
	self._widgets = {}
	self._layouts = {}
	self._screen = mui.createScreen( "hud-inworld.lua" )
	mui.activateScreen( self._screen )
end

function world_hud:destroy()
	mui.deactivateScreen( self._screen )

	for groupKey, layout in pairs( self._layouts ) do
		layout:destroy( self._screen )
	end

	self._screen = nil
	self._widgets = nil
	self._layouts = nil
end

function world_hud:show()
	self._screen:setVisible(true)
end

function world_hud:hide()
	self._screen:setVisible(false)
end

function world_hud:setMainframe( isMainframe, drawFn )
	self._screen.binder.iceScript:setVisible( isMainframe )
	self._screen.binder.iceScript:setDraw( drawFn )
end

function world_hud:setLayout( groupKey, layout )
	assert( layout )
	self._layouts[ groupKey ] = layout
end


function world_hud:createWidget( groupKey, skinName, t, updateFn, destroyFn )
	local widget = self._screen:createFromSkin( skinName )
	if t then
		for k, v in pairs(t) do
			widget[k] = v
		end
	end
	widget.destroyFn = destroyFn
	self._screen:addWidget( widget )
	if updateFn then
		widget.updateFn = updateFn
		updateFn( self._screen, widget )
	elseif widget.worldx then
		local wx, wy = self._game:worldToWnd( widget.worldx, widget.worldy, widget.worldz )
		widget:setPosition( self._screen:wndToUI( wx, wy ))
	end

	if not self._widgets[ groupKey ] then
		self._widgets[ groupKey ] = {}
	end

	table.insert( self._widgets[ groupKey ], widget )
	widget._world_hud = self

	return widget
end

function world_hud:moveToFront( widget )
	self._screen:reorderWidget( widget, nil )
end


function world_hud:refreshWidgets()
	for groupKey, widgets in pairs( self._widgets ) do
		local layout = self._layouts[ groupKey ]
		if layout then
			layout:calculateLayout( self._screen, self._game, widgets )
		end

		for i = #widgets, 1, -1 do 
            local widget = widgets[i]
			if widget.updateFn and widget.updateFn( self._screen, widget ) then
                self:destroyWidget( groupKey, widget )
			elseif (layout == nil or not layout:setPosition( widget )) and widget.worldx then
				local x0, y0 = self._game:worldToWnd( widget.worldx, widget.worldy, widget.worldz )
				local x1, y1 = self._screen:wndToUI( x0, y0 )
				widget:setPosition(x1,y1)
			end
		end
	end
end

function world_hud:destroyWidget( groupKey, widget )
	assert( array.find( self._widgets[ groupKey ], widget ))
	array.removeElement( self._widgets[ groupKey ], widget )
	self._screen:removeWidget( widget )
	if widget.destroyFn then
		widget:destroyFn()
	end
end

function world_hud:destroyWidgets( groupKey )
	local widgets = self._widgets[ groupKey ]
	while widgets and #widgets > 0 do
		local widget = table.remove( widgets )
		self._screen:removeWidget( widget )
		if widget.destroyFn then
			widget:destroyFn()
		end
	end

	if self._layouts[ groupKey ] then
		self._layouts[ groupKey ]:destroy( self._screen )
		self._layouts[ groupKey ] = nil
	end
end

function world_hud:getWidgets( groupKey )
	return self._widgets[ groupKey ]
end

return world_hud



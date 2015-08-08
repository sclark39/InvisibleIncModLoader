-----------------------------------------------------
-- MOAI UI
-- Copyright (c) 2012-2012 Klei Entertainment Inc.
-- All Rights Reserved.

local util = require( "modules/util" )
local array = require( "modules/array" )
local mui_container = require( "mui/widgets/mui_container" )
local mui_defs = require( "mui/mui_defs" )
local mui_util = require("mui/mui_util")
local mui_binder = require("mui/mui_binder")
local mui_tooltip = require( "mui/mui_tooltip" )

local mui_screen = class()

local ACTIVE_PRIORITY = 1 -- static incrementing value
local TOOLTIP_PRIORITY = 10000000

-- Name of the default tooltip skin used for displaying tooltips.
local DEFAULT_TOOLTIP_SKIN = "tooltip"

----------------------------------------------------------
-- Local Functions
----------------------------------------------------------
	
function mui_screen:init( internals, ui, filename )
	self._internals = internals
	self._ui = ui
	self._root = mui_container( { x = 0, y = 0, w = 0, h = 0 } )
	self._root._parent = self
	self._widgets = {}
	self._propToWidget = {}
	self._handlers = {}
	self._transitions = {}
	self._allTextStyles = {}
	self._lockWidgets = {}
	self._layer = nil
	self._viewport = nil
	self._camera = nil
	self._priority = nil
	self._isEnabled = true
	self._props = ui.properties or { sinksInput = true }
	self._filename = filename
	self.binder = mui_binder.create( self )
	
	-- Add all the dependents.
	local function fn( ui )
		if ui._textStyles then
			util.tmerge( self._allTextStyles, ui._textStyles )
		end
		if ui.transitions then
			for _, transition in ipairs( ui.transitions ) do
				self._transitions[ transition.name ] = transition
			end
		end
		if ui.dependents then
			for _, dependent in ipairs( ui.dependents ) do
				fn( dependent )
			end
		end
	end

	fn( ui )
end

function mui_screen:wndToUI( x, y )
	return self._layer:wndToWorld( x, y )
end

function mui_screen:uiToWnd( x, y )
	return self._layer:worldToWnd( x, y )
end

function mui_screen:wndToUISize( x, y )
	local x0, y0 = self._layer:wndToWorld( 0, 0 )
	x, y = self._layer:wndToWorld( x, y )
	
	return x - x0, y0 - y
end

function mui_screen:uiToWndSize( x, y )
	local x0, y0 = self._layer:worldToWnd( 0, 0 )
	local x1, y1 = self._layer:worldToWnd( x, y )

	return math.abs(x1 - x0), math.abs(y1 - y0)
end

function mui_screen:getSkin()
	if self._ui.currentSkin then
		return self._ui.currentSkin
	else
		local W, H = self:getResolution()
		if H <= 720 then
			return "Small"
		else
			return nil
		end
	end
end

function mui_screen:getLayer()
	return self._layer
end

function mui_screen:getProperties()
	return self._props
end

function mui_screen:setVisible( isVisible )
	self._layer:setVisible( isVisible )
	self._root:setVisible( isVisible )
end

function mui_screen:isVisible()
	return self._root:isVisible()
end

function mui_screen:hasTransition( ... )
	return self._root:hasTransition( ... )
end

function mui_screen:createTransition( name, fn, params )
	local transitionDef = self._transitions[ name ]
	assert( transitionDef, name )

	if params then
		transitionDef = util.inherit( transitionDef )( params )
	end

	self._root:createTransition( transitionDef, fn )
end

function mui_screen:reverseTransition( ... )
	self._root:reverseTransition( ... )
end

function mui_screen:setEnabled( isEnabled )
	self._isEnabled = isEnabled
	self:onLostTopmost()
end

function mui_screen:isEnabled()
	return self._isEnabled
end

function mui_screen:setPriority( priority )
	self._priority = priority
end

function mui_screen:getPriority()
	return self._priority
end

function mui_screen:setTooltip( tooltip )
	if type(tooltip) == "string" then
		if self._tooltipStr ~= tooltip then
			self._tooltip = mui_tooltip( nil, tooltip, nil )
			self._tooltipStr = tooltip
		end
	else
		self._tooltip = tooltip
		self._tooltipStr = nil
	end
	assert( self._tooltip == nil or self._tooltip.activate ~= nil )
end

function mui_screen:getCamera()
	return self._camera
end

function mui_screen:getTooltip()
	return self._tooltip
end

function mui_screen:getAllTextStyles()
	return self._allTextStyles
end

function mui_screen:resolveFilename( filename )
	return self._internals.resolveFilename( filename )
end

function mui_screen:createWidget( def )
	return self._internals.createWidget( def, self._ui, self )
end

function mui_screen:createFromSkin( skinName, def )
	if def then
		return self._internals.createWidget( util.extend( def ){ skin = skinName }, self._ui, self )
	else
		return self._internals.createWidget( { skin = skinName }, self._ui, self )
	end
end

function mui_screen:addWidget( widget )
	table.insert( self._widgets, widget )
	widget:attach( self, self._root )
end

function mui_screen:removeWidget( widget )
	array.removeElement( self._widgets, widget )
	widget:detach( self._root )
end

function mui_screen:reorderWidget( widget, newIdx )
	assert( array.find( self._widgets, widget ) ~= nil )
	array.removeElement( self._widgets, widget )
	if newIdx then
		assert( #self._widgets + 1 >= newIdx )
		table.insert( self._widgets, newIdx, widget )
	else
		table.insert( self._widgets, widget )
	end
	self:refreshPriority()
end

function mui_screen:findWidget( name )
	local found = nil
	for i,widget in ipairs(self._widgets) do
		found = widget:findWidget( name )
		if found then
			break
		end
	end
	
	return found
end

function mui_screen:registerProp( prop, widget )
	assert(widget)
	self._propToWidget[ prop ] = widget
	self._layer:insertProp( prop )
end

function mui_screen:unregisterProp( prop )	
	assert( self._propToWidget[ prop ], prop:getDebugName() )	
	self._propToWidget[ prop ] = nil
	self._layer:removeProp( prop )
end

function mui_screen:refreshPriority()
	local priority = 0
	for i,widget in ipairs(self._widgets) do
		priority = widget:updatePriority( priority + 1 )
	end
end

function mui_screen:handlesInput()
    -- We handle input only if active and not currently transitioning out.
	if not self:isActive() then
        return false
    end
    if self._props.deactivateTransition ~= nil and self:hasTransition( self._props.deactivateTransition, MOAITimer.NORMAL ) then
        return false -- Currently engaging deactivation.
    end
    if self._props.activateTransition and self:hasTransition( self._props.activateTransition, MOAITimer.REVERSE ) then
        return false -- Currently cancelling activation.
    end
    return true
end

function mui_screen:handleInputEvent( ev ) 
    if self.onInputEvent and self.onInputEvent( ev ) then
        return true
    end

	local props = self._layer:propListForPoint(ev.x, ev.y, 0, MOAILayer.SORT_PRIORITY_DESCENDING)

	local tooltip = nil
	if props then
		for i,prop in ipairs(props) do
			if prop:shouldDraw() and self._propToWidget[ prop ] then
				local tooltipWidget = self._propToWidget[ prop ]._widget
				tooltip = tooltipWidget:handleTooltip( ev.x, ev.y )
				if tooltip ~= nil then
                    if type(tooltip) == "boolean" then
                        tooltip = nil
                    end
					break
				end
			end
		end
	end

	local handled = false
	if self:isEnabled() then 
		local focusWidget = self:getInputLock()
		if focusWidget then
			handled = focusWidget:handleInputEvent( ev )
			if not handled then
				focusWidget = nil
			end
		end

		if mui_util.isMouseEvent( ev ) then
			if not handled then
				-- Cannot re-use the props list acquired earlier, since if any widget has since handled the event and triggered
				-- changes in the prop structure, the list may no longer be valid.
				props = self._layer:propListForPoint(ev.x, ev.y, 0, MOAILayer.SORT_PRIORITY_DESCENDING)

				if props then
					for i,prop in ipairs(props) do
						if prop:shouldDraw() then
							local candidate = self._propToWidget[ prop ]
							ev.prop = prop
							handled = candidate ~= nil and candidate:handleInputEvent( ev )
							if handled then
								focusWidget = candidate
								break
							end
						end
					end
				end
			end

			if focusWidget ~= self._focusWidget then
				--log:write( "FOCUS: %s -> %s", tostring(self._focusWidget), tostring(focusWidget) )
				self:dispatchEvent( { eventType = mui_defs.EVENT_FocusChanged, newFocus = focusWidget, oldFocus = self._focusWidget } )
				self._focusWidget = focusWidget
			end
			ev.prop = nil
		
		else
			handled = self:dispatchEvent( ev )
		end
	end
	
	if self._dragDropWidget then
		local wx, wy = inputmgr:getMouseXY()
		local tx, ty = self:wndToUI(wx + 16, wy + 16)
		self._dragDropWidget:setPosition( tx, ty )

		if ev.eventType == mui_defs.EVENT_MouseUp and ev.button == mui_defs.MB_Left then
			self:stopDragDrop()
		end
	end
	
	if tooltip == nil and self.onTooltip and self:handlesInput() then
		tooltip = util.callDelegate( self.onTooltip, self, ev.x, ev.y )
	end
	self:setTooltip( tooltip )

	return handled or self._props.sinksInput
end

function mui_screen:addEventHandler( handler, evType )
	
	if not self._handlers[evType] then
		self._handlers[evType] = {}
	end
	
	assert( not array.find( self._handlers[evType], handler ))
	table.insert( self._handlers[evType], handler )
end

function mui_screen:removeEventHandler( handler, evType )
	if evType then
		if self._handlers[ evType ] then
			array.removeElement( self._handlers[ evType ], handler )
		end
	else
		for i,handlers in pairs( self._handlers ) do
			array.removeElement( handlers, handler )
		end
	end
end

function mui_screen:dispatchEvent( ev )
	assert( ev.eventType )

	if self._handlers[ev.eventType] then
		return self:dispatchEventTo( ev, self._handlers[ ev.eventType ] )
	end

	return false
end

function mui_screen:dispatchEventTo( ev, handlers )
	for i,handler in ipairs( handlers ) do
		if handler:handleEvent( ev ) then
			return true
		end
	end

	return false
end

function mui_screen:isActive()
	return self._layer ~= nil
end

function mui_screen:onResize( width, height )

	self._width, self._height = width, height

	self._viewport:setSize ( width, height )
	self._viewport:setScale( width, height )

	self._camera:setScl( 1/width, 1/height )
	self._camera:forceUpdate()
	
	self:dispatchEvent( { eventType = mui_defs.EVENT_OnResize, screen = self } )
end

function mui_screen:onLostTopmost()
	self:dispatchEvent( { eventType = mui_defs.EVENT_FocusChanged, newFocus = nil, oldFocus = self._focusWidget } )
	self._focusWidget = nil

	self:dispatchEventTo( { eventType = mui_defs.EVENT_OnLostLock }, self._lockWidgets )
	assert( #self._lockWidgets == 0 )
end

function mui_screen:onActivate( width, height )
	assert( self._layer == nil )

	self._width, self._height = width, height

	local viewport = MOAIViewport.new ()
	viewport:setSize ( width, height )
	viewport:setScale( width, height )
	self._viewport = viewport

	local layer = MOAILayer2D.new ()
	layer:setDebugName( tostring(self._filename) )
	layer:setViewport ( viewport )

	local camera = MOAICamera2D.new()
	camera:setScl( 1/(width), 1/(height) )
	camera:setLoc( 0.5, 0.5 )
	camera:forceUpdate()
	layer:setCamera( camera )
	self._camera = camera
	
	self._layer = layer
	if not self._priority then
		self._priority = ACTIVE_PRIORITY
		ACTIVE_PRIORITY = ACTIVE_PRIORITY + 1
	end

	for _,widget in pairs(self._widgets) do
		widget:onActivate( self )
	end

	self:refreshPriority()
end

function mui_screen:onDeactivate()
	assert( self._layer, self._filename )

	self._priority = nil
	self._width, self._height = nil, nil

	for _,widget in pairs(self._widgets) do
		widget:onDeactivate( self )
	end

    for evType, handlers in ipairs(self._handlers) do
        assert( #handlers == 0, self._filename..","..evType )
    end

    self._focusWidget = nil
	self._layer = nil
end

function mui_screen:lockInput( widget )
	assert(not array.find( self._lockWidgets, widget ), self._filename )
	table.insert( self._lockWidgets, widget )
	self:addEventHandler( widget, mui_defs.EVENT_OnLostLock )
end

function mui_screen:unlockInput( widget )
	array.removeElement( self._lockWidgets, widget )
	self:removeEventHandler( widget, mui_defs.EVENT_OnLostLock )
end

function mui_screen:getInputLock()
	if #self._lockWidgets == 0 then
		return nil
	else
		return self._lockWidgets[ #self._lockWidgets ]
	end
end

function mui_screen:getDragDrop()
	return self._dragDropData
end

function mui_screen:startDragDrop( userData, template )
	assert( userData )
	assert( self._dragDropWidget == nil )

	self._dragDropData = userData

	if template then
		local wx, wy = inputmgr:getMouseXY()
		local tx, ty = self:wndToUI(wx + 16, wy + 16)

		self._dragDropWidget = self:createFromSkin( template )
		self._dragDropWidget:onActivate( self )
		self._dragDropWidget:setPosition( tx, ty )
		self._dragDropWidget:updatePriority( TOOLTIP_PRIORITY )
	end

	self:dispatchEvent( { eventType = mui_defs.EVENT_DragStart, dragData = userData } )

	return self._dragDropWidget
end

function mui_screen:stopDragDrop()
	self._dragDropData = nil
	self._dragDropWidget:onDeactivate( self )
	self._dragDropWidget = nil
	self:dispatchEvent( { eventType = mui_defs.EVENT_DragDrop, dragData = nil } )
end

function mui_screen:getResolution()
	return self._internals:getResolution()
end

return mui_screen

----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

module ( "inputmgr", package.seeall )
local metrics = include( "metrics" )
local mui_defs = include("mui/mui_defs")
local mui = include("mui/mui")
local array = include("modules/array")
local util = include("modules/util")

local _M =
{
	_listeners = {},
	_listenersTmp = {},
	_keysDown = {},
	_event = {},

	-- Current mouse window coordinates.  Initialize offscreen.
	_mouseX = -1,
	_mouseY = -1,
	_inputEnabled = true,
}

----------------------------------------------------------------
----------------------------------------------------------------
-- variables
----------------------------------------------------------------

local function createInputEvent( eventType, event )
	local event = event or _M._event
	util.tclear( event )
	event.eventType = eventType
	event.wx, event.wy = _M._mouseX, _M._mouseY
	event.controlDown = _M._keysDown[mui_defs.K_CONTROL]
	event.shiftDown = _M._keysDown[mui_defs.K_SHIFT]
	event.altDown = _M._keysDown[mui_defs.K_ALT]

	return event
end

function setInputEnabled( enabled )
	_M._inputEnabled = enabled
end

local function notifyListeners( event )
	metrics.app_metrics:trackActivity()

	if not _M._inputEnabled then return end


	util.tclear( _M._listenersTmp )
	local tmp = util.tmerge( _M._listenersTmp, _M._listeners )
	for i,v in pairs(tmp) do
		local result = v:onInputEvent( event )
		if result then
			return result
		end
	end
	
	return nil
end

function addListener( listener, idx )
	assert( array.find(_M._listeners, listener) == nil )
	assert( type(listener.onInputEvent) == "function" )

	table.insert( _M._listeners, idx or #_M._listeners + 1, listener )
end

function removeListener( listener )
	assert( array.find(_M._listeners, listener) ~= nil )
	
	array.removeElement( _M._listeners, listener )
end

local function onKeyboard( key, down, keychar )

	local ev
    if key == 0 then
		ev = createInputEvent( mui_defs.EVENT_KeyChar )
		ev.key = nil
		ev.keychar = keychar
        
	elseif down == true then
        if _M._keysDown[key] then
		    ev = createInputEvent( mui_defs.EVENT_KeyRepeat )
		    ev.key = key
        else
		    _M._keysDown[key] = true
		    ev = createInputEvent( mui_defs.EVENT_KeyDown )
		    ev.key = key
        end
	else
		ev = createInputEvent( mui_defs.EVENT_KeyUp )
		ev.key = key
		_M._keysDown[key] = nil -- Ensure this is after creating the event, so that the event has the modifier tags.
	end

	notifyListeners( ev )
end

local function onMouseWheel( delta )
	local ev = createInputEvent( mui_defs.EVENT_MouseWheel )
	ev.delta = delta

	notifyListeners( ev )
end

local function onMouseMove( x, y )
	_M._mouseX, _M._mouseY = x, y

	local ev = createInputEvent( mui_defs.EVENT_MouseMove )
	notifyListeners( ev )
end

local function onMouseLeft( down )
	local ev
	if down then
		ev = createInputEvent( mui_defs.EVENT_MouseDown )
		ev.button = mui_defs.MB_Left
	else
		ev = createInputEvent( mui_defs.EVENT_MouseUp )
		ev.button = mui_defs.MB_Left
	end

	notifyListeners( ev )
end


local function onMouseMiddle( down )

	local ev
	if down then
		ev = createInputEvent( mui_defs.EVENT_MouseDown )
		ev.button = mui_defs.MB_Middle
	else
		ev = createInputEvent( mui_defs.EVENT_MouseUp )
		ev.button = mui_defs.MB_Middle
	end
end

local function onMouseRight( down )

	local ev
	if down then
		ev = createInputEvent( mui_defs.EVENT_MouseDown )
		ev.button = mui_defs.MB_Right
	else
		ev = createInputEvent( mui_defs.EVENT_MouseUp )
		ev.button = mui_defs.MB_Right
	end

	notifyListeners( ev )
end

----------------------------------------------------------------
-- exposed functions
----------------------------------------------------------------

function getInputInternals()
	return _M -- For debugging access.
end

function getMouseXY()
	return _M._mouseX, _M._mouseY
end

function keyIsDown( key )
	return MOAIInputMgr.device.keyboard:keyIsDown( key )
end

function mouseIsDown( button )
	if button == mui_defs.MB_Left then
		return MOAIInputMgr.device.mouseLeft:isDown()
	elseif button == mui_defs.MB_Middle then
		return MOAIInputMgr.device.mouseMiddle:isDown()
	elseif button == mui_defs.MB_Right then
		return MOAIInputMgr.device.mouseRight:isDown()
	end
end

function init( )
	-- Register the callbacks for input
	MOAIInputMgr.device.keyboard:setCallback( onKeyboard )
	MOAIInputMgr.device.pointer:setCallback( onMouseMove )
	MOAIInputMgr.device.wheel:setCallback( onMouseWheel )
	MOAIInputMgr.device.mouseLeft:setCallback( onMouseLeft )
	MOAIInputMgr.device.mouseMiddle:setCallback( onMouseMiddle )	
	MOAIInputMgr.device.mouseRight:setCallback( onMouseRight )
end

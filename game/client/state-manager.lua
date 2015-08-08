----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

module ( "statemgr", package.seeall )

local util = include( "modules/util" )
local metrics = include( "metrics" )
local mui = include( "mui/mui" )

----------------------------------------------------------------
----------------------------------------------------------------
-- variables
----------------------------------------------------------------
local loadedStates = {}
local stateStack = {}

----------------------------------------------------------------
-- run loop
----------------------------------------------------------------
local updateThread = MOAICoroutine.new ()
local tmpStack = {}

----------------------------------------------------------------
-- local functions
----------------------------------------------------------------

local function event_error_handler( err )
	moai.traceback( "### ABORTING: FATAL SCRIPT ERROR ###\n" .. err )
	return err
end

local function updateFunction ()
	util.tclear( tmpStack )
	local activeStack = util.tmerge( tmpStack, stateStack)
	for k,v in pairs(activeStack) do
		if type ( v.onUpdate ) == "function" and util.indexOf(stateStack, v) ~= nil then
			v:onUpdate ()
		end
	end
		
	local st, tt, c = MOAISim.getDeviceTime(), nil, 0
	while not collectgarbage( "step" ) do
		tt = MOAISim.getDeviceTime()
		c = c + 1
		if tt - st > 0 then
			break
		end
	end

	--[[
	if tt and tt  - st > 1 / 1000 then
		print("GC took", (tt - st) * 1000, " ms", c )
	end
	--]]

	return true
end

local function mainLoop()

	collectgarbage( "stop" )

	while true do
		coroutine.yield ()

		local res, err = xpcall( updateFunction, event_error_handler )
		if not res then
			break
		end

		if MOAIEnvironment.QUIT then
			break
		end
	end

	shutdown()
end

----------------------------------------------------------------
-- functions
----------------------------------------------------------------
function begin ()
	
	metrics.app_metrics:sendLaunch()

	updateThread:run ( mainLoop  )
end

----------------------------------------------------------------

function deactivate( state )

	local idx = util.indexOf( stateStack, state )
	assert( idx ~= nil )

	local wasFocus = idx == #stateStack
	local state = table.remove( stateStack, idx )

	-- do the state's onLoseFocus
	if wasFocus and type ( state.onLoseFocus ) == "function" then
		state:onLoseFocus ()
	end
	
	-- do the state's onUnload
	if type ( state.onUnload ) == "function" then
		state:onUnload ()
	end
		
	-- do the new current state's onFocus
	if wasFocus and #stateStack > 0 and type ( stateStack[ #stateStack ].onFocus ) == "function" then
		stateStack[ #stateStack ]:onFocus ( state )
	end
	
end


----------------------------------------------------------------
function activateAtIndex( state, index, ... ) 
	assert( state ~= nil )
	assert( util.indexOf( stateStack, state ) == nil )

	if stateStack[index] ~= state then
		table.insert( stateStack, index, state )
	
		-- if state is newly topmost, notify the previous topmost state
		if index == #stateStack and index > 1 and type ( stateStack[ index - 1 ].onLoseFocus ) == "function" then
			stateStack[ index - 1 ]:onLoseFocus ( )
		end
	
		-- do the new state's onLoad
		state:onLoad( ... )

		-- notify the new state of topmost status, if applicable
		if index == #stateStack and type(state.onFocus) == "function" then
			state:onFocus()
		end

	else
		assert(false, "State already active at index " ..index)
	end
		
end

function activate( state, ... ) 
	activateAtIndex( state, #stateStack + 1, ... )
end

function isActive( state )
	return util.indexOf( stateStack, state ) ~= nil
end

function getStates()
    return stateStack
end

----------------------------------------------------------------
function shutdown ( )
	log:write( "### Shutting down..." )

	xpcall( function()
		while #stateStack > 0 do
			deactivate( stateStack[ #stateStack ] )
		end
	end, event_error_handler )

	local task = metrics.app_metrics:sendQuit()
	if task then
        log:write( "\tSending metrics..." )
		task:waitFinish()
	end

    log:write( "\tSaving settings..." )
	local settings = savefiles.getSettings("settings" )
    settings.data.gfx = util.extend( settings.data.gfx )( MOAISim.getGfxCurrentDisplayMode())
	settings:save()

    log:write( "\tStopping main coroutine..." )

	updateThread:stop ()
	MOAISim.shutdown()
end

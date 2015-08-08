----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

----------------------------------------------------------------
-- Level script

local level_events =
{
    EV_UI_INITIALIZED = 1,
	EV_UNIT_SELECTED = 2,
	EV_HUD_MAINFRAME_TOGGLE= 4,
	EV_HUD_CLICK_BUTTON = 6,
	EV_CLOSE_SHOP_UI = 8,
	EV_CLOSE_LOOT_UI = 9,
	EV_FINAL_ROOM_INTERRUPT = 10,
}

local script_hook = class()

function script_hook:init( script, name, hookFn, noSkip )
	self.script = script
	self.name = name
	self.noSkip = noSkip
	self.waitEvents = {}
	self.waitTriggers = {}
	self.hookFn = hookFn -- Merely for later identification
	self.thread = coroutine.create( hookFn )
end

function script_hook:addHook( hookFn, noSkip, ... )
    self.hookCount = (self.hookCount or 0) + 1
    local name = string.format( "%s [%d]", self.name, self.hookCount )
	return self.script:addHook( name, hookFn, noSkip, ... )
end

function script_hook:removeHook( hookFn )
	for i, hook in ipairs( self.script.hooks ) do
		if hook.hookFn == hookFn then
			self.script:removeHook( hook )
			break
		end
	end
end

function script_hook:removeAllHooks( exceptHook )
	if exceptHook then
		array.removeElement( self.script.hooks, exceptHook )
	end

	while #self.script.hooks > 0 do
		self.script:removeHook( self.script.hooks[1] )
	end

	if exceptHook then
		table.insert( self.script.hooks, exceptHook )
	end
end


function script_hook:queue( event )
	self.script:queue( event )
end

function script_hook:clearQueue( skip )
	self.script:clearQueue( skip )
end

function script_hook:checkpoint()
	self.script.sim:dispatchEvent( simdefs.EV_CHECKPOINT )

	local retryCount = self.script.sim:getTags().retries
	if retryCount > 0 then
		-- Retrying checkpoint, automatically insert a fadeIn event.
		self:queue( { type="fadeIn" } )
		self:waitFrames( 60 )
	end
	self.script.sim:getTags().retries = 0

	-- Return retryCount in case script cares to handle it as a special case.
	return retryCount
end

function script_hook:restore()
    self:queue( { type="restoreCheckpoint" } )
    -- Once a restore is pushed, lock any changes so it can't be undone inadvertantly.
    self.script.lockQueue = true
end

function script_hook:waitFrames( frameCount )
	-- This is a BLOCKING delay.
	assert( type(frameCount) == "number" )
	self.script.sim:dispatchEvent( simdefs.EV_WAIT_DELAY, frameCount )
end

function script_hook:waitFor( ... )
	-- Clear old waits.
	for triggerType, v in pairs( self.waitTriggers ) do
		self.script.sim:removeTrigger( triggerType, self )
	end
	self.waitEvents = { ... }
	self.waitTriggers = { }

	if #self.waitEvents > 0 then
		for _, waitEv in ipairs( self.waitEvents ) do
            if waitEv.action then
				self.waitTriggers[ simdefs.TRG_ACTION ] = waitEv.priority or 0

			elseif waitEv.trigger then
				self.waitTriggers[ waitEv.trigger ] = waitEv.priority or 0

			elseif waitEv.uiEvent then
				self.waitTriggers[ simdefs.TRG_UI_ACTION ] = waitEv.priority or 0

			else
				assert( false, util.stringize( waitEv ))
			end
		end

		-- Add hook as handler to requisite wait triggers (a post-step because we need to avoid dupes)
		for triggerType, priority in pairs( self.waitTriggers ) do
			local trigger = self.script.sim:addTrigger( triggerType, self )
            if priority ~= 0 then
                trigger.priority = priority
            end
		end

		-- When this hook is triggered by the UI event in question we will resume.
		return coroutine.yield()
	end
end

function script_hook:onTrigger( sim, triggerType, triggerData )
	--simlog( simdefs.LOG_TUTORIAL, "onTrigger( %d ) == %s", triggerType, util.stringize( triggerData, 1 ))
    local abort = nil
	for _, waitEv in ipairs( self.waitEvents ) do
		if triggerType == simdefs.TRG_ACTION then
			if (waitEv.action == triggerData.ClassType or waitEv.action == "") and waitEv.pre == triggerData.pre then
				if waitEv.fn == nil then
					abort = (self:resumeHook( waitEv, triggerData ) == false)
					break
				else
					local result = { waitEv.fn( sim, unpack(triggerData) ) }
					if result[1] then
						abort = (self:resumeHook( waitEv, unpack( result )) == false)
						break
					end
				end
			end
		
		elseif triggerType == simdefs.TRG_UI_ACTION and waitEv.uiEvent == triggerData.uiEvent then
			self:resumeHook( waitEv, triggerData.eventData )

		elseif triggerType == waitEv.trigger then
			if waitEv.fn == nil then
				abort = (self:resumeHook( waitEv, triggerData ) == false)
				break
			else
				local result = { waitEv.fn( sim, triggerData ) }
				if result[1] then
					abort = (self:resumeHook( waitEv, unpack( result )) == false)
					break
				end
			end
		end
	end
    if triggerData and abort then
        triggerData.abort = true -- It's up to the trigger source to handle what this means.
    end
end

function script_hook:resumeHook( ... )
	self:waitFor( nil )

	local args = { ... }
	local ok, result
	repeat
		ok, result = coroutine.resume( self.thread, unpack(args) )
		assert( ok, tostring(result) .. "\n" .. tostring(debug.traceback( self.thread ) ))

        if self.thread == nil then
            break -- Resuming actually caused us to be destroyed() already.

		elseif coroutine.status( self.thread ) == "dead" then
			self.script:removeHook( self )
            return result -- if result == false, the hook wants the sim to 'abort' whatever it is currently doing.
		
		elseif result then
			-- If there's a return value, it's a simevent simply needing to be dispatched from the main sim coroutine.
			args = { self.script.sim:dispatchEvent( result.eventType, result.eventData ) }
		end
	until not ok or result == nil
end

function script_hook:onScriptEvent( game, eventType, eventData )
	--simlog( simdefs.LOG_TUTORIAL, "onScriptEvent( %d ) == %s", eventType, util.stringize( eventData, 1 ))
	for i, waitEv in ipairs( self.waitEvents ) do
		if waitEv.uiEvent == eventType and (waitEv.fn == nil or waitEv.fn( self.script.sim, eventData )) then
			-- This is the UI event we're waiting for!  Encapsulate this in a trigger action, which will resume the hook.
			game:doAction( "triggerAction", simdefs.TRG_UI_ACTION, { uiEvent = eventType, eventData = eventData } )			
			break
		end
	end
end

function script_hook:destroy()
	self:waitFor()
	self.thread = nil
end

-----------------------------------------------------------------------------------------------
--

local script_mgr = class()

function script_mgr:init( sim )
	self.sim = sim
	self.hooks = {}
	self.scriptEvents = {}
	self.eventQueue = {}
	self.scripts = {}
end

function script_mgr:loadScript( filename, ... )
	local res, script = pcall( reinclude, filename )
	if res then
		table.insert( self.scripts, script( self, self.sim, ... ))
	else
		simlog( "LEVEL SCRIPT: '%s'\n%s", filename, script )
	end
end

function script_mgr:destroy()
	self.scripts = nil
	self:clearSpeech()
	while #self.hooks > 0 do
		self:removeHook( self.hooks[1] )
	end
end

function script_mgr:queue( event )
    if self.lockQueue then
        return
    end
    assert( event )
    table.insert( self.eventQueue, event )
end

function script_mgr:clearQueue( skip )
    if self.lockQueue then
        return
    end

    util.tclear( self.eventQueue )
    if skip then
        -- In addition to clearing the queue, this skips/aborts whatever is currently being processed.
        self.sim:dispatchEvent( simdefs.EV_CLEAR_QUEUE )
    end
end

function script_mgr:getQueue()
	return self.eventQueue
end

function script_mgr:queueScriptEvent( eventType, eventData )
	assert( eventType )
	table.insert( self.scriptEvents, eventType )
	table.insert( self.scriptEvents, eventData or false ) -- false is just a dummy value so that this remains an array without nil entries
end

function script_mgr:dispatchScriptEvents( game )
	assert( not game:isReplaying() )

	while #self.scriptEvents > 0 do
		local eventType = table.remove( self.scriptEvents, 1 )
		local eventData = table.remove( self.scriptEvents, 1 )
		for _, hook in ipairs( self.hooks ) do
			hook:onScriptEvent( game, eventType, eventData )
		end
	end
end

function script_mgr:addHook( name, hookFn, noSkip, ... )
	local hook = script_hook( self, name, hookFn, noSkip )
	table.insert( self.hooks, hook )
	hook:resumeHook( hook, self.sim, ... )
    return hook
end

function script_mgr:removeHook( hook )
	hook:destroy()
	array.removeElement( self.hooks, hook )
end

----------------------------------------------------------------
-- Level loader

local function loadLevel( params )
	
	local filename = "sim/"..params.levelFile
	local lvldata = include( filename )
	assert(lvldata)
	package.loaded[ filename ] = nil -- Do not cache this lua file.

	if lvldata.onLoad then
		lvldata:onLoad( params )
	end

	return lvldata
end

return util.extend( level_events )
{
	script_hook = script_hook,
	script_mgr = script_mgr,
	loadLevel = loadLevel,
}

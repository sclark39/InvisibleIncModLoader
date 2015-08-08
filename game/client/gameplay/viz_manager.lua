----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local cdefs = include( "client_defs" )
local array = include( "modules/array" )
local mathutil = include( "modules/mathutil" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local agentrig = include( "gameplay/agentrig" )
local viz_thread = include( "gameplay/viz_thread" )
local rig_util = include( "gameplay/rig_util" )

local function defaultHandler( thread, ev )
	local viz = thread.viz
	-- HUD needs first shot at events, because it handles switching mainframe mode.
	local result = viz.game.hud:onSimEvent( ev )
	viz.game.boardRig:onSimEvent( ev, ev.eventType, ev.eventData )
end


local function PlaySoundSequence(seq, pause)

    if not MOAIFmodDesigner.isPlaying( "seqSound" ) then
        local coro = MOAICoroutine.new()
        coro:run( function() 


            for k,v in ipairs(seq) do
                MOAIFmodDesigner.playSound(v, "seqSound")
                while MOAIFmodDesigner.isPlaying( "seqSound" ) do
                    coroutine.yield()
                end
                if pause then
                    rig_util.wait( pause * cdefs.SECONDS)
                end
            end
        end)
    end
end

---------------------------------------------------------------------------
-- Viz manager.  Coordinates visualization upon handling events from the sim.

local EVENT_MAP = {}

EVENT_MAP[ simdefs.EV_PLAY_SOUND ] = function( viz, eventData )	
	if eventData.x then
		MOAIFmodDesigner.playSound( eventData.sound, nil, nil, {eventData.x,eventData.y,0}, nil )
	else
		MOAIFmodDesigner.playSound( eventData )
	end
	return false
end

EVENT_MAP[ simdefs.EV_UNIT_FLOAT_TXT ] = function( viz, eventData )
	local x0,y0 = eventData.x, eventData.y
	if eventData.unit and not x0 and not y0 then
		x0, y0 = eventData.unit:getLocation()
	end
	if eventData.skipQue then
		viz.game.boardRig:showFloatText( x0, y0, eventData.txt,  eventData.color, eventData.sound, eventData.alwaysShow )
	else
		viz.game.boardRig:queFloatText( x0, y0, eventData.txt, eventData.color, eventData.sound , eventData.target, eventData.alwaysShow)
	end
end

EVENT_MAP[ simdefs.EV_UNIT_ENGAGED ] = function( viz, eventData )
	local unit = eventData
	local x0,y0 = unit:getLocation()
	MOAIFmodDesigner.playSound("SpySociety/Actions/guard/guard_alerted", nil, nil, {x0,y0,0} )
    if unit:getSounds().alert then
	    MOAIFmodDesigner.playSound(unit:getSounds().alert, nil, nil, {x0,y0, 0} )
    end
end

EVENT_MAP[ simdefs.EV_HUD_MPUSED ] = function( viz, eventData )
	local rig = viz.game.boardRig:getUnitRig( eventData:getID() )
	if rig then
		rig:refreshHUD( eventData )
	end
	viz.game.hud._home_panel:refreshAgent( eventData )
end

EVENT_MAP[ simdefs.EV_CAM_PAN ] = function( viz, eventData )
	viz.game:cameraPanToCell( eventData[1], eventData[2] )
end

EVENT_MAP[ simdefs.EV_DAEMON_TUTORIAL ] = function( viz, eventData )
    viz.game.hud:explainDaemons()
end


EVENT_MAP[ simdefs.EV_SHOW_WARNING ] = function( viz, eventData )
	if eventData.sound then
		MOAIFmodDesigner.playSound( eventData.sound )
	end
	if eventData.speech then
		MOAIFmodDesigner.playSound( eventData.speech )
	end	
	viz.game.hud:queueWarning( eventData.txt, eventData.color, nil, nil, eventData.mainframe, eventData.icon )
end
--[[
EVENT_MAP[ simdefs.EV_BLINK_REWIND ] = function ( viz, eventData )
	local blink_rewind = include( "gameplay/viz_handlers/blink_rewind" )
	viz:addThread( blink_rewind( viz.game.hud, viz ) )
end
]]
EVENT_MAP[ simdefs.EV_SHOW_MODAL_REWIND ] = function ( viz, eventData )
	local settings = savefiles.getSettings( "settings" )
    local sim = viz.game.simCore

    if sim:getTags().rewindsLeft > 0 then    	

        if sim:getPC():isNeutralized( sim ) then
            local modal_thread = include( "gameplay/modal_thread" )
            local modalThread = modal_thread.rewindSuggestDialog( viz, viz.game.hud, sim:getTags().rewindsLeft )
            viz:addThread( modalThread )

	    else
			local shouldShow = viz:checkShouldShow("modal-rewind-tutorial")
			if shouldShow then		
	            local modal_thread = include( "gameplay/modal_thread" )
	            local modalThread = modal_thread.rewindDialog( viz, viz.game.hud )
	            viz:addThread( modalThread )
	    	end
	    end
    end
end

EVENT_MAP[ simdefs.EV_SHOW_ALARM ] = function( viz, eventData )
	if not viz.game.debugStep then
		if eventData.speech then
			if type(eventData.speech) == "string" then
                MOAIFmodDesigner.playSound( eventData.speech )
            end

            if type(eventData.speech) == "table" then
                PlaySoundSequence(eventData.speech)
            end
		end
        local modal_thread = include( "gameplay/modal_thread" )
        viz:addThread( modal_thread.alarmDialog( viz, eventData.txt, eventData.txt2, eventData.stage ) )
	end
end

EVENT_MAP[ simdefs.EV_SHOW_COOLDOWN ] = function( viz, eventData )
    if not viz.game.debugStep then
    	local shouldShow = viz:checkShouldShow("modal-cooldown")
	    	if shouldShow then
			MOAIFmodDesigner.playSound( eventData.sound or "SpySociety/HUD/menu/popup" )
	        local modal_thread = include( "gameplay/modal_thread" )
	        viz:addThread( modal_thread.cooldownDialog( viz ) )
    	end
	end
end

EVENT_MAP[ simdefs.EV_SHOW_DAEMON ] = function( viz, eventData )
    if not viz.game.debugStep then
		if eventData.showMainframe then
			viz.game.hud:showMainframe()
		end
		
    	MOAIFmodDesigner.playSound( "SpySociety/HUD/voice/level1/alarmvoice_daemon" )
        local modal_thread = include( "gameplay/modal_thread" )
        viz:addThread( modal_thread.daemonDialog( viz, eventData.name, eventData.txt, eventData.icon ) )
	end
end

EVENT_MAP[ simdefs.EV_SHOW_REVERSE_DAEMON ] = function( viz, eventData )
    if not viz.game.debugStep then
    	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/daemon_reversal" )
        local modal_thread = include( "gameplay/modal_thread" )
        viz:addThread( modal_thread.reverseDaemonDialog( viz, eventData.name, eventData.txt, eventData.icon, eventData.title ) )
	end
end

EVENT_MAP[ simdefs.EV_SHOW_DIALOG ] = function( viz, eventData )
	if not viz.game.debugStep then

		local shouldShow = viz:checkShouldShow(eventData.showOnce)
		if not shouldShow then
			return
		end

        MOAIFmodDesigner.playSound( eventData.sound or "SpySociety/HUD/menu/popup" )
		if eventData.speech then
			MOAIFmodDesigner.playSound( eventData.speech )
		end
        local modal_thread = include( "gameplay/modal_thread" )
        local dialog = modal_thread[ eventData.dialog or "generalDialog" ]( viz, unpack( eventData.dialogParams ))
        viz:addThread( dialog )
	end	
end


EVENT_MAP[ simdefs.EV_REFRESH_OBJECTIVES ] = function( viz, eventData )
	viz.game.hud:refreshObjectives()
end

EVENT_MAP[ simdefs.EV_UNIT_ALERTED ] = function( viz, eventData )

	local rig = viz.game.boardRig:getUnitRig( eventData.unitID )
	if rig and rig.onUnitAlerted then
		rig:onUnitAlerted( viz, eventData )
	end
end

EVENT_MAP[ simdefs.EV_UNIT_REFRESH_TRACKS ] = function( viz, eventData )
	viz.game.boardRig:getPathRig():refreshTracks( eventData )
end

EVENT_MAP[ simdefs.EV_ACHIEVEMENT ] = function( viz, eventData )
    savefiles.winAchievement( eventData )
end

---------------------------------------------------------------------------
-- Viz manager.  Coordinates visualization upon handling events from the sim.

local viz_manager = class()

viz_manager.viz_thread = viz_thread

function viz_manager:init( game )
	self.game = game
	self.threads = {}
    self.locks = {}
	self.eventMap = {}
    self.tmpHandlers = {}
	self.eventCounter = {}
	for eventType, v in pairs(EVENT_MAP) do
		self.eventMap[ eventType ] = { v }
	end
end

function viz_manager:checkShouldShow(showOnce)
	local shouldShow = true
	if showOnce then
		local settings = savefiles.getSettings( "settings" )
		settings.data.seenOnce = settings.data.seenOnce or {}
		if settings.data.seenOnce[ showOnce ] then
			shouldShow = false
		else
			settings.data.seenOnce[ showOnce ] = true
			settings:save()
		end
	end
	return shouldShow
end


function viz_manager:registerHandler( eventType, handler )
	assert( type(handler) == "function" or handler.processViz ~= nil )

	if self.eventMap[ eventType ] == nil then
		self.eventMap[ eventType ] = {}
	end

	table.insert( self.eventMap[ eventType ], handler )
end

function viz_manager:unregisterHandler( eventType, handler )
    assert( not self.processing )
	array.removeElement( self.eventMap[ eventType ], handler )
end

function viz_manager:destroy()
	while #self.threads > 0 do
		self:removeThread( self.threads[1] )
	end
end

function viz_manager:removeThread( thread )
    assert( not self.processing )
	array.removeElement( self.threads, thread )
	for eventType, handlers in pairs( self.eventMap ) do
		if array.find( handlers, thread ) then
			array.removeElement( handlers, thread )
		end
	end
    thread:onStop()
    self:releaseLocks( thread )
end

function viz_manager:addThread( thread )
    assert( thread )
    assert( array.find( self.threads, thread ) == nil )
	table.insert( self.threads, thread )
end

function viz_manager:spawnViz( fn, ev )
    local closure = function(...)
        local zz = KLEIProfiler.Push( "ev" .. tostring(ev and ev.eventType) )
        fn(...)
        KLEIProfiler.Pop(zz)
    end

	local thread = viz_thread( self, closure )
	self:registerHandler( simdefs.EV_FRAME_UPDATE, thread )
	thread:processViz( ev )
	self:addThread( thread )
	return thread
end

function viz_manager:acquireLocks( thread, ... )
    -- No other thread can exist that has the same tag(s) as lockThread does.
    for j = 1, select( "#", ... ) do
        local tag = select( j, ... )
        if self.locks[ tag ] ~= nil and self.locks[ tag ] ~= thread then
            return false
        end
    end

    -- OK.
    for j = 1, select( "#", ... ) do
        local tag = select( j, ... )
        self.locks[ tag ] = thread
    end

    return true
end

function viz_manager:releaseLocks( thread )
    for tag, t in pairs( self.locks ) do
        if t == thread then
            self.locks[ tag ] = nil
        end
    end
end

function viz_manager:isBusy()
    return #self.threads > 0
end

function viz_manager:processViz( ev )
	assert( ev )

	-- Simply to allow handlers to easily access the viz subsystem.
	ev.viz = self

	self.eventCounter[ ev.eventType ] = (self.eventCounter[ ev.eventType ] or 0) + 1

	local handlers = self.eventMap[ ev.eventType ]
	if handlers then
        util.tclear( self.tmpHandlers )
        util.tmerge( self.tmpHandlers, handlers )
        for i, handler in ipairs( self.tmpHandlers ) do
            if array.find( handlers, handler ) ~= nil then -- Ensure handler hasn't been removed DURING processing.
			    if type(handler) == "function" then
				    handler( self, ev.eventData )
			    else
				    handler:processViz( ev.eventData )
			    end
            end
		end

	elseif ev.eventType ~= simdefs.EV_FRAME_UPDATE then
		-- defaultHandler could be removed if all handled events are added to the eventMap.
		self:spawnViz( defaultHandler, ev )
	end

	local isBlocking = false
	local i = 1
	while i <= #self.threads do
		local thread = self.threads[i]
		if not thread:isRunning() then
			self:removeThread( thread )
		else
			i = i + 1
			isBlocking = isBlocking or thread:isBlocking()
		end
	end
	-- Can't clear viz because the event might perseist as a parallel co-routine after this event completes 
	--ev.viz = nil -- Remove ref. 

	return not isBlocking
end

function viz_manager:print()
	for i, thread in ipairs(self.threads) do
		log:write( "%d]\n%s", i, debug.traceback( thread.thread ))
	end
end

return viz_manager
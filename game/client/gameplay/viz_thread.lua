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

---------------------------------------------------------------------------
-- Local shit

local viz_thread = class()

function viz_thread:init( viz, fn )
	assert( fn )
	self.thread = coroutine.create( fn )
	self.viz = viz
	self.blocking = true

	debug.sethook( self.thread,
		function()
			error( "INFINITE LOOP DETECTED" )
		end, "", 1000000000 ) -- 1 billion instructions is... too
end

function viz_thread:onStop()
    -- cleanup.
    self.thread = nil
end

function viz_thread:isRunning()
	if coroutine.status( self.thread ) == "dead" then
        return false
    end
    if self.conditionFn and not self.conditionFn() then
        return false
    end

    return true
end

function viz_thread:block()
	self.blocking = true
end

function viz_thread:unblock( conditionFn )
	self.blocking = false
    self.conditionFn = conditionFn
end

function viz_thread:waitForLocks( ... )
    while not self.viz:acquireLocks( self, ... ) do
        coroutine.yield()
    end
end

function viz_thread:waitFrames( frames )
    while frames > 0 do
        coroutine.yield()
        frames = frames - 1
    end
end

function viz_thread:isBlocking()
	return self.blocking
end

function viz_thread:processViz( ev )
	if ev then
		ev.thread = self
        self.ev = ev
	end
	local ok, err = coroutine.resume( self.thread, self, ev )
	if not ok then
		-- val will contain the error message if result is false
		moai.traceback( "Viz traceback:\n".. tostring(err), self.thread )
        if self.viz.game.simThread then
		    moai.traceback( "Event source:\n"..tostring(err), self.viz.game.simThread )
        end
	end
end

return viz_thread

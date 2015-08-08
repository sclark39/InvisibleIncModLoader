----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local simevents = class()


function simevents:init( sim )
	self.sim = sim
	self.currentEvent = nil
	self.thread = nil -- sim coroutine if applicable
end

function simevents:queueEvent( evType, evData, noSkip )
	if self.thread then
		self.currentEvent = { eventType = evType, eventData = evData, noSkip = noSkip }
		coroutine.yield( self.currentEvent )
		self.currentEvent = nil
	end
end

function simevents:setThread( thread )
	self.thread = thread
end

function simevents:getCurrentEvent()
	return self.currentEvent
end

return simevents

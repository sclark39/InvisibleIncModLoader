----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local viz_thread = include( "gameplay/viz_thread" )
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local util = include( "client_util" )
local rig_util = include( "gameplay/rig_util" )
local world_hud = include( "hud/hud-inworld" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )

---------------------------------------------------------------

local breakIceThread = class()

function breakIceThread:init( mainframePanel, widget, unit )
	self.widget = widget
	self.unit = unit
	self.mainframePanel = mainframePanel
	self.currentIce = unit:getTraits().mainframe_ice

	self.thread = MOAICoroutine.new()
	self.thread:run( self.run, self )
end

function breakIceThread:destroy()
    self.thread:stop()
	self.thread = nil

	self.widget.iceBreak = nil
end

function breakIceThread:breakIce()
	local delta = self.unit:getTraits().mainframe_ice - self.currentIce
	if delta == 0 then
		return false
	end
	local anim = self.widget.binder.anim:getProp()

    if (self.mainframePanel.lastBreakIceTime or 0) + 0.5 < os.clock() then
        if delta > 0 then
    	    MOAIFmodDesigner.playSound("SpySociety/HUD/mainframe/firewall_increase")
        else
    	    MOAIFmodDesigner.playSound("SpySociety/HUD/mainframe/ice_deactivate")
        end
        -- Greatest.. hack... ever.
        -- Prevent duplicate sound plays in the event of multiple breakIce threads.
        self.mainframePanel.lastBreakIceTime = os.clock() 
    end

	if delta > 0 then
		self.currentIce = self.currentIce + 1
		self.widget.binder.btn:setText( self.currentIce )
		rig_util.waitForAnim( anim, "in" )
	else
		self.currentIce = self.currentIce  - 1
		self.widget.binder.btn:setText( self.currentIce )
		rig_util.waitForAnim( anim, "out" )
	end

	return true
end

function breakIceThread:run()
	while self.unit:isValid() and self:breakIce() do
		-- Continue breaking ice...
		coroutine.yield()
	end

	if self.currentIce <= 0 then
		self.mainframePanel._hud._world_hud:destroyWidget( world_hud.MAINFRAME, self.widget )
	else
		self:destroy()
        self.mainframePanel:refreshBreakIceButton( self.widget, self.unit )
	end
end

return breakIceThread

----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local client_util = include( "client_util" )
local util = include("modules/util")
local simdefs = include( "sim/simdefs" )

include( "class" )

----------------------------------------------------------------
-- Local functions

local MODE_PAUSE = 0
local MODE_PLAY = 1

local function getCurrentGame()
    local states = statemgr.getStates()
    for i = 1, #states do
        if states[i].simCore and states[i].levelData then
            return states[i] -- If it acts like a duck and quacks like a duck...
        end
    end
end

local function onClickRewind( panel )
    local game = getCurrentGame()
    if game then
	    game:stepBack()
	    panel:clearEvents()
	    panel:updatePanel()
    end
end

local function onClickFF( panel )
    local game = getCurrentGame()
    if game then
	    game:step()
	    panel:updatePanel()
    end
end

local function onClickReset( panel )
	-- Keep only the first (deploy) action
    local game = getCurrentGame()
    if game then
	    game:goto( 1 )
	    panel:clearEvents()
	    game.simHistory = { game.simHistory[1] }
    end
end

local function onClickPlayPause( panel )
    local game = getCurrentGame()
    if game then
	    if game.debugStep ~= nil then
		    game.debugStep = nil
	    else
		    game.debugStep = true
	    end
	    panel:updatePanel()
    end
end

local function onClickEventUp( panel )
	panel:changeFocusEvent(1)
	panel:updatePanel()	
end

local function onClickEventDwn( panel )
	panel:changeFocusEvent(-1)
	panel:updatePanel()	
end


local function onSliderStart( panel, slider, value )
end

local function onSliderStop( panel, slider, value )
    local game = getCurrentGame()
    if game then
	    local idx = math.floor(value)
	    if idx ~= game.simHistoryIdx then
		    game.debugStep = true
		    game:goto( idx )
		    panel:clearEvents()
	    end
    end
end

local function onSliderChanged( panel, slider, value )
    local game = getCurrentGame()
    if game then
	    local idx = math.floor(value)
	    local action = game.simHistory[ idx ]
	    local str = string.format( "%d/%d", idx, #game.simHistory )

	    if action and action.playerIndex then
		    str = str .. string.format( " (P%d - %s)", action.playerIndex, action.name )
	    end

	    panel:clearEvents()
	    panel._panel.binder.replayTxt:setText( str )
    end
end

local function onConditionalStepChanged( str )
    local game = getCurrentGame()
    if game then
        game:setDebugConditional( str )
    end
end

----------------------------------------------------------------
-- Interface functions

local replay_panel = class()

function replay_panel:init( screen )
	self._events = {}
	self._focusEvent = 1

    local panel = screen.binder.replayPanel
	panel.binder.rewindBtn.onClick = client_util.makeDelegate( nil, onClickRewind, self )
	panel.binder.ffBtn.onClick = client_util.makeDelegate( nil, onClickFF, self )
	panel.binder.playBtn.onClick = client_util.makeDelegate( nil, onClickPlayPause, self )
	panel.binder.resetBtn.onClick = client_util.makeDelegate( nil, onClickReset, self )
	panel.binder.slider:setRange( 0, 0 )
	panel.binder.slider:setStep( 1 )
	panel.binder.slider.onValueChanged = client_util.makeDelegate( nil, onSliderChanged, self )
	panel.binder.slider.onSliderStart = client_util.makeDelegate( nil, onSliderStart, self )
	panel.binder.slider.onSliderStop = client_util.makeDelegate( nil, onSliderStop, self )
	panel.binder.eventUpBtn.onClick = client_util.makeDelegate( nil, onClickEventUp, self )
	panel.binder.eventDwnBtn.onClick = client_util.makeDelegate( nil, onClickEventDwn, self )
    panel.binder.stepCmb:clearItems()
    panel.binder.stepCmb.onTextChanged = onConditionalStepChanged
    self._panel = panel

    self:setVisible( true )
	self:updatePanel()
end

function replay_panel:updateConditionCombo()
    local panel = self._panel       
    local prevCondition = panel.binder.stepCmb:getText()
    if #prevCondition <= 0 then
        prevCondition = "Step 1"
    end
    panel.binder.stepCmb:clearItems()
    
    local game = getCurrentGame()
    if game then
        for name, fn in pairs( game:getDebugConditionals() ) do
            panel.binder.stepCmb:addItem( name )
        end
        panel.binder.stepCmb:sortItems()
        for i = 1, panel.binder.stepCmb:getItemCount() do
            if panel.binder.stepCmb:getItem( i ) == prevCondition then
                panel.binder.stepCmb:selectIndex( i ) -- this should be default
                break
            end
        end
    end
end

function replay_panel:updatePanel()
    local game = getCurrentGame()
    if game then
        self:updateConditionCombo()

	    self._panel.binder.slider:setRange( 0, #game.simHistory )
	    if not self._panel.binder.slider:isSliding() then
		    self._panel.binder.slider:setValue( game.simHistoryIdx )
	    end

	    local str = string.format( "%d/%d", game.simHistoryIdx, #game.simHistory )
	
	    if game.simThread then
		    local t = debug.getinfo( game.simThread, 3 )
		    if t == nil then
			    str = str .. " PLAYING"
		    else
			    local line = string.format( " %s:%d: %s", t.short_src, t.currentline, tostring(t.name))
			    str = str .. line
		    end
	    end

	    if game.debugStep ~= nil then
		    self._panel.binder.playBtn:setText( ">" )
		    if #self._events > 0 then
			    local events = {}
			    local maxEventsToDisplay = 20
			    for i = math.min(self._focusEvent, #self._events), math.max(self._focusEvent-maxEventsToDisplay, 1), -1 do
				    local str = " "
				    if i == self._focusEvent then
					    str = ">"
				    end
				    str = str..tostring(i)..": "..util.debugPrintTableWithColours(self._events[i].debug, 2)
				    table.insert(events, str)
			    end
			    self._eventsTxt = table.concat(events, "\n")


			    local stack = {}
			    local focusEvent = self._events[self._focusEvent]
				if focusEvent then
					table.insert(stack, "<c:ffff00>")
					if type(focusEvent.debug.eventData) == "table" and focusEvent.debug.eventData.unit then
						table.insert(stack, string.format("[%s] ", tostring(focusEvent.debug.eventData.unit._id) ) )
					elseif type(focusEvent.debug.eventData) == "table" and focusEvent.debug.eventData.unitID then
						table.insert(stack, string.format("[%d] ", focusEvent.debug.eventData.unitID) )
					end
					table.insert(stack, focusEvent.debug.eventType)
					table.insert(stack, "</>\n")
					table.insert(stack, focusEvent.stack)
				end
				self._panel.binder.stackTxt:setText(table.concat(stack) )
		    else
			    self._eventsTxt = ""
			    self._panel.binder.stackTxt:setText("")
		    end
	    else
		    self._panel.binder.playBtn:setText( "||" )
		    self._panel.binder.stackTxt:setText("")
		    self._eventsTxt = ""
	    end

	    self._panel.binder.replayTxt:setText( str )
    end
end

function replay_panel:getEventsText()
    return self._eventsTxt
end

function replay_panel:addEvent(event, stack)
	--translate the event type
	local eventDebug = {eventType = simdefs:stringForEvent(event.eventType), eventData = event.eventData}
	table.insert(self._events, {debug=eventDebug, stack=stack} )
	self._focusEvent = #self._events
end

function replay_panel:changeFocusEvent(delta)
	self._focusEvent = math.min(#self._events, math.max(1, self._focusEvent+delta) )
end

function replay_panel:clearEvents()
	self._events = {}
	self:updatePanel()
end

function replay_panel:setVisible( isVisible )
	self._panel:setVisible( isVisible )
end

return replay_panel

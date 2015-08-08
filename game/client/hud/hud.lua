----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local mathutil = include( "modules/mathutil" )
local array = include( "modules/array" )
local color = include( "modules/color" )
local gameobj = include( "modules/game" )
local mui = include("mui/mui")
local mui_defs = include( "mui/mui_defs")
local mui_tooltip = include( "mui/mui_tooltip")
local modalDialog = include( "states/state-modal-dialog" )
local modal_thread = include( "gameplay/modal_thread" )
local agent_panel = include( "hud/agent_panel" )
local home_panel = include( "hud/home_panel" )
local pause_dialog = include( "hud/pause_dialog" )
local console_panel = include( "hud/console_panel" )
local hudtarget = include( "hud/targeting")
local world_hud = include( "hud/hud-inworld")
local agent_actions = include( "hud/agent_actions" )
local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )
local resources = include( "resources" )
local level = include( "sim/level" )
local mui_util = include( "mui/mui_util" )
local simdefs = include( "sim/simdefs" )
local guiex = include( "client/guiex" )
local simquery = include( "sim/simquery" )
local serverdefs = include( "modules/serverdefs" )
local mui_group = include( "mui/widgets/mui_group" )
local simfactory = include( "sim/simfactory" )
local alarm_states = include( "sim/alarm_states" )

----------------------------------------------------------------
-- Local functions
local STATE_NULL = 0
local STATE_ABILITY_TARGET = 4
local STATE_ITEM_TARGET = 5
local STATE_REPLAYING = 9

local MAINFRAME_ZOOM = 0.2

 -- Max pathfinding distance for determining valid path; paths beyond this MP cost are considered unpathable.
local MAX_PATH = 15

local DEFAULT_MAINFRAME = 0
local SHOW_MAINFRAME = 1
local HIDE_MAINFRAME = 2

----------------------------------------------------------------

local function isCancelEvent( ev )
    return (ev.eventType == mui_defs.EVENT_MouseUp and ev.button == mui_defs.MB_Right) or
            (ev.eventType == mui_defs.EVENT_KeyDown and ev.key == mui_defs.K_ESCAPE)
end

----------------------------------------------------------------
-- HUD monstrosity.

local hud = class()

function hud:showFlyImage( x0, y0, target, duration)	
	local wx, wy = self._game:worldToWnd( x0, y0, 55 )
	local u1x, u1y = self._screen:wndToUI( wx,wy )	
	local nx,ny = 0,0

	local u2x,u2y = self._screen:findWidget(target):getAbsolutePosition()

	local fxmgr = self._game.fxmgr
	fxmgr:widgetFlyImage( u1x,u1y, u2x, u2y, duration, self._screen, nil)
end


function hud:showFlyText( x0, y0, txt, color, target, sound, soundDelay)	
	local wx, wy = self._game:worldToWnd( x0, y0, 0 )
	local u1x, u1y = self._screen:wndToUI( wx,wy )	
	local nx,ny = 0,0

	if target == "credits" then
		nx,ny = self._screen.binder.resourcePnl.binder.credits:getPosition()
		ny = -ny + 20

	elseif target == "alarm" then
		local sx,sy = self._screen:getResolution()
		nx,ny = self._screen.binder.alarm:getPosition()
		nx = sx - nx 

	else
		nx,ny = self._screen.binder.resourcePnl.binder.cpuNum:getPosition()
		ny = -ny + 20
	end

	local u2x,u2y = self._screen:wndToUI( nx,ny )	
	local fxmgr = self._game.fxmgr
	fxmgr:widgetFlyTxt( u1x,u1y, u2x, u2y, txt , 3, self._screen, 0.5, color,sound, soundDelay)
end

local function updateFloatTxt( screen, widget )
    local DURATION = 60
    widget.t = widget.t + 1
    -- SHARP_EASE_IN
    local t = math.pow( 1 - widget.t / DURATION, 8 )
    widget.worldz = (t) * 32 + (1-t) * 48 
    return widget.t > DURATION
end

function hud:showFloatText( x0, y0, txt, color )
	local widget = self._world_hud:createWidget( world_hud.HUD_FLOATERS, "flying_text", { worldx = x0, worldy = y0, worldz = 32, t = 0 }, updateFloatTxt )
	widget.binder.txt:setText( "<font1_24_r>"..txt.."</>" )
	if color then
		widget.binder.txt:setColor(color.r,color.g,color.b,color.a)	
	end
end

function hud:subtractCPU( delta )
	local anim = self._screen.binder.resourcePnl.binder.cpuUseFx
	anim:setVisible(true)
	anim:setAnim("idle")

	anim:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
				function( anim, animname )
					if animname == "idle" then
						anim:setVisible(false)
					end
				end )

	local nx,ny = self._screen.binder.resourcePnl.binder.cpuNum:getPosition()
	local u1x,u1y = self._screen:wndToUI( nx,ny )	
	local fxmgr = self._game.fxmgr
	fxmgr:widgetFlyTxt( u1x,u1y, u1x + 0.025 ,u1y, delta , 2, self._screen)

end

local function checkForMainframeEvent( simdefs, eventType, eventData )
	if eventType == simdefs.EV_UNIT_MAINFRAME_UPDATE
	 or eventType == simdefs.EV_UNIT_UPDATE_ICE
	 or eventType == simdefs.EV_MAINFRAME_PARASITE
	 or eventType == simdefs.EV_MAINFRAME_MOVE_DAEMON
	 or eventType == simdefs.EV_KILL_DAEMON 
	 or eventType == simdefs.EV_SCRIPT_ENTER_MAINFRAME then
		-- These events require mainframe mode.
		return SHOW_MAINFRAME
	
	elseif eventType == simdefs.EV_UNIT_START_WALKING or eventType == simdefs.EV_UNIT_START_SHOOTING or eventType == simdefs.EV_SCRIPT_EXIT_MAINFRAME or eventType == simdefs.EV_UNIT_APPEARED then
		-- These events require normal mode.
		return HIDE_MAINFRAME
	end

	-- Any eithe event don't care about the mainframe mode.
	return DEFAULT_MAINFRAME
end

function hud:showShotHaze( state )
	local widget = self._screen:findWidget( "shotHaze" )
	if state then
		widget:setVisible(true)
	else
		widget:setVisible(false)
	end
end


local function clearMovementRange( self )
	-- Hide movement range hilites.
	self._game.boardRig:clearMovementTiles()
	self._game.boardRig:clearCloakTiles()

	-- Clear movement cells
	self._revealCells = nil
	self._cloakCells = nil
end


function hud:showMovementRange( unit )

	clearMovementRange( self )

	-- Show movement range.
	if unit and not unit._isPlayer and unit:hasTrait("mp") and unit:canAct() and unit:getPlayerOwner() == self._game:getLocalPlayer() then
		local sim = self._game.simCore
		local simquery = sim:getQuery()
		local cell = sim:getCell( unit:getLocation() )

		self._revealCells = simquery.floodFill( sim, unit, cell,unit:getMP() )

		if unit:getTraits().sneaking then  
			self._game.boardRig:setMovementTiles( self._revealCells, 0.8 * cdefs.MOVECLR_SNEAK, cdefs.MOVECLR_SNEAK )
		else
			self._game.boardRig:setMovementTiles( self._revealCells, 0.8 * cdefs.MOVECLR_DEFAULT, cdefs.MOVECLR_DEFAULT )
		end

		if unit:getTraits().cloakDistance and unit:getTraits().cloakDistance > 0 then
			local distance = math.min(unit:getTraits().cloakDistance-1,unit:getMP())
			self._cloakCells = nil
			self._cloakCells = simquery.floodFill( sim, unit, cell, distance )
		end

		if self._cloakCells then
			self._game.boardRig:setCloakTiles( self._cloakCells, 0.8 * cdefs.MOVECLR_INVIS, cdefs.MOVECLR_INVIS )
		else 
			self._game.boardRig:clearCloakTiles()
		end
	end
end

function hud:previewAbilityAP( unit, apCost )
	local rig = self._game.boardRig:getUnitRig( unit:getID() )
    if rig then
	    rig:previewMovement( apCost )
    end
	self._home_panel:refreshAgent( unit )
	if apCost > 0 then
		self._abilityPreview = true
	else 
		self._abilityPreview = false 
	end  
end

local function showMovement( hud, unit, moveTable, pathCost )
	local sim = hud._game.simCore

	if hud._movePreview then
		hud._game.boardRig:unchainCells( hud._movePreview.hiliteID )
		local rig = hud._game.boardRig:getUnitRig( hud._movePreview.unitID )
		local prevUnit = sim:getUnit( hud._movePreview.unitID )
		if rig and not hud._abilityPreview then
			rig:previewMovement( 0 )
		end
		hud._movePreview = nil

		hud._home_panel:refreshAgent( prevUnit )
	end

	if moveTable then
		hud._movePreview = { unitID = unit:getID(), pathCost = pathCost }
		if unit:getMP() >= pathCost then
			hud._movePreview.hiliteID = hud._game.boardRig:chainCells( moveTable )
			local rig = hud._game.boardRig:getUnitRig( unit:getID() )
			if rig then
				rig:previewMovement( pathCost )
				hud._abilityPreview = false 
			end
		else
			hud._movePreview.hiliteID = hud._game.boardRig:chainCells( moveTable, {r=0.2, g=0.2, b=0.2, a=0.8}, nil, true )
		end

		hud._home_panel:refreshAgent( unit )
	end
end

local function previewMovement(hud, unit, cellx, celly)
	local sim = hud._game.simCore 
	local simdefs = sim:getDefs()

	hud._bValidMovement = false

	if unit and sim:getCurrentPlayer() and unit:getPlayerOwner() == sim:getCurrentPlayer() and unit:hasTrait("mp") and unit:canAct() then
		local startcell = sim:getCell( unit:getLocation() )
		local endcell = startcell
		if cellx and celly then
			endcell = sim:getCell( cellx, celly )
		end

		if startcell ~= endcell and endcell then
			local moveTable, pathCost = sim:getQuery().findPath( sim, unit, startcell, endcell, math.max( MAX_PATH, unit:getMP() ) )
			if moveTable then
				hud._bValidMovement = unit:getMP() >= pathCost
				table.insert( moveTable, 1, { x = startcell.x, y = startcell.y } )
				showMovement(hud, unit, moveTable, pathCost )
				return
			end
		end
	end

	showMovement( hud, nil )
end

local function transition( hud, state, stateData )	
    if state == hud._state then
        return
    end

	local sim = hud._game.simCore

	if hud._state == STATE_REPLAYING then
		hud._game:skip()
	end

	if hud._stateData and hud._stateData.hiliteID then
		hud._game.boardRig:unhiliteCells( hud._stateData.hiliteID )
	elseif hud._stateData and hud._stateData.ability then
		if hud._stateData.ability.endTargeting then
			hud._stateData.ability:endTargeting( hud )
		end
		if hud._stateData.targetHandler and hud._stateData.targetHandler.endTargeting then
			hud._stateData.targetHandler:endTargeting( hud )
		end
	end

	if state == STATE_ABILITY_TARGET and stateData and stateData.ability then 
		if stateData.ability.startTargeting then
			stateData.ability:startTargeting( hud )
		end
		if stateData.targetHandler and stateData.targetHandler.startTargeting then
			stateData.targetHandler:startTargeting( agent_panel.buttonLocator( hud ) )
		end
	end

	hud._state = state
	hud._stateData = stateData
	

	if hud._state == STATE_NULL then
		
		hud._hideCubeCursor = false
        MOAISim.setCursor( cdefs.CURSOR_DEFAULT )
		
		if hud:getSelectedUnit() and not hud:getSelectedUnit()._isPlayer then
			hud:showMovementRange( hud:getSelectedUnit() )
			previewMovement( hud, hud:getSelectedUnit(), hud._tooltipX, hud._tooltipY )
		end

	else
        if hud._state == STATE_ITEM_TARGET then
            hud._hideCubeCursor = true
            MOAISim.setCursor( cdefs.CURSOR_TARGET )
        end

		clearMovementRange( hud )
		showMovement( hud, nil )
	end

	hud:refreshHud( )
end

local function doMoveUnit( hud, unit, cellx, celly )
	local sim = hud._game.simCore
	local simdefs = sim:getDefs()
	assert( unit )

	if sim:getTags().blockMoveObserve then
		hud:showWarning( STRINGS.UI.WARNING_OBSERVE_GUARD, {r=1,g=1,b=1,a=1}, STRINGS.UI.WARNING_OBSERVE_GUARD_2 )
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_Monster_ForSale" )
		return false
	end

	if sim:getTags().blockMovePeek then
		hud:showWarning( STRINGS.UI.WARNING_PEEK_GUARD, {r=1,g=1,b=1,a=1}, STRINGS.UI.WARNING_PEEK_GUARD_2 )
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_Monster_ForSale" )
		return false
	end


	if sim:getTags().blockMoveCentral then 
		if not unit:getTraits().central then
			local endcell = sim:getCell( cellx, celly )
			if sim:getQuery().cellHasTag( sim, endcell, "interruptNonCentral" ) then 
				hud._game:dispatchScriptEvent( level.EV_FINAL_ROOM_INTERRUPT )
				hud:showWarning( STRINGS.UI.WARNING_NO_CENTRAL, {r=1,g=1,b=1,a=1}, STRINGS.UI.WARNING_NO_CENTRAL_2 )
				MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_Monster_ForSale" )
				return false
			end 
		end 
	end 

	if unit:getPlayerOwner() == sim:getCurrentPlayer() and unit:getPlayerOwner() == hud._game:getLocalPlayer() and unit:hasTrait("mp") and unit:canAct() then
		local startcell = sim:getCell( unit:getLocation() )
		local endcell = sim:getCell( cellx, celly )

		if startcell ~= endcell and endcell then
			local moveTable, pathCost = sim:getQuery().findPath( sim, unit, startcell, endcell, math.max( MAX_PATH, unit:getMP() ) )
			if moveTable then
				if pathCost <= unit:getMP() then
					hud._game:doAction( "moveAction", unit:getID(), moveTable )
					MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_CONFIRM )
				else
					hud:showWarning( STRINGS.UI.WARNING_NO_AP, {r=1,g=1,b=1,a=1}, STRINGS.UI.WARNING_NO_AP2 )

					local endTurnBtn = hud._screen:findWidget( "endTurnBtn" )
					endTurnBtn:blink(0.2, 2, 0, {r=1,g=1,b=1,a=1})

					if not endTurnBtn:hasTransition() then
						endTurnBtn:createTransition( "activate_left" )
					end
					MOAIFmodDesigner.playSound("SpySociety/HUD/voice/level1/alarmvoice_warning")
				end
				return true
			else
				local checkcell = unit:getPlayerOwner():getCell(cellx,celly)
				if not checkcell or not sim:getQuery().canPath(sim, unit, nil, checkcell) then
					hud:showWarning( util.sformat( STRINGS.UI.WARNING_CANT_MOVE, unit:getName() ) )
					MOAIFmodDesigner.playSound( "SpySociety/HUD/voice/level1/alarmvoice_warning" )
				else
					hud:showWarning( STRINGS.UI.WARNING_NO_PATH, {r=1,g=1,b=1,a=1} )
					MOAIFmodDesigner.playSound( "SpySociety/HUD/voice/level1/alarmvoice_warning" )
				end
				return true
			end
		end
	end

	return false
end

local function onClickMenu( hud )
    if hud._state ~= STATE_NULL then
        hud:transitionNull()
    else
    	local result = hud._pause_dialog:show()
        if result == hud._pause_dialog.QUIT then
            MOAIFmodDesigner.stopMusic()
		    hud._game:quitToMainMenu()

        elseif result == hud._pause_dialog.RETIRE then
            hud._game:doAction( "resignMission" )
        end
    end
end

local function onClickRotateCamera( hud, orientationDelta )
	if not hud._game:isReplaying() then
		local camera = hud._game:getCamera()
		camera:rotateOrientation( camera:getOrientation() + orientationDelta )
	end
end

local function onClickRegenLevel( hud )
	local result = modalDialog.showYesNo( STRINGS.UI.REGEN_LEVEL_BODY, STRINGS.UI.REGEN_LEVEL )
	if result == modalDialog.OK then
        hud._game:regenerateLevel()
    end
end

local function onClickRewindGame( hud )
	hud._screen.binder.rewindBtn:blink()
    if not hud._game:isReplaying() then

		local viz_manager = include( "gameplay/viz_manager" )
    	local shouldShow = viz_manager:checkShouldShow("modal-rewind-tutorial")
    	if shouldShow then
    		modalDialog.showRewindTutorialDialog()
    	end

        local numRewinds = hud._game.simCore:getTags().rewindsLeft
        local result = modalDialog.showUseRewind( nil, util.sformat( STRINGS.UI.REWINDS_REMAINING, numRewinds )) 
        if result == modalDialog.OK then
    		inputmgr.setInputEnabled(false)
            KLEIRenderScene:setDesaturation( rig_util.linearEase("desat_ease") )
            MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_undoAction" )
            rig_util.wait( 30 )
    		inputmgr.setInputEnabled(true)
           	hud._game:rewindTurns()
            KLEIRenderScene:setDesaturation( )
        end
    end
end

local function refreshTrackerMusic( hud, stage )
    stage = math.max( stage, hud._musicStage or 0 )
    local isClimax = stage >= simdefs.TRACKER_MAXSTAGE or hud._game.simCore:getClimax()

    -- Check special conditions for max-intensity/climax.
    if not isClimax then
        for i, unit in pairs( hud._game.simCore:getPC():getAgents() ) do
            if simquery.isUnitUnderOverwatch( unit ) then
                isClimax = true
                break
            end
        end
    end

    -- And cue the music 
	MOAIFmodDesigner.setMusicProperty("intensity", stage )
	if isClimax then
		MOAIFmodDesigner.setMusicProperty("kick",1)
    else
		MOAIFmodDesigner.setMusicProperty("kick",0)
	end

    hud._musicStage = stage
end

local function refreshTrackerAdvance( hud, trackerNumber )
    local stage = hud._game.simCore:getTrackerStage( math.min( simdefs.TRACKER_MAXCOUNT, trackerNumber ))
	local animWidget = hud._screen.binder.alarm.binder.trackerAnimFive
	local colourIndex = math.min( #cdefs.TRACKER_COLOURS, stage + 1 )
	local colour = cdefs.TRACKER_COLOURS[ colourIndex ]

    -- Show the tracker number
	hud._screen.binder.alarm.binder.trackerTxt:setText( tostring(stage) )
	hud._screen.binder.alarm.binder.trackerTxt:setColor(colour.r, colour.g, colour.b, 1)
	hud._screen.binder.alarm.binder.alarmLvlTitle:setColor(colour.r, colour.g, colour.b, 1)


	local params = hud._game.params

	local tip = STRINGS.UI.ADVANCED_ALARM_TOOLTIP
	if params.missionEvents and params.missionEvents.advancedAlarm then
		tip =STRINGS.UI.ADVANCED_ALARM_TOOLTIP
	end

	local alarmList = hud._game.simCore:getAlarmTypes()
 	local next_alarm = simdefs.ALARM_TYPES[alarmList][stage+1]

	
 	if next_alarm then
 		tip = tip .. alarm_states.alarm_level_tips[next_alarm]
	else
 		tip = tip..STRINGS.UI.ALARM_NEXT_AFTER_SIX
 	end
 	
	hud._screen.binder.alarm:setTooltip(tip)

    -- Refresh the alarm ring.
	animWidget:setColor( colour:unpack() )
    if trackerNumber >= simdefs.TRACKER_MAXCOUNT then
    	animWidget:setAnim("idle_5")
    else
    	animWidget:setAnim("idle_".. trackerNumber % simdefs.TRACKER_INCREMENT )
    end

    refreshTrackerMusic( hud, stage )


end

local function runTrackerAdvance( hud, txt, delta, tracker, subtxt )
	if txt then
		hud:showWarning( txt, nil, subtxt, (delta+3)*cdefs.SECONDS )
	end

	hud._screen.binder.alarm.binder.alarmRing1:setAnim( "idle" )	
	hud._screen.binder.alarm.binder.alarmRing1:setVisible( true )
	hud._screen.binder.alarm.binder.alarmRing1:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
		function( anim, animname )
			if animname == "idle" then
				hud._screen.binder.alarm.binder.alarmRing1:setVisible(false)
			end		
		end)

    local animWidget = hud._screen.binder.alarm.binder.trackerAnimFive
	for i=1,delta do
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_ADVANCE_TRACKER )
    
        local stage = hud._game.simCore:getTrackerStage( math.min( simdefs.TRACKER_MAXCOUNT, tracker + i ))
	    local colourIndex = math.min( #cdefs.TRACKER_COLOURS, stage + 1 )
	    local colour = cdefs.TRACKER_COLOURS[ colourIndex ]
	    animWidget:setColor( colour:unpack() )
        local fillNum = (tracker + i) % simdefs.TRACKER_INCREMENT
        if fillNum == 0 then
            rig_util.waitForAnim( animWidget:getProp(), "fill_5" )
        else
            rig_util.waitForAnim( animWidget:getProp(), "fill_" .. fillNum )
        end
    end

    refreshTrackerAdvance( hud, tracker + delta )
	
    rig_util.wait( 30 )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_ADVANCE_TRACKER_NUMBER )
end
 
function hud:showWarning( ... )
    self._warnings:showWarning( ... )
end

function hud:queueWarning( ... )
    self._warnings:queueWarning( ... )
end

function hud:showElement( isVisible, ... )
	if self.vizTags == nil then
		self.vizTags = {}
	end

	for i, name in ipairs({...}) do
		self.vizTags[ name ] = isVisible
	end

    self:refreshHud()
end

function hud:canShowElement( name )
	local vizTags = self._game.simCore.vizTags

	return (vizTags == nil or vizTags[ name ] ~= false) and (self.vizTags == nil or self.vizTags[ name ] ~= false)
end

local function startTitleSwipe( hud, swipeText,color,sound,showCorpTurn,turn)
	
	MOAIFmodDesigner.playSound( sound )
	hud._screen.binder.swipe:setVisible(true)
	hud._screen.binder.swipe.binder.anim:setColor(color.r, color.g, color.b, color.a )	
	hud._screen.binder.swipe.binder.anim:setAnim("pre")
	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/turnswitch_in" )

	hud._screen.binder.swipe.binder.txt:spoolText(string.format(swipeText))	
	hud._screen.binder.swipe.binder.txt:setColor(color.r, color.g, color.b, color.a )	

	hud._screen.binder.swipe.binder.turnTxt:spoolText(string.format(STRINGS.UI.TURN, turn), 20)	
	hud._screen.binder.swipe.binder.turnTxt:setColor(color.r, color.g, color.b, color.a )	

	local stop = false
	hud._screen.binder.swipe.binder.anim:getProp():setPlayMode( KLEIAnim.LOOP )
	hud._screen.binder.swipe.binder.anim:getProp():setListener( KLEIAnim.EVENT_ANIM_END,
	function( anim, animname )
				if animname == "pre" then
					hud._screen.binder.swipe.binder.anim:setAnim("loop")		
					stop = true
				end					
			end )

	util.fullGC() -- Convenient time to do a full GC. ;}			

	while stop == false do
		coroutine.yield()		
	end

end

local function stopTitleSwipe(hud)
	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/turnswitch_out" )
    rig_util.waitForAnim(  hud._screen.binder.swipe.binder.anim:getProp(), "pst" )
    hud._screen.binder.swipe:setVisible(false)
end

local function hideTitleSwipe( hud )

	hud._screen.binder.swipe:setVisible( false )
end

local function onClickEndTurn( hud, button, event )
	transition( hud, STATE_NULL )

	if not hud._game.simCore:getTags().isTutorial then
		hud._missionPanel:stopTalkingHead()
	end
    hud._game:doEndTurn()
end

function hud:isMainframe()
    return self._isMainframe
end

function hud:hideMainframe()
	if self._isMainframe then
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_MODE_SWITCH )
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/mode_switch_static" )
        MOAIFmodDesigner.setMusicProperty("mode",0)
        MOAIFmodDesigner.setAmbientReverb( "office" )
        FMODMixer:popMix("mainframe")

        KLEIRenderScene:pulseUIFuzz( 0.2 )

        self._isMainframe = false
		self._hideCubeCursor = false

        self:refreshHud()
        self._mainframe_panel:hide()

        local game = self._game
    	local gfxOptions = game:getGfxOptions()
		gfxOptions.bRenderExits = true
		gfxOptions.bFOWEnabled = true
		gfxOptions.bMainframeMode = false
		gfxOptions.KAnimFilter = "default"
        gfxOptions.bTacticalView = util.isKeyBindingDown( "toggleTactical" )

        game:getCamera():zoomTo( game:getCamera():getZoom() - MAINFRAME_ZOOM )
        if game.viz then
            game.viz:destroy()
        end
        if game.boardRig then
    		game.boardRig:refresh()
        end

		self._missionPanel:ShowTalkingHeadIfStillVO()
		game:dispatchScriptEvent( level.EV_HUD_MAINFRAME_TOGGLE )	
	end
end

function hud:showMainframe()
	if not self._isMainframe then 
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_MODE_SWITCH )
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/mode_switch_static" )
        MOAIFmodDesigner.setMusicProperty("mode",1)
        MOAIFmodDesigner.setAmbientReverb( "mainframe" )
        FMODMixer:pushMix("mainframe")
        
        KLEIRenderScene:pulseUIFuzz( 0.2 )					

        self._isMainframe = true
        self._hideCubeCursor = true

        self:refreshHud()


        local game = self._game
        local gfxOptions = game:getGfxOptions()
        gfxOptions.bRenderExits = true
		gfxOptions.bFOWEnabled = false
		gfxOptions.bMainframeMode = true
		gfxOptions.KAnimFilter = "green"
        game:getCamera():zoomTo( game:getCamera():getZoom() +MAINFRAME_ZOOM )

        game.viz:destroy()
		game.boardRig:refresh()
        game:dispatchScriptEvent( level.EV_HUD_MAINFRAME_TOGGLE )	 

        self._missionPanel:processEvent( {type = "clearEnemyMessage"} )
		self._missionPanel:HideTalkingHeadButRetainVO()
		self._mainframe_panel:show()
	end
end

function hud:onClickMainframeBtn( button, event )
	if self._state ~= STATE_NULL and self._state ~= STATE_REPLAYING then
    	transition( self, STATE_NULL )
    end

    if self._state == STATE_NULL then
		if self._isMainframe then
			self:hideMainframe()
		else
			self:showMainframe()
		end
	end
end

local function onClickWallsButton( hud, button, event )
	if not hud._game:isReplaying() then
		hud:setShortWalls(not hud._isShortWall)
	end
end

function hud:setShortWalls(do_short)
	local gfxOptions = self._game:getGfxOptions()
	gfxOptions.bShortWallMode = do_short
	self._isShortWall = do_short
	self._game.boardRig:refresh()

	self._screen.binder.topPnl.binder.btnToggleWalls:setInactiveImage(do_short and "gui/hud3/UserButtons/userbtn_raise_walls.png" or "gui/hud3/UserButtons/userbtn_lower_walls.png" )
	self._screen.binder.topPnl.binder.btnToggleWalls:setActiveImage(do_short and "gui/hud3/UserButtons/userbtn_raise_walls_hl.png" or "gui/hud3/UserButtons/userbtn_lower_wall_hl.png" )
	self._screen.binder.topPnl.binder.btnToggleWalls:setHoverImage(do_short and "gui/hud3/UserButtons/userbtn_raise_walls_hl.png" or "gui/hud3/UserButtons/userbtn_lower_wall_hl.png" )
	self._screen.binder.topPnl.binder.btnToggleWalls:setColorInactive(cdefs.COLOR_ACTION:unpack())
	self._screen.binder.topPnl.binder.btnToggleWalls:setColorActive(cdefs.COLOR_ACTION_HOVER:unpack())
	self._screen.binder.topPnl.binder.btnToggleWalls:setColorHover(cdefs.COLOR_ACTION_HOVER:unpack())				
end

function hud:refreshTacticalView()
    local isEnabled = false
    if self._state ~= STATE_REPLAYING and not self._isMainframe and ( util.isKeyBindingDown( "toggleTactical" ) or self._screen.binder.btnToggleTac:isActive() ) then
        isEnabled = true
    end

    local gfxOptions = self._game:getGfxOptions()
    if isEnabled ~= gfxOptions.bTacticalView then
    	
	    	if isEnabled == true then
	    		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/TacticalView_Open")
	    	else
	    		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/TacticalView_Close")
	    	end
    	
        gfxOptions.bTacticalView = isEnabled
        self._game.boardRig:refresh()
    end
end

local function showGrafterDialog( hud, itemDef, userUnit, drill )
	assert( hud._choice_dialog == nil )

	local screen = mui.createScreen( "modal-grafter.lua" )
	
	hud._choice_dialog = screen
	mui.activateScreen( screen )

	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/popup")

	screen.binder.bodyTxt2:setText( string.format( STRINGS.UI.DIALOGS.AUGMENT_MACHINE_BODY_2, itemDef.name) )

	screen.binder.pnl.binder.yourface.binder.portrait:bindBuild( userUnit:getUnitData().profile_build or userUnit:getUnitData().profile_anim )
	screen.binder.pnl.binder.yourface.binder.portrait:bindAnim( userUnit:getUnitData().profile_anim )
	
	local augments = userUnit:getAugments()
	local result = nil

	if itemDef then
		screen.binder.pnl.binder.drill:setVisible(false)
		screen.binder.pnl.binder.Item:setVisible(true)

		local item = simfactory.createUnit( itemDef, nil )		
		local widget = screen:findWidget( "Item" )						
		widget.binder.img:setImage( item:getUnitData().profile_icon )

        local tooltip = util.tooltip( screen )
        local section = tooltip:addSection()
        item:getUnitData().onTooltip( section, item )
        widget.binder.img:setTooltip( tooltip )
		widget.binder.itemName:setText(item:getName())
	end

	if drill then
		screen.binder.pnl.binder.headerTxt:setText(STRINGS.UI.AUGMENT_DRILL_MODAL_TITLE)
		
		screen.binder.pnl.binder.Item:setVisible(false)
		screen.binder.pnl.binder.subheader2:setText(STRINGS.UI.AUGMENT_DRILL_MODAL_ACTION)
		screen.binder.pnl.binder.functionTxt2:setText(STRINGS.UI.AUGMENT_DRILL_MODAL_HEADER)
		screen.binder.pnl.binder.bodyTxt2:setText(STRINGS.UI.AUGMENT_DRILL_MODAL_BODY)		
		screen:findWidget( "installAugmentBtn" ):setVisible(false)
		screen.binder.pnl.binder.drill:setVisible(true)
		
		for i, widget in screen.binder.drill.binder:forEach( "augment" ) do
			if augments[i] then 
				widget.binder.img:setVisible( true )
				widget.binder.btn:setVisible( true )
				widget.binder.btn.onClick = function() result = 3+i end
				local item = augments[i]
				widget.binder.btn:setImage( item:getUnitData().profile_icon )
		        local tooltip = util.tooltip( screen )
		        local section = tooltip:addSection()
		        item:getUnitData().onTooltip( section, item )
		        widget.binder.img:setTooltip( tooltip )
		      --  widget.binder.img:setColor(1,1,1)

			else
				widget.binder.img:setVisible( false )
				widget.binder.btn:setVisible( false )
			end			
		end
	else
		screen.binder.pnl.binder.drill:setVisible(false)
	end

	
	local maxed = true
	for i, widget in screen.binder:forEach( "augment" ) do
		if augments[i] then 
			widget.binder.item:setVisible( true )
			widget.binder.slot:setVisible( false )
			widget.binder.empty:setVisible( false )
			widget.binder.installPlus:setVisible( false )			
			local item = augments[i]
			widget.binder.item:setImage( item:getUnitData().profile_icon )
	        local tooltip = util.tooltip( screen )
	        local section = tooltip:addSection()
	        item:getUnitData().onTooltip( section, item )
	        widget.binder.item:setTooltip( tooltip )
	        widget.binder.item:setColor(1,1,1)
		elseif i <= userUnit:getTraits().augmentMaxSize then 
			widget.binder.slot:setVisible( true )
			widget.binder.item:setVisible( false )
			widget.binder.empty:setVisible( false )
			widget.binder.installPlus:setVisible( false )
			widget.binder.slot:setTooltip( STRINGS.UI.AUGMENT_GRAFTER_EMPTY_SOCKET )
			widget.binder.slot:setColor(1,1,1)
		elseif i == userUnit:getTraits().augmentMaxSize + 1 then
			widget.binder.item:setVisible( false )
			widget.binder.slot:setVisible( false )
			widget.binder.empty:setVisible( false )
			widget.binder.installPlus:setVisible( true )
			widget.binder.installPlus:setTooltip( STRINGS.UI.AUGMENT_GRAFTER_NEW_SOCKET )
			maxed = false
		elseif i <= simdefs.DEFAULT_AUGMENT_CAPACITY then
			widget.binder.item:setVisible( false )
			widget.binder.slot:setVisible( false )
			widget.binder.empty:setVisible( true )
			widget.binder.installPlus:setVisible( false )
			widget.binder.empty:setTooltip( STRINGS.UI.AUGMENT_GRAFTER_FUTURE_SOCKET )
			widget.binder.empty:setColor( 0.3,0.3,0.3,0.6)
		else
			widget.binder.installPlus:setVisible( false )
			widget.binder.item:setVisible( false )
			widget.binder.slot:setVisible( false )
			widget.binder.empty:setVisible( false )
		end
	end 

	if maxed then
		screen.binder.bodyTxt1:setText(STRINGS.UI.AUGMENT_GRAFTER_MAX_SOCKETS)
	end

    
    screen:findWidget( "cancelBtn" ).onClick = function() result = 1 end
    if maxed then
    	screen:findWidget( "installSocketBtn" ):setDisabled(true)
    else
    	screen:findWidget( "installSocketBtn" ).onClick = function() result = 2 end   
    end
    screen:findWidget( "installAugmentBtn" ).onClick = function() result = 3 end
    screen:findWidget( "installAugmentBtn" ):setText( string.format(STRINGS.UI.DIALOGS.AUGMENT_MACHINE_3, util.toupper(itemDef.name)))

    if  #augments >= userUnit:getTraits().augmentMaxSize then
    	screen:findWidget( "installAugmentBtn" ):setDisabled(true)
    	screen:findWidget( "installAugmentBtn" ):setTooltip(STRINGS.UI.REASON.NO_FREE_SOCKETS)
    end

    -- We are running in the vizThread coroutine.  Yield until a response is chosen by the UI.
	-- Note that the click handler will be triggered by the main coroutine, but we use a closure
	-- to inform us what the chosen result is.
	while result == nil do
		coroutine.yield()
        result = result or modal_thread.checkAutoClose( hud, hud._game )
	end

	mui.deactivateScreen( screen )
	hud._choice_dialog = nil

	hud._game.simCore:setChoice( result )

	return result
end

local function showExecDialog( hud, headerTxt, bodyTxt, options, corps, names )
	assert( hud._choice_dialog == nil )

	local screen

	screen = mui.createScreen( "modal-execterminals.lua" )
	
	hud._choice_dialog = screen
	mui.activateScreen( screen )

	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/popup")

	screen.binder.targetTitle:setText( headerTxt )
	screen.binder.objTxt:setText( bodyTxt )

	--selected agent
	local unit = hud:getSelectedUnit()
	if unit ~= nil and unit.getUnitData then
		screen.binder.pnl.binder.portrait:bindBuild( unit:getUnitData().profile_build or unit:getUnitData().profile_anim )
		screen.binder.pnl.binder.portrait:bindAnim( unit:getUnitData().profile_anim )
		screen.binder.pnl.binder.portrait:setVisible(true)
	else
		screen.binder.pnl.binder.yourface:setVisible(false)
	end

	for i, location in screen.binder.pnl.binder:forEach( "location" ) do
		local corp = corps[i]
		local name = names[i]
		local nameIcon = serverdefs.SITUATIONS[ name ].ui.icon
		local corpIcon = serverdefs.CORP_DATA[ corp ].imgs.logoLarge
		location.binder.corpLogo:setImage( corpIcon )
		location.binder.locationImg:setImage( nameIcon )
	end 

	-- Fill out the dialog options.
	local result = nil
	local x = 1
	for i, location in screen.binder.pnl.binder:forEach( "location" ) do
		local btn = location.binder.btn
		if options[i] == nil then
			btn:setVisible( false )
		else
			btn:setVisible( true )
			btn:setText("<c:8CFFFF>"..  options[i] .."</>")
			btn.onClick = util.makeDelegate( nil, function() result = i end )

			local txt = string.format("<ttheader>%s</>\n%s", util.toupper(options[i]), serverdefs.SITUATIONS[ names[i] ].ui.moreInfo)
			btn:setTooltip(txt)
			x = x + 1
		end
	end

	-- We are running in the vizThread coroutine.  Yield until a response is chosen by the UI.
	-- Note that the click handler will be triggered by the main coroutine, but we use a closure
	-- to inform us what the chosen result is.
	while result == nil do
		coroutine.yield()
        result = result or modal_thread.checkAutoClose( hud, hud._game )
	end

	mui.deactivateScreen( screen )
	hud._choice_dialog = nil

	hud._game.simCore:setChoice( result )

	return result
end

local function showInstallAugmentDialog( hud, item, unit )
	assert( hud._choice_dialog == nil )
	assert( item )
	assert( unit )

	local screen

	screen = mui.createScreen( "modal-install-augment.lua" )
	
	hud._choice_dialog = screen
	mui.activateScreen( screen )

	MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/popup")

	--selected agent
	if unit ~= nil and unit.getUnitData then
		screen.binder.pnl.binder.yourface.binder.portrait:bindBuild( unit:getUnitData().profile_build or unit:getUnitData().profile_anim )
		screen.binder.pnl.binder.yourface.binder.portrait:bindAnim( unit:getUnitData().profile_anim )
		screen.binder.pnl.binder.portrait:setVisible(true)
	else
		screen.binder.pnl.binder.yourface:setVisible(false)
	end

	if item then
		screen.binder.pnl.binder.Item:setVisible(true)

		local widget = screen:findWidget( "Item" )						
		widget.binder.img:setImage( item:getUnitData().profile_icon )

        local tooltip = util.tooltip( screen )
        local section = tooltip:addSection()
        item:getUnitData().onTooltip( section, item )
        widget.binder.img:setTooltip( tooltip )
		widget.binder.itemName:setText(item:getName())
	end

	-- Fill out the dialog options.
    local result = nil


    screen:findWidget( "installAugmentBtn" ).onClick = util.makeDelegate( nil, function() result = 2 end )
    screen:findWidget( "leaveInInventoryBtn" ).onClick =util.makeDelegate( nil, function() result = 1 end )  

	-- We are running in the vizThread coroutine.  Yield until a response is chosen by the UI.
	-- Note that the click handler will be triggered by the main coroutine, but we use a closure
	-- to inform us what the chosen result is.
	while result == nil do
		coroutine.yield()
        result = result or modal_thread.checkAutoClose( hud, hud._game )
	end

	mui.deactivateScreen( screen )
	hud._choice_dialog = nil

	hud._game.simCore:setChoice( result )

	return result
end


----------------------------------------------------------

function hud:destroyHud( )
	MOAIFmodDesigner.setAmbientReverb( nil )

    self:hideMainframe()

	if self._itemsPanel then
		self._itemsPanel:destroy()
		self._itemsPanel = nil
	end

	if self._missionPanel then
		self._missionPanel:destroy()
		self._missionPanel = nil
	end

    if self._pause_dialog then
        self._pause_dialog:hide()
        self._pause_dialog = nil
    end

    if self._blackOverlay then 
    	mui.deactivateScreen( self._blackOverlay )
    	self._blackOverlay = nil 
    end 

	self._world_hud:destroy()

	mui.deactivateScreen( self._screen )
	self._screen = nil

	self._game.layers["ceiling"]:removeProp( self.hudProp )
	self.hudProp = nil

    MOAISim.setCursor( cdefs.CURSOR_DEFAULT )
end

local function refreshTooltip( self )
	self._forceTooltipRefresh = true
end

local function onHudTooltip( self, screen, wx, wy )
	if self._world_hud._screen:getTooltip() ~= nil then
		return nil
	end

	wx, wy = screen:uiToWnd( wx, wy )
	local cellx, celly = self._game:wndToCell( wx, wy )
	local cell = cellx and celly and self._game.boardRig:getLastKnownCell( cellx, celly )

	local tooltipTxt = wx and wy and self._game:generateTooltip( wx, wy )
	if type(tooltipTxt) == "string" and #tooltipTxt > 0 then
		return tooltipTxt
	
    elseif not self:canShowElement( "tooltips" ) then
        return nil

    elseif self._state == STATE_ABILITY_TARGET or self._state == STATE_ITEM_TARGET then
        local tt = ""
		if self._stateData.targetHandler and self._stateData.targetHandler.getTooltip then
            tt = self._stateData.targetHandler:getTooltip( cellx, celly ) or ""
            if tt then
                tt = tt.."\n"
            end
        end
        return tt .. STRINGS.UI.HUD_CANCEL_TT

	elseif not cell then
		-- No cell here, no tooltip.
		self._lastTooltipCell, self._lastTooltip = nil, nil

	elseif self._lastTooltipCell == cell and not self._forceTooltipRefresh then
		-- Same cell as last update, dont recreate things.  Shiz be expensive yo!
		return self._lastTooltip

	elseif self._isMainframe then
		self._lastTooltipCell = cell
		self._lastTooltip = self._mainframe_panel:onHudTooltip( screen, cell )
		return self._lastTooltip

	else
		local tooltip = util.tooltip( self._screen )
		local selectedUnit = self:getSelectedUnit()


		-- check to see if there are any interest points here
		local player = self._game:getForeignPlayer()
		local interest = nil
		for i,unit in ipairs(player:getUnits()) do
			local sim = unit:getSim()
			if unit:getBrain() and unit:getBrain():getInterest() and unit:getBrain():getInterest().x == cell.x and unit:getBrain():getInterest().y == cell.y and 
				(sim:drawInterestPoints() or unit:getTraits().patrolObserved or unit:getBrain():getInterest().alwaysDraw) then

				if unit:isAlerted() then				
					interest = "hunting"
				else
					if interest ~= "hunting" then
						interest = "investigating"
					end
				end
		
			end				
		end
		
		-- only put the tip if needed and only 1, not one for each interest present.
		if interest then
			local section = tooltip:addSection()
				
			local line = cdefs.INTEREST_TOOLTIPS[interest].line
			local icon = cdefs.INTEREST_TOOLTIPS[interest].icon
			section:addAbility( STRINGS.UI.HUD_INTEREST_TT, line,icon )
		end

		local localPlayer = self._game:getLocalPlayer()
		local isWatched = localPlayer and simquery.isCellWatched( self._game.simCore, localPlayer, cellx, celly )

		if selectedUnit and simquery.isUnitWatched(selectedUnit) then
			tooltip:addSection():addWarning( STRINGS.UI.TRACKED, STRINGS.UI.TRACKED_TT, "gui/hud3/hud3_tracking_icon_sm.png" , cdefs.COLOR_WATCHED_BOLD  )
		end

		if isWatched == simdefs.CELL_WATCHED then
			tooltip:addSection():addWarning( STRINGS.UI.WATCHED, STRINGS.UI.WATCHED_TT, nil , cdefs.COLOR_WATCHED_BOLD )
		elseif isWatched == simdefs.CELL_NOTICED then
			tooltip:addSection():addWarning( STRINGS.UI.NOTICED, STRINGS.UI.NOTICED_TT, nil , cdefs.COLOR_NOTICED_BOLD )
		elseif isWatched == simdefs.CELL_HIDDEN then
			tooltip:addSection():addWarning( STRINGS.UI.HIDDEN, STRINGS.UI.HIDDEN_TT, nil )
		end

		if selectedUnit then

			if self._state == STATE_NULL and not selectedUnit._isPlayer then
				-- This cell has NO selectable units, and there is a unit selected.
				local x0, y0 = selectedUnit:getLocation()
				local canMove = (x0 ~= cell.x or y0 ~= cell.y) and self._revealCells ~= nil and array.find( self._revealCells, cell ) ~= nil
				if canMove then
					local section = tooltip:addSection()
					section:appendHeader( STRINGS.UI.HUD_RIGHT_CLICK, STRINGS.UI.HUD_MOVE )
				end
			end
		end
			
		if cell.units then

			local nextSelect = nil
			for i, cellUnit in ipairs( cell.units ) do
				if cellUnit:getUnitData().onWorldTooltip then
					local section = tooltip:addSection()
                    cellUnit:getUnitData().onWorldTooltip( section, cellUnit, self )

					if selectedUnit ~= cellUnit and nextSelect == nil and self._selection:canSelect( cellUnit ) then
						section:appendHeader( STRINGS.UI.HUD_LEFT_CLICK, STRINGS.UI.HUD_SELECT )
						nextSelect = cellUnit
					end
					if cellUnit:getTraits().mainframe_item then
                        local binding = util.getKeyBinding( "mainframeMode" )
                        if binding then
    						section:appendHeader( mui_util.getBindingName( binding ), STRINGS.UI.HUD_MAINFRAME )
                        end
					end
				end
			end	
		end

		self._lastTooltipCell, self._lastTooltip = cell, tooltip
		self._forceTooltipRefresh = nil

		return tooltip
	end
end


local function refreshHudValues( self )
	local pcPlayer = self._game.simCore:getPC()
	if pcPlayer then
		self._screen.binder.resourcePnl.binder.cpuNum:setText(util.sformat( STRINGS.FORMATS.PWR ,string.format("%d/%d", pcPlayer:getCpus(), pcPlayer:getMaxCpus() )))	
		self._screen.binder.resourcePnl.binder.credits:setText( util.sformat(STRINGS.FORMATS.CREDITS,tostring(pcPlayer:getCredits()) ) )
	else
		self._screen.binder.resourcePnl.binder.cpuNum:setText("-")
		self._screen.binder.resourcePnl.binder.credits:setText("???")
	end
end

function hud:refreshObjectives()
    self._objectives:refreshObjectives()
end

function hud:refreshHud()
	hideTitleSwipe( self )
    self:showShotHaze( false )
	refreshTrackerAdvance( self, self._game.simCore:getTracker() )
    self:refreshObjectives()
    self:abortChoiceDialog()

    if self._isMainframe or self._state == STATE_REPLAYING then
        showMovement( self, nil )
        clearMovementRange( self )
        self._game.boardRig:selectUnit( nil )
    else
        local selectedUnit = self._selection:getSelectedUnit()
        previewMovement( self, selectedUnit, self._tooltipX, self._tooltipY )
        self:showMovementRange( selectedUnit )
        self._game.boardRig:selectUnit( selectedUnit )
    end

	self._home_panel:refresh()
	self._mainframe_panel:refresh()
	self._agent_panel:refreshPanel()
    self._tabs:refreshAllTabs()

    local sim = self._game.simCore
	local showPanels = (sim:getCurrentPlayer() == self._game:getLocalPlayer())

	self._endTurnButton:setVisible( showPanels and self:canShowElement( "endTurnBtn" ))
	self._screen.binder.homePanel:setVisible( showPanels )
	self._screen.binder.homePanel_top:setVisible( showPanels and self._state ~= STATE_REPLAYING )
	self._screen.binder.resourcePnl:setVisible( showPanels and self:canShowElement( "resourcePnl" ))
	self._screen.binder.statsPnl:setVisible( showPanels and self:canShowElement( "statsPnl" ))
	self._screen.binder.alarm:setVisible( self:canShowElement( "alarm" ))
	self._screen.binder.mainframePnl:setVisible( showPanels )
	self._screen.binder.topPnl:setVisible( self:canShowElement( "topPnl" ))

	self._screen.binder.mainframePnl.binder.daemonPanel:setVisible( self:canShowElement( "daemonPanel" ) )

	self._screen.binder.agentPanel:setVisible( self:canShowElement( "agentPanel" ))

	local settings = savefiles.getSettings( "settings" )
	local user = savefiles.getCurrentGame()

    local canShowRewind = showPanels and (sim:getTags().rewindsLeft or 0) > 0 and not sim:getTags().isTutorial and self:canShowElement( "rewindBtn" )
    self._screen.binder.rewindBtn:setVisible( canShowRewind )                              
	local tip =	mui_tooltip( STRINGS.UI.REWIND , tostring(STRINGS.UI.REWIND_TIP .. sim:getTags().rewindsLeft) ,nil)
    self._screen.binder.rewindBtn:setTooltip(tip)

	local daysTxt = 0
	local hoursTxt = 0

	local gameModeStr = util.toupper( serverdefs.GAME_MODE_STRINGS[ self._game.params.campaignDifficulty ] )

	if self._game.params.campaignHours then
		daysTxt = math.floor( self._game.params.campaignHours / 24 ) + 1
		hoursTxt = self._game.params.campaignHours % 24
	end

	local turn = math.ceil( (sim:getTurnCount() + 1) / 2)
    local corpData = serverdefs.CORP_DATA[ self._game.params.world ]
    local situationData = serverdefs.SITUATIONS[ self._game.params.situationName ]
    if corpData and situationData then
        local missionTxt = corpData.stringTable.SHORTNAME .." " .. situationData.ui.locationName
	    self._screen.binder.statsPnl.binder.statsTxt:setText( string.format(STRINGS.UI.HUD_DAYS_TURN_ALARM, turn, daysTxt, gameModeStr, missionTxt ) )
    end

    if sim:getTags().rewindError then
        self:showRegenLevel()
    else
        self:hideRegenLevel()
    end

    if sim:getParams().missionEvents and sim:getParams().missionEvents.advancedAlarm then
    	self._screen.binder.alarm.binder.advancedAlarm:setVisible(true)
    else
    	self._screen.binder.alarm.binder.advancedAlarm:setVisible(false)
    end

	refreshHudValues( self )

	-- As the HUD can change right beneath the mouse, want to force a tooltip refresh
	refreshTooltip( self )

end

function hud:clearLOS()
	-- Boardrig has cleared all hilites, need to clear identifiers so we don't try to double unhilite.
	self._losUnits = {}
end

function hud:getTabs()
    return self._tabs
end

function hud:onSelectUnit( prevUnit, selectedUnit )
    if prevUnit then
        MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_DESELECT_UNIT )
    end

    self:refreshHud()

    self._game:dispatchScriptEvent( level.EV_UNIT_SELECTED, selectedUnit and selectedUnit:getID() )
end

function hud:getSelectedUnit()
    if self._selection:getSelectedUnit() and self._selection:getSelectedUnit():isValid() then
    	return self._selection:getSelectedUnit()
	end
end

function hud:selectUnit( unit )
    return self._selection:selectUnit( unit )
end

function hud:transitionAbilityTarget( abilityOwner, abilityUser, ability )
    if self._state == STATE_ABILITY_TARGET then
        self:transitionNull()
    elseif self._state == STATE_REPLAYING then
        return
    end

	if not ability.acquireTargets then
		agent_actions.performAbility( self._game, abilityOwner, abilityUser, ability )
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_CONFIRM )
	else
		local targetHandler = ability:acquireTargets( hudtarget, self._game, self._game.simCore, abilityOwner, abilityUser )
		if not targetHandler:hasTargets() then
			self:showWarning( STRINGS.UI.WARNING_NO_TARGETS )
		else
			local defaultTarget = targetHandler:getDefaultTarget()
			if defaultTarget and not ability.noDefaultTarget then
				agent_actions.performAbility( self._game, abilityOwner, abilityUser, ability, defaultTarget )
			else
				if ability.startTargeting then
					ability:startTargeting( hudtarget, self._game, self._game.simCore, abilityOwner, abilityUser )
				end

				transition( self, STATE_ABILITY_TARGET, { abilityOwner = abilityOwner, abilityUser = abilityUser, ability = ability, targetHandler = targetHandler } )
			end
		end
	end
end

function hud:transitionItemTarget( item, itemUser )
	local isSameItem = (self._state == STATE_ABILITY_TARGET or self._state == STATE_ITEM_TARGET) and item == self._stateData.item
    transition( self, STATE_NULL )
   	if not isSameItem then
        transition( self, STATE_ITEM_TARGET, { item = item, itemUser = itemUser } )        
    end
end

function hud:updateTooltipCell( x, y )
    if x ~= self._tooltipX or y ~= self._tooltipY then
        local selectedUnit = self:getSelectedUnit()
	    if self._state == STATE_NULL then
		    if selectedUnit and not self:isMainframe() then
			    previewMovement( self, selectedUnit, x, y )			
		    end
	    end

	    self._game.boardRig:onTooltipCell( x, y, self._tooltipX, self._tooltipY )
	    self._tooltipX, self._tooltipY = x,y

        if self._state == STATE_ITEM_TARGET then
            MOAISim.setCursor( cdefs.CURSOR_TARGET )
            
        elseif self._state == STATE_NULL and not self._bValidMovement and selectedUnit and x and y and not self:isMainframe() then
            MOAISim.setCursor( cdefs.CURSOR_CANT_MOVE )

        else
            MOAISim.setCursor( cdefs.CURSOR_DEFAULT )
        end
    end
end

local function updateIngameCursor( self, sim, localPlayer )
	if not self._hideCubeCursor and self._tooltipX then
		if not self._game.fxmgr:containsFx( self.selectFX ) then
			self.selectFX = self._game.fxmgr:addAnimFx({ x = 0, y = 0, kanim = "gui/selectioncubetest", symbol = "character", anim = "anim", loop = true, scale = 1.0 })
		end
		self.selectFX:setLoc( self._game:cellToWorld( self._tooltipX, self._tooltipY ))
        local cursorColor = util.color.GRAY
        if localPlayer then
		    local isWatched = localPlayer and simquery.isCellWatched( sim, localPlayer, self._tooltipX, self._tooltipY )
		    if isWatched == simdefs.CELL_WATCHED then
                cursorColor = cdefs.COLOR_WATCHED_BOLD
		    elseif isWatched == simdefs.CELL_NOTICED then
                cursorColor = cdefs.COLOR_NOTICED_BOLD
		    elseif isWatched == simdefs.CELL_HIDDEN then
                cursorColor = util.color.WHITE
            elseif self._revealCells then
                for _, cell in ipairs(self._revealCells) do
                    if cell.x == self._tooltipX and cell.y == self._tooltipY then
                        cursorColor = cdefs.MOVECLR_SNEAK
                        break
                    end
                end
		    end
        end
        self.selectFX:setSymbolModulate( "Cursor", cursorColor:unpack() )

	else
		if self.selectFX then
			self._game.fxmgr:removeFx( self.selectFX )
			self.selectFX = nil
		end			
	end
end

local function fadeToBlack( self )
	local screen = mui.createScreen( "screen-overlay.lua" )
	mui.activateScreen( screen )

	self._blackOverlay = screen 

	local overlay = screen:findWidget("overlay")
	overlay:setVisible(true)

	local fade_time = 2
	local t = 0
	while t < fade_time do
		t = t + 1/cdefs.SECONDS
		local percent = math.min(t / fade_time, 1)
		overlay:setColor(0, 0, 0, percent)
		coroutine.yield()
	end
end

local function updateHudTooltip( self )
	local sim = self._game.simCore
	local localPlayer = self._game:getLocalPlayer()

    updateIngameCursor( self, sim, localPlayer )

	if localPlayer and self._tooltipX and self._tooltipY then
		local tooltipCell = localPlayer:getCell( self._tooltipX, self._tooltipY )

		if tooltipCell then
			for i,unit in ipairs(tooltipCell.units) do
				if unit:hasTrait("hasSight") and self._losUnits[ unit:getID() ] == nil then
					self._losUnits[ unit:getID() ] = 0
				end
			end
		end	

		for unitID, hiliteID in pairs( self._losUnits ) do
			local unit = sim:getUnit( unitID )
			local x, y
			if unit then
				x, y = unit:getLocation()
			end
			
			if unit == nil or x ~= self._tooltipX or y ~= self._tooltipY or not inputmgr.keyIsDown( mui_defs.K_SHIFT ) then
				if hiliteID > 0 then
					self._game.boardRig:unhiliteCells( hiliteID )
				end
				self._losUnits[ unitID ] = nil

			elseif hiliteID == 0 then
				local losCoords, cells = {}, {}
				sim:getLOS():getVizCells( unit:getID(), losCoords )
				for i = 1, #losCoords, 2 do
					local x, y = losCoords[i], losCoords[i+1]
					table.insert( cells, sim:getCell( x, y ))
				end
				self._losUnits[ unitID ] = self._game.boardRig:hiliteCells( cells )
			end
		end

	else
		if self.selectFX then
			self._game.fxmgr:removeFx( self.selectFX )
			self.selectFX = nil
		end

		showMovement( self ) -- Clear
	end

	self._world_hud:refreshWidgets()
end


function hud:transferDaemonProgram( )
	local player = self._game:getLocalPlayer()
					
	local move = false
	if self._daemonCenterPanelUp.ability.duration or self._daemonCenterPanelUp.ability.ice then
		self._mainframe_panel:addMainframeProgram(  player, self._daemonCenterPanelUp.ability, self._daemonCenterPanelUp.idx)
		move = true
	end
	
	for i,abilityI in ipairs(self._mainframe_panel._installing) do
		if abilityI == self._daemonCenterPanelUp.ability then
			table.remove(self._mainframe_panel._installing,i)
			break
		end
	end
	
	return move
end

function hud:showItemsPanel( panel )
	if self._itemsPanel then
		self._itemsPanel:destroy()
	end
    self._itemsPanel = panel
	self._itemsPanel:refresh()
end

function hud:hideItemsPanel()
    if self._itemsPanel then
        self._itemsPanel:destroy()
        self._itemsPanel = nil
    end
end

function hud:showRegenLevel()
    local btn = self._screen:findWidget( "regenLevelBtn" )
    btn:setVisible( true )
    btn.onClick = util.makeDelegate( nil, onClickRegenLevel, self )
end

function hud:hideRegenLevel()
    local btn = self._screen:findWidget( "regenLevelBtn" )
    btn:setVisible( false )
    btn.onClick = nil
end

function hud:abortChoiceDialog()
	if self._choice_dialog then
    	hud._game.simCore:setChoice( simdefs.CHOICE_ABORT ) -- ABORT the choice.
		mui.deactivateScreen( self._choice_dialog )
		self._choice_dialog = nil
	end     
end

function hud:refreshTimeAttack()
	local totalTime = self._game.chessTimeTotal + self._game.chessTimer
	local hr = math.floor( totalTime / (60*60*60) )
	local min = math.floor( totalTime / (60*60) ) - hr*60
	local sec = math.floor( totalTime / 60 ) % 60

	self._screen:findWidget("totalTimer"):setText( string.format(STRINGS.UI.HUD_TOTAL_TIME, hr, min, sec) )

    local chessTimeLeft = self._game.params.difficultyOptions.timeAttack - self._game.chessTimer
	local min = math.floor( chessTimeLeft / (60*60) )
	local sec = math.floor( chessTimeLeft / 60 ) % 60

	self._screen:findWidget("timeAttackTxt"):setText( string.format( STRINGS.UI.HUD_TIME_ATTACK_TIME_LEFT, min, sec) )
	self._screen:findWidget("timeProgress"):setProgress( chessTimeLeft / self._game.params.difficultyOptions.timeAttack )

	if chessTimeLeft <= 10 * cdefs.SECONDS then
		self._screen:findWidget("timeAttackTxt"):setColor(184/255, 13/255, 13/255, 1)
		self._screen:findWidget("timeProgress"):setProgressColor(184/255, 13/255, 13/255, 1)
		if chessTimeLeft % 60 == 0 and chessTimeLeft > 0 then
			MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/button_flash" )
		end
	else
		self._screen:findWidget("timeAttackTxt"):setColor(250/255, 253/255, 104/255,1)
		self._screen:findWidget("timeProgress"):setProgressColor(250/255, 253/255, 104/255,1)
	end

    if self._pause_dialog then
        self._pause_dialog:updateHeader( string.format(STRINGS.UI.PAUSE_TOTAL_TIME, 0, min, sec) )
    end
end

function hud:updateHud()
	assert( self._game:isReplaying() == (self._state == STATE_REPLAYING) )

	if mui.wasHandled() then
		-- no In game tooltip stuff if the UI is handling events
        self:updateTooltipCell( nil, nil )
	end

    self:refreshTacticalView()

	updateHudTooltip( self )

    self._warnings:updateWarnings()

	local player = self._game:getLocalPlayer()
	if player then
		if self._blinkyCPUCount and self._isMainframe then 
			if player:getCpus() <= 0 then 
				self._blinkyCPUCount = self._blinkyCPUCount - 1 

				if self._blinkyCPUCount < 1 then 
					if self._blinkyCPU_showOff then 
						self._screen.binder.resourcePnl.binder.cpuNum:setColor(1, 0, 0, 1)	
						self._blinkyCPU_showOff = nil
						self._blinkyCPUCount = 20
					else 
						self._screen.binder.resourcePnl.binder.cpuNum:setColor(140/255,255/255,255/255,1)	
						self._blinkyCPU_showOff = true
						self._blinkyCPUCount = 20
					end
				end
			end
		end

		if self._isMainframe == false or player:getCpus() >= 1 then 
			self._screen.binder.resourcePnl.binder.cpuNum:setColor(140/255,255/255,255/255,1)
		end
	end

	self._missionPanel:onUpdate()

	if self._game.chessTimer then
        self:refreshTimeAttack()
    end
end

function hud:onHudDraw()
	if self._state == STATE_ABILITY_TARGET or self._state == STATE_ITEM_TARGET then
		if self._stateData.targetHandler and self._stateData.targetHandler.onDraw then
			self._stateData.targetHandler:onDraw()
		end
	end
end

function hud:hideInterface()
	self._world_hud:hide()
	self._screen:setVisible(false)
	self.hide_interface = true
	self._selection:selectUnit( nil )
end
function hud:showInterface()
	self._world_hud:show()
	self._screen:setVisible(true)
	self.hide_interface = false
	self._selection:selectInitialUnit()
end

function hud:onSimEvent( ev )

	local sim = self._game.simCore
	local simdefs = sim.getDefs()

	if ev.eventType == simdefs.EV_HIDE_PROGRAM or ev.eventType == simdefs.EV_SLIDE_IN_PROGRAM then 
		self._mainframe_panel:onSimEvent( ev )
	end 

	local mfMode = checkForMainframeEvent( simdefs, ev.eventType, ev.eventData )
	if mfMode == SHOW_MAINFRAME then
		if not self._isMainframe then
			self:showMainframe()
		end
		self._mainframe_panel:onSimEvent( ev )

	elseif mfMode == HIDE_MAINFRAME and self._isMainframe then
		self:hideMainframe()
	end

	if ev.eventType == simdefs.EV_HUD_REFRESH then
		self:refreshHud()

	elseif ev.eventType == simdefs.EV_UNIT_DRAG_BODY or ev.eventType == simdefs.EV_UNIT_DROP_BODY then
		self._home_panel:refreshAgent( ev.eventData.unit )

	elseif ev.eventType == simdefs.EV_TURN_START then
		--self:refreshHud()
		local currentPlayer = self._game.simCore:getCurrentPlayer()

		self._game.boardRig:onStartTurn( currentPlayer and currentPlayer:isPC() )

		if currentPlayer ~= nil then
			if currentPlayer ~= self._game:getLocalPlayer() then
				self._oldPlayerMainframeState = self._isMainframe
			end

			self:refreshHud()			

			local txt, color, sound
			local corpTurn = false
			if currentPlayer:isNPC() then
				txt = STRINGS.UI.ENEMY_ACTIVITY
				color = {r=1,g=0,b=0,a=1}
				sound = cdefs.SOUND_HUD_GAME_ACTIVITY_CORP		
				corpTurn = true
			else
				txt = STRINGS.UI.AGENT_ACTIVITY
				color = {r=140/255,g=255/255 ,b=255/255,a=1}
				sound = cdefs.SOUND_HUD_GAME_ACTIVITY_AGENT
			end

			local turn = math.ceil( (sim:getTurnCount() + 1) / 2)

			startTitleSwipe( self, txt,color,sound, corpTurn, turn)
			rig_util.wait(30)		
			stopTitleSwipe( self )
		end
        local selectedUnit = self:getSelectedUnit()
        if selectedUnit and selectedUnit:isValid() then
            self._game:getCamera():fitOnscreen( self._game:cellToWorld( selectedUnit:getLocation() ) )
        end
	
	elseif ev.eventType == simdefs.EV_WAIT_DELAY then
		rig_util.wait( ev.eventData )
	
	elseif ev.eventType == simdefs.EV_TURN_END then		
        self:hideItemsPanel()
		if ev.eventData and not ev.eventData:isNPC() then
			stopTitleSwipe( self )
		end

	elseif ev.eventType == simdefs.EV_ADVANCE_TRACKER then

		if  ev.eventData.alarmOnly or (ev.eventData.tracker + ev.eventData.delta >= simdefs.TRACKER_MAXCOUNT) then			
		--	self._game.post_process:colorCubeLerp( "data/images/cc/cc_default.png", "data/images/cc/screen_shot_out_test1_cc.png", 1.0, MOAITimer.PING_PONG, 0,0.5 )			
			if not self._playingAlarmLoop then
				MOAIFmodDesigner.playSound(  "SpySociety/HUD/gameplay/alarm_LP","alarm")
				self._playingAlarmLoop = true
			end
		end
		if not ev.eventData.alarmOnly then
			runTrackerAdvance( self, ev.eventData.txt, ev.eventData.delta, ev.eventData.tracker, ev.eventData.subtxt)
		end

    elseif ev.eventType == "used_radio" then
        local stage = self._game.simCore:getTrackerStage( ev.eventData.tracker )
        refreshTrackerMusic( self, stage )

	elseif ev.eventType == simdefs.EV_LOOT_ACQUIRED and not ev.eventData.silent then
		if not self._game.debugStep then
			self._game.viz:addThread( modal_thread.programDialog( self._game.viz, 
				STRINGS.UI.LOOT_MODAL_TITLE, 
				util.toupper(ev.eventData.lootUnit:getName()), 
				util.sformat( STRINGS.UI.LOOT_MODAL1, ev.eventData.lootUnit:getName(), ev.eventData.unit:getName() ),
				ev.eventData.icon ) )
		end

	elseif ev.eventType == simdefs.EV_PUSH_QUIET_MIX then 
		--play stinger to hide the new music
		MOAIFmodDesigner.playSound("SpySociety/Music/stinger_finalroom")
		FMODMixer:pushMix( "nomusic" )
		MOAIFmodDesigner.playSound("SpySociety/AMB/finalroom", "AMB3")

	elseif ev.eventType == simdefs.EV_FADE_TO_BLACK then 
		fadeToBlack( self )

	elseif ev.eventType == simdefs.EV_CREDITS_REFRESH then
		refreshHudValues( self )

	elseif ev.eventType == simdefs.EV_SHORT_WALLS then 
		if not self._isShortWall then 
			self:setShortWalls( true )
		end

	elseif ev.eventType == simdefs.EV_GRAFTER_DIALOG then
		return showGrafterDialog( self, ev.eventData.itemDef, ev.eventData.userUnit, ev.eventData.drill )

	elseif ev.eventType == simdefs.EV_INSTALL_AUGMENT_DIALOG then
		return showInstallAugmentDialog( self, ev.eventData.item, ev.eventData.unit )

	elseif ev.eventType == simdefs.EV_EXEC_DIALOG then
		return showExecDialog( self, ev.eventData.headerTxt, ev.eventData.bodyTxt, ev.eventData.options, ev.eventData.corps, ev.eventData.names )

	elseif ev.eventType == simdefs.EV_ITEMS_PANEL then
		if ev.eventData then
			if ev.eventData.shopUnit then
                local shop_panel = include( "hud/shop_panel" )
				if ev.eventData.shopUnit:getTraits().storeType=="server" then
					self:showItemsPanel( shop_panel.server( self, ev.eventData.shopperUnit, ev.eventData.shopUnit ))
				elseif ev.eventData.shopUnit:getTraits().storeType=="miniserver" then
					self:showItemsPanel( shop_panel.server( self, ev.eventData.shopperUnit, ev.eventData.shopUnit, STRINGS.UI.SHOP_MINISERVER, true))
				else
					self:showItemsPanel( shop_panel.shop( self, ev.eventData.shopperUnit, ev.eventData.shopUnit ))
				end
            else
                local items_panel = include( "hud/items_panel" )
			    if ev.eventData.targetUnit then
				    self:showItemsPanel( items_panel.loot( self, ev.eventData.unit, ev.eventData.targetUnit ))
			    else
				    self:showItemsPanel( items_panel.pickup( self, ev.eventData.unit, ev.eventData.x, ev.eventData.y ))
			    end
            end

		elseif self._itemsPanel then
			self._itemsPanel:refresh()
		end

	elseif ev.eventType == simdefs.EV_CMD_DIALOG then
		console_panel.panel( self, ev.eventData )
		
	elseif ev.eventType == simdefs.EV_AGENT_LIMIT then
		if not self._game.debugStep then
			modalDialog.show( STRINGS.UI.WARNING_MAX_AGENTS )
		end

	elseif ev.eventType == simdefs.EV_UNIT_FLY_TXT then
		if ev.eventData.unit and not ev.eventData.x and not ev.eventData.x then
			ev.eventData.x, ev.eventData.y = ev.eventData.unit:getLocation()
		end
		local wx, wy = self._game:cellToWorld(  ev.eventData.x, ev.eventData.y )
		local color =  ev.eventData.color
		local txt = ev.eventData.txt	
		local target = ev.eventData.target	
		local sound = ev.eventData.sound
		local soundDelay = ev.eventData.soundDelay
		self:showFlyText(wx, wy, txt, color, target, sound, soundDelay)

	elseif ev.eventType == simdefs.EV_FLY_IMAGE then

		if ev.eventData.unit and not ev.eventData.x and not ev.eventData.x then
			ev.eventData.x, ev.eventData.y = ev.eventData.unit:getLocation()
		end
		local wx, wy = self._game:cellToWorld(  ev.eventData.x, ev.eventData.y )			
		self:showFlyImage(wx, wy,"agent1", eventData.duration)		

	elseif ev.eventType == simdefs.EV_HUD_SUBTRACT_CPU then
		self:subtractCPU( ev.eventData.delta)

	elseif ev.eventType == simdefs.EV_SKILL_LEVELED then
		if self._itemsPanel then
			 self._itemsPanel:refresh()
		end
	elseif ev.eventType == simdefs.EV_SET_MUSIC_PARAM then
		MOAIFmodDesigner.setMusicProperty(ev.eventData.param,ev.eventData.value)

	elseif ev.eventType == simdefs.EV_UNIT_TAB then
        self._tabs:refreshUnitTab( ev.eventData )

	elseif ev.eventType == simdefs.EV_UNIT_OBSERVED then
		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/observe_guard")	
        self._tabs:refreshUnitTab( ev.eventData )

	    local reveal_path = include( "gameplay/viz_handlers/reveal_path" )
	    self._game.viz:addThread( reveal_path( self._game.boardRig, ev.eventData:getID(), ev ) )

	elseif ev.eventType == simdefs.EV_SHOW_MODAL then
		local result = modalDialog.show(  ev.eventData.txt, ev.eventData.header)

	elseif ev.eventType == simdefs.EV_BLINK_REWIND then
		local widget = self._screen.binder.rewindBtn
		local boardrig = self._game.boardRig
		local blinkFunction = function()
		    widget:blink(0.2, 2, 2)
		    boardrig:wait( 6*cdefs.SECONDS ) 
		    widget:blink()
		end
		self._screen.binder.rewindBtn:onUpdate( blinkFunction )
	end
end

function hud:handleEvent( ev )
	if ev.eventType == mui_defs.EVENT_LostTopMost then
        MOAISim.setCursor( cdefs.CURSOR_DEFAULT )
    end
end

function hud:onInputEvent( event )
	local sim = self._game.simCore
	if self.hide_interface then return end

	if self._state == STATE_ABILITY_TARGET then
		if isCancelEvent( event ) then
			transition( self, STATE_NULL )
			return true
		
		elseif self._stateData.targetHandler then
			local target = self._stateData.targetHandler:onInputEvent( event )
			if target then
				agent_actions.performAbility( self._game, self._stateData.abilityOwner, self._stateData.abilityUser, self._stateData.ability, target )
				return true
			end
		end
		
	elseif self._state == STATE_ITEM_TARGET then
		if isCancelEvent( event ) then
			transition( self, STATE_NULL )
			return true

		elseif self._stateData.targetHandler and self._stateData.targetHandler.onInputEvent then
			local target = self._stateData.targetHandler:onInputEvent( event )
			if target then
				agent_actions.performAbility( self._game, self._stateData.item, self._stateData.itemUser, self._stateData.ability, target )
				return true
			end
		end

	elseif self._isMainframe then
		if event.eventType == mui_defs.EVENT_KeyDown then
			if mui_util.isBinding( event, util.getKeyBinding( "cycleSelection" )) then
                self:hideMainframe()
			end
		end		
	
	elseif self._state == STATE_NULL then
        if event.eventType == mui_defs.EVENT_MouseDown then
            self._mouseDownX, self._mouseDownY = event.wx, event.wy

		elseif event.eventType == mui_defs.EVENT_MouseUp then
			if event.button == mui_defs.MB_Left then
                if self._mouseDownX and mathutil.distSqr2d( event.wx, event.wy, self._mouseDownX, self._mouseDownY ) < 512 then
				    local cellx, celly = self._game:wndToCell( event.wx, event.wy )
                    self._selection:selectUnitAtCell( cellx, celly )
                end

			elseif event.button == mui_defs.MB_Right then
				local cellx, celly = self._game:wndToCell( event.wx, event.wy )
				local unit = self:getSelectedUnit()
				if unit then
					if cellx and doMoveUnit( self, unit, cellx, celly ) then
						MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_CLICK )
					end
					return true		
				end
			end

		elseif event.eventType == mui_defs.EVENT_KeyDown then
			if mui_util.isBinding( event, util.getKeyBinding( "cycleSelection" )) then
                self._selection:selectNextUnit()
			end
		end

	elseif self._state == STATE_REPLAYING then
		if config.DEV and event.eventType == mui_defs.EVENT_KeyDown and mui_util.isBinding( event, util.getKeyBinding( "cycleSelection" )) then
			self._game:skip()
            self._selection:selectInitialUnit()
		end
	end

	if self._state == STATE_NULL and event.eventType == mui_defs.EVENT_MouseMove then
		local x, y = self._game:wndToSubCell( event.wx, event.wy )
        x, y = math.floor( x ), math.floor( y )
        self:updateTooltipCell( x, y )
	end

	-- Cancel
	if self._state ~= STATE_NULL and self._state ~= STATE_REPLAYING then
		if (event.eventType == mui_defs.EVENT_KeyDown and util.isKeyBindingEvent( "pause", event )) then
			transition( self, STATE_NULL )	
			showMovement( self, nil )
		end
	end

	if self._game:getCamera():onInputEvent( event ) then
		return true	
	end

	return false
end

function hud:transitionNull()
	transition( self, STATE_NULL )
end

function hud:transitionReplay( replay )
	--self._screen:setEnabled( not replay )
	if self._itemsPanel then
		self._itemsPanel._screen:setEnabled( not replay )
	end

	if replay then
		if self._state ~= STATE_REPLAYING then
			assert( self._state )
			transition( self, STATE_REPLAYING, { prevState = self._state, prevData = self._stateData })
            self:updateTooltipCell( nil, nil )
            self:refreshTacticalView()
		end
	else
		if self._state == STATE_REPLAYING then
			transition( self, self._stateData.prevState, self._stateData.prevData )
			if not self.hide_interface then
            	self._selection:selectInitialUnit()
            end
		    local x, y = self._game:wndToSubCell( inputmgr.getMouseXY() )
            self:updateTooltipCell( math.floor( x ), math.floor( y ) )
		end
	end
end

function hud:explainDaemons()
	local settings = savefiles.getSettings( "settings" )
	if not settings.data.seenDaemon then
		settings.data.seenDaemon = true
		settings:save()
		self:showMainframe()
		MOAICoroutine.new():run( function() modalDialog.showDaemonDialog() end )
    end
end

function hud:init( game )
    self.STATE_NULL = STATE_NULL
	self.STATE_ABILITY_TARGET = STATE_ABILITY_TARGET
	self.STATE_ITEM_TARGET = STATE_ITEM_TARGET
	self.STATE_REPLAYING = STATE_REPLAYING

    self._game = game

    self._state = STATE_NULL
    self._stateData = nil
    self._isMainframe = false
    self._movePreview = nil
    self._oldPlayerMainframeState = nil
    self._abilityPreview = false

    self._losUnits = {}

    self._selection = include( "hud/selection" )( self )
    self._world_hud = world_hud( game )

	self._screen = mui.createScreen( "hud.lua" )
	self._screen.onTooltip = util.makeDelegate( nil, onHudTooltip, self )
	
	self._agent_panel = agent_panel.agent_panel( self, self._screen )
	self._home_panel = home_panel.panel( self._screen, self )
    self._warnings = include( "hud/hud_warnings" )( self )
    self._tabs = include( "hud/hud_tabs")( self )
    self._objectives = include( "hud/hud_objectives" )( self )

	do
		local mainframe_panel = include( "hud/mainframe_panel" )
		self._mainframe_panel = mainframe_panel.panel( self._screen, self )
	end

	self._pause_dialog = pause_dialog( game )

	self._endTurnButton = self._screen.binder.endTurnBtn
	self._endTurnButton.onClick = util.makeDelegate(nil, onClickEndTurn, self)

	self._uploadGroup = self._screen.binder.upload_bar 
	
	self._screen.binder.menuBtn.onClick = util.makeDelegate( nil, onClickMenu, self )

	self._screen.binder.topPnl.binder.watermark:setText( config.WATERMARK )
	self._statusLabel = self._screen.binder.statusTxt
	self._tooltipLabel = self._screen.binder.tooltipTxt
	self._tooltipBg = self._screen.binder.tooltipBg

	self._screen.binder.warning:setVisible(false)

	local w,h = game:getWorldSize()
	local scriptDeck = MOAIScriptDeck.new ()
	scriptDeck:setRect ( -w/2, -h/2, w/2, h/2 )
	scriptDeck:setDrawCallback ( 
		function( index, xOff, yOff, xFlip, yFlip )
			self:onHudDraw()
		end )

	self.hudProp = MOAIProp2D.new ()
	self.hudProp:setDeck ( scriptDeck )
	self.hudProp:setPriority( 1 ) -- above the board, below everything else
	game.layers["ceiling"]:insertProp ( self.hudProp )
	
	self._screen.binder.alarm.binder.alarmRing1:setVisible( false )
	self._screen.binder.alarm.binder.alarmRing1:setColor( 1, 0, 0, 1 ) 
	
    -- Time attack enabled!
    if (game.params.difficultyOptions.timeAttack or 0) > 0 then
    	self._screen:findWidget("timeProgress"):setVisible(true)
	    self._screen:findWidget("totalTimer"):setVisible(true)
	    self._screen:findWidget("timeAttackTxt"):setVisible(true)
    end

	self._screen.binder.topPnl.binder.btnToggleWalls.onClick = util.makeDelegate( nil, onClickWallsButton, self )
	self._screen.binder.topPnl.binder.btnRotateLeft.onClick = util.makeDelegate( nil, onClickRotateCamera, self, -1 )
	self._screen.binder.topPnl.binder.btnRotateRight.onClick = util.makeDelegate( nil, onClickRotateCamera, self, 1 )
    self._screen.binder.rewindBtn.onClick = util.makeDelegate( nil, onClickRewindGame, self )

	local camera = game:getCamera()

	mui.activateScreen( self._screen )
    self._screen:addEventHandler( self, mui_defs.EVENT_LostTopMost )

	self:refreshHud()
		
	local mission_panel = include( "hud/mission_panel" )
	self._missionPanel = mission_panel( self, self._screen )

	self._blinkyCPUCount = 30 
	MOAIFmodDesigner.setAmbientReverb( "office" )
end

local function createHud( ... )
    return hud( ... )
end

return
{
	createHud = createHud
}



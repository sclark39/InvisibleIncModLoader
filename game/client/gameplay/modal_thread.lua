----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local array = include( "modules/array" )
local cdefs = include( "client_defs" )
local simdefs = include( "sim/simdefs" )
local viz_thread = include( "gameplay/viz_thread" )
local modalDialog = include( "states/state-modal-dialog" )
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local guiex = include( "guiex" )
local rig_util = include( "gameplay/rig_util" )

---------------------------------------------------------------------------
-- Local functions

local function checkAutoClose( modal, game )
    if game.chessTimer and game.chessTimer >= game.params.difficultyOptions.timeAttack then
        -- Time has expired.
        return modalDialog.CANCEL

    elseif game.chessTimer == 0 then
        -- NPC's turn; modals shouldnt be allowed to last forever, so time them out.
        modal.autoCloseTimer = (modal.autoCloseTimer or (3 * cdefs.SECONDS)) - 1
        if modal.autoCloseTimer <= 0 then
            modal.autoCloseTimer = nil
            return modalDialog.CANCEL
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- Base class modal thread invoking a viz dialog

local modal_thread = class( viz_thread )

function modal_thread:init( viz, screen )
    viz_thread.init( self, viz, self.onResume )
	viz:registerHandler( simdefs.EV_FRAME_UPDATE, self )
    self.screen = screen
end

function modal_thread:onStop()
    if self.screen then
        mui.deactivateScreen( self.screen )
        self.screen = nil
    end
end

function modal_thread:onResume( ev )
    self:waitForLocks( 'modal' )

    mui.activateScreen( self.screen )

	while self.result == nil do
        self:yield()
	end

	return self.result
end

function modal_thread:yield()
    coroutine.yield()
    self.result = self.result or checkAutoClose( self, self.viz.game )
end

---------------------------------------------------------------------------
-- Base class modal thread invoking a viz dialog

local alarmDialog = class( modal_thread )

function alarmDialog:init( viz, txt,txt2, alarmStage )
    local screen = mui.createScreen( "modal-alarm.lua" )
	screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
	screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() self.result = modalDialog.CANCEL end
	screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )

	screen.binder.pnl.binder.title.binder.titleTxt:setText( STRINGS.UI.ALARM_INSTALL )
	screen.binder.pnl.binder.title.binder.titleTxt2:setText( txt )
	screen.binder.pnl.binder.bodyTxt:setText( txt2 )

	screen.binder.pnl.binder.num:setText( alarmStage )

	local color = cdefs.TRACKER_COLOURS[alarmStage+1]
	screen.binder.pnl.binder.circle:setColor(color.r,color.g,color.b,1)
	screen.binder.pnl.binder.num:setColor(color.r,color.g,color.b,1)
	screen.binder.pnl.binder.headerbox:setColor(color.r,color.g,color.b,1)
	screen.binder.pnl.binder.bodyTxt:setColor(color.r,color.g,color.b,1)

    modal_thread.init( self, viz, screen )
end

local rewindSuggestDialog = class( modal_thread )

function rewindSuggestDialog:init( viz, hud, numRewinds )
    local screen = mui.createScreen( "modal-rewind.lua" )
    local ok = screen:findWidget("okBtn")
	local cancel = screen:findWidget("cancelBtn")

    self.game = hud._game
	ok.binder.btn.onClick = function() self:onClickOk() end
	ok.binder.btn:setText(STRINGS.UI.REWIND_CONFIRM)
		
	cancel.binder.btn.onClick = util.makeDelegate( nil, function() self.result = modalDialog.CANCEL end )
    cancel.binder.btn:setText(STRINGS.UI.REWIND_GAME_OVER)
	cancel.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
		                 
    screen.binder.bodyTxt:setText( STRINGS.UI.REWIND_SUGGEST )
    screen.binder.title.binder.titleTxt2:setText( util.sformat(STRINGS.UI.REWINDS_REMAINING, numRewinds) )

    modal_thread.init( self, viz, screen )
end

function rewindSuggestDialog:onClickOk()
    self.result = modalDialog.OK
    inputmgr.setInputEnabled(false)

    KLEIRenderScene:setDesaturation( rig_util.linearEase("desat_ease") )
    MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/HUD_undoAction" )

    rig_util.wait( 30 )
    inputmgr.setInputEnabled(true)
    self.game:rewindTurns()
    KLEIRenderScene:setDesaturation( )
end

function rewindSuggestDialog:yield()
    coroutine.yield() -- Do not autoclose this dialog.
end


local rewindDialog = class( modal_thread )

function rewindDialog:init( viz, hud )
	local screen = mui.createScreen( "modal-rewind-tutorial.lua" )
	screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
	screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )
	screen.binder.pnl.binder.okBtn.binder.btn.onClick =
	    function()
	        self.result = modalDialog.CANCEL
			local widget = hud._screen:findWidget("rewindBtn")
	        widget:setVisible( true )
	        widget:blink(0.2, 2, 2)

	        self:waitFrames( 6*cdefs.SECONDS ) 

	        widget:blink()
	    end

	modal_thread.init( self, viz, screen )
end

local programDialog = class( modal_thread )

function programDialog:init( viz, txt1,txt2,txt3,icon,color )
    local screen = mui.createScreen( "modal-program.lua" )

	screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
	screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() self.result = modalDialog.CANCEL end
	screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )

	screen.binder.pnl.binder.title.binder.titleTxt:setText( txt1 )
	screen.binder.pnl.binder.title.binder.titleTxt2:setText( txt2 )
	screen.binder.pnl.binder.bodyTxt:setText( txt3 )	
	screen.binder.pnl.binder.icon:setImage(icon)
	if not color then
		color = {r=140/255,g=255/255,b=255/255,a=1}
	end
	screen.binder.pnl.binder.headerbox:setColor(color.r,color.g,color.b,1)
	screen.binder.pnl.binder.bodyTxt:setColor(color.r,color.g,color.b,1)

    modal_thread.init( self, viz, screen )
end

local daemonDialog = class( modal_thread )

function daemonDialog:init( viz, daemonName, daemonBodyTxt, icon )
	local screen = mui.createScreen( "modal-daemon.lua" )

	screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
	screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() self.result = modalDialog.OK end
	screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )

	screen.binder.pnl.binder.title.binder.titleTxt:setVisible(false)
	screen.binder.pnl.binder.title.binder.titleTxt2:setVisible(false)
	screen.binder.pnl.binder.bodyTxt:setVisible(false)
	screen.binder.pnl.binder.progress:setVisible(false)

	screen.binder.pnl.binder.icon:setImage(icon)

    self.daemonName = daemonName
    self.daemonBodyTxt = daemonBodyTxt

    modal_thread.init( self, viz, screen )
end

local cooldownDialog = class( modal_thread )

function cooldownDialog:init( viz  )
	local screen = mui.createScreen( "modal-cooldown.lua" )

	screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
	screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() self.result = modalDialog.OK end
	screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )

    modal_thread.init( self, viz, screen )
end

function daemonDialog:onResume()
    self:waitForLocks( 'modal' )

    local screen = self.screen
    mui.activateScreen( screen )

    self:waitFrames( 0.2*cdefs.SECONDS )
	screen.binder.pnl.binder.title.binder.titleTxt:setVisible(true)
	screen.binder.pnl.binder.title.binder.titleTxt2:setVisible(true)
	screen.binder.pnl.binder.title.binder.titleTxt:setText( string.format( STRINGS.DAEMONS.DAEMON_PNL_TITLE ) )
	screen.binder.pnl.binder.title.binder.titleTxt2:spoolText( string.format( STRINGS.DAEMONS.WARNING_TITLE, self.daemonName ) )
	
    self:waitFrames( 0.2*cdefs.SECONDS )
	screen.binder.pnl.binder.bodyTxt:setVisible(true)
	screen.binder.pnl.binder.bodyTxt:spoolText( self.daemonBodyTxt )

    self:waitFrames( 0.2*cdefs.SECONDS )
	screen.binder.pnl.binder.progress:setVisible(true)

    local val = 0
	while self.result == nil do
        if val <= 1 then
		    screen.binder.pnl.binder.progress:setProgress( val )	
		    val = math.min(1, val + .02)
        end

        self:yield()
	end

	return self.result
end

local reverseDaemonDialog = class( modal_thread )

function reverseDaemonDialog:init( viz, daemonName, daemonBodyTxt, icon, title )
	local screen = mui.createScreen( "modal-daemon.lua" )

	screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
	screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() self.result = modalDialog.OK end
	screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )

	screen.binder.pnl.binder.title.binder.titleTxt:setVisible(false)
	screen.binder.pnl.binder.title.binder.titleTxt2:setVisible(false)
	screen.binder.pnl.binder.bodyTxt:setVisible(false)
	screen.binder.pnl.binder.progress:setVisible(false)

	screen.binder.pnl.binder["header box"]:setColor( 0/255, 200/255, 0/255, 1 )
	screen.binder.pnl.binder["iconBG"]:setColor( 0/255, 200/255, 0/255, 1 )
	
	screen.binder.pnl.binder.bodyTxt:setColor( 0/255, 200/255, 0/255, 1 )
	screen.binder.pnl.binder.caution:setImage( "gui/hud3/tutorial_useIncognita.png" )

	screen.binder.pnl.binder.progress:setBGColor( 0/255, 50/255, 0/255, 1 )
	screen.binder.pnl.binder.progress:setProgressColor( 0/255, 255/255, 0/255, 1 )

	screen.binder.pnl.binder.icon:setImage(icon)

    self.daemonName = daemonName
    self.daemonBodyTxt = daemonBodyTxt
    self.titleTxt = title

    modal_thread.init( self, viz, screen )
end

function reverseDaemonDialog:onResume()
    self:waitForLocks( 'modal' )

    local screen = self.screen
    mui.activateScreen( screen )

    self:waitFrames( 0.2*cdefs.SECONDS )
	screen.binder.pnl.binder.title.binder.titleTxt:setVisible(true)
	screen.binder.pnl.binder.title.binder.titleTxt2:setVisible(true)
	if self.titleTxt then
		screen.binder.pnl.binder.title.binder.titleTxt:setText( string.format( self.titleTxt ) )
	else
		screen.binder.pnl.binder.title.binder.titleTxt:setText( string.format( STRINGS.REVERSE_DAEMONS.REVERSE_PNL_TITLE ) )
	end
	screen.binder.pnl.binder.title.binder.titleTxt2:spoolText( string.format( STRINGS.REVERSE_DAEMONS.WARNING_TITLE, self.daemonName ) )
	
    self:waitFrames( 0.2*cdefs.SECONDS )
	screen.binder.pnl.binder.bodyTxt:setVisible(true)
	screen.binder.pnl.binder.bodyTxt:spoolText( self.daemonBodyTxt )

    self:waitFrames( 0.2*cdefs.SECONDS )
	screen.binder.pnl.binder.progress:setVisible(true)

    MOAICoroutine.new():run(function() 
        rig_util.wait( .5 * cdefs.SECONDS)
        MOAIFmodDesigner.playSound( "SpySociety/VoiceOver/Incognita/Pickups/Daemon_Reversal" )
    end)
    

    local val = 0
	while self.result == nil do
        if val <= 1 then
		    screen.binder.pnl.binder.progress:setProgress( val )	
		    val = math.min(1, val + .02)
        end

        self:yield()
	end

    self:waitFrames( 0.5*cdefs.SECONDS )

	return self.result
end

---------------------------------------------------------------------------
-- Generic dialog with body and text

local messageDialog = class( modal_thread )

function messageDialog:init( viz, headerTxt, bodyTxt )
	local screen = mui.createScreen( "modal-dialog.lua" )

    screen:findWidget( "headerTxt" ):setText( headerTxt )
    screen:findWidget( "bodyTxt" ):setText( bodyTxt )
	screen:findWidget( "okBtn" ).onClick = function() self.result = modalDialog.OK end
	screen:findWidget( "cancelBtn" ):setVisible( false )

    modal_thread.init( self, viz, screen )
end

---------------------------------------------------------------------------
-- General dialog -- pass in the screen name.

local generalDialog = class( modal_thread )

function generalDialog:init( viz, dialogName )
	local screen = mui.createScreen( dialogName )

	screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
	screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() self.result = modalDialog.OK end
	screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )

    modal_thread.init( self, viz, screen )
end

---------------------------------------------------------------------------
-- Threat dialog

local threatDialog = class( modal_thread )

function threatDialog:init( viz, unit, pan )
	local x, y = unit:getLocation()
	viz.game:cameraPanToCell( x, y )
	viz.game:getCamera():zoomTo( 0.3 )

	local screen = mui.createScreen( "modal-newthreat.lua" )
	mui.activateScreen( screen )

	screen.binder.pnl:createTransition( "activate_left" )

	screen.binder.pnl.binder.portrait:bindBuild( unit:getUnitData().profile_build or unit:getUnitData().profile_anim )
	screen.binder.pnl.binder.portrait:bindAnim( unit:getUnitData().profile_anim )
	screen.binder.pnl.binder.portrait:setVisible(true)

	local corp = viz.game.simCore:getParams().world
    local serverdefs = include( "modules/serverdefs" )

	screen.binder.pnl.binder.corpIcon:setImage( serverdefs.CORP_DATA[ corp ].imgs.logoLarge )
	screen.binder.pnl.binder.bodyTxt:setText( unit:getName() )

    modal_thread.init( self, viz, screen )
end 

function threatDialog:onResume()
    self:waitForLocks( 'modal' )

    mui.activateScreen( self.screen )

    local screen = self.screen
    local val = 0
	while val < 1 do
        if val <= 1 then
		    val = math.min(1, val + .02)
		    screen.binder.pnl.binder.progress:setProgress( val )	
        end

        self:yield()
	end

    rig_util.wait( 50 )

    return modalDialog.OK
end

---------------------------------------------------------------------------
-- location detected dialog

local locationDetectedDialog = class( modal_thread )

function locationDetectedDialog:init( viz, unit, pan )
	local x, y = unit:getLocation()
	viz.game:cameraPanToCell( x, y )
	viz.game:getCamera():zoomTo( 0.3 )

	local screen = mui.createScreen( "modal-locationdetected.lua" )
	mui.activateScreen( screen )

	screen.binder.pnl:createTransition( "activate_left" )

	screen.binder.pnl.binder.portrait:bindBuild( unit:getUnitData().profile_build or unit:getUnitData().profile_anim )
	screen.binder.pnl.binder.portrait:bindAnim( unit:getUnitData().profile_anim )
	screen.binder.pnl.binder.portrait:setVisible(true)

	screen.binder.pnl.binder.bodyTxt:setText( unit:getName() )

    modal_thread.init( self, viz, screen )
end 

function locationDetectedDialog:onResume()
    self:waitForLocks( 'modal' )

    mui.activateScreen( self.screen )

    local screen = self.screen
    local val = 0
	while val < 1 do
        if val <= 1 then
		    val = math.min(1, val + .02)
		    screen.binder.pnl.binder.progress:setProgress( val )	
        end

        self:yield()
	end

    rig_util.wait( 50 )

    return modalDialog.OK
end

return
{
    checkAutoClose = checkAutoClose,

    alarmDialog = alarmDialog,
    programDialog = programDialog,
    rewindSuggestDialog = rewindSuggestDialog,
    rewindDialog = rewindDialog,
    daemonDialog = daemonDialog,
    reverseDaemonDialog = reverseDaemonDialog,
    threatDialog = threatDialog,
    generalDialog = generalDialog,
    messageDialog = messageDialog,
    locationDetectedDialog = locationDetectedDialog,
    cooldownDialog = cooldownDialog,
}

----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include("client_util")
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local modalDialog = include( "states/state-modal-dialog" )
local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )

----------------------------------------------------------------

local TUTORIALS = 
{
	{ name=STRINGS.TUTORIAL_DIALOGS.TURN_BASED, dialog = modalDialog.showTurnbaseDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.PEEK_AROUND_DOORS, dialog = modalDialog.showPeekOpenPeekDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.PEEK_AROUND_CORNERS, dialog = modalDialog.showCornerPeekDialog},
	--{ name=TUTORIAL_DIALOGS.INCOGNITA, dialog = modalDialog.showIncognitaDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.LOCKPICK, dialog = modalDialog.showLockpickDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.GUARD_BLIND_SPOTS, dialog = modalDialog.showBlindSpots},
	{ name=STRINGS.TUTORIAL_DIALOGS.MANIPULATE_GUARDS, dialog = modalDialog.showManipulateDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.ALARM, dialog = modalDialog.showAlarmFirstDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.TACTICAL_VIEW, dialog = modalDialog.showTacticalViewDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.REWINDS, dialog = modalDialog.showRewindTutorialDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.DAEMONS, dialog = modalDialog.showDaemonDialog},	
	{ name=STRINGS.TUTORIAL_DIALOGS.PINNING, dialog = modalDialog.showPinningDialog},
	{ name=STRINGS.TUTORIAL_DIALOGS.COOLDOWN, dialog = modalDialog.showCooldownDialog},	
}

----------------------------------------------------------------

local dialog = class()

local function onClickClose(self)
    self:destroy()
end

function dialog:init()
    self.modalControl = modalDialog.modalControl()
end

function dialog:show()

	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	local screen = mui.createScreen( "modal-tutorials.lua" )
    self.screen = screen
	mui.activateScreen( screen )

	local pnl = screen:findWidget("panel")

	for i, widget in pnl.binder:forEach( "tutorial" ) do
		widget.binder.btn:setVisible(false)
	end

	for i, v in ipairs(TUTORIALS) do
		local widget = screen:findWidget("tutorial"..i..".btn")		
		widget:setText( v.name )
		widget:setVisible(true)
		widget.onClick = util.makeDelegate( nil, function()
			v.dialog( self.modalControl )
			MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPDOWN  )
		end )
	end

	screen:findWidget("backBtn.btn"):setText(STRINGS.UI.BACK)
	screen:findWidget("backBtn.btn").onClick = util.makeDelegate( nil, onClickClose, self)
	screen:findWidget("backBtn.btn"):setHotkey( "pause" )
    
end

function dialog:isActive()
	return self.screen and self.screen:isActive()
end

function dialog:destroy()
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPDOWN  )
    mui.deactivateScreen( self.screen )
    self.modalControl:abort()
    self.screen = nil
end

return dialog



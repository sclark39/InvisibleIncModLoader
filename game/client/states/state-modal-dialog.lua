----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include( "resources")
local util = include( "modules/util" )
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )

local CANCEL = 0
local OK = 1
local AUX = 2

----------------------------------------------------------------

local _M =
{
}

_M.setText = function( self, str )
	self.screen.binder.bodyTxt:setText(str)
end

_M.onUnload = function ( self )
	mui.deactivateScreen( self.screen )
	self.screen = nil
end

----------------------------------------------------------------
-- Modal controller that signals abort.

local modalControl = class()

function modalControl:abort()
    self.result = CANCEL
    return modalControl()
end


local function findGameModalControl()
    local states = statemgr.getStates()
    for i = 1, #states do
        if states[i].simCore and states[i].levelData and states[i].modalControl then
            return states[i].modalControl -- If it acts like a duck and quacks like a duck...
        end
    end
end

----------------------------------------------------------------

local function createModalDialog( dialogStr, headerStr, large, okStr, cancelStr)
	local t = util.tcopy( _M )

	--so the OK and the cancel buttons are swapped, which is really weird, but I don't want to break compatibility with the existant one-button cases.
	t.onLoad = function( self )
		if large then
			self.screen = mui.createScreen( "modal-dialog-large.lua" )
		else
			self.screen = mui.createScreen( "modal-dialog.lua" )
		end

		mui.activateScreen( self.screen )

		self.screen.binder.cancelBtn.onClick = util.makeDelegate( nil, function() t.result = OK end )
		self.screen.binder.cancelBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
		self.screen.binder.cancelBtn:setText( okStr and okStr or STRINGS.UI.BUTTON_CLOSE )

		self.screen.binder.okBtn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
		self.screen.binder.okBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
        
        if cancelStr then
        	self.screen.binder.okBtn:setText( cancelStr )
        end
        if not okStr then
			self.screen.binder.okBtn:setVisible( false )
		end

		self.screen.binder.headerTxt:setText( headerStr or "" )
		self.screen.binder.bodyTxt:setText( dialogStr )
	end

	return t
end

local function createUpdateDisclaimerDialog( okStr, readMoreStr )
	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-update-disclaimer.lua" )
		mui.activateScreen( self.screen )

		self.screen.binder.okBtn.binder.btn:setText(okStr)
		self.screen.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = OK end )

		self.screen.binder.readMoreBtn.binder.btn:setText(readMoreStr)
		self.screen.binder.readMoreBtn.binder.btn.onClick = util.makeDelegate( nil, function() MOAISim.visitURL( config.PATCHNOTES_URL ) end )
	end

	return t
end

local function createUpdateDisclaimerDialog_b( okStr, readMoreStr )
	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-update-disclaimer_b.lua" )
		mui.activateScreen( self.screen )

		self.screen.binder.okBtn.binder.btn:setText(okStr)
		self.screen.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = OK end )

		self.screen.binder.readMoreBtn.binder.btn:setText(readMoreStr)
		self.screen.binder.readMoreBtn.binder.btn.onClick = util.makeDelegate( nil, function() MOAISim.visitURL( config.PATCHNOTES_URL ) end )
	end

	return t
end

local function createYesNoDialog( dialogStr, headerStr, auxStr, continueTxt, cancelTxt, large )
	local t = util.tcopy( _M )

	t.onLoad = function( self )
		if large then
			self.screen = mui.createScreen( "modal-dialog-large.lua" )
		else
			self.screen = mui.createScreen( "modal-dialog.lua" )
		end

		mui.activateScreen( self.screen )
		
		if continueTxt then
			self.screen.binder.okBtn:setText( util.toupper(continueTxt) )
		end

		self.screen.binder.okBtn.onClick = util.makeDelegate( nil, function() t.result = OK end )
		self.screen.binder.cancelBtn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
		self.screen.binder.cancelBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
		if auxStr then
			self.screen.binder.auxBtn:setVisible( true )
			self.screen.binder.auxBtn:setText( auxStr )
			self.screen.binder.auxBtn.onClick = util.makeDelegate( nil, function() t.result = AUX end )
		end
		if cancelTxt then
			self.screen.binder.cancelBtn:setText( cancelTxt )
		end
		if headerStr then
			self.screen.binder.headerTxt:setText( headerStr )
		else
			self.screen.binder.headerTxt:setText("")
		end	
		self.screen.binder.bodyTxt:setText( dialogStr )
	end
	
	return t
end

local function createUseRewindDialog( bodyTxt, headerStr, lastChance )
	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-rewind.lua" )
		mui.activateScreen( self.screen )

		local ok = self.screen:findWidget("okBtn")
		local cancel = self.screen:findWidget("cancelBtn")

		ok.binder.btn.onClick = util.makeDelegate( nil, function() t.result = OK end )
		ok.binder.btn:setText(STRINGS.UI.REWIND_CONFIRM)
		
		cancel.binder.btn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )

		if lastChance then 
			cancel.binder.btn:setText(STRINGS.UI.REWIND_GAME_OVER)
		else
			cancel.binder.btn:setText(STRINGS.UI.HUD_CANCEL)
		end

		cancel.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
		                 
		if bodyTxt then
			self.screen.binder.bodyTxt:setText( bodyTxt )
		end
		
		if headerStr then
			self.screen.binder.title.binder.titleTxt2:setText( headerStr )
		else
			self.screen.binder.title.binder.titleTxt2:setText( "" )
		end	
	end
	
	return t
end

local function createBusyDialog( dialogStr, headerStr )

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-busy.lua" )
		mui.activateScreen( self.screen )
		
		self.screen.binder.cancelBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
		self.screen.binder.cancelBtn.binder.btn:setVisible( false ) -- nothing cancel-able atm
		self.screen.binder.cancelBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
		self.screen.binder.cancelBtn.binder.btn:setText(STRINGS.UI.BUTTON_CANCEL)
		self.screen.binder.bodyTxt:setText( dialogStr or "" )
        if headerStr then
		    self.screen.binder.headerTxt:setText( headerStr )
        end
	end

	return t
end

local function createBlindSpotsDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-blindspots.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
	end

	return t
end

local function createManipulateDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-manipulate.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
	end

	return t
end

local function tunBasedDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-turns.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
	end

	return t
end


function createObjectivesDialog( missionTxt, objTxt, subObjTxt, objImg, corpLogo )
	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-mission-objectives.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setHotkey( "pause" )

		--self.screen.binder.pnl.binder.missionTxt:setText(missionTxt)
		self.screen.binder.pnl.binder.objTxt:setText(objTxt)
		self.screen.binder.pnl.binder.objTxt2:setText(subObjTxt)
		self.screen.binder.pnl.binder.objImg:setImage(objImg)
		self.screen.binder.pnl.binder.corpLogo:setImage(corpLogo)

	end

	return t
end

local function createCornerPeekDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-corner_peek.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = util.makeDelegate( nil, function() t.result = CANCEL end )
	end

	return t
end

local function createDamemonDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-daemon-intro.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end

local function createIncognitaDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-incognita.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end

local function createPeekOpenPeekDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-peek_open_peek.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end

local function createPinningDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-pinning.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end


local function createCooldownDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-cooldown.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end



local function createRewindTutorialDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-rewind-tutorial.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end

local function createLockpickDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-lockpick.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end

local function createAlarmFirstDialog()
	local t = util.tcopy( _M )

	t.onUnload = function( self )	
		self._alarmThread:stop()
		self._alarmThread = nil
		mui.deactivateScreen( self.screen )
		self.screen = nil
	end

	t.onLoad = function( self )
	    self.screen = mui.createScreen( "modal-alarm-first.lua" )
	    mui.activateScreen( self.screen )
	    self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end

		self.screen.binder.pnl.binder.title.binder.titleTxt:setText( STRINGS.UI.ALARM_INSTALL )
		self.screen.binder.pnl.binder.title.binder.titleTxt2:setText( STRINGS.UI.ALARM_INSTALL_FIRST_1 )
		self.screen.binder.pnl.binder.bodyTxt:setText( STRINGS.UI.ALARM_INSTALL_FIRST_2 ) 

		local color = cdefs.TRACKER_COLOURS[1]
		self.screen.binder.pnl.binder.num:setColor( color:unpack() )
		self.screen.binder.pnl.binder.headerbox:setColor(color.r,color.g,color.b, 1)
		self.screen.binder.pnl.binder.bodyTxt:setColor(color.r,color.g,color.b, 1)

		local animWidget = self.screen:findWidget("trackerAnimFive")
		local alarmRing = self.screen:findWidget("alarmRing1")
		alarmRing:setColor( 1, 0, 0, 0.5 ) 

		self._alarmThread = MOAICoroutine.new()
		self._alarmThread:run( function()

			rig_util.wait( 30 )

			for i = 1, 6 do
				local colorIndex = math.min( #cdefs.TRACKER_COLOURS, i )
				local color = cdefs.TRACKER_COLOURS[ colorIndex ]
				animWidget:setColor( color:unpack() )
				self.screen.binder.pnl.binder.num:setColor( color:unpack() )

				for j = 1, 5 do
					alarmRing:setAnim( "idle" )	
					alarmRing:setVisible( true )
					rig_util.waitForAnim( animWidget:getProp(), "fill_"..j )

					if j == 5 then
						self.screen.binder.pnl.binder.num:setText( i )
					end

					rig_util.wait( 15 )
					alarmRing:setVisible( false )
					
					rig_util.wait( 15 )

				end
			end
		end )
	end

	return t
end


local function createTacticalViewDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-tactical-view.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	return t
end

local function createLoveDialog()

	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-love.lua" )
		mui.activateScreen( self.screen )
		self.screen.binder.pnl.binder.okBtn.binder.btn:setText(STRINGS.UI.CONTINUE)
		self.screen.binder.pnl.binder.okBtn.binder.btn.onClick = function() t.result = CANCEL end 
	end

	t.onUnload = function( self )	
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
		mui.deactivateScreen( self.screen )
		self.screen = nil
	end

	return t
end


local function showDialog( modalDialog, controller )
	statemgr.activate( modalDialog )

    controller = controller or findGameModalControl()

	while modalDialog.result == nil do
        if controller and controller.result then
            break
        end
		coroutine.yield()
	end

    -- It's possible for shutdown to preemptively deactivate active dialogs from under us.
    if statemgr.isActive( modalDialog ) then
	    statemgr.deactivate( modalDialog )
    end

    if controller and controller.result then
        return controller.result
    end

	return modalDialog.result
end

local function show( ... )
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createModalDialog( ... )
	return showDialog( modalDialog )
end

local function showYesNo( ... )
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createYesNoDialog( ... )
	return showDialog( modalDialog )
end

local function showUseRewind( bodyTxt, headerTxt, lastChance )
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createUseRewindDialog( bodyTxt, headerTxt, lastChance )
	return showDialog( modalDialog )
end

local function showBlindSpots()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createBlindSpotsDialog()
	return showDialog( modalDialog )
end

local function showManipulateDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createManipulateDialog()
	return showDialog( modalDialog )
end


local function showTurnbaseDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = tunBasedDialog()
	return showDialog( modalDialog )
end

local function showCornerPeekDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createCornerPeekDialog()
	return showDialog( modalDialog )
end

local function showObjectivesDialog( ... )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createObjectivesDialog( ... )
	return showDialog( modalDialog )
end


local function showDaemonDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createDamemonDialog()
	return showDialog( modalDialog )
end


local function showIncognitaDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createIncognitaDialog()
	return showDialog( modalDialog )
end

local function showPeekOpenPeekDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createPeekOpenPeekDialog()
	return showDialog( modalDialog )
end

local function showPinningDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createPinningDialog()
	return showDialog( modalDialog )
end


local function showCooldownDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createCooldownDialog()
	return showDialog( modalDialog )
end


local function showRewindTutorialDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createRewindTutorialDialog()
	return showDialog( modalDialog )
end



local function showTacticalViewDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createTacticalViewDialog()
	return showDialog( modalDialog )
end

local function showAlarmFirstDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createAlarmFirstDialog()
	return showDialog( modalDialog )
end

local function showLockpickDialog()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createLockpickDialog()
	return showDialog( modalDialog )
end

local function showLoveProgram()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPUP )
	MOAIFmodDesigner.playSound( "SpySociety/VoiceOver/Incognita/Pickups/NewProgram" )
	local modalDialog = createLoveDialog()
	return showDialog( modalDialog )
end

local function showWelcome()
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP  )
	local t = util.tcopy( _M )

	t.onLoad = function( self )
		self.screen = mui.createScreen( "modal-posttutorial.lua" )
		mui.activateScreen( self.screen )

		local closeBtn = self.screen.binder.closeBtn.binder.btn
		closeBtn:setHotkey( "pause" )
		closeBtn:setText( STRINGS.UI.NEW_GAME_CONFIRM )
		closeBtn.onClick = util.makeDelegate( nil, function() t.result = OK end )
	end

	return showDialog( t )
end

local function showUnlockProgram( rewardData )

	local t = util.tcopy( _M )

	t.onLoad = function( self )

		self.screen = mui.createScreen( "modal-unlock.lua" )
		mui.activateScreen( self.screen )

		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/unlock_agent" )

		local abilitydefs = include( "sim/abilitydefs" )
		local rewardName1 = rewardData.unlocks[1].name
		local rewardName2 = rewardData.unlocks[2].name

		local ability1 = abilitydefs.lookupAbility( rewardName1 )
		local ability2 = abilitydefs.lookupAbility( rewardName2 )

		local populateProgram = function(programWidget, ability)

			local PWRtooltip = STRINGS.UI.TOOLTIPS.TEAM_SELECT_PWR_DESC

			programWidget.binder.programIcon:setImage(ability.icon)		
			programWidget.binder.programName:setText(util.toupper(ability.name))
			programWidget.binder.programTxt:spoolText(ability.desc)
			if ability.cpu_cost > 0 or not ability.passive then
				programWidget.binder.powerTxt:setText(tostring(ability.cpu_cost))
				programWidget.binder.firewallTooltip:setTooltip(PWRtooltip..util.sformat(STRINGS.UI.TOOLTIPS.TEAM_SELECT_PWR, ability.cpu_cost))
			else
				programWidget.binder.powerTxt:setText("-")
			end

			if ability.cpu_cost then 
				for i, widget in programWidget.binder:forEach( "power" ) do	
					if i<=ability.cpu_cost then
						widget:setColor(140/255,255/255,255/255)
					else
						widget:setColor(17/255,29/255,29/255)
					end
				end
				if ability.cpu_cost > 0 then
					programWidget.binder.firewallTooltip:setTooltip(PWRtooltip..util.sformat(STRINGS.UI.TOOLTIPS.TEAM_SELECT_PWR, ability.cpu_cost))			
				end
			else
				for i, widget in programWidget.binder:forEach( "power" ) do
					widget:setColor(17/255,29/255,29/255)
				end
			end

		end

		populateProgram(self.screen.binder.program1.binder.Program, ability1)
		populateProgram(self.screen.binder.program2.binder.Program, ability2)

		local closeBtn = self.screen.binder.okBtn.binder.btn
		closeBtn:setHotkey( "pause" )
		closeBtn:setText( STRINGS.UI.CONTINUE )
		closeBtn.onClick = util.makeDelegate( nil, function() t.result = OK end )
	end

	return showDialog( t )

end

local function showUnlockAgent( rewardData )
	
	local t = util.tcopy( _M )

	t.onLoad = function( self )

		local SET_COLOR = {r=244/255,g=255/255,b=120/255, a=1}

		self.screen = mui.createScreen( "modal-unlock-agents.lua" )
		mui.activateScreen( self.screen )

		MOAIFmodDesigner.playSound( "SpySociety/HUD/gameplay/unlock_agent" )

		local agentdefs = include( "sim/unitdefs/agentdefs" )
		local skilldefs = include( "sim/skilldefs" )
		local tool_templates = include( "sim/unitdefs/itemdefs" )
		local simfactory = include( "sim/simfactory" )

		local rewardName1 = rewardData.unlocks[1].name
		local rewardName2 = rewardData.unlocks[2].name

		local agentDef1 = agentdefs[ rewardName1 ]
		local agentDef2 = agentdefs[ rewardName2 ]

		local agentPnl1 = self.screen.binder.agent1.binder.agentPnl
		local agentPnl2 = self.screen.binder.agent2.binder.agentPnl

		self.screen.binder.agent1.binder.agentPnl.binder.agentIMG:setImage(agentDef1.team_select_img[1])
		if agentDef1.loadoutName == STRINGS.UI.ON_ARCHIVE then 
			self.screen.binder.agent1.binder.agentPnl.binder.agentName:setVisible( false )	
			self.screen.binder.agent1.binder.agentPnl.binder.agentNameSmall:setVisible( true )		
			self.screen.binder.agent1.binder.agentPnl.binder.agentNameSmall:setText(util.toupper(STRINGS.UI.ON_ARCHIVE.." "..agentDef1.name))
		else 
			self.screen.binder.agent1.binder.agentPnl.binder.agentName:setText(util.toupper(agentDef1.name))
		end 

		for i, widget in agentPnl1.binder.skillPnl.binder:forEach( "skill" ) do 
			local skill = nil
			if agentDef1.skills[i] then 
				skill = skilldefs.lookupSkill(agentDef1.skills[i])
			end 
			widget.binder.bar1.binder.bar:setColor( 244/255, 1, 120/255 )
			if agentDef1.startingSkills[ agentDef1.skills[i] ] then 
				widget.binder.bar2.binder.bar:setColor( 244/255, 1, 120/255 )
			end 
			widget.binder.skillName:setText( skill.name )
		end 

		for i, widget in agentPnl1.binder:forEach( "item" ) do
			if agentDef1.upgrades[i] then
				widget:setVisible(true)

				local unitData = tool_templates[agentDef1.upgrades[i]]
                local newItem = simfactory.createUnit( unitData, nil )						
				widget:setImage( unitData.profile_icon )

		        local tooltip = util.tooltip( self.screen )
		        local section = tooltip:addSection()
		        newItem:getUnitData().onTooltip( section, newItem )
		        widget:setTooltip( tooltip )
		        widget:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
			else
				widget:setVisible(false)
			end
		end

		self.screen.binder.agent2.binder.agentPnl.binder.agentIMG:setImage(agentDef2.team_select_img[1])		
		if agentDef2.loadoutName == STRINGS.UI.ON_ARCHIVE then 
			self.screen.binder.agent2.binder.agentPnl.binder.agentName:setVisible( false )	
			self.screen.binder.agent2.binder.agentPnl.binder.agentNameSmall:setVisible( true )		
			self.screen.binder.agent2.binder.agentPnl.binder.agentNameSmall:setText(util.toupper(STRINGS.UI.ON_ARCHIVE.." "..agentDef2.name))
		else 
			self.screen.binder.agent2.binder.agentPnl.binder.agentName:setText(util.toupper(agentDef2.name))
		end 

		for i, widget in agentPnl2.binder.skillPnl.binder:forEach( "skill" ) do 
			local skill = nil
			if agentDef2.skills[i] then 
				skill = skilldefs.lookupSkill(agentDef2.skills[i])
			end 
			widget.binder.bar1.binder.bar:setColor( 244/255, 1, 120/255 )
			if agentDef2.startingSkills[ agentDef2.skills[i] ] then 
				widget.binder.bar2.binder.bar:setColor( 244/255, 1, 120/255 )
			end 
			widget.binder.skillName:setText( skill.name )
		end 

		for i, widget in agentPnl2.binder:forEach( "item" ) do
			if agentDef2.upgrades[i] then
				widget:setVisible(true)

				local unitData = tool_templates[agentDef2.upgrades[i]]
                local newItem = simfactory.createUnit( unitData, nil )						
				widget:setImage( unitData.profile_icon )

		        local tooltip = util.tooltip( self.screen )
		        local section = tooltip:addSection()
		        newItem:getUnitData().onTooltip( section, newItem )
		        widget:setTooltip( tooltip )
		        widget:setColor(SET_COLOR.r,SET_COLOR.g,SET_COLOR.b,SET_COLOR.a)
			else
				widget:setVisible(false)
			end
		end


		local closeBtn = self.screen.binder.okBtn.binder.btn
		closeBtn:setHotkey( "pause" )
		closeBtn:setText( STRINGS.UI.CONTINUE )
		closeBtn.onClick = util.makeDelegate( nil, function() t.result = OK end )
	end

	return showDialog( t )
end

local function showUpdateDisclaimer( okTxt, readMoreTxt )
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createUpdateDisclaimerDialog( okTxt, readMoreTxt )
	return showDialog( modalDialog )
end

local function showUpdateDisclaimer_b( okTxt, readMoreTxt )
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	local modalDialog = createUpdateDisclaimerDialog_b( okTxt, readMoreTxt )
	return showDialog( modalDialog )
end

return
{
	CANCEL = CANCEL,
	OK = OK,
	AUX = AUX,

    modalControl = modalControl,

	show = show,
	showYesNo = showYesNo,
	showUseRewind = showUseRewind,
    createModalDialog = createModalDialog,
	createBusyDialog = createBusyDialog,
	showWelcome = showWelcome,
	showUnlockAgent = showUnlockAgent,
	showUnlockProgram = showUnlockProgram,
	showBlindSpots = showBlindSpots,
	showManipulateDialog = showManipulateDialog,
	showPeekOpenPeekDialog = showPeekOpenPeekDialog,
	showPinningDialog = showPinningDialog,
	showRewindTutorialDialog = showRewindTutorialDialog,
	showCornerPeekDialog = showCornerPeekDialog,
	showTurnbaseDialog = showTurnbaseDialog,
	showUpdateDisclaimer = showUpdateDisclaimer,
	showUpdateDisclaimer_b = showUpdateDisclaimer_b,
	showObjectivesDialog = showObjectivesDialog,
	showDaemonDialog = showDaemonDialog,
	showIncognitaDialog = showIncognitaDialog,
	showLockpickDialog = showLockpickDialog,
	showLoveProgram = showLoveProgram,
	showTacticalViewDialog = showTacticalViewDialog,
	showAlarmFirstDialog = showAlarmFirstDialog,
	showCooldownDialog = showCooldownDialog,
}

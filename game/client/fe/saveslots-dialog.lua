----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local cdefs = include("client_defs")
local strings = include( "strings" )
local metrics = include( "metrics" )
local simparams = include( "sim/simparams" )
local unitdefs = include( "sim/unitdefs" )
local serverdefs = include( "modules/serverdefs" )
local version = include( "modules/version" )
local modalDialog = include( "states/state-modal-dialog" )
local simdefs = include( "sim/simdefs" )

----------------------------------------------------------------
-- Local functions
local GAME_MODE_STRINGS =
{
    [ simdefs.CUSTOM_DIFFICULTY ] = STRINGS.UI.CUSTOM_DIFFICULTY,
    [ simdefs.NORMAL_DIFFICULTY ] = STRINGS.UI.NORMAL_DIFFICULTY,
    [ simdefs.EXPERIENCED_DIFFICULTY ] = STRINGS.UI.EXPERIENCED_DIFFICULTY,
    [ simdefs.HARD_DIFFICULTY ] = STRINGS.UI.HARD_DIFFICULTY,
    [ simdefs.VERY_HARD_DIFFICULTY ] = STRINGS.UI.VERY_HARD_DIFFICULTY,
    [ simdefs.ENDLESS_DIFFICULTY ] = STRINGS.UI.ENDLESS_DIFFICULTY,
    [ simdefs.ENDLESS_PLUS_DIFFICULTY ] = STRINGS.UI.ENDLESS_PLUS_DIFFICULTY,
    [ simdefs.TIME_ATTACK_DIFFICULTY ] = STRINGS.UI.TIME_ATTACK_DIFFICULTY,
    [ simdefs.TUTORIAL_DIFFICULTY ] = STRINGS.UI.NORMAL_DIFFICULTY,
}

local MAX_SAVE_SLOTS = 4

local STATE_SELECT_SAVE = 1
local STATE_CONTINUE_GAME = 2
local STATE_NEW_GAME = 3


local function checkFirstTimePlaying()
	
	--do return true end

	local user = savefiles.getCurrentGame()

	local firstTime = true
	if user.data.gamesStarted then
		firstTime = false 
	end

	if user.data.top_games ~= nil and #user.data.top_games > 0 then
		firstTime = false
	end

	return firstTime
end

local function launchTutorial(dialog)
	dialog:hide()
	local campaign = serverdefs.createNewCampaign( serverdefs.createTutorialAgency() )

	local user = savefiles.getCurrentGame()
	user.data.saveSlots[ user.data.currentSaveSlot ] = campaign
	user.data.num_campaigns = (user.data.num_campaigns or 0) + 1
	user.data.gamesStarted= true
	user:save()

	statemgr.deactivate( dialog._mainMenu )
	local stateLoading = include( "states/state-loading" )
	stateLoading:loadCampaign( campaign )
end

local function canContinueCampaign( campaign )
	if not campaign then
		return false
	end

	if version.isIncompatible( campaign.version ) then
		local reason = "<ttheader>" .. STRINGS.UI.SAVE_NOT_COMPATIBLE.. "<font1_12_r>\n"
		reason = reason .. string.format( "%s v%s\n", STRINGS.UI.SAVE_GAME_VERSION, tostring(campaign.version) )
		reason = reason .. string.format( "%s v%s", STRINGS.UI.CURRENT_VERSION, version.VERSION )
		return false, reason
	end

    if campaign.difficultyOptions.enabledDLC and next(campaign.difficultyOptions.enabledDLC) then
    	--log:write("Campaign has installed mods:")
        for modID, info in pairs(campaign.difficultyOptions.enabledDLC) do
        	--log:write("    [%s] %s %s", modID, info.name, mod_manager:isInstalled( modID ) and "OK" or "(missing)")
            if info.enabled and not mod_manager:isInstalled( modID ) then
        		local reason = "<ttheader>" .. STRINGS.UI.SAVE_NOT_COMPATIBLE.. "<font1_12_r>\n"
                reason = reason .. util.sformat( STRINGS.UI.SAVE_NEEDS_DLC, info.name )
                return false, reason
            end
        end
    end

	return true
end

local function continueCampaign( dialog, campaign )

    mod_manager:resetContent()
    mod_manager:loadModContent( campaign.difficultyOptions.enabledDLC )

	if campaign.situation == nil then
		-- Go to map screen if the campaign currently isn't mid-mission.
		MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
		MOAIFmodDesigner.stopSound("theme")
		local stateMapScreen = include( "states/state-map-screen" )
		statemgr.deactivate( dialog._mainMenu )
		statemgr.activate( stateMapScreen(), campaign )
	else
		local stateLoading = include( "states/state-loading" )
		statemgr.deactivate( dialog._mainMenu )
		stateLoading:loadCampaign( campaign )
	end
end

local function onClickCancel( dialog )
	dialog:hide()
end

local function onSaveSlotClicked( dialog, idx, campaign )
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP)
	-- Update currently selected save slot.
	local user = savefiles.getCurrentGame()
	user.data.lastSaveSlot = idx
	user.data.currentSaveSlot = idx

	if campaign == nil then
		if checkFirstTimePlaying() then
			launchTutorial(dialog)
		else
			dialog:showState( STATE_NEW_GAME )
		end

	
	else
		dialog:showState( STATE_CONTINUE_GAME, campaign )
	end
end

local function onClickContinue( dialog )
	local user = savefiles.getCurrentGame()
	local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
	local canContinue, reason = canContinueCampaign( campaign )
	assert( canContinue )

	local version = include( "modules/version" )

	if campaign.missionVersion and  not version.isVersionOrHigher( campaign.missionVersion or "", version.VERSION ) then
		local result = modalDialog.showUpdateDisclaimer_b( STRINGS.UI.SAVESLOTS.CONTINUE, STRINGS.UI.SAVESLOTS.SEE_PATCHNOTES )
		if result == modalDialog.AUX then
			MOAISim.visitURL( config.PATCHNOTES_URL )
			return
		end
	end
	--[[
	if campaign.wasUpdated then
		local result = modalDialog.showUpdateDisclaimer( STRINGS.UI.SAVESLOTS.CONTINUE, STRINGS.UI.SAVESLOTS.SEE_PATCHNOTES )
		if result == modalDialog.AUX then
			MOAISim.visitURL( config.PATCHNOTES_URL )
			return

		elseif result == modalDialog.OK then
    	    campaign.seed = campaign.seed + 1
			campaign.wasUpdated = nil
		else
			return
		end
	end
	]]
    if canContinue then
		dialog:hide()
		continueCampaign( dialog, campaign )
		metrics.app_metrics:incStat( "continued_games" )
	end
end

local function onClickDelete( dialog )
	local modalDialog = include( "states/state-modal-dialog" )
	local result = modalDialog.showYesNo( STRINGS.UI.SAVESLOTS.DELETE_AREYOUSURE, STRINGS.UI.SAVESLOTS.DELETE_SAVE, nil, STRINGS.UI.SAVESLOTS.DELETE_SAVE, nil, true )
	if result == modalDialog.OK then
		local user = savefiles.getCurrentGame()
		user.data.saveSlots[ user.data.currentSaveSlot ] = nil
		user.data.currentSaveSlot = nil
		user:save()
		
		dialog:populateSaveSlots()
		dialog:showState( STATE_SELECT_SAVE )
	end
end

local function onClickCancelContinue( dialog )
	dialog:showState( STATE_SELECT_SAVE )
end

local function onClickStory( dialog )
	dialog:hide()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
    local settings = savefiles.getSettings( "settings" )
	local stateGenerationOptions = include( "states/state-generation-options" )
	statemgr.activate( stateGenerationOptions(), settings.data.lastdiff )
	statemgr.deactivate( dialog._mainMenu )
	
end

local function onClickTutorial( dialog )
	launchTutorial(dialog)
end

local function onClickCancelNewGame( dialog )
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPDOWN )
	dialog:showState( STATE_SELECT_SAVE )
end

----------------------------------------------------------------
-- Interface functions

local dialog = class()

function dialog:init( mainMenu )
	local screen = mui.createScreen( "modal-saveslots.lua" )
	self._screen = screen
    self._mainMenu = mainMenu

   	screen.binder.cancelBtn.binder.btn.onClick = util.makeDelegate( nil, onClickCancel, self )
   	screen.binder.cancelBtn.binder.btn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
   	screen.binder.cancelBtn.binder.btn:setText(STRINGS.UI.HUD_CANCEL)
   	screen.binder.cancelBtn.binder.btn:setHotkey( "pause" )

	screen.binder.listbox.onItemClicked = util.makeDelegate( nil, onSaveSlotClicked, self )

	screen.binder.storyBtn.onClick = util.makeDelegate( nil, onClickStory, self )
	screen.binder.storyBtn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)

	
	screen.binder.tutorialBtn.onClick = util.makeDelegate( nil, onClickTutorial, self )
	screen.binder.tutorialBtn:setClickSound(cdefs.SOUND_HUD_MENU_CONFIRM)
	local user = savefiles.getCurrentGame()
	--screen.binder.endlessBtn:setDisabled( (user.data.storyWins or 0) <= 0 )
	screen.binder.cancelGameBtn.onClick = util.makeDelegate( nil, onClickCancelNewGame, self )
	screen.binder.cancelGameBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)

	screen.binder.continueBtn.onClick = util.makeDelegate( nil, onClickContinue, self )
	screen.binder.continueBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)
	
	screen.binder.deleteBtn.onClick = util.makeDelegate( nil, onClickDelete, self )
	

	screen.binder.cancelContinueBtn.onClick = util.makeDelegate( nil, onClickCancelContinue, self )
	screen.binder.cancelContinueBtn:setClickSound(cdefs.SOUND_HUD_MENU_CANCEL)

	self:showState( STATE_SELECT_SAVE )
end

function dialog:showState( state, campaign )

	self._screen.binder.newGame:setVisible( state == STATE_NEW_GAME )
	self._screen.binder.continueGame:setVisible( state == STATE_CONTINUE_GAME )
	self._screen.binder.cover:setVisible( state ~= STATE_SELECT_SAVE )
	self._screen.binder.optionsBG:setVisible( state ~= STATE_SELECT_SAVE )

	if state == STATE_NEW_GAME then
		self._screen.binder.newGame:createTransition("activate_left")
		self._screen.binder.optionsBG:createTransition("activate_left")
	elseif state == STATE_CONTINUE_GAME then
		self._screen.binder.continueGame:createTransition("activate_left")
		self._screen.binder.optionsBG:createTransition("activate_left")
		self._screen.binder.continueBtn:setDisabled( not canContinueCampaign( campaign ))
	end

end

function dialog:show()
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP )
	mui.activateScreen( self._screen )

	self:populateSaveSlots()
end

function dialog:populateSaveSlots()
	local listbox = self._screen.binder.listbox

	listbox:clearItems()

	local user = savefiles.getCurrentGame()
	-- for backwards compatability
	if user.data.saveSlots == nil then
		user.data.saveSlots = { user.data.campaign }
	end

	for i = 1, MAX_SAVE_SLOTS do
		local campaign = user.data.saveSlots[i]
		local widget = listbox:addItem( campaign )
		local txt = nil

		if campaign then
            serverdefs.updateCompatibility( campaign )

			local num_agents = #campaign.agency.unitDefs
			local agents_to_show = {}
			for k,v in ipairs(campaign.agency.unitDefs) do

				if num_agents <= 4 or (v.template ~= "monst3r" and v.template ~= "central") then
					table.insert(agents_to_show, v)
				end
			end

			for i, portrait in widget.binder:forEach("img") do
				local unitDef = agents_to_show[i]
				if unitDef then
					local template = unitdefs.lookupTemplate( unitDef.template )
                    if template then
    					portrait:setImage( template.profile_icon_64x64 )
                    else
    					portrait:setImage( "gui/profile_icons/unknown_64x64.png" )
                    end
				else
					portrait:setVisible(false)
				end
			end

			local canContinue, reason = canContinueCampaign( campaign )
			if not canContinue then
				txt = reason
			else
				local gameModeStr = GAME_MODE_STRINGS[ campaign.campaignDifficulty ]
			    txt = util.sformat("<font1_16_sb>"..STRINGS.UI.DIFFICULTY_FORMAT.."</>", gameModeStr )

				if campaign.situation and campaign.situation.name == serverdefs.TUTORIAL_SITUATION then
					txt = txt .. "\n"..STRINGS.UI.SAVESLOTS.TUTORIAL
				else
					local totalHours = serverdefs.calculateCurrentHours(campaign)
                    local hours = totalHours % 24
                    local days = math.floor(totalHours / 24) + 1
					txt = txt .. "\n"..util.sformat( STRINGS.UI.SAVESLOTS.DAYS_SPENT, string.format( "%02d", days ), days, string.format( "%02d", hours ), hours )
				end

				if campaign.save_time then
					txt = txt .. string.format("\n<font1_16_sb>%s</>", os.date("%c", campaign.save_time))
				end
			end
            if config.DEV then
                widget.binder.txt:setTooltip( string.format( "VERSION = %s\nLAST SLOT: %s\n%s",
                    tostring(campaign.version), tostring( user.data.lastSaveSlot ), tostring( campaign.recent_build_number )))
            end
		else
			for i, portrait in widget.binder:forEach("img") do
				portrait:setVisible(false)
			end
			txt = STRINGS.UI.SAVESLOTS.EMPTY_SLOT
		end

		widget.binder.txt:setText( txt )
	end
    user:save()
end


function dialog:hide()
	 MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_MENU_POPDOWN  )
	if self._screen:isActive() then
		mui.deactivateScreen( self._screen )
	end
end

return dialog

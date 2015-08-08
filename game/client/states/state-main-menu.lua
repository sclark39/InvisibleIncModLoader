----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local resources = include("resources")
local util = include("client_util")
local cdefs = include("client_defs")
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local serverdefs = include( "modules/serverdefs" )
local metrics = include( "metrics" )
local stateLoading = include( "states/state-loading" )
local stateSignUp = include( "states/state-signup" )
local modalDialog = include( "states/state-modal-dialog" )
local options_dialog = include( "hud/options_dialog" )
local simparams = include( "sim/simparams" )
local metadefs = include( "sim/metadefs" )
local scroll_text = include("hud/scroll_text")

----------------------------------------------------------------

local mainMenu = class()

local function onEnterSpool( widget )
	widget:spoolText( widget:getText() )
end

local function onClickPlay( self )
	
	local user = savefiles.getCurrentGame()
	if user.data.old_xp then

		local result = modalDialog.show( STRINGS.UI.PRERELEASE_COMPAT_BODY, STRINGS.UI.PRERELEASE_COMPAT_TITLE, true, STRINGS.UI.PRERELEASE_COMPAT_YES, STRINGS.UI.PRERELEASE_COMPAT_NO )
		if result == modalDialog.OK then
			user.data.xp = user.data.old_xp
		end
		user.data.old_xp = nil
		user:save()
	end


    if config.DEV and #config.SIM_DATA > 0 then
		local simhistory = include( "sim/simhistory" )
        local ok, params, simHistory = pcall( simhistory.unpackActions, config.SIM_DATA )
        if ok and params and simHistory then
		    statemgr.deactivate( self )
		    stateLoading:loadLocalGame( params, simHistory )
        else
            log:write( "Failed to unpack sim data of length %d", #config.SIM_DATA )
        end

	elseif #config.DEFAULTLVL == 0 then
		local modalSaveSlots = include( "fe/saveslots-dialog" )
		local dialog = modalSaveSlots( self )
		dialog:show()

	else
		statemgr.deactivate( self )
		local params = simparams.createParams( config.DEFAULTLVL )
		stateLoading:loadLocalGame( params )
	end
end

local function onClickForum()
	MOAISim.visitURL( config.FORUM_URL )
end

local function onClickSignUp()
	statemgr.activate( stateSignUp )
end

local function onClickExit()
	MOAIFmodDesigner.playSound(  cdefs.SOUND_HUD_MENU_POPUP  )
	local result = modalDialog.showYesNo( STRINGS.UI.QUIT_CONFIRM, STRINGS.UI.QUIT, nil, STRINGS.UI.QUIT )
	if result == modalDialog.OK then
		MOAIEnvironment.QUIT = true
	end
end


local function onClickCredits()
	MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT )
    local stateCredits = include( "states/state-credits" )
	statemgr.activate( stateCredits() )
end

local function onClickOptions(dialog)
	dialog._options_dialog:show()
end

function mainMenu:onLoad()
    if not config.DEV and KLEIAchievements then
        -- Yes, this achievement exists... No, I'm not giving it away for free. :)
        --KLEIAchievements:achieve( "META_HACKING" )
    end

    if DBG_STATE.isLeakTracking then
        DBG_STATE.isLeakTracking = false
    	MOAISim.reportLeaks()
	    MOAISim.setLeakTrackingEnabled( false )
    end

    mod_manager:resetContent()
    mod_manager:loadModContent(mod_manager:getModContentDefaults())

    --jcheng: failsafe
    FMODMixer:popMix("nomusic")
    
	FMODMixer:pushMix("frontend")
	self.screen = mui.createScreen( "main-menu.lua" )
	mui.activateScreen( self.screen )

	self.screen.binder.watermark:setText( config.WATERMARK )

	self.screen.binder.playBtn.onClick = util.makeDelegate( nil, onClickPlay, self )
	self.screen.binder.playBtn.onEnter = onEnterSpool

	self.screen.binder.signUpBtn.onClick = onClickSignUp
	self.screen.binder.signUpBtn.onEnter = onEnterSpool
	self.screen.binder.exitBtn.onClick = onClickExit
	self.screen.binder.exitBtn.onEnter = onEnterSpool
	self.screen.binder.creditsBtn.onClick = onClickCredits
	self.screen.binder.creditsBtn.onEnter = onEnterSpool

	self.screen.binder.optionsBtn.onClick = util.makeDelegate( nil, onClickOptions, self )  
	self.screen.binder.optionsBtn.onEnter = onEnterSpool

	MOAIFmodDesigner.stopMusic()
	if not MOAIFmodDesigner.isPlaying("theme") then
		MOAIFmodDesigner.playSound("SpySociety/Music/music_title","theme")
	end

    log:write( "\tmainmenu:onLoad() - playing title theme" )

	self._options_dialog = options_dialog( )

	--allow showing movie the first time
	config.SHOW_MOVIE = true

end

----------------------------------------------------------------
function mainMenu:onUnload()
	FMODMixer:popMix("frontend")
	mui.deactivateScreen( self.screen )
    self.screen = nil

    if DBG_STATE.isLeakTracking then
	    MOAISim.setLeakTrackingEnabled( true )
    end
end

return mainMenu

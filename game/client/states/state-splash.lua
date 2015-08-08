----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "modules/util" )
local resources = include( "resources")
local modalDialog = include("states/state-modal-dialog")
local stateLoading = include( "states/state-loading" )
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )

local WAIT_SECONDS = 0

----------------------------------------------------------------

local splash = class()

----------------------------------------------------------------
function splash:onLoad()
    log:write( "\tsplash:onLoad()" )
	MOAIGfxDevice.setClearColor ( 0, 0, 0, 1 )
	
	self.screen = mui.createScreen( "splash-screen.lua" )
	mui.activateScreen( self.screen )

    self.waitSeconds = WAIT_SECONDS 

    log:write( "\tsplash:onLoad() - activated screen" )
	self.startTime = MOAISim.getDeviceTime ()

	-- Set the current user to the last user, based on the settings file.
	savefiles.initSaveGame()

    log:write( "\tsplash:onLoad() - applying settings screen" )
    local settingsFile = savefiles.getSettings( "settings" )
	util.applyUserSettings( settingsFile.data )
end


function splash:onUnload()
	mui.deactivateScreen( self.screen )
	self.screen = nil
end

----------------------------------------------------------------
function splash:onUpdate()

	if self.waitSeconds < ( MOAISim.getDeviceTime () - self.startTime ) then
		statemgr.deactivate( self )

	    local stateDebug = include("states/state-debug")
        statemgr.activate( stateDebug )
	
		if #config.LAUNCHLVL > 0 then
			-- Shortcut directly into game, to play the specified launch level
			local simparams = include( "sim/simparams" )
			local params = simparams.createParams( config.LAUNCHLVL )

			stateLoading:loadLocalGame( params )
		else
            log:write( "\tsplash:onUpdate() - activating main menu" )
			-- Normal flow: progress to main menu
            local stateMainMenu = include( "states/state-main-menu" )
			statemgr.activate ( stateMainMenu() )
		end
	end

end

return splash

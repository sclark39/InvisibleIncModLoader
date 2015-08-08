----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local util = include( "client_util" )
local resources = include( "resources")
local animmgr = include("anim-manager")
local gameobj = include( "modules/game" )
local version = include( "modules/version" )
local modalDialog = include("states/state-modal-dialog")
local simparams = include( "sim/simparams" )
local mui = include( "mui/mui" )
local mui_defs = include( "mui/mui_defs" )
local mui_util = include( "mui/mui_util" )
local cdefs = include( "client_defs" )
local rig_util = include( "gameplay/rig_util" )
local simdefs = include( "sim/simdefs" )
local serverdefs = include( "modules/serverdefs" )

----------------------------------------------------------------

local loading = {}

local LOADING_IMAGES = 
{
	{ png="airplane", world="any" },
	{ png="infiltration", world="any" },
	{ png="nika", world="any" },
	{ png="VTOL_matte", world="any" },
	{ png="tony_matte", world="any" },
	{ png="KO_matte", world="ko" },
	{ png="prism_hologram", world="ko" },
	{ png="Plastek_matte", world="plastech" },
	{ png="Droid_matte", world="sankaku" },
}
----------------------------------------------------------------

local function waitForClick()
    local done = false
    local handler =
    {
        onInputEvent = function( self, event )
            if event.eventType == mui_defs.EVENT_MouseDown or (event.eventType == mui_defs.EVENT_KeyDown and event.key == mui_defs.K_ENTER) then
                done = true
            end
        end
    }

    inputmgr.addListener( handler, 1 )
    while not done do
        coroutine.yield()
    end
    inputmgr.removeListener( handler )
end

local function generateLoadTip()
    local tips = STRINGS.LOADING_TIPS
    if tips and #tips > 0 then
        local n = math.random( 1, #tips )
        return tips[ n ]
    end
end

local function runUnloadThread( nextState, ... )
	KLEIResourceMgr.ClearResources()

	MOAIFmodDesigner.playSound("SpySociety/AMB/office", "AMB1")
	MOAIFmodDesigner.setVolume( "AMB1", 0 )	
	MOAIFmodDesigner.playSound("SpySociety/AMB/mainframe", "AMB2")
	MOAIFmodDesigner.setVolume( "AMB2", 0 )	

	statemgr.activate( nextState, ... )
end


local function runLoadLocalThread( stateLoad, params, stateGame, sim_history )

	MOAIFmodDesigner.playSound("SpySociety/AMB/office", "AMB1")
	MOAIFmodDesigner.setVolume( "AMB1", 0 )	
	MOAIFmodDesigner.playSound("SpySociety/AMB/mainframe", "AMB2")
	MOAIFmodDesigner.setVolume( "AMB2", 0 )	

	local simCore, levelData = gameobj.constructSim( params )
	FMODMixer:popMix( "nomusic" ) -- Matches to the pushMix in playMusic().
	statemgr.activate( stateGame, params, simCore, levelData, sim_history, 0 )
end


local function runLoadThread( stateLoad, params, stateGame, campaign, simHistoryIdx )

	MOAIFmodDesigner.playSound("SpySociety/AMB/office", "AMB1")
	MOAIFmodDesigner.setVolume( "AMB1", 0 )	
	MOAIFmodDesigner.playSound("SpySociety/AMB/mainframe", "AMB2")
	MOAIFmodDesigner.setVolume( "AMB2", 0 )	

    local situationData = serverdefs.SITUATIONS[ params.situationName ]
    local corpData = serverdefs.CORP_DATA[ params.world ]
    if situationData and corpData then
        stateLoad.screen:findWidget( "TextGroup" ):setVisible( true )
        local missionTxt = corpData.stringTable.SHORTNAME .." " .. situationData.ui.locationName
        stateLoad.screen.binder.titleTxt:setText(missionTxt)
        stateLoad.screen.binder.corpLogo:setImage(corpData.imgs.logoLarge)
    end

	

    local tip = ""
    if campaign and (corpData.world == "omni" or corpData.world == "omni2" )then
		stateLoad.screen.binder.loadingBG:setImage( "gui/menu pages/loading/finalmission.png")
    elseif campaign and campaign.campaignDifficulty == simdefs.TUTORIAL_DIFFICULTY then
    	tip = STRINGS.LOADING_TIP_TUTORIAL 
    elseif campaign and campaign.missionCount == 0 then
    	tip =   STRINGS.LOADING_TIP_FIRST
    else
    	local images = {}
    	for _, v in ipairs(LOADING_IMAGES) do
    		if v.world == "any" or (corpData and v.world == corpData.world) then
    			table.insert( images, v )
    		end
    	end

		local idx = math.random(1,#images)
		stateLoad.screen.binder.loadingBG:setImage( "gui/menu pages/loading/"..images[idx].png..".png")
    	tip = generateLoadTip()
    end

	if situationData.ui.tip then
    	tip = situationData.ui.tip 
    end

	local sim_history = nil
	local uiMemento = nil
	local simCore, levelData = gameobj.constructSim( params )
	if campaign and campaign.sim_history then
		local serializer = include( "modules/serialize" )
		sim_history = campaign.sim_history and serializer.deserialize( campaign.sim_history )
		uiMemento = campaign.uiMemento
		simHistoryIdx = simHistoryIdx or #sim_history
        if simHistoryIdx < #sim_history then
            sim_history[ simHistoryIdx ].rewindError = true
        end
		local simguard = include( "modules/simguard" )
		local st = os.clock()
		simguard.start()
		for i = 1, simHistoryIdx do
			local action = sim_history[i]
			simCore:applyAction( action )
            if not simCore:isGameOver() then
                loading.lastActionIndex = i -- Save this in case of errors so we can fast-forward to last good state
            end
		end
		simguard.finish()
		log:write( "\tAdvanced %d/%d sim actions (Took %.2f ms).", simHistoryIdx, #sim_history, (os.clock() - st) * 1000 )
	end

    local auto_load = #config.LAUNCHLVL > 0
    if not auto_load then

    	local partial = campaign and campaign.sim_history
    	local waitTime = 1.2*cdefs.SECONDS

    	if partial or simCore:getTags().isTutorial then
			stateLoad.screen.binder.tipTxt:spoolText("<c:8CFFFF>"..tip.."</>")
	    	MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/loading" )
	    	rig_util.wait( waitTime )

	    	MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/loading" )
	    	rig_util.wait( waitTime )		
		else

            for k,v in ipairs( STRINGS.UI.GENERATING_WORLD ) do
                MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/loading" )
                stateLoad.screen.binder.tipTxt:spoolText( string.format("<c:FAFD68>%s</>", v ))
                rig_util.wait( waitTime )
            end

			MOAIFmodDesigner.playSound( "SpySociety/HUD/menu/loading_end" )
            stateLoad.screen.binder.tipTxt:spoolText("<c:8CFFFF>"..tip.."</>")
            rig_util.wait( waitTime )
            
		end

        local endless_mode = campaign and campaign.difficultyOptions.maxHours == math.huge
        

        local warning_sound = partial and "SpySociety/VoiceOver/Incognita/Pickups/LoadMidLevel_Day1" or "SpySociety/VoiceOver/Incognita/Loading/Incognita_Loading_Level1"
        
        if campaign and not endless_mode then
            if campaign.currentDay == 1 then
                warning_sound = partial and "SpySociety/VoiceOver/Incognita/Pickups/LoadMidLevel_Day2" or "SpySociety/VoiceOver/Incognita/Loading/Incognita_Loading_Level2" 
            elseif campaign.currentDay == 2 then
                warning_sound = partial and "SpySociety/VoiceOver/Incognita/Pickups/LoadMidLevel_Day3" or "SpySociety/VoiceOver/Incognita/Loading/Incognita_Loading_Level3" 
            elseif campaign.currentDay > 2 then
                warning_sound = partial and "SpySociety/VoiceOver/Incognita/Pickups/LoadMidLevel_Day4" or "SpySociety/VoiceOver/Incognita/Loading/Incognita_Loading_Last" 
            end
        end

        if simCore:getTags().isTutorial then
            warning_sound = "SpySociety/VoiceOver/Incognita/Pickups/Tutorial_Connection"
        end

        MOAIFmodDesigner.playSound(warning_sound)

        stateLoad.screen.binder.doneTxt:setVisible( true )
        stateLoad.screen.binder.connectionImg:setVisible( false )
        stateLoad.screen.binder.doneTxt:loopUpdate( mui_util.loopSpool )

        waitForClick()
    end

	FMODMixer:popMix( "nomusic" ) -- Matches to the pushMix in playMusic().
	statemgr.activate( stateGame, params, simCore, levelData, sim_history, simHistoryIdx, uiMemento )
end

local function onLoadError( self, result )
	moai.traceback( "Loading traceback:\n".. tostring(result), self.loadThread )

	local simguard = include( "modules/simguard" )
	simguard.finish()
	statemgr.deactivate( self )

	FMODMixer:popMix( "nomusic" ) -- Matches to the pushMix in playMusic().

	local stateMainMenu = include( "states/state-main-menu" )
	statemgr.activate( stateMainMenu() )
	util.coDelegate(
		function()
			local errMsg = util.formatGameInfo() .. "\n" .. tostring(result)
			modalDialog.show( errMsg, "Loading Error" )
		end )
end

local function onLoadCampaignError( campaign, params, self, result )
    local err = util.formatParamsInfo( params )
    err = err .. "\n" .. util.formatCampaignInfo( campaign )
    err = err .."\nLoading traceback:\n".. tostring(result)
	moai.traceback( err, self.loadThread )

	local simguard = include( "modules/simguard" )
	simguard.finish()
	statemgr.deactivate( self )

	FMODMixer:popMix( "nomusic" ) -- Matches to the pushMix in playMusic().

	util.coDelegate(
		function()
			local body = util.sformat( STRINGS.LOADING.ERR_BODY, result )
			local result = modalDialog.showYesNo( body, STRINGS.LOADING.ERR_TITLE, STRINGS.LOADING.TRY_AGAIN, nil, nil, true )
			if result == modalDialog.OK then
				self:loadCampaign( campaign, self.lastActionIndex or 1 )
			elseif result == modalDialog.AUX then
				local user = savefiles.getCurrentGame()
				local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
				if campaign then
					campaign.seed = campaign.seed + 1
					campaign.uiMemento = nil
					campaign.sim_history = nil
                    campaign.missionVersion = version.VERSION
					log:write( "Load failure: user opted to try new seed (now %u)", campaign.seed )
					user:save()
				end
				self:loadCampaign( campaign )
			else
				local stateMainMenu = include( "states/state-main-menu" )
				statemgr.activate( stateMainMenu() )
			end
		end )
end

local function playMusic( params )
	MOAIFmodDesigner.stopSound("theme")
	FMODMixer:popMix("frontend")

	MOAIFmodDesigner.startMusic( params.music )
	MOAIFmodDesigner.setMusicProperty("intensity",0)
	MOAIFmodDesigner.setMusicProperty("mode",0)
	MOAIFmodDesigner.setMusicProperty("kick",0)
	-- Not the best, but this lets mission script control when exactly the music comes in.
	FMODMixer:pushMix( "nomusic" )
end


----------------------------------------------------------------

loading.loadCampaign = function( self, campaign, simHistoryIdx )
	local params = simparams.createCampaign( campaign )

	playMusic( params )

	self.errorFn = util.makeDelegate( nil, onLoadCampaignError, campaign, params )

	log:write( "### CAMPAIGN [ %s, mission %u, %u hrs, r%s ]\n### PARAMS: [ %s, seed = %u, difficulty = %u]",
		campaign.situation.name, campaign.missionCount, campaign.hours, tostring(campaign.version), params.world, params.seed, params.difficulty )

	local stateCampaignGame = include( "states/state-campaigngame" )
	statemgr.activate( loading, runLoadThread, self, params, stateCampaignGame(), campaign, simHistoryIdx )
end

loading.loadLocalGame = function( self, params, simHistory )

	playMusic( params )

	log:write( "### LOCAL GAME PARAMS: [ %s, seed = %u ]",
		params.levelFile, params.seed )

	local stateGame = include( "states/state-localgame" )
	statemgr.activate( loading, runLoadLocalThread, self, params, stateGame(), simHistory )
end

loading.loadFrontEnd = function( self )
	local stateMainMenu = include( "states/state-main-menu" )
	statemgr.activate( loading, runUnloadThread, stateMainMenu() )
end

loading.loadUpgradeScreen = function( self, agency, endless, post_mission, suppress_map_intro )
	local stateUpgradeScreen = include( "states/state-upgrade-screen" )
	statemgr.activate( loading, runUnloadThread, stateUpgradeScreen, agency, endless, post_mission, suppress_map_intro )
end

loading.loadMapScreen = function( self, campaign )
	local stateMapScreen = include( "states/state-map-screen" )
	assert( campaign )
	statemgr.activate( loading, runUnloadThread, stateMapScreen(), campaign )
end

----------------------------------------------------------------
loading.onLoad = function ( self, fn, ... )

	self.startTime = os.clock()

    self.screen = mui.createScreen( "loading_screen.lua" )
    mui.activateScreen( self.screen )

    local overlay = self.screen:findWidget("overlay")
    overlay:setVisible(true)
    overlay:setColor(0,0,0,1)
    
    self.screen:findWidget( "TextGroup" ):setVisible( false )
    
    self.fadeThread = MOAICoroutine.new()
    self.fadeThread:run( function()       
        local fade_time = .5
        local t = 0
        while t < fade_time do
            t = t + 1/cdefs.SECONDS
            local percent = math.min(1, math.max(0, t / fade_time))
            overlay:setColor(0, 0, 0, 1 - percent)
            coroutine.yield()
        end
        overlay:setVisible(false)
    end)

	self.loadThread = coroutine.create( fn )
	self.loadParams = { ... }
end

----------------------------------------------------------------
loading.onUnload = function ( self )
    mui.deactivateScreen( self.screen )
    self.fadeThread = nil
    self.screen = nil
	self.loadThread = nil
	self.errorFn = nil

	util.fullGC()
	log:write( "## Load screen took: %.1f ms", 1000 * (os.clock() - self.startTime) )
end

loading.onUpdate = function( self )
	local ok, result = coroutine.resume( self.loadThread, unpack(self.loadParams) )
	if not ok then
		util.callDelegate( self.errorFn or onLoadError, self, result )

	elseif coroutine.status( self.loadThread ) == "dead" then
        statemgr.deactivate( self )
	end
end

return loading

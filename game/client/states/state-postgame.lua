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
local cdefs = include( "client_defs" )
local mui_defs = include( "mui/mui_defs" )
local mission_scoring = include("mission_scoring")
local mission_recap_screen = include ("hud/mission_recap_screen")
local metrics = include( "metrics" )
local ENDGAMEFLOW = mission_scoring.ENDGAMEFLOW
local death_dialog = include( "hud/death_dialog" )
local movieScreen = include('client/fe/moviescreen')
local serverdefs = include( "modules/serverdefs" )
local version = include( "modules/version" )
local simdefs = include( "sim/simdefs" )
local stateMapScreen = include( "states/state-map-screen" )
local stateTeamPreview = include( "states/state-team-preview" )
local SCRIPTS = include('client/story_scripts')
local agentdefs = include("sim/unitdefs/agentdefs")

----------------------------------------------------------------
local postgame = class()

----------------------------------------------------------------
function postgame:onLoad(sim, params, num_actions)
    log:write( "\tpostgame:onLoad()" )
    MOAIFmodDesigner.stopSound("alarm")
    MOAIFmodDesigner.playSound( "SpySociety/Music/stinger_victory")
    MOAIFmodDesigner.stopMusic()
    MOAIFmodDesigner.playSound("SpySociety/Music/music_map","theme")		
    FMODMixer:pushMix("frontend")

    self._sim = sim
    self._params = params
        
    --save these because they get wiped when we finalize a losing game
    local user = savefiles.getCurrentGame()
    local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
    local oldcampaignDifficulty, olddifficultyOptions = campaign.campaignDifficulty, campaign.difficultyOptions   


    -- CHECK FOR CAMPAIGN EVENTS
    if campaign.campaignEvents then
        for i=#campaign.campaignEvents,0,-1 do
            local event = campaign.campaignEvents[i] 
            if event then
             --   local hoursLeft = campaign.difficultyOptions.maxHours - campaign.hours
                if event.eventType == simdefs.CAMPAIGN_EVENTS.ADD_MORE_HOURS then
                    if self._params.situationName == event.mission then
                        campaign.difficultyOptions.maxHours = campaign.difficultyOptions.maxHours + event.data
                        print("ADDING CAMPAIGN HOURS", event.mission)
                        table.remove(campaign.campaignEvents,i)
                    end
                end

                if event.eventType == simdefs.CAMPAIGN_EVENTS.ADVANCE_TO_NEXT_DAY then                 
                    if self._params.situationName == event.mission then
                        local int,fraction = math.modf(campaign.hours/24)
                        local adjustmentHours = 24 - (fraction*24)
                        print("JUMPING TO NEXT DAY", event.mission, adjustmentHours )
                        campaign.situation.advanceHours = adjustmentHours 
                        table.remove(campaign.campaignEvents,i)     
                    end
                end  
                if event.eventType == simdefs.CAMPAIGN_EVENTS.SET_CUSTOM_SCRIPT_INDEX then                 
                    if self._params.situationName == event.mission then
                        print("SETTING CUSTOM SCRIPT INDEX", event.data )
                        campaign.customScriptIndex = event.data
                        table.remove(campaign.campaignEvents,i)     
                    end
                end    
                if event.eventType == simdefs.CAMPAIGN_EVENTS.SET_CAMPAIGN_PARAM then                 
                    if self._params.situationName == event.mission then
                        if event.data.agency then
                            print("SETTING AGENCY PARAM" )
                            if event.data.value then
                                campaign.agency[event.data.param] = event.data.value
                            else
                                campaign.agency[event.data.param] = true
                            end
                        else
                            print("SETTING CAMPAIGN PARAM" )
                          --  campaign.missionEvents[event.data.params] = true
                            if event.data.value then
                                campaign.missionEvents[event.data.param] = event.data.value
                            else
                                campaign.missionEvents[event.data.param] = true
                            end                            
                        end
                        table.remove(campaign.campaignEvents,i)     
                    end
                end                   
                if event.eventType == simdefs.CAMPAIGN_EVENTS.REMOVE_AGENT then                 
                    if self._params.situationName == event.mission then
                        print("REMOVING EXTRA AGENT", event.data )

                        local player = sim:getPC()                    
                        for agentID, deployData in pairs( player:getDeployed() ) do
                            print(agentID)
                            if deployData.agentDef.id == event.data then
                               deployData.agentDef.leave = true
                            end
                        end

                        table.remove(campaign.campaignEvents,i)     
                    end
                end                                       
            end
        end
    end

    --do our scoring stuff
    local flow_result  = mission_scoring.DoFinishMission(sim, campaign)
    metrics.level_finished():send( params, num_actions, sim )
    
    if flow_result == ENDGAMEFLOW.WON_CAMPAIGN then
        movieScreen("data/movies/end_Cinematic.ogv", function() self:OnFinalMovieDone( ) end, SCRIPTS.SUBTITLES.END)

    elseif flow_result == ENDGAMEFLOW.GAME_OVER then
        local screen = mission_recap_screen()
        screen:show(sim._resultTable,
            function()
                local rewardsDialog = death_dialog()
                rewardsDialog:show( false, function( option )

                    if option == 1 then

                        local user = savefiles.getCurrentGame()
                        local campaign = user.data.saveScumLevelSlots[ user.data.currentSaveSlot ]
                        if campaign then
                            campaign.hasShownInitialDeathTip = true
                            campaign.agency.missions_completed_1 = 0
                            campaign.agency.missions_completed_2 = 0
                            campaign.agency.missions_completed_3 = 0
                            sim:getStats():setStat( "missions_completed_1", 0 )
                            sim:getStats():setStat( "missions_completed_2", 0 )
                            sim:getStats():setStat( "missions_completed_3", 0 )

                            campaign.seed = campaign.seed + 1
                            campaign.uiMemento = nil
                            campaign.sim_history = nil
                            campaign.missionVersion = version.VERSION
                        end

                        user.data.saveSlots[ user.data.currentSaveSlot ] = util.tcopy( campaign )
                        user:save()

                        local stateLoading = include( "states/state-loading" )
                        statemgr.deactivate( self )
                        stateLoading:loadCampaign( campaign )

                    elseif option == 2 then

                        local user = savefiles.getCurrentGame()
                        local campaign = user.data.saveScumDaySlots[ user.data.currentSaveSlot ]
                        if campaign then
                            campaign.hasShownInitialDeathTip = true
                            campaign.agency.missions_completed_1 = 0
                            campaign.agency.missions_completed_2 = 0
                            campaign.agency.missions_completed_3 = 0
                            sim:getStats():setStat( "missions_completed_1", 0 )
                            sim:getStats():setStat( "missions_completed_2", 0 )
                            sim:getStats():setStat( "missions_completed_3", 0 )

                            campaign.seed = campaign.seed + 1
                            campaign.uiMemento = nil
                            campaign.sim_history = nil
                            campaign.missionVersion = version.VERSION
                        end

                        user.data.saveSlots[ user.data.currentSaveSlot ] = util.tcopy( campaign )
                        user:save()

                        local stateMapScreen = include( "states/state-map-screen" )
                        statemgr.activate( stateMapScreen(), campaign )
                        statemgr.deactivate( self )

                    else

                        --jcheng: :(
                        FMODMixer:popMix("nomusic")
                        FMODMixer:pushMix("frontend")
                        MOAIFmodDesigner.stopMusic()
                        MOAIFmodDesigner.stopSound("theme")

                        MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT ) 
                        MOAIFmodDesigner.playSound("SpySociety/Music/music_title","theme")

                        local stateGenerationOptions = include( "states/state-generation-options" )
                        statemgr.activate( stateGenerationOptions(), oldcampaignDifficulty, olddifficultyOptions )
                        statemgr.deactivate( self )

                    end
                end)
            end )

    else
        local screen = mission_recap_screen()
        screen:show(sim._resultTable, function() self:OnFinishRecap( flow_result ) end )
        user:save()
    end
end


function postgame:onUnload()
    FMODMixer:popMix("frontend")
end

----------------------------------------------------------------
function postgame:onUpdate()

end


function postgame:OnFinalMovieDone()
    local rewardsDialog = death_dialog()
    
    local user = savefiles.getCurrentGame()
    local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
    local oldcampaignDifficulty, olddifficultyOptions = campaign.campaignDifficulty, campaign.difficultyOptions

    MOAIFmodDesigner.playSound("SpySociety/Music/music_map","theme")
    FMODMixer:pushMix("frontend")

    rewardsDialog:show( true, function()
        if oldcampaignDifficulty < simdefs.VERY_HARD_DIFFICULTY and oldcampaignDifficulty ~= -1 then
            oldcampaignDifficulty = oldcampaignDifficulty + 1
            olddifficultyOptions = nil
        end

        MOAIFmodDesigner.stopSound("theme")

        MOAIFmodDesigner.playSound( cdefs.SOUND_HUD_GAME_WOOSHOUT ) 
        MOAIFmodDesigner.playSound("SpySociety/Music/music_title","theme")

        local stateGenerationOptions = include( "states/state-generation-options" )
        statemgr.activate( stateGenerationOptions(), oldcampaignDifficulty, olddifficultyOptions )
        statemgr.deactivate( self )

    end)
end

function postgame:OnFinishRecap( flow_result )

    if flow_result == ENDGAMEFLOW.DONE_TUTORIAL then
        
        --go to the campaign generation screen
        local stateGenerationOptions = include( "states/state-generation-options" )
        statemgr.activate( stateGenerationOptions(), simdefs.NORMAL_DIFFICULTY )
        statemgr.deactivate( self )

        --movieScreen("data/movies/IntroCinematic.ogv", function() self:OnIntroMovieDone() end)
    elseif flow_result == ENDGAMEFLOW.CONTINUE_FINAL_MISSION then
        -- TODO: remove me.  don't think this happens for 1-level final mission.
        local user = savefiles.getCurrentGame()
        local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
        statemgr.deactivate( self )
        stateLoading:loadCampaign( campaign )
    
    elseif flow_result == ENDGAMEFLOW.CONTINUE_CAMPAIGN then
        local user = savefiles.getCurrentGame()
        local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]
        local situation = nil


        -- CHECK FOR CAMPAIGN EVENTS THAT START NEW LEVELS
        if campaign.campaignEvents then
            for i=#campaign.campaignEvents,0,-1 do
                local event = campaign.campaignEvents[i] 
                if event and event.eventType == simdefs.CAMPAIGN_EVENTS.GOTO_MISSION then
                    if self._params.situationName == event.mission then
                        situation = { name = event.data.mission, difficulty = self._params.difficulty, mapLocation = nil, corpData=event.data.corp}
                        print("SETTING SEQUEL MISSION")
                        table.remove(campaign.campaignEvents,i)
                    end
                end
            end
        end


        local endless = campaign.difficultyOptions.maxHours == math.huge 
        statemgr.deactivate( self )

        if situation then
            user.data.saveSlots[ user.data.currentSaveSlot ] = campaign

            user.data.num_games = (user.data.num_games or 0) + 1
            campaign.recent_build_number = util.formatGameInfo()
            campaign.missionVersion = version.VERSION

            campaign.situation = situation
            campaign.preMissionNetWorth = serverdefs.CalculateNetWorth(campaign)

            if not user.data.saveScumLevelSlots then 
                user.data.saveScumLevelSlots = {}
            end

            user.data.saveScumLevelSlots[ user.data.currentSaveSlot ] = util.tcopy( user.data.saveSlots[ user.data.currentSaveSlot ] )
            user:save()
            metrics.app_metrics:incStat( "new_games" )
            
            stateLoading:loadCampaign( campaign )            
        else
            stateLoading:loadUpgradeScreen( campaign.agency, endless, true )
        end
    else
        assert(nil, "UNKNOWN LEVEL FINISH TYPE")
    end
end


return postgame

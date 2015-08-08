----------------------------------------------------------------
-- Copyright (c) 2012 Klei Entertainment Inc.
-- All Rights Reserved.
-- SPY SOCIETY.
----------------------------------------------------------------

local mui = include( "mui/mui" )
local util = include( "client_util" )
local array = include( "modules/array" )
local serverdefs = include( "modules/serverdefs" )
local version = include( "modules/version" )
local gameobj = include( "modules/game" )
local cdefs = include("client_defs")
local agentdefs = include("sim/unitdefs/agentdefs")
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local rig_util = include( "gameplay/rig_util" )
local weighted_list = include( "modules/weighted_list" )
local unitdefs = include( "sim/unitdefs" )
local mission_recap_screen = include ("hud/mission_recap_screen")
local death_dialog = include( "hud/death_dialog" )
local stateLoading = include( "states/state-loading" )
local stateMapScreen = include( "states/state-map-screen" )
local rand = include( "modules/rand" )
----------------------------------------------------------------
-- Local functions


local ENDGAMEFLOW =
{
    CONTINUE_CAMPAIGN = "CONTINUE_CAMPAIGN",
    DONE_TUTORIAL = "DONE_TUTORIAL",
    GAME_OVER = "GAME_OVER",
    WON_CAMPAIGN = "WON_CAMPAIGN",
    CONTINUE_FINAL_MISSION = "CONTINUE_FINAL"
}


local CLEANING_COST_BASE = 50 
local CLEANING_COST_EXPONENT = 1.3

------------------------------SCORE CALCULATION STUFF


local function calculateExplorationBonus( sim, player )
    local exploreCount = 0
    local totalCount = 0
    sim:forEachCell(
        function( cell )
            if not cell.isSolid then
                totalCount = totalCount + 1
                if player:getCell( cell.x, cell.y ) ~= nil then
                    exploreCount = exploreCount + 1
                end
            end
        end )

    local explorePercent = exploreCount / totalCount
    local exploreBonus = nil

    -- Do we get a credit bonus for exploration?
    for agentID, deployData in pairs( player:getDeployed() ) do
        if deployData.escapedUnit and deployData.escapedUnit:countAugments( "augment_microslam_apparatus" ) > 0 then
            exploreBonus = simquery.scaleCredits( sim, explorePercent * 300 )
            break
        end
    end

    return explorePercent, exploreBonus
end

local function sortLootTable( loot_table, agency_upgrades, post_upgrades)
    for upgrade,v in pairs(agency_upgrades) do
        for k = 1, v do
            if post_upgrades[upgrade] then
                post_upgrades[upgrade] =  math.max(post_upgrades[upgrade] -1,0)
            end
        end         
    end

    for lootitem,v in pairs(post_upgrades) do
        --these items are handled specially in the final mission
        if lootitem ~= "augment_central" and lootitem ~= "item_monst3r_gun" then
            for k = 1, v do
            table.insert(loot_table, lootitem) 
            end
        end
    end    
end


local function getNewItemsForUnit( agentDef, unit, agency_upgrades, post_upgrades)

    for _,childUnit in ipairs( unit:getChildren() ) do
        local upgradeName = childUnit:getUnitData().upgradeName
        if upgradeName then
            post_upgrades[upgradeName] = post_upgrades[upgradeName] and post_upgrades[upgradeName] + 1 or 1
        end
    end

    for _, v in pairs(agentDef.upgrades) do
        local upg = type(v) == "string" and v or v.upgradeName
        if upg then
            agency_upgrades[upg] = agency_upgrades[upg] and agency_upgrades[upg] + 1 or 1
        end
    end
end

local function updateAgentFromSim( agentDef, unit )
    -- Feh.  Clear upgrades so we can add them back from the sim unit's inventory.
    util.tclear( agentDef.upgrades )

    if unit:getTraits().temp_skill_points then
        local skills = unit:getSkills()
        for i,skill in ipairs(unit:getTraits().temp_skill_points) do
            skills[skill]:levelDown( unit:getSim(), unit )
        end
    end

    for _,childUnit in ipairs( unit:getChildren() ) do
        local upgradeName = childUnit:getUnitData().upgradeName        
        if upgradeName then
            local unitData = childUnit:getUnitData()
            if childUnit:getUnitData().upgradeOverride then
               upgradeName = childUnit:getUnitData().upgradeOverride
               unitData =  unitdefs.lookupTemplate( upgradeName ) 
            end
            local upgradeParams = unitData.createUpgradeParams and unitData:createUpgradeParams( childUnit )
            table.insert( agentDef.upgrades, { upgradeName = upgradeName, upgradeParams = upgradeParams })
        end
    end

    local templateData = unitdefs.lookupTemplate( agentDef.template )
    local newAugmentSlots = unit:getTraits().augmentMaxSize - templateData.traits.augmentMaxSize 
    for i= 1, newAugmentSlots do                
        table.insert( agentDef.upgrades,"augmentUpgradeSlot")
    end

    agentDef.skills = {}
    for _, skill in ipairs( unit:getSkills() ) do
        table.insert( agentDef.skills, { skillID = skill:getID(), level = skill:getCurrentLevel() } )
    end
end


local function updateAgencyFromAgent( escapedUnit, sim, agency )
    for _,childUnit in ipairs( escapedUnit:getChildren() ) do
        if childUnit:getTraits().newLocations then
            agency.newLocations = util.tmerge( agency.newLocations, childUnit:getTraits().newLocations )
        end

        if childUnit:getTraits().cashInReward then
            local value = sim:getQuery().scaleCredits(sim, childUnit:getTraits().cashInReward )
            sim:addMissionReward(value)
            sim._resultTable.credits_gained.stolengoods = sim._resultTable.credits_gained.stolengoods and sim._resultTable.credits_gained.stolengoods + value or value 
        end
    end
end


local function updateAgencyFromSim( campaign, sim, situation )
    local player = sim:getPC()

    local agency = campaign.agency

    if sim._resultTable.mission_won then
        if situation.difficulty == 1 then
            sim:getStats():incStat( "missions_completed_1" )
        elseif situation.difficulty == 2 then
            sim:getStats():incStat( "missions_completed_2" )
        else
            sim:getStats():incStat( "missions_completed_3" )
        end
    end
    
    serverdefs.updateStats( agency, sim )

    if simquery.findUnit( sim:getAllUnits(), function( u ) return u:getTraits().storeType == "miniserver" end ) then
        campaign.miniserversSeen = (campaign.miniserversSeen or 0) + 1
    end

    -- Transfer player abilities
    agency.abilities = {}
    for _, ability in ipairs( player:getAbilities() ) do
        if not ability.no_save then
            local abilityID = ability:getID()
            if ability.abilityOverride then
                abilityID = ability.abilityOverride
            end
            table.insert( agency.abilities, abilityID )
        end
    end

    -- Transfer agent data.
    agency.newLocations = sim:getNewLocations()

    local agency_upgrades = {}
    local post_upgrades = {}

    local numAgentsHired = 0
    local i = 0
    for agentID, deployData in pairs( player:getDeployed() ) do
        local agentDef = serverdefs.findAgent( agency, agentID )

        -- deployData.id existence implies this agent was deployed and assigned a unit ID.          
        if deployData.id then
            i = i + 1
            
            if agentDef == nil then -- This is a rescued unit that doesn't exist in the agency, yet.
                
                table.insert(sim._resultTable.agents, {name=deployData.agentDef, status="RESCUED"})
                agentDef = deployData.agentDef
                serverdefs.assignAgent( agency, agentDef )
                numAgentsHired = numAgentsHired + 1
            end

            if deployData.escapedUnit and not deployData.agentDef.leave then --active agent who returned

                table.insert(sim._resultTable.agents, {name=agentDef.template, status="ACTIVE"})
                getNewItemsForUnit( agentDef, deployData.escapedUnit, agency_upgrades, post_upgrades )

                updateAgentFromSim( agentDef, deployData.escapedUnit )
                 -- Determine what the escaped agent brings back to the agency.
                updateAgencyFromAgent( deployData.escapedUnit, sim, agency )
                
                -- Keep track which exit this agent escaped from.
                agentDef.deployID = deployData.exitID

                local data = deployData.escapedUnit:getUnitData()
                --widget.binder.name:setText( util.toupper(deployData.escapedUnit:getName()) )
                
                
            elseif deployData.agentDef.leave then
                table.insert(sim._resultTable.agents, {name=agentDef.template, status="EXITED"})

                --Is this necesary?
                local unit = sim:getUnit( deployData.id )
                if unit then
                    updateAgentFromSim( agentDef, unit )
                end                

                local k = array.find( agency.unitDefs, agentDef )
                table.remove( agency.unitDefs, k )                

            else
                --killed!
                table.insert(sim._resultTable.agents, {name=agentDef.template, status="MIA"})

                local unit = sim:getUnit( deployData.id )
                if unit then
                    updateAgentFromSim( agentDef, unit )
                end
                local data = unitdefs.lookupTemplate( agentDef.template )

                -- Remove this agent from the agency.
                local k = array.find( agency.unitDefs, agentDef )
                agentDef.captureTime = campaign.hours -- Keep track of when this agent was captured.
                table.insert( agency.unitDefsPotential, table.remove( agency.unitDefs, k ))
            end
        end
    end
    
    sortLootTable( sim._resultTable.loot, agency_upgrades, post_upgrades)

    -- Remove capture status for any agents that were available for rescue, but were not rescued.
    for i, agentDef in ipairs( agency.unitDefsPotential ) do
        if agentDef.captureTime and agentDef.id == sim:getTags().hadAgent then
            agentDef.captureTime = nil
        end
    end


end

local function CheckAchievements( campaign, sim )
    if campaign.campaignDifficulty >= simdefs.HARD_DIFFICULTY then
        if (sim:getStats().max_tracker or 0) >= simdefs.TRACKER_MAXCOUNT then
            savefiles.winAchievement( cdefs.ACHIEVEMENTS.THE_LIMIT )
        end
    end
    if campaign.campaignDifficulty >= simdefs.NORMAL_DIFFICULTY then
        if (sim:getStats().times_seen or 0) == 0 then
            savefiles.winAchievement( cdefs.ACHIEVEMENTS.GHOST_MOVES )
        end
    end
end

local function ApplyCreditBonuses( campaign, sim)
    local creditBonus = 0

    
    --1
    --self:addAnalysisStat( STRINGS.UI.CURRENT_CREDITS,  string.format("$"..campaign.agency.cash ), POSITIVE_COLOR )
        --self:addAnalysisStat( STRINGS.UI.MISSION_REWARD, string.format("$"..missionReward), POSITIVE_COLOR )
    --self:addAnalysisStat( STRINGS.UI.KILLS,  cleaningKills, NEGATIVE_COLOR )
    --local alarmLvl = sim:getTrackerStage()
    

    local missionReward = sim:getMissionReward()
    if missionReward ~= nil then
        creditBonus = creditBonus + missionReward
    end

    local explorePercent, exploreBonus = calculateExplorationBonus( sim, sim:getPC() )
    if exploreBonus then
        creditBonus = creditBonus + exploreBonus

        sim._resultTable.credits_gained.mapping = exploreBonus

    end

    if sim:getWinner() then
        local cleaningKills = sim:getCleaningKills()
        local cleaningBonus = 0
        if cleaningKills > 0 then
            cleaningBonus = math.floor( (cleaningKills ^ CLEANING_COST_EXPONENT) * CLEANING_COST_BASE)
        end
        creditBonus = creditBonus - cleaningBonus

        sim._resultTable.credits_lost.cleanup = cleaningBonus

    end
    


    campaign.agency.cash = math.max(0, campaign.agency.cash + creditBonus)
end

local function getNewMonst3rItem(sim, campaign)
    local item = nil
    local gen = rand.createGenerator( campaign.seed )

    local monst3rSellTable = nil

    if campaign.hours < 36 then
        monst3rSellTable = simdefs.ITEMS_SPECIAL_DAY_1
    elseif campaign.hours >= 72 then
        monst3rSellTable = simdefs.ITEMS_SPECIAL_DAY_4
    else
        monst3rSellTable = simdefs.ITEMS_SPECIAL_DAY_2
    end

    if campaign.campaignDifficulty == simdefs.NORMAL_DIFFICULTY then 
        if campaign.missionsPlayedThisDay == 0 then 
            if campaign.hours > 23 and campaign.hours < 48 then 
                monst3rSellTable = simdefs.BEGINNER_ITEMS_SPECIAL_DAY_2
            elseif campaign.hours >= 48 then 
                monst3rSellTable = simdefs.BEGINNER_ITEMS_SPECIAL_DAY_3
            end 
        elseif campaign.hours > 23 then 
            monst3rSellTable = simdefs.BEGINNER_ITEMS_SPECIAL_VARIETY
        end 
    end

    --Is it the beginning of Day 2, Day 3 or Day 4 on Beginner? Otherwise we give ourselves to the random gods
    if campaign.campaignDifficulty == simdefs.NORMAL_DIFFICULTY and campaign.missionsPlayedThisDay == 0 and campaign.hours > 23 then 
        local dropTable = weighted_list( monst3rSellTable )
        local w = gen:nextInt( 1, dropTable:getTotalWeight() )
        item = dropTable:getChoice( w )
    elseif gen:next() < 0.3 or campaign.missionCount == 1 then
        local dropTable = weighted_list( monst3rSellTable )
        local w = gen:nextInt( 1, dropTable:getTotalWeight() )
        item = dropTable:getChoice( w )
    end
    return item
end


local function DoFinishMission( sim, campaign )

    sim._resultTable.final_credits = sim:getPC():getCredits()
    sim._resultTable.mission_won = sim:getWinner()
    sim._resultTable.credits_gained.hostage = sim:getMissionReward()

    for k,v in pairs(sim._resultTable.guards) do
        v.seen = sim:getPC()._seenBefore[ k ]
    end
    for k,v in pairs(sim._resultTable.devices) do
        v.seen = sim:getPC()._seenBefore[ k ]
    end

    local user = savefiles.getCurrentGame()
  --  local campaign = user.data.saveSlots[ user.data.currentSaveSlot ]

    if sim:getTags().hadAgent then
        campaign.agentsFound = (campaign.agentsFound or 0) + 1
    end
    campaign.foundPrisoner = (sim:getTags().hadAgent == nil)

    local corpData = serverdefs.getCorpData( campaign.situation )
    local situationData = serverdefs.SITUATIONS[campaign.situation.name]

    local location = campaign.location
    if campaign.situation.mapLocation then
        location = campaign.situation.mapLocation
    end

    sim._resultTable.mission_city = util.toupper(serverdefs.MAP_LOCATIONS[location].name)
    

    sim._resultTable.mission_type = ""
    if situationData and situationData.strings and situationData.strings.MISSION_TITLE then
        sim._resultTable.mission_type = situationData.strings.MISSION_TITLE
    else
        sim._resultTable.mission_type = corpData.stringTable.SHORTNAME .. " " .. situationData.ui.locationName
    end

    local oldFinalSequence = campaign.inFinalSequence
    updateAgencyFromSim( campaign, sim, campaign.situation)
    
    ApplyCreditBonuses( campaign, sim)
    
    local situationTime = serverdefs.calculateTravelTime( campaign.location, campaign.situation.mapLocation ) + serverdefs.BASE_TRAVEL_TIME

    -- if the mission has special hours it advances the game, used for when it should advance automatically to the next day.
    if campaign.situation.advanceHours then
         situationTime = campaign.situation.advanceHours
         print("SPECIAL SITUATION TIME",situationTime)
    end

    if campaign.situation.mapLocation then
        -- if nill, use the previous location (check this)
        campaign.location = campaign.situation.mapLocation
    end

    local finished_final_mission = false

    if serverdefs.isFinalMission( campaign ) then 
        print("IN IS FINAL MISSION")
        finished_final_mission = true
    end 


    if campaign.agency.newLocations then
        for i, newSituation in ipairs( campaign.agency.newLocations ) do
            serverdefs.createCampaignSituations( campaign, 1, newSituation.mission_tags )
        end
        campaign.agency.newLocations = nil
    end

    serverdefs.advanceCampaignTime( campaign, situationTime )

    campaign.missionCount = campaign.missionCount + 1
    if campaign.currentDay == campaign.previousDay then
        campaign.missionsPlayedThisDay = campaign.missionsPlayedThisDay + 1
    else
        campaign.missionsPlayedThisDay = 0
    end

    campaign.agency.monst3rItem = getNewMonst3rItem(sim, campaign)

    campaign.sim_history = nil
    campaign.uiMemento = nil
    campaign.missionVersion = nil

    --close out the tutorial slot
    if campaign.situation.name == serverdefs.TUTORIAL_SITUATION then
        user.data.saveSlots[ user.data.currentSaveSlot ] = nil
    else
        if finished_final_mission then 
            campaign.situation = nil
        end
    end

    if sim:getWinner() ~= nil then
        CheckAchievements( campaign, sim )
    end

    --figure out our end flow, and pass it back so that we know where to go when the screen ends
    local end_type = ENDGAMEFLOW.CONTINUE_CAMPAIGN
    if campaign.situation and campaign.situation.name == serverdefs.TUTORIAL_SITUATION then
        end_type = ENDGAMEFLOW.DONE_TUTORIAL
    elseif sim:getWinner() == nil then
        end_type = ENDGAMEFLOW.GAME_OVER
    elseif finished_final_mission then 
        end_type = ENDGAMEFLOW.WON_CAMPAIGN
    elseif oldFinalSequence then
        end_type = ENDGAMEFLOW.CONTINUE_FINAL_MISSION
    end

    --close of the situation if we're not directly continuing
    if not oldFinalSequence then
        campaign.situation = nil
    end


    sim._resultTable.preNetWorth = campaign.preMissionNetWorth or 0
    sim._resultTable.postNetWorth = serverdefs.CalculateNetWorth(campaign)

    campaign.preMissionNetWorth = nil

    return end_type
end

return { DoFinishMission = DoFinishMission, ENDGAMEFLOW = ENDGAMEFLOW}
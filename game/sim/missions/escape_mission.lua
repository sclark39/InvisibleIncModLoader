local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local mission_util = include( "sim/missions/mission_util" )
local unitdefs = include( "sim/unitdefs" )
local simfactory = include( "sim/simfactory" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local serverdefs = include( "modules/serverdefs" )

---------------------------------------------------------------------------------------------
-- Local helpers

local HISEC_EXIT_DAY = 5

local function isEndlessMode( params, day )
    if params.difficultyOptions.maxHours == math.huge then
        return params.campaignHours >= 24 * (day - 1 )
    end

    return false
end

local mission = class( mission_util.campaign_mission )

function mission:init( scriptMgr, sim )
    mission_util.campaign_mission.init( self, scriptMgr, sim )

    if isEndlessMode( sim:getParams(), HISEC_EXIT_DAY ) then
    	sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_EXIT_PASSCARD, "elevator_1" )
    else
        sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJECTIVE, "elevator_1" )
    end
	sim:openElevator()
    scriptMgr:addHook( "CONNECT", mission_util.makeAgentConnection )
	scriptMgr:addHook( "FTM-SCANNER", mission_util.checkFtmScanner )	

    for i, mod in pairs(mod_manager.modMissionScripts)do
        if mod.init then
            mod.init(scriptMgr, sim )
        end
    end
end

local function makeTags( tag, count )
    local t = {}
    for i = 1, count do
        table.insert( t, tag )
    end
    return unpack( t )
end

local function exitFitnessFn( cxt, prefab, x, y )
    local tileCount = cxt:calculatePrefabLinkage( prefab, x, y )
    if tileCount == 0 then
        return 0 -- Doesn't link up
    end

    local maxDist = mission_util.calculatePrefabDistance( cxt, x, y, "entry" )
    return tileCount + maxDist^2
end

function mission.pregeneratePrefabs( cxt, tagSet )
    if cxt.params.difficulty == 1 then
        table.insert( tagSet, { "entry", makeTags( "struct", cxt.params.difficultyOptions.roomCount ) })
        table.insert( tagSet, { { "exit", exitFitnessFn } })            
    else
        local EXIT_PREFAB = "exit"
        if isEndlessMode( cxt.params, HISEC_EXIT_DAY ) then
            EXIT_PREFAB = "exit_vault"
        end
        table.insert( tagSet, { EXIT_PREFAB, "entry", makeTags( "struct", cxt.params.difficultyOptions.roomCount )})
    end
    
    table.insert( tagSet, { "struct_small", "struct_small" })

        -- SUB OBJECTIVE - RESEARCH LAB
        --table.insert( tagSet, { "research_lab" })
    

    for i, mod in pairs(mod_manager.modMissionScripts)do
        if mod.pregeneratePrefabs then        
            mod.pregeneratePrefabs( cxt, tagSet )
        end
    end
--[[
    if cxt.params.missionEvents and cxt.params.missionEvents.needPowerCells then      
        table.insert( tagSet, { { "powerCell", exitFitnessFn } })
    end
]]
end

function mission.generatePrefabs( cxt, candidates )
    local prefabs = include( "sim/prefabs" )
    if isEndlessMode( cxt.params, HISEC_EXIT_DAY ) then
        prefabs.generatePrefabs( cxt, candidates, "safe_exit_vault", 1 )
    end

    for i, mod in pairs(mod_manager.modMissionScripts)do
        if mod.generatePrefabs then
            mod.generatePrefabs( cxt, candidates )
        end
    end

   -- prefabs.generatePrefabs( cxt, candidates, "powerCell", 1 )

end

return mission

local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local mission_util = include( "sim/missions/mission_util" )
local escape_mission = include( "sim/missions/escape_mission" )
local unitdefs = include( "sim/unitdefs" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local SCRIPTS = include('client/story_scripts')
local serverdefs = include( "modules/serverdefs" )
local cdefs = include( "client_defs" )
---------------------------------------------------------------------------------------------
-- Local helpers



local USE_TERM =
{
    action = "abilityAction",
    --pre = true,
    fn = function( sim, ownerID, userID, abilityIdx, ... )
        local unit, ownerUnit = sim:getUnit( userID ), sim:getUnit( ownerID )
        
        if not unit or not unit:isPC() or not ownerUnit or not ownerUnit:getTraits().bigshopcat then
            return nil
        end

        if ownerUnit:getAbilities()[ abilityIdx ]:getID() == "showItemStore" then
            return ownerUnit
        end
    end,
}


local function useServerTerminal( script, sim, mission)
    local _, terminal = script:waitFor( USE_TERM )
    mission.used_terminal = true
    script:waitFor( mission_util.UI_SHOP_CLOSED )

    terminal:destroyTab()
    local possibleUnits = {}
    for _, unit in pairs( sim:getAllUnits() ) do
        if unit:getTraits().mainframe_item and unit:getPlayerOwner() ~= sim:getPC() and not unit:getTraits().mainframe_program and unit:getTraits().mainframe_status ~= "off" then
            table.insert( possibleUnits, unit )     
        end
    end
    if #possibleUnits > 0 then
        script:waitFrames( .75*cdefs.SECONDS )
        script:queue({type="showIncognitaWarning", txt= STRINGS.UI.WARNING_NEW_DAEMON, vo="SpySociety/VoiceOver/Incognita/Pickups/Warning_New_Daemon"})
        script:waitFrames( .75*cdefs.SECONDS )


        for k=1,3 do 
            if #possibleUnits > 0 then 
                local index = sim:nextRand(1, #possibleUnits)
                local unit = possibleUnits[ index ]
                table.remove( possibleUnits, index )
                
                if sim:isVersion("0.17.6") then
                    local programList = sim:getIcePrograms()
                    unit:getTraits().mainframe_program = programList:getChoice( sim:nextRand( 1, programList:getTotalWeight() ))
                else
                    unit:getTraits().mainframe_program = serverdefs.PROGRAM_LIST[ sim:nextRand(1, #serverdefs.PROGRAM_LIST) ]
                end

                local x, y = unit:getLocation()
                script:queue( { type="pan", x=x, y=y } )

                sim:getPC():glimpseUnit( sim, unit:getID() )
                sim:dispatchEvent( simdefs.EV_UNIT_MAINFRAME_UPDATE, {units = {unit.unitID}, reveal=true} )
                sim:dispatchEvent( simdefs.EV_UNIT_UPDATE_ICE, { unit = unit, ice = unit:getTraits().mainframe_ice, delta = 0, refreshAll = true} )
                sim:dispatchEvent(simdefs.EV_MAINFRAME_INSTALL_NEW_DAEMON, {target=unit})
                sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/mainframe_daemonmove")
                script:waitFrames( 1*cdefs.SECONDS )
            end 
        end 


        local x, y = terminal:getLocation()
        sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
        script:queue( { type="pan", x=x, y=y } )
        script:waitFrames( 1*cdefs.SECONDS )
        script:queue( { script=SCRIPTS.INGAME.AFTERMATH.SERVERFARM[sim:nextRand(1, #SCRIPTS.INGAME.AFTERMATH.SERVERFARM)], type="newOperatorMessage" } )    

        script:queue( 1*cdefs.SECONDS )
        script:queue( { script=SCRIPTS.INGAME.MONSTERCAT_POST[sim:nextRand(1, #SCRIPTS.INGAME.MONSTERCAT_POST)], type="newOperatorMessage" } )

    end

end


local BOUGHT_ITEM =
{       
    trigger = simdefs.TRG_BUY_ITEM,
    fn = function( sim, triggerData )
        if triggerData.shopUnit:getTraits().bigshopcat then
            return true
        end
    end,
}


local function checkBuyItem(script, sim, mission)
    script:waitFor( BOUGHT_ITEM )
    mission.bought_item = true
end


---------------------------------------------------------------------------------------------
-- Begin!

local mission = class( escape_mission )

function mission:init( scriptMgr, sim )
    escape_mission.init( self, scriptMgr, sim )

    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_SERVERFARM, "serverFarm" )			

    scriptMgr:addHook( "USE_TERMINAL", useServerTerminal, nil, self )
    scriptMgr:addHook( "BUY", checkBuyItem, nil, self )


    local function prefn( script, sim, item )
        item:createTab( STRINGS.MISSIONS.UTIL.SERVER_FARM, STRINGS.MISSIONS.UTIL.PROGRAM_UPGRADES_AVAILABLE )
        sim:setClimax(true)
        sim:removeObjective( "serverFarm" )
    end

    function pstfn(script, sim, item) 
        script:queue( 1*cdefs.SECONDS )
        script:queue( { script=SCRIPTS.INGAME.MONSTERCAT_PRE[sim:nextRand(1, #SCRIPTS.INGAME.MONSTERCAT_PRE)], type="newOperatorMessage" } )
    end


    scriptMgr:addHook( "SEE", mission_util.DoReportObject(mission_util.PC_SAW_UNIT("serverFarm"), SCRIPTS.INGAME.SEEOBJECTIVE.SERVERFARM, prefn, pstfn) )
 



 --This picks a reaction rant from Central on exit based upon whether or not an agent has escaped with the loot yet.
    local scriptfn = function()
        local scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.SERVERFARM.MISSED 
        if self.used_terminal then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.SERVERFARM.SAW end
        if self.bought_item then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.SERVERFARM.BOUGHT end
        return scripts[sim:nextRand(1, #scripts)]
    end

    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))    

end


function mission.pregeneratePrefabs( cxt, tagSet )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    table.insert( tagSet[1], "server" )
end


return mission

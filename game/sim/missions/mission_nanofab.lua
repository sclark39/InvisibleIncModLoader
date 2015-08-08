local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local mission_util = include( "sim/missions/mission_util" )
local escape_mission = include( "sim/missions/escape_mission" )
local unitdefs = include( "sim/unitdefs" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local SCRIPTS = include('client/story_scripts')
local mainframe = include( "sim/mainframe" )
local cdefs = include( "client_defs" )
---------------------------------------------------------------------------------------------
-- Local helpers

local OBJECTIVE_ID = "nanofab"

local USE_NANOFAB = 
{
	trigger = simdefs.TRG_CLOSE_NANOFAB,
    fn = function( sim, triggerData )
        if triggerData.unit:getTraits().storeType == "large" then
            return triggerData.unit, triggerData.sourceUnit
       	end
    end
}

local function checkNanofab( script, sim, mission )
    local _, nano, agent = script:waitFor( USE_NANOFAB )
    mission.used_nano = true
	sim:removeObjective( OBJECTIVE_ID )	
    sim.exit_warning = nil
    script:waitFor( mission_util.UI_SHOP_CLOSED )
    mission_util.doRecapturePresentation(script, sim, nano, agent)
end

local BOUGHT_ITEM =
{       
    trigger = simdefs.TRG_BUY_ITEM,
    fn = function( sim, triggerData )
        if triggerData.shopUnit:getTraits().storeType == "large" then
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
    sim.exit_warning = STRINGS.UI.HUD_WARN_EXIT_NANOFAB

    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_NANO_FAB, OBJECTIVE_ID )			

	scriptMgr:addHook( "SEENANO", mission_util.DoReportObject(mission_util.PC_SAW_UNIT_WITH_TRAIT("largenano"), SCRIPTS.INGAME.SEEOBJECTIVE.NANOFAB) )
    scriptMgr:addHook( "NANOFAB", checkNanofab, nil, self )
    scriptMgr:addHook( "BUY", checkBuyItem, nil, self )

    local scriptfn = function()
        local scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.NANOFAB.MISSED 
        if self.used_nano then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.NANOFAB.SAW end
        if self.bought_item then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.NANOFAB.BOUGHT end
        return scripts[sim:nextRand(1, #scripts)]
    end

    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))    

end


function mission.pregeneratePrefabs( cxt, tagSet )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    table.insert( tagSet[1], "nanofab" )
end


return mission

local array = include( "modules/array" )
local util = include( "modules/util" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local mission_util = include( "sim/missions/mission_util" )
local escape_mission = include( "sim/missions/escape_mission" )
local unitdefs = include( "sim/unitdefs" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local SCRIPTS = include('client/story_scripts')
---------------------------------------------------------------------------------------------
-- Local helpers


local USE_AUGMENT = 
{
    trigger = simdefs.TRG_CLOSE_AUGMENT_MACHINE,
    fn = function( sim, triggerData )
        return triggerData.unit, triggerData.user
    end
}

local BOUGHT_AUGMENT =
{       
    trigger = simdefs.TRG_USE_AUGMENT_MACHINE,
    fn = function( sim, triggerData )
        return true
    end,
}


local function checkBuyItem(script, sim, mission)
    script:waitFor( BOUGHT_AUGMENT )
    mission.bought_item = true
end


local OBJECTIVE_ID = "cyberlab"

local function checkAugmentMachine( script, sim, mission )
	local _, cyber = script:waitFor( mission_util.PC_SAW_UNIT("cyberlab") )		
	sim:setClimax(true)
    sim.exit_warning = nil
	sim:removeObjective( OBJECTIVE_ID )
    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_CYBERLAB_2, OBJECTIVE_ID )
    local _, cyberlab, agent = script:waitFor( USE_AUGMENT )
    sim:removeObjective( OBJECTIVE_ID )

    mission.opened_machine = true
    mission_util.doRecapturePresentation(script, sim, cyberlab, agent, true, 3)
end

---------------------------------------------------------------------------------------------
-- Begin!

local mission = class( escape_mission )

function mission:init( scriptMgr, sim )
    escape_mission.init( self, scriptMgr, sim )
    sim.exit_warning = STRINGS.UI.HUD_WARN_EXIT_CYBERLAB

    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_CYBERLAB, OBJECTIVE_ID )			

    scriptMgr:addHook( "AUGMENT", checkAugmentMachine, nil, self )  
    scriptMgr:addHook( "BOUGHT", checkBuyItem, nil, self )  
    scriptMgr:addHook( "SEE", mission_util.DoReportObject(mission_util.PC_SAW_UNIT("cyberlab"), SCRIPTS.INGAME.SEEOBJECTIVE.CYBERLAB) )

    local scriptfn = function()
        local scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.CYBERLAB.MISSED 
        if self.opened_machine then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.CYBERLAB.SAW end
        if self.bought_item then scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.CYBERLAB.BOUGHT end
        return scripts[sim:nextRand(1, #scripts)]
    end

    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))    
end


function mission.pregeneratePrefabs( cxt, tagSet )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    table.insert( tagSet[1], "cyberlab" )
end


return mission

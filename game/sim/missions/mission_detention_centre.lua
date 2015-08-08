local array = include( "modules/array" )
local util = include( "modules/util" )
local cdefs = include( "client_defs" )
local simdefs = include( "sim/simdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local mission_util = include( "sim/missions/mission_util" )
local escape_mission = include( "sim/missions/escape_mission" )
local unitdefs = include( "sim/unitdefs" )
local itemdefs = include( "sim/unitdefs/itemdefs" )
local SCRIPTS = include('client/story_scripts')

---------------------------------------------------------------------------------------------
-- Local helpers

local OBJECTIVE_ID = "detentionCenter"

-- This is the chance that an agent will load in the detention centre.  If not, a hostage
-- will be placed there.
local CHANCE_OF_AGENT_IN_DETENTION = 0.5

local PRISONER_ESCAPED = 
{
    trigger = simdefs.TRG_UNIT_ESCAPED,
	fn = function( sim, triggerData )

		local unit = triggerData
        if unit and unit:getTraits().rescued then
            return true -- note that unit has escaped so it is DESPAWNED and not actually valid.
        end
	end,
}


local function highlightprocessor(script, sim)
    local unit = mission_util.findUnitByTag( sim, "detention_processor" )
    if unit then
        sim:getPC():glimpseUnit( sim, unit:getID() )
        unit:createTab( STRINGS.MISSIONS.UTIL.DETENION_PROCESSOR, STRINGS.MISSIONS.UTIL.DETENION_PROCESSOR_SUB )
    end 
    return unit
end


local function checkForAgent( script, sim, mission )
	local _, unit = script:waitFor( mission_util.SAW_SPECIAL_TAG(script, "agent", STRINGS.MISSIONS.UTIL.HEAT_SIGNATURE_DETECTED, STRINGS.MISSIONS.UTIL.RESCUE_PRISONER ) )				
	local template = unitdefs.lookupTemplate( unit:getTraits().template )

    local proc = highlightprocessor(script, sim)
	sim:removeObjective( OBJECTIVE_ID )

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_SEE_AGENT, type="newOperatorMessage" } )	

	script:waitFor( mission_util.PC_USED_ABILITY( "open_detention_cells" ))
	mission.agent_release = true
    sim:setClimax(true)
    sim.exit_warning = nil

    unit:destroyTab()
    proc:destroyTab()

	script:queue( { type="hideHUDInstruction" } )
	script:queue( { body=template.hireText, header=template.name, type="enemyMessage", 
			profileAnim=template.profile_anim,	
			profileBuild=template.profile_anim,	
		} )
	script:queue( 8*cdefs.SECONDS )
	sim:addObjective( string.format(STRINGS.MISSIONS.ESCAPE.OBJ_RESCUE_AGENT,template.name) )	
	script:queue( { type="clearEnemyMessage" } )
	script:queue( { type="clearOperatorMessage" } )

	script:waitFor( PRISONER_ESCAPED )
    mission.agent_escape = true

end

local function getLostAgent( agency )
    -- Get the earliest captured agent from the list.
    local minCaptureTime, lostAgent = math.huge, nil
    for i, agentDef in ipairs(agency.unitDefsPotential) do
        if (agentDef.captureTime or math.huge) < minCaptureTime then
            minCaptureTime, lostAgent = agentDef.captureTime, agentDef
        end
    end

    return lostAgent
end

local function checkPrisonerAgentSwap( script, sim, mission )

    local unit = mission_util.findUnitByTag( sim, "prisoner" )
    if unit == nil then
        return -- No prisoner to swap?!
    end

    if #sim:getPC():getAgents() >= simdefs.AGENT_LIMIT then
        return -- Maxxed out agents
    end

	local agency = sim._params.agency
    local agentDef = getLostAgent( agency )
    
    -- If there aren't any lost agents, pick one of the remaining potentials at random.
	if agentDef == nil and #agency.unitDefsPotential > 0 then

        if (sim:nextRand() < CHANCE_OF_AGENT_IN_DETENTION or sim:getParams().foundPrisoner == true ) or 
           (sim:getParams().campaignDifficulty == simdefs.NORMAL_DIFFICULTY and sim:getParams().agentsFound == 0) then
    		local wt = util.weighted_list()
            for i, agentDef in ipairs(agency.unitDefsPotential) do
                wt:addChoice( agentDef, 1 )
            end
            agentDef = wt:removeChoice( sim:nextRand( 1, wt:getTotalWeight() ))     
        end
    end

    if agentDef then
		local template = unitdefs.prop_templates.agent_capture
		local newUnit = simfactory.createUnit( template, sim )
		local agentTemplate = unitdefs.lookupTemplate( agentDef.template )
					
		newUnit._unitData.kanim = agentTemplate.kanim
		newUnit:getTraits().template = agentDef.template
		newUnit:getTraits().rescueID = agentDef.id
		newUnit:setFacing( unit:getFacing() )
		newUnit:getTraits().rescued = true

		local cell = sim:getCell( unit:getLocation() )
        assert( cell )
		sim:spawnUnit( newUnit )
		sim:warpUnit( newUnit, cell )

		newUnit:addTag("agent")					
		sim:warpUnit( unit, nil )
		sim:despawnUnit( unit )
        sim:getTags().hadAgent = agentDef.id

		script:addHook( "PRISONER-AGENT", checkForAgent, nil, mission )  
	end  
end

local function checkForPrisoner( script, sim, mission )
	local _, prisoner = script:waitFor( mission_util.SAW_SPECIAL_TAG(script, "prisoner", STRINGS.MISSIONS.UTIL.HEAT_SIGNATURE_DETECTED, STRINGS.MISSIONS.UTIL.RESCUE_PRISONER ) )				
    local proc = highlightprocessor(script, sim)
	script:queue( { script=SCRIPTS.INGAME.CENTRAL_SEE_PRISONER, type="newOperatorMessage" } )		

	sim:removeObjective( OBJECTIVE_ID )

	script:waitFor( mission_util.PC_USED_ABILITY( "open_detention_cells" ))
	mission.prisoner_release = true
    sim:setClimax(true)
    sim.exit_warning = nil
    prisoner:destroyTab()
    proc:destroyTab()

	script:queue( { type="hideHUDInstruction" } )
	script:queue( { body=STRINGS.MISSIONS.ESCAPE.PRISONER_CONVO1, header=STRINGS.MISSIONS.ESCAPE.PRISONER_NAME, type="enemyMessage", 
			profileAnim="portraits/portrait_animation_template",
			profileBuild="portraits/portrait_prisoner_build",
		} )
	script:queue( 160 )	

	script:queue( { script=SCRIPTS.INGAME.CENTRAL_PRISONER_CONV, type="newOperatorMessage" } )	

	sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_RESCUE_PRISONER )	
	script:queue( { type="clearEnemyMessage" } )
	script:queue( { type="clearOperatorMessage" } )

	script:waitFor( PRISONER_ESCAPED )
    mission.prisoner_escape = true
	sim:setMissionReward( simquery.scaleCredits( sim, 800 ))
end


local function detentionFitness( cxt, prefab, x, y )
    local tileCount = cxt:calculatePrefabLinkage( prefab, x, y )
    if tileCount == 0 then
        return 0 -- Doesn't link up
    end
    
    -- Maximize distance to exit AND entrance prefab.
    local maxDist = mission_util.calculatePrefabDistance( cxt, x, y, "entry", "exit" )
    return tileCount + maxDist^2
end

local function exitFitnessFn( cxt, prefab, x, y )
    local tileCount = cxt:calculatePrefabLinkage( prefab, x, y )
    if tileCount == 0 then
        return 0 -- Doesn't link up
    end

    local maxDist = mission_util.calculatePrefabDistance( cxt, x, y, "entry", "holdingcell" )
    return tileCount + maxDist^2
end


---------------------------------------------------------------------------------------------
-- Begin!

local mission = class( escape_mission )

function mission:init( scriptMgr, sim )
    escape_mission.init( self, scriptMgr, sim )

	checkPrisonerAgentSwap( scriptMgr, sim, self )

    sim:addObjective( STRINGS.MISSIONS.ESCAPE.OBJ_DETENTION_CENTER, OBJECTIVE_ID )			

    sim.exit_warning = STRINGS.UI.HUD_WARN_EXIT_DETENTION

	scriptMgr:addHook( "PRISONER", checkForPrisoner, nil, self )

    --This picks a reaction rant from Central on exit based upon whether or not an agent has escaped with the loot yet.
    local scriptfn = function()

        local scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.DETENTION.GOTNOTHING
        if self.agent_escape then
            scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.DETENTION.GOTAGENT
        elseif self.agent_release then
            scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.DETENTION.LOSTAGENT
        elseif self.prisoner_escape then
            scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.DETENTION.GOTOTHER
        elseif self.prisoner_release then
            scripts = SCRIPTS.INGAME.CENTRAL_JUDGEMENT.DETENTION.LOSTOTHER
        end
        local scr = scripts[sim:nextRand(1, #scripts)]
        return scr
    end
    scriptMgr:addHook( "FINAL", mission_util.CreateCentralReaction(scriptfn))

end


function mission.pregeneratePrefabs( cxt, tagSet )
    local prefabs = include( "sim/prefabs" )
    escape_mission.pregeneratePrefabs( cxt, tagSet )
    tagSet[1].fitnessSelect = prefabs.SELECT_HIGHEST
    table.insert( tagSet, { { "detention", detentionFitness }, fitnessSelect = prefabs.SELECT_HIGHEST })
end


return mission

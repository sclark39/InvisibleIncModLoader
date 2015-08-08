local array = include( "modules/array" )
local util = include( "modules/util" )
local mathutil = include( "modules/mathutil" )
local cdefs = include( "client_defs" )
local simdefs = include( "sim/simdefs" )
local unitdefs = include( "sim/unitdefs" )
local simquery = include( "sim/simquery" )
local simfactory = include( "sim/simfactory" )
local mission_util = include( "sim/missions/mission_util" )
local inventory = include( "sim/inventory" )
local serverdefs = include( "modules/serverdefs" )
local level = include( "sim/level" )

local STRINGS = include( "strings" )
local SCRIPTS = include('client/story_scripts')

---------------------------------------------------------------------------------------------
-- Local helpers

local FINAL_ROOM_INTERRUPT =
{
    uiEvent = level.EV_FINAL_ROOM_INTERRUPT,
    fn = function( sim )
        return true
    end
}

local ENDING_JACKIN = 
{
	trigger = "ending_jackin",
}

local FINAL_UNLOCK = 
{
	trigger = "final_unlock",
}

local USED_TURING = 
{
	trigger = "used_turing"
}

local WIN_GAME = 
{
	trigger = "win_game"
}

local MONST3R_WALK_AWAY_FROM_HACK = 
{
	action = "moveAction",
	pre = true,
	fn = function( sim, unitID, moveTable )
		local unit = sim:getUnit( unitID )
		return unit and unit:isPC() and unit:getTraits().monst3r and unit:getTraits().monster_hacking
	end,
}

local function PC_ENTERED_TILE_WITH_TAG( tag )
	return
	{
		trigger = simdefs.TRG_UNIT_WARP,
		fn = function( sim, eventData )
			if eventData.unit:getTraits().central then 
				if eventData.to_cell and sim:getQuery().cellHasTag( sim, eventData.to_cell, "finalCentral" ) then 
					eventData.unit:interruptMove( sim )
					return true
				end
			end 
		end
	}
end

local function findCell( sim, tag )
	local cells = sim:getCells( tag )
	return cells and cells[1]
end

local function checkMonst3rWalkingAway( script, sim )
	script:waitFor( MONST3R_WALK_AWAY_FROM_HACK )

	local centralAgent = nil 
	local pcplayer = sim:getPC()

	for i, agent in pairs( pcplayer:getAgents() ) do 
		if agent:getTraits().central then 
			centralAgent = agent 
		end 
	end 

	if not centralAgent:isDown() and sim:hasObjective( "security_hub" ) then
		script:queue( { type="clearOperatorMessage" } )
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.STOP_HACKING_EARLY, type="newOperatorMessage" } )
	end

	script:addHook( checkMonst3rWalkingAway )
end

local function checkConsoleEMP( script, sim )
    local CONSOLE_EMP =
    {
        trigger = simdefs.TRG_UNIT_EMP,
        fn = function( sim, eventData )
            if eventData and eventData:hasTag( "ending_jackin" ) then
                return eventData
            end
        end,
    }

    local _, finalConsole = script:waitFor( CONSOLE_EMP )

    local monst3rAgent = mission_util.findUnitByTag( sim, "monst3r" )
    if monst3rAgent and monst3rAgent:getTraits().monster_hacking then
        monst3rAgent:setKO( sim, 2 )
    end

    script:addHook( checkConsoleEMP )
end

local function checkMonst3rResumeHack( script, sim )
   script:waitFor( ENDING_JACKIN )

   script:queue( { script=SCRIPTS.INGAME.FINALMISSION.HACK_RESUME, type="newOperatorMessage" } )

   script:addHook( checkMonst3rResumeHack )
end


local function checkImportantDeath( script, sim )
	local centralAgent = mission_util.findUnitByTag( sim, "central" )
    local monst3rAgent = mission_util.findUnitByTag( sim, "monst3r" )
    local bothDown = centralAgent and centralAgent:isDown() and monst3rAgent and monst3rAgent:isDown()

	local _, agent = script:waitFor( mission_util.AGENT_DOWN )

    script:clearQueue( true )
 	script:queue( { type="clearOperatorMessage" } )
    --script:queue(cdefs.SECONDS)

	if (agent:getTraits().central or agent:getTraits().monst3r) and bothDown then
        -- Central or Monst3r died, and they are both currently down.
		script:queue( { script=SCRIPTS.INGAME.BOTH_CRITICAL_DOWN, type="newOperatorMessage" } )

	elseif agent:getTraits().central then
        -- Central went down
		script:queue( { script=SCRIPTS.INGAME.CENTRAL_DOWN, type="newOperatorMessage" } )

	elseif agent:getTraits().monst3r then
		--jcheng: need to check if hacking is complete and play a different one
		if sim:hasObjective( "security_hub" ) or sim:hasObjective( "getToJackIn" ) or sim:hasObjective( "jackIn" ) then
			script:queue( { script=SCRIPTS.INGAME.FINALMISSION.MONSTER_DOWN_BEFORE_HACK, type="newOperatorMessage"} )
		else
			script:queue( { script=SCRIPTS.INGAME.FINALMISSION.MONSTER_DOWN_AFTER_HACK, type="newOperatorMessage"} )
		end
	elseif centralAgent:isDown() == false then 
		script:queue( {  debug = true, script=SCRIPTS.INGAME.FINALMISSION.AGENT_DOWN[sim:nextRand(1, #SCRIPTS.INGAME.FINALMISSION.AGENT_DOWN)], type="newOperatorMessage"} )
	end

	script:addHook(checkImportantDeath)

end

local function interruptNonCentral( script, sim )
	script:waitFor( FINAL_ROOM_INTERRUPT )	
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.NO_GO_THROUGH_DOOR, type="newOperatorMessage" } )
	script:addHook(interruptNonCentral)
end
	

local function seeGuardsFirstTime(script, sim)
	local a, unit, seer = script:waitFor( mission_util.PC_SAW_UNIT_WITH_TRAIT("omni") )
	local x, y = unit:getLocation()
	local x1, y1 = seer:getLocation()
	seer:interruptMove( sim )

	script:queue( { type="cameraCentre", x0=x, y0=y, x1=x1, y1=y1 } )
	script:queue( 0.25*cdefs.SECONDS )
    unit:createTab( STRINGS.MISSIONS.ENDING_1.UNKNOWN_THREAT, "" )
	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.SEE_GUARDS, type="newOperatorMessage" } )

	script:waitFor( mission_util.PC_ANY )
    unit:destroyTab()
end

local function incognitaReboot(script, sim)

	for k = 1, #SCRIPTS.INGAME.FINALMISSION.REBOOT_RANT do
		script:waitFor( mission_util.PC_START_TURN )
		
		--eh... not sure how we want to playt his
		if not sim:hasObjective( "security_hub" ) and not sim:getTags().monster_finished_hacking then
			script:queue( 2*cdefs.SECONDS )
			script:queue( { script=SCRIPTS.INGAME.FINALMISSION.REBOOT_RANT[k], type="newOperatorMessage", doNotQueue=true } )
		end
	end
end

local function incognitaReboot2(script, sim)

	for k = 1, #SCRIPTS.INGAME.FINALMISSION.SUPERCHARGE_RANT do
		script:waitFor( mission_util.PC_START_TURN )
		
		script:queue( 2*cdefs.SECONDS )
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.SUPERCHARGE_RANT[k], type="newOperatorMessage", doNotQueue=true } )

		if k == 2 then
			script:queue( { script=SCRIPTS.INGAME.FINALMISSION.POST_SUPERCHARGE_CONVO, type="newOperatorMessage", doNotQueue=true } )
		end
		
	end
end

local function callReinforcement(script, sim)
	local target = nil

	sim:forEachUnit(
			function(unit)
				if unit:getTraits().monst3r then 
					target = unit				
				end
			end)
	if target then
		local newGuards = sim:getNPC():spawnGuards(sim, "npc_guard_enforcer_reinforcement_2", 1)
		for i, newUnit in ipairs(newGuards) do
			local x1,y1 = target:getLocation()
			newUnit:getBrain():spawnInterest(x1, y1, simdefs.SENSE_RADIO, simdefs.REASON_REINFORCEMENTS, target)
		end
		return true
	else
		return false
	end

end

local function useIncognitaLove( script, sim )
	script:waitFor( USED_TURING )

	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.USE_LOVE_PROGRAM, type="newOperatorMessage" } )
end

local function processIncognitaState( script, sim )
	
	script:waitFor( util.extend( mission_util.PC_START_TURN ){ priority = -1 } )

	script:queue( .5*cdefs.SECONDS )

	local centralAgent = mission_util.findUnitByTag( sim, "central" )
    local monst3rAgent = mission_util.findUnitByTag( sim, "monst3r" )
    local centralDown = centralAgent and centralAgent:isDown() 
    local monst3rDown = monst3rAgent and monst3rAgent:isDown()
    local eitherDown = centralDown or monst3rDown

    if eitherDown then 
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.SUPERCHARGE_CONVO_ALT, type="modalConversation" } )
	else 
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.SUPERCHARGE_CONVO, type="modalConversation" } )
	end 
	sim:dispatchEvent( simdefs.EV_SCRIPT_ENTER_MAINFRAME )
	script:queue( 0.3 * cdefs.SECONDS )
	script:queue( { type="showLoveProgram" } ) 
	sim:dispatchEvent( simdefs.EV_HIDE_PROGRAM, { idx = 6 } )
	local pcplayer = sim:getPC() 
	pcplayer:addMainframeAbility( sim, "love" )

	script:removeHook( incognitaReboot )
	script:addHook( incognitaReboot2 )
end 

local function runFailsafe( script, sim )
	
	mission_util.doRecapturePresentation(script, sim, nil, nil, false, 2)

	script:waitFor( mission_util.PC_START_TURN )
	if sim:getNPC():hasMainframeAbility( "failsafe" ) then 
		script:addHook( runFailsafe )
	end 
end 

local function hallwayLights(script,sim)
	for i=1,12 do		
		local cell = findCell( sim, "light"..i )

		if cell then
			script:queue( 0.5 * cdefs.SECONDS )
			local console = mission_util.findUnitByTag( sim, "final_console" )
			script:queue( { type="finalHallLight", cell=cell, console = console} ) 
		end
	end
end

local function setMonst3rConsoleFX(sim,stage)
	local unit = nil
	for unitID, checkUnit in pairs(sim:getAllUnits()) do
		if checkUnit:hasTag("ending_jackin")then
			unit = checkUnit
		end				
	end
	if unit then
		unit:setMonst3rConsoleStage(sim,stage)	
	end
end

local function doCountermeasures( sim )
	local countermeasures = false
	if sim:getParams().difficultyOptions.countermeasuresFinal == nil then 
		if sim:getParams().campaignDifficulty == simdefs.NORMAL_DIFFICULTY then 
			countermeasures = false
		else
			countermeasures = true
		end 
	else 
		if sim:getParams().difficultyOptions.countermeasuresFinal == false then 
			countermeasures = false 
		else
			countermeasures = true 
		end 
	end 

	return countermeasures
end

local function processHubState( script, sim, hubState, monst3rAgent )

	local beginner = nil 

	if doCountermeasures( sim ) then 
		beginner = false
	else
		beginner = true
	end

	local x, y = monst3rAgent:getLocation()
    script:clearQueue()
	script:queue( { type="pan", x=x, y=y, zoom=0.27 } )	
	script:waitFrames( 0.8 * cdefs.SECONDS )

	if beginner and hubState <= 3 then 
		setMonst3rConsoleFX(sim,hubState+2)
	else
		setMonst3rConsoleFX(sim,hubState+1)
	end 

	script:waitFrames( 1 * cdefs.SECONDS )

	if hubState == 1 then
		sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.HUB_HACK_PROGRESS[2], type="newOperatorMessage" } )
	elseif hubState == 2 then 
		callReinforcement( script, sim )
		sim:setClimax(true)
		script:queue( 1.5 * cdefs.SECONDS )
		sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.HUB_HACK_PROGRESS[3], type="newOperatorMessage" } )
	elseif hubState == 3 then 
		local daemon = "panic"
		script:waitFrames( 1 * cdefs.SECONDS )
		sim:getNPC():addMainframeAbility( sim, daemon, nil, 0 )
		sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.HUB_HACK_PROGRESS[5], type="newOperatorMessage" } )
	elseif hubState == 4 then
		local daemon = "failsafe"
		script:waitFrames( 1 * cdefs.SECONDS )
		sim:getNPC():addMainframeAbility( sim, daemon, nil, 0 )	
		script:addHook( runFailsafe )
		sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.HUB_HACK_PROGRESS[4], type="newOperatorMessage" } )
	else 
		sim:removeObjective("security_hub")
	end 

end

local function seeMainframeLock( script, sim )
	script:waitFor( mission_util.PC_SAW_UNIT("yellow_level_console") )	
	local console = mission_util.findUnitByTag( sim, "yellow_level_console" )
    console:createTab( STRINGS.MISSIONS.ENDING_1.MAINFRAME_LOCK, STRINGS.MISSIONS.ENDING_1.REQUIRES_SPECIAL_ACCESS )
	if not sim:getTags().seen_security_hub then 
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.SEE_DOOR_FIRST, type="newOperatorMessage" } )
	end 
	sim:getTags().seen_mainframe_lock = true 
	script:waitFor( FINAL_UNLOCK )
    console:destroyTab()
end 

local function hubProgression( script, sim )
	local hubState = 0
	local monst3rAgent = nil
	script:addHook( checkMonst3rWalkingAway ) 

	while sim:hasObjective( "security_hub" ) do 
		script:waitFor( util.extend( mission_util.PC_START_TURN ){ priority = -1 } )

		script:queue( .5*cdefs.SECONDS )

		local pcplayer = sim:getPC()
		for i, agent in pairs( pcplayer:getAgents() ) do 
			if agent:getTraits().monster_hacking then 
				monst3rAgent = agent
				sim:incrementTimedObjective( "security_hub" )
				hubState = hubState + 1
				if not doCountermeasures( sim ) and hubState == 3 then
					hubState = 4 
				end 
				
				processHubState( script, sim, hubState, monst3rAgent )
			end 
		end 
	end 
	
	sim:getTags().monster_finished_hacking = true 
	script:addHook( processIncognitaState )
	sim:dispatchEvent( simdefs.EV_SCRIPT_EXIT_MAINFRAME )
	local x, y = monst3rAgent:getLocation()
	script:queue( { type="pan", x=x, y=y, zoom=0.27 } )
	
	setMonst3rConsoleFX(sim,6)

	script:queue( 2.5 * cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.HUB_HACK_FINISHED, type="modalConversation" } )
	local augment = inventory.giftUnit( sim, monst3rAgent, "augment_final_level", false )
	monst3rAgent:getTraits().monster_hacking = nil 
	monst3rAgent:getSounds().spot = nil
	sim:dispatchEvent( simdefs.EV_UNIT_TINKER_END, { unit = monst3rAgent } ) 
	sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, { unit = monst3rAgent } )
	monst3rAgent:doAugmentUpgrade(augment)
	script:queue(1*cdefs.SECONDS)

end 

local function incognitaChatter( script, sim )
	script:queue( 2*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.FINAL_WALK_RANT[1], type="newOperatorMessage" } )

	script:queue( 2*cdefs.SECONDS )
	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.FINAL_WALK_RANT[2], type="newOperatorMessage" } )
end

local function removeHudElements( sim )
	sim:showHUD( false, "inventoryPanel", "endTurnBtn", "abilities", "mainframe", "agentSelection", "alarm", "agentFlags", "resourcePnl", "statsPnl", "topPnl", "rewindBtn", "menuBtn", "agentPanel", "daemonPanel", "objectivesTopLabel" )
	sim:clearObjectives()
end 

local function startPhase( script, sim )
	
    script:waitFor( mission_util.UI_INITIALIZED )
	
	script:queue( { type = "hideInterface" })
    sim:dispatchEvent( simdefs.EV_TELEPORT, { units = sim:getPC():getAgents(), warpOut = false } )		

	
	--mission_util.makeAgentConnection( script, sim )

	local centralAgent = mission_util.findUnitByTag( sim, "central" )
	local monsterAgent = mission_util.findUnitByTag( sim, "monst3r" ) 
    inventory.giftUnit( sim, centralAgent, "item_incognita", false )

	sim:forEachCell(
		function( c )
			for i, exit in pairs( c.exits ) do
				if exit.door and exit.keybits == simdefs.DOOR_KEYS.FINAL_LEVEL then 
					exit.no_close = true 
				end
			end 
		end) 



	script:queue( 1*cdefs.SECONDS )
	sim:getTags().no_escape = true 

	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.INTRO, type="modalConversation" } )	
	script:queue( { type = "showInterface" })

	script:queue( 0.5*cdefs.SECONDS )
	script:queue( { type = "showMissionObjectives" })

	sim:addObjective( STRINGS.MISSIONS.ENDING_1.FIND_CONSOLE, "getToJackIn" )

	script:waitFor( mission_util.PC_ANY )
	script:queue( { type="clearOperatorMessage" } )

	local _, hackConsole = script:waitFor( mission_util.SAW_SPECIAL_TAG(script, "ending_jackin", STRINGS.MISSIONS.ENDING_1.COMMUNICATIONS_NEXUS, STRINGS.MISSIONS.ENDING_1.HACK_WITH_MONST3R ) )	

	if sim:getTags().seen_mainframe_lock then 
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.SEE_HUB_SECOND, type="newOperatorMessage" } )
	else 
		script:queue( { script=SCRIPTS.INGAME.FINALMISSION.SEE_HUB_FIRST, type="newOperatorMessage" } )
	end 
	

	sim:getTags().seen_security_hub = true 
	sim:removeObjective( "getToJackIn" )

	sim:addObjective( STRINGS.MISSIONS.ENDING_1.HACK_CONSOLE, "jackIn" )

	script:waitFor( ENDING_JACKIN )

 	--SPAWN THE FX. 	
 	setMonst3rConsoleFX(sim,1)
 	local beginner = false 
 	if not doCountermeasures( sim ) then 
 		beginner = true
 		script:waitFrames( 1.5*cdefs.SECONDS )
 		setMonst3rConsoleFX(sim,2)
 	end 

	script:addHook( checkMonst3rResumeHack )

	--wait for effect to finish
	script:waitFrames( 1*cdefs.SECONDS )

	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.HUB_HACK_PROGRESS[1], type="newOperatorMessage" } )

    hackConsole:destroyTab()
	sim:removeObjective( "jackIn" )
	if beginner then 
		sim:addObjective( STRINGS.MISSIONS.ENDING_1.OBJ_SECURITY_HUB, "security_hub", 4 )
	else 
		sim:addObjective( STRINGS.MISSIONS.ENDING_1.OBJ_SECURITY_HUB, "security_hub", 5 )
	end 
	hubProgression( script, sim )

	sim:addObjective( STRINGS.MISSIONS.ENDING_1.BRING_MONST3R, "bringMonster" )
	sim:addObjective( STRINGS.MISSIONS.ENDING_1.BRING_CENTRAL, "bringCentral" )
	--script:queue( { script=SCRIPTS.INGAME[2], type="newOperatorMessage" } )

	script:waitFor( mission_util.PC_ANY )
	script:queue( { type="clearOperatorMessage" } )

	script:waitFor( FINAL_UNLOCK )
	sim:removeObjective( "bringMonster" )

	sim:openElevator()
	sim:dispatchEvent( simdefs.EV_PLAY_SOUND, "SpySociety/Actions/door_finallarge_open" )
	sim:getTags().blockMoveCentral = true
	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.OPEN_FINAL_DOOR, type="newOperatorMessage" } )
	
	script:queue( 1*cdefs.SECONDS )

	script:waitFor( PC_ENTERED_TILE_WITH_TAG( "finalCentral" ) )

	centralAgent:interruptMove( sim )
	sim:dispatchEvent( simdefs.EV_PUSH_QUIET_MIX )
	sim:closeElevator()
	removeHudElements( sim )
	centralAgent:getTraits().walk = true
	centralAgent:getTraits().mp = 99999
	centralAgent:getTraits().hidesInCover = nil
	sim:getTags().no_last_words = true 
	sim:dispatchEvent( simdefs.EV_UNIT_REFRESH, {unit = centralAgent} )
    script:removeHook( checkImportantDeath )
	local pcplayer = sim:getPC()
	for _, agent in pairs(pcplayer:getAgents()) do
		if not agent:getTraits().central then
			for agentID, deployData in pairs(pcplayer:getDeployed()) do
				if deployData.id == agent:getID() then
					deployData.escapedUnit = agent
				end
			end 
			sim:warpUnit( agent, nil )
			sim:despawnUnit( agent )
		end
	end 

	for _, unit in pairs( sim:getAllUnits() ) do 
		if unit:getTraits().mainframe_camera or (simquery.isAgent( unit ) and not unit:getTraits().central ) then 
            local cell = sim:getCell( unit:getLocation() )
            if cell then
                if cell.procgenRoom.tags.exit_final then
        		 	sim:dispatchEvent( simdefs.EV_TELEPORT, { units = { unit }, warpOut = true } )
                end
                sim:warpUnit( unit, nil )
                sim:getPC():glimpseUnit( sim, unit:getID() )
    			sim:despawnUnit( unit )
            end
		end 
	end 

	sim:dispatchEvent( simdefs.EV_SHORT_WALLS )

	local tile = findCell( sim, "zoomTo" )
	local final_console = mission_util.findUnitByTag(sim, "final_console")
	--rotate the world so the console is facing down at you
	--local orient = 3 - final_console:getFacing() / 2
	local orient = final_console:getFacing()

	script:queue( { type="pan", x=tile.x, y=tile.y, zoom=0.27, orientation=orient } )	
	script:queue( { script=SCRIPTS.INGAME.FINALMISSION.PASS_THROUGH_DOOR, type="newOperatorMessage" } )

	hallwayLights(script,sim)

	script:addHook( incognitaChatter )

	script:waitFor( WIN_GAME )

	script:queue( { type="clearOperatorMessage" } )
	script:removeHook( incognitaChatter )

	sim:dispatchEvent( simdefs.EV_FADE_TO_BLACK )

	script:queue( 4 * cdefs.SECONDS )
	sim:win()
end

---------------------------------------------------------------------------------------------
-- Begin!

local ending_1 = class( mission_util.campaign_mission )

function ending_1:init( scriptMgr, sim )
    self.finalMission = true
    mission_util.campaign_mission.init( self, scriptMgr, sim )

    local serverdefs = include( "modules/serverdefs" )
    local specialAgents = {}

    local hasCentral = false
    local hasMonst3r = false
	for i, agent in pairs( sim:getPC():getAgents() ) do 
		if agent:getTraits().central then 
			hasCentral = true
		end 
		if agent:getTraits().monst3r then 
			hasMonst3r = true
		end 
	end 

	if not hasCentral then
		table.insert( specialAgents, serverdefs.createAgent( "central" ))
	end
	
	if not hasMonst3r then
		table.insert( specialAgents, serverdefs.createAgent( "monst3r" ))
	end

	if #specialAgents > 0 then
	    sim:getPC():reserveUnits( specialAgents )
	    sim:getPC():deployUnits( sim, specialAgents )
	end

	scriptMgr:addHook( "ENDING_1", startPhase )
    scriptMgr:addHook( "EMP", checkConsoleEMP )
	scriptMgr:addHook( "IMPT DEATH", checkImportantDeath )
	scriptMgr:addHook( "ENDING_1", incognitaReboot )
	scriptMgr:addHook( "ENDING_1", seeGuardsFirstTime )
	scriptMgr:addHook( "ENDING_1", useIncognitaLove )
	scriptMgr:addHook( "ENDING_1", interruptNonCentral )
	scriptMgr:addHook( "ENDING_1", seeMainframeLock )
end

local function exitFitnessFn( cxt, prefab, x, y )
    local tileCount = cxt:calculatePrefabLinkage( prefab, x, y )
    if tileCount == 0 then
        return 0 -- Doesn't link up
    end

    local maxDist = mission_util.calculatePrefabDistance( cxt, x, y, "entry" )
    return tileCount + maxDist^2
end

local function rootAccessFn( cxt, prefab, x, y )
    local tileCount = cxt:calculatePrefabLinkage( prefab, x, y )
    if tileCount == 0 then
        return 0 -- Doesn't link up
    end
    
    -- Maximize distance to exit AND entrance prefab.
    local maxDist = mission_util.calculatePrefabDistance( cxt, x, y, "entry", "exit" )
    return tileCount + maxDist^2
end

local function makeTags( tag, count )
    local t = {}
    for i = 1, count do
        table.insert( t, tag )
    end
    return unpack( t )
end

function ending_1.pregeneratePrefabs( cxt, tagSet )
    local prefabs = include( "sim/prefabs" )

    table.insert( tagSet, { "entry", makeTags( "struct", cxt.params.difficultyOptions.roomCount ) })
    tagSet[1].fitnessSelect = prefabs.SELECT_HIGHEST
    table.insert( tagSet, { "struct_small", "struct_small" })

    local FINAL_EXIT = { "exit_final", exitFitnessFn }
    local ROOT_ACCESS = { "root_access_console", rootAccessFn }
	table.insert( tagSet, { FINAL_EXIT, fitnessSelect = prefabs.SELECT_HIGHEST })
    table.insert( tagSet, { ROOT_ACCESS, fitnessSelect = prefabs.SELECT_HIGHEST })
end

return ending_1
